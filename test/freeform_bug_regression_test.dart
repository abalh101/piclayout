import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:piclayout/features/collage_editor/models/photo_asset.dart';
import 'package:piclayout/features/collage_editor/rendering/preview_image_cache.dart';
import 'package:piclayout/features/collage_editor/state/collage_editor_controller.dart';
import 'package:piclayout/features/collage_editor/widgets/styled_collage_scene.dart';
import 'package:piclayout/features/editorial/models/editorial_design.dart';
import 'package:piclayout/features/editorial/models/freeform_presets.dart';
import 'package:piclayout/features/editorial/widgets/freeform_tools.dart';
import 'package:piclayout/features/projects/models/collage_project.dart';
import 'package:piclayout/features/projects/services/project_repository.dart';
import 'support/editorial_fixtures.dart';

CollageProject _project() {
  final base = editorialProject(count: 2);
  return base.copyWith(design: FreeformPresets.create('ffCanvas', base.photos));
}

class _DelayedRepository extends EditorialMemoryRepository {
  final result = Completer<PhotoAsset>();
  final discarded = <PhotoAsset>[];
  @override
  Future<PhotoAsset> importReplacement(XFile file, String projectId) =>
      result.future;
  @override
  Future<void> discardImportedPhotos(
      String projectId, Iterable<PhotoAsset> photos) async {
    discarded.addAll(photos);
  }
}

