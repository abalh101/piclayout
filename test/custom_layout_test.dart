import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:piclayout/features/collage_editor/layouts/layout_library.dart';
import 'package:piclayout/features/collage_editor/models/canvas_settings.dart';
import 'package:piclayout/features/collage_editor/models/canvas_style.dart';
import 'package:piclayout/features/collage_editor/models/photo_adjustments.dart';
import 'package:piclayout/features/collage_editor/models/photo_transform.dart';
import 'package:piclayout/features/collage_editor/models/text_overlay.dart';
import 'package:piclayout/features/collage_editor/rendering/layout_geometry.dart';
import 'package:piclayout/features/collage_editor/state/collage_editor_controller.dart';
import 'package:piclayout/features/custom_layouts/models/custom_layout.dart';
import 'package:piclayout/features/custom_layouts/services/custom_layout_repository.dart';
import 'package:piclayout/features/custom_layouts/services/layout_builder_seed.dart';
import 'package:piclayout/features/custom_layouts/state/custom_layout_providers.dart';
import 'package:piclayout/features/export/collage_exporter.dart';
import 'package:piclayout/features/export/export_settings.dart';
import 'package:piclayout/features/projects/models/collage_project.dart';
import 'package:piclayout/features/projects/services/project_repository.dart';
import 'package:piclayout/features/templates/models/collage_template.dart';
import 'support/custom_layout_fixtures.dart';

