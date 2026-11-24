import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:piclayout/core/localization/app_localizations.dart';
import 'package:piclayout/core/localization/freeform_translations.dart';
import 'package:piclayout/features/collage_editor/models/canvas_settings.dart';
import 'package:piclayout/features/collage_editor/models/canvas_style.dart';
import 'package:piclayout/features/collage_editor/models/photo_adjustments.dart';
import 'package:piclayout/features/collage_editor/models/photo_transform.dart';
import 'package:piclayout/features/collage_editor/rendering/photo_crop.dart';
import 'package:piclayout/features/collage_editor/rendering/photo_filter_renderer.dart';
import 'package:piclayout/features/collage_editor/rendering/project_image_loader.dart';
import 'package:piclayout/features/collage_editor/state/collage_editor_controller.dart';
import 'package:piclayout/features/collage_editor/widgets/collage_canvas.dart';
import 'package:piclayout/features/collage_editor/widgets/styled_collage_scene.dart';
import 'package:piclayout/features/editorial/models/editorial_design.dart';
import 'package:piclayout/features/editorial/models/freeform_presets.dart';
import 'package:piclayout/features/editorial/rendering/editorial_renderer.dart';
import 'package:piclayout/features/editorial/rendering/freeform_snapping.dart';
import 'package:piclayout/features/editorial/widgets/design_sheet.dart';
import 'package:piclayout/features/editorial/widgets/freeform_tools.dart';
import 'package:piclayout/features/export/collage_exporter.dart';
import 'package:piclayout/features/export/export_settings.dart';
import 'package:piclayout/features/project_archive/project_archive_service.dart';
import 'package:piclayout/features/projects/models/collage_project.dart';
import 'package:piclayout/features/projects/services/project_repository.dart';
import 'package:piclayout/features/templates/models/collage_template.dart';
import 'support/editorial_fixtures.dart';

CollageProject freeformProject({int count = 3}) {
  final base = editorialProject(count: count);
  return base.copyWith(design: FreeformPresets.create('ffCanvas', base.photos));
}

class _CountingRepository extends EditorialMemoryRepository {
  int saves = 0;
  @override
  Future<void> save(CollageProject project) async {
    saves++;
    await super.save(project);
  }
}

