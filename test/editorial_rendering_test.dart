import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:piclayout/features/editorial/models/editorial_design.dart';
import 'package:piclayout/features/editorial/models/design_presets.dart';
import 'package:piclayout/features/editorial/rendering/editorial_renderer.dart';
import 'package:piclayout/features/collage_editor/models/canvas_settings.dart';
import 'package:piclayout/features/collage_editor/models/canvas_style.dart';
import 'package:piclayout/features/collage_editor/models/photo_adjustments.dart';
import 'package:piclayout/features/collage_editor/models/photo_transform.dart';
import 'package:piclayout/features/collage_editor/rendering/project_image_loader.dart';
import 'package:piclayout/features/collage_editor/rendering/style_renderer.dart';
import 'package:piclayout/features/export/collage_exporter.dart';
import 'package:piclayout/features/export/export_settings.dart';
import 'package:piclayout/features/projects/models/collage_project.dart';
import 'support/editorial_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late File source;
  late List<int> original;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('editorial_pixels_');
    source = File('${dir.path}/source.png');
    final bitmap = img.Image(width: 80, height: 80, numChannels: 4);
    for (var y = 0; y < 80; y++) {
      for (var x = 0; x < 80; x++) {
        bitmap.setPixelRgba(x, y, x < 40 ? 255 : 0, 0, x < 40 ? 0 : 255, 255);
      }
    }
    original = img.encodePng(bitmap);
    await source.writeAsBytes(original);
  });
  tearDown(() async {
    expect(await source.readAsBytes(), original);
    await dir.delete(recursive: true);
  });
  CollageProject project(List<DesignLayer> layers) =>
      editorialProject(count: 1, path: source.path).copyWith(
          canvas: const CanvasSettings(
              style: CanvasStyle(backgroundType: BackgroundType.transparent)),
          design: EditorialDesign(mode: DesignMode.blank, layers: layers));
  Future<img.Image> export(CollageProject p,
      {ExportFormat format = ExportFormat.png,
      int width = 200,
      int height = 320}) async {
    final file = await CollageExporter(outputDirectory: dir).export(
        p, ExportSettings(format: format, width: width, height: height));
    return img.decodeImage(await file.readAsBytes())!;
  }

  test(
      'Shared scene painting exactly matches PNG export for every built-in design',
      () async {
    final p = editorialProject(count: 9, path: source.path);
    final image = await loadProjectImage(source.path, maxEdge: 1024);
    try {
      for (final preset in DesignPreset.all) {
        final designed =
            p.copyWith(design: preset.create(p.photos, (key) => key));
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        const size = Size(200, 320);
        StyleRenderer.background(canvas, size, designed.canvas);
        for (final layer in designed.design.ordered) {
          EditorialRenderer.paintLayer(canvas, size, designed, layer,
              image: layer.isPhoto ? image : null,
              sourceSize: const Size(80, 80));
        }
        final picture = recorder.endRecording();
        final rendered = await picture.toImage(200, 320);
        picture.dispose();
        final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
        rendered.dispose();
        final preview = img.decodePng(bytes!.buffer.asUint8List())!;
        final result = await export(designed);
        expect(result.getBytes(), preview.getBytes(), reason: preset.key);
        if (const bool.fromEnvironment('EDITORIAL_VISUAL_QA')) {
          final out = Directory('build/editorial-qa');
          await out.create(recursive: true);
          await File('${out.path}/${preset.key}.png')
              .writeAsBytes(img.encodePng(result));
        }
      }
    } finally {
      image.dispose();
    }
  });
  test(
      'Torn masks preserve pixels, produce irregular alpha and no cyan editor handles',
      () async {
    const l = DesignLayer(
        id: 'strip',
        type: DesignLayerType.torn,
        width: .8,
        height: .8,
        tearEdges: TearEdges.all,
        tearIntensity: 1,
        roughness: 1,
        shadow: false);
    final p = project([l]);
    final png = await export(p, width: 200, height: 200);
    expect(png.getPixel(50, 100).r, 255);
    expect(png.getPixel(150, 100).b, 255);
    final alphas = [for (var x = 30; x < 170; x++) png.getPixel(x, 24).a];
    expect(alphas.any((a) => a == 0), isTrue);
    expect(alphas.any((a) => a > 0), isTrue);
    expect(png.getPixel(0, 0).a, 0);
    expect(
        png.every((px) => !(px.g > 200 && px.b > 200 && px.r < 100)), isTrue);
    final jpeg =
        await export(p, format: ExportFormat.jpeg, width: 200, height: 200);
    expect(jpeg.getPixel(0, 0).r, greaterThan(245));
    expect(jpeg.getPixel(0, 0).g, greaterThan(245));
  });
  test(
      'Callouts sample their original source crop, border and connector without crop guides',
      () async {
    const main = DesignLayer(
        id: 'main',
        type: DesignLayerType.photo,
        x: .25,
        y: .25,
        width: .4,
        height: .4);
    const detail = DesignLayer(
        id: 'detail',
        type: DesignLayerType.callout,
        x: .75,
        y: .75,
        width: .35,
        height: .35,
        crop: Rect.fromLTWH(.5, 0, .5, 1),
        shape: CalloutShape.circle,
        borderColor: 0xFFFFFFFF,
        borderWidth: 3,
        lineColor: 0xFF00FF00,
        lineWidth: 2,
        endpoint: Offset(.5, 0));
    final p = project([main, detail]);
    final png = await export(p, width: 200, height: 200);
    expect(png.getPixel(150, 150).b, 255);
    expect(png.getPixel(150, 150).r, 0);
    expect(png.getPixel(118, 118).a, 0);
    expect(png.any((px) => px.g > 200 && px.r < 20 && px.b < 20), isTrue);
    expect(png.any((px) => px.r > 240 && px.g > 240 && px.b > 240), isTrue);
    // Cyan is the editor's source-guide color and is never part of the scene.
    expect(png.any((px) => px.g > 200 && px.b > 200 && px.r < 100), isFalse);
    final changed = await export(
        p.copyWith(
            design: p.design.copyWith(layers: [
          main,
          detail.copyWith(crop: const Rect.fromLTWH(0, 0, .5, 1))
        ])),
        width: 200,
        height: 200);
    expect(changed.getPixel(150, 150).r, 255);
    expect(changed.getPixel(150, 150).b, 0);
  });
  test(
      'Opacity, z order, visibility, filters and Fill/ Fit use the same rendering path',
      () async {
    const back = DesignLayer(
        id: 'back',
        type: DesignLayerType.background,
        width: 1,
        height: 1,
        color: 0xFFFFFFFF,
        z: -1);
    const photo = DesignLayer(
        id: 'photo',
        type: DesignLayerType.photo,
        width: .9,
        height: .4,
        z: 1,
        opacity: .5);
    const hidden = DesignLayer(
        id: 'hidden',
        type: DesignLayerType.background,
        width: 1,
        height: 1,
        color: 0xFF00FF00,
        z: 99,
        visible: false);
    var p = project([hidden, photo, back]);
    p = p.copyWith(photos: [
      p.photos.first.copyWith(
          adjustments:
              const PhotoAdjustments(preset: PhotoFilterPreset.blackWhite),
          transform: const PhotoTransform(
              scale: .1,
              offsetX: 99,
              offsetY: 99,
              rotationQuarterTurns: 1,
              flipX: true))
    ]);
    final result = await export(p, width: 200, height: 200);
    final center = result.getPixel(100, 100);
    expect(center.r, center.g);
    expect(center.g, center.b);
    expect(center.r, greaterThan(120));
    final edge = result.getPixel(12, 61);
    expect(edge.r, lessThan(255));
    final fitted = await export(
        p.copyWith(photos: [
          p.photos.first.copyWith(
              transform: const PhotoTransform(fitMode: PhotoFitMode.fit))
        ]),
        width: 200,
        height: 200);
    expect(fitted.getPixel(15, 100).r, 255);
  });
  test('Standalone connectors match preview without saved photo dimensions',
      () async {
    original = img.encodePng(
        img.Image(width: 80, height: 40)..clear(img.ColorRgb8(180, 120, 70)));
    await source.writeAsBytes(original);
    final base = project([]);
    final photo = base.photos.single.copyWith(
        clearMetadata: true,
        transform: const PhotoTransform(fitMode: PhotoFitMode.fit));
    final image = await loadProjectImage(source.path);
    try {
      for (final z in [-1, 1]) {
        final designed = base.copyWith(
            photos: [photo],
            design: base.design.copyWith(layers: [
              const DesignLayer(
                  id: 'main',
                  type: DesignLayerType.photo,
                  x: .3,
                  y: .3,
                  width: .4,
                  height: .4),
              DesignLayer(
                  id: 'line',
                  type: DesignLayerType.connector,
                  x: .8,
                  y: .8,
                  width: .2,
                  height: .2,
                  z: z,
                  crop: const Rect.fromLTWH(.1, .1, .2, .2),
                  lineWidth: 3,
                  lineColor: 0xFF00FF00),
            ]));
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        const size = Size(200, 320);
        StyleRenderer.background(canvas, size, designed.canvas);
        for (final layer in designed.design.ordered) {
          EditorialRenderer.paintLayer(canvas, size, designed, layer,
              image: layer.isPhoto ? image : null,
              sourceSize: const Size(80, 40));
        }
        final picture = recorder.endRecording();
        final rendered = await picture.toImage(200, 320);
        picture.dispose();
        final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
        rendered.dispose();
        final preview = img.decodePng(bytes!.buffer.asUint8List())!;
        expect((await export(designed)).getBytes(), preview.getBytes(),
            reason: 'z=$z');
      }
    } finally {
      image.dispose();
    }
  });
  test(
      'Source mapping follows rotation and flip and geometry scales proportionally',
      () {
    final p = project([]);
    const layer = DesignLayer(
        id: 'main', type: DesignLayerType.photo, width: 1, height: 1);
    final photo = p.photos.first.copyWith(
        transform: const PhotoTransform(rotationQuarterTurns: 1, flipX: true));
    final point = EditorialRenderer.sourcePoint(layer, photo,
        const Size(80, 80), const Size(200, 200), const Offset(0, 0));
    expect(point.dx, closeTo(0, 1e-7));
    expect(point.dy, closeTo(0, 1e-7));
    final large = EditorialRenderer.sourcePoint(layer, photo,
        const Size(80, 80), const Size(400, 400), const Offset(0, 0));
    expect(large, point * 2);
  });
}
