import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../models/photo_adjustments.dart';
import '../state/collage_editor_controller.dart';
import 'adjustment_slider.dart';
import 'styled_collage_scene.dart';

Future<void> showPhotoAdjustmentsStudio(
    BuildContext context, CollageEditorController controller) async {
  if (controller.selectedPhoto == null) return;
  try {
    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => PhotoAdjustmentsStudio(controller: controller));
  } finally {
    controller.endInteractiveTransform();
  }
}

class PhotoAdjustmentsStudio extends StatefulWidget {
  const PhotoAdjustmentsStudio({super.key, required this.controller});
  final CollageEditorController controller;
  @override
  State<PhotoAdjustmentsStudio> createState() => _StudioState();
}

class _StudioState extends State<PhotoAdjustmentsStudio> {
  bool _holding = false, _compare = false, _confirming = false;
  CollageEditorController get controller => widget.controller;

  void _navigate(int direction) {
    controller.endInteractiveTransform();
    if (controller.project.isFreeform) {
      final frames = controller.project.design.ordered
          .where((l) =>
              l.isPhoto &&
              !l.locked &&
              l.source(controller.project.photos) != null)
          .toList();
      if (frames.isEmpty) return;
      final index =
          frames.indexWhere((l) => l.id == controller.selectedDesignLayerId);
      setState(() {
        _holding = false;
        _compare = false;
      });
      controller
          .selectDesignLayer(frames[(index + direction) % frames.length].id);
      return;
    }
    final photos = controller.project.photos;
    final index = photos.indexWhere((p) => p.id == controller.selectedPhotoId);
    setState(() {
      _holding = false;
      _compare = false;
    });
    controller.selectPhoto(photos[(index + direction) % photos.length].id);
  }

