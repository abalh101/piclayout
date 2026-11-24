import '../../stickers/sticker_layer.dart';
import '../../stickers/sticker_sheet.dart';
import 'styled_collage_scene.dart';
import 'freestyle_layer.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';

import '../models/text_overlay.dart';
import '../models/photo_transform.dart';
import '../rendering/crop_geometry.dart';
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
  double _gestureScale = 1;
  final _gridPointers = <int>{};
  bool _gridGesturing = false;

  void _endGridPointer(PointerEvent event) {
    _gridPointers.remove(event.pointer);
    if (_gridPointers.isEmpty && _gridGesturing) {
      _gridGesturing = false;
      controller.endInteractiveTransform();
    }
  }

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
              final cells = project.freestyle
                  ? const <ResolvedLayoutCell>[]
                  : LayoutGeometry.resolve(project, size);
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
                child: Listener(
                    onPointerDown: project.freestyle
                        ? null
                        : (event) => _gridPointers.add(event.pointer),
                    onPointerUp: _endGridPointer,
                    onPointerCancel: _endGridPointer,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                            child: IgnorePointer(
                                child: StyledCollageScene(
                                    project: project,
                                    showMissingPhotoWarning: true))),
                        if (project.freestyle)
                          FreestyleLayer(
                              controller: controller,
                              size: size,
                              onEditPhoto: widget.onEditPhoto),
                        for (final cell in cells)
                          if (cell.photoIndex < project.photos.length)
                            _PhotoCell(
                              key: ValueKey(project.photos[cell.photoIndex].id),
                              label:
                                  '${AppLocalizations.of(context).photo} ${cell.photoIndex + 1}',
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
                                _gestureScale = 1;
                                _gridGesturing = true;
                                controller.selectPhoto(photo.id);
                                controller.beginInteractiveTransform();
                              },
                              onScaleUpdate: (details) {
                                final photo =
                                    controller.project.photos[cell.photoIndex];
                                final current = photo.transform;
                                final metadata = photo.metadata;
                                final change = details.scale / _gestureScale;
                                _gestureScale = details.scale;
                                if (current.fitMode == PhotoFitMode.fit ||
                                    metadata == null ||
                                    !change.isFinite) {
                                  return;
                                }
                                controller.updateTransformLive(
                                  photo.id,
                                  CropGeometry.gesture(
                                    cell.rect,
                                    Size(metadata.width.toDouble(),
                                        metadata.height.toDouble()),
                                    current,
                                    focalPoint: cell.rect.topLeft +
                                        details.localFocalPoint,
                                    focalDelta: details.focalPointDelta,
                                    scaleChange: change,
                                  ),
                                );
                              },
                            ),
                        _TextOverlayLayer(
                          controller: controller,
                          size: size,
                          onEditText: widget.onEditText,
                        ),
                        StickerLayer(
                            controller: controller,
                            size: size,
                            onEdit: () =>
                                showStickerEditor(context, controller)),
                      ],
                    )),
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
          for (final overlay in overlays)
            if (!overlay.hidden) _textHitTarget(context, overlay),
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
          onDoubleTap: overlay.locked
              ? null
              : () {
                  controller.selectText(overlay.id);
                  onEditText?.call();
                },
          onPanStart: overlay.locked
              ? null
              : (details) =>
                  controller.beginTextDrag(overlay.id, details.globalPosition),
          onPanUpdate: overlay.locked
              ? null
              : (details) =>
                  controller.updateTextDrag(details.globalPosition, size),
          onPanEnd: overlay.locked ? null : (_) => controller.endTextDrag(),
          onPanCancel: overlay.locked ? null : controller.endTextDrag,
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
      {super.key,
      required this.label,
      required this.rect,
      required this.cornerRadius,
      required this.selected,
      required this.onTap,
      required this.onScaleStart,
      required this.onScaleUpdate});
  final String label;
  final Rect rect;
  final double cornerRadius;
  final bool selected;
  final VoidCallback onTap, onScaleStart;
  final ValueChanged<ScaleUpdateDetails> onScaleUpdate;
  @override
  Widget build(BuildContext context) => Positioned.fromRect(
      rect: rect,
      child: Semantics(
          button: true,
          selected: selected,
          label: label,
          child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              onScaleStart: (_) => onScaleStart(),
              onScaleUpdate: onScaleUpdate,
              child: DecoratedBox(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(cornerRadius),
                      border: selected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2)
                          : null)))));
}
