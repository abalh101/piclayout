import '../../app/app_config.dart';
import 'widgets/aspect_ratio_choices.dart';
import 'widgets/freestyle_photo_controls.dart';
import 'widgets/layers_sheet.dart';
import '../layout_recommendations/recommended_layouts.dart';
import '../editorial/widgets/design_sheet.dart';
import '../editorial/widgets/freeform_tools.dart';
import '../tutorial_tips/tutorial_tip.dart';
import '../project_archive/project_archive_actions.dart';
import '../project_archive/project_archive_controller.dart';
import '../stickers/sticker_sheet.dart';
import '../custom_layouts/widgets/custom_layout_section.dart';
import 'widgets/photo_edit_sheet.dart';
import 'widgets/photo_adjustments_studio.dart';
import 'widgets/style_studio_sheet.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../photo_import/device_photo_picker.dart';

import '../../core/localization/app_localizations.dart';
import '../export/widgets/export_center.dart';
import '../projects/models/collage_project.dart';
import '../projects/state/project_providers.dart';
import '../templates/models/design_library.dart';
import '../templates/state/design_library_providers.dart';
import '../templates/widgets/templates_sheet.dart';
import 'layouts/layout_library.dart';
import 'models/layout_template.dart';
import 'models/photo_transform.dart';
import 'state/collage_editor_controller.dart';
import 'widgets/collage_canvas.dart';
import 'widgets/thumbnail_strip.dart';
import 'widgets/text_overlay_sheet.dart';
import 'widgets/custom_aspect_ratio_dialog.dart';

class EditorPage extends ConsumerStatefulWidget {
  const EditorPage({
    required this.project,
    super.key,
  });

  final CollageProject project;

