import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:piclayout/core/localization/translations.dart';
import 'package:piclayout/features/collage_editor/models/canvas_settings.dart';
import 'package:piclayout/features/collage_editor/models/canvas_style.dart';
import 'package:piclayout/features/collage_editor/models/photo_adjustments.dart';
import 'package:piclayout/features/collage_editor/models/photo_transform.dart';
import 'package:piclayout/features/collage_editor/models/text_overlay.dart';
import 'package:piclayout/features/project_archive/project_archive_service.dart';
import 'package:piclayout/features/project_archive/project_archive_controller.dart';
import 'package:piclayout/features/projects/models/collage_project.dart';
import 'package:piclayout/features/projects/services/project_repository.dart';
import 'package:piclayout/features/stickers/sticker_overlay.dart';
import 'support/custom_layout_fixtures.dart';

class _Platform implements ProjectArchivePlatform {
  XFile? picked;
  int shares = 0;
  bool fail = false;
  Completer<void>? pending;
  File? shared;
  @override
  Future<XFile?> pickProject() async => picked;
  @override
  Future<void> shareProject(File file, Rect origin) async {
    shares++;
    shared = file;
    expect(await file.exists(), isTrue);
    expect(file.path, endsWith('.piclayout'));
    if (fail) throw StateError('share unavailable');
    await pending?.future;
  }
}

