import '../../collage_editor/models/aspect_ratio_preset.dart';
import '../../collage_editor/models/photo_placement.dart';
import '../../collage_editor/rendering/layout_geometry.dart';
import '../models/built_in_designs.dart';
import '../models/collage_template.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../collage_editor/layouts/layout_library.dart';
import '../../collage_editor/state/collage_editor_controller.dart';
import '../state/design_library_providers.dart';

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
                        leading: SizedBox(
                            width: 54,
                            height: 52,
                            child:
                                CustomPaint(painter: _TemplatePreview(item))),
                        title: Text(title(item)),
                        subtitle: Text(
                            '${item.photoCount} ${t('Fotos')} · ${AspectRatios.byId(item.aspectRatioId).label}'),
                        onTap: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final adjusted =
                              item.photoCount != project.photos.length;
                          widget.controller.applyTemplate(item);
                          Navigator.pop(context);
                          if (adjusted) {
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

class _TemplatePreview extends CustomPainter {
  const _TemplatePreview(this.template);
  final CollageTemplate template;

  @override
  void paint(Canvas canvas, Size size) {
    if (template.photoCount < 1 || template.photoCount > 12) return;
    final ratio = AspectRatios.byId(template.aspectRatioId).value;
    final width = (size.height * ratio).clamp(0, size.width).toDouble();
    final extent = Size(width, width / ratio);
    final origin = (Offset.zero & size).center -
        Offset(extent.width / 2, extent.height / 2);
    final area = Offset.zero & extent;
    final background = Color(template.canvas.backgroundColor);
    final ink =
        background.computeLuminance() > .40 ? Colors.black : Colors.white;
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.clipRRect(RRect.fromRectAndRadius(area, const Radius.circular(4)));
    canvas.drawColor(background, BlendMode.srcOver);
    final paint = Paint()..color = ink.withValues(alpha: .30);
    if (template.freestyle) {
      for (final placement in template.placements) {
        final item = placement ?? const PhotoPlacement();
        if (item.hidden) continue;
        final rect = item.rect(extent);
        canvas.save();
        canvas.translate(rect.center.dx, rect.center.dy);
        canvas.rotate(item.radians);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                rect.shift(-rect.center), const Radius.circular(2)),
            paint);
        canvas.restore();
      }
    } else {
      final layout = LayoutLibrary.byIdOrDefault(
          template.layoutTemplateId, template.photoCount);
      final style = template.canvas;
      final cells = template.customLayout?.layoutCells ??
          LayoutLibrary.cellsFor(layout, staggerAmount: style.staggerAmount);
      for (final cell in LayoutGeometry.resolveCells(cells, extent,
          spacing: style.spacing + 4,
          outerMargin: style.outerMargin,
          cornerRadius: style.cornerRadius)) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                cell.rect, Radius.circular(cell.cornerRadius)),
            paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TemplatePreview oldDelegate) =>
      oldDelegate.template != template;
}
