import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'sticker_overlay.dart';

/// Shared by live canvas, picker and original-resolution export.
class StickerRenderer {
  static const icons = <String, IconData>{
    'left': Icons.arrow_back,
    'right': Icons.arrow_forward,
    'up': Icons.arrow_upward,
    'down': Icons.arrow_downward,
    'heart': Icons.favorite,
    'star': Icons.star,
    'pin': Icons.location_on,
    'camera': Icons.camera_alt,
    'celebration': Icons.celebration,
  };
  static Size extent(StickerOverlay sticker, Size canvas) {
    final unit = canvas.shortestSide * .22 * sticker.scale;
    return Size(unit * (sticker.type == StickerType.label ? 2 : 1), unit);
  }

  static Rect bounds(StickerOverlay sticker, Size canvas) => Rect.fromCenter(
      center: Offset(sticker.x * canvas.width, sticker.y * canvas.height),
      width: extent(sticker, canvas).width,
      height: extent(sticker, canvas).height);

  static void paint(Canvas canvas, Size size, List<StickerOverlay> stickers) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (final sticker in stickers) {
      final extent = StickerRenderer.extent(sticker, size);
      canvas.save();
      canvas.translate(sticker.x * size.width, sticker.y * size.height);
      canvas.rotate(sticker.rotation * math.pi / 180);
      canvas.scale(
          extent.width / (sticker.type == StickerType.label ? 200 : 100),
          extent.height / 100);
      final rect = Rect.fromCenter(
          center: Offset.zero,
          width: sticker.type == StickerType.label ? 200 : 100,
          height: 100);
      canvas.saveLayer(rect.inflate(2),
          Paint()..color = Colors.white.withValues(alpha: sticker.opacity));
      if (sticker.backgroundColor case final background?) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(14)),
            Paint()..color = Color(background));
      }
      final paint = Paint()..color = Color(sticker.color);
      switch (sticker.type) {
        case StickerType.shape:
          switch (sticker.content) {
            case 'circle':
              canvas.drawOval(rect, paint);
            case 'rectangle':
              canvas.drawRect(rect, paint);
            case 'rounded':
              canvas.drawRRect(
                  RRect.fromRectAndRadius(rect, const Radius.circular(18)),
                  paint);
            case 'line':
              canvas.drawRRect(
                  RRect.fromRectAndRadius(const Rect.fromLTWH(-50, -4, 100, 8),
                      const Radius.circular(4)),
                  paint);
            case 'bubble':
              canvas.drawRRect(
                  RRect.fromRectAndRadius(const Rect.fromLTWH(-48, -45, 96, 72),
                      const Radius.circular(16)),
                  paint);
              canvas.drawPath(
                  Path()
                    ..moveTo(-25, 20)
                    ..lineTo(-30, 48)
                    ..lineTo(5, 20)
                    ..close(),
                  paint);
          }
        case StickerType.icon:
          final icon = icons[sticker.content];
          if (icon != null) {
            _text(canvas, String.fromCharCode(icon.codePoint), rect, 94,
                Color(sticker.color),
                fontFamily: icon.fontFamily, fontPackage: icon.fontPackage);
          }
        case StickerType.emoji:
          _text(canvas, sticker.content, rect, 78, Color(sticker.color));
        case StickerType.label:
          _text(canvas, sticker.content, rect.deflate(10), 32,
              Color(sticker.color));
      }
      canvas.restore();
      canvas.restore();
    }
    canvas.restore();
  }

  static void _text(
      Canvas canvas, String content, Rect rect, double fontSize, Color color,
      {String? fontFamily, String? fontPackage}) {
    final rtl = RegExp(r'[\u0590-\u08ff]').hasMatch(content);
    final painter = TextPainter(
        text: TextSpan(
            text: content,
            style: TextStyle(
                color: color,
                fontSize: fontSize,
                fontFamily: fontFamily,
                package: fontPackage,
                fontWeight: fontFamily == null ? FontWeight.w600 : null)),
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 2,
        ellipsis: '…')
      ..layout(maxWidth: rect.width);
    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
    painter.dispose();
  }
}

class StickerPainter extends CustomPainter {
  const StickerPainter(this.stickers);
  final List<StickerOverlay> stickers;
  @override
  void paint(Canvas canvas, Size size) =>
      StickerRenderer.paint(canvas, size, stickers);
  @override
  bool shouldRepaint(covariant StickerPainter oldDelegate) =>
      oldDelegate.stickers != stickers;
}
