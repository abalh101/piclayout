import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../../app/app_config.dart';
import '../projects/models/collage_project.dart';
import '../collage_editor/models/photo_asset.dart';

class ProjectArchiveException implements Exception {
  const ProjectArchiveException(this.key);
  final String key;
  factory ProjectArchiveException.storage(FileSystemException error) =>
      ProjectArchiveException([28, 112].contains(error.osError?.errorCode)
          ? 'archiveNoSpace'
          : 'archiveStorageError');
}

/// Version 1: ZIP, manifest.json, project.json, images/0.png ... images/11.png.
class ProjectArchiveService {
  ProjectArchiveService(
      {required this.documentsDirectory,
      required this.temporaryDirectory,
      this.createdWithAppVersion = 'unknown'});
  final Directory documentsDirectory, temporaryDirectory;
  final String createdWithAppVersion;
  static const archiveVersion = 1;
  static const maxBytes = 128 * 1024 * 1024;
  static const maxImageBytes = 32 * 1024 * 1024;
  static const maxJsonBytes = 1024 * 1024;

  Future<File> exportProject(CollageProject project) async {
    Directory? output;
    try {
      if (project.formatVersion != AppConfig.projectFormatVersion) {
        throw const ProjectArchiveException('archiveVersionError');
      }
      if (project.photos.isEmpty ||
          project.photos.length > AppConfig.maxPhotos) {
        throw const ProjectArchiveException('archiveInvalid');
      }
      final root =
          Directory(p.join(documentsDirectory.path, 'piclayout_projects'));
      if (!_safeId(project.id)) {
        throw const ProjectArchiveException('archiveMissingImages');
      }
      final sourceDir = Directory(p.join(root.path, project.id, 'images'));
      if (!await sourceDir.exists()) {
        throw const ProjectArchiveException('archiveMissingImages');
      }
      final canonicalRoot = await root.resolveSymbolicLinks();
      final canonicalImages = await sourceDir.resolveSymbolicLinks();
      if (!p.isWithin(canonicalRoot, canonicalImages)) {
        throw const ProjectArchiveException('archiveMissingImages');
      }
      final files = <String, Uint8List>{};
      final photos = <PhotoAsset>[];
      var total = 0;
      for (var i = 0; i < project.photos.length; i++) {
        final photo = project.photos[i];
        final file = File(photo.localPath);
        if (!await file.exists()) {
          throw const ProjectArchiveException('archiveMissingImages');
        }
        final source = await file.resolveSymbolicLinks();
        if (!p.isWithin(canonicalImages, source)) {
          throw const ProjectArchiveException('archiveMissingImages');
        }
        if (await file.length() > maxImageBytes) {
          throw const ProjectArchiveException('archiveTooLarge');
        }
        final bytes = await _portableImage(await file.readAsBytes());
        total += bytes.length;
        if (total > maxBytes - 2 * maxJsonBytes) {
          throw const ProjectArchiveException('archiveTooLarge');
        }
        final name = 'images/$i.png';
        files[name] = bytes;
        photos.add(photo.copyWith(localPath: name, originalFileName: '$i.png'));
      }
      final json = project.copyWith(photos: photos).toJson();
      files['project.json'] = Uint8List.fromList(utf8.encode(jsonEncode(json)));
      files['manifest.json'] = Uint8List.fromList(utf8.encode(jsonEncode({
        'format': 'piclayout',
        'archiveVersion': archiveVersion,
        'projectFormatVersion': project.formatVersion,
        'createdWithAppVersion': createdWithAppVersion,
      })));
      if (files['project.json']!.length > maxJsonBytes) {
        throw const ProjectArchiveException('archiveTooLarge');
      }
      final encoded = await Isolate.run(() {
        final archive = Archive();
        for (final entry in files.entries) {
          archive.add(ArchiveFile.noCompress(
              entry.key, entry.value.length, entry.value));
        }
        return ZipEncoder().encode(archive);
      });
      await temporaryDirectory.create(recursive: true);
      output = await temporaryDirectory.createTemp('piclayout_archive_');
      var name = project.name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
      if (name.length > 60) name = name.substring(0, 60);
      if (name.isEmpty) name = 'collage';
      final file =
          File(p.join(output.path, 'piclayout_project_$name.piclayout'));
      await file.writeAsBytes(encoded, flush: true);
      return file;
    } catch (error) {
      if (output != null && await output.exists()) {
        await output.delete(recursive: true);
      }
      throw _mapped(error);
    }
  }

