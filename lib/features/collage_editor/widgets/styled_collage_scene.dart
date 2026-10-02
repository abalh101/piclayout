import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../projects/models/collage_project.dart';
import '../models/canvas_style.dart';
import '../rendering/layout_geometry.dart';
import '../rendering/project_image_loader.dart';
import '../rendering/style_renderer.dart';

/// Decodes only when file paths change, never when style sliders move.
class StyledCollageScene extends StatefulWidget {
  const StyledCollageScene({required this.project, super.key});
  final CollageProject project;
  @override
  State<StyledCollageScene> createState() => _StyledCollageSceneState();
}

class _StyledCollageSceneState extends State<StyledCollageScene> {
  final _images = <String, ui.Image>{};
  final _requests = <String, Object>{};
  final _failed = <String>{};
  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant StyledCollageScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final paths = widget.project.photos.map((p) => p.localPath).toSet();
    for (final path in _images.keys.toList()) {
      if (!paths.contains(path)) _images.remove(path)?.dispose();
    }
    _requests.removeWhere((path, _) => !paths.contains(path));
    _failed.removeWhere((path) => !paths.contains(path));
    for (final path in paths) {
      if (_images.containsKey(path) ||
          _requests.containsKey(path) ||
          _failed.contains(path)) {
        continue;
      }
      final token = Object();
      _requests[path] = token;
      _load(path, token);
    }
  }

  Future<void> _load(String path, Object token) async {
    try {
      final image = await loadProjectImage(path, maxEdge: 1024);
      if (!mounted || _requests[path] != token) {
        image.dispose();
        return;
      }
      setState(() {
        _requests.remove(path);
        _images[path] = image;
      });
    } catch (_) {
      if (mounted && _requests[path] == token) {
        setState(() {
          _requests.remove(path);
          _failed.add(path);
        });
      }
    }
  }

  @override
  void dispose() {
    for (final image in _images.values) {
      image.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
      painter: _ScenePainter(widget.project, Map.of(_images), Set.of(_failed)));
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.project, this.images, this.failed);
  final CollageProject project;
  final Map<String, ui.Image> images;
  final Set<String> failed;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    if (project.canvas.style.backgroundType == BackgroundType.transparent) {
      canvas.drawColor(const Color(0xFFECECEC), BlendMode.srcOver);
      for (double y = 0; y < size.height; y += 12) {
        for (double x = 0; x < size.width; x += 12) {
          if (((x / 12).floor() + (y / 12).floor()).isEven) {
            canvas.drawRect(Rect.fromLTWH(x, y, 12, 12),
                Paint()..color = const Color(0xFFCCCCCC));
          }
        }
      }
    }
    final photos = project.photos;
    final backdrop = photos.isEmpty
        ? null
        : images[photos[
                StyleRenderer.photoIndex(project.canvas.style, photos.length)]
            .localPath];
    StyleRenderer.background(canvas, size, project.canvas, image: backdrop);
    final cells = LayoutGeometry.resolve(project, size);
    StyleRenderer.shadows(canvas, size, project.canvas, cells);
    for (final cell in cells) {
      if (cell.photoIndex >= photos.length) continue;
      final photo = photos[cell.photoIndex];
      final image = images[photo.localPath];
      if (image != null) {
        StyleRenderer.photo(
            canvas, image, cell.rect, cell.cornerRadius, photo.transform);
      } else {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                cell.rect, Radius.circular(cell.cornerRadius)),
            Paint()
              ..color = failed.contains(photo.localPath)
                  ? const Color(0xFFFFCDD2)
                  : const Color(0xFFE0E0E0));
      }
    }
    StyleRenderer.frames(canvas, size, project.canvas, cells);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) => true;
}
