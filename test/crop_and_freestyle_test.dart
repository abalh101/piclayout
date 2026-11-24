import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:piclayout/features/collage_editor/models/aspect_ratio_preset.dart';
import 'package:piclayout/features/collage_editor/models/canvas_settings.dart';
import 'package:piclayout/features/collage_editor/models/canvas_style.dart';
import 'package:piclayout/features/collage_editor/models/photo_adjustments.dart';
import 'package:piclayout/features/collage_editor/models/photo_metadata.dart';
import 'package:piclayout/features/collage_editor/models/layout_template.dart';
import 'package:piclayout/features/collage_editor/models/photo_placement.dart';
import 'package:piclayout/features/collage_editor/models/photo_transform.dart';
import 'package:piclayout/features/collage_editor/models/text_overlay.dart';
import 'package:piclayout/features/collage_editor/rendering/crop_geometry.dart';
import 'package:piclayout/features/collage_editor/rendering/freestyle_geometry.dart';
import 'package:piclayout/features/collage_editor/state/collage_editor_controller.dart';
import 'package:piclayout/features/export/collage_exporter.dart';
import 'package:piclayout/features/export/export_settings.dart';
import 'package:piclayout/features/export/services/gallery_save_service.dart';
import 'package:piclayout/features/editorial/models/freeform_presets.dart';
import 'package:piclayout/features/project_archive/project_archive_service.dart';
import 'package:piclayout/features/projects/models/collage_project.dart';
import 'package:piclayout/features/projects/services/project_repository.dart';
import 'package:piclayout/features/stickers/sticker_overlay.dart';
import 'package:piclayout/features/templates/models/collage_template.dart';
import 'package:piclayout/features/templates/models/built_in_designs.dart';
import 'package:piclayout/features/layout_recommendations/layout_recommendation_service.dart';

import 'support/custom_layout_fixtures.dart';

const _transparentCanvas = CanvasSettings(
  style: CanvasStyle(backgroundType: BackgroundType.transparent),
);

