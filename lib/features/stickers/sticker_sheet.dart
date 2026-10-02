import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../collage_editor/state/collage_editor_controller.dart';
import 'sticker_overlay.dart';
import 'sticker_renderer.dart';

const stickerColors = <int>[
  0xFFFFFFFF,
  0xFF171717,
  0xFFFF477E,
  0xFFFFC107,
  0xFF4CAF50,
  0xFF2196F3,
  0xFF9C27B0
];

Future<void> showStickerPicker(
        BuildContext context, CollageEditorController controller) =>
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _StickerPicker(controller: controller));

class _StickerPicker extends StatefulWidget {
  const _StickerPicker({required this.controller});
  final CollageEditorController controller;
  @override
  State<_StickerPicker> createState() => _StickerPickerState();
}

class _StickerPickerState extends State<_StickerPicker> {
  StickerCategory _category = StickerCategory.emojis;
  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final t = strings.tr;
    return SafeArea(
        child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .7,
            child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                children: [
                  Text(t('stickers'),
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 4, children: [
                    for (final category in StickerCategory.values)
                      ChoiceChip(
                          label: Text(t('stCategory_${category.name}')),
                          selected: _category == category,
                          onSelected: (_) =>
                              setState(() => _category = category)),
                  ]),
                  const SizedBox(height: 16),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final item in StickerCatalog.items
                        .where((s) => s.category == _category))
                      SizedBox(
                          width: 80,
                          child: InkWell(
                            key: ValueKey('catalog-${item.content}'),
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              final content = item.type == StickerType.label
                                  ? item.content == 'date'
                                      ? MaterialLocalizations.of(context)
                                          .formatMediumDate(DateTime.now())
                                      : t(item.labelKey)
                                  : null;
                              widget.controller
                                  .addSticker(item, label: content);
                              Navigator.pop(context);
                            },
                            child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Column(children: [
                                  SizedBox(
                                      width: 60,
                                      height: 60,
                                      child: CustomPaint(
                                          painter: StickerPainter([
                                        item
                                            .create('preview',
                                                label: item.type ==
                                                        StickerType.label
                                                    ? t(item.labelKey)
                                                    : null)
                                            .copyWith(
                                                scale: item.type ==
                                                        StickerType.label
                                                    ? 2
                                                    : 3.5)
                                      ]))),
                                  Text(t(item.labelKey),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center),
                                ])),
                          )),
                  ]),
                  const SizedBox(height: 16),
                  Text(t('stHint')),
                  if (widget.controller.project.stickers.isNotEmpty) ...[
                    const Divider(),
                    Text(t('stOnCanvas'),
                        style: Theme.of(context).textTheme.titleMedium),
                    for (final sticker
                        in widget.controller.project.stickers.reversed)
                      ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: Text(sticker.type == StickerType.label ||
                                sticker.type == StickerType.emoji
                            ? sticker.content
                            : t(StickerCatalog.items
                                .firstWhere((s) =>
                                    s.type == sticker.type &&
                                    s.content == sticker.content)
                                .labelKey)),
                        onTap: () {
                          widget.controller.selectSticker(sticker.id);
                          final navigator = Navigator.of(context);
                          navigator.pop();
                        },
                      ),
                  ],
                ])));
  }
}

Future<void> showStickerEditor(
        BuildContext context, CollageEditorController controller) =>
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _StickerEditor(controller: controller));

class _StickerEditor extends StatefulWidget {
  const _StickerEditor({required this.controller});
  final CollageEditorController controller;
  @override
  State<_StickerEditor> createState() => _StickerEditorState();
}

class _StickerEditorState extends State<_StickerEditor> {
  bool _interactive = false;
  void _begin() {
    if (!_interactive) {
      _interactive = true;
      widget.controller.beginInteractiveTransform();
    }
  }

  void _end() {
    if (_interactive) {
      _interactive = false;
      widget.controller.endInteractiveTransform();
    }
  }

