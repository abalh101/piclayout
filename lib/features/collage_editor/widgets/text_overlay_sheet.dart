import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../models/text_overlay.dart';
import '../state/collage_editor_controller.dart';

Future<void> showTextOverlaySheet(
  BuildContext context,
  CollageEditorController controller,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _TextOverlaySheet(controller: controller),
  );
}

class _TextOverlaySheet extends StatefulWidget {
  const _TextOverlaySheet({required this.controller});

  final CollageEditorController controller;

  @override
  State<_TextOverlaySheet> createState() => _TextOverlaySheetState();
}

class _TextOverlaySheetState extends State<_TextOverlaySheet> {
  late final TextEditingController _textController = TextEditingController(
    text: widget.controller.selectedText?.text ?? '',
  );

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: (MediaQuery.sizeOf(context).height -
                    MediaQuery.viewInsetsOf(context).bottom) *
                0.75,
          ),
          child: SingleChildScrollView(
            child: AnimatedBuilder(
              animation: widget.controller,
              builder: (context, _) {
                final overlays = widget.controller.project.textOverlays;
                final selected = widget.controller.selectedText;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(strings.textOverlay,
                              style: Theme.of(context).textTheme.titleLarge),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () {
                            final added = widget.controller.addText('Text');
                            _textController.text = added.text;
                          },
                          icon: const Icon(Icons.add),
                          label: Text(strings.addText),
                        ),
                      ],
                    ),
                    if (overlays.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (var index = 0; index < overlays.length; index++)
                            ChoiceChip(
                              label: Text(
                                '${index + 1}: ${overlays[index].text.isEmpty ? '…' : overlays[index].text}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              selected: selected?.id == overlays[index].id,
                              onSelected: (_) {
                                widget.controller
                                    .selectText(overlays[index].id);
                                _textController.text = overlays[index].text;
                              },
                            ),
                        ],
                      ),
                    ],
                    if (selected == null) ...[
                      const SizedBox(height: 16),
                      Text(strings.selectTextHint),
                    ] else ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _textController,
                        maxLines: 3,
                        maxLength: 300,
                        decoration: InputDecoration(
                          labelText: strings.textContent,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) => widget.controller.updateText(
                          selected.copyWith(text: value),
                        ),
                      ),
                      _settingLabel(context, strings.fontSize),
                      Slider(
                        value: selected.fontSize,
                        min: 12,
                        max: 72,
                        divisions: 60,
                        label: selected.fontSize.round().toString(),
                        onChanged: (value) => widget.controller.updateText(
                          selected.copyWith(fontSize: value),
                        ),
                      ),
                      _settingLabel(context, strings.textColor),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final option in [
                            (0xFFFFFFFF, strings.white),
                            (0xFF000000, strings.black),
                            (0xFF2563EB, strings.blue),
                            (0xFFDC2626, strings.red),
                            (0xFFFACC15, strings.yellow),
                          ])
                            ChoiceChip(
                              avatar: CircleAvatar(
                                backgroundColor: Color(option.$1),
                                radius: 9,
                              ),
                              label: Text(option.$2),
                              selected: selected.color == option.$1,
                              onSelected: (_) => widget.controller.updateText(
                                selected.copyWith(color: option.$1),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _settingLabel(context, strings.textBackground),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final option in [
                            (null, strings.none),
                            (0x99000000, strings.black),
                            (0x99FFFFFF, strings.white),
                          ])
                            ChoiceChip(
                              label: Text(option.$2),
                              selected: selected.backgroundColor == option.$1,
                              onSelected: (_) => widget.controller.updateText(
                                selected.copyWith(backgroundColor: option.$1),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _settingLabel(context, strings.textAlignment),
                      SegmentedButton<TextOverlayAlignment>(
                        segments: [
                          ButtonSegment(
                            value: TextOverlayAlignment.left,
                            icon: const Icon(Icons.format_align_left),
                            label: Text(strings.left),
                          ),
                          ButtonSegment(
                            value: TextOverlayAlignment.center,
                            icon: const Icon(Icons.format_align_center),
                            label: Text(strings.center),
                          ),
                          ButtonSegment(
                            value: TextOverlayAlignment.right,
                            icon: const Icon(Icons.format_align_right),
                            label: Text(strings.right),
                          ),
                        ],
                        selected: {selected.alignment},
                        onSelectionChanged: (values) =>
                            widget.controller.updateText(
                          selected.copyWith(alignment: values.first),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _settingLabel(context, strings.rotate),
                      Slider(
                        value: selected.rotation,
                        min: -180,
                        max: 180,
                        divisions: 72,
                        label: '${selected.rotation.round()}°',
                        onChanged: (value) => widget.controller.updateText(
                          selected.copyWith(rotation: value),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            widget.controller.removeSelectedText();
                            _textController.clear();
                          },
                          icon: const Icon(Icons.delete_outline),
                          label: Text(strings.delete),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _settingLabel(BuildContext context, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(label, style: Theme.of(context).textTheme.labelLarge),
      );
}