  Future<void> _resetAll() async {
    if (_confirming) return;
    _confirming = true;
    try {
      final t = AppLocalizations.of(context).tr;
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                  title: Text(t('adjustResetAll')),
                  content: Text(t('adjustResetConfirm')),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(t('cancel'))),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(t('reset')))
                  ]));
      if (mounted && confirmed == true) {
        controller.applyAdjustmentsToAll(reset: true);
      }
    } finally {
      _confirming = false;
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = AppLocalizations.of(context).tr;
        final photo = controller.selectedPhoto;
        if (photo == null) return const SizedBox.shrink();
        final a = photo.adjustments;
        final project = controller.project;
        // Comparison is a view-only copy, never supplied to history/save/export.
        final preview = !_holding && !_compare
            ? project
            : controller.adjustmentPreview(const PhotoAdjustments());
        Widget slider(String key, double value, double min, double max,
                double neutral, PhotoAdjustments Function(double) change,
                {bool enabled = true}) =>
            AdjustmentSlider(
                key: ValueKey('adjust-$key'),
                label: t(key),
                value: value,
                min: min,
                max: max,
                neutral: neutral,
                enabled: enabled,
                resetLabel: t('reset'),
                onStart: controller.beginInteractiveTransform,
                onEnd: controller.endInteractiveTransform,
                onChanged: (v) =>
                    controller.setAdjustments(photo.id, change(v), live: true),
                onReset: () =>
                    controller.setAdjustments(photo.id, change(neutral)));
        return SafeArea(
            child: SizedBox(
                height: MediaQuery.sizeOf(context).height * .9,
                child: Column(children: [
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(children: [
                        Expanded(
                            child: Text(t('adjust'),
                                style:
                                    Theme.of(context).textTheme.titleMedium)),
                        IconButton(
                            tooltip: t('undo'),
                            onPressed:
                                controller.canUndo ? controller.undo : null,
                            icon: const Icon(Icons.undo)),
                        IconButton(
                            tooltip: t('redo'),
                            onPressed:
                                controller.canRedo ? controller.redo : null,
                            icon: const Icon(Icons.redo)),
                        IconButton(
                            tooltip: t('done'),
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.check)),
                      ])),
                  SizedBox(
                      height: MediaQuery.sizeOf(context).height * .22,
                      child: Center(
                          child: AspectRatio(
                              aspectRatio: project.aspectRatio.value,
                              child: RepaintBoundary(
                                  child: StyledCollageScene(
                                      project: preview,
                                      imageCache: controller.previewImages))))),
                  Expanded(
                      child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                        Row(children: [
                          IconButton(
                              tooltip: t('adjustPrevious'),
                              onPressed: project.photos.length > 1
                                  ? () => _navigate(-1)
                                  : null,
                              icon: const Icon(Icons.navigate_before)),
                          Expanded(
                              child: Text(
                                  '${t('photo')} ${project.photos.indexWhere((p) => p.id == photo.id) + 1} / ${project.photos.length}',
                                  textAlign: TextAlign.center)),
                          IconButton(
                              tooltip: t('adjustNext'),
                              onPressed: project.photos.length > 1
                                  ? () => _navigate(1)
                                  : null,
                              icon: const Icon(Icons.navigate_next)),
                        ]),
                        Wrap(spacing: 8, children: [
                          Tooltip(
                              message: t('adjustHold'),
                              child: Listener(
                                  onPointerDown: (_) =>
                                      setState(() => _holding = true),
                                  onPointerUp: (_) =>
                                      setState(() => _holding = false),
                                  onPointerCancel: (_) =>
                                      setState(() => _holding = false),
                                  child: OutlinedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.compare),
                                      label: Text(t('adjustHold'))))),
                          FilterChip(
                              label: Text(t('adjustBefore')),
                              selected: _compare,
                              onSelected: (value) =>
                                  setState(() => _compare = value)),
                        ]),
                        Wrap(spacing: 8, children: [
                          for (final preset in PhotoFilterPreset.values)
                            ChoiceChip(
                                label: Text(t(preset.name)),
                                selected: a.preset == preset,
                                onSelected: (_) => controller.setAdjustments(
                                    photo.id, a.copyWith(preset: preset))),
                        ]),
                        slider('filterIntensity', a.filterIntensity, 0, 1, 1,
                            (v) => a.copyWith(filterIntensity: v),
                            enabled: a.preset != PhotoFilterPreset.original),
                        slider('brightness', a.brightness, -1, 1, 0,
                            (v) => a.copyWith(brightness: v)),
                        slider('contrast', a.contrast, 0, 2, 1,
                            (v) => a.copyWith(contrast: v)),
                        slider('saturation', a.saturation, 0, 2, 1,
                            (v) => a.copyWith(saturation: v)),
                        slider('warmth', a.warmth, -1, 1, 0,
                            (v) => a.copyWith(warmth: v)),
                        slider('tint', a.tint, -1, 1, 0,
                            (v) => a.copyWith(tint: v)),
                        slider('highlights', a.highlights, -1, 1, 0,
                            (v) => a.copyWith(highlights: v)),
                        slider('shadows', a.shadows, -1, 1, 0,
                            (v) => a.copyWith(shadows: v)),
                        slider('fade', a.fade, 0, 1, 0,
                            (v) => a.copyWith(fade: v)),
                        slider('blackPoint', a.blackPoint, 0, 1, 0,
                            (v) => a.copyWith(blackPoint: v)),
                        slider('vignette', a.vignette, 0, 1, 0,
                            (v) => a.copyWith(vignette: v)),
                        Wrap(spacing: 8, runSpacing: 4, children: [
                          TextButton.icon(
                              onPressed: controller.copyAdjustments,
                              icon: const Icon(Icons.copy),
                              label: Text(t('adjustCopy'))),
                          TextButton.icon(
                              onPressed: controller.copiedAdjustments == null
                                  ? null
                                  : controller.pasteAdjustments,
                              icon: const Icon(Icons.paste),
                              label: Text(t('adjustPaste'))),
                          TextButton(
                              onPressed: controller.applyAdjustmentsToAll,
                              child: Text(t('adjustApplyAll'))),
                          TextButton(
                              onPressed: controller.resetPhotoAdjustments,
                              child: Text(t('adjustResetPhoto'))),
                          TextButton(
                              onPressed: _resetAll,
                              child: Text(t('adjustResetAll'))),
                        ]),
                        if (controller.saveFailed) Text(t('projectSaveFailed')),
                        const SizedBox(height: 16),
                      ])),
                ])));
      });
}