  @override
  void dispose() {
    _end();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final sticker = controller.selectedSticker;
        final strings = AppLocalizations.of(context);
        final t = strings.tr;
        if (sticker == null) return const SizedBox.shrink();
        return SafeArea(
            child: SizedBox(
                height: MediaQuery.sizeOf(context).height * .72,
                child: ListView(
                    padding: EdgeInsets.fromLTRB(20, 0, 20,
                        20 + MediaQuery.viewInsetsOf(context).bottom),
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(t('stEdit'),
                                style: Theme.of(context).textTheme.titleLarge)),
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(strings.done))
                      ]),
                      Center(
                          child: SizedBox(
                              width: 180,
                              height: 100,
                              child: CustomPaint(
                                  painter: StickerPainter([
                                sticker.copyWith(x: .5, y: .5, scale: 3)
                              ])))),
                      if (sticker.type == StickerType.label)
                        TextFormField(
                            key: ValueKey(sticker.id),
                            initialValue: sticker.content,
                            maxLength: 60,
                            decoration:
                                InputDecoration(labelText: t('stLabelText')),
                            onChanged: (value) {
                              _begin();
                              controller.updateSticker(
                                  sticker.copyWith(content: value),
                                  live: true);
                            },
                            onEditingComplete: () {
                              _end();
                              FocusScope.of(context).unfocus();
                            }),
                      _slider(t('stSize'), sticker.scale, .25, 4,
                          (v) => sticker.copyWith(scale: v)),
                      _slider(t('stRotation'), sticker.rotation, -180, 180,
                          (v) => sticker.copyWith(rotation: v)),
                      _slider(t('stOpacity'), sticker.opacity, 0, 1,
                          (v) => sticker.copyWith(opacity: v)),
                      if (sticker.type != StickerType.emoji) ...[
                        Text(t('stColor')),
                        _colors(context, sticker.color, (color) {
                          _end();
                          controller
                              .updateSticker(sticker.copyWith(color: color));
                        }),
                      ] else
                        Text(t('stEmojiColor')),
                      const SizedBox(height: 12),
                      Text(t('stBackground')),
                      _colors(context, sticker.backgroundColor, (color) {
                        _end();
                        controller.updateSticker(
                            sticker.copyWith(backgroundColor: color));
                      }),
                      TextButton(
                          onPressed: () {
                            _end();
                            controller.updateSticker(
                                sticker.copyWith(clearBackground: true));
                          },
                          child: Text(t('stNoBackground'))),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        OutlinedButton.icon(
                            onPressed: () {
                              _end();
                              controller.duplicateSticker();
                            },
                            icon: const Icon(Icons.copy),
                            label: Text(t('stDuplicate'))),
                        OutlinedButton.icon(
                            onPressed: () {
                              _end();
                              controller.reorderSticker(front: true);
                            },
                            icon: const Icon(Icons.flip_to_front),
                            label: Text(t('stFront'))),
                        OutlinedButton.icon(
                            onPressed: () {
                              _end();
                              controller.reorderSticker(front: false);
                            },
                            icon: const Icon(Icons.flip_to_back),
                            label: Text(t('stBack'))),
                        OutlinedButton.icon(
                            onPressed: () {
                              _end();
                              controller.removeSticker();
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: Text(strings.delete)),
                      ]),
                    ])));
      });
  Widget _slider(String label, double value, double min, double max,
          StickerOverlay Function(double) updated) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label),
        Slider(
            value: value,
            min: min,
            max: max,
            label: value.toStringAsFixed(2),
            onChangeStart: (_) {
              _end();
              _begin();
            },
            onChanged: (v) =>
                widget.controller.updateSticker(updated(v), live: true),
            onChangeEnd: (_) => _end()),
      ]);
  Widget _colors(
          BuildContext context, int? selected, ValueChanged<int> onSelect) =>
      Wrap(spacing: 4, runSpacing: 4, children: [
        for (var i = 0; i < stickerColors.length; i++)
          Semantics(
              label: AppLocalizations.of(context).tr('stColor$i'),
              selected: selected == stickerColors[i],
              child: IconButton(
                  tooltip: AppLocalizations.of(context).tr('stColor$i'),
                  onPressed: () => onSelect(stickerColors[i]),
                  icon: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                          color: Color(stickerColors[i]),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                              width: selected == stickerColors[i] ? 4 : 1))))),
      ]);
}
