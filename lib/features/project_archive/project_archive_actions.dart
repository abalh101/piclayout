import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../projects/models/collage_project.dart';
import '../projects/state/project_providers.dart';
import 'project_archive_controller.dart';
import 'project_archive_service.dart';

Future<void> importProjectArchive(BuildContext context, WidgetRef ref) async {
  final controller = ref.read(projectArchiveControllerProvider);
  if (controller.busy) return;
  final strings = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  // Capture before awaiting; the home page may be removed during the picker.
  final projects = ref.read(projectsProvider.notifier);
  try {
    final imported = await controller.importProject();
    if (imported != null) await projects.reload();
    if (context.mounted) {
      messenger.showSnackBar(SnackBar(
          content: Text(strings
              .tr(imported == null ? 'archiveCancelled' : 'archiveImported'))));
    }
  } on ProjectArchiveException catch (error) {
    if (context.mounted) {
      messenger.showSnackBar(SnackBar(content: Text(strings.tr(error.key))));
    }
  }
}

Future<void> exportProjectArchive(
    BuildContext context, WidgetRef ref, CollageProject project) async {
  final controller = ref.read(projectArchiveControllerProvider);
  if (controller.busy) return;
  final strings = AppLocalizations.of(context);
  final box = context.findRenderObject() as RenderBox?;
  final origin = box == null
      ? const Rect.fromLTWH(0, 0, 1, 1)
      : box.localToGlobal(Offset.zero) & box.size;
  try {
    await controller.exportProject(project, origin);
  } on ProjectArchiveException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.tr(error.key))));
    }
  }
}
