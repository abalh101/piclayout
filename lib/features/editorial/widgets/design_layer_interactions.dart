import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../collage_editor/models/photo_transform.dart';
import '../../collage_editor/state/collage_editor_controller.dart';
import '../models/editorial_design.dart';
import '../rendering/editorial_renderer.dart';

/// Hit targets and guides only. Nothing in this widget is used by export.
class DesignLayerInteractions extends StatefulWidget {
  const DesignLayerInteractions(
      {required this.controller,
      required this.size,
      required this.onEditLayer,
      this.onEditPhoto,
      super.key});
  final CollageEditorController controller;
  final Size size;
  final VoidCallback onEditLayer;
  final VoidCallback? onEditPhoto;
  @override
  State<DesignLayerInteractions> createState() =>
      _DesignLayerInteractionsState();
}

class _DesignLayerInteractionsState extends State<DesignLayerInteractions> {
  DesignLayer? _start;
  Offset _focal = Offset.zero;
  PhotoTransform? _photoStart;
  CollageEditorController get c => widget.controller;
  @override
  Widget build(BuildContext context) {
    final selected = c.selectedDesignLayer;
    return Positioned.fill(
        child: Stack(clipBehavior: Clip.hardEdge, children: [
      for (final layer in c.project.design.ordered)
        if (layer.visible && layer.opacity > 0) _target(context, layer),
      if (selected != null && selected.visible) ...[
        if (selected.type == DesignLayerType.callout)
          Positioned.fill(
              child: IgnorePointer(
                  child: CustomPaint(painter: _SourceGuide(c, selected)))),
        if (!selected.locked && !c.editingDesignCrop)
          _handle(context, selected, resize: true),
        if (!selected.locked && !c.editingDesignCrop)
          _handle(context, selected, resize: false),
      ],
    ]));
  }

