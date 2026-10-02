import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../models/photo_adjustments.dart';
import '../models/photo_asset.dart';
import '../state/collage_editor_controller.dart';
import 'styled_collage_scene.dart';

Future<void> showPhotoEditor(
    BuildContext context, CollageEditorController controller) async {
  final photo = controller.selectedPhoto;
  if (photo == null) return;
  final result = await showModalBottomSheet<PhotoAdjustments>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PhotoEditor(controller: controller, photo: photo));
  if (result != null) controller.setAdjustments(photo.id, result);
}

class _PhotoEditor extends StatefulWidget {
  const _PhotoEditor({required this.controller, required this.photo});
  final CollageEditorController controller;
  final PhotoAsset photo;
  @override
  State<_PhotoEditor> createState() => _PhotoEditorState();
}

class _PhotoEditorState extends State<_PhotoEditor> {
  late PhotoAdjustments _draft = widget.photo.adjustments;
  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final t = strings.tr;
    final project = widget.controller.project;
    final preview = project.copyWith(photos: [
      for (final photo in project.photos)
        if (photo.id == widget.photo.id)
          photo.copyWith(adjustments: _draft)
        else
          photo
    ]);
    Widget slider(String key, double value, double min, double max,
            ValueChanged<double> change) =>
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${t(key)} · ${value.toStringAsFixed(2)}'),
          Slider(
              value: value,
              min: min,
              max: max,
              onChanged: (value) => setState(() => change(value))),
        ]);
    return SafeArea(
        child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .88,
            child: Column(children: [
              Text(t('editPhoto'),
                  style: Theme.of(context).textTheme.titleLarge),
              SizedBox(
                  height: MediaQuery.sizeOf(context).height * .23,
                  child: Center(
                      child: AspectRatio(
                          aspectRatio: project.aspectRatio.value,
                          child: StyledCollageScene(project: preview)))),
              Expanded(
                  child: ListView(padding: const EdgeInsets.all(16), children: [
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final preset in PhotoFilterPreset.values)
                    ChoiceChip(
                        label: Text(t(preset.name)),
                        selected: _draft.preset == preset,
                        onSelected: (_) => setState(
                            () => _draft = _draft.copyWith(preset: preset)))
                ]),
                const SizedBox(height: 16),
                slider('filterIntensity', _draft.filterIntensity, 0, 1,
                    (v) => _draft = _draft.copyWith(filterIntensity: v)),
                slider('brightness', _draft.brightness, -1, 1,
                    (v) => _draft = _draft.copyWith(brightness: v)),
                slider('contrast', _draft.contrast, 0, 2,
                    (v) => _draft = _draft.copyWith(contrast: v)),
                slider('saturation', _draft.saturation, 0, 2,
                    (v) => _draft = _draft.copyWith(saturation: v)),
                slider('warmth', _draft.warmth, -1, 1,
                    (v) => _draft = _draft.copyWith(warmth: v)),
                TextButton(
                    onPressed: () =>
                        setState(() => _draft = const PhotoAdjustments()),
                    child: Text(t('reset'))),
              ])),
              Padding(
                  padding: const EdgeInsets.all(12),
                  child:
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(strings.cancel)),
                    const SizedBox(width: 12),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, _draft),
                        child: Text(strings.done)),
                  ])),
            ])));
  }
}