Future<File> _solid(Directory root, String name, img.Color color) async {
  final bitmap = img.Image(width: 120, height: 90)..clear(color);
  return File('${root.path}/$name.png').writeAsBytes(img.encodePng(bitmap));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('switching to Editorial Freeform preserves Freestyle placement for undo',
      () {
    final controller = CollageEditorController(
        initialProject: layoutProject(count: 2),
        repository: LayoutMemoryProjects());
    addTearDown(controller.dispose);
    controller.setFreestyle(true);
    final photo = controller.project.photos.first;
    const placement = PhotoPlacement(x: .21, y: .67, rotation: 34, border: .03);
    controller.updatePlacement(photo.id, placement);
    final design =
        FreeformPresets.create('ffCanvas', controller.project.photos);
    controller.applyDesign(design);
    expect(controller.project.isFreeform, isTrue);
    expect(controller.project.freestyle, isFalse);
    expect(controller.project.photos.first.placement!.toJson(),
        placement.toJson());
    final reloaded = CollageProject.fromJson(controller.project.toJson());
    expect(reloaded.design.layers.first.source(reloaded.photos)?.id, photo.id);
    controller.undo();
    expect(controller.project.freestyle, isTrue);
    expect(controller.project.isFreeform, isFalse);
    expect(controller.project.photos.first.placement!.toJson(),
        placement.toJson());
  });

  test(
      'recommendation categories rank crop, grids and hero layouts independently',
      () {
    const service = LayoutRecommendationService();
    final project = layoutProject(count: 6);
    final photos = [
      for (final (index, photo) in project.photos.indexed)
        photo.copyWith(
            metadata: index.isEven
                ? const PhotoMetadata(width: 400, height: 150)
                : const PhotoMetadata(width: 150, height: 250)),
    ];
    final defaults = service.recommend(photos, targetRatio: 4 / 3);
    final spaced = service.recommend(photos,
        targetRatio: 4 / 3,
        canvas: const CanvasSettings(spacing: 39, outerMargin: 44));
    expect(spaced.map((item) => item.score.fit).toSet(),
        isNot(defaults.map((item) => item.score.fit).toSet()));
    final minimal = service.rankBy(spaced, LayoutFocus.minimalCrop);
    expect(minimal.first.score.fit,
        spaced.map((item) => item.score.fit).reduce((a, b) => a > b ? a : b));
    expect(
        service
            .rankBy(spaced, LayoutFocus.balanced)
            .every((item) => item.layout.kind == LayoutTemplateKind.grid),
        isTrue);
    expect(
        service
            .rankBy(spaced, LayoutFocus.hero)
            .map((item) => item.layout.kind),
        unorderedEquals(
            [LayoutTemplateKind.heroLeft, LayoutTemplateKind.heroTop]));
    expect(service.rankBy(spaced, LayoutFocus.creative).isNotEmpty, isTrue);
  });

  test(
      'built-in designs are distinct, bounded and reuse only destination photos',
      () {
    final designs = BuiltInDesigns.all;
    expect(designs.map((item) => item.id).toSet(), hasLength(6));
    expect(designs.where((item) => item.freestyle), hasLength(2));
    for (final design in designs) {
      final destination = layoutProject(count: design.photoCount);
      final result = design.applyTo(destination);
      expect(result.photos.map((item) => item.localPath),
          destination.photos.map((item) => item.localPath));
      expect(design.toJson().toString(), isNot(contains('/private')));
      expect(result.freestyle, design.freestyle);
      if (design.freestyle) {
        expect(result.photos.every((photo) => photo.placement != null), isTrue);
      }
    }
  });

  test('fill encloses every cell after rotate, flip, zoom and extreme pan', () {
    const source = Size(501, 130);
    for (final cell in [
      const Rect.fromLTWH(30, 44, 104, 315),
      const Rect.fromLTWH(0, 0, 491, 67),
      const Rect.fromLTWH(40, 20, 120, 120),
    ]) {
      for (var turn = 0; turn < 4; turn++) {
        for (final mirror in [true, false]) {
          for (final zoom in [.6, 1.0, 3.0, 300.0]) {
            final transform = PhotoTransform(
                scale: zoom,
                offsetX: -10,
                offsetY: 10,
                rotationQuarterTurns: turn,
                flipX: mirror);
            final actual = CropGeometry.resolve(cell, source, transform);
            final size = turn.isOdd
                ? Size(actual.imageSize.height, actual.imageSize.width)
                : actual.imageSize;
            final fitted = Rect.fromCenter(
                center: actual.center, width: size.width, height: size.height);
            expect(fitted.inflate(.00001).contains(cell.topLeft), isTrue);
            expect(fitted.inflate(.00001).contains(cell.bottomRight), isTrue);
            expect(actual.zoom, inInclusiveRange(1, 5));
            final fit = CropGeometry.resolve(
                cell, source, transform.copyWith(fitMode: PhotoFitMode.fit));
            expect(fit.center, cell.center);
            expect(fit.zoom, 1);
            expect(turn.isOdd ? fit.imageSize.height : fit.imageSize.width,
                lessThanOrEqualTo(cell.width + .00001));
            expect(turn.isOdd ? fit.imageSize.width : fit.imageSize.height,
                lessThanOrEqualTo(cell.height + .00001));
          }
        }
      }
    }
  });

  test('pan can reverse from a clamp and pinch keeps its focal point', () {
    const cell = Rect.fromLTWH(0, 0, 200, 100);
    const source = Size(400, 200);
    const start = PhotoTransform(scale: 2);
    final pinch = CropGeometry.gesture(cell, source, start,
        focalPoint: const Offset(60, 30),
        focalDelta: Offset.zero,
        scaleChange: 1.5);
    expect(pinch.scale, 3);
    expect(pinch.offsetX, closeTo(.1, .0001));
    expect(pinch.offsetY, closeTo(.1, .0001));
    final clamped = CropGeometry.gesture(cell, source, pinch,
        focalPoint: const Offset(60, 30),
        focalDelta: const Offset(1000, 1000),
        scaleChange: 1);
    final reversed = CropGeometry.gesture(cell, source, clamped,
        focalPoint: const Offset(60, 30),
        focalDelta: const Offset(-10, -10),
        scaleChange: 1);
    expect(reversed.offsetX, lessThan(clamped.offsetX));
    expect(reversed.offsetY, lessThan(clamped.offsetY));
  });

  test('alignment snaps to center, edges and visible neighbors', () {
    const canvas = Size(400, 400);
    final center =
        FreestyleGeometry.snap(const PhotoPlacement(x: .49, y: .51), canvas);
    expect(center.placement.x, .5);
    expect(center.placement.y, .5);
    expect(center.guideX, 200);
    final edge = FreestyleGeometry.snap(
        const PhotoPlacement(x: .105, y: .5, width: .20), canvas);
    expect(edge.guideX, 0);
    expect(edge.placement.x, closeTo(.10, .001));
    const neighbor = PhotoPlacement(x: .22, y: .21, width: .2, height: .2);
    const moving = PhotoPlacement(x: .216, y: .216, width: .45, height: .45);
    final visible =
        FreestyleGeometry.snap(moving, canvas, neighbors: [neighbor]);
    expect(visible.guideX, 88);
    final hidden = FreestyleGeometry.snap(moving, canvas,
        neighbors: [neighbor.copyWith(hidden: true)]);
    expect(hidden.guideX, isNot(88));
  });

  test('custom ratios normalize and cap export size with localized digits', () {
    final ratio = AspectRatios.custom(1400, 1000)!;
    expect(ratio.id, 'custom_7_5');
    expect(AspectRatios.byId(ratio.id).value, 7 / 5);
    expect(AspectRatios.parseDimension('١٢۳'), 123);
    expect(AspectRatios.custom(2, 9), isNull);
    expect(AspectRatios.custom(10001, 10000), isNull);
    expect(AspectRatios.byId('custom_1_0'), AspectRatios.story);
    final wide = AspectRatios.custom(4, 1)!.exportSizes();
    expect(wide, hasLength(3));
    expect((wide.last.width, wide.last.height), (4096, 1024));
  });

  test('every count from 1 through 12 seeds a normalized freestyle composition',
      () {
    for (var count = 1; count <= 12; count++) {
      final controller = CollageEditorController(
          initialProject: layoutProject(count: count),
          repository: LayoutMemoryProjects());
      controller.setFreestyle(true);
      expect(
          controller.project.photos.every((photo) => photo.placement != null),
          isTrue,
          reason: '$count');
      final placements = controller.project.photos.map((p) => p.placement!);
      for (final item in placements) {
        final small = item.rect(const Size(300, 200));
        final large = item.rect(const Size(1200, 800));
        expect(large.width, closeTo(small.width * 4, .0001));
        expect(large.center.dy, closeTo(small.center.dy * 4, .0001));
      }
      controller.setFreestyle(false);
      expect(controller.project.photos.map((photo) => photo.placement),
          placements);
      controller.undo();
      expect(controller.project.freestyle, isTrue);
      controller.dispose();
    }
  });

  test(
      'freestyle, layers and custom ratio survive storage, duplicate, templates and archive',
      () async {
    final root = await Directory.systemTemp.createTemp('piclayout_free_');
    addTearDown(() => root.delete(recursive: true));
    final source = await _solid(root, 'source', img.ColorRgb8(190, 20, 50));
    final bytes = await source.readAsBytes();
    final repository = ProjectRepository(documentsDirectory: root);
    final initial =
        await repository.createFromPickedImages([XFile(source.path)]);
    final controller = CollageEditorController(
        initialProject: initial, repository: repository);
    addTearDown(controller.dispose);
    controller.setFreestyle(true);
    controller.setAspectRatio(AspectRatios.custom(7, 5)!);
    controller.duplicateSelectedPhoto();
    expect(controller.project.photos, hasLength(2));
    expect(controller.project.photos.first.localPath,
        controller.project.photos.last.localPath);
    final last = controller.selectedPhoto!;
    const editedPlacement = PhotoPlacement(
        x: .33,
        y: .42,
        rotation: 23,
        opacity: .67,
        border: .08,
        shadow: true,
        locked: true,
        hidden: true);
    controller.updatePlacement(last.id, editedPlacement);
    final text = controller.addText('Summer');
    controller.updateText(text.copyWith(hidden: true));
    final sticker = controller.addSticker(StickerCatalog.items.first);
    controller.updateSticker(sticker.copyWith(locked: true));
    await controller.saveNow();

    void verify(CollageProject project) {
      expect(project.freestyle, isTrue);
      expect(project.aspectRatio.label, '7:5');
      expect(project.photos.last.placement!.toJson(), editedPlacement.toJson());
      expect(project.textOverlays.single.hidden, isTrue);
      expect(project.stickers.single.locked, isTrue);
    }

    final loaded = (await repository.loadProjects()).single;
    verify(loaded);
    final duplicate = await repository.duplicate(loaded);
    verify(duplicate);
    expect(duplicate.id, isNot(loaded.id));
    expect(duplicate.photos.first.id, isNot(loaded.photos.first.id));
    final template = CollageTemplate.fromProject(
        id: 'preset',
        name: 'Freestyle',
        project: loaded,
        includeTextOverlays: true,
        includeStickers: true);
    final json = template.toJson();
    expect(json.toString(), isNot(contains(root.path)));
    expect(json.toString(), isNot(contains(loaded.photos.first.id)));
    verify(CollageTemplate.fromJson(json).applyTo(layoutProject(count: 2)));
    final archives = ProjectArchiveService(
        documentsDirectory: root, temporaryDirectory: root);
    final imported =
        await archives.importProject(await archives.exportProject(loaded));
    verify(imported);
    expect(imported.id, isNot(loaded.id));
    expect(await source.readAsBytes(), bytes);
  });

  test(
      'visible z-order, opacity, rotation and transparency render to PNG and JPEG pixels',
      () async {
    final root =
        await Directory.systemTemp.createTemp('piclayout_free_pixels_');
    addTearDown(() => root.delete(recursive: true));
    final red = await _solid(root, 'red', img.ColorRgb8(240, 0, 0));
    final green = await _solid(root, 'green', img.ColorRgb8(0, 240, 0));
    final initial = layoutProject(count: 2, paths: [red.path, green.path]);
    const front = PhotoPlacement(
        width: .60, height: .25, rotation: 45, opacity: .5, border: .03);
    final project =
        initial.copyWith(freestyle: true, canvas: _transparentCanvas, photos: [
      initial.photos.first
          .copyWith(placement: const PhotoPlacement(width: .78, height: .78)),
      initial.photos.last.copyWith(placement: front),
    ], textOverlays: [
      const TextOverlay(
          id: 'hidden',
          text: 'HIDDEN',
          hidden: true,
          backgroundColor: 0xFFFFFFFF)
    ]);
    final exporter = CollageExporter(outputDirectory: root);
    Future<img.Image> render(
        CollageProject project, ExportFormat format) async {
      final result = await exporter.export(
          project,
          ExportSettings(
              width: 200, height: 200, format: format, jpegQuality: 100));
      return img.decodeImage(await result.readAsBytes())!;
    }

    for (final format in ExportFormat.values) {
      final image = await render(project, format);
      final overlap = image.getPixel(100, 100);
      expect(overlap.r, closeTo(120, 8));
      expect(overlap.g, closeTo(120, 8));
      expect(image.getPixel(134, 134).g, greaterThan(85));
      expect(image.getPixel(134, 66).g, lessThan(8));
      if (format == ExportFormat.png) {
        expect(image.getPixel(0, 0).a, 0);
      } else {
        expect(image.getPixel(0, 0).r, greaterThan(240));
      }
    }
    final reordered = await render(
        project.copyWith(photos: project.photos.reversed.toList()),
        ExportFormat.png);
    expect(reordered.getPixel(100, 100).g, 0);
    final hidden = await render(
        project.copyWith(photos: [
          project.photos.first,
          project.photos.last.copyWith(
              localPath: '/missing.png',
              placement: front.copyWith(hidden: true)),
        ]),
        ExportFormat.png);
    expect(hidden.getPixel(100, 100).r, 240);
  });

  test('export uses the same crop clamp for an extreme legacy transform',
      () async {
    final root =
        await Directory.systemTemp.createTemp('piclayout_crop_pixels_');
    addTearDown(() => root.delete(recursive: true));
    final photo = await _solid(root, 'photo', img.ColorRgb8(20, 160, 30));
    final initial = layoutProject(count: 1, paths: [photo.path]);
    final transformed = initial.photos.single.copyWith(
        transform: const PhotoTransform(
            scale: .5,
            offsetX: 10,
            offsetY: -10,
            rotationQuarterTurns: 1,
            flipX: true));
    final project =
        initial.copyWith(canvas: _transparentCanvas, photos: [transformed]);
    final exporter = CollageExporter(outputDirectory: root);
    const config =
        ExportSettings(width: 160, height: 100, format: ExportFormat.png);
    final fill = img.decodePng(
        await (await exporter.export(project, config)).readAsBytes())!;
    expect(fill.every((pixel) => pixel.a == 255 && pixel.g == 160), isTrue);
    final fit = img.decodePng(await (await exporter.export(
            project.copyWith(photos: [
              transformed.copyWith(
                  transform:
                      transformed.transform.copyWith(fitMode: PhotoFitMode.fit))
            ]),
            config))
        .readAsBytes())!;
    expect(fit.getPixel(1, 50).a, 0);
    expect(fit.getPixel(80, 50).g, 160);
    await expectLater(
        exporter.export(
            project,
            const ExportSettings(
                width: 4100, height: 100, format: ExportFormat.png)),
        throwsA(isA<ExportFailure>()));
  });

  test('export prunes only expired PicLayout cache files', () async {
    final root = await Directory.systemTemp.createTemp('piclayout_cache_');
    addTearDown(() => root.delete(recursive: true));
    final source = await _solid(root, 'source', img.ColorRgb8(210, 20, 30));
    final cache = await Directory('${root.path}/piclayout_exports').create();
    final stale =
        await File('${cache.path}/piclayout_123.png').writeAsString('old');
    final other = await File('${cache.path}/other.png').writeAsString('keep');
    final old = DateTime.now().subtract(const Duration(days: 3));
    await stale.setLastModified(old);
    await other.setLastModified(old);
    final output = await CollageExporter(outputDirectory: root).export(
      layoutProject(count: 1, paths: [source.path]),
      const ExportSettings(width: 100, height: 100, format: ExportFormat.png),
    );
    expect(await stale.exists(), isFalse);
    expect(await other.exists(), isTrue);
    expect(await source.exists(), isTrue);
    expect(await output.exists(), isTrue);
  });

  test('detail shader lifts shadows, reduces highlights and sharpens locally',
      () async {
    final root =
        await Directory.systemTemp.createTemp('piclayout_detail_pixels_');
    addTearDown(() => root.delete(recursive: true));
    final source = img.Image(width: 256, height: 256);
    for (final pixel in source) {
      final shade = pixel.x < 128 ? 60 : 184;
      pixel.setRgb(shade, shade, shade);
    }
    final file = await File('${root.path}/detail.png')
        .writeAsBytes(img.encodePng(source));
    final initial = layoutProject(count: 1, paths: [file.path]);
    Future<img.Image> render(PhotoAdjustments adjustments) async {
      final project = initial.copyWith(
          photos: [initial.photos.single.copyWith(adjustments: adjustments)]);
      final output = await CollageExporter(outputDirectory: root).export(
          project,
          const ExportSettings(
              width: 256, height: 256, format: ExportFormat.png));
      return img.decodePng(await output.readAsBytes())!;
    }

    final tone =
        await render(const PhotoAdjustments(shadows: .8, highlights: -.8));
    expect(tone.getPixel(60, 126).r, greaterThan(75));
    expect(tone.getPixel(195, 126).r, lessThan(175));
    final sharpened = await render(const PhotoAdjustments(sharpness: 1));
    expect(sharpened.getPixel(30, 126).r, closeTo(60, 1));
    expect(sharpened.getPixel(127, 126).r, lessThan(60));
    expect(sharpened.getPixel(128, 126).r, greaterThan(184));
    final vignette = await render(const PhotoAdjustments(vignette: 1));
    expect(vignette.getPixel(4, 4).r, lessThan(30));
    expect(vignette.getPixel(130, 128).r, closeTo(184, 2));
  });
}
