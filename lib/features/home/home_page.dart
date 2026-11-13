import '../demo_projects/demo_projects_page.dart';
import '../project_archive/project_archive_actions.dart';
import '../project_archive/project_archive_controller.dart';
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

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _picking = false;
  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final projects = ref.watch(projectsProvider);
    final archiveBusy = ref.watch(projectArchiveControllerProvider).busy;

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
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(18),
            children: [
              FilledButton.icon(
                onPressed:
                    _picking || archiveBusy ? null : () => _pickPhotos(context),
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(strings.newCollage),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const ValueKey('new-freeform'),
                onPressed: _picking || archiveBusy
                    ? null
                    : () => _newFreeform(context),
                icon: const Icon(Icons.dashboard_customize_outlined),
                label: Text(strings.tr('ffTitle')),
              ),
              OutlinedButton.icon(
                key: const ValueKey('import-project'),
                onPressed: archiveBusy
                    ? null
                    : () => importProjectArchive(context, ref),
                icon: const Icon(Icons.file_open_outlined),
                label: Text(strings.tr('archiveImport')),
              ),
              if (archiveBusy) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
                Text(strings.tr('archiveWorking')),
              ],
              OutlinedButton.icon(
                key: const ValueKey('open-demo'),
                onPressed: () => openDemoProjects(context),
                icon: const Icon(Icons.auto_awesome_mosaic_outlined),
                label: Text(strings.tr('demoOpen')),
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
                    child: Column(children: [
                      Text(strings.tr('operationFailed')),
                      TextButton(
                          onPressed: () =>
                              ref.read(projectsProvider.notifier).reload(),
                          child: Text(strings.tr('retry')))
                    ]),
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
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final picked = await ImagePicker().pickMultiImage(
          limit: AppConfig.maxPhotos, requestFullMetadata: false);
      if (!context.mounted || picked.isEmpty) return;
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => SelectionReviewPage(files: picked)));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context).tr('photoPickFailed'))));
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _newFreeform(BuildContext context) async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final project = await ref
          .read(projectRepositoryProvider)
          .createFromPickedImages([], freeform: true);
      await ref.read(projectsProvider.notifier).add(project);
      if (context.mounted) {
        await Navigator.push(context,
            MaterialPageRoute(builder: (_) => EditorPage(project: project)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context).tr('operationFailed'))));
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
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
              '${strings.emptyProjectsBody}\n\n${strings.tr('introLocal')}',
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
    final archiveBusy = ref.watch(projectArchiveControllerProvider).busy;
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
                cacheWidth: 640,
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
                  PopupMenuItem(
                      value: 'archive',
                      enabled: !archiveBusy,
                      child: Text(strings.tr('archiveExport'))),
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
    try {
      if (value == 'archive') {
        await exportProjectArchive(context, ref, project);
      } else if (value == 'rename') {
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
        final strings = AppLocalizations.of(context);
        final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text(strings.delete),
                  content: Text(strings
                      .tr('deleteProjectConfirm')
                      .replaceAll('{name}', project.name)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(strings.cancel)),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(strings.delete)),
                  ],
                ));
        if (confirmed == true) await notifier.delete(project);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context).tr('operationFailed'))));
      }
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
