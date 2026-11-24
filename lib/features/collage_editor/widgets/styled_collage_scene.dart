import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/localization/app_localizations.dart';
import '../../projects/models/collage_project.dart';
import '../models/canvas_style.dart';
import '../models/canvas_settings.dart';
import '../rendering/layout_geometry.dart';
import '../rendering/project_image_loader.dart';
import '../rendering/style_renderer.dart';
import '../rendering/photo_detail_renderer.dart';
import '../rendering/text_overlay_renderer.dart';
import '../../stickers/sticker_renderer.dart';

/// Decodes only when file paths change, never when style sliders move.
class StyledCollageScene extends StatefulWidget {
  const StyledCollageScene(
      {required this.project,
      this.showOverlays = false,
      this.opaque = false,
      this.showMissingPhotoWarning = false,
      this.maxEdge = 1024,
      super.key});
  final CollageProject project;
  final bool showOverlays;
  final bool opaque;
  final bool showMissingPhotoWarning;
  final int maxEdge;
  @override
  State<StyledCollageScene> createState() => _StyledCollageSceneState();
}

class _StyledCollageSceneState extends State<StyledCollageScene> {
  final _images = <String, ui.Image>{};
  final _requests = <String, Object>{};
  final _failed = <String>{};
  int _activeLoads = 0;
  bool _detailRequested = false;
  ui.FragmentProgram? _detailProgram;
  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant StyledCollageScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.project.photos, widget.project.photos)) _sync();
  }

  void _sync() {
    if (!_detailRequested &&
        widget.project.photos.any((photo) => photo.adjustments.usesDetail)) {
      _detailRequested = true;
      _loadDetailProgram();
    }
    final paths = widget.project.photos.map((p) => p.localPath).toSet();
    for (final path in _images.keys.toList()) {
      if (!paths.contains(path)) _images.remove(path)?.dispose();
    }
    _requests.removeWhere((path, _) => !paths.contains(path));
    _failed.removeWhere((path) => !paths.contains(path));
    for (final path in paths) {
      if (_activeLoads >= 2) break;
      if (_images.containsKey(path) ||
          _requests.containsKey(path) ||
          _failed.contains(path)) {
        continue;
      }
      final token = Object();
      _requests[path] = token;
      _activeLoads++;
      _load(path, token);
    }
  }

  Future<void> _loadDetailProgram() async {
    try {
      final program = await PhotoDetailRenderer.load();
      if (mounted) setState(() => _detailProgram = program);
    } catch (_) {
      // Basic filters still render if the platform cannot load the shader.
    }
  }

  Future<void> _load(String path, Object token) async {
    try {
      final image = await loadProjectImage(path, maxEdge: widget.maxEdge);
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
    } finally {
      _activeLoads--;
      if (mounted) _sync();
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
  Widget build(BuildContext context) {
    final photo = StyleRenderer.backdropPhoto(widget.project);
    final missing = widget.showMissingPhotoWarning &&
        widget.project.photos.any((item) =>
            _failed.contains(item.localPath) &&
            (!widget.project.freestyle || item.placement?.hidden != true));
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
            child: CustomPaint(
          painter: _BackgroundPainter(
              widget.project.canvas, _images[photo?.localPath], widget.opaque),
        )),
        if (missing)
          PositionedDirectional(
            top: 6,
            start: 6,
            child: Tooltip(
              message: AppLocalizations.of(context).tr('exportUnreadablePhoto'),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 17,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    )),
              ),
            ),
          ),
        RepaintBoundary(
            child: CustomPaint(
          painter: _ScenePainter(
            widget.project,
            Map.of(_images),
            Set.of(_failed),
            widget.showOverlays,
            _detailProgram,
          ),
        )),
      ],
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  const _BackgroundPainter(this.settings, this.image, this.opaque);
  final CanvasSettings settings;
  final ui.Image? image;
  final bool opaque;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    if (!opaque &&
        settings.style.backgroundType == BackgroundType.transparent) {
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
    StyleRenderer.background(canvas, size, settings,
        image: image, opaque: opaque);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter old) =>
      old.settings != settings || old.image != image || old.opaque != opaque;
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.project, this.images, this.failed, this.showOverlays,
      this.detailProgram);
  final CollageProject project;
  final Map<String, ui.Image> images;
  final ui.FragmentProgram? detailProgram;
  final Set<String> failed;
  final bool showOverlays;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final photos = project.photos;
    Color placeholder(String path) => failed.contains(path)
        ? const Color(0xFFFFCDD2)
        : const Color(0xFFE0E0E0);
    if (project.freestyle) {
      for (final photo in photos) {
        StyleRenderer.freestylePhoto(
            canvas, size, photo, images[photo.localPath],
            placeholder: placeholder(photo.localPath),
            detailProgram: detailProgram);
      }
    } else {
      final cells = LayoutGeometry.resolve(project, size);
      StyleRenderer.shadows(canvas, size, project.canvas, cells);
      for (final cell in cells) {
        if (cell.photoIndex >= photos.length) continue;
        final photo = photos[cell.photoIndex];
        final image = images[photo.localPath];
        if (image != null) {
          StyleRenderer.photo(
              canvas, image, cell.rect, cell.cornerRadius, photo.transform,
              adjustments: photo.adjustments, detailProgram: detailProgram);
        } else {
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  cell.rect, Radius.circular(cell.cornerRadius)),
              Paint()..color = placeholder(photo.localPath));
        }
      }
      StyleRenderer.frames(canvas, size, project.canvas, cells);
    }
    if (showOverlays) {
      TextOverlayRenderer.paint(canvas, size, project.textOverlays);
      StickerRenderer.paint(canvas, size, project.stickers);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ScenePainter old) =>
      !identical(old.project, project) ||
      old.showOverlays != showOverlays ||
      old.detailProgram != detailProgram ||
      !mapEquals(old.images, images) ||
      !setEquals(old.failed, failed);
}
