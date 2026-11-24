import '../demo_projects/demo_projects_page.dart';
import '../project_archive/project_archive_actions.dart';
import '../project_archive/project_archive_controller.dart';
import '../collage_editor/widgets/styled_collage_scene.dart';

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
        child: LayoutBuilder(builder: (context, constraints) {
          final inset =
              ((constraints.maxWidth - 1120) / 2).clamp(18.0, double.infinity);
          final columns = constraints.maxWidth >= 900
              ? 3
              : constraints.maxWidth >= 560
                  ? 2
                  : 1;
          final colors = Theme.of(context).colorScheme;
          final text = Theme.of(context).textTheme;
          return RefreshIndicator(
            onRefresh: () => ref.read(projectsProvider.notifier).reload(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(inset, 10, inset, 12),
                  sliver: SliverToBoxAdapter(
                    child: Card(
                      margin: EdgeInsets.zero,
                      color: colors.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FilledButton.icon(
                              onPressed: _picking || archiveBusy
                                  ? null
                                  : () => _pickPhotos(context),
                              icon: const Icon(
                                  Icons.add_photo_alternate_outlined),
                              label: Text(strings.newCollage),
                            ),
                            OutlinedButton.icon(
                              key: const ValueKey('new-freeform'),
                              onPressed: _picking || archiveBusy
                                  ? null
                                  : () => _newFreeform(context),
                              icon: const Icon(
                                  Icons.dashboard_customize_outlined),
                              label: Text(strings.tr('ffTitle')),
                            ),
                            const SizedBox(height: 8),
                            Wrap(spacing: 8, runSpacing: 6, children: [
                              TextButton.icon(
                                key: const ValueKey('import-project'),
                                onPressed: archiveBusy
                                    ? null
                                    : () => importProjectArchive(context, ref),
                                icon: const Icon(Icons.file_open_outlined),
                                label: Text(strings.tr('archiveImport')),
                              ),
                              TextButton.icon(
                                key: const ValueKey('open-demo'),
                                onPressed: () => openDemoProjects(context),
                                icon: const Icon(
                                    Icons.auto_awesome_mosaic_outlined),
                                label: Text(strings.tr('demoOpen')),
                              ),
                            ]),
                            if (archiveBusy) ...[
                              const SizedBox(height: 8),
                              const LinearProgressIndicator(),
                              Text(strings.tr('archiveWorking')),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(inset, 10, inset, 12),
                  sliver: SliverToBoxAdapter(
                      child:
                          Text(strings.recentProjects, style: text.titleLarge)),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(inset, 0, inset, 24),
                  sliver: projects.when(
                    loading: () => const SliverToBoxAdapter(
                        child: Center(
                      child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator()),
                    )),
                    error: (_, __) => SliverToBoxAdapter(
                        child: Card(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(strings.tr('operationFailed'))),
                    )),
                    data: (items) => items.isEmpty
                        ? SliverToBoxAdapter(
                            child: _EmptyProjects(strings: strings))
                        : SliverGrid.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              mainAxisExtent: 204,
                            ),
                            itemCount: items.length,
                            itemBuilder: (context, index) =>
                                _ProjectCard(project: items[index]),
                          ),
                  ),
                ),
              ],
            ),
          );
        }),
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
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EditorPage(project: project)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ColoredBox(
                color: theme.colorScheme.surfaceContainerHigh,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: AspectRatio(
                        aspectRatio: project.aspectRatio.value,
                        child: ExcludeSemantics(
                            child: StyledCollageScene(
                          project: project,
                          maxEdge: 320,
                          showOverlays: true,
                        )),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(
                  start: 12, end: 4, top: 4, bottom: 4),
              child: Row(
                children: [
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(project.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall),
                      Text(
                        '${project.photos.length} ${strings.tr('Fotos')} · ${project.aspectRatio.label}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  )),
                  PopupMenuButton<String>(
                    onSelected: (value) =>
                        _handleMenu(context, ref, value, project),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                          value: 'archive',
                          enabled: !archiveBusy,
                          child: Text(strings.tr('archiveExport'))),
                      PopupMenuItem(
                          value: 'rename', child: Text(strings.rename)),
                      PopupMenuItem(
                          value: 'duplicate', child: Text(strings.duplicate)),
                      PopupMenuItem(
                          value: 'delete', child: Text(strings.delete)),
                    ],
                  ),
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
