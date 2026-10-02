import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:piclayout/features/collage_editor/models/canvas_settings.dart';
import 'package:piclayout/features/collage_editor/models/canvas_style.dart';
import 'package:piclayout/features/collage_editor/models/style_presets.dart';
import 'package:piclayout/features/collage_editor/models/photo_asset.dart';
import 'package:piclayout/features/collage_editor/rendering/style_renderer.dart';
import 'package:piclayout/features/collage_editor/rendering/layout_geometry.dart';
import 'package:piclayout/features/collage_editor/state/collage_editor_controller.dart';
import 'package:piclayout/features/collage_editor/widgets/style_studio_sheet.dart';
import 'package:piclayout/features/export/collage_exporter.dart';
import 'package:piclayout/features/export/export_settings.dart';
import 'package:piclayout/features/projects/models/collage_project.dart';
import 'package:piclayout/features/projects/services/project_repository.dart';
import 'package:piclayout/features/templates/models/collage_template.dart';

CollageProject project([String path = '/private/photo.png']) => CollageProject(
        id: 'p',
        name: 'Test',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        formatVersion: 1,
        aspectRatioId: '1_1',
        layoutTemplateId: 'grid_1x1_1',
        photos: [
          PhotoAsset(
              id: 'private-id',
              originalFileName: 'private.png',
              localPath: path)
        ]);

