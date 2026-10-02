import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/app_config.dart';
import '../../core/localization/app_localizations.dart';
import '../collage_editor/editor_page.dart';
import '../photo_import/selection_review_page.dart';
import '../projects/models/collage_project.dart';
import '../projects/state/project_providers.dart';
import '../settings/settings_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final projects = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Image.asset('assets/branding/app_logo.png', width: 34, height: 34),
          const SizedBox(width: 10),
          Expanded(
              child: Text(strings.appName, overflow: TextOverflow.ellipsis)),
        ]),
        actions: [
          IconButton(
            tooltip: strings.settings,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(projectsProvider.notifier).reload(),
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              FilledButton.icon(
                onPressed: () => _pickPhotos(context),
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(strings.newCollage),
              ),
              const SizedBox(height: 24),
              Text(
                strings.recentProjects,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              projects.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(strings.tr('operationFailed')),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return _EmptyProjects(strings: strings);
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 900
                          ? 3
                          : constraints.maxWidth >= 560
                              ? 2
                              : 1;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.55,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          return _ProjectCard(project: items[index]);
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhotos(BuildContext context) async {
    final strings = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(
      limit: AppConfig.maxPhotos,
      requestFullMetadata: false,
    );
    if (picked.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(strings.permissionOrPickerCancelled)),
      );
      return;
    }
    if (!context.mounted) {
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectionReviewPage(files: picked),
      ),
    );
  }
}

class _EmptyProjects extends StatelessWidget {
  const _EmptyProjects({required this.strings});

  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.auto_awesome_mosaic_outlined,
              size: 46,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              strings.emptyProjectsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              strings.emptyProjectsBody,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends ConsumerWidget {
  const _ProjectCard({required this.project});

  final CollageProject project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final firstPhoto = project.photos.isNotEmpty ? project.photos.first : null;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EditorPage(project: project)),
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (firstPhoto != null)
              Image.file(
                File(firstPhoto.localPath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const ColoredBox(color: Colors.black12),
              )
            else
              const ColoredBox(color: Colors.black12),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 44,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    project.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${project.photos.length} ${strings.tr('Fotos')} · ${project.aspectRatio.label}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 4,
              bottom: 2,
              child: PopupMenuButton<String>(
                iconColor: Colors.white,
                onSelected: (value) =>
                    _handleMenu(context, ref, value, project),
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'rename', child: Text(strings.rename)),
                  PopupMenuItem(
                      value: 'duplicate', child: Text(strings.duplicate)),
                  PopupMenuItem(value: 'delete', child: Text(strings.delete)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleMenu(
    BuildContext context,
    WidgetRef ref,
    String value,
    CollageProject project,
  ) async {
    final notifier = ref.read(projectsProvider.notifier);
    if (value == 'rename') {
      final name = await _askName(context, project.name);
      if (name != null) {
        await notifier.rename(project, name);
      }
    } else if (value == 'duplicate') {
      final copy = await notifier.duplicate(project);
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EditorPage(project: copy)),
        );
      }
    } else if (value == 'delete') {
      await notifier.delete(project);
    }
  }

  Future<String?> _askName(BuildContext context, String current) async {
    final strings = AppLocalizations.of(context);
    final controller = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.projectName),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: strings.projectName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(strings.done),
          ),
        ],
      ),
    );
  }
}
