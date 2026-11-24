import '../models/photo_adjustments.dart';
import 'photo_filter_renderer.dart';
import 'photo_detail_renderer.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/canvas_settings.dart';
import '../models/canvas_style.dart';
import '../models/photo_transform.dart';
import '../models/photo_placement.dart';
import '../models/photo_asset.dart';
import '../../projects/models/collage_project.dart';
import 'layout_geometry.dart';
import 'crop_geometry.dart';

class StyleRenderer {
  const StyleRenderer._();
  static double scale(Size size) => size.shortestSide / 390;
  static int photoIndex(CanvasStyle style, int count) =>
      count == 0 ? 0 : style.blurPhotoIndex.clamp(0, count - 1);

  static PhotoAsset? backdropPhoto(CollageProject project) {
    if (project.photos.isEmpty ||
        project.canvas.style.backgroundType != BackgroundType.blur) {
      return null;
    }
    final photo =
        project.photos[photoIndex(project.canvas.style, project.photos.length)];
    return project.freestyle && photo.placement?.hidden == true ? null : photo;
  }

  static void background(Canvas canvas, Size size, CanvasSettings settings,
      {ui.Image? image, bool opaque = false}) {
    final rect = Offset.zero & size;
    final style = settings.style;
    final unit = scale(size);
    canvas.save();
    canvas.clipRect(rect);
    if (opaque) canvas.drawRect(rect, Paint()..color = Colors.white);
    if (style.backgroundType == BackgroundType.transparent) {
      canvas.restore();
      return;
    }
    canvas.drawRect(rect, Paint()..color = Color(settings.backgroundColor));
    if (style.backgroundType == BackgroundType.gradient) {
      final angle = style.gradientAngle * math.pi / 180;
      final vector = Offset(
          math.cos(angle) * size.width / 2, math.sin(angle) * size.height / 2);
      canvas.drawRect(
          rect,
          Paint()
            ..shader = ui.Gradient.linear(
                rect.center - vector, rect.center + vector, [
              Color(settings.backgroundColor),
              Color(style.gradientEndColor)
            ]));
    } else if (style.backgroundType == BackgroundType.blur && image != null) {
      final sigma = style.blurSigma * unit;
      canvas.saveLayer(
          rect,
          Paint()
            ..imageFilter = ui.ImageFilter.blur(
                sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.clamp));
      final target = rect.inflate(sigma * 3);
      final fit = applyBoxFit(BoxFit.cover,
          Size(image.width.toDouble(), image.height.toDouble()), target.size);
      final source = Alignment.center.inscribe(fit.source,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()));
      final paint = Paint()..filterQuality = FilterQuality.medium;
      if (style.desaturate) {
        paint.colorFilter = const ColorFilter.matrix([
          .6065,
          .3575,
          .036,
          0,
          0,
          .1065,
          .8575,
          .036,
          0,
          0,
          .1065,
          .3575,
          .536,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);
      }
      canvas.drawImageRect(image, source, target, paint);
      canvas.restore();
      canvas.drawRect(
          rect,
          Paint()
            ..color = (style.brightness < 0 ? Colors.black : Colors.white)
                .withValues(alpha: style.brightness.abs()));
    } else if ([BackgroundType.paper, BackgroundType.grid, BackgroundType.dots]
        .contains(style.backgroundType)) {
      final ink = Color(settings.backgroundColor).computeLuminance() > 0.5
          ? Colors.black
          : Colors.white;
      final paint = Paint()
        ..color = ink.withValues(alpha: 0.08)
        ..strokeWidth = 0.6 * unit;
      final step =
          (style.backgroundType == BackgroundType.paper ? 5 : 18) * unit;
      if (step > 0) {
        for (double y = 0; y < size.height; y += step) {
          if (style.backgroundType == BackgroundType.grid) {
            canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
          }
          for (double x = 0; x < size.width; x += step) {
            if (style.backgroundType == BackgroundType.grid) {
              if (y == 0) {
                canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
              }
            } else {
              final shift = style.backgroundType == BackgroundType.paper
                  ? math.sin(x * .3 + y * .7) * unit * 2
                  : 0.0;
              canvas.drawCircle(
                  Offset(x + shift, y),
                  (style.backgroundType == BackgroundType.paper ? .35 : 1) *
                      unit,
                  paint);
            }
          }
        }
      }
    }
    canvas.restore();
  }

  static Path cellPath(List<ResolvedLayoutCell> cells) {
    var path = Path();
    for (final cell in cells) {
      final next = Path()
        ..addRRect(RRect.fromRectAndRadius(
            cell.rect, Radius.circular(cell.cornerRadius)));
      path = Path.combine(PathOperation.union, path, next);
    }
    return path;
  }

