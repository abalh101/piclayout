import '../../collage_editor/models/aspect_ratio_preset.dart';
import '../models/built_in_designs.dart';
import '../models/collage_template.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../collage_editor/state/collage_editor_controller.dart';
import '../state/design_library_providers.dart';
import 'template_preview.dart';
import '../../editorial/widgets/freeform_tools.dart';

Future<void> showSaveTemplateDialog(
  BuildContext context,
  WidgetRef ref,
  CollageEditorController controller,
) async {
  final strings = AppLocalizations.of(context);
  final input =
      await showDialog<({String name, bool includeText, bool includeStickers})>(
    context: context,
    builder: (_) => _SaveTemplateDialog(strings: strings),
  );
  if (input == null || !context.mounted) return;
  try {
    await ref.read(designLibraryProvider.notifier).saveTemplate(
          name: input.name,
          project: controller.project,
          includeTextOverlays: input.includeText,
          includeStickers: input.includeStickers,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.templateSaved)),
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.tr('operationFailed'))),
      );
    }
  }
}

class _SaveTemplateDialog extends StatefulWidget {
  const _SaveTemplateDialog({required this.strings});

  final AppLocalizations strings;

  @override
  State<_SaveTemplateDialog> createState() => _SaveTemplateDialogState();
}

class _SaveTemplateDialogState extends State<_SaveTemplateDialog> {
  final TextEditingController _nameController = TextEditingController();
  bool _includeText = false;
  bool _includeStickers = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.strings.saveAsTemplate),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                autofocus: true,
                maxLength: 60,
                decoration:
                    InputDecoration(labelText: widget.strings.templateName),
                onChanged: (_) => setState(() {}),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(widget.strings.tr('includeStickers')),
                value: _includeStickers,
                onChanged: (value) =>
                    setState(() => _includeStickers = value ?? false),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(widget.strings.includeTemplateText),
                value: _includeText,
                onChanged: (value) =>
                    setState(() => _includeText = value ?? false),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.strings.cancel),
          ),
          FilledButton(
            onPressed: _nameController.text.trim().isEmpty
                ? null
                : () => Navigator.pop(context, (
                      name: _nameController.text.trim(),
                      includeText: _includeText,
                      includeStickers: _includeStickers,
                    )),
            child: Text(widget.strings.saveTemplate),
          ),
        ],
      );
}

Future<void> showMyTemplatesSheet(
  BuildContext context,
  CollageEditorController controller,
) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _TemplatesSheet(controller),
    );

enum _TemplateCollection { all, favorites, recent }

class _TemplatesSheet extends ConsumerStatefulWidget {
  const _TemplatesSheet(this.controller);
  final CollageEditorController controller;

  @override
  ConsumerState<_TemplatesSheet> createState() => _TemplatesSheetState();
}

