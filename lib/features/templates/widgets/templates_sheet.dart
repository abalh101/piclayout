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
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        final strings = AppLocalizations.of(context);
        final library = ref.watch(designLibraryProvider);
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.myTemplates,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Flexible(
                    child: library.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) =>
                          Center(child: Text(strings.tr('operationFailed'))),
                      data: (data) => data.templates.isEmpty
                          ? Center(child: Text(strings.noTemplates))
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: data.templates.length,
                              itemBuilder: (context, index) {
                                final template = data.templates[index];
                                return ListTile(
                                  title: Text(template.name),
                                  subtitle: Text(
                                    '${template.photoCount} ${strings.photo} · ${template.aspectRatioId}',
                                  ),
                                  onTap: () {
                                    final messenger =
                                        ScaffoldMessenger.of(context);
                                    final resolved =
                                        LayoutLibrary.byIdOrDefault(
                                      template.layoutTemplateId,
                                      controller.project.photos.length,
                                    );
                                    final adjusted = template.customLayout !=
                                            null
                                        ? template.customLayout!.photoCount !=
                                            controller.project.photos.length
                                        : resolved.id !=
                                            template.layoutTemplateId;
                                    controller.applyTemplate(template);
                                    Navigator.pop(sheetContext);
                                    if (adjusted) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                            content:
                                                Text(strings.layoutAdjusted)),
                                      );
                                    }
                                  },
                                  trailing: IconButton(
                                    tooltip: strings.delete,
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => ref
                                        .read(designLibraryProvider.notifier)
                                        .deleteTemplate(template.id),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