  @override
  ConsumerState<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends ConsumerState<EditorPage> {
  bool _leaving = false;
  bool _savedForExit = false;

  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onInactive: () {
      final controller = ref.read(editorControllerProvider(widget.project));
      unawaited(controller.flushPendingSave().catchError((Object _) {}));
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _leave(CollageEditorController controller) async {
    if (_leaving) return;
    setState(() => _leaving = true);
    try {
      await controller.saveNow();
      if (!mounted) return;
      final projects = ref.read(projectsProvider.notifier);
      setState(() => _savedForExit = true);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      Navigator.of(context).pop();
      unawaited(projects.reload());
    } catch (_) {
      // The persistent retry message keeps the unsaved project reachable.
    } finally {
      if (mounted) setState(() => _leaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final provider = editorControllerProvider(widget.project);
    ref.watch(provider.select((c) => (
          c.canUndo,
          c.canRedo,
          c.saveFailed,
          c.project.recovered,
          c.project.name,
        )));
    final controller = ref.read(provider);
    final archiveBusy = ref.watch(projectArchiveControllerProvider).busy;

    return PopScope(
      canPop: _savedForExit,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave(controller));
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(controller.project.name,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            Builder(
              builder: (menuContext) => PopupMenuButton<String>(
                enabled: !_leaving && !archiveBusy,
                onSelected: (_) =>
                    exportProjectArchive(menuContext, ref, controller.project),
                itemBuilder: (_) => [
                  PopupMenuItem(
                      value: 'archive',
                      child: Text(strings.tr('archiveExport')))
                ],
              ),
            ),
            IconButton(
              tooltip: strings.tr('undo'),
              onPressed:
                  !_leaving && controller.canUndo ? controller.undo : null,
              icon: const Icon(Icons.undo),
            ),
            IconButton(
              tooltip: strings.tr('redo'),
              onPressed:
                  !_leaving && controller.canRedo ? controller.redo : null,
              icon: const Icon(Icons.redo),
            ),
            IconButton(
              tooltip: strings.export,
              onPressed: _leaving
                  ? null
                  : () => showExportCenter(context, controller.project),
              icon: const Icon(Icons.ios_share),
            ),
          ],
        ),
        bottomNavigationBar: _leaving || archiveBusy
            ? const LinearProgressIndicator()
            : controller.saveFailed
                ? SafeArea(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Wrap(
                            spacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(strings.tr('projectSaveFailed')),
                              TextButton(
                                  onPressed: () async {
                                    try {
                                      await controller.saveNow();
                                    } catch (_) {/* Keep retry visible. */}
                                  },
                                  child: Text(strings.tr('retry'))),
                            ])))
                : controller.project.recovered
                    ? SafeArea(
                        child: ListTile(
                            leading: const Icon(Icons.info_outline),
                            title: Text(strings.tr('projectRecovered'))))
                    : null,
        body: AbsorbPointer(
            absorbing: _leaving,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 760 ||
                      (constraints.maxWidth >= 560 &&
                          constraints.maxHeight < 500);
                  final preview = _PreviewPanel(controller: controller);
                  final tools = _ToolsPanel(
                      initialProject: widget.project, controller: controller);

                  if (wide) {
                    return Row(
                      children: [
                        Expanded(child: preview),
                        SizedBox(
                          width: (constraints.maxWidth * .42).clamp(260, 380),
                          child: tools,
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      Expanded(child: preview),
                      SizedBox(
                        height: constraints.maxHeight * 0.45,
                        child: tools,
                      ),
                    ],
                  );
                },
              ),
            )),
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({required this.controller});

  final CollageEditorController controller;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 760),
            child: CollageCanvas(
              controller: controller,
              onEditText: () => showTextOverlaySheet(context, controller),
              onEditPhoto: () => showPhotoSheet(context, controller),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolsPanel extends ConsumerWidget {
  const _ToolsPanel({required this.initialProject, required this.controller});

  final CollageProject initialProject;

  final CollageEditorController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    ref.watch(editorControllerProvider(initialProject).select((editor) => (
          editor.projectAtGestureStart,
          editor.project.canvas.staggerAmount,
          editor.selectedPhotoId,
          editor.selectedDesignLayerId,
          editor.selectedTextId,
          editor.selectedStickerId,
          editor.metadataLoading,
          editor.snapFreestyle,
          editor.editingDividers,
          editor.editingDesignCrop,
          editor.importingPhotos,
        )));
    final project = controller.project;
    final layouts = LayoutLibrary.templatesFor(project.photos.length);
    final library =
        ref.watch(designLibraryProvider).value ?? const DesignLibrary();
    final favorites =
        layouts.where((item) => library.isFavorite(item.id)).toList();
    final others =
        layouts.where((item) => !library.isFavorite(item.id)).toList();

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (project.isFreeform) ...[
              Text(strings.tr(controller.editingDesignCrop
                  ? 'ffCropHint'
                  : 'ffGestureHint')),
              Wrap(spacing: 8, children: [
                FilledButton.icon(
                    onPressed: controller.importingPhotos
                        ? null
                        : () => pickFreeformPhotos(context, controller),
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(strings.tr('ffAddPhotos'))),
                OutlinedButton.icon(
                    onPressed: () => showFreeformCanvas(context, controller),
                    icon: const Icon(Icons.open_in_full),
                    label: Text(strings.tr('ffExpand'))),
                if (controller.editingDesignCrop)
                  FilledButton.icon(
                      onPressed: () => controller.setDesignCropEditing(false),
                      icon: const Icon(Icons.check),
                      label: Text(strings.tr('edCropDone'))),
              ]),
              if (controller.importingPhotos) const LinearProgressIndicator(),
            ],
            TutorialTip(
              key: ValueKey(controller.selectedText != null ||
                      controller.selectedSticker != null
                  ? 'tipDrag'
                  : 'tipPhoto'),
              id: controller.selectedText != null ||
                      controller.selectedSticker != null
                  ? 'tipDrag'
                  : 'tipPhoto',
            ),
            SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: IconTheme(
                    data: const IconThemeData(size: 20),
                    child: Row(spacing: 8, children: [
                      OutlinedButton.icon(
                          key: const ValueKey('freeform-design'),
                          onPressed: () =>
                              showFreeformPresets(context, controller),
                          icon: const Icon(Icons.dashboard_customize_outlined),
                          label: Text(strings.tr('ffTitle'))),
                      OutlinedButton.icon(
                          key: const ValueKey('photo-adjustments'),
                          onPressed: !controller.selectedPhotoEditable
                              ? null
                              : () => showPhotoAdjustmentsStudio(
                                  context, controller),
                          icon: const Icon(Icons.tune),
                          label: Text(strings.tr('adjust'))),
                      OutlinedButton.icon(
                          key: const ValueKey('editorial-design'),
                          onPressed: () => showDesignSheet(context, controller),
                          icon: const Icon(Icons.auto_awesome_mosaic_outlined),
                          label: Text(strings.tr('edDesign'))),
                      OutlinedButton.icon(
                          key: const ValueKey('editorial-layers'),
                          onPressed: () => showDesignSheet(context, controller,
                              layers: true),
                          icon: const Icon(Icons.layers_outlined),
                          label: Text(strings.tr('edLayers'))),
                      if (controller.editingDesignCrop)
                        FilledButton.icon(
                            onPressed: () =>
                                controller.setDesignCropEditing(false),
                            icon: const Icon(Icons.check),
                            label: Text(strings.tr('edCropDone'))),
                      OutlinedButton.icon(
                          key: const ValueKey('add-sticker'),
                          onPressed: () =>
                              showStickerPicker(context, controller),
                          icon: const Icon(Icons.emoji_emotions_outlined),
                          label: Text(strings.tr('stickers'))),
                      if (!project.design.active)
                        OutlinedButton.icon(
                          onPressed: () => showLayersSheet(context, controller),
                          icon: const Icon(Icons.layers_outlined),
                          label: Text(strings.tr('projectLayers')),
                        ),
                      if (controller.selectedSticker?.locked == false)
                        FilledButton.icon(
                            key: const ValueKey('edit-sticker'),
                            onPressed: () =>
                                showStickerEditor(context, controller),
                            icon: const Icon(Icons.edit_outlined),
                            label: Text(strings.tr('stEdit'))),
                    ]))),
            const SizedBox(height: 12),
            if (!project.design.active)
              Wrap(spacing: 8, runSpacing: 4, children: [
                ChoiceChip(
                  avatar: const Icon(Icons.grid_view_outlined, size: 18),
                  label: Text(strings.tr('gridMode')),
                  selected: !project.freestyle,
                  onSelected: (_) => controller.setFreestyle(false),
                ),
                ChoiceChip(
                  avatar:
                      const Icon(Icons.dashboard_customize_outlined, size: 18),
                  label: Text(strings.tr('freestyleMode')),
                  selected: project.freestyle,
                  onSelected: (_) => controller.setFreestyle(true),
                ),
                if (project.freestyle) ...[
                  ActionChip(
                    avatar: const Icon(Icons.add_photo_alternate_outlined,
                        size: 18),
                    label: Text(strings.tr('addPhotos')),
                    onPressed: controller.canAddPhotos
                        ? () => _addPhotos(context)
                        : null,
                  ),
                  FilterChip(
                    label: Text(strings.tr('snapPhoto')),
                    selected: controller.snapFreestyle,
                    onSelected: controller.setSnapFreestyle,
                  ),
                ],
              ]),
            if (!project.isFreeform) ThumbnailStrip(controller: controller),
            const SizedBox(height: 12),
            Text(strings.format, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            AspectRatioChoices(
              selectedId: project.aspectRatioId,
              onSelected: controller.setAspectRatio,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final ratio in library.aspectRatios)
                  if (ratio.id != project.aspectRatioId)
                    ChoiceChip(
                      key: ValueKey('ratio-${ratio.id}'),
                      label: Text(ratio.label),
                      selected: false,
                      onSelected: (_) => controller.setAspectRatio(ratio),
                    ),
                ActionChip(
                  key: const ValueKey('custom-aspect-ratio'),
                  avatar: const Icon(Icons.aspect_ratio),
                  label: Text(strings.tr('advancedRatio')),
                  onPressed: () async {
                    final ratio = await showCustomAspectRatioDialog(context);
                    if (ratio == null || !context.mounted) return;
                    try {
                      await ref
                          .read(designLibraryProvider.notifier)
                          .saveAspectRatio(ratio);
                      if (context.mounted) controller.setAspectRatio(ratio);
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(strings.tr('settingsError'))));
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!project.isFreeform && !project.freestyle) ...[
              RecommendedLayouts(
                recommendations: controller.layoutRecommendations,
                targetRatio: project.aspectRatio.value,
                staggerAmount: project.canvas.staggerAmount,
                loading: controller.metadataLoading,
                selectedId:
                    !project.design.active && project.customLayout == null
                        ? project.layoutTemplateId
                        : null,
                onSelected: controller.setLayoutTemplate,
                onAuto: controller.autoLayout,
              ),
              Text(strings.layout,
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              if (favorites.isNotEmpty) ...[
                Text(strings.favorites,
                    style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final layout in favorites)
                      _layoutChoice(context, ref, layout, true),
                  ],
                ),
                const SizedBox(height: 8),
                Text(strings.otherLayouts,
                    style: Theme.of(context).textTheme.labelMedium),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final layout in others)
                    _layoutChoice(context, ref, layout, false),
                ],
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed:
                    controller.canVaryLayout ? controller.varyLayout : null,
                icon: const Icon(Icons.shuffle),
                label: Text(strings.variation),
              ),
              CustomLayoutSection(controller: controller),
              OutlinedButton.icon(
                key: const ValueKey('toggle-canvas-dividers'),
                onPressed: controller.canEditDividers
                    ? controller.toggleDividerEditing
                    : null,
                icon: Icon(controller.editingDividers
                    ? Icons.check
                    : Icons.drag_handle),
                label: Text(strings.tr(controller.editingDividers
                    ? 'canvasDividersDone'
                    : 'canvasDividersEdit')),
              ),
              Text(
                  strings.tr(controller.canEditDividers
                      ? 'canvasDividersHint'
                      : 'canvasDividersUnavailable'),
                  style: Theme.of(context).textTheme.bodySmall),
              if (project.customLayout == null &&
                  LayoutLibrary.byIdOrDefault(
                    project.layoutTemplateId,
                    project.photos.length,
                  ).supportsStagger)
                _SliderTile(
                  label: strings.stagger,
                  value: project.canvas.staggerAmount,
                  min: 0,
                  max: 0.18,
                  onStart: controller.beginCanvasEdit,
                  onEnd: controller.endCanvasEdit,
                  onChanged: (value) => controller.updateCanvas(
                    project.canvas.copyWith(staggerAmount: value),
                  ),
                ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                    onPressed: () => showStyleStudio(context, controller),
                    icon: const Icon(Icons.tune),
                    label: Text(strings.style)),
                FilledButton.icon(
                    onPressed: !controller.selectedPhotoEditable
                        ? null
                        : () => showPhotoSheet(context, controller),
                    icon: const Icon(Icons.crop),
                    label: Text(strings.photo)),
                OutlinedButton.icon(
                    onPressed: () => showTextOverlaySheet(context, controller),
                    icon: const Icon(Icons.text_fields),
                    label: Text(strings.textOverlay)),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                OutlinedButton.icon(
                  onPressed: () =>
                      showSaveTemplateDialog(context, ref, controller),
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: Text(strings.saveAsTemplate),
                ),
                OutlinedButton.icon(
                  onPressed: () => showMyTemplatesSheet(context, controller),
                  icon: const Icon(Icons.collections_bookmark_outlined),
                  label: Text(strings.myTemplates),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addPhotos(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final strings = AppLocalizations.of(context);
    try {
      final count = AppConfig.maxPhotos - controller.project.photos.length;
      if (count < 1) return;
      const picker = DevicePhotoPicker();
      final photos = await picker.pickPhotos(limit: count);
      try {
        if (context.mounted) await controller.addPhotos(photos);
      } finally {
        await picker.release(photos);
      }
    } catch (_) {
      if (context.mounted) {
        messenger.showSnackBar(
            SnackBar(content: Text(strings.tr('operationFailed'))));
      }
    }
  }

  Widget _layoutChoice(
    BuildContext context,
    WidgetRef ref,
    LayoutTemplate layout,
    bool favorite,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
            child: ChoiceChip(
          avatar: SizedBox.square(
              dimension: 24,
              child: CustomPaint(
                  painter: LayoutPreviewPainter(layout,
                      color: Theme.of(context).colorScheme.primary,
                      staggerAmount: controller.project.canvas.staggerAmount))),
          label:
              Text(AppLocalizations.of(context).tr(layout.title), maxLines: 2),
          selected: !controller.project.design.active &&
              controller.project.customLayout == null &&
              controller.project.layoutTemplateId == layout.id,
          onSelected: (_) => controller.setLayoutTemplate(layout.id),
        )),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: favorite
              ? AppLocalizations.of(context).removeFavorite
              : AppLocalizations.of(context).addFavorite,
          onPressed: () async {
            try {
              await ref
                  .read(designLibraryProvider.notifier)
                  .toggleFavorite(layout);
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        AppLocalizations.of(context).tr('operationFailed'))));
              }
            }
          },
          icon: Icon(favorite ? Icons.star : Icons.star_border),
        ),
      ],
    );
  }
}

