import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:piclayout/core/localization/app_localizations.dart';
import 'package:piclayout/features/collage_editor/models/canvas_settings.dart';
import 'package:piclayout/features/collage_editor/models/photo_adjustments.dart';
import 'package:piclayout/features/collage_editor/models/photo_transform.dart';
import 'package:piclayout/features/collage_editor/rendering/photo_filter_renderer.dart';
import 'package:piclayout/features/collage_editor/rendering/project_image_loader.dart';
import 'package:piclayout/features/collage_editor/rendering/style_renderer.dart';
import 'package:piclayout/features/collage_editor/state/collage_editor_controller.dart';
import 'package:piclayout/features/collage_editor/widgets/photo_adjustments_studio.dart';
import 'package:piclayout/features/collage_editor/widgets/styled_collage_scene.dart';
import 'package:piclayout/features/export/collage_exporter.dart';
import 'package:piclayout/features/export/export_settings.dart';
import 'package:piclayout/features/projects/services/project_repository.dart';

const _edits = PhotoAdjustments(
  preset: PhotoFilterPreset.vintage,
  filterIntensity: .42,
  brightness: .05,
  contrast: 1.1,
  saturation: .9,
  warmth: .12,
  tint: -.3,
  highlights: -.4,
  shadows: .35,
  fade: .2,
  blackPoint: .15,
  vignette: .7,
);

Future<Directory> _testDirectory() async =>
    (await getTemporaryDirectory()).createTemp('studio_device_');

