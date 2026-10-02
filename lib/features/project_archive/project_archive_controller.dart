import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../projects/models/collage_project.dart';
import 'project_archive_service.dart';

abstract interface class ProjectArchivePlatform {
  Future<XFile?> pickProject();
  Future<void> shareProject(File file, Rect origin);
}

class NativeProjectArchivePlatform implements ProjectArchivePlatform {
  @override
  Future<XFile?> pickProject() => openFile();
  // Custom extensions are not consistently exposed by document providers.
  // Validate the chosen name and archive contents after selection instead.
  @override
  Future<void> shareProject(File file, Rect origin) async {
    await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/octet-stream')],
        sharePositionOrigin: origin);
  }
}

final projectArchiveControllerProvider =
    ChangeNotifierProvider((ref) => ProjectArchiveController(
        platform: NativeProjectArchivePlatform(),
        service: () async {
          final info = await PackageInfo.fromPlatform();
          return ProjectArchiveService(
              documentsDirectory: await getApplicationDocumentsDirectory(),
              temporaryDirectory: await getTemporaryDirectory(),
              createdWithAppVersion: '${info.version}+${info.buildNumber}');
        }));

class ProjectArchiveController extends ChangeNotifier {
  ProjectArchiveController({required this.platform, required this.service});
  final ProjectArchivePlatform platform;
  final Future<ProjectArchiveService> Function() service;
  bool busy = false;
  bool _disposed = false;
  void _setBusy(bool value) {
    busy = value;
    if (!_disposed) notifyListeners();
  }

  Future<CollageProject?> importProject() async {
    if (busy) return null;
    _setBusy(true);
    try {
      final picked = await platform.pickProject();
      if (picked == null) return null;
      if (!picked.name.toLowerCase().endsWith('.piclayout')) {
        throw const ProjectArchiveException('archiveWrongFile');
      }
      return await (await service()).importProject(File(picked.path));
    } on ProjectArchiveException {
      rethrow;
    } catch (_) {
      throw const ProjectArchiveException('archivePickerError');
    } finally {
      _setBusy(false);
    }
  }

  Future<void> exportProject(CollageProject project, Rect origin) async {
    if (busy) return;
    _setBusy(true);
    File? file;
    try {
      file = await (await service()).exportProject(project);
      try {
        await platform.shareProject(file, origin);
      } catch (_) {
        throw const ProjectArchiveException('archiveShareError');
      }
    } on ProjectArchiveException {
      rethrow;
    } catch (_) {
      throw const ProjectArchiveException('archiveStorageError');
    } finally {
      if (file != null) {
        try {
          await file.parent.delete(recursive: true);
        } on FileSystemException {/* OS temp cleanup remains available. */}
      }
      _setBusy(false);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