void main() {
  test('Rejected design keeps project and existing redo history intact', () {
    final c = CollageEditorController(
        initialProject: _project(), repository: EditorialMemoryRepository());
    addTearDown(c.dispose);
    c.selectDesignLayer(c.project.design.layers.first.id);
    c.updateDesignLayer(c.selectedDesignLayer!.copyWith(x: .4));
    c.undo();
    final before = c.project.toJson();
    final selection = c.selectedDesignLayerId;
    final invalid = c.project.design.copyWith(layers: [
      for (var i = 0; i < 21; i++)
        c.project.design.layers.first.copyWith(id: 'frame-$i')
    ]);
    expect(() => c.applyDesign(invalid), throwsArgumentError);
    expect(c.project.toJson(), before);
    expect(c.canUndo, isFalse);
    expect(c.canRedo, isTrue);
    expect(c.selectedDesignLayerId, selection);
  });

  test('Aspect lock survives simultaneous width/height edits at size limits',
      () {
    final p = _project();
    final frame = p.design.layers.first
        .copyWith(width: .8, height: .2, aspectLocked: true);
    final c = CollageEditorController(
        initialProject: p.copyWith(design: p.design.copyWith(layers: [frame])),
        repository: EditorialMemoryRepository());
    addTearDown(c.dispose);
    c.updateDesignLayer(frame.copyWith(width: 2.4, height: .6));
    var actual = c.project.design.layers.single;
    expect(actual.width / actual.height, closeTo(4, 1e-9));
    c.updateDesignLayer(actual.copyWith(width: .03, height: .0075));
    actual = c.project.design.layers.single;
    expect(actual.width / actual.height, closeTo(4, 1e-9));
    expect(actual.width, inInclusiveRange(.02, 1.5));
    expect(actual.height, inInclusiveRange(.02, 1.5));
  });

  for (final action in ['switch mode', 'clear photo', 'bind another photo']) {
    test('Pending replacement does not overwrite a later $action', () async {
      final r = _DelayedRepository();
      final c =
          CollageEditorController(initialProject: _project(), repository: r);
      addTearDown(c.dispose);
      c.selectDesignLayer(c.project.design.layers.first.id);
      final replacement = c.project.photos.first.copyWith(id: 'imported');
      final pending = c.fillFreeformFrame(XFile('unused.png'));
      switch (action) {
        case 'switch mode':
          c.applyDesign(c.project.design.copyWith(mode: DesignMode.standard));
        case 'clear photo':
          c.clearFramePhoto();
        case 'bind another photo':
          c.bindFramePhoto(c.project.photos.last.id);
      }
      final before = c.project.toJson();
      r.result.complete(replacement);
      await pending;
      expect(c.project.toJson(), before);
      expect(c.importingPhotos, isFalse);
      expect(r.discarded.map((p) => p.id), ['imported']);
    });
  }

  test(
      'Failed photo batch removes only its fresh copies and preserves originals',
      () async {
    final root = await Directory.systemTemp.createTemp('freeform_import_');
    addTearDown(() => root.delete(recursive: true));
    final bytes = img.encodePng(img.Image(width: 8, height: 8));
    final original = await File('${root.path}/source.png').writeAsBytes(bytes);
    final r = ProjectRepository(documentsDirectory: root);
    final p =
        await r.createFromPickedImages([XFile(original.path)], freeform: true);
    final c = CollageEditorController(initialProject: p, repository: r);
    try {
      await expectLater(
          c.addFreeformPhotos(
              [XFile(original.path), XFile('${root.path}/not-found.png')]),
          throwsA(isA<FileSystemException>()));
      expect(c.project.toJson(), p.toJson());
      expect(c.canUndo, isFalse);
      expect(c.importingPhotos, isFalse);
      final imageDirectory = File(p.photos.single.localPath).parent;
      expect(await imageDirectory.list().length, 1);
      expect(await original.readAsBytes(), bytes);
      expect(await File(p.photos.single.localPath).readAsBytes(), bytes);
      await expectLater(
          r.discardImportedPhotos(
              p.id, [p.photos.single.copyWith(localPath: original.path)]),
          throwsArgumentError);
      expect(await original.readAsBytes(), bytes);
    } finally {
      c.dispose();
      await r.save(c.project);
    }
  });

  for (final dispose in [false, true]) {
    test(
        'Pending batch is discarded after ${dispose ? 'closing' : 'mode change'}',
        () async {
      final repository = _DelayedRepository();
      final controller = CollageEditorController(
          initialProject: _project(), repository: repository);
      if (!dispose) addTearDown(controller.dispose);
      final imported = controller.project.photos.first.copyWith(id: 'fresh');
      final pending = controller.addFreeformPhotos([XFile('unused.png')]);
      if (dispose) {
        controller.dispose();
      } else {
        controller.applyDesign(
            controller.project.design.copyWith(mode: DesignMode.standard));
      }
      final before = controller.project.toJson();
      repository.result.complete(imported);
      await pending;
      expect(controller.project.toJson(), before);
      expect(controller.importingPhotos, isFalse);
      expect(repository.discarded.map((photo) => photo.id), ['fresh']);
    });
  }

  testWidgets(
      'Covered empty frame does not draw its placeholder over front layers',
      (tester) async {
    final p = _project();
    final empty = p.design.layers.first
        .copyWith(empty: true, x: .5, y: .5, width: 1, height: 1);
    const front = DesignLayer(
        id: 'cover',
        type: DesignLayerType.background,
        x: .5,
        y: .5,
        width: 1,
        height: 1,
        z: 100,
        color: 0xFF00FF00);
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
        home: Center(
            child: RepaintBoundary(
                key: key,
                child: SizedBox(
                    width: 100,
                    height: 100,
                    child: StyledCollageScene(
                        project: p.copyWith(
                            design: p.design
                                .copyWith(layers: [empty, front]))))))));
    await tester.pumpAndSettle();
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      try {
        final pixels = (await image.toByteData())!.buffer.asUint8List();
        var mismatches = 0;
        for (var i = 0; i < pixels.length; i += 4) {
          if (pixels[i] != 0 || pixels[i + 1] != 255 || pixels[i + 2] != 0) {
            mismatches++;
          }
        }
        expect(mismatches, 0);
      } finally {
        image.dispose();
      }
    });
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Thumbnail drops released image on clearing or replacing source',
      (tester) async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawColor(Colors.red, BlendMode.src);
    final picture = recorder.endRecording();
    final decoded = await tester.runAsync(() => picture.toImage(8, 8));
    picture.dispose();
    final secondImage = decoded!.clone();
    final next = Completer<ui.Image>();
    final cache = PreviewImageCache(decode: (path, {maxEdge, onSourceSize}) {
      onSourceSize?.call(const Size(8, 8));
      return path == 'first' ? Future.value(decoded) : next.future;
    });
    final first = _project().photos.first.copyWith(localPath: 'first');
    final second = first.copyWith(localPath: 'second');
    Widget thumbnail(PhotoAsset? photo) => MaterialApp(
        home: Scaffold(body: FrameSourceThumbnail(photo: photo, cache: cache)));
    await tester.pumpWidget(thumbnail(first));
    await tester.pumpAndSettle();
    expect(find.byType(RawImage), findsOneWidget);
    await tester.pumpWidget(thumbnail(second));
    expect(tester.takeException(), isNull);
    expect(find.byType(RawImage), findsNothing,
        reason: 'The old source is released while the new decode is pending');
    next.complete(secondImage);
    await tester.pumpAndSettle();
    await tester.pumpWidget(thumbnail(null));
    expect(tester.takeException(), isNull);
    expect(find.byType(RawImage), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(cache.sourceCount, 0);
  });
}
