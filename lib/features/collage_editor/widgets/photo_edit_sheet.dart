import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../models/photo_adjustments.dart';
import '../models/photo_asset.dart';
import '../state/collage_editor_controller.dart';
import 'styled_collage_scene.dart';

Future<void> showPhotoEditor(
    BuildContext context, CollageEditorController controller) async {
  final photo = controller.selectedPhoto;
  if (photo == null || !controller.selectedPhotoEditable) return;
  final result =
      await showModalBottomSheet<({PhotoAdjustments adjustments, bool all})>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => _PhotoEditor(controller: controller, photo: photo));
  if (result != null && context.mounted) {
    controller.setAdjustments(photo.id, result.adjustments, all: result.all);
  }
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
  bool _original = false;
  bool _all = false;
  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final t = strings.tr;
    final project = widget.controller.project;
    final preview = project.copyWith(photos: [
      for (final photo in project.photos)
        if ((photo.id == widget.photo.id || _all) &&
            (!project.freestyle || photo.placement?.locked != true))
          photo.copyWith(
              adjustments: _original ? const PhotoAdjustments() : _draft)
        else
          photo
    ]);
    Widget slider(String key, double value, double min, double max,
            double neutral, ValueChanged<double> change) =>
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('${t(key)} · ${value.toStringAsFixed(2)}')),
            IconButton(
              tooltip: '${t('resetAdjustment')} · ${t(key)}',
              onPressed: value == neutral
                  ? null
                  : () => setState(() => change(neutral)),
              icon: const Icon(Icons.restart_alt, size: 18),
            ),
          ]),
          Slider(
              value: value,
              min: min,
              max: max,
              semanticFormatterCallback: (value) =>
                  '${t(key)} ${value.toStringAsFixed(2)}',
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
                          child: StyledCollageScene(
                              project: preview, maxEdge: 512)))),
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
                Wrap(spacing: 8, runSpacing: 4, children: [
                  FilterChip(
                      label: Text(t('comparePhoto')),
                      selected: _original,
                      onSelected: (value) => setState(() => _original = value)),
                  if (project.photos.length > 1)
                    FilterChip(
                        label: Text(t('applyAllPhotos')),
                        selected: _all,
                        onSelected: (value) => setState(() => _all = value)),
                  ActionChip(
                      label: Text(t('copyAdjustments')),
                      avatar: const Icon(Icons.copy_outlined, size: 18),
                      onPressed: () => setState(
                          () => widget.controller.copiedAdjustments = _draft)),
                  ActionChip(
                      label: Text(t('pasteAdjustments')),
                      avatar: const Icon(Icons.paste_outlined, size: 18),
                      onPressed: widget.controller.copiedAdjustments == null
                          ? null
                          : () => setState(() =>
                              _draft = widget.controller.copiedAdjustments!)),
                ]),
                slider('filterIntensity', _draft.filterIntensity, 0, 1, 1,
                    (v) => _draft = _draft.copyWith(filterIntensity: v)),
                slider('brightness', _draft.brightness, -1, 1, 0,
                    (v) => _draft = _draft.copyWith(brightness: v)),
                slider('exposure', _draft.exposure, -2, 2, 0,
                    (v) => _draft = _draft.copyWith(exposure: v)),
                slider('contrast', _draft.contrast, 0, 2, 1,
                    (v) => _draft = _draft.copyWith(contrast: v)),
                slider('saturation', _draft.saturation, 0, 2, 1,
                    (v) => _draft = _draft.copyWith(saturation: v)),
                slider('warmth', _draft.warmth, -1, 1, 0,
                    (v) => _draft = _draft.copyWith(warmth: v)),
                slider('highlights', _draft.highlights, -1, 1, 0,
                    (v) => _draft = _draft.copyWith(highlights: v)),
                slider('shadows', _draft.shadows, -1, 1, 0,
                    (v) => _draft = _draft.copyWith(shadows: v)),
                slider('sharpness', _draft.sharpness, 0, 1, 0,
                    (v) => _draft = _draft.copyWith(sharpness: v)),
                slider('vignette', _draft.vignette, 0, 1, 0,
                    (v) => _draft = _draft.copyWith(vignette: v)),
                TextButton(
                    onPressed: () =>
                        setState(() => _draft = const PhotoAdjustments()),
                    child: Text(t('reset'))),
              ])),
              Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 12,
                      children: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(strings.cancel)),
                        FilledButton(
                            onPressed: () => Navigator.pop(
                                context, (adjustments: _draft, all: _all)),
                            child: Text(strings.done)),
                      ])),
            ])));
  }
}
