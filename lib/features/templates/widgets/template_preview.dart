import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../collage_editor/models/photo_asset.dart';
import '../../collage_editor/rendering/layout_geometry.dart';
import '../../collage_editor/rendering/style_renderer.dart';
import '../../collage_editor/rendering/text_overlay_renderer.dart';
import '../../editorial/rendering/editorial_renderer.dart';
import '../../projects/models/collage_project.dart';
import '../../stickers/sticker_renderer.dart';
import '../models/collage_template.dart';

/// Structured style/layout preview. Placeholder cells never read user images.
class TemplatePreview extends StatelessWidget {
  const TemplatePreview({super.key, required this.template});
  final CollageTemplate template;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 56,
      height: 64,
      child: RepaintBoundary(
          child: CustomPaint(painter: _PreviewPainter(template))));
}

class _PreviewPainter extends CustomPainter {
  _PreviewPainter(this.template);
  final CollageTemplate template;
  // Tiny vector recordings only, with no file or decoded image references.
  static final _pictures = <String, ui.Picture>{};
  @override
  void paint(Canvas canvas, Size size) {
    final key = '${jsonEncode(template.toJson())}|$size';
    var picture = _pictures.remove(key);
    if (picture == null) {
      final recorder = ui.PictureRecorder();
      final c = Canvas(recorder);
      final base = CollageProject(
          id: '',
          name: '',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          formatVersion: 1,
          aspectRatioId: template.aspectRatioId,
          layoutTemplateId: template.layoutTemplateId,
          photos: [
            for (var i = 0; i < template.photoCount.clamp(1, 20); i++)
              PhotoAsset(
                  id: 'placeholder-$i', originalFileName: '', localPath: ''),
          ]);
      try {
        final project = template.applyTo(base);
        final ratio = project.aspectRatio.value;
        final target = ratio > size.aspectRatio
            ? Size(size.width, size.width / ratio)
            : Size(size.height * ratio, size.height);
        c.translate(
            (size.width - target.width) / 2, (size.height - target.height) / 2);
        c.clipRect(Offset.zero & target);
        StyleRenderer.background(c, target, project.canvas);
        if (project.design.active) {
          for (final layer in project.design.ordered) {
            EditorialRenderer.paintLayer(c, target, project, layer);
          }
        } else {
          final cells = LayoutGeometry.resolve(project, target);
          StyleRenderer.shadows(c, target, project.canvas, cells);
          for (final cell in cells) {
            c.drawRRect(
                RRect.fromRectAndRadius(
                    cell.rect, Radius.circular(cell.cornerRadius)),
                Paint()
                  ..color = Color.lerp(const Color(0xFF80969F),
                      const Color(0xFFD5DED8), (cell.photoIndex % 4) / 3)!);
          }
          StyleRenderer.frames(c, target, project.canvas, cells);
        }
        TextOverlayRenderer.paint(c, target, project.textOverlays);
        StickerRenderer.paint(c, target, project.stickers);
      } catch (_) {
        // A future/invalid template can still be selected using its name.
        c.drawRect(
            Offset.zero & size, Paint()..color = const Color(0xFFBAC4CA));
      }
      picture = recorder.endRecording();
    }
    _pictures[key] = picture;
    if (_pictures.length > 32) {
      _pictures.remove(_pictures.keys.first)!.dispose();
    }
    canvas.drawPicture(picture);
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter oldDelegate) =>
      template != oldDelegate.template;
}
