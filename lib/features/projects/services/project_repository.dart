import '../../layout_recommendations/photo_metadata_reader.dart';
import '../../layout_recommendations/layout_recommendation_service.dart';
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
    await for (final entity in root.list(followLinks: false)) {
      if (entity is! Directory) {
        continue;
      }
      final file = File(p.join(entity.path, 'project.json'));
      final id = p.basename(entity.path);
      final primary = await _readProject(file, id);
      final project = primary ??
          await _readProject(File('${file.path}.bak'), id) ??
          await _readProject(File('${file.path}.tmp'), id) ??
          await _readProject(File('${file.path}.pending'), id);
      if (project == null) continue;
      projects.add(project.copyWith(
        recovered: primary == null,
        photos: [
          for (final photo in project.photos)
            photo.copyWith(
              localPath:
                  p.join(entity.path, 'images', p.basename(photo.localPath)),
            ),
        ],
      ));
    }
    projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return projects;
  }

  Future<CollageProject> createFromPickedImages(List<XFile> picked,
      {String aspectRatioId = '9_16'}) async {
    if (picked.isEmpty) throw ArgumentError.value(picked, 'picked');
    final now = DateTime.now();
    return _withNewProjectDirectory((dir) async {
      final projectId = p.basename(dir.path);
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
            metadata: await const PhotoMetadataReader().read(target.path),
          ),
        );
      }

      final recommendations = const LayoutRecommendationService().recommend(
          photos,
          targetRatio: AspectRatios.byId(aspectRatioId).value);
      final template = recommendations.isEmpty
          ? LayoutLibrary.defaultFor(photos.length)
          : recommendations.first.layout;
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
    });
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
    final previous = await _readProject(file, project.id);
    if (previous != null) {
      await _atomicWrite(File('${file.path}.bak'), await file.readAsString());
    } else {
      final backup = File('${file.path}.bak');
      if (await _readProject(backup, project.id) == null) {
        for (final suffix in ['tmp', 'pending']) {
          final pending = File('${file.path}.$suffix');
          if (await _readProject(pending, project.id) == null) continue;
          await _atomicWrite(backup, await pending.readAsString());
          break;
        }
      }
    }
    await _atomicWrite(
      file,
      const JsonEncoder.withIndent('  ').convert(json),
    );
  }

  Future<CollageProject?> _readProject(File file, String expectedId) async {
    try {
      final json = jsonDecode(await file.readAsString());
      if (json is! Map<String, dynamic> || json['id'] != expectedId) {
        return null;
      }
      final project = CollageProject.fromJson(json);
      if (project.photos.isEmpty ||
          project.photos.length > AppConfig.maxPhotos ||
          project.photos.map((photo) => photo.id).toSet().length !=
              project.photos.length ||
          project.photos.any((photo) =>
              ['', '.', '..'].contains(p.basename(photo.localPath)))) {
        return null;
      }
      return project;
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<void> _atomicWrite(File destination, String contents) async {
    final pending = File('${destination.path}.pending');
    await pending.writeAsString(contents, flush: true);
    await pending.rename(destination.path);
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
      metadata: await const PhotoMetadataReader().read(target.path),
    );
  }

  Future<CollageProject> duplicate(CollageProject source) async {
    final now = DateTime.now();
    return _withNewProjectDirectory((dir) async {
      final projectId = p.basename(dir.path);
      final imageDir = Directory(p.join(dir.path, 'images'))
        ..createSync(recursive: true);

      final photos = <PhotoAsset>[];
      for (final photo in source.photos) {
        final newPhotoId = _uuid.v4();
        final extension = p.extension(photo.localPath);
        final target = File(p.join(imageDir.path, '$newPhotoId$extension'));
        final original = File(photo.localPath);
        if (await original.exists()) await original.copy(target.path);
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
        recovered: false,
      );
      await save(copy);
      return copy;
    });
  }

  Future<void> rename(CollageProject project, String name) async {
    await save(
        project.copyWith(name: name.trim().isEmpty ? project.name : name));
  }

  Future<void> delete(CollageProject project) async {
    await _pendingSaves[project.id]?.catchError((Object _) {});
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

  Future<T> _withNewProjectDirectory<T>(
      Future<T> Function(Directory) create) async {
    final directory = await _newProjectDirectory();
    try {
      return await create(directory);
    } catch (_) {
      try {
        await directory.delete(recursive: true);
      } on FileSystemException {
        // Preserve the original import or write error.
      }
      rethrow;
    }
  }

  Future<Directory> _newProjectDirectory() async {
    final root = await _projectsRoot();
    for (var attempt = 0; attempt < 5; attempt++) {
      final path = p.join(root.path, _uuid.v4());
      if (FileSystemEntity.typeSync(path, followLinks: false) ==
          FileSystemEntityType.notFound) {
        return Directory(path)..createSync();
      }
    }
    throw FileSystemException(
        'Could not allocate a unique project directory', root.path);
  }

  Future<Directory> _projectDirectory(
    String projectId, {
    bool create = false,
  }) async {
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(projectId)) {
      throw ArgumentError.value(projectId, 'projectId');
    }
    final root = await _projectsRoot();
    final dir = Directory(p.join(root.path, projectId));
    if (create) {
      dir.createSync(recursive: true);
    }
    return dir;
  }
}
