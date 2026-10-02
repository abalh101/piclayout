import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:piclayout/features/collage_editor/layouts/layout_library.dart';
import 'package:piclayout/features/collage_editor/models/photo_asset.dart';
import 'package:piclayout/features/collage_editor/models/photo_metadata.dart';
import 'package:piclayout/features/collage_editor/models/photo_adjustments.dart';
import 'package:piclayout/features/collage_editor/models/photo_transform.dart';
import 'package:piclayout/features/collage_editor/models/layout_template.dart';
import 'package:piclayout/features/collage_editor/models/text_overlay.dart';
import 'package:piclayout/features/collage_editor/models/canvas_settings.dart';
import 'package:piclayout/features/collage_editor/state/collage_editor_controller.dart';
import 'package:piclayout/features/layout_recommendations/layout_recommendation_service.dart';
import 'package:piclayout/features/layout_recommendations/photo_metadata_reader.dart';
import 'package:piclayout/features/projects/models/collage_project.dart';
import 'package:piclayout/features/projects/services/project_repository.dart';
import 'package:piclayout/features/stickers/sticker_overlay.dart';
import 'package:piclayout/features/templates/models/collage_template.dart';
import 'support/custom_layout_fixtures.dart';

List<PhotoAsset> photos(List<PhotoMetadata?> sizes) => [
      for (var i = 0; i < sizes.length; i++)
        PhotoAsset(
            id: 'photo-$i',
            originalFileName: 'private-$i.jpg',
            localPath: '/private/$i.jpg',
            metadata: sizes[i])
    ];
const portrait = PhotoMetadata(width: 800, height: 1200);
const landscape = PhotoMetadata(width: 1600, height: 900);
const square = PhotoMetadata(width: 900, height: 900);
const engine = LayoutRecommendationService();

