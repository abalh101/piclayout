import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:piclayout/core/localization/app_localizations.dart';
import 'package:piclayout/features/collage_editor/models/photo_adjustments.dart';
import 'package:piclayout/features/collage_editor/models/photo_transform.dart';
import 'package:piclayout/features/collage_editor/rendering/photo_filter_renderer.dart';
import 'package:piclayout/features/collage_editor/rendering/project_image_loader.dart';
import 'package:piclayout/features/collage_editor/rendering/style_renderer.dart';
import 'package:piclayout/features/collage_editor/state/collage_editor_controller.dart';
import 'package:piclayout/features/collage_editor/widgets/photo_adjustments_studio.dart';
import 'package:piclayout/features/collage_editor/widgets/adjustment_slider.dart';
import 'package:piclayout/features/collage_editor/widgets/styled_collage_scene.dart';
import 'package:piclayout/features/export/collage_exporter.dart';
import 'package:piclayout/features/export/export_settings.dart';
import 'package:piclayout/features/projects/services/project_repository.dart';
import 'package:piclayout/features/templates/models/collage_template.dart';
import 'style_studio_test.dart' as fixture;

const studioEdits = PhotoAdjustments(
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
    vignette: .7);

class CountingRepository extends fixture.MemoryRepository {
  int saves = 0;
  @override
  Future<void> save(project) async {
    saves++;
    await super.save(project);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'All studio values round trip, clamp, ignore future fields and default neutral',
      () {
    expect(
        PhotoAdjustments.fromJson(jsonDecode(jsonEncode(studioEdits.toJson())))
            .toJson(),
        studioEdits.toJson());
    expect(PhotoAdjustments.fromJson({}).hasStudioEffects, isFalse);
    final invalid = PhotoAdjustments.fromJson({
      'tint': double.nan,
      'highlights': -20,
      'shadows': 30,
      'fade': -1,
      'blackPoint': double.infinity,
      'vignette': 2,
      'future': {}
    });
    expect([
      invalid.tint,
      invalid.highlights,
      invalid.shadows,
      invalid.fade,
      invalid.blackPoint,
      invalid.vignette
    ], [
      0,
      -1,
      1,
      0,
      0,
      1
    ]);
  });

  test(
      'One undo per gesture; paste/reset/all preserve transforms and layout; rapid no-ops retain history',
      () async {
    final source = fixture.project();
    final project = source.copyWith(photos: [
      source.photos.single,
      source.photos.single.copyWith(
          id: 'second',
          transform: const PhotoTransform(
              scale: 2, rotationQuarterTurns: 1, flipX: true))
    ]);
    final c = CollageEditorController(
        initialProject: project, repository: fixture.MemoryRepository());
    addTearDown(c.dispose);
    final before = c.project;
    c.beginInteractiveTransform();
    for (var i = 1; i <= 30; i++) {
      c.setAdjustments(
          c.selectedPhoto!.id, studioEdits.copyWith(brightness: i / 100),
          live: true);
    }
    c.endInteractiveTransform();
    c.undo();
    expect(c.project.toJson(), before.toJson());
    expect(c.canUndo, isFalse);
    c.redo();
    final edits = c.selectedPhoto!.adjustments;
    c.copyAdjustments();
    c.selectPhoto('second');
    c.pasteAdjustments();
    expect(c.selectedPhoto!.adjustments.toJson(), edits.toJson());
    c.undo();
    expect(c.selectedPhoto!.adjustments.hasStudioEffects, isFalse);
    c.redo();
    c.resetPhotoAdjustments();
    c.undo();
    expect(c.selectedPhoto!.adjustments.toJson(), edits.toJson());
    c.redo();
    expect(c.selectedPhoto!.adjustments.hasStudioEffects, isFalse);
    c.selectPhoto(before.photos.first.id);
    c.applyAdjustmentsToAll();
    for (var i = 0; i < 20; i++) {
      c.applyAdjustmentsToAll();
    }
    for (var i = 0; i < 2; i++) {
      expect(c.project.photos[i].transform.toJson(),
          before.photos[i].transform.toJson());
      expect(c.project.photos[i].adjustments.toJson(), edits.toJson());
    }
    expect(c.project.layoutTemplateId, before.layoutTemplateId);
    expect(c.project.canvas.toJson(), before.canvas.toJson());
    c.undo();
    expect(c.project.photos.last.adjustments.hasStudioEffects, isFalse);
    c.redo();
    c.applyAdjustmentsToAll(reset: true);
    expect(
        c.project.photos.every((p) => !p.adjustments.hasStudioEffects), isTrue);
    c.undo();
    expect(c.project.photos.last.adjustments.toJson(), edits.toJson());
    await c.saveNow();
  });