Future<void> showPhotoSheet(
  BuildContext context,
  CollageEditorController controller,
) async {
  final strings = AppLocalizations.of(context);
  const picker = DevicePhotoPicker();
  bool replacing = false;

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return StatefulBuilder(
          builder: (context, setSheetState) => PopScope(
              canPop: !replacing,
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  final photo = controller.selectedPhoto;
                  if (photo == null || !controller.selectedPhotoEditable) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(strings.noPhotoSelected),
                    );
                  }
                  return AbsorbPointer(
                      absorbing: replacing,
                      child: SafeArea(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!controller.project.freestyle)
                                const TutorialTip(id: 'tipZoom'),
                              if (replacing) const LinearProgressIndicator(),
                              FilledButton.icon(
                                icon: const Icon(Icons.tune),
                                label: Text(strings.tr('editPhoto')),
                                onPressed: () =>
                                    showPhotoEditor(context, controller),
                              ),
                              const SizedBox(height: 12),
                              SegmentedButton<PhotoFitMode>(
                                segments: [
                                  ButtonSegment(
                                    value: PhotoFitMode.fill,
                                    label: Text(strings.fill),
                                    icon: const Icon(Icons.fullscreen),
                                  ),
                                  ButtonSegment(
                                    value: PhotoFitMode.fit,
                                    label: Text(strings.fit),
                                    icon: const Icon(Icons.fit_screen),
                                  ),
                                ],
                                selected: {photo.transform.fitMode},
                                onSelectionChanged: (value) {
                                  controller.setSelectedFitMode(value.first);
                                },
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed:
                                        controller.resetSelectedTransform,
                                    icon: const Icon(Icons.restart_alt),
                                    label: Text(strings.resetCrop),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: controller.rotateSelected,
                                    icon:
                                        const Icon(Icons.rotate_90_degrees_ccw),
                                    label: Text(strings.rotate),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: controller.flipSelected,
                                    icon: const Icon(Icons.flip),
                                    label: Text(strings.flip),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      if (replacing) return;
                                      setSheetState(() => replacing = true);
                                      try {
                                        final photos =
                                            await picker.pickPhotos(limit: 1);
                                        try {
                                          if (context.mounted &&
                                              photos.isNotEmpty) {
                                            await controller
                                                .replaceSelected(photos.single);
                                          }
                                        } finally {
                                          await picker.release(photos);
                                        }
                                      } catch (_) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(strings
                                                      .tr('photoPickFailed'))));
                                        }
                                      } finally {
                                        if (context.mounted) {
                                          setSheetState(
                                              () => replacing = false);
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.swap_horiz),
                                    label: Text(strings.replace),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed:
                                        controller.project.photos.length <= 1
                                            ? null
                                            : controller.removeSelected,
                                    icon: const Icon(Icons.delete_outline),
                                    label: Text(strings.remove),
                                  ),
                                  if (controller.project.freestyle)
                                    FreestylePhotoControls(
                                        photo: photo, controller: controller),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ));
                },
              )));
    },
  );
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onStart,
    required this.onEnd,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final VoidCallback onStart, onEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(value.toStringAsFixed(max <= 1 ? 2 : 0)),
          ],
        ),
        Slider(
          value: value.clamp(min, max).toDouble(),
          min: min,
          max: max,
          onChanged: onChanged,
          onChangeStart: (_) => onStart(),
          onChangeEnd: (_) => onEnd(),
        ),
      ],
    );
  }
}
