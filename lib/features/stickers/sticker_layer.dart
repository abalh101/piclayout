import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../collage_editor/state/collage_editor_controller.dart';
import 'sticker_overlay.dart';
import 'sticker_renderer.dart';

class StickerLayer extends StatefulWidget {
  const StickerLayer(
      {required this.controller,
      required this.size,
      required this.onEdit,
      super.key});
  final CollageEditorController controller;
  final Size size;
  final VoidCallback onEdit;
  @override
  State<StickerLayer> createState() => _StickerLayerState();
}

class _StickerLayerState extends State<StickerLayer> {
  StickerOverlay? _start;
  Offset? _origin;
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Positioned.fill(
        child: Stack(clipBehavior: Clip.hardEdge, children: [
      Positioned.fill(
          child: IgnorePointer(
              child: CustomPaint(
                  painter: StickerPainter(controller.project.stickers)))),
      for (final sticker in controller.project.stickers)
        Positioned.fromRect(
          rect: Rect.fromCenter(
              center: StickerRenderer.bounds(sticker, widget.size).center,
              width: math.max(
                  44, StickerRenderer.extent(sticker, widget.size).width),
              height: math.max(
                  44, StickerRenderer.extent(sticker, widget.size).height)),
          child: Transform.rotate(
            angle: sticker.rotation * math.pi / 180,
            child: Semantics(
              label:
                  '${AppLocalizations.of(context).tr('stickers')}: ${sticker.content}',
              selected: controller.selectedStickerId == sticker.id,
              button: true,
              child: GestureDetector(
                key: ValueKey('sticker-${sticker.id}'),
                behavior: HitTestBehavior.opaque,
                onTap: () => controller.selectSticker(sticker.id),
                onDoubleTap: () {
                  controller.selectSticker(sticker.id);
                  widget.onEdit();
                },
                onScaleStart: (details) {
                  _start = sticker;
                  _origin = details.focalPoint;
                  controller.selectSticker(sticker.id);
                  controller.beginInteractiveTransform();
                },
                onScaleUpdate: (details) {
                  final start = _start;
                  if (start == null || _origin == null) return;
                  final delta = details.focalPoint - _origin!;
                  controller.updateSticker(
                      start.copyWith(
                          x: start.x + delta.dx / widget.size.width,
                          y: start.y + delta.dy / widget.size.height,
                          scale: start.scale * details.scale,
                          rotation: start.rotation +
                              details.rotation * 180 / math.pi),
                      live: true);
                },
                onScaleEnd: (_) {
                  _start = null;
                  _origin = null;
                  controller.endInteractiveTransform();
                },
                child: DecoratedBox(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: controller.selectedStickerId == sticker.id
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2)
                            : null)),
              ),
            ),
          ),
        ),
    ]));
  }
}