Future<File> _source(Directory root, int width, int height) async {
  final bitmap = img.Image(width: width, height: height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      bitmap.setPixelRgb(x, y, x * 255 ~/ width, y * 255 ~/ height, 100);
    }
  }
  return File('${root.path}/source.png').writeAsBytes(img.encodePng(bitmap));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Native shader matches PNG/JPEG with crop, rotation and flip',
      (tester) async {
    final root = await _testDirectory();
    addTearDown(() => root.delete(recursive: true));
    final source = await _source(root, 128, 96);
    final originalBytes = await source.readAsBytes();
    final repository = ProjectRepository(documentsDirectory: root);
    final project = await repository
        .createFromPickedImages([XFile(source.path)], aspectRatioId: '1_1');
    final image = await loadProjectImage(source.path);
    try {
      for (final transform in [
        PhotoTransform.identity,
        const PhotoTransform(scale: 1.4, rotationQuarterTurns: 1, flipX: true),
      ]) {
        final edited = project.copyWith(
            canvas: const CanvasSettings(spacing: 0),
            photos: [
              project.photos.single
                  .copyWith(adjustments: _edits, transform: transform)
            ]);
        final recorder = ui.PictureRecorder();
        StyleRenderer.photo(Canvas(recorder), image,
            const Rect.fromLTWH(0, 0, 128, 128), 0, transform,
            adjustments: _edits);
        final picture = recorder.endRecording();
        final preview = await picture.toImage(128, 128);
        late img.Image expected;
        try {
          final data = await preview.toByteData(format: ui.ImageByteFormat.png);
          expected = img.decodePng(data!.buffer.asUint8List())!;
        } finally {
          preview.dispose();
          picture.dispose();
        }
        // A missing or blank shader must not pass merely because both paths
        // produce the same empty image.
        expect(expected.getPixel(64, 64).a, 255);
        expect(expected.getPixel(64, 64).r, greaterThan(20));
        expect(expected.getPixel(64, 64).r, lessThan(230));
        expect(
            expected.getPixel(20, 20).r, isNot(expected.getPixel(100, 100).r));
        for (final format in ExportFormat.values) {
          final file = await CollageExporter(outputDirectory: root).export(
              edited,
              ExportSettings(
                  width: 128, height: 128, format: format, jpegQuality: 100));
          final actual = img.decodeImage(await file.readAsBytes())!;
          expect((actual.width, actual.height), (128, 128));
          for (final point in [(20, 20), (64, 64), (100, 100)]) {
            final a = actual.getPixel(point.$1, point.$2);
            final e = expected.getPixel(point.$1, point.$2);
            final tolerance = format == ExportFormat.png ? 1 : 5;
            expect(a.r, closeTo(e.r, tolerance));
            expect(a.g, closeTo(e.g, tolerance));
            expect(a.b, closeTo(e.b, tolerance));
          }
        }
      }
      expect(await source.readAsBytes(), originalBytes);
    } finally {
      PhotoFilterRenderer.releaseImage(image);
      image.dispose();
    }
    expect(PhotoFilterRenderer.cachedSourceCount, 0);
  });

  testWidgets('Twelve photos: live edit, compare, undo, reopen and export',
      (tester) async {
    final root = await _testDirectory();
    final source = await _source(root, 1600, 1200);
    final originalBytes = await source.readAsBytes();
    final repository = ProjectRepository(documentsDirectory: root);
    final project = await repository.createFromPickedImages(
        List.generate(12, (_) => XFile(source.path)),
        aspectRatioId: '1_1');
    final controller = CollageEditorController(
        initialProject: project, repository: repository);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      // Drain the controller's final queued save before deleting the fixture.
      await repository.save(controller.project);
      await root.delete(recursive: true);
    });
    final leases = [
      for (final photo in project.photos)
        controller.previewImages.acquire(photo.localPath)
    ];
    try {
      final images = await Future.wait(leases.map((lease) => lease.image));
      expect(images, everyElement(isNotNull));
      for (final image in images) {
        expect((image!.width, image.height), (1024, 768));
      }
      await tester.pumpWidget(MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home:
              Scaffold(body: PhotoAdjustmentsStudio(controller: controller))));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
      expect(controller.previewImages.sourceCount, 12);

      final tint = find.byKey(const ValueKey('adjust-tint'));
      await tester.scrollUntilVisible(tint, 200);
      final slider = find.descendant(of: tint, matching: find.byType(Slider));
      await Scrollable.ensureVisible(tester.element(slider), alignment: .5);
      await tester.pumpAndSettle();
      expect(slider.hitTestable(), findsOneWidget);
      await tester.drag(slider, const Offset(65, 0));
      await tester.pumpAndSettle();
      final edits = controller.selectedPhoto!.adjustments;
      expect(edits.tint.abs(), greaterThan(.05));
      expect(controller.canUndo, isTrue);
      await tester.tap(find.byTooltip('Undo'));
      await tester.pumpAndSettle();
      expect(controller.selectedPhoto!.adjustments.tint, 0);
      expect(controller.canUndo, isFalse);
      await tester.tap(find.byTooltip('Redo'));
      await tester.pumpAndSettle();
      expect(controller.selectedPhoto!.adjustments.tint, edits.tint);

      final compare = find.byType(FilterChip);
      await tester.scrollUntilVisible(compare, -200);
      await tester.tap(compare);
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<StyledCollageScene>(find.byType(StyledCollageScene))
              .project
              .photos
              .first
              .adjustments
              .tint,
          0);
      expect(controller.selectedPhoto!.adjustments.tint, edits.tint);
      await tester.tap(compare);
      await tester.pumpAndSettle();
      controller.applyAdjustmentsToAll();
      await controller.saveNow();
      final reopened = (await repository.loadProjects()).single;
      expect(reopened.photos, hasLength(12));
      for (final photo in reopened.photos) {
        expect(photo.adjustments.toJson(), edits.toJson());
        expect(await File(photo.localPath).readAsBytes(), originalBytes);
      }
      for (final format in ExportFormat.values) {
        final file = await CollageExporter(outputDirectory: root).export(
            reopened, ExportSettings(width: 600, height: 600, format: format));
        final decoded = img.decodeImage(await file.readAsBytes())!;
        expect((decoded.width, decoded.height), (600, 600));
      }
      expect(controller.previewImages.sourceCount, 12);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      for (final lease in leases) {
        lease.release();
      }
    }
    expect(controller.previewImages.sourceCount, 0);
    expect(PhotoFilterRenderer.cachedSourceCount, 0);
  });
}