Matcher failure(String key) =>
    throwsA(isA<ProjectArchiveException>().having((e) => e.key, 'key', key));
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late Directory docs;
  late ProjectArchiveService service;
  late ProjectRepository repository;
  late CollageProject project;
  late File original;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('piclayout_archive_test_');
    docs = Directory('${root.path}/docs');
    repository = ProjectRepository(documentsDirectory: docs);
    final image = img.Image(
        width: 12, height: 10, textData: {'Device': 'private-device-id'});
    img.fill(image, color: img.ColorRgb8(180, 90, 45));
    original = await File('${root.path}/private_original.png')
        .writeAsBytes(img.encodePng(image));
    final created = await repository
        .createFromPickedImages([XFile(original.path), XFile(original.path)]);
    project = created.copyWith(
        name: 'Travel / Berlin',
        customLayout: gridLayout(count: 2),
        canvas: const CanvasSettings(
            spacing: 8,
            style: CanvasStyle(frameEnabled: true, shadowEnabled: true)),
        textOverlays: const [
          TextOverlay(id: 'text', text: 'مرحبا', rotation: 30)
        ],
        stickers: [
          StickerCatalog.items.first.create('heart')
        ],
        photos: [
          for (final p in created.photos)
            p.copyWith(
                adjustments:
                    const PhotoAdjustments(preset: PhotoFilterPreset.warm),
                transform:
                    const PhotoTransform(scale: 1.4, offsetX: .2, flipX: true))
        ]);
    await repository.save(project);
    service = ProjectArchiveService(
        documentsDirectory: docs,
        temporaryDirectory: Directory('${root.path}/tmp'),
        createdWithAppVersion: '0.1.0+1');
  });
  tearDown(() async => root.delete(recursive: true));

  Future<Map<String, List<int>>> entries(File file) async {
    final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
    return {for (final f in archive) f.name: f.content};
  }

  Future<File> modified(Map<String, List<int>> files) async {
    final archive = Archive();
    for (final item in files.entries) {
      archive.add(ArchiveFile.bytes(item.key, item.value));
    }
    return File('${root.path}/modified.piclayout')
        .writeAsBytes(ZipEncoder().encode(archive));
  }

  Map<String, dynamic> jsonFile(Map<String, List<int>> files, String name) =>
      jsonDecode(utf8.decode(files[name]!)) as Map<String, dynamic>;
  void putJson(
      Map<String, List<int>> files, String name, Map<String, dynamic> json) {
    files[name] = utf8.encode(jsonEncode(json));
  }

  test(
      'Portable archive holds JSON and only referenced images, without device paths or original filenames',
      () async {
    final before = await original.readAsBytes();
    final file = await service.exportProject(project);
    expect(file.path, endsWith('piclayout_project_Travel_Berlin.piclayout'));
    final files = await entries(file);
    expect(files.keys.toSet(),
        {'manifest.json', 'project.json', 'images/0.png', 'images/1.png'});
    final manifest = jsonFile(files, 'manifest.json');
    expect(manifest, {
      'format': 'piclayout',
      'archiveVersion': 1,
      'projectFormatVersion': 1,
      'createdWithAppVersion': '0.1.0+1'
    });
    final json = utf8.decode(files['project.json']!);
    expect(json, isNot(contains(root.path)));
    expect(json, isNot(contains('private_original')));
    expect(json, contains('images/0.png'));
    for (final name in ['images/0.png', 'images/1.png']) {
      final decoded = img.decodePng(Uint8List.fromList(files[name]!))!;
      expect([decoded.width, decoded.height], [12, 10]);
      expect(decoded.getPixel(0, 0).r, 180);
      expect(decoded.textData, anyOf(isNull, isEmpty));
    }
    expect(await original.readAsBytes(), before);
  });
  test(
      'Import creates independent project and images while preserving all editor data',
      () async {
    final file = await service.exportProject(project);
    final imported = await service.importProject(file);
    final again = await service.importProject(file);
    expect({project.id, imported.id, again.id}, hasLength(3));
    expect(imported.name, project.name);
    expect(imported.customLayout!.toJson(), project.customLayout!.toJson());
    expect(imported.canvas.toJson(), project.canvas.toJson());
    expect(imported.textOverlays.map((s) => s.toJson()),
        project.textOverlays.map((s) => s.toJson()));
    expect(imported.stickers.map((s) => s.toJson()),
        project.stickers.map((s) => s.toJson()));
    for (var i = 0; i < imported.photos.length; i++) {
      final photo = imported.photos[i];
      expect(photo.id, isNot(project.photos[i].id));
      expect(photo.localPath, contains('/${imported.id}/images/'));
      expect(await File(photo.localPath).exists(), isTrue);
      expect(photo.transform.toJson(), project.photos[i].transform.toJson());
      expect(
          photo.adjustments.toJson(), project.photos[i].adjustments.toJson());
    }
    expect(await repository.loadProjects(), hasLength(3));
    final saved = await File(
            '${docs.path}/piclayout_projects/${imported.id}/project.json')
        .readAsString();
    expect(saved, isNot(contains(root.path)));
  });
  test('Legacy optional fields load and newer versions are rejected', () async {
    final files = await entries(await service.exportProject(project));
    final json = jsonFile(files, 'project.json')
      ..remove('stickers')
      ..remove('textOverlays')
      ..remove('customLayout');
    putJson(files, 'project.json', json);
    final loaded = await service.importProject(await modified(files));
    expect(loaded.stickers, isEmpty);
    expect(loaded.textOverlays, isEmpty);
    for (final key in ['archiveVersion', 'projectFormatVersion']) {
      final manifest = jsonFile(files, 'manifest.json');
      putJson(files, 'manifest.json', {...manifest, key: 999});
      await expectLater(service.importProject(await modified(files)),
          failure('archiveVersionError'));
      putJson(files, 'manifest.json', manifest);
    }
  });
  test(
      'Wrong format, damaged ZIP, missing images and image corruption do not create partial projects',
      () async {
    final bad =
        await File('${root.path}/bad.piclayout').writeAsString('not zip');
    await expectLater(service.importProject(bad), failure('archiveInvalid'));
    final files = await entries(await service.exportProject(project));
    final missing = {...files}..remove('images/1.png');
    await expectLater(service.importProject(await modified(missing)),
        failure('archiveMissingImages'));
    final wrong = {...files};
    putJson(wrong, 'manifest.json',
        {...jsonFile(files, 'manifest.json'), 'format': 'other'});
    await expectLater(service.importProject(await modified(wrong)),
        failure('archiveInvalid'));
    await expectLater(
        service.importProject(await modified({
          ...files,
          'images/1.png': [1, 2, 3]
        })),
        failure('archiveInvalid'));
    expect(await repository.loadProjects(), hasLength(1));
    final directories =
        await Directory('${docs.path}/piclayout_projects').list().toList();
    expect(directories, hasLength(1));
  });
  test(
      'Traversal, absolute references, unused entries, symlinks and CRC corruption are rejected',
      () async {
    final file = await service.exportProject(project);
    final files = await entries(file);
    for (final name in [
      '../escape.png',
      '/absolute.png',
      r'images\escape.png',
      'unused.txt'
    ]) {
      await expectLater(
          service.importProject(await modified({
            ...files,
            name: [1]
          })),
          failure('archiveInvalid'));
    }
    final json = jsonFile(files, 'project.json');
    (json['photos'] as List).first['localPath'] = original.path;
    final absolute = {...files};
    putJson(absolute, 'project.json', json);
    await expectLater(service.importProject(await modified(absolute)),
        failure('archiveInvalid'));
    final linked = Archive();
    for (final entry in files.entries) {
      final item = ArchiveFile.bytes(entry.key, entry.value);
      if (entry.key == 'images/0.png') item.mode = 0xa1ff;
      linked.add(item);
    }
    final linkFile = await File('${root.path}/link.piclayout')
        .writeAsBytes(ZipEncoder().encode(linked));
    await expectLater(
        service.importProject(linkFile), failure('archiveInvalid'));
    final data = await file.readAsBytes();
    // First entry is stored PNG. Change payload without changing the ZIP CRC.
    final signature = data.indexOf(137);
    expect(signature, greaterThan(0));
    data[signature + 10] ^= 1;
    await File('${root.path}/crc.piclayout').writeAsBytes(data);
    await expectLater(service.importProject(File('${root.path}/crc.piclayout')),
        failure('archiveInvalid'));
  });
  test(
      'Exporter refuses photos outside app project copies and reports storage failures',
      () async {
    final external = project.copyWith(
        photos: [project.photos.first.copyWith(localPath: original.path)]);
    await expectLater(
        service.exportProject(external), failure('archiveMissingImages'));
    final blocked = await File('${root.path}/blocked').writeAsString('file');
    final failing = ProjectArchiveService(
        documentsDirectory: docs, temporaryDirectory: Directory(blocked.path));
    await expectLater(
        failing.exportProject(project), failure('archiveStorageError'));
  });
  test(
      'Picker cancellation, wrong extension, sharing lock, failures and temp cleanup',
      () async {
    final platform = _Platform();
    final controller = ProjectArchiveController(
        platform: platform, service: () async => service);
    addTearDown(controller.dispose);
    expect(await controller.importProject(), isNull);
    expect(controller.busy, isFalse);
    platform.picked = XFile(original.path);
    await expectLater(controller.importProject(), failure('archiveWrongFile'));
    platform.pending = Completer<void>();
    final pending =
        controller.exportProject(project, const Rect.fromLTWH(0, 0, 10, 10));
    while (platform.shared == null) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(controller.busy, isTrue);
    await controller.exportProject(project, Rect.zero);
    expect(platform.shares, 1);
    platform.pending!.complete();
    await pending;
    expect(controller.busy, isFalse);
    expect(await platform.shared!.exists(), isFalse);
    platform.fail = true;
    await expectLater(controller.exportProject(project, Rect.zero),
        failure('archiveShareError'));
    expect(controller.busy, isFalse);
    expect(await platform.shared!.exists(), isFalse);
    platform.picked = XFile((await service.exportProject(project)).path);
    expect(await controller.importProject(), isNotNull);
  });
  test('Forged expanded sizes are bounded and disk-full errors are readable',
      () async {
    final file =
        await modified(await entries(await service.exportProject(project)));
    final bytes = await file.readAsBytes();
    var offset = -1;
    for (var i = 0; i < bytes.length - 4; i++) {
      if (bytes[i] == 0x50 &&
          bytes[i + 1] == 0x4b &&
          bytes[i + 2] == 1 &&
          bytes[i + 3] == 2) {
        offset = i;
        break;
      }
    }
    expect(offset, greaterThan(0));
    // Lie about the actual inflated size; output must stop at the declared limit.
    ByteData.sublistView(bytes).setUint32(offset + 24, 1, Endian.little);
    await file.writeAsBytes(bytes);
    await expectLater(service.importProject(file), failure('archiveTooLarge'));
    expect(
        ProjectArchiveException.storage(
                const FileSystemException('full', '', OSError('full', 28)))
            .key,
        'archiveNoSpace');
    expect(await repository.loadProjects(), hasLength(1));
  });
  test('Archive UI and failure messages cover all six languages', () {
    final keys = translations.keys.where((key) => key.startsWith('archive'));
    expect(keys, hasLength(14));
    for (final key in keys) {
      expect(translations[key], hasLength(6));
      expect(translations[key]!.every((s) => s.isNotEmpty), isTrue);
    }
  });
}
