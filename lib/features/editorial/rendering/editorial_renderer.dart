import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../collage_editor/models/photo_asset.dart';
import '../../collage_editor/models/photo_transform.dart';
import '../../collage_editor/models/text_overlay.dart';
import '../../collage_editor/rendering/photo_crop.dart';
import '../../collage_editor/rendering/style_renderer.dart';
import '../../collage_editor/rendering/text_overlay_renderer.dart';
import '../../projects/models/collage_project.dart';
import '../models/editorial_design.dart';
import '../models/design_presets.dart';

/// No widget state or selection data enters this renderer.
class EditorialRenderer {
  static Rect bounds(DesignLayer layer, Size size) {
    final r = layer.rect(size);
    if (layer.type != DesignLayerType.callout ||
        (layer.shape != CalloutShape.circle &&
            layer.shape != CalloutShape.square)) {
      return r;
    }
    final edge = math.min(r.width, r.height);
    return Rect.fromCenter(center: r.center, width: edge, height: edge);
  }

  /// Seeded multi-frequency edge displacement, normalized before scaling.
  /// Independent of output resolution; no textures or external assets.
  static Path tearPath(Rect rect, DesignLayer layer) {
    final random = math.Random(layer.seed + layer.tearStyle.index * 104729);
    final amplitude = .065 * layer.tearIntensity;
    final samples = 28 + (layer.roughness * 80).round();
    final style = layer.tearStyle;
    final path = Path();
    for (var edge = 0; edge < 4; edge++) {
      final enabled = switch (layer.tearEdges) {
        TearEdges.top => edge == 0,
        TearEdges.bottom => edge == 2,
        TearEdges.horizontal => edge.isEven,
        TearEdges.vertical => edge.isOdd,
        TearEdges.all => true,
      };
      final points = <Offset>[];
      final phase = random.nextDouble() * math.pi * 2;
      for (var i = 0; i <= samples; i++) {
        final t = i / samples;
        final low = (math.sin(t * math.pi * 7 + phase) + 1) * .22;
        final noise = random.nextDouble();
        final fiber = style == TearStyle.fibrous
            ? math.pow(noise, 3).toDouble()
            : noise * .55;
        final displacement = enabled
            ? amplitude *
                (.15 + low + fiber * (.2 + layer.roughness)) *
                (style == TearStyle.soft
                    ? .55
                    : style == TearStyle.weathered
                        ? 1.3
                        : 1) *
                math.sin(t * math.pi).abs()
            : 0.0;
        points.add(switch (edge) {
          0 => Offset(t, displacement),
          1 => Offset(1 - displacement, t),
          2 => Offset(1 - t, 1 - displacement),
          _ => Offset(displacement, 1 - t),
        });
      }
      Offset pixel(Offset p) =>
          Offset(rect.left + p.dx * rect.width, rect.top + p.dy * rect.height);
      if (edge == 0) {
        final p = pixel(points.first);
        path.moveTo(p.dx, p.dy);
      }
      for (var i = 1; i < points.length; i++) {
        final a = pixel(points[i - 1]);
        final b = pixel(points[i]);
        final mid = (a + b) / 2;
        path.quadraticBezierTo(a.dx, a.dy, mid.dx, mid.dy);
      }
      final end = pixel(points.last);
      path.lineTo(end.dx, end.dy);
    }
    return path..close();
  }

  static Path clipPath(DesignLayer layer, Rect rect, Size size) {
    if (layer.type == DesignLayerType.torn) return tearPath(rect, layer);
    if (layer.type == DesignLayerType.callout &&
        layer.shape == CalloutShape.circle) {
      return Path()..addOval(rect);
    }
    final radius = layer.type == DesignLayerType.callout &&
            layer.shape != CalloutShape.rounded
        ? 0.0
        : layer.radius * StyleRenderer.scale(size);
    return Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
  }

  static Offset rotatePoint(Offset point, Offset center, double degrees) {
    final p = point - center, a = degrees * math.pi / 180;
    return center +
        Offset(p.dx * math.cos(a) - p.dy * math.sin(a),
            p.dx * math.sin(a) + p.dy * math.cos(a));
  }

