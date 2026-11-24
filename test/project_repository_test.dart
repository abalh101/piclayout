import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:piclayout/features/projects/services/project_repository.dart';
import 'package:piclayout/features/collage_editor/models/text_overlay.dart';

void main() {
  test('Deleting a project waits for queued saves and does not resurrect it',
      () async {
    final root =
        await Directory.systemTemp.createTemp('piclayout_save_delete_');
    addTearDown(() => root.delete(recursive: true));
    final original = File(p.join(root.path, 'original.jpg'));
    await original.writeAsBytes([1, 2, 3, 4]);
    final repository = ProjectRepository(documentsDirectory: root);
    final project =
        await repository.createFromPickedImages([XFile(original.path)]);
    final saves = [
      for (var i = 0; i < 8; i++)
        repository.save(project.copyWith(name: 'Edit $i'))
    ];
    final deleting = repository.delete(project);
    await expectLater(repository.save(project), throwsStateError);
    await Future.wait([...saves, deleting, repository.delete(project)]);
    await expectLater(repository.save(project), throwsStateError);
    expect(await repository.loadProjects(), isEmpty);
    expect(
        await Directory(p.join(root.path, 'piclayout_projects', project.id))
            .exists(),
        isFalse);
    expect(await original.readAsBytes(), [1, 2, 3, 4]);
  });
  test(
      'Imports and reopens all 12 originals; invalid counts fail before writing',
      () async {
    final root = await Directory.systemTemp.createTemp('piclayout_twelve_');
    addTearDown(() => root.delete(recursive: true));
    final repository = ProjectRepository(documentsDirectory: root);
    final original = File(p.join(root.path, 'original.jpg'));
    await original.writeAsBytes([1, 2, 3, 4]);
    await expectLater(
        repository.createFromPickedImages([]), throwsArgumentError);
    await expectLater(
        repository.createFromPickedImages(
            List.generate(13, (_) => XFile(original.path))),
        throwsArgumentError);
    expect(Directory(p.join(root.path, 'piclayout_projects')).existsSync(),
        isFalse);
    final project = await repository
        .createFromPickedImages(List.generate(12, (_) => XFile(original.path)));
    expect(project.photos, hasLength(12));
    expect(project.photos.map((p) => p.id).toSet(), hasLength(12));
    final restored =
        (await ProjectRepository(documentsDirectory: root).loadProjects())
            .single;
    expect(restored.photos.map((p) => p.id), project.photos.map((p) => p.id));
    for (final photo in restored.photos) {
      expect(await File(photo.localPath).readAsBytes(), [1, 2, 3, 4]);
    }
  });
  test('import copies originals and reopening resolves project images',
      () async {
    final root = await Directory.systemTemp.createTemp('piclayout_test_');
    addTearDown(() => root.delete(recursive: true));
    final original = File(p.join(root.path, 'original.jpg'));
    await original.writeAsBytes([1, 2, 3, 4]);
    final repository = ProjectRepository(documentsDirectory: root);

    final project =
        await repository.createFromPickedImages([XFile(original.path)]);
    final imported = File(project.photos.single.localPath);
    expect(imported.path, isNot(original.path));
    expect(await imported.readAsBytes(), [1, 2, 3, 4]);

    final jsonFile = File(
        p.join(root.path, 'piclayout_projects', project.id, 'project.json'));
    final saved =
        jsonDecode(await jsonFile.readAsString()) as Map<String, dynamic>;
    expect((saved['photos'] as List).single['localPath'],
        'images/${p.basename(imported.path)}');

    final reopened = (await repository.loadProjects()).single;
    expect(reopened.photos.single.localPath, imported.path);
    expect(await original.readAsBytes(), [1, 2, 3, 4]);

    (saved['photos'] as List).single['localPath'] =
        '/old/ios/container/images/${p.basename(imported.path)}';
    await jsonFile.writeAsString(jsonEncode(saved));
    final migrated = (await repository.loadProjects()).single;
    expect(migrated.photos.single.localPath, imported.path);

    await repository.save(migrated.copyWith(
      textOverlays: [const TextOverlay(id: 'title', text: 'Sommer', x: 0.3)],
    ));
    final reopenedWithText =
        (await ProjectRepository(documentsDirectory: root).loadProjects())
            .single;
    expect(reopenedWithText.textOverlays.single.text, 'Sommer');
    expect(reopenedWithText.textOverlays.single.x, 0.3);
  });

  test('interrupted and corrupt metadata falls back to the last valid revision',
      () async {
    final root = await Directory.systemTemp.createTemp('piclayout_recovery_');
    addTearDown(() => root.delete(recursive: true));
    final source =
        await File(p.join(root.path, 'original.jpg')).writeAsBytes([1, 2, 3]);
    final repository = ProjectRepository(documentsDirectory: root);
    final initial =
        await repository.createFromPickedImages([XFile(source.path)]);
    final snapshots =
        Directory(p.join(root.path, 'piclayout_projects', initial.id));
    final primary = File(p.join(snapshots.path, 'project.json'));
    await Future.wait([
      repository.save(initial.copyWith(name: 'Draft')),
      repository.save(initial.copyWith(name: 'Latest')),
    ]);
    expect((await repository.loadProjects()).single.name, 'Latest');
    final backup = File('${primary.path}.bak');
    expect(jsonDecode(await backup.readAsString())['name'], 'Draft');

    await File('${primary.path}.pending').writeAsString('{"partial":');
    expect((await repository.loadProjects()).single.name, 'Latest');
    await primary.writeAsString('{broken');
    final recovered = (await repository.loadProjects()).single;
    expect(recovered.name, 'Draft');
    expect(recovered.recovered, isTrue);
    await repository.save(recovered.copyWith(name: 'Repaired'));
    expect((await repository.loadProjects()).single.recovered, isFalse);
    expect(jsonDecode(await backup.readAsString())['name'], 'Draft');
    expect(await source.readAsBytes(), [1, 2, 3]);
  });

  test(
      'a complete pending first save and a project missing an image remain recoverable',
      () async {
    final root = await Directory.systemTemp.createTemp('piclayout_pending_');
    addTearDown(() => root.delete(recursive: true));
    final source =
        await File(p.join(root.path, 'original.jpg')).writeAsBytes([1, 2, 3]);
    final repository = ProjectRepository(documentsDirectory: root);
    final project =
        await repository.createFromPickedImages([XFile(source.path)]);
    final primary = File(
        p.join(root.path, 'piclayout_projects', project.id, 'project.json'));
    await primary.rename('${primary.path}.pending');
    await File(project.photos.single.localPath).delete();
    final recovered = (await repository.loadProjects()).single;
    expect(recovered.recovered, isTrue);
    expect(recovered.photos.single.localPath, project.photos.single.localPath);
    final copy = await repository.duplicate(recovered);
    expect(copy.id, isNot(project.id));
    expect(
        copy.photos.single.localPath, isNot(project.photos.single.localPath));
    expect(await File(copy.photos.single.localPath).exists(), isFalse);
    expect(await source.readAsBytes(), [1, 2, 3]);
  });
}