  Widget _target(BuildContext context, DesignLayer layer) {
    final r = EditorialRenderer.bounds(layer, widget.size);
    final selected = c.selectedDesignLayerId == layer.id;
    final label = AppLocalizations.of(context).tr('edType_${layer.type.name}');
    return Positioned.fromRect(
        rect: Rect.fromCenter(
            center: r.center,
            width: math.max(36, r.width),
            height: math.max(36, r.height)),
        child: Transform.rotate(
            angle: layer.rotation * math.pi / 180,
            child: Semantics(
                label: layer.isText ? '$label: ${layer.text.text}' : label,
                selected: selected,
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => c.selectDesignLayer(layer.id),
                  onDoubleTap: () {
                    c.selectDesignLayer(layer.id);
                    if (layer.isPhoto &&
                        layer.type != DesignLayerType.callout) {
                      widget.onEditPhoto?.call();
                    } else {
                      widget.onEditLayer();
                    }
                  },
                  onLongPress: () {
                    c.selectDesignLayer(layer.id);
                    widget.onEditLayer();
                  },
                  onScaleStart: layer.locked
                      ? null
                      : (d) {
                          final crop = c.editingDesignCrop && selected;
                          if (!selected) c.selectDesignLayer(layer.id);
                          c.setDesignCropEditing(crop);
                          _start = layer;
                          _focal = d.focalPoint;
                          _photoStart =
                              layer.source(c.project.photos)?.transform;
                          c.beginInteractiveTransform();
                        },
                  onScaleUpdate: layer.locked
                      ? null
                      : (d) {
                          final start = _start;
                          if (start == null) return;
                          final delta = d.focalPoint - _focal;
                          if (c.editingDesignCrop &&
                              start.type != DesignLayerType.callout &&
                              _photoStart != null) {
                            final local = EditorialRenderer.rotatePoint(
                                delta, Offset.zero, -start.rotation);
                            c.updateTransformLive(
                                start.source(c.project.photos)!.id,
                                _photoStart!.copyWith(
                                    scale: _photoStart!.scale * d.scale,
                                    offsetX: _photoStart!.offsetX +
                                        local.dx / r.width,
                                    offsetY: _photoStart!.offsetY +
                                        local.dy / r.height));
                          } else if (d.pointerCount > 1 &&
                              start.isPhoto &&
                              start.type != DesignLayerType.callout &&
                              _photoStart != null) {
                            c.updateTransformLive(
                                start.source(c.project.photos)!.id,
                                _photoStart!.copyWith(
                                    scale: _photoStart!.scale * d.scale));
                          } else {
                            c.updateDesignLayer(
                                start.copyWith(
                                    x: start.x + delta.dx / widget.size.width,
                                    y: start.y + delta.dy / widget.size.height,
                                    width: start.width *
                                        (start.isPhoto ? 1 : d.scale),
                                    height: start.height *
                                        (start.isPhoto ? 1 : d.scale),
                                    rotation: start.rotation +
                                        d.rotation * 180 / math.pi),
                                live: true);
                          }
                        },
                  onScaleEnd: layer.locked
                      ? null
                      : (_) {
                          c.endInteractiveTransform();
                          _start = null;
                        },
                  child: Center(
                      child: SizedBox(
                          width: r.width,
                          height: r.height,
                          child: DecoratedBox(
                              decoration: BoxDecoration(
                                  border: selected
                                      ? Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          width: 2)
                                      : null),
                              child: selected && layer.locked
                                  ? const Align(
                                      alignment: Alignment.topRight,
                                      child: Icon(Icons.lock, size: 18))
                                  : null))),
                ))));
  }

  Widget _handle(BuildContext context, DesignLayer layer,
      {required bool resize}) {
    final r = EditorialRenderer.bounds(layer, widget.size);
    final center = EditorialRenderer.rotatePoint(
        resize ? r.bottomRight : r.topCenter, r.center, layer.rotation);
    return Positioned(
        left: (center.dx - 24).clamp(0, math.max(0, widget.size.width - 48)),
        top: (center.dy - 24).clamp(0, math.max(0, widget.size.height - 48)),
        width: 48,
        height: 48,
        child: Tooltip(
            message:
                AppLocalizations.of(context).tr(resize ? 'edResize' : 'rotate'),
            child: Semantics(
                label: AppLocalizations.of(context)
                    .tr(resize ? 'edResize' : 'rotate'),
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (d) {
                    _start = layer;
                    _focal = d.globalPosition;
                    c.beginInteractiveTransform();
                  },
                  onPanUpdate: (d) {
                    final s = _start;
                    if (s == null) return;
                    final delta = d.globalPosition - _focal;
                    if (resize) {
                      final local = EditorialRenderer.rotatePoint(
                          delta, Offset.zero, -s.rotation);
                      c.updateDesignLayer(
                          s.copyWith(
                              width: s.width + local.dx * 2 / widget.size.width,
                              height:
                                  s.height + local.dy * 2 / widget.size.height),
                          live: true);
                    } else {
                      c.updateDesignLayer(
                          s.copyWith(rotation: s.rotation + delta.dx * .8),
                          live: true);
                    }
                  },
                  onPanEnd: (_) => c.endInteractiveTransform(),
                  onPanCancel: c.endInteractiveTransform,
                  child: Center(
                      child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle),
                          child: Icon(
                              resize ? Icons.open_in_full : Icons.rotate_right,
                              size: 16,
                              color: Colors.white))),
                ))));
  }
}

class _SourceGuide extends CustomPainter {
  _SourceGuide(this.controller, this.layer);
  final CollageEditorController controller;
  final DesignLayer layer;
  @override
  void paint(Canvas canvas, Size size) {
    final main = EditorialRenderer.mainPhoto(controller.project, layer);
    final photo = layer.source(controller.project.photos);
    if (main == null || photo?.metadata == null) return;
    final source = Size(
        photo!.metadata!.width.toDouble(), photo.metadata!.height.toDouble());
    final points = [
      layer.crop.topLeft,
      layer.crop.topRight,
      layer.crop.bottomRight,
      layer.crop.bottomLeft
    ]
        .map((p) => EditorialRenderer.sourcePoint(main, photo, source, size, p))
        .toList();
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawPath(
        Path()..addPolygon(points, true),
        Paint()
          ..color = Colors.cyanAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SourceGuide old) => true;
}
