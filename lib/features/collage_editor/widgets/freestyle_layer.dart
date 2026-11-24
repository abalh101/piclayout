import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/app_localizations.dart';
import '../models/photo_placement.dart';
import '../rendering/freestyle_geometry.dart';
import '../state/collage_editor_controller.dart';

class FreestyleLayer extends StatefulWidget {
  const FreestyleLayer({
    super.key,
    required this.controller,
    required this.size,
    this.onEditPhoto,
  });

  final CollageEditorController controller;
  final Size size;
  final VoidCallback? onEditPhoto;

  @override
  State<FreestyleLayer> createState() => _FreestyleLayerState();
}

class _FreestyleLayerState extends State<FreestyleLayer> {
  PhotoPlacement? _start;
  Offset _origin = Offset.zero;
  double? _guideX, _guideY;
  final _pointers = <int>{};
  CollageEditorController get _controller => widget.controller;

  void _begin(String id, PhotoPlacement placement, Offset origin) {
    _start = placement;
    _origin = origin;
    _controller.selectPhoto(id);
    _controller.beginInteractiveTransform();
  }

  void _end(PointerEvent event) {
    _pointers.remove(event.pointer);
    if (_pointers.isNotEmpty) return;
    _start = null;
    if (_guideX != null || _guideY != null) {
      setState(() => _guideX = _guideY = null);
    }
    _controller.endInteractiveTransform();
  }

  void _move(String id, ScaleUpdateDetails details) {
    final start = _start;
    if (start == null) return;
    final size = widget.size;
    final delta = details.focalPoint - _origin;
    final next = start.resized(details.scale).copyWith(
          x: start.x + delta.dx / size.width,
          y: start.y + delta.dy / size.height,
          rotation: start.rotation + details.rotation * 180 / math.pi,
        );
    if (!_controller.snapFreestyle) {
      _controller.updatePlacement(id, next, live: true);
      return;
    }
    final result = FreestyleGeometry.snap(
      next,
      size,
      neighbors: [
        for (final photo in _controller.project.photos)
          if (photo.id != id) photo.placement ?? const PhotoPlacement(),
      ],
    );
    if (result.guideX != _guideX || result.guideY != _guideY) {
      final enteredGuide = (_guideX == null && result.guideX != null) ||
          (_guideY == null && result.guideY != null);
      if (enteredGuide) HapticFeedback.selectionClick();
      setState(() {
        _guideX = result.guideX;
        _guideY = result.guideY;
      });
    }
    _controller.updatePlacement(id, result.placement, live: true);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final size = widget.size;
    final photos = _controller.project.photos;
    final selected = _controller.selectedPhoto;
    final placement =
        selected == null ? null : selected.placement ?? const PhotoPlacement();
    return Positioned.fill(
      child: Listener(
        onPointerDown: (event) => _pointers.add(event.pointer),
        onPointerUp: _end,
        onPointerCancel: _end,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            for (final (index, photo) in photos.indexed)
              if ((photo.placement ?? const PhotoPlacement()) case final item)
                if (!item.hidden)
                  Positioned.fromRect(
                    key: ValueKey('freestyle-${photo.id}'),
                    rect: item.rect(size),
                    child: Transform.rotate(
                      angle: item.radians,
                      child: Semantics(
                        button: true,
                        selected: selected?.id == photo.id,
                        label: '${strings.photo} ${index + 1}',
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _controller.selectPhoto(photo.id),
                          onDoubleTap: item.locked
                              ? null
                              : () {
                                  _controller.selectPhoto(photo.id);
                                  widget.onEditPhoto?.call();
                                },
                          onScaleStart: item.locked
                              ? null
                              : (details) =>
                                  _begin(photo.id, item, details.focalPoint),
                          onScaleUpdate: item.locked
                              ? null
                              : (details) => _move(photo.id, details),
                          child: DecoratedBox(
                              decoration: BoxDecoration(
                            border: selected?.id == photo.id
                                ? Border.all(color: scheme.primary, width: 2)
                                : null,
                          )),
                        ),
                      ),
                    ),
                  ),
            if (_guideX case final x?)
              Positioned(
                  left: x,
                  top: 0,
                  bottom: 0,
                  width: 1,
                  child:
                      IgnorePointer(child: ColoredBox(color: scheme.primary))),
            if (_guideY case final y?)
              Positioned(
                  top: y,
                  left: 0,
                  right: 0,
                  height: 1,
                  child:
                      IgnorePointer(child: ColoredBox(color: scheme.primary))),
            if (selected != null &&
                placement != null &&
                !placement.hidden &&
                !placement.locked)
              _resizeHandle(selected.id, placement, strings.tr('resizePhoto')),
          ],
        ),
      ),
    );
  }

  Widget _resizeHandle(String id, PhotoPlacement placement, String label) {
    final rect = placement.rect(widget.size);
    final corner = rect.bottomRight - rect.center;
    final c = math.cos(placement.radians);
    final s = math.sin(placement.radians);
    final position = rect.center +
        Offset(c * corner.dx - s * corner.dy, s * corner.dx + c * corner.dy);
    return Positioned(
      left:
          position.dx.clamp(12.0, math.max(12.0, widget.size.width - 12)) - 22,
      top:
          position.dy.clamp(12.0, math.max(12.0, widget.size.height - 12)) - 22,
      width: 44,
      height: 44,
      child: Semantics(
        label: label,
        onIncrease: () =>
            _controller.updatePlacement(id, placement.resized(1.1)),
        onDecrease: () =>
            _controller.updatePlacement(id, placement.resized(.9)),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (details) =>
              _begin(id, placement, details.globalPosition),
          onPanUpdate: (details) {
            final start = _start;
            if (start == null) return;
            final delta = details.globalPosition - _origin;
            final projected = delta.dx * (c * corner.dx - s * corner.dy) +
                delta.dy * (s * corner.dx + c * corner.dy);
            _controller.updatePlacement(
                id, start.resized(1 + projected / corner.distanceSquared),
                live: true);
          },
          onPanEnd: (_) => _controller.endInteractiveTransform(),
          onPanCancel: _controller.endInteractiveTransform,
          child: Center(
            child: Material(
              shape: const CircleBorder(),
              color: Theme.of(context).colorScheme.primary,
              elevation: 2,
              child: const SizedBox.square(dimension: 14),
            ),
          ),
        ),
      ),
    );
  }
}