  /// Maps original normalized source coordinates through the SAME fit/fill,
  /// rotation, flip and offset equations used by StyleRenderer.photo.
  static Offset sourcePoint(
      DesignLayer main, PhotoAsset photo, Size source, Size size, Offset uv) {
    final rect = bounds(main, size);
    final t = PhotoCrop.clamp(photo.transform, source, rect.size);
    final q = t.rotationQuarterTurns % 4;
    final rw = q.isOdd ? source.height : source.width;
    final rh = q.isOdd ? source.width : source.height;
    final scale = (t.fitMode == PhotoFitMode.fill
            ? math.max(rect.width / rw, rect.height / rh)
            : math.min(rect.width / rw, rect.height / rh)) *
        t.scale;
    var p = Offset((uv.dx - .5) * source.width * scale,
        (uv.dy - .5) * source.height * scale);
    p = rotatePoint(p, Offset.zero, q * 90.0);
    if (t.flipX) p = Offset(-p.dx, p.dy);
    final mapped = rect.center +
        p +
        Offset(t.offsetX * rect.width, t.offsetY * rect.height);
    return rotatePoint(mapped, rect.center, main.rotation);
  }

  static DesignLayer? mainPhoto(CollageProject project, DesignLayer callout) =>
      project.design.ordered
          .where((l) =>
              l.visible &&
              l.isPhoto &&
              l.type != DesignLayerType.callout &&
              l.source(project.photos)?.id ==
                  callout.source(project.photos)?.id)
          .firstOrNull;

  static Offset connectorStart(
      CollageProject project, DesignLayer layer, Size size, Size? sourceSize) {
    final main = mainPhoto(project, layer);
    final photo = layer.source(project.photos);
    if (main == null || photo == null) {
      return Offset(layer.crop.center.dx * size.width,
          layer.crop.center.dy * size.height);
    }
    final source = sourceSize ??
        Size(photo.metadata?.width.toDouble() ?? 1,
            photo.metadata?.height.toDouble() ?? 1);
    return sourcePoint(main, photo, source, size, layer.crop.center);
  }

