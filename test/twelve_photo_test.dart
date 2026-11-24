import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:piclayout/features/collage_editor/models/canvas_settings.dart';
import 'package:piclayout/features/collage_editor/models/photo_adjustments.dart';
import 'package:piclayout/features/collage_editor/models/photo_asset.dart';
import 'package:piclayout/features/collage_editor/models/photo_transform.dart';
import 'package:piclayout/features/collage_editor/models/text_overlay.dart';
import 'package:piclayout/features/collage_editor/rendering/layout_geometry.dart';
import 'package:piclayout/features/collage_editor/rendering/project_image_loader.dart';
import 'package:piclayout/features/collage_editor/rendering/style_renderer.dart';
import 'package:piclayout/features/collage_editor/rendering/text_overlay_renderer.dart';
import 'package:piclayout/features/collage_editor/state/collage_editor_controller.dart';
import 'package:piclayout/features/export/collage_exporter.dart';
import 'package:piclayout/features/export/export_settings.dart';
import 'package:piclayout/features/layout_recommendations/layout_recommendation_service.dart';
import 'package:piclayout/features/projects/models/collage_project.dart';
import 'package:piclayout/features/projects/services/project_repository.dart';
import 'package:piclayout/features/stickers/sticker_overlay.dart';
import 'package:piclayout/features/stickers/sticker_renderer.dart';
import 'package:piclayout/features/templates/models/collage_template.dart';
import 'support/custom_layout_fixtures.dart';