class _DelayedReader extends PhotoMetadataReader {
  final completer = Completer<PhotoMetadata?>();
  @override
  Future<PhotoMetadata?> read(String path) => completer.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'Dimensions derive orientation, ratio and extreme category; invalid metadata is ignored',
      () {
    expect(portrait.orientation, PhotoOrientation.portrait);
    expect(landscape.orientation, PhotoOrientation.landscape);
    expect(square.orientation, PhotoOrientation.square);
    expect(landscape.aspectRatio, closeTo(16 / 9, .001));
    expect(const PhotoMetadata(width: 400, height: 100).shape,
        PhotoShape.veryWide);
    expect(const PhotoMetadata(width: 100, height: 400).shape,
        PhotoShape.veryTall);
    expect(portrait.shape, PhotoShape.normal);
    for (final invalid in [
      null,
      {},
      {'width': 0, 'height': 10},
      {'width': 'x', 'height': 20},
      {'width': -1, 'height': 5}
    ]) {
      expect(PhotoMetadata.tryParse(invalid), isNull);
    }
    expect(
        PhotoMetadata.tryParse(portrait.toJson())!.toJson(), portrait.toJson());
    expect(portrait.rotated(1).orientation, PhotoOrientation.landscape);
  });
  test('Story with six portrait photos prefers 2x3 or staggered columns', () {
    final result =
        engine.recommend(photos(List.filled(6, portrait)), targetRatio: 9 / 16);
    expect(result.first.layout.id,
        isIn(['grid_2x3_6', 'staggered_two_columns_6']));
    expect(result.first.reasonKey, 'recStorySix');
  });
  test(
      'Landscape target prefers wide cells and mixed photos prefer asymmetric layouts',
      () {
    final wide = engine
        .recommend(photos(List.filled(4, landscape)), targetRatio: 16 / 9)
        .first;
    expect(wide.layout.kind, LayoutTemplateKind.grid);
    for (final cell in LayoutLibrary.cellsFor(wide.layout)) {
      expect(cell.rect.width / cell.rect.height * 16 / 9, greaterThan(1));
    }
    expect(wide.reasonKey, 'recLandscape');
    final mixed = engine
        .recommend(
            photos([
              portrait,
              landscape,
              portrait,
              landscape,
              portrait,
              landscape
            ]),
            targetRatio: 1)
        .first;
    expect(
        mixed.layout.kind,
        isIn([
          LayoutTemplateKind.heroTop,
          LayoutTemplateKind.heroLeft,
          LayoutTemplateKind.unevenRows
        ]));
    expect(mixed.reasonKey, 'recMixed');
    expect(
        engine
            .recommend(photos(List.filled(4, square)), targetRatio: 1)
            .first
            .layout
            .id,
        'grid_2x2_4');
  });
  test(
      'Hero reasons follow photo positions; rotation changes recommendations without changing data',
      () {
    const wide = PhotoMetadata(width: 3000, height: 1000);
    const tall = PhotoMetadata(width: 1000, height: 3000);
    expect(
        engine
            .recommend(photos([wide, portrait, portrait]), targetRatio: 1)
            .first
            .reasonKey,
        'recWideHero');
    expect(
        engine
            .recommend(photos([tall, landscape, landscape]), targetRatio: 1)
            .first
            .reasonKey,
        'recTallHero');
    final later =
        engine.recommend(photos([portrait, wide, portrait]), targetRatio: 1);
    expect(later.any((r) => r.reasonKey == 'recWideHero'), isFalse);
    final source = photos([wide, portrait, portrait]);
    final rotated = [
      source.first
          .copyWith(transform: const PhotoTransform(rotationQuarterTurns: 1)),
      ...source.skip(1)
    ];
    final rotatedHero = engine
        .recommend(rotated, targetRatio: 1)
        .singleWhere((r) => r.layout.kind == LayoutTemplateKind.heroLeft);
    expect(rotatedHero.reasonKey, 'recTallHero');
    expect(rotated.first.metadata!.width, 3000);
  });
  test(
      'Unknown metadata gives deterministic finite recommendations for every supported count; results contain no photo data',
      () {
    for (var count = 1; count <= 12; count++) {
      final input = photos(List.filled(count, null));
      final result = engine.recommend(input, targetRatio: 9 / 16);
      expect(result, isNotEmpty);
      expect(
          result.every(
              (r) => r.layout.photoCount == count && r.score.total.isFinite),
          isTrue);
      expect(
          result.map((r) => r.layout.id).toList(),
          engine
              .recommend(input, targetRatio: 9 / 16)
              .map((r) => r.layout.id)
              .toList());
      final encoded = jsonEncode(result.map((r) => r.toJson()).toList());
      for (final forbidden in ['/private', 'private-', 'localPath', 'photo-']) {
        expect(encoded, isNot(contains(forbidden)));
      }
    }
    expect(engine.recommend([], targetRatio: 1), isEmpty);
    expect(
        engine.recommend(photos([portrait]), targetRatio: double.nan), isEmpty);
  });
  test(
      'Auto Layout preserves every edit and order; one undo restores custom layout and redo restores recommendation',
      () async {
    final source = layoutProject(count: 6).copyWith(
      aspectRatioId: '9_16',
      photos: [
        for (final photo in photos(List.filled(6, portrait)))
          photo.copyWith(
              transform: const PhotoTransform(scale: 1.2, offsetX: .1),
              adjustments: const PhotoAdjustments(brightness: .2))
      ],
      customLayout: gridLayout(),
      canvas:
          const CanvasSettings(spacing: 8, outerMargin: 12, cornerRadius: 14),
      textOverlays: const [TextOverlay(id: 't', text: 'Text')],
      stickers: const [
        StickerOverlay(id: 's', type: StickerType.icon, content: 'star')
      ],
    );
    final repository = LayoutMemoryProjects();
    final controller =
        CollageEditorController(initialProject: source, repository: repository);
    addTearDown(controller.dispose);
    expect(controller.autoLayout(), isTrue);
    final changed = controller.project;
    expect(changed.customLayout, isNull);
    expect(changed.photos.map((p) => p.toJson()).toList(),
        source.photos.map((p) => p.toJson()).toList());
    expect(changed.canvas.toJson(), source.canvas.toJson());
    expect(changed.textOverlays, source.textOverlays);
    expect(changed.stickers, source.stickers);
    expect(controller.autoLayout(), isFalse); // No duplicate undo step.
    controller.undo();
    expect(controller.project.toJson(), source.toJson());
    expect(controller.canUndo, isFalse);
    controller.redo();
    expect(controller.project.toJson(), changed.toJson());
    await controller.saveNow();
    expect(repository.saved!.layoutTemplateId, changed.layoutTemplateId);
    final template = CollageTemplate.fromProject(
        id: 't', name: 'T', project: changed, includeTextOverlays: true);
    expect(jsonEncode(template.toJson()), isNot(contains('/private')));
  });
  test(
      'Lazy legacy metadata merge preserves edits made during loading and does not add undo steps',
      () async {
    final old = layoutProject(count: 1);
    expect(
        CollageProject.fromJson(old.toJson()).photos.single.metadata, isNull);
    final repository = LayoutMemoryProjects();
    final controller =
        CollageEditorController(initialProject: old, repository: repository);
    addTearDown(controller.dispose);
    final reader = _DelayedReader();
    final pending = controller.loadPhotoMetadata(reader: reader);
    expect(controller.metadataLoading, isTrue);
    expect(controller.autoLayout(), isFalse);
    controller.updateCanvas(old.canvas.copyWith(spacing: 11));
    reader.completer.complete(portrait);
    await pending;
    expect(controller.project.canvas.spacing, 11);
    expect(controller.project.photos.single.metadata!.width, 800);
    controller.undo();
    expect(controller.canUndo, isFalse);
    expect(controller.project.photos.single.metadata!.width, 800);
    await controller.saveNow();
    expect(repository.saved!.photos.single.metadata!.height, 1200);
  });
  test(
      'PNG and EXIF-oriented JPEG dimensions are read locally; corrupt/missing images are safe',
      () async {
    final root = await Directory.systemTemp.createTemp('photo_metadata');
    addTearDown(() => root.delete(recursive: true));
    const reader = PhotoMetadataReader();
    final file = File('${root.path}/photo.png');
    final bytes = img.encodePng(img.Image(width: 120, height: 80));
    await file.writeAsBytes(bytes);
    final metadata = await reader.read(file.path);
    expect(metadata!.toJson(), {'width': 120, 'height': 80});
    expect(await file.readAsBytes(), bytes);
    for (var orientation = 1; orientation <= 8; orientation++) {
      final image = img.Image(width: 120, height: 80);
      image.exif.imageIfd.orientation = orientation;
      final jpeg = File('${root.path}/oriented.jpg');
      await jpeg.writeAsBytes(img.encodeJpg(image));
      final result = await reader.read(jpeg.path);
      expect(result!.width, orientation >= 5 ? 80 : 120,
          reason: 'EXIF $orientation');
      expect(result.height, orientation >= 5 ? 120 : 80,
          reason: 'EXIF $orientation');
    }
    await file.writeAsString('broken');
    expect(await reader.read(file.path), isNull);
    expect(await reader.read('${root.path}/missing.png'), isNull);
  });
  test(
      'Import and replacement persist dimensions and select a good default; old project is still loadable',
      () async {
    final root = await Directory.systemTemp.createTemp('metadata_import');
    addTearDown(() => root.delete(recursive: true));
    final file = File('${root.path}/source.png');
    final bytes = img.encodePng(img.Image(width: 40, height: 60));
    await file.writeAsBytes(bytes);
    final repository = ProjectRepository(documentsDirectory: root);
    final project = await repository
        .createFromPickedImages(List.generate(6, (_) => XFile(file.path)));
    expect(project.layoutTemplateId, 'grid_2x3_6');
    expect(
        project.photos
            .every((p) => p.metadata?.orientation == PhotoOrientation.portrait),
        isTrue);
    final reloaded = (await repository.loadProjects()).single;
    expect(
        reloaded.photos.first.metadata!.toJson(), {'width': 40, 'height': 60});
    final replacement =
        await repository.importReplacement(XFile(file.path), project.id);
    expect(replacement.metadata!.toJson(), {'width': 40, 'height': 60});
    final oldJson = project.toJson();
    for (final photo in oldJson['photos'] as List) {
      (photo as Map).remove('metadata');
    }
    await File('${root.path}/piclayout_projects/${project.id}/project.json')
        .writeAsString(jsonEncode(oldJson));
    final legacy = (await repository.loadProjects()).single;
    expect(legacy.photos.first.metadata, isNull);
    final controller =
        CollageEditorController(initialProject: legacy, repository: repository);
    await controller.loadPhotoMetadata();
    expect(controller.canUndo, isFalse);
    await controller.saveNow();
    expect(
        (await repository.loadProjects()).single.photos.first.metadata!.width,
        40);
    controller.dispose();
    await repository.save(controller.project);
    expect(await file.readAsBytes(), bytes);
  });
}
