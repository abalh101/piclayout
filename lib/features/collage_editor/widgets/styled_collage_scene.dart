import 'dart:ui' as ui;
import '../../editorial/rendering/editorial_renderer.dart';
import '../../editorial/models/editorial_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/localization/app_localizations.dart';
import '../../projects/models/collage_project.dart';
import '../models/canvas_style.dart';
import '../rendering/layout_geometry.dart';
import '../rendering/preview_image_cache.dart';
import '../rendering/style_renderer.dart';

/// Decodes only when file paths change, never when style sliders move.
class StyledCollageScene extends StatefulWidget {
  const StyledCollageScene({required this.project, this.imageCache, super.key});
  final CollageProject project;
  final PreviewImageCache? imageCache;
  @override
  State<StyledCollageScene> createState() => _StyledCollageSceneState();
}

class _StyledCollageSceneState extends State<StyledCollageScene> {
  late final _cache = widget.imageCache ?? PreviewImageCache();
  final _images = <String, ui.Image>{};
  final _sourceSizes = <String, Size>{};
  final _requests = <String, Object>{};
  final _failed = <String>{};
  final _leases = <String, PreviewImageLease>{};
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
    final project = widget.project;
    final paths = project.isFreeform
        ? project.design.layers
            .where((l) => l.visible && l.opacity > 0 && l.isPhoto)
            .map((l) => l.source(project.photos)?.localPath)
            .whereType<String>()
            .toSet()
        : project.photos.map((p) => p.localPath).toSet();
    if (project.canvas.style.backgroundType == BackgroundType.blur &&
        project.photos.isNotEmpty) {
      paths.add(project
          .photos[StyleRenderer.photoIndex(
              project.canvas.style, project.photos.length)]
          .localPath);
    }
    for (final path in _leases.keys.toList()) {
      if (!paths.contains(path)) {
        _leases.remove(path)!.release();
        _images.remove(path);
        _sourceSizes.remove(path);
      }
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
      _leases[path] = _cache.acquire(path);
      _load(path, token);
    }
  }

  Future<void> _load(String path, Object token) async {
    try {
      final lease = _leases[path]!;
      final image = await lease.image;
      if (!mounted || _requests[path] != token) {
        return;
      }
      if (image == null) throw StateError('Photo unavailable');
      setState(() {
        _requests.remove(path);
        _images[path] = image;
        _sourceSizes[path] = lease.sourceSize!;
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
    for (final lease in _leases.values) {
      lease.release();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final cells =
            LayoutGeometry.resolve(widget.project, constraints.biggest);
        return Stack(fit: StackFit.expand, children: [
          CustomPaint(
              painter: _ScenePainter(widget.project, Map.of(_images),
                  Map.of(_sourceSizes), Set.of(_failed))),
          if (widget.project.isFreeform)
            for (final layer in widget.project.design.ordered)
              if (layer.visible && layer.opacity > 0)
                Positioned.fill(
                    child: RepaintBoundary(
                  key: ValueKey('frame-paint-${layer.id}'),
                  child: CustomPaint(
                      painter: FreeformLayerPainter(
                          widget.project,
                          layer,
                          _images[
                              layer.source(widget.project.photos)?.localPath],
                          _sourceSizes[
                              layer.source(widget.project.photos)?.localPath])),
                )),
          if (widget.project.isFreeform)
            for (final layer in widget.project.design.ordered)
              if (layer.isPhoto &&
                  layer.visible &&
                  layer.opacity > 0 &&
                  !_images.containsKey(
                      layer.source(widget.project.photos)?.localPath))
                Positioned.fromRect(
                    rect: layer.rect(constraints.biggest),
                    child: IgnorePointer(
                        child: Center(
                            child: FittedBox(
                                child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            semanticLabel:
                                AppLocalizations.of(context).tr('ffFill')),
                        Text('${layer.photoSlot + 1}',
                            style: const TextStyle(color: Colors.black87))
                      ],
                    ))))),
          for (final cell in cells)
            if (!widget.project.isFreeform &&
                cell.photoIndex < widget.project.photos.length &&
                !_images.containsKey(
                    widget.project.photos[cell.photoIndex].localPath))
              Positioned.fromRect(
                  rect: cell.rect,
                  child: Center(
                      child: FittedBox(
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                        _failed.contains(widget
                                .project.photos[cell.photoIndex].localPath)
                            ? Icons.broken_image_outlined
                            : Icons.image_outlined,
                        color: Colors.black54,
                        semanticLabel: _failed.contains(widget
                                .project.photos[cell.photoIndex].localPath)
                            ? AppLocalizations.of(context).tr('photoLoadFailed')
                            : AppLocalizations.of(context).tr('recLoading')),
                    if (_failed.contains(
                        widget.project.photos[cell.photoIndex].localPath))
                      SizedBox(
                          width: 120,
                          child: Text(
                              AppLocalizations.of(context)
                                  .tr('photoLoadFailed'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.black87, fontSize: 12))),
                  ])))),
        ]);
      });
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.project, this.images, this.sourceSizes, this.failed);
  final CollageProject project;
  final Map<String, ui.Image> images;
  final Map<String, Size> sourceSizes;
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
    if (project.isFreeform) {
      canvas.restore();
      return;
    }
    if (project.design.active) {
      for (final layer in project.design.ordered) {
        final photo = layer.source(project.photos);
        EditorialRenderer.paintLayer(canvas, size, project, layer,
            image: images[photo?.localPath],
            sourceSize: _sizeFor(photo?.localPath));
      }
      canvas.restore();
      return;
    }
    final cells = LayoutGeometry.resolve(project, size);
    StyleRenderer.shadows(canvas, size, project.canvas, cells);
    for (final cell in cells) {
      if (cell.photoIndex >= photos.length) continue;
      final photo = photos[cell.photoIndex];
      final image = images[photo.localPath];
      if (image != null) {
        StyleRenderer.photo(
            canvas, image, cell.rect, cell.cornerRadius, photo.transform,
            adjustments: photo.adjustments,
            sourceSize: sourceSizes[photo.localPath]);
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
  bool shouldRepaint(covariant _ScenePainter oldDelegate) =>
      (project.isFreeform && oldDelegate.project.isFreeform
          ? project.canvas != oldDelegate.project.canvas ||
              project.photos != oldDelegate.project.photos
          : !identical(project, oldDelegate.project)) ||
      !mapEquals(images, oldDelegate.images) ||
      !mapEquals(sourceSizes, oldDelegate.sourceSizes) ||
      !setEquals(failed, oldDelegate.failed);

  Size? _sizeFor(String? path) => sourceSizes[path];
}

/// Each frame retains its own repaint boundary. Moving another frame changes
/// neither this painter's geometry nor its source/adjustment configuration.
class FreeformLayerPainter extends CustomPainter {
  const FreeformLayerPainter(
      this.project, this.layer, this.image, this.sourceSize);
  final CollageProject project;
  final DesignLayer layer;
  final ui.Image? image;
  final Size? sourceSize;
  @override
  void paint(Canvas canvas, Size size) =>
      EditorialRenderer.paintLayer(canvas, size, project, layer,
          image: image, sourceSize: sourceSize);
  @override
  bool shouldRepaint(covariant FreeformLayerPainter old) =>
      layer != old.layer ||
      image != old.image ||
      sourceSize != old.sourceSize ||
      layer.source(project.photos) != old.layer.source(old.project.photos) ||
      (!layer.isPhoto && project != old.project);
}
