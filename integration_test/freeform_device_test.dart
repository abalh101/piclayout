import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:piclayout/core/localization/app_localizations.dart';
import 'package:piclayout/features/collage_editor/models/photo_adjustments.dart';
import 'package:piclayout/features/collage_editor/models/photo_transform.dart';
import 'package:piclayout/features/collage_editor/rendering/photo_filter_renderer.dart';
import 'package:piclayout/features/collage_editor/state/collage_editor_controller.dart';
import 'package:piclayout/features/collage_editor/widgets/collage_canvas.dart';
import 'package:piclayout/features/export/collage_exporter.dart';
import 'package:piclayout/features/export/export_settings.dart';
import 'package:piclayout/features/projects/services/project_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Twenty high resolution frames: preview, edits, release and export',
      (tester) async {
    final root =
        await (await getTemporaryDirectory()).createTemp('freeform_device_');
    final bitmap = img.Image(width: 2400, height: 1800);
    for (var y = 0; y < bitmap.height; y++) {
      for (var x = 0; x < bitmap.width; x++) {
        bitmap.setPixelRgb(
            x, y, x * 255 ~/ bitmap.width, y * 255 ~/ bitmap.height, 100);
      }
    }
    final original = img.encodeJpg(bitmap);
    final source = await File('${root.path}/source.jpg').writeAsBytes(original);
    final repository = ProjectRepository(documentsDirectory: root);
    final project = await repository.createFromPickedImages(
        List.generate(20, (_) => XFile(source.path)),
        freeform: true);
    final controller = CollageEditorController(
        initialProject: project, repository: repository);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      await repository.save(controller.project);
      await root.delete(recursive: true);
    });
    final rssBefore = ProcessInfo.currentRss;
    final leases = [
      for (final photo in project.photos)
        controller.previewImages.acquire(photo.localPath)
    ];
    try {
      final images = await Future.wait(leases.map((l) => l.image));
      expect(images, everyElement(isNotNull));
      var decodedBytes = 0;
      for (final image in images) {
        expect((image!.width, image.height), (1024, 768));
        decodedBytes += image.width * image.height * 4;
      }
      expect(decodedBytes, 20 * 1024 * 768 * 4);
      await tester.pumpWidget(MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
              body: Center(child: CollageCanvas(controller: controller)))));
      await tester.pumpAndSettle();
      expect(controller.previewImages.sourceCount, 20);
      for (final lease in leases) {
        lease.release();
      }
      controller.selectDesignLayer(project.design.layers.first.id);
      controller.beginInteractiveTransform();
      for (var i = 0; i < 30; i++) {
        controller.updateDesignLayer(
            controller.selectedDesignLayer!.copyWith(x: .2 + i * .005),
            live: true);
        await tester.pump(const Duration(milliseconds: 16));
      }
      controller.endInteractiveTransform();
      expect(controller.canUndo, isTrue);
      controller.undo();
      expect(controller.canUndo, isFalse);
      controller.redo();
      controller.setFrameCrop(const PhotoTransform(scale: 1.6, flipX: true));
      controller.setAdjustments(controller.selectedPhoto!.id,
          const PhotoAdjustments(tint: .25, vignette: .4));
      controller.deleteDesignLayer();
      await tester.pumpAndSettle();
      expect(controller.previewImages.sourceCount, 19);
      controller.undo();
      await tester.pumpAndSettle();
      // Wait explicitly for native decoding after restoring the deleted frame.
      final restoredLease = controller.previewImages
          .acquire(controller.project.photos.first.localPath);
      expect(await restoredLease.image, isNotNull);
      restoredLease.release();
      await tester.pumpAndSettle();
      expect(controller.previewImages.sourceCount, 20);
      await controller.saveNow();
      final reopened = (await repository.loadProjects()).single;
      expect(reopened.design.toJson(), controller.project.design.toJson());
      for (final format in ExportFormat.values) {
        final file = await CollageExporter(outputDirectory: root).export(
            reopened,
            ExportSettings(width: 1080, height: 1920, format: format));
        final output = img.decodeImage(await file.readAsBytes())!;
        expect((output.width, output.height), (1080, 1920));
        // The center of an untouched gallery frame contains the source gradient.
        final frame = reopened.design.layers.last;
        final pixel =
            output.getPixel((frame.x * 1080).round(), (frame.y * 1920).round());
        expect(pixel.r, closeTo(127, 12));
        expect(pixel.g, closeTo(127, 12));
        expect(pixel.b, closeTo(100, 12));
      }
      for (final photo in reopened.photos) {
        expect(await File(photo.localPath).readAsBytes(), original);
      }
      expect(await source.readAsBytes(), original);
      debugPrint('Freeform memory: decoded=$decodedBytes bytes, '
          'RSS before=$rssBefore, current=${ProcessInfo.currentRss}, '
          'peak=${ProcessInfo.maxRss}');
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
