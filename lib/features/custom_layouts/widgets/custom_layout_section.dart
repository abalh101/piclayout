import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../collage_editor/state/collage_editor_controller.dart';
import '../services/layout_builder_seed.dart';
import '../state/custom_layout_providers.dart';
import 'layout_builder_page.dart';

class CustomLayoutSection extends ConsumerWidget {
  const CustomLayoutSection({required this.controller, super.key});
  final CollageEditorController controller;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context).tr;
    final project = controller.project;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        OutlinedButton.icon(
            key: const ValueKey('open-layout-builder'),
            onPressed: () => showLayoutBuilder(context, controller),
            icon: const Icon(Icons.dashboard_customize_outlined),
            label: Text(t(project.customLayout == null
                ? 'customLayout'
                : 'editCustomLayout'))),
        OutlinedButton.icon(
            onPressed: () async {
              final seed = LayoutBuilderSeed.fromProject(project);
              if (seed.adjusted) {
                await showLayoutBuilder(context, controller);
              } else {
                await saveCustomLayoutDialog(context, ref, seed.layout);
              }
            },
            icon: const Icon(Icons.bookmark_add_outlined),
            label: Text(t('saveCustomLayout'))),
      ]),
      const SizedBox(height: 8),
      Text(t('myCustomLayouts'), style: Theme.of(context).textTheme.labelLarge),
      ref.watch(customLayoutsProvider).when(
          loading: () => const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))),
          error: (error, stack) => TextButton(
              onPressed: () => ref.invalidate(customLayoutsProvider),
              child: Text(t('customLayoutLoadFailed'))),
          data: (layouts) {
            final compatible = layouts
                .where((l) => l.photoCount == project.photos.length)
                .toList();
            if (compatible.isEmpty) {
              return Text(t('noCustomLayouts'),
                  style: Theme.of(context).textTheme.bodySmall);
            }
            return Wrap(spacing: 8, runSpacing: 6, children: [
              for (final layout in compatible)
                ChoiceChip(
                    label: Text(layout.name,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    selected: project.customLayout?.id == layout.id &&
                        project.customLayout?.updatedAt == layout.updatedAt,
                    onSelected: (_) => controller.applyCustomLayout(layout))
            ]);
          }),
    ]);
  }
}
