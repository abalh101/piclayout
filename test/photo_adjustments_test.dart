import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:piclayout/features/collage_editor/models/photo_adjustments.dart';
import 'package:piclayout/features/collage_editor/models/photo_transform.dart';
import 'package:piclayout/features/collage_editor/rendering/photo_filter_renderer.dart';
import 'package:piclayout/features/collage_editor/rendering/style_renderer.dart';
import 'package:piclayout/features/collage_editor/state/collage_editor_controller.dart';
import 'package:piclayout/features/collage_editor/widgets/photo_edit_sheet.dart';
import 'package:piclayout/features/export/collage_exporter.dart';
import 'package:piclayout/features/export/export_settings.dart';
import 'package:piclayout/features/projects/models/collage_project.dart';
import 'package:piclayout/features/templates/models/collage_template.dart';
import 'style_studio_test.dart' as fixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const edits = PhotoAdjustments(
      preset: PhotoFilterPreset.vintage,
      filterIntensity: .6,
      brightness: .1,
      contrast: 1.2,
      saturation: .8,
      warmth: .3);
  test('Photo adjustments and projects round trip; legacy defaults to original',
      () {
    expect(
        PhotoAdjustments.fromJson(jsonDecode(jsonEncode(edits.toJson())))
            .toJson(),
        edits.toJson());
    final source = fixture.project();
    final json = source.toJson();
    for (final photo in json['photos'] as List) {
      (photo as Map).remove('adjustments');
    }
    expect(CollageProject.fromJson(json).photos.single.adjustments.toJson(),
        const PhotoAdjustments().toJson());
    final filtered = source
        .copyWith(photos: [source.photos.single.copyWith(adjustments: edits)]);
    expect(
        CollageProject.fromJson(filtered.toJson())
            .photos
            .single
            .adjustments
            .toJson(),
        edits.toJson());
    expect(
        PhotoAdjustments.fromJson(
                {'preset': 'future', 'brightness': 99, 'warmth': double.nan})
            .brightness,
        1);
    expect(PhotoAdjustments.fromJson({'preset': 'future'}).preset,
        PhotoFilterPreset.original);
    final template = CollageTemplate.fromProject(
        id: 't', name: 't', project: filtered, includeTextOverlays: false);
    expect(jsonEncode(template.toJson()), isNot(contains('/private')));
    expect(jsonEncode(template.toJson()), isNot(contains('adjustments')));
    expect(template.applyTo(filtered).photos.single.adjustments.toJson(),
        edits.toJson());
  });
  test('Filter edits preserve path/crop, undo/redo and save together',
      () async {
    final repository = fixture.MemoryRepository();
    final source = fixture.project();
    final controller =
        CollageEditorController(initialProject: source, repository: repository);
    addTearDown(controller.dispose);
    const transform = PhotoTransform(
        scale: 1.8, offsetX: .2, rotationQuarterTurns: 1, flipX: true);
    controller.setTransform(source.photos.single.id, transform);
    controller.setAdjustments(source.photos.single.id, edits);
    expect(controller.selectedPhoto!.localPath, source.photos.single.localPath);
    expect(controller.selectedPhoto!.transform.toJson(), transform.toJson());
    controller.undo();
    expect(controller.selectedPhoto!.adjustments.preset,
        PhotoFilterPreset.original);
    controller.redo();
    expect(controller.selectedPhoto!.adjustments.toJson(), edits.toJson());
    await controller.saveNow();
    expect(
        repository.saved!.photos.single.adjustments.toJson(), edits.toJson());
  });
  test('Neutral matrix and zero intensity preserve original', () {
    expect(PhotoFilterRenderer.matrix(const PhotoAdjustments()),
        PhotoFilterRenderer.identity);
    for (final preset in PhotoFilterPreset.values) {
      expect(
          PhotoFilterRenderer.matrix(
              PhotoAdjustments(preset: preset, filterIntensity: 0)),
          PhotoFilterRenderer.identity);
    }
  });
  test(
      'Shared preview renderer equals PNG pixels; PNG/JPEG contain filter without altering originals',
      () async {
    final dir = await Directory.systemTemp.createTemp('filters_test');
    addTearDown(() => dir.delete(recursive: true));
    final bitmap = img.Image(width: 16, height: 16);
    img.fill(bitmap, color: img.ColorRgb8(180, 100, 40));
    final bytes = img.encodePng(bitmap);
    final file = File('${dir.path}/original.png');
    await file.writeAsBytes(bytes);
    final source = fixture.project(file.path);
    final codec = await ui.instantiateImageCodec(bytes);
    final image = (await codec.getNextFrame()).image;
    codec.dispose();
    addTearDown(image.dispose);
    final exporter = CollageExporter(outputDirectory: dir);
    for (final preset in PhotoFilterPreset.values) {
      final adjustments = PhotoAdjustments(preset: preset);
      final filtered = source.copyWith(
          photos: [source.photos.single.copyWith(adjustments: adjustments)]);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      StyleRenderer.photo(canvas, image, const Rect.fromLTWH(0, 0, 64, 64), 0,
          PhotoTransform.identity,
          adjustments: adjustments);
      final picture = recorder.endRecording();
      final preview = await picture.toImage(64, 64);
      final previewBytes =
          await preview.toByteData(format: ui.ImageByteFormat.png);
      final previewPixel =
          img.decodePng(previewBytes!.buffer.asUint8List())!.getPixel(32, 32);
      preview.dispose();
      picture.dispose();
      for (final format in ExportFormat.values) {
        final result = await exporter.export(
            filtered,
            ExportSettings(
                width: 64, height: 64, format: format, jpegQuality: 100));
        final pixel =
            img.decodeImage(await result.readAsBytes())!.getPixel(32, 32);
        final tolerance = format == ExportFormat.png ? 0 : 3;
        expect(pixel.r, closeTo(previewPixel.r, tolerance),
            reason: preset.name);
        expect(pixel.g, closeTo(previewPixel.g, tolerance),
            reason: preset.name);
        expect(pixel.b, closeTo(previewPixel.b, tolerance),
            reason: preset.name);
        if (preset != PhotoFilterPreset.original) {
          expect([pixel.r, pixel.g, pixel.b], isNot([180, 100, 40]),
              reason: preset.name);
        }
      }
    }
    expect(await file.readAsBytes(), bytes);
  });
  testWidgets(
      'Edit is staged; confirm autosaves, reopen retains edits, cancel discards',
      (tester) async {
    final repository = fixture.MemoryRepository();
    final controller = CollageEditorController(
        initialProject: fixture.project(), repository: repository);
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () => showPhotoEditor(context, controller),
                    child: const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Warm'));
    await tester.pump();
    expect(controller.selectedPhoto!.adjustments.preset,
        PhotoFilterPreset.original);
    await tester.tap(find.text('Fertig'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    expect(repository.saved!.photos.single.adjustments.preset,
        PhotoFilterPreset.warm);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Warm'))
            .selected,
        isTrue);
    await tester.tap(find.text('Kühl'));
    await tester.pump();
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(
        controller.selectedPhoto!.adjustments.preset, PhotoFilterPreset.warm);
    controller.undo();
    expect(controller.selectedPhoto!.adjustments.preset,
        PhotoFilterPreset.original);
    await controller.saveNow();
    expect(tester.takeException(), isNull);
  });
}
