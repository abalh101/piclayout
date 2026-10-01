import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/localization/app_localizations.dart';
import '../export/collage_exporter.dart';
import '../export/export_settings.dart';
import '../projects/models/collage_project.dart';
import '../projects/state/project_providers.dart';
import '../templates/models/design_library.dart';
import '../templates/state/design_library_providers.dart';
import '../templates/widgets/templates_sheet.dart';
import 'layouts/layout_library.dart';
import 'models/aspect_ratio_preset.dart';
import 'models/layout_template.dart';
import 'models/photo_transform.dart';
import 'state/collage_editor_controller.dart';
import 'widgets/collage_canvas.dart';
import 'widgets/thumbnail_strip.dart';
import 'widgets/text_overlay_sheet.dart';

class EditorPage extends ConsumerWidget {
  const EditorPage({
    required this.project,
    super.key,
  });

  final CollageProject project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final controller = ref.watch(editorControllerProvider(project));

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          final projects = ref.read(projectsProvider.notifier);
          unawaited(
            controller.saveNow().then(
                  (_) => projects.reload(),
                ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(controller.project.name),
          actions: [
            IconButton(
              tooltip: 'Undo',
              onPressed: controller.canUndo ? controller.undo : null,
              icon: const Icon(Icons.undo),
            ),
            IconButton(
              tooltip: 'Redo',
              onPressed: controller.canRedo ? controller.redo : null,
              icon: const Icon(Icons.redo),
            ),
            IconButton(
              tooltip: strings.export,
              onPressed: () => _showExportSheet(context, controller),
              icon: const Icon(Icons.ios_share),
            ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 860;
              final preview = _PreviewPanel(controller: controller);
              final tools = _ToolsPanel(controller: controller);

              if (wide) {
                return Row(
                  children: [
                    Expanded(child: preview),
                    SizedBox(
                      width: 360,
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
        ),
      ),
    );
  }

  Future<void> _showExportSheet(
    BuildContext context,
    CollageEditorController controller,
  ) async {
    final strings = AppLocalizations.of(context);
    final sizes = controller.project.aspectRatio.exportSizes();

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.exportSize,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  strings.unsupportedExportWarning,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                for (final size in sizes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(child: Text(size.label)),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _exportAndShare(
                              context,
                              controller,
                              ExportSettings(
                                width: size.width,
                                height: size.height,
                                format: ExportFormat.jpeg,
                              ),
                            );
                          },
                          child: const Text('JPEG'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _exportAndShare(
                              context,
                              controller,
                              ExportSettings(
                                width: size.width,
                                height: size.height,
                                format: ExportFormat.png,
                              ),
                            );
                          },
                          child: const Text('PNG'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportAndShare(
    BuildContext context,
    CollageEditorController controller,
    ExportSettings settings,
  ) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await controller.saveNow();
    if (!context.mounted) {
      return;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final file =
          await const CollageExporter().export(controller.project, settings);
      navigator.pop();
      await Share.shareXFiles([XFile(file.path)]);
    } catch (error) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('Export fehlgeschlagen: $error')),
      );
    }
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
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolsPanel extends ConsumerWidget {
  const _ToolsPanel({required this.controller});

  final CollageEditorController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
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
            ThumbnailStrip(controller: controller),
            const SizedBox(height: 12),
            Text(strings.format, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final ratio in AspectRatios.all)
                  ChoiceChip(
                    label: Text(ratio.label),
                    selected: project.aspectRatioId == ratio.id,
                    onSelected: (_) => controller.setAspectRatio(ratio),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(strings.layout, style: Theme.of(context).textTheme.labelLarge),
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
            if (LayoutLibrary.byIdOrDefault(
              project.layoutTemplateId,
              project.photos.length,
            ).supportsStagger)
              _SliderTile(
                label: strings.stagger,
                value: project.canvas.staggerAmount,
                min: 0,
                max: 0.18,
                onChanged: (value) => controller.updateCanvas(
                  project.canvas.copyWith(staggerAmount: value),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showStyleSheet(context, controller),
                    icon: const Icon(Icons.tune),
                    label: Text(strings.style),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: controller.selectedPhoto == null
                        ? null
                        : () => _showPhotoSheet(context, controller),
                    icon: const Icon(Icons.crop),
                    label: Text(strings.photo),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => showTextOverlaySheet(context, controller),
                    icon: const Icon(Icons.text_fields),
                    label: Text(strings.textOverlay),
                  ),
                ),
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

  Widget _layoutChoice(
    BuildContext context,
    WidgetRef ref,
    LayoutTemplate layout,
    bool favorite,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ChoiceChip(
          label: Text(layout.title),
          selected: controller.project.layoutTemplateId == layout.id,
          onSelected: (_) => controller.setLayoutTemplate(layout.id),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: favorite
              ? AppLocalizations.of(context).removeFavorite
              : AppLocalizations.of(context).addFavorite,
          onPressed: () =>
              ref.read(designLibraryProvider.notifier).toggleFavorite(layout),
          icon: Icon(favorite ? Icons.star : Icons.star_border),
        ),
      ],
    );
  }

  Future<void> _showStyleSheet(
    BuildContext context,
    CollageEditorController controller,
  ) async {
    final strings = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final canvas = controller.project.canvas;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SliderTile(
                      label: strings.spacing,
                      value: canvas.spacing,
                      min: 0,
                      max: 32,
                      onChanged: (value) => controller.updateCanvas(
                        canvas.copyWith(spacing: value),
                      ),
                    ),
                    _SliderTile(
                      label: strings.outerMargin,
                      value: canvas.outerMargin,
                      min: 0,
                      max: 42,
                      onChanged: (value) => controller.updateCanvas(
                        canvas.copyWith(outerMargin: value),
                      ),
                    ),
                    _SliderTile(
                      label: strings.cornerRadius,
                      value: canvas.cornerRadius,
                      min: 0,
                      max: 42,
                      onChanged: (value) => controller.updateCanvas(
                        canvas.copyWith(cornerRadius: value),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(strings.background),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      children: [
                        for (final color in const [
                          0xFFFFFFFF,
                          0xFF000000,
                          0xFFF3F4F6,
                          0xFFEAF2FF,
                          0xFFFFF7ED,
                          0xFFF4F0FF,
                        ])
                          _ColorDot(
                            color: Color(color),
                            selected: canvas.backgroundColor == color,
                            onTap: () => controller.updateCanvas(
                              canvas.copyWith(backgroundColor: color),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showPhotoSheet(
    BuildContext context,
    CollageEditorController controller,
  ) async {
    final strings = AppLocalizations.of(context);
    final picker = ImagePicker();

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final photo = controller.selectedPhoto;
            if (photo == null) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Text(strings.noPhotoSelected),
              );
            }
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                          onPressed: controller.resetSelectedTransform,
                          icon: const Icon(Icons.restart_alt),
                          label: Text(strings.resetCrop),
                        ),
                        OutlinedButton.icon(
                          onPressed: controller.rotateSelected,
                          icon: const Icon(Icons.rotate_90_degrees_ccw),
                          label: Text(strings.rotate),
                        ),
                        OutlinedButton.icon(
                          onPressed: controller.flipSelected,
                          icon: const Icon(Icons.flip),
                          label: Text(strings.flip),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await picker.pickImage(
                              source: ImageSource.gallery,
                              requestFullMetadata: false,
                            );
                            if (picked != null) {
                              await controller.replaceSelected(picked);
                            }
                          },
                          icon: const Icon(Icons.swap_horiz),
                          label: Text(strings.replace),
                        ),
                        OutlinedButton.icon(
                          onPressed: controller.project.photos.length <= 1
                              ? null
                              : controller.removeSelected,
                          icon: const Icon(Icons.delete_outline),
                          label: Text(strings.remove),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

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
        ),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: selected ? 3 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black12),
            ),
            child: const SizedBox(width: 30, height: 30),
          ),
        ),
      ),
    );
  }
}