  test(
      'Save/reopen/duplicate preserve adjustments and bytes; recovery tolerates interrupted or corrupt primary',
      () async {
    final root = await Directory.systemTemp.createTemp('studio_repository_');
    addTearDown(() => root.delete(recursive: true));
    final bytes = img.encodePng(img.Image(width: 8, height: 8));
    final file = await File('${root.path}/input.png').writeAsBytes(bytes);
    final r = ProjectRepository(documentsDirectory: root);
    final p = await r.createFromPickedImages([XFile(file.path)]);
    final edited = p
        .copyWith(photos: [p.photos.single.copyWith(adjustments: studioEdits)]);
    await r.save(edited);
    expect((await r.loadProjects()).single.photos.single.adjustments.toJson(),
        studioEdits.toJson());
    final copy = await r.duplicate(edited);
    expect(copy.photos.single.adjustments.toJson(), studioEdits.toJson());
    expect(await File(copy.photos.single.localPath).readAsBytes(), bytes);
    await r.save(edited.copyWith(name: 'next'));
    final primary =
        File('${root.path}/piclayout_projects/${p.id}/project.json');
    await primary.writeAsString('{broken');
    var recovered = (await r.loadProjects()).firstWhere((v) => v.id == p.id);
    expect(recovered.photos.single.adjustments.toJson(), studioEdits.toJson());
    await primary.delete();
    recovered = (await r.loadProjects()).firstWhere((v) => v.id == p.id);
    expect(recovered.photos.single.adjustments.filterIntensity, .42);
    await File(recovered.photos.single.localPath).delete();
    await r.save(recovered);
    expect((await r.loadProjects()).firstWhere((v) => v.id == p.id).photos,
        hasLength(1));
    expect(await file.readAsBytes(), bytes);
    // Simulate an unwritable staging destination without depending on OS ACLs.
    await Directory('${primary.path}.tmp').create();
    await expectLater(r.save(recovered.copyWith(name: 'must not replace')),
        throwsA(isA<FileSystemException>()));
    expect((await r.loadProjects()).firstWhere((v) => v.id == p.id).name,
        recovered.name);
  });

  test('Templates store positional photo styles without private sources', () {
    final p = fixture.project();
    final template = CollageTemplate.fromProject(
        id: 't',
        name: 't',
        includeTextOverlays: false,
        project: p.copyWith(
            photos: [p.photos.single.copyWith(adjustments: studioEdits)]));
    final json = jsonEncode(template.toJson());
    expect(json, isNot(contains('/private')));
    expect(json, isNot(contains('localPath')));
    final restored = CollageTemplate.fromJson(jsonDecode(json));
    expect(restored.applyTo(p).photos.single.adjustments.toJson(),
        studioEdits.toJson());
  });