Widget _app(Widget child,
        {String language = 'en', bool dark = false, double text = 1}) =>
    MaterialApp(
      locale: Locale(language),
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
              .copyWith(textScaler: TextScaler.linear(text)),
          child: child!),
      home: Scaffold(body: child),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Legacy projects and editorial sources retain their transform semantics',
      () {
    final base = editorialProject();
    final json = base.toJson()..remove('design');
    final restored = CollageProject.fromJson(json);
    expect(restored.design.mode, DesignMode.standard);
    final l = DesignLayer.tryParse({'id': 'legacy', 'type': 'photo'})!;
    expect(l.imageTransform, isNull);
    expect(l.source(base.photos), base.photos.first);
    expect(l.transformFor(base.photos.first), base.photos.first.transform);
  });

  test(
      'Frame JSON preserves independent crop, appearance and empty slot metadata',
      () {
    final frame = freeformProject().design.layers.first.copyWith(
        imageTransform: const PhotoTransform(
            scale: 2.1,
            offsetX: .2,
            offsetY: -.1,
            rotationQuarterTurns: 3,
            flipX: true,
            fitMode: PhotoFitMode.fit),
        adjustments: const PhotoAdjustments(tint: .4, vignette: .8),
        aspectLocked: true,
        empty: true,
        name: 'Highlight',
        rotation: -13,
        opacity: .7,
        radius: 12,
        borderWidth: 3,
        shadow: true,
        locked: true);
    final restored =
        DesignLayer.tryParse(jsonDecode(jsonEncode(frame.toJson())))!;
    expect(restored.toJson(), frame.toJson());
    expect(restored.source(freeformProject().photos), isNull);
  });

  test('Freeform supports twenty frames while standard grids retain twelve',
      () {
    final base = freeformProject();
    final photos =
        List.generate(20, (i) => base.photos.first.copyWith(id: '$i'));
    final twenty = base.copyWith(
        photos: photos, design: FreeformPresets.create('ffCanvas', photos));
    expect(twenty.normalizedForPhotoCount().photos, hasLength(20));
    expect(
        () => twenty
            .copyWith(design: const EditorialDesign())
            .normalizedForPhotoCount(),
        throwsArgumentError);
    expect(
        () => twenty
            .copyWith(
                design: twenty.design.copyWith(layers: [
              ...twenty.design.layers,
              twenty.design.layers.first.copyWith(id: 'extra')
            ]))
            .normalizedForPhotoCount(),
        throwsArgumentError);
  });

  for (final count in [9, 12, 15]) {
    test(
        'Story Mosaic $count has mixed sizes, highlights and consistent non-overlapping gaps',
        () {
      final frames = FreeformPresets.create('ffStory$count', const []).layers;
      expect(frames, hasLength(count));
      expect(
          frames.every((l) => l.empty && l.source(const []) == null), isTrue);
      expect(frames.map((l) => '${l.width}:${l.height}').toSet().length,
          greaterThan(3));
      final areas = frames.map((l) => l.width * l.height).toList()..sort();
      expect(areas.last / areas.first, greaterThan(2));
      for (final a in frames) {
        final r = a.rect(const Size(1, 1));
        expect(r.left, greaterThan(0));
        expect(r.right, lessThan(1));
        expect(r.top, greaterThan(0));
        expect(r.bottom, lessThan(1));
        for (final b in frames) {
          if (a.id != b.id) {
            expect(r.overlaps(b.rect(const Size(1, 1))), isFalse);
          }
        }
      }
    });
  }

  test(
      'Templates remove private sources and frame names and leave excess slots empty',
      () {
    final base = freeformProject();
    final design = FreeformPresets.create('ffStory9', base.photos);
    final project = base.copyWith(
        design: design.copyWith(layers: [
      for (final l in design.layers) l.copyWith(name: '/private/user-photo.jpg')
    ]));
    final template = CollageTemplate.fromProject(
        id: 'template',
        name: 'Mosaic',
        project: project,
        includeTextOverlays: false);
    final encoded = jsonEncode(template.toJson());
    for (final secret in [
      '/private',
      'localPath',
      'private-photo',
      'originalFileName'
    ]) {
      expect(encoded, isNot(contains(secret)));
    }
    final restored = CollageTemplate.fromJson(jsonDecode(encoded));
    final applied =
        restored.applyTo(base.copyWith(photos: base.photos.reversed.toList()));
    expect(applied.design.layers.first.source(applied.photos)!.id,
        base.photos.last.id);
    expect(applied.design.layers.where((l) => l.source(applied.photos) != null),
        hasLength(3));
    expect(applied.design.layers.where((l) => l.empty), hasLength(6));
    expect(applied.photos, hasLength(3));
    final fewerSlots = CollageTemplate.fromProject(
        id: 'one',
        name: 'One',
        project: base.copyWith(
            design: base.design.copyWith(layers: [base.design.layers.first])),
        includeTextOverlays: false);
    expect(fewerSlots.applyTo(base).photos, hasLength(3));
  });

  test('Frame movement never mutates crop and crop never mutates geometry', () {
    final c = CollageEditorController(
        initialProject: freeformProject(),
        repository: EditorialMemoryRepository());
    addTearDown(c.dispose);
    expect(c.selectedPhoto, isNull,
        reason: 'A freeform photo is editable only through a selected frame');
    c.selectDesignLayer(c.project.design.layers.first.id);
    final original = c.selectedDesignLayer!;
    c.updateDesignLayer(original.copyWith(x: .4, y: .6, rotation: 20));
    expect(c.selectedDesignLayer!.imageTransform!.toJson(),
        original.imageTransform!.toJson());
    final geometry = c.selectedDesignLayer!.rect(const Size(390, 700));
    c.setFrameCrop(const PhotoTransform(scale: 2, offsetX: .1));
    expect(c.selectedDesignLayer!.rect(const Size(390, 700)), geometry);
    expect(c.selectedDesignLayer!.rotation, 20);
    expect(c.project.photos.first.transform.toJson(),
        PhotoTransform.identity.toJson());
    c.undo();
    expect(c.selectedPhoto!.transform.scale, 1);
    c.redo();
    expect(c.selectedPhoto!.transform.scale, 2);
  });

  testWidgets(
      'A live frame or crop gesture saves after completion and undoes once',
      (tester) async {
    final repository = _CountingRepository();
    final c = CollageEditorController(
        initialProject: freeformProject(), repository: repository);
    addTearDown(c.dispose);
    c.selectDesignLayer(c.project.design.layers.first.id);
    final original = c.project.toJson();
    c.beginInteractiveTransform();
    for (var i = 0; i < 25; i++) {
      c.updateDesignLayer(c.selectedDesignLayer!.copyWith(x: .3 + i * .01),
          live: true);
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(repository.saves, 0);
    expect(c.canUndo, isFalse);
    c.endInteractiveTransform();
    await tester.pump(const Duration(milliseconds: 750));
    expect(repository.saves, 1);
    c.undo();
    expect(c.project.toJson(), original);
    expect(c.canUndo, isFalse);
    c.redo();
    final moved = c.project.toJson();
    c.beginInteractiveTransform();
    for (var i = 0; i < 10; i++) {
      c.setFrameCrop(PhotoTransform(scale: 1 + i / 10), live: true);
    }
    c.endInteractiveTransform();
    c.undo();
    expect(c.project.toJson(), moved);
    await tester.pump(const Duration(milliseconds: 750));
  });

  test('Fit/Fill clamp uses frame dimensions with image rotation and flip', () {
    final c = CollageEditorController(
        initialProject: freeformProject(),
        repository: EditorialMemoryRepository());
    addTearDown(c.dispose);
    c.selectDesignLayer(c.project.design.layers.first.id);
    c.setFrameCrop(const PhotoTransform(
        scale: 2,
        offsetX: 99,
        offsetY: -99,
        rotationQuarterTurns: 1,
        flipX: true));
    final frame = c.selectedDesignLayer!;
    final expected = PhotoCrop.clamp(
        const PhotoTransform(
            scale: 2,
            offsetX: 99,
            offsetY: -99,
            rotationQuarterTurns: 1,
            flipX: true),
        const Size(100, 100),
        frame.rect(const Size(390, 390 * 16 / 9)).size);
    expect(frame.imageTransform!.toJson(), expected.toJson());
    c.setSelectedFitMode(PhotoFitMode.fit);
    expect(c.selectedPhoto!.transform.fitMode, PhotoFitMode.fit);
    c.setDesignCropEditing(true);
    c.clearFramePhoto();
    expect(c.editingDesignCrop, isFalse);
  });

  test(
      'Duplicate edits independently; order, lock, swap, clear and deletion are undoable',
      () {
    final c = CollageEditorController(
        initialProject: freeformProject(),
        repository: EditorialMemoryRepository());
    addTearDown(c.dispose);
    final firstId = c.project.design.layers.first.id;
    c.selectDesignLayer(firstId);
    c.duplicateDesignLayer();
    final duplicate = c.selectedDesignLayer!;
    expect(duplicate.photoId, c.project.design.layers.first.photoId);
    c.setAdjustments(c.selectedPhoto!.id, const PhotoAdjustments(tint: .6));
    c.setFrameCrop(const PhotoTransform(scale: 2));
    expect(c.project.design.layers.first.adjustments!.tint, 0);
    expect(c.project.design.layers.first.imageTransform!.scale, 1);
    c.moveLayerTo(0);
    expect(c.project.design.ordered.first.id, duplicate.id);
    c.updateDesignLayer(c.selectedDesignLayer!.copyWith(locked: true));
    final locked = c.project.toJson();
    c.setFrameCrop(const PhotoTransform(scale: 4));
    c.deleteDesignLayer();
    c.moveLayerTo(3);
    c.setAdjustments(c.selectedPhoto!.id, const PhotoAdjustments(tint: -.8));
    expect(c.project.toJson(), locked);
    c.updateDesignLayer(c.selectedDesignLayer!.copyWith(locked: false));
    final other = c.project.design.layers
        .where((l) => l.photoId != duplicate.photoId)
        .first;
    final oldPhoto = c.selectedDesignLayer!.photoId;
    final geometry = c.selectedDesignLayer!.rect(const Size(1, 1));
    c.swapFramePhotos(other.id);
    expect(c.selectedDesignLayer!.photoId, other.photoId);
    expect(c.project.design.layers.firstWhere((l) => l.id == other.id).photoId,
        oldPhoto);
    expect(c.selectedDesignLayer!.rect(const Size(1, 1)), geometry);
    c.clearFramePhoto();
    expect(c.selectedDesignLayer!.source(c.project.photos), isNull);
    c.undo();
    expect(c.selectedDesignLayer!.source(c.project.photos), isNotNull);
    c.deleteDesignLayer();
    expect(c.project.design.layers, hasLength(3));
    c.undo();
    expect(c.project.design.layers, hasLength(4));
  });

  test(
      'Aspect-locked dimension edits preserve ratio; empty frames do not enter crop mode',
      () {
    final c = CollageEditorController(
        initialProject: freeformProject(),
        repository: EditorialMemoryRepository());
    addTearDown(c.dispose);
    c.selectDesignLayer(c.project.design.layers.first.id);
    c.updateDesignLayer(c.selectedDesignLayer!.copyWith(aspectLocked: true));
    final ratio = c.selectedDesignLayer!.width / c.selectedDesignLayer!.height;
    c.updateDesignLayer(c.selectedDesignLayer!.copyWith(width: .7));
    expect(c.selectedDesignLayer!.width / c.selectedDesignLayer!.height,
        closeTo(ratio, 1e-8));
    c.clearFramePhoto();
    c.setDesignCropEditing(true);
    expect(c.editingDesignCrop, isFalse);
  });

  test('Snapping aligns canvas center, edges, neighbors and story safe areas',
      () {
    const size = Size(400, 800);
    final frame = freeformProject()
        .design
        .layers
        .first
        .copyWith(width: .2, height: .2, x: .505, y: .18);
    var result = FreeformSnapping.move(frame, [], size);
    expect(result.layer.x, .5);
    expect(result.guides, isNotEmpty);
    result = FreeformSnapping.move(frame.copyWith(x: .105, y: .181), [], size);
    expect(result.layer.x, closeTo(.1, 1e-9));
    expect(result.layer.y, closeTo(.18, 1e-9));
    final neighbor = frame.copyWith(id: 'neighbor', x: .7);
    result = FreeformSnapping.move(frame.copyWith(x: .491), [neighbor], size);
    expect(result.layer.x, closeTo(.5, 1e-9));
  });

  test('Moving one frame invalidates only that frame painter', () {
    final p = freeformProject();
    final moved = p.copyWith(
        design: p.design.copyWith(layers: [
      p.design.layers.first.copyWith(x: .6),
      ...p.design.layers.skip(1)
    ]));
    expect(
        FreeformLayerPainter(moved, moved.design.layers[1], null, null)
            .shouldRepaint(
                FreeformLayerPainter(p, p.design.layers[1], null, null)),
        isFalse);
    expect(
        FreeformLayerPainter(moved, moved.design.layers.first, null, null)
            .shouldRepaint(
                FreeformLayerPainter(p, p.design.layers.first, null, null)),
        isTrue);
  });

  test(
      'Save, reopen, duplicate, replace and archive preserve frames and original bytes',
      () async {
    final root = await Directory.systemTemp.createTemp('freeform_io_');
    addTearDown(() => root.delete(recursive: true));
    final bitmap = img.Image(width: 24, height: 32);
    img.fill(bitmap, color: img.ColorRgb8(80, 130, 190));
    final bytes = img.encodePng(bitmap);
    final file = await File('${root.path}/input.png').writeAsBytes(bytes);
    final repository = ProjectRepository(documentsDirectory: root);
    var p = await repository.createFromPickedImages(
        [XFile(file.path), XFile(file.path)],
        freeform: true);
    p = p.copyWith(design: FreeformPresets.create('ffStory9', p.photos));
    final c =
        CollageEditorController(initialProject: p, repository: repository);
    try {
      c.selectDesignLayer(p.design.layers.first.id);
      c.setFrameCrop(const PhotoTransform(scale: 1.7, offsetX: .1));
      c.setAdjustments(
          c.selectedPhoto!.id, const PhotoAdjustments(tint: -.2, shadows: .3));
      c.duplicateDesignLayer();
      final originalId = p.photos.first.id;
      await c.fillFreeformFrame(XFile(file.path));
      expect(c.project.design.layers.first.photoId, originalId);
      expect(c.selectedDesignLayer!.photoId, isNot(originalId));
      await c.saveNow();
      final reopened = (await repository.loadProjects()).single;
      expect(reopened.design.toJson(), c.project.design.toJson());
      final copy = await repository.duplicate(reopened);
      expect(copy.design.layers.length, reopened.design.layers.length);
      expect(copy.design.layers.first.photoId,
          isNot(reopened.design.layers.first.photoId));
      final archive = ProjectArchiveService(
          documentsDirectory: root, temporaryDirectory: root);
      final zipped = await archive.exportProject(reopened);
      final imported = await archive.importProject(zipped);
      expect(imported.isFreeform, isTrue);
      expect(imported.design.layers.where((l) => l.empty), hasLength(7));
      expect(imported.design.layers.first.imageTransform!.scale, 1.7);
      expect(imported.design.layers.first.adjustments!.tint, -.2);
      for (final photo in reopened.photos) {
        expect(await File(photo.localPath).readAsBytes(), bytes);
      }
      expect(await file.readAsBytes(), bytes);
    } finally {
      c.dispose();
      await repository.save(c.project);
    }
  });

  test('Empty freeform canvas saves and transfers as an editable archive',
      () async {
    final root = await Directory.systemTemp.createTemp('freeform_empty_');
    addTearDown(() => root.delete(recursive: true));
    final r = ProjectRepository(documentsDirectory: root);
    final p = await r.createFromPickedImages([], freeform: true);
    final a = ProjectArchiveService(
        documentsDirectory: root, temporaryDirectory: root);
    final restored = await a.importProject(await a.exportProject(p));
    expect(restored.isFreeform, isTrue);
    expect(restored.photos, isEmpty);
  });

  test(
      'Native frame renderer and export share clips, transforms, effects and missing placeholders',
      () async {
    final root = await Directory.systemTemp.createTemp('freeform_pixels_');
    addTearDown(() => root.delete(recursive: true));
    final bitmap = img.Image(width: 64, height: 96);
    for (var y = 0; y < 96; y++) {
      for (var x = 0; x < 64; x++) {
        bitmap.setPixelRgb(x, y, x * 3, y * 2, 120);
      }
    }
    final file = await File('${root.path}/source.png')
        .writeAsBytes(img.encodePng(bitmap));
    final r = ProjectRepository(documentsDirectory: root);
    final base =
        await r.createFromPickedImages([XFile(file.path)], freeform: true);
    final frame = base.design.layers.first.copyWith(
        width: .8,
        height: .7,
        x: .3,
        rotation: 19,
        radius: 18,
        borderWidth: 4,
        borderColor: 0xFF30A080,
        shadow: true,
        opacity: .8,
        imageTransform: const PhotoTransform(
            scale: 1.6, rotationQuarterTurns: 1, flipX: true),
        adjustments: const PhotoAdjustments(
            preset: PhotoFilterPreset.vintage, tint: .4, vignette: .6));
    final p = base.copyWith(
        canvas: const CanvasSettings(backgroundColor: 0),
        design: base.design.copyWith(layers: [frame]));
    final image = await loadProjectImage(file.path);
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawColor(const Color(0x00000000), BlendMode.src);
      EditorialRenderer.paintLayer(canvas, const Size(180, 320), p, frame,
          image: image);
      final picture = recorder.endRecording();
      final rendered = await picture.toImage(180, 320);
      final expected =
          (await rendered.toByteData(format: ui.ImageByteFormat.png))!
              .buffer
              .asUint8List();
      rendered.dispose();
      picture.dispose();
      final output = await CollageExporter(outputDirectory: root).export(
          p,
          const ExportSettings(
              width: 180, height: 320, format: ExportFormat.png));
      final actual = img.decodePng(await output.readAsBytes())!;
      final want = img.decodePng(expected)!;
      for (final point in [(30, 100), (70, 160), (100, 200)]) {
        expect(actual.getPixel(point.$1, point.$2).toList(),
            want.getPixel(point.$1, point.$2).toList());
      }
      final c = CollageEditorController(
          initialProject: p, repository: EditorialMemoryRepository());
      c.selectDesignLayer(frame.id);
      c.setDesignCropEditing(true);
      final selectedOutput = await CollageExporter(outputDirectory: root)
          .export(
              c.project,
              const ExportSettings(
                  width: 180, height: 320, format: ExportFormat.png));
      expect(await selectedOutput.readAsBytes(), await output.readAsBytes(),
          reason: 'Selection and crop guides never enter exports');
      c.dispose();
      await File(p.photos.first.localPath).delete();
      final placeholder = await CollageExporter(outputDirectory: root).export(
          p.copyWith(
              canvas: p.canvas.copyWith(
                  style:
                      const CanvasStyle(backgroundType: BackgroundType.blur))),
          const ExportSettings(
              width: 180, height: 320, format: ExportFormat.png));
      expect(img.decodePng(await placeholder.readAsBytes()), isNotNull);
    } finally {
      PhotoFilterRenderer.releaseImage(image);
      image.dispose();
    }
  });

  testWidgets(
      'Touch frame drag, crop drag, double tap and deselection preserve gesture separation',
      (tester) async {
    final p = freeformProject(count: 1);
    final frame = p.design.layers.single.copyWith(width: .5, height: .5);
    final c = CollageEditorController(
        initialProject: p.copyWith(design: p.design.copyWith(layers: [frame])),
        repository: EditorialMemoryRepository());
    addTearDown(c.dispose);
    await tester.pumpWidget(_app(Center(
        child: SizedBox(
            width: 360, height: 640, child: CollageCanvas(controller: c)))));
    await tester.pumpAndSettle();
    final canvas = find.byType(CollageCanvas);
    final center = tester.getCenter(canvas);
    await tester.dragFrom(center, const Offset(30, 20));
    await tester.pumpAndSettle();
    expect(c.project.design.layers.single.x, greaterThan(frame.x));
    expect(c.project.design.layers.single.imageTransform!.scale, 1);
    c.undo();
    expect(c.project.design.layers.single.x, frame.x);
    expect(c.canUndo, isFalse);
    c.selectDesignLayer(frame.id);
    c.setFrameCrop(const PhotoTransform(scale: 2));
    c.setDesignCropEditing(true);
    await tester.pump();
    final before = c.selectedDesignLayer!.rect(const Size(360, 640));
    await tester.dragFrom(center, const Offset(50, 30));
    await tester.pumpAndSettle();
    expect(c.selectedDesignLayer!.rect(const Size(360, 640)), before);
    expect(c.selectedPhoto!.transform.offsetX, isNot(0));
    c.setDesignCropEditing(false);
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tapAt(center);
    await tester.pumpAndSettle();
    expect(c.editingDesignCrop, isTrue);
    await tester.tapAt(tester.getTopLeft(canvas) + const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(c.selectedDesignLayerId, isNull);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Pinch resizes frames and zooms crops as separate undo steps',
      (tester) async {
    final p = freeformProject(count: 1);
    final frame = p.design.layers.single.copyWith(width: .6, height: .6);
    final c = CollageEditorController(
        initialProject: p.copyWith(design: p.design.copyWith(layers: [frame])),
        repository: EditorialMemoryRepository());
    addTearDown(c.dispose);
    await tester.pumpWidget(_app(Center(
        child: SizedBox(
            width: 360, height: 640, child: CollageCanvas(controller: c)))));
    await tester.pumpAndSettle();
    final center = tester.getCenter(find.byType(CollageCanvas));
    Future<void> pinch() async {
      final left =
          await tester.startGesture(center - const Offset(40, 0), pointer: 1);
      final right =
          await tester.startGesture(center + const Offset(40, 0), pointer: 2);
      await tester.pump();
      for (var i = 1; i <= 4; i++) {
        await left.moveTo(center - Offset(40 + i * 10, 0));
        await right.moveTo(center + Offset(40 + i * 10, 0));
        await tester.pump();
      }
      await left.up();
      await right.up();
      await tester.pump();
    }

    await pinch();
    expect(c.selectedDesignLayer!.width, greaterThan(frame.width));
    expect(c.selectedPhoto!.transform.scale, 1);
    c.undo();
    expect(c.canUndo, isFalse);
    expect(c.selectedDesignLayer!.width, frame.width);
    c.setDesignCropEditing(true);
    await tester.pump();
    await pinch();
    expect(c.selectedPhoto!.transform.scale, greaterThan(1));
    expect(c.selectedDesignLayer!.rect(const Size(360, 640)),
        frame.rect(const Size(360, 640)));
    c.undo();
    expect(c.canUndo, isFalse);
    c.updateDesignLayer(c.selectedDesignLayer!.copyWith(locked: true));
    await tester.pump();
    final locked = c.project.toJson();
    await tester.dragFrom(center, const Offset(70, 45));
    await pinch();
    expect(c.project.toJson(), locked);
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Photo mapping fits Arabic landscape with large type',
      (tester) async {
    tester.view.physicalSize = const Size(640, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = CollageEditorController(
        initialProject: freeformProject(),
        repository: EditorialMemoryRepository());
    addTearDown(c.dispose);
    await tester.pumpWidget(_app(
        Builder(
            builder: (context) => TextButton(
                onPressed: () => orderFreeformPhotos(context, c),
                child: const Text('Open'))),
        language: 'ar',
        text: 2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(ReorderableListView), findsOneWidget);
    expect(Directionality.of(tester.element(find.byType(AlertDialog))),
        TextDirection.rtl);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final language in ['de', 'en', 'ar', 'tr', 'fr', 'es']) {
    testWidgets('Freeform layers at 320px, large type, dark mode: $language',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = CollageEditorController(
          initialProject: freeformProject(),
          repository: EditorialMemoryRepository());
      addTearDown(c.dispose);
      c.selectDesignLayer(c.project.design.layers.first.id);
      await tester.pumpWidget(_app(DesignSheet(controller: c, initialTab: 2),
          language: language, dark: true, text: 2));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.byType(ReorderableListView), 150,
          scrollable: find
              .descendant(
                  of: find.byType(ListView).last,
                  matching: find.byType(Scrollable))
              .first);
      expect(find.byType(ReorderableListView), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  test('Every freeform string covers all six supported languages', () {
    for (final values in freeformTranslations.values) {
      expect(values, hasLength(6));
      expect(values.every((v) => v.trim().isNotEmpty), isTrue);
    }
  });
}