class _Replacements extends LayoutMemoryProjects {
  @override
  Future<PhotoAsset> importReplacement(XFile picked, String projectId) async =>
      layoutProject(count: 1, paths: [picked.path])
          .photos
          .first
          .copyWith(id: 'replacement');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      '12 photos retain edits across reorder, replace, remove, templates and undo/redo',
      () async {
    final base = layoutProject(count: 12);
    final original = base.copyWith(photos: [
      for (final photo in base.photos)
        photo.copyWith(
            transform:
                const PhotoTransform(scale: 1.4, offsetX: .1, flipX: true),
            adjustments: const PhotoAdjustments(preset: PhotoFilterPreset.warm))
    ], textOverlays: const [
      TextOverlay(id: 'text', text: 'Twelve')
    ], stickers: const [
      StickerOverlay(id: 'label', type: StickerType.label, content: 'Hello')
    ]);
    final repository = _Replacements();
    final controller = CollageEditorController(
        initialProject: original, repository: repository);
    addTearDown(controller.dispose);
    controller.reorderPhotos(0, 11);
    expect(controller.project.photos.last.id, 'photo-0');
    controller.undo();
    expect(controller.project.photos, original.photos);
    controller.redo();
    controller.selectPhoto('photo-11');
    await controller.replaceSelected(XFile('/replacement.png'));
    expect(controller.project.photos[10].id, 'replacement');
    expect(controller.project.photos[10].transform.toJson(),
        original.photos[11].transform.toJson());
    controller.undo();
    expect(controller.project.photos[10].id, 'photo-11');
    controller.applyCustomLayout(gridLayout(count: 12));
    final template = CollageTemplate.fromProject(
        id: 'template',
        name: 'Twelve',
        project: controller.project,
        includeTextOverlays: true,
        includeStickers: true);
    final restored = CollageTemplate.fromJson(template.toJson());
    expect(restored.applyTo(base).customLayout!.photoCount, 12);
    expect(restored.applyTo(layoutProject(count: 6)).customLayout, isNull);
    controller.removeSelected();
    expect(controller.project.photos, hasLength(11));
    expect(controller.project.customLayout, isNull);
    controller.undo();
    expect(controller.project.photos, hasLength(12));
    expect(controller.project.customLayout!.photoCount, 12);
    expect(
        controller.project.photos
            .every((p) => p.adjustments.preset == PhotoFilterPreset.warm),
        isTrue);
    expect(controller.project.textOverlays, original.textOverlays);
    expect(controller.project.stickers, original.stickers);
    await controller.saveNow();
    final loaded = CollageProject.fromJson(repository.saved!.toJson());
    expect(loaded.photos, hasLength(12));
    expect(loaded.stickers.single.content, 'Hello');
    expect(loaded.textOverlays.single.text, 'Twelve');
    final recommendations = const LayoutRecommendationService()
        .recommend(loaded.photos, targetRatio: 1);
    expect(recommendations, isNotEmpty);
    expect(recommendations.every((r) => r.layout.photoCount == 12), isTrue);
    expect(
        () => loaded.copyWith(photos: [
              ...loaded.photos,
              loaded.photos.first
            ]).normalizedForPhotoCount(),
        throwsArgumentError);
  });

  test(
      '12-photo PNG matches shared preview after direct divider edits; JPEG and reload keep every cell',
      () async {
    final root = await Directory.systemTemp.createTemp('twelve_export_');
    addTearDown(() => root.delete(recursive: true));
    final paths = <String>[];
    final imageDirectory =
        Directory('${root.path}/piclayout_projects/project/images');
    await imageDirectory.create(recursive: true);
    final images = <ui.Image>[];
    addTearDown(() {
      for (final image in images) {
        image.dispose();
      }
    });
    for (var i = 0; i < 12; i++) {
      final bitmap = img.Image(width: 60, height: 40);
      for (var y = 0; y < bitmap.height; y++) {
        for (var x = 0; x < bitmap.width; x++) {
          bitmap.setPixelRgb(x, y, i * 20, x * 4, y * 6);
        }
      }
      final path = '${imageDirectory.path}/$i.png';
      await File(path).writeAsBytes(img.encodePng(bitmap));
      paths.add(path);
      images.add(await loadProjectImage(path));
    }
    final base = layoutProject(count: 12, paths: paths);
    final repository = ProjectRepository(documentsDirectory: root);
    final controller = CollageEditorController(
        initialProject: base.copyWith(
            canvas: const CanvasSettings(spacing: 8, outerMargin: 10),
            photos: [
              for (var i = 0; i < 12; i++)
                base.photos[i].copyWith(
                    transform: PhotoTransform(
                        scale: 1.3,
                        offsetX: .4,
                        offsetY: -.2,
                        rotationQuarterTurns: i % 4,
                        flipX: i.isOdd),
                    adjustments: PhotoAdjustments(
                        preset: i == 0
                            ? PhotoFilterPreset.warm
                            : PhotoFilterPreset.original))
            ],
            textOverlays: const [
              TextOverlay(id: 'text', text: '12 photos')
            ],
            stickers: const [
              StickerOverlay(
                  id: 'label',
                  type: StickerType.label,
                  content: 'Hi',
                  x: .8,
                  y: .9)
            ]),
        repository: repository);
    final divider = controller.editableCanvasLayout!.dividers.first;
    controller.beginDividerDrag(divider);
    controller.updateDividerDrag(.42);
    controller.endDividerDrag();
    await controller.saveNow();
    final project = (await repository.loadProjects()).single;
    controller.dispose();
    // Flush the controller's disposal save before deleting the temporary root.
    await repository.save(project);
    expect(project.customLayout!.toJson(),
        controller.project.customLayout!.toJson());
    const size = Size(390, 390);
    final cells = LayoutGeometry.resolve(project, size);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    StyleRenderer.background(canvas, size, project.canvas);
    StyleRenderer.shadows(canvas, size, project.canvas, cells);
    for (final cell in cells) {
      final photo = project.photos[cell.photoIndex];
      StyleRenderer.photo(canvas, images[cell.photoIndex], cell.rect,
          cell.cornerRadius, photo.transform,
          adjustments: photo.adjustments);
    }
    StyleRenderer.frames(canvas, size, project.canvas, cells);
    TextOverlayRenderer.paint(canvas, size, project.textOverlays);
    StickerRenderer.paint(canvas, size, project.stickers);
    final picture = recorder.endRecording();
    final preview = await picture.toImage(390, 390);
    picture.dispose();
    final data = await preview.toByteData(format: ui.ImageByteFormat.png);
    preview.dispose();
    final expected = img.decodePng(data!.buffer.asUint8List())!;
    final exporter = CollageExporter(outputDirectory: root);
    final png = await exporter.export(
        project,
        const ExportSettings(
            width: 390, height: 390, format: ExportFormat.png));
    final actual = img.decodePng(await png.readAsBytes())!;
    expect(actual.getBytes(), expected.getBytes());
    final jpeg = await exporter.export(
        project,
        const ExportSettings(
            width: 390,
            height: 390,
            format: ExportFormat.jpeg,
            jpegQuality: 100));
    final jpg = img.decodeJpg(await jpeg.readAsBytes())!;
    for (final cell in cells) {
      final x = cell.rect.center.dx.round(), y = cell.rect.center.dy.round();
      expect(jpg.getPixel(x, y).r, closeTo(expected.getPixel(x, y).r, 5),
          reason: 'photo ${cell.photoIndex}');
    }
  });
}
