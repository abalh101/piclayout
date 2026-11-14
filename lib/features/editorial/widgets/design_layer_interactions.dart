import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../collage_editor/models/photo_transform.dart';
import '../../collage_editor/state/collage_editor_controller.dart';
import '../models/editorial_design.dart';
import '../rendering/editorial_renderer.dart';
import '../rendering/freeform_snapping.dart';

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
  List<SnapGuide> _guides = [];
  CollageEditorController get c => widget.controller;
  @override
  Widget build(BuildContext context) {
    final selected = c.selectedDesignLayer;
    return Positioned.fill(
        child: Stack(clipBehavior: Clip.hardEdge, children: [
      if (c.project.isFreeform)
        Positioned.fill(
            child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: c.deselectFrame,
                child: const SizedBox.expand())),
      for (final layer in c.project.design.ordered)
        if (layer.visible && layer.opacity > 0) _target(context, layer),
      if (selected != null && selected.visible) ...[
        if (selected.type == DesignLayerType.callout)
          Positioned.fill(
              child: IgnorePointer(
                  child: CustomPaint(painter: _SourceGuide(c, selected)))),
        if (!selected.locked && !c.editingDesignCrop)
          _handle(context, selected, resize: true),
        if (c.project.isFreeform && !selected.locked && !c.editingDesignCrop)
          for (final corner in [
            const Offset(-1, -1),
            const Offset(1, -1),
            const Offset(-1, 1)
          ])
            _handle(context, selected, resize: true, corner: corner),
        if (!selected.locked && !c.editingDesignCrop)
          _handle(context, selected, resize: false),
      ],
      if (c.project.isFreeform)
        Positioned.fill(
            child: IgnorePointer(
                child: CustomPaint(
                    painter: _FreeformGuides(
                        _guides,
                        c.editingDesignCrop ? selected : null,
                        Theme.of(context).colorScheme.primary)))),
    ]));
  }

  Widget _target(BuildContext context, DesignLayer layer) {
    final r = EditorialRenderer.bounds(layer, widget.size);
    final selected = c.selectedDesignLayerId == layer.id;
    final label = c.project.isFreeform && layer.isPhoto
        ? '${AppLocalizations.of(context).tr('ffFrame')} ${layer.photoSlot + 1}'
        : AppLocalizations.of(context).tr('edType_${layer.type.name}');
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
                    if (c.project.isFreeform && layer.isPhoto) {
                      if (layer.source(c.project.photos) == null) {
                        widget.onEditLayer();
                      } else {
                        c.setDesignCropEditing(true);
                      }
                      return;
                    }
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
                          _photoStart = layer
                              .transformFor(layer.source(c.project.photos));
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
                              start.source(c.project.photos) != null &&
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
                              !c.project.isFreeform &&
                              start.isPhoto &&
                              start.type != DesignLayerType.callout &&
                              _photoStart != null) {
                            final photo = start.source(c.project.photos);
                            if (photo == null) return;
                            c.updateTransformLive(
                                photo.id,
                                _photoStart!.copyWith(
                                    scale: _photoStart!.scale * d.scale));
                          } else {
                            var next = start.copyWith(
                                x: start.x + delta.dx / widget.size.width,
                                y: start.y + delta.dy / widget.size.height,
                                width: start.width *
                                    (start.isPhoto && !c.project.isFreeform
                                        ? 1
                                        : d.scale),
                                height: start.height *
                                    (start.isPhoto && !c.project.isFreeform
                                        ? 1
                                        : d.scale),
                                rotation: start.rotation +
                                    d.rotation * 180 / math.pi);
                            if (c.project.isFreeform) {
                              final snap = FreeformSnapping.move(
                                  next, c.project.design.layers, widget.size);
                              next = snap.layer;
                              _guides = snap.guides;
                            }
                            c.updateDesignLayer(next, live: true);
                          }
                        },
                  onScaleEnd: layer.locked
                      ? null
                      : (_) {
                          c.endInteractiveTransform();
                          _start = null;
                          setState(() => _guides = []);
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
      {required bool resize, Offset corner = const Offset(1, 1)}) {
    final r = EditorialRenderer.bounds(layer, widget.size);
    final center = EditorialRenderer.rotatePoint(
        resize
            ? r.center +
                Offset(r.width * corner.dx / 2, r.height * corner.dy / 2)
            : r.topCenter,
        r.center,
        layer.rotation);
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
                      if (c.project.isFreeform) {
                        var width =
                            (s.width + local.dx * corner.dx / widget.size.width)
                                .clamp(.04, 1.5);
                        var height = (s.height +
                                local.dy * corner.dy / widget.size.height)
                            .clamp(.04, 1.5);
                        if (s.aspectLocked) {
                          final factor = ((width / s.width - 1).abs() >
                                      (height / s.height - 1).abs()
                                  ? width / s.width
                                  : height / s.height)
                              .clamp(math.max(.04 / s.width, .04 / s.height),
                                  math.min(1.5 / s.width, 1.5 / s.height));
                          width = s.width * factor;
                          height = s.height * factor;
                        }
                        final shift = EditorialRenderer.rotatePoint(
                            Offset(
                                (width - s.width) *
                                    widget.size.width *
                                    corner.dx /
                                    2,
                                (height - s.height) *
                                    widget.size.height *
                                    corner.dy /
                                    2),
                            Offset.zero,
                            s.rotation);
                        c.updateDesignLayer(
                            s.copyWith(
                                width: width,
                                height: height,
                                x: s.x + shift.dx / widget.size.width,
                                y: s.y + shift.dy / widget.size.height),
                            live: true);
                        return;
                      }
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

class _FreeformGuides extends CustomPainter {
  const _FreeformGuides(this.guides, this.crop, this.color);
  final List<SnapGuide> guides;
  final DesignLayer? crop;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: .75)
      ..strokeWidth = 1;
    for (final guide in guides) {
      canvas.drawLine(
          guide.vertical
              ? Offset(size.width * guide.position, 0)
              : Offset(0, size.height * guide.position),
          guide.vertical
              ? Offset(size.width * guide.position, size.height)
              : Offset(size.width, size.height * guide.position),
          paint);
    }
    final frame = crop;
    if (frame == null) return;
    final r = frame.rect(size);
    canvas.save();
    canvas.translate(r.center.dx, r.center.dy);
    canvas.rotate(frame.rotation * math.pi / 180);
    canvas.translate(-r.center.dx, -r.center.dy);
    paint.color = Colors.white.withValues(alpha: .8);
    for (final fraction in [1 / 3, 2 / 3]) {
      canvas.drawLine(Offset(r.left + r.width * fraction, r.top),
          Offset(r.left + r.width * fraction, r.bottom), paint);
      canvas.drawLine(Offset(r.left, r.top + r.height * fraction),
          Offset(r.right, r.top + r.height * fraction), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FreeformGuides old) =>
      guides != old.guides || crop != old.crop || color != old.color;
}