class _TemplatesSheetState extends ConsumerState<_TemplatesSheet> {
  String _query = '';
  bool _matchingCount = false;
  bool _matchingRatio = false;
  _TemplateCollection _collection = _TemplateCollection.all;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final t = strings.tr;
    final library = ref.watch(designLibraryProvider);
    final project = widget.controller.project;
    final theme = Theme.of(context);
    final notifier = ref.read(designLibraryProvider.notifier);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .82,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          children: [
            Text(strings.myTemplates, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: t('searchTemplates'),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 4, children: [
              for (final item in {
                _TemplateCollection.favorites: strings.favorites,
                _TemplateCollection.recent: t('recentTemplates'),
              }.entries)
                FilterChip(
                  label: Text(item.value),
                  selected: _collection == item.key,
                  onSelected: (selected) => setState(() => _collection =
                      selected ? item.key : _TemplateCollection.all),
                ),
              FilterChip(
                  label: Text(t('matchingPhotoCount')),
                  selected: _matchingCount,
                  onSelected: (value) =>
                      setState(() => _matchingCount = value)),
              FilterChip(
                  label: Text(t('matchingAspectRatio')),
                  selected: _matchingRatio,
                  onSelected: (value) =>
                      setState(() => _matchingRatio = value)),
            ]),
            const SizedBox(height: 12),
            ...library.when(
              loading: () => [const Center(child: CircularProgressIndicator())],
              error: (error, _) => [Text(t('operationFailed'))],
              data: (data) {
                final byId = {
                  for (final item in [...data.templates, ...BuiltInDesigns.all])
                    item.id: item
                };
                final candidates = switch (_collection) {
                  _TemplateCollection.all => byId.values,
                  _TemplateCollection.favorites =>
                    data.favoriteTemplateIds.map((id) => byId[id]).nonNulls,
                  _TemplateCollection.recent =>
                    data.recentTemplateIds.map((id) => byId[id]).nonNulls,
                };
                String title(CollageTemplate item) =>
                    item.id.startsWith('builtin_') ? t(item.name) : item.name;
                final filtered = candidates
                    .where((item) =>
                        title(item).toLowerCase().contains(_query) &&
                        (!_matchingCount ||
                            item.photoCount == project.photos.length) &&
                        (!_matchingRatio ||
                            (AspectRatios.byId(item.aspectRatioId).value -
                                        project.aspectRatio.value)
                                    .abs() <
                                .001))
                    .toList();
                if (filtered.isEmpty) return [Text(t('noMatchingTemplates'))];
                return [
                  for (final (index, item) in filtered.indexed) ...[
                    if (_collection == _TemplateCollection.all &&
                        item.id.startsWith('builtin_') &&
                        (index == 0 ||
                            !filtered[index - 1].id.startsWith('builtin_')))
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(t('builtInTemplates'),
                              style: theme.textTheme.titleSmall)),
                    Card(
                      child: ListTile(
                        leading: TemplatePreview(template: item),
                        title: Text(title(item)),
                        subtitle: Text(
                            '${item.photoCount} ${t('Fotos')} · ${AspectRatios.byId(item.aspectRatioId).label}'),
                        onTap: () async {
                          if (!item.design.freeform &&
                              (project.photos.isEmpty ||
                                  project.photos.length > 12)) {
                            _notice(context, t('ffGridLimit'));
                            return;
                          }
                          final ordered = item.design.freeform
                              ? await orderFreeformPhotos(
                                  context, widget.controller)
                              : null;
                          if (!context.mounted ||
                              (item.design.freeform && ordered == null)) {
                            return;
                          }
                          if (project.design.layers.isNotEmpty &&
                              !item.design.freeform) {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(t('edChangeDesign')),
                                content: Text(t('edChangeWarning')),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text(strings.cancel)),
                                  FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: Text(strings.applyTemplate)),
                                ],
                              ),
                            );
                            if (confirmed != true || !context.mounted) return;
                          }
                          final messenger = ScaffoldMessenger.of(context);
                          final adjusted =
                              item.photoCount != project.photos.length;
                          widget.controller
                              .applyTemplate(item, orderedPhotos: ordered);
                          Navigator.pop(context);
                          if (adjusted && !item.design.freeform) {
                            messenger.showSnackBar(SnackBar(
                                content: Text(strings.layoutAdjusted)));
                          }
                          try {
                            await notifier.recordTemplateUse(item.id);
                          } catch (_) {
                            messenger.showSnackBar(
                                SnackBar(content: Text(t('operationFailed'))));
                          }
                        },
                        trailing:
                            Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                            tooltip: data.favoriteTemplateIds.contains(item.id)
                                ? strings.removeFavorite
                                : strings.addFavorite,
                            icon: Icon(
                                data.favoriteTemplateIds.contains(item.id)
                                    ? Icons.star
                                    : Icons.star_border),
                            onPressed: () async {
                              try {
                                await notifier.toggleTemplateFavorite(item.id);
                              } catch (_) {
                                if (context.mounted) {
                                  _notice(context, t('operationFailed'));
                                }
                              }
                            },
                          ),
                          if (!item.id.startsWith('builtin_'))
                            IconButton(
                              tooltip: strings.delete,
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                try {
                                  await notifier.deleteTemplate(item.id);
                                } catch (_) {
                                  if (context.mounted) {
                                    _notice(context, t('operationFailed'));
                                  }
                                }
                              },
                            ),
                        ]),
                      ),
                    ),
                  ],
                ];
              },
            ),
          ],
        ),
      ),
    );
  }

  void _notice(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
}
