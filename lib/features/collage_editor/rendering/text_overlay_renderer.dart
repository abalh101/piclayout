import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/text_overlay.dart';

class TextOverlayLayout {
  TextOverlayLayout({
    required this.painter,
    required this.bounds,
    required this.center,
  });

  final TextPainter painter;
  final Rect bounds;
  final Offset center;

  void dispose() => painter.dispose();
}

class TextOverlayRenderer {
  const TextOverlayRenderer._();

  static double scaleFor(Size size) => size.shortestSide / 390;

  static TextOverlayLayout layout(TextOverlay overlay, Size size) {
    final scale = scaleFor(size);
    final padding = 8 * scale;
    final maxTextWidth = math.max(1.0, size.width * 0.84 - padding * 2);
    var fontSize = overlay.fontSize * scale;
    TextPainter makePainter() => TextPainter(
          text: TextSpan(
            text: overlay.text.isEmpty ? ' ' : overlay.text,
            style: TextStyle(
              color: Color(overlay.color),
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          textAlign: switch (overlay.alignment) {
            TextOverlayAlignment.left => TextAlign.left,
            TextOverlayAlignment.center => TextAlign.center,
            TextOverlayAlignment.right => TextAlign.right,
          },
          textDirection: TextDirection.ltr,
          textWidthBasis: TextWidthBasis.longestLine,
          maxLines: 6,
          ellipsis: '…',
        )..layout(maxWidth: maxTextWidth);

    var painter = makePainter();
    while (painter.height + padding * 2 > size.height * 0.8 &&
        fontSize > 6 * scale) {
      painter.dispose();
      fontSize *= 0.9;
      painter = makePainter();
    }
    final width = painter.width + padding * 2;
    final height = painter.height + padding * 2;
    final angle = overlay.rotation * math.pi / 180;
    final halfX =
        (math.cos(angle).abs() * width + math.sin(angle).abs() * height) / 2;
    final halfY =
        (math.sin(angle).abs() * width + math.cos(angle).abs() * height) / 2;
    final center = Offset(
      _clampCenter(overlay.x * size.width, halfX, size.width),
      _clampCenter(overlay.y * size.height, halfY, size.height),
    );
    return TextOverlayLayout(
      painter: painter,
      bounds: Rect.fromCenter(center: center, width: width, height: height),
      center: center,
    );
  }

  static double _clampCenter(double value, double halfExtent, double extent) {
    if (halfExtent >= extent / 2) return extent / 2;
    return value.clamp(halfExtent, extent - halfExtent).toDouble();
  }

  static TextOverlay moveBy(
    TextOverlay overlay,
    Size size,
    Offset delta,
  ) {
    final current = layout(overlay, size);
    final position = current.center + delta;
    current.dispose();
    final moved = overlay.copyWith(
      x: position.dx / size.width,
      y: position.dy / size.height,
    );
    final clamped = layout(moved, size);
    final result = moved.copyWith(
      x: clamped.center.dx / size.width,
      y: clamped.center.dy / size.height,
    );
    clamped.dispose();
    return result;
  }

  static void paint(Canvas canvas, Size size, Iterable<TextOverlay> overlays) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (final overlay in overlays) {
      final item = layout(overlay, size);
      final angle = overlay.rotation * math.pi / 180;
      canvas.save();
      canvas.translate(item.center.dx, item.center.dy);
      canvas.rotate(angle);
      final localRect = Rect.fromCenter(
        center: Offset.zero,
        width: item.bounds.width,
        height: item.bounds.height,
      );
      if (overlay.backgroundColor != null) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              localRect, Radius.circular(6 * scaleFor(size))),
          Paint()..color = Color(overlay.backgroundColor!),
        );
      }
      item.painter.paint(
        canvas,
        Offset(localRect.left + 8 * scaleFor(size),
            localRect.top + 8 * scaleFor(size)),
      );
      canvas.restore();
      item.dispose();
    }
    canvas.restore();
  }
}
