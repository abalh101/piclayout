import 'styled_collage_scene.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/text_overlay.dart';
import '../rendering/layout_geometry.dart';
import '../rendering/text_overlay_renderer.dart';
import '../state/collage_editor_controller.dart';

class CollageCanvas extends StatefulWidget {
  const CollageCanvas({
    required this.controller,
    this.onEditText,
    this.onEditPhoto,
    super.key,
  });

  final CollageEditorController controller;
  final VoidCallback? onEditText;
  final VoidCallback? onEditPhoto;

  @override
  State<CollageCanvas> createState() => _CollageCanvasState();
}

class _CollageCanvasState extends State<CollageCanvas> {
  double _gestureStartScale = 1;

  CollageEditorController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final project = controller.project;
        return AspectRatio(
          aspectRatio: project.aspectRatio.value,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              final cells = LayoutGeometry.resolve(project, size);
              return DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                        child: IgnorePointer(
                            child: StyledCollageScene(project: project))),
                    for (final cell in cells)
                      if (cell.photoIndex < project.photos.length)
                        _PhotoCell(
                          rect: cell.rect,
                          cornerRadius: cell.cornerRadius,
                          selected: controller.selectedPhotoId ==
                              project.photos[cell.photoIndex].id,
                          onTap: () {
                            controller.selectPhoto(
                                project.photos[cell.photoIndex].id);
                            widget.onEditPhoto?.call();
                          },
                          onScaleStart: () {
                            final photo = project.photos[cell.photoIndex];
                            _gestureStartScale = photo.transform.scale;
                            controller.selectPhoto(photo.id);
                            controller.beginInteractiveTransform();
                          },
                          onScaleUpdate: (details) {
                            final photo =
                                controller.project.photos[cell.photoIndex];
                            final current = photo.transform;
                            controller.updateTransformLive(
                              photo.id,
                              current.copyWith(
                                scale: (_gestureStartScale * details.scale)
                                    .clamp(0.6, 5.0)
                                    .toDouble(),
                                offsetX: (current.offsetX +
                                        details.focalPointDelta.dx /
                                            cell.rect.width)
                                    .clamp(-1.5, 1.5)
                                    .toDouble(),
                                offsetY: (current.offsetY +
                                        details.focalPointDelta.dy /
                                            cell.rect.height)
                                    .clamp(-1.5, 1.5)
                                    .toDouble(),
                              ),
                            );
                          },
                          onScaleEnd: controller.endInteractiveTransform,
                        ),
                    _TextOverlayLayer(
                      controller: controller,
                      size: size,
                      onEditText: widget.onEditText,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _TextOverlayLayer extends StatelessWidget {
  const _TextOverlayLayer({
    required this.controller,
    required this.size,
    this.onEditText,
  });

  final CollageEditorController controller;
  final Size size;
  final VoidCallback? onEditText;

  @override
  Widget build(BuildContext context) {
    final overlays = controller.project.textOverlays;
    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _TextPainter(overlays),
              ),
            ),
          ),
          for (final overlay in overlays) _textHitTarget(context, overlay),
        ],
      ),
    );
  }

  Widget _textHitTarget(BuildContext context, TextOverlay overlay) {
    final layout = TextOverlayRenderer.layout(overlay, size);
    final bounds = layout.bounds;
    layout.dispose();
    final selected = controller.selectedTextId == overlay.id;
    return Positioned.fromRect(
      rect: bounds,
      child: Transform.rotate(
        angle: overlay.rotation * math.pi / 180,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => controller.selectText(overlay.id),
          onDoubleTap: () {
            controller.selectText(overlay.id);
            onEditText?.call();
          },
          onPanStart: (details) =>
              controller.beginTextDrag(overlay.id, details.globalPosition),
          onPanUpdate: (details) =>
              controller.updateTextDrag(details.globalPosition, size),
          onPanEnd: (_) => controller.endTextDrag(),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: selected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _TextPainter extends CustomPainter {
  const _TextPainter(this.overlays);

  final List<TextOverlay> overlays;

  @override
  void paint(Canvas canvas, Size size) {
    TextOverlayRenderer.paint(canvas, size, overlays);
  }

  @override
  bool shouldRepaint(covariant _TextPainter oldDelegate) =>
      oldDelegate.overlays != overlays;
}

class _PhotoCell extends StatelessWidget {
  const _PhotoCell(
      {required this.rect,
      required this.cornerRadius,
      required this.selected,
      required this.onTap,
      required this.onScaleStart,
      required this.onScaleUpdate,
      required this.onScaleEnd});
  final Rect rect;
  final double cornerRadius;
  final bool selected;
  final VoidCallback onTap, onScaleStart, onScaleEnd;
  final ValueChanged<ScaleUpdateDetails> onScaleUpdate;
  @override
  Widget build(BuildContext context) => Positioned.fromRect(
      rect: rect,
      child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onScaleStart: (_) => onScaleStart(),
          onScaleUpdate: onScaleUpdate,
          onScaleEnd: (_) => onScaleEnd(),
          child: DecoratedBox(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(cornerRadius),
                  border: selected
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2)
                      : null))));
}