  static void paintLayer(
      Canvas canvas, Size size, CollageProject project, DesignLayer layer,
      {ui.Image? image, Size? sourceSize}) {
    if (!layer.visible || layer.opacity <= 0) return;
    final r = bounds(layer, size);
    final scale = StyleRenderer.scale(size);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    if (layer.opacity < 1) {
      canvas.saveLayer(
          null, Paint()..color = Colors.white.withValues(alpha: layer.opacity));
    }
    if ((layer.type == DesignLayerType.callout && layer.connector) ||
        layer.type == DesignLayerType.connector) {
      final end = rotatePoint(
          Offset(r.left + r.width * layer.endpoint.dx,
              r.top + r.height * layer.endpoint.dy),
          r.center,
          layer.rotation);
      canvas.drawLine(
          connectorStart(project, layer, size, sourceSize),
          end,
          Paint()
            ..color = Color(layer.lineColor)
            ..strokeWidth = layer.lineWidth * scale
            ..isAntiAlias = true);
    }
    canvas.translate(r.center.dx, r.center.dy);
    canvas.rotate(layer.rotation * math.pi / 180);
    canvas.translate(-r.center.dx, -r.center.dy);
    final path = clipPath(layer, r, size);
    if (layer.type == DesignLayerType.background) {
      canvas.drawPath(path, Paint()..color = Color(layer.color));
    }
    if (layer.isPhoto) {
      if (layer.type == DesignLayerType.torn && layer.shadow) {
        canvas.save();
        canvas.translate(0, 2 * scale);
        canvas.drawPath(
            path,
            Paint()
              ..color = const Color(0x33000000)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * scale));
        canvas.restore();
      }
      canvas.save();
      canvas.clipPath(path);
      final photo = layer.source(project.photos);
      if (image != null && photo != null) {
        StyleRenderer.photo(
            canvas,
            image,
            r,
            0,
            layer.type == DesignLayerType.callout
                ? PhotoTransform.identity
                : photo.transform,
            adjustments: photo.adjustments,
            sourceSize: sourceSize,
            sourceCrop:
                layer.type == DesignLayerType.callout ? layer.crop : null);
      } else {
        canvas.drawRect(r, Paint()..color = const Color(0xFFE0E0E0));
      }
      canvas.restore();
    }
    if (layer.isText) {
      final content = layer.type == DesignLayerType.caption
          ? DesignPreset.caption(project.design, layer)
          : layer.text.text;
      if (content.isNotEmpty) {
        paintText(canvas, size, r, layer.text, content,
            locationIcon: layer.type == DesignLayerType.location &&
                layer.showLocationIcon);
      }
    }
    if (layer.borderWidth > 0 && layer.type != DesignLayerType.connector) {
      canvas.save();
      canvas.clipPath(path);
      canvas.drawPath(
          path,
          Paint()
            ..color = Color(layer.borderColor)
            ..style = PaintingStyle.stroke
            ..strokeWidth = layer.borderWidth * scale * 2
            ..isAntiAlias = true);
      canvas.restore();
    }
    if (layer.opacity < 1) canvas.restore();
    canvas.restore();
  }

  static void paintText(
      Canvas canvas, Size size, Rect rect, TextOverlay style, String content,
      {bool locationIcon = false}) {
    final scale = StyleRenderer.scale(size);
    final pad =
        math.min(style.padding * scale, math.min(rect.width, rect.height) * .2);
    if (style.backgroundColor != null) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              rect, Radius.circular(style.cornerRadius * scale)),
          Paint()..color = Color(style.backgroundColor!));
    }
    final rtl = TextOverlayRenderer.directionFor(content) == TextDirection.rtl;
    final iconSpace = locationIcon ? 22 * scale : 0.0;
    var fontSize = style.fontSize * scale;
    TextPainter make() => TextPainter(
        text: TextSpan(
            text: content,
            style: TextStyle(
                color: Color(style.color),
                fontSize: fontSize,
                fontFamily: style.fontFamily,
                fontWeight: FontWeight.w500,
                height: 1.15)),
        textDirection: TextOverlayRenderer.directionFor(content),
        textAlign: switch (style.alignment) {
          TextOverlayAlignment.left => TextAlign.left,
          TextOverlayAlignment.center => TextAlign.center,
          TextOverlayAlignment.right => TextAlign.right
        },
        maxLines: 12,
        ellipsis: '…')
      ..layout(maxWidth: math.max(1, rect.width - pad * 2 - iconSpace));
    var text = make();
    while (text.height > rect.height - pad * 2 && fontSize > 4 * scale) {
      text.dispose();
      fontSize *= .9;
      text = make();
    }
    canvas.save();
    canvas.clipRect(rect);
    final available = rect.width - pad * 2 - iconSpace;
    final dx = switch (style.alignment) {
      TextOverlayAlignment.left => 0.0,
      TextOverlayAlignment.center => (available - text.width) / 2,
      TextOverlayAlignment.right => available - text.width
    };
    text.paint(
        canvas,
        Offset(rect.left + pad + (!rtl ? iconSpace : 0) + dx,
            rect.center.dy - text.height / 2));
    if (locationIcon) {
      final icon = TextPainter(
          text: TextSpan(
              text: String.fromCharCode(Icons.location_on_outlined.codePoint),
              style: TextStyle(
                  fontFamily: Icons.location_on_outlined.fontFamily,
                  package: Icons.location_on_outlined.fontPackage,
                  fontSize: 18 * scale,
                  color: Color(style.color))),
          textDirection: TextDirection.ltr)
        ..layout();
      icon.paint(
          canvas,
          Offset(rtl ? rect.right - pad - icon.width : rect.left + pad,
              rect.center.dy - icon.height / 2));
      icon.dispose();
    }
    canvas.restore();
    text.dispose();
  }
}