  Future<CollageProject> importProject(File file) async {
    Directory? staging;
    try {
      if (await file.length() > maxBytes) {
        throw const ProjectArchiveException('archiveTooLarge');
      }
      final bytes = await file.readAsBytes();
      final decoded = await Isolate.run(() => _decode(bytes));
      final source = CollageProject.fromJson(decoded.project);
      final id = const Uuid().v4();
      final root =
          Directory(p.join(documentsDirectory.path, 'piclayout_projects'));
      await root.create(recursive: true);
      // No project.json is visible until the entire import is ready.
      staging = await documentsDirectory.createTemp('.piclayout_import_');
      final images = Directory(p.join(staging.path, 'images'));
      await images.create();
      final destination = Directory(p.join(root.path, id));
      final photos = <PhotoAsset>[];
      var importedBytes = 0;
      for (final photo in source.photos) {
        final image = decoded.images[photo.localPath]!;
        // Validate decoding and strip any metadata, including for external archives.
        final portable = await _portableImage(image);
        importedBytes += portable.length;
        if (importedBytes > maxBytes) {
          throw const ProjectArchiveException('archiveTooLarge');
        }
        final photoId = const Uuid().v4();
        final name = '$photoId.png';
        await File(p.join(images.path, name))
            .writeAsBytes(portable, flush: true);
        photos.add(photo.copyWith(
            id: photoId,
            originalFileName: name,
            localPath: p.join(destination.path, 'images', name)));
      }
      final now = DateTime.now();
      final project = source.copyWith(
          id: id,
          photos: photos,
          createdAt: now,
          updatedAt: now,
          formatVersion: AppConfig.projectFormatVersion);
      final localJson = project.toJson();
      localJson['photos'] = [
        for (final photo in project.photos)
          {
            ...photo.toJson(),
            'localPath': 'images/${p.basename(photo.localPath)}'
          }
      ];
      await File(p.join(staging.path, 'project.json'))
          .writeAsString(jsonEncode(localJson), flush: true);
      await staging.rename(destination.path);
      staging = null;
      return project;
    } catch (error) {
      if (staging != null && await staging.exists()) {
        await staging.delete(recursive: true);
      }
      throw _mapped(error);
    }
  }

  static bool _safeId(String value) =>
      RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value);
  static ProjectArchiveException _mapped(Object error) {
    if (error is ProjectArchiveException) return error;
    if (error is FileSystemException) {
      return ProjectArchiveException.storage(error);
    }
    return const ProjectArchiveException('archiveInvalid');
  }

  static Future<Uint8List> _portableImage(Uint8List bytes) async {
    if (bytes.length > maxImageBytes) {
      throw const ProjectArchiveException('archiveTooLarge');
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      if (descriptor.width * descriptor.height > 40000000) {
        throw const ProjectArchiveException('archiveTooLarge');
      }
      codec = await descriptor.instantiateCodec();
      image = (await codec.getNextFrame()).image;
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw const ProjectArchiveException('archiveInvalid');
      if (data.lengthInBytes > maxImageBytes) {
        throw const ProjectArchiveException('archiveTooLarge');
      }
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer.dispose();
    }
  }
}

class _Decoded {
  const _Decoded(this.project, this.images);
  final Map<String, Object?> project;
  final Map<String, Uint8List> images;
}

