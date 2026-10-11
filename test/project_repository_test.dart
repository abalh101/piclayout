import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:piclayout/features/projects/services/project_repository.dart';
import 'package:piclayout/features/collage_editor/models/text_overlay.dart';

void main() {
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
}
