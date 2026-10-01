import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:piclayout/features/collage_editor/layouts/layout_library.dart';
import 'package:piclayout/features/collage_editor/models/canvas_settings.dart';
import 'package:piclayout/features/collage_editor/models/photo_asset.dart';
import 'package:piclayout/features/collage_editor/models/text_overlay.dart';
import 'package:piclayout/features/projects/models/collage_project.dart';
import 'package:piclayout/features/templates/models/collage_template.dart';
import 'package:piclayout/features/templates/services/design_library_repository.dart';
import 'package:piclayout/features/templates/state/design_library_providers.dart';

CollageProject _project(int count) {
  final now = DateTime.utc(2026);
  return CollageProject(
    id: 'project',
    name: 'Private trip',
    createdAt: now,
    updatedAt: now,
    formatVersion: 1,
    aspectRatioId: '1_1',
    layoutTemplateId: LayoutLibrary.defaultFor(count).id,
    canvas: const CanvasSettings(
      spacing: 10,
      outerMargin: 12,
      cornerRadius: 8,
      backgroundColor: 0xFF123456,
      staggerAmount: 0.12,
    ),
    photos: [
      for (var i = 0; i < count; i++)
        PhotoAsset(
          id: '$i',
          originalFileName: 'private_$i.jpg',
          localPath: '/private/holiday_$i.jpg',
        ),
    ],
    textOverlays: const [TextOverlay(id: 'text', text: 'Hello')],
  );
}

void main() {
  test('favorites persist, include photo count and can be removed', () async {
    final root = await Directory.systemTemp.createTemp('piclayout_design_');
    addTearDown(() => root.delete(recursive: true));
    final repository = DesignLibraryRepository(documentsDirectory: root);
    final notifier = DesignLibraryNotifier(repository);
    final layout = LayoutLibrary.templatesFor(6).first;

    await notifier.toggleFavorite(layout);
    final saved =
        await DesignLibraryRepository(documentsDirectory: root).load();
    expect(saved.isFavorite(layout.id), isTrue);
    expect(saved.favoriteLayouts.single.photoCount, 6);
    expect(saved.toJson().toString(), isNot(contains('private')));

    await notifier.toggleFavorite(layout);
    final removed = await repository.load();
    expect(removed.favoriteLayouts, isEmpty);
    notifier.dispose();
  });

  test('custom template persists without photos or paths and can be deleted',
      () async {
    final root = await Directory.systemTemp.createTemp('piclayout_design_');
    addTearDown(() => root.delete(recursive: true));
    final repository = DesignLibraryRepository(documentsDirectory: root);
    final notifier = DesignLibraryNotifier(repository);
    final project = _project(6);

    final template = await notifier.saveTemplate(
      name: 'Sommer',
      project: project,
      includeTextOverlays: false,
    );
    final raw = await File(p.join(root.path, 'piclayout_design_library.json'))
        .readAsString();
    expect(raw, isNot(contains('/private/')));
    expect(raw, isNot(contains('holiday_')));
    expect(raw, isNot(contains('originalFileName')));
    expect(raw, isNot(contains('photos')));
    final loaded =
        await DesignLibraryRepository(documentsDirectory: root).load();
    expect(loaded.templates.single.id, template.id);
    expect(loaded.templates.single.name, 'Sommer');
    expect(loaded.templates.single.canvas.spacing, 10);
    expect(loaded.templates.single.textOverlays, isEmpty);

    await notifier.deleteTemplate(template.id);
    expect((await repository.load()).templates, isEmpty);
    notifier.dispose();
  });

  test('template apply keeps photo order and uses compatible layout', () {
    final source = _project(6);
    final template = CollageTemplate.fromProject(
      id: 'template',
      name: 'Six photos',
      project: source,
      includeTextOverlays: true,
    );
    final target = _project(4).copyWith(
      canvas: const CanvasSettings(),
      textOverlays: const [TextOverlay(id: 'old', text: 'Old')],
    );
    final applied = template.applyTo(target);
    expect(applied.photos.map((photo) => photo.id).toList(),
        target.photos.map((photo) => photo.id).toList());
    expect(applied.photos.map((photo) => photo.localPath).toList(),
        target.photos.map((photo) => photo.localPath).toList());
    expect(applied.layoutTemplateId, LayoutLibrary.defaultFor(4).id);
    expect(applied.canvas.spacing, 10);
    expect(applied.textOverlays.single.text, 'Hello');
    expect(applied.textOverlays.single.id, isNot('text'));
    final encoded = jsonEncode(template.toJson());
    expect(encoded, isNot(contains('/private/')));
    expect(encoded, isNot(contains('holiday_')));

    final withoutText = CollageTemplate.fromProject(
      id: 'without',
      name: 'No text',
      project: source,
      includeTextOverlays: false,
    ).applyTo(target);
    expect(withoutText.textOverlays.single.text, 'Old');
  });

  test('legacy project JSON without template fields still loads', () {
    final json = _project(2).toJson()..remove('textOverlays');
    final restored = CollageProject.fromJson(json);
    expect(restored.photos, hasLength(2));
    expect(restored.textOverlays, isEmpty);
  });
}
