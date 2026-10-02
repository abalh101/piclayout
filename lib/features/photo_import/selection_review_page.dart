import '../settings/state/settings_controller.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/app_config.dart';
import '../../core/localization/app_localizations.dart';
import '../collage_editor/editor_page.dart';
import '../projects/state/project_providers.dart';

class SelectionReviewPage extends ConsumerStatefulWidget {
  const SelectionReviewPage({
    required this.files,
    super.key,
  });

  final List<XFile> files;

  @override
  ConsumerState<SelectionReviewPage> createState() =>
      _SelectionReviewPageState();
}

class _SelectionReviewPageState extends ConsumerState<SelectionReviewPage> {
  late final List<XFile> _files =
      widget.files.take(AppConfig.maxPhotos).toList();
  bool _creating = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.selectedPhotos)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _files.length,
                onReorderItem: (oldIndex, newIndex) {
                  setState(() {
                    final file = _files.removeAt(oldIndex);
                    _files.insert(newIndex, file);
                  });
                },
                itemBuilder: (context, index) {
                  final file = _files[index];
                  return Card(
                    key: ValueKey(file.path),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(
                          File(file.path),
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text('${strings.tr('Bild')} ${index + 1}'),
                      subtitle: Text(
                        file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        tooltip: strings.remove,
                        icon: const Icon(Icons.close),
                        onPressed: _files.length <= 1
                            ? null
                            : () => setState(() => _files.removeAt(index)),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: _creating || _files.isEmpty ? null : _createProject,
                icon: _creating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_mosaic),
                label: Text(strings.createCollage),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createProject() async {
    setState(() => _creating = true);
    final navigator = Navigator.of(context);
    final repository = ref.read(projectRepositoryProvider);
    final projects = ref.read(projectsProvider.notifier);
    try {
      final defaults = await ref.read(settingsControllerProvider.future);
      final project = await repository.createFromPickedImages(_files,
          aspectRatioId: defaults.aspectRatioId);
      await projects.add(project);
      if (!mounted) {
        return;
      }
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => EditorPage(project: project)),
      );
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }
}
