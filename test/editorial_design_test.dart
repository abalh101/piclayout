import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:piclayout/core/localization/editorial_translations.dart';
import 'package:piclayout/features/editorial/models/editorial_design.dart';
import 'package:piclayout/features/editorial/models/design_presets.dart';
import 'package:piclayout/features/editorial/rendering/editorial_renderer.dart';
import 'package:piclayout/features/collage_editor/models/text_overlay.dart';
import 'package:piclayout/features/collage_editor/models/photo_transform.dart';
import 'package:piclayout/features/collage_editor/models/photo_adjustments.dart';
import 'package:piclayout/features/collage_editor/rendering/layout_geometry.dart';
import 'package:piclayout/features/collage_editor/state/collage_editor_controller.dart';
import 'package:piclayout/features/projects/models/collage_project.dart';
import 'package:piclayout/features/projects/services/project_repository.dart';
import 'package:piclayout/features/templates/models/collage_template.dart';
import 'package:piclayout/features/project_archive/project_archive_service.dart';
import 'support/editorial_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'Legacy projects keep standard geometry; unknown optional layers are isolated',
      () {
    final p = editorialProject();
    final json = p.toJson()..remove('design');
    final old = CollageProject.fromJson(json);
    expect(old.design.active, isFalse);
    expect(LayoutGeometry.resolve(old, const Size(390, 690)).map((c) => c.rect),
        LayoutGeometry.resolve(p, const Size(390, 690)).map((c) => c.rect));
    json['design'] = {
      'version': 1,
      'mode': 'editorial',
      'layers': [
        {'id': 'future', 'type': 'hologram'},
        {'id': 'broken', 'type': 'text', 'text': 5},
        const DesignLayer(id: 'valid', type: DesignLayerType.photo).toJson(),
        {
          'id': 'bad',
          'type': 'photo',
          'x': double.nan,
          'width': double.infinity,
          'z': double.nan
        },
      ]
    };
    final restored = CollageProject.fromJson(json);
    expect(restored.design.layers.map((l) => l.id), contains('valid'));
    expect(
        restored.design.layers.every((l) => l.x.isFinite && l.width.isFinite),
        isTrue);
    expect(EditorialDesign.fromJson({'version': 99}).active, isFalse);
  });
  test(
      'Every preset supports 1–12 photos and grid/masonry bounds do not overlap',
      () {
    for (var count = 1; count <= 12; count++) {
      final p = editorialProject(count: count);
      for (final preset in DesignPreset.all) {
        final d = preset.create(p.photos, (k) => k);
        final cells =
            d.layers.where((l) => l.layoutSlot >= 0 && l.isPhoto).toList();
        expect(cells.length, preset.mode == DesignMode.detail ? 1 : count);
        for (final cell in cells) {
          final r = cell.rect(const Size(1, 1));
          expect(r.left, greaterThanOrEqualTo(-1e-9));
          expect(r.right, lessThanOrEqualTo(1 + 1e-9));
          expect(r.top, greaterThanOrEqualTo(-1e-9));
          expect(r.bottom, lessThanOrEqualTo(1 + 1e-9));
          expect(r.width, greaterThan(0));
          expect(r.height, greaterThan(0));
          for (final other in cells.where((o) => o.id != cell.id)) {
            final overlap = r.intersect(other.rect(const Size(1, 1)));
            expect(overlap.width > 1e-9 && overlap.height > 1e-9, isFalse);
          }
        }
        if (preset.mode == DesignMode.editorial) {
          final captions =
              d.layers.where((l) => l.type == DesignLayerType.caption);
          expect(captions.length, count);
          expect(DesignPreset.caption(d, captions.last), '($count)');
        }
      }
    }
  });
  test('Masonry variants differ and asymmetric heights survive reflow', () {
    final p = editorialProject(count: 9);
    final variants = DesignPreset.all
        .where((p) => p.mode == DesignMode.masonry)
        .take(3)
        .map((preset) => preset.create(p.photos, (k) => k))
        .toList();
    expect(
        variants
            .map((d) => d.layers
                .where((l) => l.isPhoto)
                .map((l) => l.rect(const Size(1, 1)))
                .join())
            .toSet()
            .length,
        3);
    final d = DesignPreset.reflow(
        variants.first.copyWith(margin: .18, gapX: .1, gapY: .12));
    expect(d.layers.where((l) => l.isPhoto).map((l) => l.height).toSet().length,
        greaterThan(1));
  });
  test('Full layer state and custom captions round trip in stable z order', () {
    final p = editorialProject();
    final layer = DesignLayer(
        id: 'full',
        type: DesignLayerType.callout,
        photoId: p.photos.last.id,
        x: .3,
        y: .6,
        width: .2,
        height: .3,
        rotation: -13,
        opacity: .6,
        z: 99,
        locked: true,
        borderWidth: 3,
        borderColor: 0xFF123456,
        shape: CalloutShape.circle,
        crop: const Rect.fromLTWH(.1, .2, .3, .4),
        lineColor: 0xFF445566,
        lineWidth: 2,
        endpoint: const Offset(.2, .8),
        tearStyle: TearStyle.weathered,
        tearEdges: TearEdges.all);
    final d = DesignPreset.all.first
        .create(p.photos, (k) => k)
        .copyWith(numberStyle: NumberStyle.custom);
    final layers = [
      for (final l in d.layers)
        l.type == DesignLayerType.caption
            ? l.copyWith(
                text: l.text.copyWith(
                    text: 'تعليق خاص',
                    fontFamily: 'serif',
                    padding: 3,
                    cornerRadius: 9))
            : l,
      layer
    ];
    final source = p.copyWith(design: d.copyWith(layers: layers));
    final restored =
        CollageProject.fromJson(jsonDecode(jsonEncode(source.toJson())));
    expect(restored.design.toJson(), source.design.toJson());
    expect(restored.design.ordered.last.id, 'full');
    expect(
        DesignPreset.caption(
            restored.design,
            restored.design.layers
                .firstWhere((l) => l.type == DesignLayerType.caption)),
        'تعليق خاص');
  });
  test('All numbering formats and custom text are preserved independently', () {
    const l = DesignLayer(
        id: 'c',
        type: DesignLayerType.caption,
        photoSlot: 2,
        text: TextOverlay(id: 't', text: 'Private caption'));
    const d = EditorialDesign();
    expect([
      for (final style in NumberStyle.values)
        DesignPreset.caption(d.copyWith(numberStyle: style), l)
    ], [
      '(3)',
      '3',
      '03',
      'Private caption',
      ''
    ]);
  });
  test(
      'Templates use placeholders and opt-in text, with no private IDs or paths',
      () {
    final p = editorialProject();
    final d = DesignPreset.all.first
        .create(p.photos, (k) => 'PRIVATE TEXT')
        .copyWith(layers: [
      ...DesignPreset.all.first.create(p.photos, (k) => 'PRIVATE TEXT').layers,
      DesignLayer(
          id: 'private-layer',
          type: DesignLayerType.location,
          photoId: p.photos.last.id,
          text: const TextOverlay(id: 'private-text', text: 'PRIVATE TEXT'))
    ]);
    for (final include in [false, true]) {
      final template = CollageTemplate.fromProject(
          id: 't',
          name: 'Reusable',
          project: p.copyWith(design: d),
          includeTextOverlays: include);
      final encoded = jsonEncode(template.toJson());
      for (final forbidden in [
        'private-',
        '/private',
        'localPath',
        'originalFileName',
        'photoId'
      ]) {
        expect(encoded, isNot(contains(forbidden)));
      }
      expect(encoded.contains('PRIVATE TEXT'), include);
      final restored = CollageTemplate.fromJson(jsonDecode(encoded));
      final target = editorialProject(count: 2);
      final applied = restored.applyTo(target);
      expect(
          applied.design.layers
              .where((l) => l.isPhoto)
              .every((l) => target.photos.any((p) => p.id == l.photoId)),
          isTrue);
      if (!include) {
        expect(
            applied.design.layers
                .where((l) => l.type == DesignLayerType.caption)
                .length,
            6);
      }
    }
  });
  test('Move, resize, rotate, duplicate, lock, order and delete are undoable',
      () {
    final p = editorialProject();
    final repo = EditorialMemoryRepository();
    final c = CollageEditorController(initialProject: p, repository: repo);
    addTearDown(c.dispose);
    c.applyDesign(DesignPreset.all.first.create(p.photos, (k) => k));
    final layer = c.project.design.layers.first;
    c.selectDesignLayer(layer.id);
    void changeAndUndo(void Function() change) {
      final before = jsonEncode(c.project.design.toJson());
      change();
      final after = jsonEncode(c.project.design.toJson());
      expect(after, isNot(before));
      c.undo();
      expect(jsonEncode(c.project.design.toJson()), before);
      c.redo();
      expect(jsonEncode(c.project.design.toJson()), after);
    }

    changeAndUndo(() =>
        c.updateDesignLayer(c.selectedDesignLayer!.copyWith(x: .3, y: .4)));
    changeAndUndo(() => c.updateDesignLayer(
        c.selectedDesignLayer!.copyWith(width: .25, height: .15)));
    changeAndUndo(() =>
        c.updateDesignLayer(c.selectedDesignLayer!.copyWith(rotation: 35)));
    changeAndUndo(c.duplicateDesignLayer);
    final copy = c.project.design.layers.last;
    c.selectDesignLayer(copy.id);
    changeAndUndo(() => c.reorderDesignLayer(forward: false));
    changeAndUndo(() =>
        c.updateDesignLayer(c.selectedDesignLayer!.copyWith(locked: true)));
    final locked = c.selectedDesignLayer!;
    c.updateDesignLayer(locked.copyWith(x: .9));
    c.deleteDesignLayer();
    expect(c.selectedDesignLayer!.toJson(), locked.toJson());
    c.updateDesignLayer(locked.copyWith(locked: false));
    changeAndUndo(c.deleteDesignLayer);
  });
  testWidgets('A gesture is one undo step and autosave includes scene data',
      (tester) async {
    final p = editorialProject();
    final repo = EditorialMemoryRepository();
    final c = CollageEditorController(initialProject: p, repository: repo);
    addTearDown(c.dispose);
    c.applyDesign(DesignPreset.all.first.create(p.photos, (k) => k));
    final layer = c.project.design.layers.first;
    c.beginInteractiveTransform();
    for (var i = 0; i < 10; i++) {
      c.updateDesignLayer(layer.copyWith(x: .2 + i * .01, rotation: i * 2),
          live: true);
    }
    c.endInteractiveTransform();
    final after = c.project.design.toJson();
    await tester.pump(const Duration(seconds: 1));
    expect(repo.saved!.design.toJson(), after);
    c.undo();
    expect(c.project.design.layers.first.toJson(), layer.toJson());
    c.redo();
    expect(c.project.design.toJson(), after);
    await tester.pump(const Duration(seconds: 1));
  });
  test('Adding a detail to a legacy layout preserves its photo geometry', () {
    final p = editorialProject();
    final c = CollageEditorController(
        initialProject: p, repository: EditorialMemoryRepository());
    addTearDown(c.dispose);
    const size = Size(390, 390 * 16 / 9);
    final before = LayoutGeometry.resolve(p, size);
    c.addDesignLayer(DesignLayer(
        id: 'detail',
        type: DesignLayerType.callout,
        photoId: p.photos.first.id));
    final after = LayoutGeometry.resolve(c.project, size);
    for (var i = 0; i < before.length; i++) {
      expect(after[i].rect.left, closeTo(before[i].rect.left, 1e-8));
      expect(after[i].rect.width, closeTo(before[i].rect.width, 1e-8));
    }
  });
  test(
      'Layer source selection follows edits and history; crop mode exits cleanly',
      () {
    final p = editorialProject(count: 2);
    final c = CollageEditorController(
        initialProject: p, repository: EditorialMemoryRepository());
    addTearDown(c.dispose);
    c.applyDesign(DesignPreset.all.first.create(p.photos, (k) => k));
    final layer = c.project.design.layers.firstWhere((l) => l.isPhoto);
    c.selectDesignLayer(layer.id);
    c.setDesignCropEditing(true);
    expect(c.editingDesignCrop, isTrue);
    c.updateDesignLayer(layer.copyWith(photoId: p.photos.last.id));
    expect(c.selectedPhoto!.id, p.photos.last.id);
    c.undo();
    expect(c.selectedPhoto!.id, p.photos.first.id);
    c.redo();
    expect(c.selectedPhoto!.id, p.photos.last.id);
    c.addText('Caption');
    expect(c.selectedDesignLayerId, isNull);
    expect(c.editingDesignCrop, isFalse);
    c.selectDesignLayer(layer.id);
    c.setDesignCropEditing(true);
    c.setLayoutTemplate(p.layoutTemplateId);
    expect(c.selectedDesignLayerId, isNull);
    expect(c.editingDesignCrop, isFalse);
    c.selectDesignLayer(layer.id);
    expect(c.selectedDesignLayerId, isNull);
  });
  test('Fill remains clamped for editorial cells with rotation and flip', () {
    final p = editorialProject();
    final c = CollageEditorController(
        initialProject: p, repository: EditorialMemoryRepository());
    addTearDown(c.dispose);
    c.applyDesign(DesignPreset.all[1].create(p.photos, (k) => k));
    c.setTransform(
        p.photos.first.id,
        const PhotoTransform(
            scale: .1,
            offsetX: 100,
            offsetY: -100,
            rotationQuarterTurns: 1,
            flipX: true));
    final t = c.project.photos.first.transform;
    expect(t.scale, 1);
    expect(t.offsetX.abs(), lessThan(2));
    expect(t.offsetY.abs(), lessThan(2));
    c.setAdjustments(p.photos.first.id,
        const PhotoAdjustments(preset: PhotoFilterPreset.sepia));
    expect(c.project.photos.first.adjustments.preset, PhotoFilterPreset.sepia);
    c.setSelectedFitMode(PhotoFitMode.fit);
    expect(c.selectedPhoto!.transform.fitMode, PhotoFitMode.fit);
  });
  test('Tears are deterministic across sizes and four styles are distinct', () {
    final signatures = <String>{};
    for (final style in TearStyle.values) {
      final l = DesignLayer(
          id: 'tear',
          type: DesignLayerType.torn,
          tearStyle: style,
          tearEdges: TearEdges.all,
          seed: 45,
          tearIntensity: 1);
      final a =
          EditorialRenderer.tearPath(const Rect.fromLTWH(0, 0, 100, 200), l);
      final b =
          EditorialRenderer.tearPath(const Rect.fromLTWH(0, 0, 1000, 2000), l);
      final values = <bool>[];
      for (var x = 1; x < 100; x += 3) {
        for (var y = 0; y < 12; y++) {
          final hit = a.contains(Offset(x.toDouble(), y.toDouble()));
          values.add(hit);
          expect(b.contains(Offset(x * 10.0, y * 10.0)), hit);
        }
      }
      signatures.add(values.join());
      expect(a.contains(const Offset(50, 100)), isTrue);
    }
    expect(signatures.length, 4);
  });
  test('All editorial strings exist in all six languages', () {
    for (final entry in editorialTranslations.entries) {
      expect(entry.value.length, 6, reason: entry.key);
      expect(entry.value.every((s) => s.isNotEmpty), isTrue);
    }
  });
  test(
      'Repository save, duplicate and archive import remap sources without changing originals',
      () async {
    final dir = await Directory.systemTemp.createTemp('editorial_persistence_');
    addTearDown(() => dir.delete(recursive: true));
    final images = Directory('${dir.path}/piclayout_projects/editorial/images');
    await images.create(recursive: true);
    final bytes = img.encodePng(img.Image(width: 32, height: 32));
    final file = File('${images.path}/source.png');
    await file.writeAsBytes(bytes);
    final p = editorialProject(count: 1, path: file.path);
    final source =
        p.copyWith(design: DesignPreset.all[5].create(p.photos, (k) => k));
    final repo = ProjectRepository(documentsDirectory: dir);
    await repo.save(source);
    final loaded = (await repo.loadProjects()).single;
    expect(loaded.design.toJson(), source.design.toJson());
    final stored = jsonDecode(
        await File('${images.parent.path}/project.json').readAsString()) as Map;
    expect(stored['photos'][0]['localPath'], 'images/source.png');
    final copy = await repo.duplicate(loaded);
    expect(
        copy.design.layers
            .where((l) => l.isPhoto)
            .every((l) => l.photoId == copy.photos.single.id),
        isTrue);
    final archive =
        ProjectArchiveService(documentsDirectory: dir, temporaryDirectory: dir);
    final packed = await archive.exportProject(loaded);
    final imported = await archive.importProject(packed);
    expect(
        imported.design.layers
            .where((l) => l.isPhoto)
            .every((l) => l.photoId == imported.photos.single.id),
        isTrue);
    expect(await file.readAsBytes(), bytes);
  });
}