void assertPartition(CustomLayout layout) {
  var area = 0.0;
  for (final a in layout.cells) {
    expect(a.x, greaterThanOrEqualTo(0));
    expect(a.y, greaterThanOrEqualTo(0));
    expect(a.right, lessThanOrEqualTo(1 + 1e-8));
    expect(a.bottom, lessThanOrEqualTo(1 + 1e-8));
    expect(a.width, greaterThanOrEqualTo(.12 - 1e-8));
    expect(a.height, greaterThanOrEqualTo(.12 - 1e-8));
    area += a.width * a.height;
    for (final b in layout.cells.where((b) => b.photoIndex > a.photoIndex)) {
      final overlapX = min(a.right, b.right) - max(a.x, b.x);
      final overlapY = min(a.bottom, b.bottom) - max(a.y, b.y);
      expect(overlapX > 1e-8 && overlapY > 1e-8, isFalse);
    }
  }
  expect(area, closeTo(1, 1e-8));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'Custom layout round trip is immutable and contains geometry but no photos or paths',
      () {
    final layout = gridLayout();
    final serialized = jsonEncode(layout.toJson());
    final restored = CustomLayout.fromJson(jsonDecode(serialized));
    expect(restored.toJson(), layout.toJson());
    expect(restored.photoCount, 6);
    for (final forbidden in [
      'localPath',
      'originalFileName',
      'photos',
      '/private',
      'photo-0',
      'adjustments',
      'transform'
    ]) {
      expect(serialized, isNot(contains(forbidden)));
    }
    expect(() => restored.cells.clear(), throwsUnsupportedError);
    final renamed =
        layout.savedAs('copy', '  New layout  ', now: DateTime.utc(2027));
    expect(renamed.name, 'New layout');
    expect(renamed.createdAt, DateTime.utc(2027));
    expect(renamed.updatedAt, renamed.createdAt);
  });
  test(
      'Rejects outside, overlap, holes, small cells, duplicate indexes and nonfinite JSON',
      () {
    final source = gridLayout(count: 2).toJson();
    for (final update in <Map<String, Object?>>[
      {'x': -.1},
      {'width': .6},
      {'width': .4},
      {'width': .1},
      {'height': double.infinity},
      {'y': double.nan},
      {'photoIndex': 1},
    ]) {
      final altered = {
        ...source,
        'cells': [
          {
            ...(source['cells'] as List).first as Map<String, Object?>,
            ...update
          },
          (source['cells'] as List).last,
        ]
      };
      expect(CustomLayout.tryParse(altered), isNull, reason: update.toString());
    }
    expect(CustomLayout.tryParse({'id': 'broken'}), isNull);
    expect(CustomLayout.tryParse({...source, 'photoCount': 3}), isNull);
  });
  test(
      '2x3 and 3x3 seams clamp to 12%, preserve outside edges, cover every sample',
      () {
    for (final count in [6, 9]) {
      var layout = gridLayout(count: count);
      for (final axis in DividerAxis.values) {
        var divider = layout.dividers.firstWhere((d) => d.axis == axis);
        layout = layout.moveDivider(divider, -99);
        assertPartition(layout);
        divider = layout.dividers.firstWhere((d) => d.axis == axis);
        layout = layout.moveDivider(divider, 99);
        assertPartition(layout);
      }
      for (var y = 0; y < 100; y++) {
        for (var x = 0; x < 100; x++) {
          final px = (x + .5) / 100, py = (y + .5) / 100;
          expect(
              layout.cells
                  .where((c) =>
                      px >= c.x && px < c.right && py >= c.y && py < c.bottom)
                  .length,
              1);
        }
      }
    }
  });
  test(
      'All editable built-ins preserve valid partitions through randomized seam drags',
      () {
    final random = Random(41);
    for (var count = 1; count <= 12; count++) {
      for (final template in LayoutLibrary.templatesFor(count)) {
        var layout = LayoutBuilderSeed.fromTemplate(template, .12);
        if (layout == null) continue;
        for (var step = 0; step < 60; step++) {
          final dividers = layout!.dividers;
          if (dividers.isEmpty) break;
          final seam = dividers[random.nextInt(dividers.length)];
          layout = layout.moveDivider(seam, random.nextDouble() * 1.4 - .2);
          assertPartition(layout);
        }
      }
    }
  });
  test(
      'Staggered short seams affect their column only; invalid seeds get explicit fallback',
      () {
    final template =
        LayoutLibrary.templatesFor(6).firstWhere((t) => t.supportsStagger);
    var layout = LayoutBuilderSeed.fromTemplate(template, .1)!;
    final seam = layout.dividers
        .firstWhere((d) => d.axis == DividerAxis.horizontal && d.end <= .5);
    final right =
        layout.cells.where((c) => c.x == .5).map((c) => c.toJson()).toList();
    layout = layout.moveDivider(seam, .2);
    expect(layout.cells.where((c) => c.x == .5).map((c) => c.toJson()).toList(),
        right);
    assertPartition(layout);
    expect(LayoutBuilderSeed.fromProject(layoutProject(count: 5)).adjusted,
        isTrue);
    expect(LayoutBuilderSeed.fromProject(layoutProject(count: 6)).adjusted,
        isFalse);
    for (var count = 1; count <= 12; count++) {
      assertPartition(
          LayoutBuilderSeed.fromProject(layoutProject(count: count)).layout);
    }
  });
  test(
      'Applying and editing preserves photos, order, crops, filters, text and style; undo/redo saves',
      () async {
    final base = layoutProject();
    final project = base.copyWith(
        photos: [
          for (final p in base.photos)
            p.copyWith(
                transform:
                    const PhotoTransform(scale: 1.4, offsetX: .1, flipX: true),
                adjustments:
                    const PhotoAdjustments(preset: PhotoFilterPreset.warm))
        ],
        textOverlays: const [
          TextOverlay(id: 'text', text: 'Hello')
        ],
        canvas: const CanvasSettings(
            spacing: 10, style: CanvasStyle(frameEnabled: true)));
    final repository = LayoutMemoryProjects();
    final controller = CollageEditorController(
        initialProject: project, repository: repository);
    addTearDown(controller.dispose);
    final first = gridLayout();
    final moved = first.moveDivider(first.dividers.first, .65);
    expect(controller.applyCustomLayout(first), isTrue);
    expect(controller.applyCustomLayout(moved), isTrue);
    expect(controller.project.photos.map((p) => p.toJson()).toList(),
        project.photos.map((p) => p.toJson()).toList());
    expect(controller.project.canvas.toJson(), project.canvas.toJson());
    expect(controller.project.textOverlays, project.textOverlays);
    controller.undo();
    expect(controller.project.customLayout!.toJson(), first.toJson());
    controller.undo();
    expect(controller.project.customLayout, isNull);
    controller.redo();
    controller.redo();
    await controller.saveNow();
    expect(repository.saved!.customLayout!.toJson(), moved.toJson());
    expect(controller.applyCustomLayout(gridLayout(count: 2)), isFalse);
    expect(controller.project.customLayout!.toJson(), moved.toJson());
    controller.setLayoutTemplate(project.layoutTemplateId);
    expect(controller.project.customLayout, isNull);
    controller.undo();
    expect(controller.project.customLayout, isNotNull);
    controller.removeSelected();
    expect(controller.project.customLayout, isNull);
    controller.undo();
    expect(controller.project.customLayout, isNotNull);
    controller.varyLayout();
    expect(controller.project.customLayout, isNull);
  });
  test(
      'Legacy projects and invalid/mismatched custom data load with built-in fallback',
      () {
    final project = layoutProject();
    expect(CollageProject.fromJson(project.toJson()).customLayout, isNull);
    expect(
        CollageProject.fromJson({
          ...project.toJson(),
          'customLayout': {'bad': true}
        }).customLayout,
        isNull);
    expect(
        CollageProject.fromJson(
                project.copyWith(customLayout: gridLayout(count: 2)).toJson())
            .customLayout,
        isNull);
    final custom = project.copyWith(customLayout: gridLayout());
    expect(CollageProject.fromJson(custom.toJson()).customLayout!.toJson(),
        custom.customLayout!.toJson());
    final template = CollageTemplate.fromProject(
        id: 't', name: 'Test', project: custom, includeTextOverlays: false);
    final encoded = jsonEncode(template.toJson());
    expect(encoded, isNot(contains('/private')));
    expect(encoded, isNot(contains('photos')));
    final loaded = CollageTemplate.fromJson(jsonDecode(encoded));
    expect(loaded.applyTo(project).customLayout!.toJson(),
        custom.customLayout!.toJson());
    expect(loaded.applyTo(layoutProject(count: 2)).customLayout, isNull);
    final legacyTemplate = CollageTemplate.fromProject(
        id: 'old', name: 'Old', project: project, includeTextOverlays: false);
    expect(legacyTemplate.applyTo(custom).customLayout, isNull);
  });
  test(
      'Local repository restarts, serializes writes and ignores individual malformed entries',
      () async {
    final dir = await Directory.systemTemp.createTemp('custom_layouts_');
    addTearDown(() => dir.delete(recursive: true));
    final repository = CustomLayoutRepository(directory: dir);
    expect(await repository.load(), isEmpty);
    final layout = gridLayout();
    await repository.save([layout]);
    expect(
        (await CustomLayoutRepository(directory: dir).load()).single.toJson(),
        layout.toJson());
    final second = layout.savedAs('second', 'Second');
    await Future.wait([
      repository.save([layout]),
      repository.save([layout, second])
    ]);
    expect(await repository.load(), hasLength(2));
    final file = File('${dir.path}/piclayout_custom_layouts.json');
    await file.writeAsString(jsonEncode({
      'layouts': [
        {'broken': true},
        layout.toJson()
      ]
    }));
    expect(await repository.load(), hasLength(1));
    await file.writeAsString('broken');
    await expectLater(repository.load(), throwsFormatException);
  });
  test(
      'Library controller keeps concurrent saves and does not publish failed saves',
      () async {
    final repository = LayoutMemoryLibrary();
    final container = ProviderContainer(overrides: [
      customLayoutRepositoryProvider.overrideWithValue(repository)
    ]);
    addTearDown(container.dispose);
    await container.read(customLayoutsProvider.future);
    final controller = container.read(customLayoutsProvider.notifier);
    await Future.wait([
      controller.saveLayout(gridLayout(id: 'a')),
      controller.saveLayout(gridLayout(id: 'b'))
    ]);
    expect(repository.layouts.map((l) => l.id), ['a', 'b']);
    repository.fail = true;
    await expectLater(
        controller.saveLayout(gridLayout(id: 'c')), throwsFormatException);
    expect(container.read(customLayoutsProvider).value, hasLength(2));
    repository.fail = false;
    await controller.saveLayout(gridLayout(id: 'd'));
    expect(repository.layouts.map((l) => l.id), ['a', 'b', 'd']);
  });
  test(
      'Geometry uses normalized coordinates at all sizes and never inverts narrow styled cells',
      () {
    final layout = gridLayout(count: 2);
    final moved = layout.moveDivider(layout.dividers.single, .12);
    final base = layoutProject(count: 2).copyWith(
        customLayout: moved, canvas: const CanvasSettings(spacing: 0));
    for (final size in [
      const Size(390, 780),
      const Size(1080, 1920),
      const Size(1200, 600)
    ]) {
      final rect = LayoutGeometry.resolve(base, size).first.rect;
      expect(rect.width / size.width, closeTo(.12, 1e-8));
      expect(rect.height / size.height, closeTo(1, 1e-8));
      final cells = LayoutGeometry.resolve(
          base.copyWith(
              canvas: const CanvasSettings(spacing: 40, outerMargin: 60)),
          size);
      expect(cells.every((c) => c.rect.width > 0 && c.rect.height > 0), isTrue);
    }
  });
  test(
      'PNG and JPEG use moved seams with filters/style/text; project reload and originals remain intact',
      () async {
    final dir = await Directory.systemTemp.createTemp('custom_export_');
    addTearDown(() => dir.delete(recursive: true));
    final paths = <String>[];
    final originals = <List<int>>[];
    for (final color in [
      img.ColorRgb8(220, 30, 20),
      img.ColorRgb8(20, 30, 220)
    ]) {
      final bitmap = img.Image(width: 16, height: 16);
      img.fill(bitmap, color: color);
      final bytes = img.encodePng(bitmap);
      originals.add(bytes);
      final path = '${dir.path}/${paths.length}.png';
      await File(path).writeAsBytes(bytes);
      paths.add(path);
    }
    var layout = gridLayout(count: 2);
    layout = layout.moveDivider(layout.dividers.single, .7);
    final source = layoutProject(count: 2, paths: paths);
    final project = source.copyWith(
        customLayout: layout,
        canvas: const CanvasSettings(spacing: 0),
        photos: [
          source.photos[0].copyWith(
              adjustments:
                  const PhotoAdjustments(preset: PhotoFilterPreset.blackWhite)),
          source.photos[1]
        ]);
    final exporter = CollageExporter(outputDirectory: dir);
    for (final format in ExportFormat.values) {
      final file = await exporter.export(
          project,
          ExportSettings(
              width: 200, height: 200, format: format, jpegQuality: 100));
      final bitmap = img.decodeImage(await file.readAsBytes())!;
      final left = bitmap.getPixel(120, 100), right = bitmap.getPixel(170, 100);
      expect(left.r, closeTo(left.g, 2));
      expect(left.g, closeTo(left.b, 2));
      expect(right.b, greaterThan(210));
      expect(right.r, lessThan(30));
      // Export contains the photo at handle anchor, never selection handles.
      final anchor = bitmap.getPixel(140, 50);
      expect(anchor.b, greaterThan(100));
    }
    final decorated = project.copyWith(
        canvas: const CanvasSettings(
            spacing: 8,
            outerMargin: 20,
            backgroundColor: 0xFFFFFF00,
            style: CanvasStyle(
                frameEnabled: true,
                frameColor: 0xFF00FF00,
                frameWidth: 5,
                shadowEnabled: true)),
        textOverlays: const [
          TextOverlay(id: 'text', text: 'X', color: 0xFFFFFFFF, fontSize: 60)
        ]);
    final decoratedFile = await exporter.export(
        decorated,
        const ExportSettings(
            width: 390, height: 390, format: ExportFormat.png));
    final bitmap = img.decodePng(await decoratedFile.readAsBytes())!;
    expect(bitmap.getPixel(0, 0).r, 255);
    expect(bitmap.getPixel(0, 0).g, 255);
    expect(bitmap.getPixel(21, 195).g, greaterThan(240));
    expect(bitmap.where((p) => p.r > 245 && p.g > 245 && p.b > 245).isNotEmpty,
        isTrue);
    for (var i = 0; i < paths.length; i++) {
      expect(await File(paths[i]).readAsBytes(), originals[i]);
    }
    final repo = ProjectRepository(documentsDirectory: dir);
    // Geometry is embedded in project JSON independently of the layout library.
    await repo.save(project);
    expect((await repo.loadProjects()).single.customLayout!.toJson(),
        layout.toJson());
  });
}