_Decoded _decode(Uint8List bytes) {
  try {
    final directory = ZipDirectory()..read(InputMemoryStream(bytes));
    final headers = directory.fileHeaders;
    if (headers.length < 2 ||
        headers.length > AppConfig.maxPhotos + 2 ||
        directory.numberOfThisDisk != 0 ||
        directory.diskWithTheStartOfTheCentralDirectory != 0) {
      throw const ProjectArchiveException('archiveInvalid');
    }
    final names = <String>{};
    var total = 0;
    for (final h in headers) {
      final name = h.filename;
      final isJson = name == 'manifest.json' || name == 'project.json';
      if (!names.add(name) ||
          (!isJson &&
              !RegExp(r'^images/[a-zA-Z0-9_-]+\.(png|jpg|jpeg|webp|heic|heif)$')
                  .hasMatch(name)) ||
          h.file == null ||
          h.file!.filename != name ||
          h.generalPurposeBitFlag & 1 != 0 ||
          h.file!.flags & 1 != 0 ||
          h.file!.compressionMethod !=
              (h.compressionMethod == 8
                  ? CompressionType.deflate
                  : CompressionType.none) ||
          ![0, 8].contains(h.compressionMethod) ||
          (h.externalFileAttributes >> 16) & 0xf000 == 0xa000) {
        throw const ProjectArchiveException('archiveInvalid');
      }
      final max = isJson
          ? ProjectArchiveService.maxJsonBytes
          : ProjectArchiveService.maxImageBytes;
      total += h.uncompressedSize;
      if (h.uncompressedSize < 1 ||
          h.uncompressedSize > max ||
          total > ProjectArchiveService.maxBytes) {
        throw const ProjectArchiveException('archiveTooLarge');
      }
    }
    final contents = <String, Uint8List>{};
    for (final h in headers) {
      final output = _LimitedOutput(h.uncompressedSize);
      // The native archive inflater accumulates output before delivering it.
      // Use the streaming Dart inflater so dishonest sizes cannot bypass limits.
      if (h.compressionMethod == 8) {
        const ZLibDecoderWeb().decodeStream(
            InputMemoryStream(h.file!.getRawContent()), output,
            raw: true);
      } else {
        output.writeBytes(h.file!.getRawContent());
      }
      final content = output.getBytes();
      if (content.length != h.uncompressedSize ||
          getCrc32(content) != h.crc32) {
        throw const ProjectArchiveException('archiveInvalid');
      }
      contents[h.filename] = content;
    }
    if (!contents.containsKey('manifest.json') ||
        !contents.containsKey('project.json')) {
      throw const ProjectArchiveException('archiveInvalid');
    }
    final manifest =
        jsonDecode(utf8.decode(contents.remove('manifest.json')!)) as Map;
    if (manifest['format'] != 'piclayout') {
      throw const ProjectArchiveException('archiveInvalid');
    }
    if (manifest['archiveVersion'] != 1 ||
        manifest['projectFormatVersion'] != AppConfig.projectFormatVersion) {
      throw const ProjectArchiveException('archiveVersionError');
    }
    final json = Map<String, Object?>.from(
        jsonDecode(utf8.decode(contents.remove('project.json')!)) as Map);
    if ((json['formatVersion'] ?? 1) != manifest['projectFormatVersion']) {
      throw const ProjectArchiveException('archiveVersionError');
    }
    final project = CollageProject.fromJson(json);
    if (project.photos.isEmpty ||
        project.photos.length > AppConfig.maxPhotos ||
        project.photos.map((p) => p.id).toSet().length !=
            project.photos.length) {
      throw const ProjectArchiveException('archiveInvalid');
    }
    if (json['customLayout'] != null && project.customLayout == null ||
        json['stickers'] is List &&
            (json['stickers'] as List).length != project.stickers.length) {
      throw const ProjectArchiveException('archiveInvalid');
    }
    final referenced = <String>{};
    for (final photo in project.photos) {
      if (!RegExp(r'^images/[a-zA-Z0-9_-]+\.(png|jpg|jpeg|webp|heic|heif)$')
          .hasMatch(photo.localPath)) {
        throw const ProjectArchiveException('archiveInvalid');
      }
      if (!contents.containsKey(photo.localPath)) {
        throw const ProjectArchiveException('archiveMissingImages');
      }
      referenced.add(photo.localPath);
    }
    if (contents.keys.any((name) => !referenced.contains(name))) {
      throw const ProjectArchiveException('archiveInvalid');
    }
    return _Decoded(project.toJson(), contents);
  } on ProjectArchiveException {
    rethrow;
  } catch (_) {
    throw const ProjectArchiveException('archiveInvalid');
  }
}

/// Enforces actual inflated size, not only the ZIP header's claimed size.
class _LimitedOutput extends OutputMemoryStream {
  _LimitedOutput(this.limit) : super(size: 1024);
  final int limit;
  void _check(int count) {
    if (length + count > limit) {
      throw const ProjectArchiveException('archiveTooLarge');
    }
  }

  @override
  void writeByte(int value) {
    _check(1);
    super.writeByte(value);
  }

  @override
  void writeBytes(List<int> bytes, {int? length}) {
    _check(length ?? bytes.length);
    super.writeBytes(bytes, length: length);
  }

  @override
  void writeStream(InputStream stream) {
    _check(stream.length);
    super.writeStream(stream);
  }

  @override
  void writeBackReference(int distance, int count) {
    _check(count);
    super.writeBackReference(distance, count);
  }
}