  test(
      'Shared shader PNG/JPEG pixels match preview; caches reuse, invalidate and release',
      () async {
    final root = await Directory.systemTemp.createTemp('studio_pixels_');
    addTearDown(() => root.delete(recursive: true));
    final bitmap = img.Image(width: 64, height: 64);
    for (var y = 0; y < 64; y++) {
      for (var x = 0; x < 64; x++) {
        bitmap.setPixelRgb(x, y, x * 4, y * 4, 100);
      }
    }
    final bytes = img.encodePng(bitmap);
    final source = await File('${root.path}/image.png').writeAsBytes(bytes);
    final image = await loadProjectImage(source.path, maxEdge: 1024);
    addTearDown(() {
      PhotoFilterRenderer.releaseImage(image);
      image.dispose();
    });
    const crop = Rect.fromLTWH(0, 0, 1, 1);
    final shader = PhotoFilterRenderer.studioShader(
        image, studioEdits, const Size(64, 64), crop);
    expect(
        identical(
            shader,
            PhotoFilterRenderer.studioShader(
                image, studioEdits, const Size(64, 64), crop)),
        isTrue);
    expect(
        identical(
            shader,
            PhotoFilterRenderer.studioShader(image,
                studioEdits.copyWith(tint: .2), const Size(64, 64), crop)),
        isFalse);
    PhotoFilterRenderer.studioShader(
        image, studioEdits, const Size(128, 128), crop);
    expect(
        identical(
            shader,
            PhotoFilterRenderer.studioShader(
                image, studioEdits, const Size(64, 64), crop)),
        isTrue,
        reason: 'Other view sizes must not evict an unchanged preview');
    final cropA = PhotoFilterRenderer.studioShader(image, studioEdits,
        const Size(64, 64), const Rect.fromLTWH(.12, .12, .5, .5));
    final cropB = PhotoFilterRenderer.studioShader(image, studioEdits,
        const Size(64, 64), const Rect.fromLTWH(.13, .13, .5, .5));
    expect(identical(cropA, cropB), isFalse,
        reason: 'Nearby editorial crops must not share rounded cache keys');
    final recorder = ui.PictureRecorder();
    StyleRenderer.photo(Canvas(recorder), image,
        const Rect.fromLTWH(0, 0, 64, 64), 0, PhotoTransform.identity,
        adjustments: studioEdits);
    final picture = recorder.endRecording();
    final preview = await picture.toImage(64, 64);
    final data = await preview.toByteData(format: ui.ImageByteFormat.png);
    final expected = img.decodePng(data!.buffer.asUint8List())!;
    picture.dispose();
    preview.dispose();
    final p = fixture.project(source.path);
    final edited = p
        .copyWith(photos: [p.photos.single.copyWith(adjustments: studioEdits)]);
    for (final format in ExportFormat.values) {
      final output = await CollageExporter(outputDirectory: root).export(
          edited,
          ExportSettings(
              width: 64, height: 64, format: format, jpegQuality: 100));
      final decoded = img.decodeImage(await output.readAsBytes())!;
      for (final point in [(12, 12), (32, 32), (48, 48)]) {
        final actual = decoded.getPixel(point.$1, point.$2);
        final want = expected.getPixel(point.$1, point.$2);
        expect(actual.r, closeTo(want.r, format == ExportFormat.png ? 0 : 4));
        expect(actual.g, closeTo(want.g, format == ExportFormat.png ? 0 : 4));
        expect(actual.b, closeTo(want.b, format == ExportFormat.png ? 0 : 4));
      }
    }
    expect(expected.getPixel(32, 32).r, isNot(bitmap.getPixel(32, 32).r));
    expect(await source.readAsBytes(), bytes);
    PhotoFilterRenderer.releaseImage(image);
    expect(PhotoFilterRenderer.cachedSourceCount, 0);
  });

