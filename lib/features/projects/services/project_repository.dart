import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../app/app_config.dart';
import '../../collage_editor/layouts/layout_library.dart';
import '../../collage_editor/models/aspect_ratio_preset.dart';
import '../../collage_editor/models/photo_asset.dart';
import '../models/collage_project.dart';

class ProjectRepository {
  ProjectRepository({Uuid? uuid, Directory? documentsDirectory})
      : _uuid = uuid ?? const Uuid(),
        _documentsDirectory = documentsDirectory;

  final Uuid _uuid;
  final Directory? _documentsDirectory;
  final Map<String, Future<void>> _pendingSaves = {};

  Future<List<CollageProject>> loadProjects() async {
    final root = await _projectsRoot();
    if (!root.existsSync()) {
      return [];
    }

    final projects = <CollageProject>[];
    await for (final entity in root.list()) {
      if (entity is! Directory) {
        continue;
      }
      final file = File(p.join(entity.path, 'project.json'));
      if (!file.existsSync()) {
        continue;
      }
      try {
        final json =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        final project = CollageProject.fromJson(json);
        projects.add(project.copyWith(
          photos: [
            for (final photo in project.photos)
              photo.copyWith(
                localPath:
                    p.join(entity.path, 'images', p.basename(photo.localPath)),
              ),
          ],
        ));
      } catch (_) {
        // Corrupt projects are ignored here and can be handled by a repair flow later.
      }
    }
    projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return projects;
  }

  Future<CollageProject> createFromPickedImages(List<XFile> picked,
      {String aspectRatioId = '9_16'}) async {
    final now = DateTime.now();
    final projectId = _uuid.v4();
    final dir = await _projectDirectory(projectId, create: true);
    final imageDir = Directory(p.join(dir.path, 'images'))
      ..createSync(recursive: true);
    final photos = <PhotoAsset>[];

    for (var i = 0; i < picked.length && i < AppConfig.maxPhotos; i++) {
      final source = picked[i];
      final extension = p.extension(source.path).isEmpty
          ? '.jpg'
          : p.extension(source.path).toLowerCase();
      final photoId = _uuid.v4();
      final target = File(p.join(imageDir.path, '$photoId$extension'));
      await File(source.path).copy(target.path);
      photos.add(
        PhotoAsset(
          id: photoId,
          originalFileName: p.basename(source.path),
          localPath: target.path,
        ),
      );
    }

    final template = LayoutLibrary.defaultFor(photos.length);
    final project = CollageProject(
      id: projectId,
      name: 'Collage ${now.day}.${now.month}.${now.year}',
      createdAt: now,
      updatedAt: now,
      formatVersion: AppConfig.projectFormatVersion,
      aspectRatioId: AspectRatios.byId(aspectRatioId).id,
      layoutTemplateId: template.id,
      photos: photos,
    );
    await save(project);
    return project;
  }

  Future<void> save(CollageProject project) async {
    final previous = _pendingSaves[project.id] ?? Future<void>.value();
    final pending = previous.catchError((Object _) {}).then(
          (_) => _writeProject(project),
        );
    _pendingSaves[project.id] = pending;
    pending.then(
      (_) {
        if (identical(_pendingSaves[project.id], pending)) {
          _pendingSaves.remove(project.id);
        }
      },
      onError: (Object _, StackTrace __) {
        if (identical(_pendingSaves[project.id], pending)) {
          _pendingSaves.remove(project.id);
        }
      },
    );
    return pending;
  }

  Future<void> _writeProject(CollageProject project) async {
    final dir = await _projectDirectory(project.id, create: true);
    final file = File(p.join(dir.path, 'project.json'));
    final tmp = File('${file.path}.tmp');
    final normalized = project.normalizedForPhotoCount().copyWith(
          updatedAt: DateTime.now(),
        );
    final json = normalized.toJson();
    json['photos'] = [
      for (final photo in normalized.photos)
        {
          ...photo.toJson(),
          'localPath': p.join('images', p.basename(photo.localPath))
        },
    ];
    await tmp.writeAsString(
      const JsonEncoder.withIndent('  ').convert(json),
      flush: true,
    );
    if (file.existsSync()) {
      await file.delete();
    }
    await tmp.rename(file.path);
  }

  Future<PhotoAsset> importReplacement(XFile picked, String projectId) async {
    final dir = await _projectDirectory(projectId, create: true);
    final imageDir = Directory(p.join(dir.path, 'images'))
      ..createSync(recursive: true);
    final photoId = _uuid.v4();
    final extension = p.extension(picked.path).isEmpty
        ? '.jpg'
        : p.extension(picked.path).toLowerCase();
    final target = File(p.join(imageDir.path, '$photoId$extension'));
    await File(picked.path).copy(target.path);
    return PhotoAsset(
      id: photoId,
      originalFileName: p.basename(picked.path),
      localPath: target.path,
    );
  }

  Future<CollageProject> duplicate(CollageProject source) async {
    final now = DateTime.now();
    final projectId = _uuid.v4();
    final dir = await _projectDirectory(projectId, create: true);
    final imageDir = Directory(p.join(dir.path, 'images'))
      ..createSync(recursive: true);

    final photos = <PhotoAsset>[];
    for (final photo in source.photos) {
      final newPhotoId = _uuid.v4();
      final extension = p.extension(photo.localPath);
      final target = File(p.join(imageDir.path, '$newPhotoId$extension'));
      await File(photo.localPath).copy(target.path);
      photos.add(
        photo.copyWith(
          id: newPhotoId,
          localPath: target.path,
        ),
      );
    }

    final copy = source.copyWith(
      id: projectId,
      name: '${source.name} Kopie',
      createdAt: now,
      updatedAt: now,
      photos: photos,
    );
    await save(copy);
    return copy;
  }

  Future<void> rename(CollageProject project, String name) async {
    await save(
        project.copyWith(name: name.trim().isEmpty ? project.name : name));
  }

  Future<void> delete(CollageProject project) async {
    final dir = await _projectDirectory(project.id);
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  }

  Future<Directory> _projectsRoot() async {
    final docs =
        _documentsDirectory ?? await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'piclayout_projects'))
      ..createSync(recursive: true);
  }

  Future<Directory> _projectDirectory(
    String projectId, {
    bool create = false,
  }) async {
    final root = await _projectsRoot();
    final dir = Directory(p.join(root.path, projectId));
    if (create) {
      dir.createSync(recursive: true);
    }
    return dir;
  }
}