  static void shadows(Canvas canvas, Size size, CanvasSettings settings,
      List<ResolvedLayoutCell> cells) {
    final style = settings.style;
    if (!style.shadowEnabled) return;
    // One union silhouette prevents accumulating shadows at shared edges.
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(0, 3 * scale(size));
    canvas.drawPath(
        cellPath(cells),
        Paint()
          ..color = Colors.black.withValues(alpha: style.shadowOpacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal,
              math.max(.01, style.shadowSoftness * scale(size))));
    canvas.restore();
  }

  static void frames(Canvas canvas, Size size, CanvasSettings settings,
      List<ResolvedLayoutCell> cells) {
    final style = settings.style;
    if (!style.frameEnabled || style.frameWidth <= 0) return;
    final path = cellPath(cells);
    canvas.save();
    canvas.clipPath(path);
    canvas.drawPath(
        path,
        Paint()
          ..color = Color(style.frameColor)
          ..style = PaintingStyle.stroke
          ..strokeWidth = style.frameWidth * scale(size) * 2);
    canvas.restore();
  }

  static void photo(Canvas canvas, ui.Image image, Rect cell, double radius,
      PhotoTransform transform,
      {PhotoAdjustments adjustments = const PhotoAdjustments(),
      ui.FragmentProgram? detailProgram}) {
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(cell, Radius.circular(radius)));
    final vignette = adjustments.vignette.clamp(0.0, 1.0);
    if (vignette > 0) canvas.saveLayer(cell, Paint());
    canvas.save();
    final rotation = transform.rotationQuarterTurns % 4;
    final source = Size(image.width.toDouble(), image.height.toDouble());
    final crop = CropGeometry.resolve(cell, source, transform);
    final center = crop.center;
    canvas.translate(center.dx, center.dy);
    if (transform.flipX) canvas.scale(-1, 1);
    canvas.rotate(rotation * math.pi / 2);
    final destination = Rect.fromCenter(
        center: Offset.zero,
        width: crop.imageSize.width,
        height: crop.imageSize.height);
    final paint = Paint()
      ..colorFilter = PhotoFilterRenderer.filter(adjustments)
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;
    if (detailProgram != null && adjustments.usesDetail) {
      PhotoDetailRenderer.paint(
          canvas, image, destination, paint, adjustments, detailProgram);
    } else {
      canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          destination,
          paint);
    }
    canvas.restore();
    if (vignette > 0) {
      canvas.save();
      canvas.translate(cell.center.dx, cell.center.dy);
      canvas.scale(cell.width / 2, cell.height / 2);
      canvas.drawRect(
          const Rect.fromLTRB(-1, -1, 1, 1),
          Paint()
            ..blendMode = BlendMode.srcATop
            ..shader = ui.Gradient.radial(Offset.zero, math.sqrt2, [
              Colors.transparent,
              Colors.black.withValues(alpha: vignette * .48),
              Colors.black.withValues(alpha: vignette * .85),
            ], [
              .28,
              .72,
              1
            ]));
      canvas.restore();
      canvas.restore();
    }
    canvas.restore();
  }

  static void freestylePhoto(
      Canvas canvas, Size size, PhotoAsset photoAsset, ui.Image? image,
      {Color? placeholder, ui.FragmentProgram? detailProgram}) {
    final placement = photoAsset.placement ?? const PhotoPlacement();
    if (placement.hidden ||
        placement.opacity == 0 ||
        (image == null && placeholder == null)) {
      return;
    }
    final bounds = placement.rect(size);
    final rect = Rect.fromCenter(
        center: Offset.zero, width: bounds.width, height: bounds.height);
    final radius = placement.radius * rect.shortestSide;
    final outline = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.save();
    canvas.translate(bounds.center.dx, bounds.center.dy);
    canvas.rotate(placement.radians);
    if (placement.shadow) {
      canvas.drawRRect(
          outline.shift(Offset(0, 5 * scale(size))),
          Paint()
            ..color = Colors.black.withValues(alpha: .42 * placement.opacity)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * scale(size)));
    }
    if (placement.opacity < 1) {
      canvas.saveLayer(rect,
          Paint()..color = Colors.white.withValues(alpha: placement.opacity));
    }
    if (image == null) {
      canvas.drawRRect(outline, Paint()..color = placeholder!);
    } else {
      photo(canvas, image, rect, radius, photoAsset.transform,
          adjustments: photoAsset.adjustments, detailProgram: detailProgram);
    }
    if (placement.border > 0) {
      canvas.save();
      canvas.clipRRect(outline);
      canvas.drawRRect(
          outline,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 * placement.border * rect.shortestSide);
      canvas.restore();
    }
    if (placement.opacity < 1) canvas.restore();
    canvas.restore();
  }
}