class MemoryRepository extends ProjectRepository {
  CollageProject? saved;
  @override
  Future<void> save(CollageProject project) async {
    saved = project;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Legacy projects retain background and default style', () {
    final json = project().toJson();
    json['canvas'] = {'backgroundColor': 0xFF112233, 'spacing': 7};
    final restored = CollageProject.fromJson(json);
    expect(restored.canvas.style.backgroundType, BackgroundType.solid);
    expect(restored.canvas.backgroundColor, 0xFF112233);
    expect(restored.canvas.spacing, 7);
  });
  test(
      'All style settings round trip through project and private-free template',
      () {
    const style = CanvasStyle(
        backgroundType: BackgroundType.blur,
        gradientEndColor: 0xFFFF0000,
        gradientAngle: -25,
        blurPhotoIndex: 5,
        blurSigma: 23,
        brightness: -.4,
        desaturate: true,
        frameEnabled: true,
        frameColor: 0xFF00FF00,
        frameWidth: 7,
        shadowEnabled: true,
        shadowOpacity: .7,
        shadowSoftness: 12);
    final source =
        project().copyWith(canvas: const CanvasSettings(style: style));
    expect(
        CollageProject.fromJson(jsonDecode(jsonEncode(source.toJson())))
            .canvas
            .style
            .toJson(),
        style.toJson());
    final template = CollageTemplate.fromProject(
        id: 't', name: 'Style', project: source, includeTextOverlays: false);
    final encoded = jsonEncode(template.toJson());
    expect(encoded, isNot(contains('private')));
    expect(encoded, isNot(contains('localPath')));
    expect(encoded, isNot(contains('photos')));
    final restored = CollageTemplate.fromJson(jsonDecode(encoded));
    expect(restored.canvas.style.toJson(), style.toJson());
    expect(restored.applyTo(project()).photos.map((p) => p.id), ['private-id']);
  });
  test('Seven presets contain no photos or paths and source index is bounded',
      () {
    expect(StylePreset.all.length, 7);
    for (final preset in StylePreset.all) {
      final json = jsonEncode(preset.settings.toJson());
      expect(json, isNot(contains('localPath')));
      expect(json, isNot(contains('photos')));
    }
    expect(
        StyleRenderer.photoIndex(const CanvasStyle(blurPhotoIndex: 9), 2), 1);
    expect(StyleRenderer.photoIndex(const CanvasStyle(), 0), 0);
  });
  test('Style slider and reset are undoable without changing photo order', () {
    final controller = CollageEditorController(
        initialProject: project(), repository: MemoryRepository());
    addTearDown(controller.dispose);
    controller.beginCanvasEdit();
    controller.updateCanvas(StylePreset.all.last.settings);
    controller
        .updateCanvas(StylePreset.all.last.settings.copyWith(spacing: 20));
    controller.endCanvasEdit();
    controller.undo();
    expect(
        controller.project.canvas.style.backgroundType, BackgroundType.solid);
    controller.redo();
    expect(controller.project.canvas.spacing, 20);
    controller.resetStyle();
    expect(controller.project.canvas.toJson(), const CanvasSettings().toJson());
    expect(controller.project.photos.single.id, 'private-id');
    controller.undo();
    expect(controller.project.canvas.style.backgroundType, BackgroundType.blur);
  });
  test('Shared edges produce one frame and shadow silhouette', () {
    final path = StyleRenderer.cellPath(const [
      ResolvedLayoutCell(
          photoIndex: 0, rect: Rect.fromLTWH(0, 0, 50, 100), cornerRadius: 0),
      ResolvedLayoutCell(
          photoIndex: 1, rect: Rect.fromLTWH(50, 0, 50, 100), cornerRadius: 0)
    ]);
    expect(path.computeMetrics().length, 1);
    expect(path.contains(const Offset(50, 50)), isTrue);
  });
  test('PNG transparency, JPEG white, gradient, blur and framed export pixels',
      () async {
    final dir = await Directory.systemTemp.createTemp('piclayout_style_');
    addTearDown(() => dir.delete(recursive: true));
    final source = File('${dir.path}/source.png');
    final red = img.Image(width: 32, height: 32);
    img.fill(red, color: img.ColorRgb8(255, 0, 0));
    final original = img.encodePng(red);
    await source.writeAsBytes(original);
    final exporter = CollageExporter(outputDirectory: dir);
    Future<img.Image> render(CanvasStyle style,
        {ExportFormat format = ExportFormat.png}) async {
      final file = await exporter.export(
          project(source.path).copyWith(
              canvas: CanvasSettings(
                  outerMargin: 60, backgroundColor: 0xFF0000FF, style: style)),
          ExportSettings(width: 390, height: 390, format: format));
      return img.decodeImage(await file.readAsBytes())!;
    }

    final transparent = await render(
        const CanvasStyle(backgroundType: BackgroundType.transparent));
    expect(transparent.getPixel(0, 0).a, 0);
    expect(transparent.getPixel(195, 195).r, 255);
    final jpeg = await render(
        const CanvasStyle(backgroundType: BackgroundType.transparent),
        format: ExportFormat.jpeg);
    expect(jpeg.getPixel(0, 0).r, greaterThan(245));
    expect(jpeg.getPixel(0, 0).g, greaterThan(245));
    final gradient = await render(const CanvasStyle(
        backgroundType: BackgroundType.gradient,
        gradientEndColor: 0xFF00FF00,
        gradientAngle: 0));
    expect(gradient.getPixel(389, 0).g, greaterThan(gradient.getPixel(0, 0).g));
    final blur = await render(const CanvasStyle(
        backgroundType: BackgroundType.blur, brightness: -.5));
    expect(blur.getPixel(10, 10).r, inInclusiveRange(120, 135));
    expect(blur.getPixel(10, 10).b, lessThan(5));
    final frame = await render(const CanvasStyle(
        frameEnabled: true,
        frameColor: 0xFF00FF00,
        frameWidth: 8,
        shadowEnabled: true));
    expect(frame.getPixel(62, 195).g, greaterThan(240));
    expect(frame.getPixel(195, 195).r, 255);
    for (final type in [
      BackgroundType.paper,
      BackgroundType.grid,
      BackgroundType.dots
    ]) {
      expect((await render(CanvasStyle(backgroundType: type))).width, 390);
    }
    expect(await source.readAsBytes(), original);
  });
  testWidgets(
      'Style sheet fits small screen, applies preset, autosaves and resets',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = MemoryRepository();
    final controller = CollageEditorController(
        initialProject: project(), repository: repository);
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () => showStyleStudio(context, controller),
                    child: const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Presets'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Presets'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clean White'));
    await tester.pump(const Duration(seconds: 1));
    expect(repository.saved?.canvas.outerMargin, 16);
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(controller.project.canvas.outerMargin, 0);
    expect(tester.takeException(), isNull);
  });
}
