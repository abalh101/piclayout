import '../models/photo_adjustments.dart';
import 'photo_filter_renderer.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/canvas_settings.dart';
import '../models/canvas_style.dart';
import '../models/photo_transform.dart';
import 'layout_geometry.dart';

class StyleRenderer {
  const StyleRenderer._();
  static double scale(Size size) => size.shortestSide / 390;
  static int photoIndex(CanvasStyle style, int count) =>
      count == 0 ? 0 : style.blurPhotoIndex.clamp(0, count - 1);

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
      {PhotoAdjustments adjustments = const PhotoAdjustments()}) {
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(cell, Radius.circular(radius)));
    final rotation = transform.rotationQuarterTurns % 4;
    final rotatedWidth =
        rotation.isOdd ? image.height.toDouble() : image.width.toDouble();
    final rotatedHeight =
        rotation.isOdd ? image.width.toDouble() : image.height.toDouble();
    final baseScale = transform.fitMode == PhotoFitMode.fill
        ? math.max(cell.width / rotatedWidth, cell.height / rotatedHeight)
        : math.min(cell.width / rotatedWidth, cell.height / rotatedHeight);
    final userScale = transform.scale.clamp(0.5, 5.0).toDouble();
    final center = cell.center +
        Offset(transform.offsetX * cell.width, transform.offsetY * cell.height);
    canvas.translate(center.dx, center.dy);
    if (transform.flipX) canvas.scale(-1, 1);
    canvas.rotate(rotation * math.pi / 2);
    canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromCenter(
            center: Offset.zero,
            width: image.width * baseScale * userScale,
            height: image.height * baseScale * userScale),
        Paint()
          ..colorFilter = PhotoFilterRenderer.filter(adjustments)
          ..isAntiAlias = true
          ..filterQuality = FilterQuality.high);
    canvas.restore();
  }
}