  testWidgets(
      'Live slider saves once; hold/cancel comparison, navigation and reset confirmation',
      (tester) async {
    final r = CountingRepository();
    final p = fixture.project();
    final c = CollageEditorController(
        initialProject: p.copyWith(
            photos: [p.photos.single, p.photos.single.copyWith(id: 'second')]),
        repository: r);
    addTearDown(c.dispose);
    await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate
        ],
        home: Scaffold(body: PhotoAdjustmentsStudio(controller: c))));
    await tester.pumpAndSettle();
    final control = find.byKey(const ValueKey('adjust-brightness'));
    await tester.scrollUntilVisible(control, 200);
    final slider = tester.widget<AdjustmentSlider>(control);
    slider.onStart();
    for (var i = 1; i <= 10; i++) {
      slider.onChanged(i / 20);
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(r.saves, 0);
    expect(c.canUndo, isFalse);
    slider.onEnd();
    await tester.pump(const Duration(milliseconds: 750));
    expect(r.saves, 1);
    expect(c.canUndo, isTrue);
    c.undo();
    expect(c.selectedPhoto!.adjustments.brightness, 0);
    expect(c.canUndo, isFalse);
    c.redo();
    await tester.pump(const Duration(milliseconds: 750));
    final before = jsonEncode(c.project.toJson());
    final saves = r.saves;
    final hold = find.widgetWithText(OutlinedButton, 'Hold for before');
    await tester.scrollUntilVisible(hold, -200);
    final gesture = await tester.startGesture(tester.getCenter(hold));
    await tester.pump();
    expect(
        tester
            .widget<StyledCollageScene>(find.byType(StyledCollageScene))
            .project
            .photos
            .first
            .adjustments
            .brightness,
        0);
    await gesture.cancel();
    await tester.pump();
    expect(
        tester
            .widget<StyledCollageScene>(find.byType(StyledCollageScene))
            .project
            .photos
            .first
            .adjustments
            .brightness,
        .5);
    expect(jsonEncode(c.project.toJson()), before);
    expect(r.saves, saves);
    await tester.scrollUntilVisible(find.byTooltip('Next photo'), -200);
    await tester.tap(find.byTooltip('Next photo'));
    await tester.pump();
    expect(c.selectedPhotoId, 'second');
    await tester.scrollUntilVisible(
        find.text('Reset all photo adjustments'), 300);
    await tester.tap(find.text('Reset all photo adjustments'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(c.project.photos.first.adjustments.brightness, .5);
    await tester.tap(find.text('Reset all photo adjustments'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
    await tester.pumpAndSettle();
    expect(c.project.photos.first.adjustments.brightness, 0);
    c.undo();
    expect(c.project.photos.first.adjustments.brightness, .5);
    await c.saveNow();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Comparison-only sheet dismissal never schedules autosave',
      (tester) async {
    final r = CountingRepository();
    final c = CollageEditorController(
        initialProject: fixture.project(), repository: r);
    addTearDown(c.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () => showPhotoAdjustmentsStudio(context, c),
                    child: const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilterChip));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    expect(r.saves, 0);
    expect(c.canUndo, isFalse);
  });

  for (final size in [const Size(740, 360), const Size(1024, 768)]) {
    testWidgets('Studio landscape/tablet $size retains scrollable controls',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = CollageEditorController(
          initialProject: fixture.project(), repository: CountingRepository());
      addTearDown(c.dispose);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: PhotoAdjustmentsStudio(controller: c))));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
          find.byKey(const ValueKey('adjust-vignette')), 200);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('adjust-vignette')), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final locale in ['de', 'en', 'ar', 'tr', 'fr', 'es']) {
    for (final dark in [false, true]) {
      testWidgets(
          'Studio 320px large type $locale dark=$dark; comparison never saves or mutates',
          (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final r = CountingRepository();
        final p = fixture.project();
        final c = CollageEditorController(
            initialProject: p.copyWith(
                photos: [p.photos.single.copyWith(adjustments: studioEdits)]),
            repository: r);
        addTearDown(c.dispose);
        final before = jsonEncode(c.project.toJson());
        await tester.pumpWidget(MaterialApp(
            locale: Locale(locale),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate
            ],
            theme: dark ? ThemeData.dark() : ThemeData.light(),
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: child!),
            home: Scaffold(body: PhotoAdjustmentsStudio(controller: c))));
        await tester.pumpAndSettle();
        final chip = find.byType(FilterChip);
        await tester.ensureVisible(chip);
        await tester.tap(chip);
        await tester.pumpAndSettle();
        expect(
            tester
                .widget<StyledCollageScene>(find.byType(StyledCollageScene))
                .project
                .photos
                .single
                .adjustments
                .hasStudioEffects,
            isFalse);
        expect(jsonEncode(c.project.toJson()), before);
        expect(r.saves, 0);
        expect(c.canUndo, isFalse);
        await tester.tap(chip);
        await tester.pumpAndSettle();
        expect(
            tester
                .widget<StyledCollageScene>(find.byType(StyledCollageScene))
                .project
                .photos
                .single
                .adjustments
                .toJson(),
            studioEdits.toJson());
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
