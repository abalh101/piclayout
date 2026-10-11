import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:piclayout/features/collage_editor/models/aspect_ratio_preset.dart';
import 'package:piclayout/features/collage_editor/models/photo_metadata.dart';
import 'package:piclayout/features/collage_editor/models/photo_transform.dart';
import 'package:piclayout/features/collage_editor/rendering/photo_crop.dart';
import 'package:piclayout/features/collage_editor/rendering/project_image_loader.dart';
import 'package:piclayout/features/collage_editor/rendering/style_renderer.dart';
import 'package:piclayout/features/collage_editor/state/collage_editor_controller.dart';
import 'package:piclayout/features/export/collage_exporter.dart';
import 'package:piclayout/features/export/export_settings.dart';

import 'support/custom_layout_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Fill covers every edge for wide/tall photos, rotation, flip and zoom',
      () {
    final random = math.Random(42);
    for (var i = 0; i < 300; i++) {
      final source = Size(
          10 + random.nextDouble() * 2000, 10 + random.nextDouble() * 2000);
      final cell =
          Size(10 + random.nextDouble() * 500, 10 + random.nextDouble() * 500);
      final input = PhotoTransform(
          scale: random.nextDouble() * 10,
          offsetX: random.nextDouble() * 200 - 100,
          offsetY: random.nextDouble() * 200 - 100,
          rotationQuarterTurns: i % 4,
          flipX: i.isEven);
      final result = PhotoCrop.clamp(input, source, cell);
      final w = i.isOdd ? source.height : source.width;
      final h = i.isOdd ? source.width : source.height;
      final base = math.max(cell.width / w, cell.height / h);
      final left = cell.width / 2 +
          result.offsetX * cell.width -
          w * base * result.scale / 2;
      final top = cell.height / 2 +
          result.offsetY * cell.height -
          h * base * result.scale / 2;
      expect(left, lessThanOrEqualTo(1e-8));
      expect(top, lessThanOrEqualTo(1e-8));
      expect(left + w * base * result.scale,
          greaterThanOrEqualTo(cell.width - 1e-8));
      expect(top + h * base * result.scale,
          greaterThanOrEqualTo(cell.height - 1e-8));
      expect(result.scale, inInclusiveRange(1, 5));
      final scaled =
          PhotoCrop.clamp(input, source, Size(cell.width * 4, cell.height * 4));
      expect(scaled.offsetX, closeTo(result.offsetX, 1e-10));
      expect(scaled.offsetY, closeTo(result.offsetY, 1e-10));
      expect(PhotoCrop.clamp(result, source, cell).toJson(), result.toJson());
    }
  });

  test('Fit keeps intentional empty space; malformed values stay finite', () {
    final fit = PhotoCrop.clamp(
        const PhotoTransform(
            fitMode: PhotoFitMode.fit, scale: .5, offsetX: .7, offsetY: -.8),
        const Size(200, 100),
        const Size(100, 100));
    expect(fit.scale, .5);
    expect(fit.offsetX, .7);
    expect(fit.offsetY, -.8);
    final invalid = PhotoCrop.clamp(
        const PhotoTransform(
            scale: double.nan, offsetX: double.infinity, offsetY: double.nan),
        const Size(100, 100),
        const Size(100, 100));
    expect(invalid.toJson(), PhotoTransform.identity.toJson());
  });

  testWidgets(
      'Clamped gestures, rotate/flip/reset and ratio changes undo and autosave',
      (tester) async {
    final repo = LayoutMemoryProjects();
    final original = layoutProject(count: 1);
    final controller = CollageEditorController(
        initialProject: original.copyWith(photos: [
          original.photos.single
              .copyWith(metadata: const PhotoMetadata(width: 200, height: 100))
        ]),
        repository: repo);
    addTearDown(controller.dispose);
    final id = controller.selectedPhoto!.id;
    controller.beginInteractiveTransform();
    controller.updateTransformLive(
        id, const PhotoTransform(scale: .5, offsetX: 100, offsetY: -100));
    expect(controller.selectedPhoto!.transform.scale, 1);
    expect(controller.selectedPhoto!.transform.offsetX, .5);
    expect(controller.selectedPhoto!.transform.offsetY, 0);
    controller.updateTransformLive(
        id, controller.selectedPhoto!.transform.copyWith(offsetX: .4));
    controller.endInteractiveTransform();
    await tester.pump(const Duration(milliseconds: 701));
    expect(repo.saved!.photos.single.transform.offsetX, .4);
    controller.undo();
    expect(controller.selectedPhoto!.transform.offsetX, 0);
    controller.redo();
    expect(controller.selectedPhoto!.transform.offsetX, .4);
    controller.rotateSelected();
    expect(controller.selectedPhoto!.transform.rotationQuarterTurns, 1);
    expect(controller.selectedPhoto!.transform.offsetX, 0);
    controller.flipSelected();
    expect(controller.selectedPhoto!.transform.flipX, isTrue);
    controller.setSelectedFitMode(PhotoFitMode.fit);
    controller.setTransform(
        id, controller.selectedPhoto!.transform.copyWith(scale: .5));
    expect(controller.selectedPhoto!.transform.scale, .5);
    controller.setSelectedFitMode(PhotoFitMode.fill);
    expect(controller.selectedPhoto!.transform.scale, 1);
    controller.setAspectRatio(AspectRatios.parse('3', '2'));
    controller.resetSelectedTransform();
    expect(controller.selectedPhoto!.transform.toJson(),
        PhotoTransform.identity.toJson());
    await controller.saveNow();
    expect(repo.saved!.aspectRatio.value, 1.5);
  });

  test(
      'PNG export matches shared preview cropping, including rotation/flip and Fit',
      () async {
    final root = await Directory.systemTemp.createTemp('crop_export_test_');
    addTearDown(() => root.delete(recursive: true));
    final bitmap = img.Image(width: 60, height: 40);
    for (var y = 0; y < 40; y++) {
      for (var x = 0; x < 60; x++) {
        bitmap.setPixelRgb(x, y, x * 4, y * 6, (x + y) * 2);
      }
    }
    final bytes = img.encodePng(bitmap);
    final file = File('${root.path}/original.png');
    await file.writeAsBytes(bytes);
    Size? naturalSize;
    final thumbnail = await loadProjectImage(file.path,
        maxEdge: 31, onSourceSize: (size) => naturalSize = size);
    expect(naturalSize, const Size(60, 40));
    expect(thumbnail.width, 31);
    expect(thumbnail.height, 21);
    thumbnail.dispose();
    final codec = await ui.instantiateImageCodec(bytes);
    final image = (await codec.getNextFrame()).image;
    codec.dispose();
    addTearDown(image.dispose);
    final base = layoutProject(count: 1, paths: [file.path])
        .copyWith(aspectRatioId: AspectRatios.parse('3', '2').id);
    for (final mode in PhotoFitMode.values) {
      for (var rotation = 0; rotation < 4; rotation++) {
        for (final flip in [false, true]) {
          final transform = PhotoTransform(
              scale: mode == PhotoFitMode.fill ? .6 : .5,
              offsetX: 8,
              offsetY: -8,
              rotationQuarterTurns: rotation,
              flipX: flip,
              fitMode: mode);
          final project = base.copyWith(photos: [
            base.photos.single.copyWith(
                transform: transform,
                metadata: const PhotoMetadata(width: 60, height: 40))
          ]);
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          StyleRenderer.background(canvas, const Size(120, 80), project.canvas);
          StyleRenderer.photo(
              canvas, image, const Rect.fromLTWH(0, 0, 120, 80), 0, transform);
          final picture = recorder.endRecording();
          final preview = await picture.toImage(120, 80);
          picture.dispose();
          final data = await preview.toByteData(format: ui.ImageByteFormat.png);
          preview.dispose();
          final expected = img.decodePng(data!.buffer.asUint8List())!;
          final output = await CollageExporter(outputDirectory: root).export(
              project,
              const ExportSettings(
                  width: 120, height: 80, format: ExportFormat.png));
          final actual = img.decodePng(await output.readAsBytes())!;
          expect(actual.width, 120);
          expect(actual.height, 80);
          expect(actual.getBytes(), expected.getBytes(),
              reason: '$mode/$rotation/$flip');
          if (rotation == 0 && !flip) {
            final jpeg = await CollageExporter(outputDirectory: root).export(
                project,
                const ExportSettings(
                    width: 120,
                    height: 80,
                    format: ExportFormat.jpeg,
                    jpegQuality: 100));
            final jpegPixel =
                img.decodeJpg(await jpeg.readAsBytes())!.getPixel(60, 40);
            final previewPixel = expected.getPixel(60, 40);
            expect(jpegPixel.r, closeTo(previewPixel.r, 4));
            expect(jpegPixel.g, closeTo(previewPixel.g, 4));
            expect(jpegPixel.b, closeTo(previewPixel.b, 4));
          }
        }
      }
    }
    expect(await file.readAsBytes(), bytes);
  });
}
