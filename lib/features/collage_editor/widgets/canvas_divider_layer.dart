import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../custom_layouts/models/custom_layout.dart';
import '../state/collage_editor_controller.dart';

/// Editor-only hit targets. Export uses the project's saved custom geometry.
class CanvasDividerLayer extends StatefulWidget {
  const CanvasDividerLayer(
      {required this.controller, required this.size, super.key});
  final CollageEditorController controller;
  final Size size;
  @override
  State<CanvasDividerLayer> createState() => _CanvasDividerLayerState();
}

class _CanvasDividerLayerState extends State<CanvasDividerLayer> {
  Offset? _origin;
  LayoutDivider? _startDivider;
  Rect? _startInner;

  Rect get _inner {
    final margin = widget.controller.project.canvas.outerMargin *
        widget.size.shortestSide /
        390;
    return Rect.fromLTWH(
        margin,
        margin,
        math.max(1, widget.size.width - 2 * margin),
        math.max(1, widget.size.height - 2 * margin));
  }

  Offset _point(LayoutDivider divider, double along) =>
      divider.axis == DividerAxis.vertical
          ? Offset(_inner.left + divider.position * _inner.width,
              _inner.top + along * _inner.height)
          : Offset(_inner.left + along * _inner.width,
              _inner.top + divider.position * _inner.height);

  Widget _target(LayoutDivider divider, {required bool handle}) {
    final vertical = divider.axis == DividerAxis.vertical;
    final from = _point(divider, divider.start);
    final to = _point(divider, divider.end);
    // Offset anchors keep horizontal and vertical handles apart at crossings.
    final anchor = _point(divider,
        divider.start + (divider.end - divider.start) * (vertical ? .25 : .75));
    final rect = handle
        ? Rect.fromCenter(center: anchor, width: 44, height: 44)
        : vertical
            ? Rect.fromLTRB(from.dx - 12, from.dy, to.dx + 12, to.dy)
            : Rect.fromLTRB(from.dx, from.dy - 12, to.dx, to.dy + 12);
    return Positioned.fromRect(
      rect: rect,
      child: Semantics(
        label: AppLocalizations.of(context)
            .tr(vertical ? 'layoutBuilderVertical' : 'layoutBuilderHorizontal'),
        child: GestureDetector(
          key: ValueKey('canvas-${handle ? 'divider' : 'seam'}-${divider.id}'),
          behavior: HitTestBehavior.opaque,
          dragStartBehavior: DragStartBehavior.down,
          onPanStart: (details) {
            _origin = details.globalPosition;
            _startDivider = divider;
            _startInner = _inner;
            widget.controller.beginDividerDrag(divider);
          },
          onPanUpdate: (details) {
            final start = _startDivider;
            final inner = _startInner;
            if (_origin == null || start == null || inner == null) return;
            final delta = details.globalPosition - _origin!;
            widget.controller.updateDividerDrag(start.position +
                (start.axis == DividerAxis.vertical
                    ? delta.dx / inner.width
                    : delta.dy / inner.height));
          },
          onPanEnd: (_) => _finish(),
          onPanCancel: _finish,
          child: handle
              ? Center(
                  child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2)),
                      child: Icon(vertical ? Icons.swap_horiz : Icons.swap_vert,
                          size: 18,
                          color: Theme.of(context).colorScheme.onPrimary)))
              : Center(
                  child: Container(
                      width: vertical ? 2 : rect.width,
                      height: vertical ? rect.height : 2,
                      color: Theme.of(context).colorScheme.primary)),
        ),
      ),
    );
  }

  void _finish() {
    _origin = null;
    _startDivider = null;
    _startInner = null;
    widget.controller.endDividerDrag();
  }

  @override
  Widget build(BuildContext context) {
    final dividers = widget.controller.editableCanvasLayout?.dividers ?? [];
    return Stack(clipBehavior: Clip.hardEdge, children: [
      for (final divider in dividers) _target(divider, handle: false),
      for (final divider in dividers) _target(divider, handle: true),
    ]);
  }
}
