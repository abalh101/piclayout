import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:piclayout/features/demo_projects/demo_project_factory.dart';
import 'package:piclayout/features/projects/services/project_repository.dart';
import 'package:piclayout/features/collage_editor/state/collage_editor_controller.dart';
import 'package:piclayout/features/export/collage_exporter.dart';
import 'package:piclayout/features/export/export_settings.dart';
import 'package:image/image.dart' as img;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'Five demos produce independent, reloadable projects with only relative persisted paths',
      () async {
    final directory = await Directory.systemTemp.createTemp('demo_test');
    addTearDown(() => directory.delete(recursive: true));
    final repository = ProjectRepository(documentsDirectory: directory);
    final factory =
        DemoProjectFactory(repository, temporaryDirectory: directory);
    expect(DemoProjectFactory.designs, hasLength(5));
    final ids = <String>{};
    for (final design in DemoProjectFactory.designs) {
      final project = await factory.createCopy(design, name: design.key);
      expect(ids.add(project.id), isTrue);
      expect(project.aspectRatioId, design.ratio);
      expect(project.photos.length, design.images.length);
      final projectDir =
          p.join(directory.path, 'piclayout_projects', project.id);
      final json = jsonDecode(
          await File(p.join(projectDir, 'project.json')).readAsString()) as Map;
      for (final photo in json['photos'] as List) {
        expect(p.isAbsolute(photo['localPath'] as String), isFalse);
        expect(photo['localPath'], startsWith('images/'));
      }
      final restored = (await repository.loadProjects())
          .singleWhere((value) => value.id == project.id);
      expect(restored.textOverlays.single.text, design.key);
      for (final photo in restored.photos) {
        expect(await File(photo.localPath).exists(), isTrue);
        expect(img.decodePng(await File(photo.localPath).readAsBytes())!.width,
            480);
      }
    }
    final design = DemoProjectFactory.designs.first;
    final originalAsset = await rootBundle.load('assets/demo/demo_1.png');
    final originalBytes = originalAsset.buffer
        .asUint8List(originalAsset.offsetInBytes, originalAsset.lengthInBytes)
        .toList();
    final first = await factory.createCopy(design, name: 'first');
    final second = await factory.createCopy(design, name: 'second');
    expect(first.id, isNot(second.id));
    expect(first.photos.first.id, isNot(second.photos.first.id));
    expect(first.photos.first.localPath, isNot(second.photos.first.localPath));
    await File(first.photos.first.localPath).writeAsString('changed copy');
    await repository.rename(first, 'edited');
    expect(
        await File(second.photos.first.localPath).readAsBytes(), originalBytes);
    final sourceAgain = await rootBundle.load('assets/demo/demo_1.png');
    expect(
        sourceAgain.buffer
            .asUint8List(sourceAgain.offsetInBytes, sourceAgain.lengthInBytes),
        originalBytes);
    await repository.delete(first);
    expect(
        (await repository.loadProjects()).any((value) => value.id == second.id),
        isTrue);
    expect(
        directory
            .listSync()
            .whereType<Directory>()
            .where((dir) => p.basename(dir.path).startsWith('piclayout_demo_')),
        isEmpty);
  });
  test('Demo supports normal editing, undo, saving and PNG/JPEG export',
      () async {
    final directory = await Directory.systemTemp.createTemp('demo_edit_test');
    addTearDown(() => directory.delete(recursive: true));
    final repository = ProjectRepository(documentsDirectory: directory);
    final project =
        await DemoProjectFactory(repository, temporaryDirectory: directory)
            .createCopy(DemoProjectFactory.designs[2], name: 'Birthday');
    final controller = CollageEditorController(
        initialProject: project, repository: repository);
    addTearDown(controller.dispose);
    controller.updateCanvas(project.canvas.copyWith(spacing: 20));
    expect(controller.canUndo, isTrue);
    controller.undo();
    expect(controller.project.canvas.spacing, project.canvas.spacing);
    controller.redo();
    await controller.saveNow();
    final restored = (await repository.loadProjects()).single;
    expect(restored.canvas.spacing, 20);
    expect(restored.stickers, hasLength(1));
    for (final format in ExportFormat.values) {
      final output = await CollageExporter(outputDirectory: directory).export(
          restored, ExportSettings(format: format, width: 240, height: 300));
      final decoded = img.decodeImage(await output.readAsBytes())!;
      expect(decoded.width, 240);
      expect(decoded.height, 300);
    }
  });
}
