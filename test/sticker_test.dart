import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:piclayout/core/localization/translations.dart';
import 'package:piclayout/features/collage_editor/models/canvas_settings.dart';
import 'package:piclayout/features/collage_editor/models/canvas_style.dart';
import 'package:piclayout/features/collage_editor/models/photo_adjustments.dart';
import 'package:piclayout/features/collage_editor/models/text_overlay.dart';
import 'package:piclayout/features/collage_editor/state/collage_editor_controller.dart';
import 'package:piclayout/features/export/collage_exporter.dart';
import 'package:piclayout/features/export/export_settings.dart';
import 'package:piclayout/features/export/models/social_share_preset.dart';
import 'package:piclayout/features/export/services/export_flow_controller.dart';
import 'package:piclayout/features/export/services/gallery_save_service.dart';
import 'package:piclayout/features/export/services/social_share_service.dart';
import 'package:piclayout/features/projects/models/collage_project.dart';
import 'package:piclayout/features/projects/services/project_repository.dart';
import 'package:piclayout/features/stickers/sticker_overlay.dart';
import 'package:piclayout/features/stickers/sticker_renderer.dart';
import 'package:piclayout/features/templates/models/collage_template.dart';
import 'support/custom_layout_fixtures.dart';

StickerDefinition definition(String content) =>
    StickerCatalog.items.firstWhere((s) => s.content == content);

class _Gallery implements GalleryPlatform {
  String? path;
  @override
  Future<void> save(String path) async {
    this.path = path;
  }
}

class _Share implements SocialSharePlatform {
  String? path;
  @override
  Future<bool?> isInstalled(String app) async => true;
  @override
  Future<bool> shareDirect(String app, String path) async {
    this.path = path;
    return true;
  }

  @override
  Future<void> shareSheet(String path, Rect origin) async {
    this.path = path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'Catalogue and full sticker style round trip, invalid data and legacy projects',
      () {
    for (final item in StickerCatalog.items) {
      final sticker = item.create('stable').copyWith(
          x: .2,
          y: .8,
          scale: 1.7,
          rotation: -45,
          color: 0xFF00FF00,
          backgroundColor: 0xFF000000,
          opacity: .4);
      expect(
          StickerOverlay.tryParse(jsonDecode(jsonEncode(sticker.toJson())))!
              .toJson(),
          sticker.toJson());
      expect(jsonEncode(sticker.toJson()), isNot(contains('localPath')));
    }
    final json = layoutProject().toJson()..remove('stickers');
    expect(CollageProject.fromJson(json).stickers, isEmpty);
    json['stickers'] = [
      {'type': 'image', 'content': '/private/photo.png'},
      null
    ];
    expect(CollageProject.fromJson(json).stickers, isEmpty);
    final sticker = definition('circle').create('a');
    expect(
        StickerOverlay.tryParse(
            {...sticker.toJson(), 'content': '/private/photo.png'}),
        isNull);
    final safe = StickerOverlay.tryParse(
        {...sticker.toJson(), 'x': double.nan, 'scale': 90, 'opacity': -1})!;
    expect([safe.x, safe.scale, safe.opacity], [.5, 4, 0]);
    expect(StickerOverlay.parseList([sticker.toJson(), sticker.toJson()]),
        hasLength(1));
    final emptyLabel = definition('place').create('label', label: '');
    expect(StickerOverlay.tryParse(emptyLabel.toJson()), isNotNull);
  });
  test(
      'Add/edit/gesture/duplicate/order/delete participate in undo redo and persistence',
      () async {
    final repository = LayoutMemoryProjects();
    final initial = layoutProject();
    final controller = CollageEditorController(
        initialProject: initial, repository: repository);
    addTearDown(controller.dispose);
    final first = controller.addSticker(definition('circle'));
    controller.undo();
    expect(controller.project.stickers, isEmpty);
    controller.redo();
    expect(controller.project.stickers.single.id, first.id);
    controller.selectSticker(first.id);
    controller.beginInteractiveTransform();
    controller.updateSticker(first.copyWith(x: .3, scale: 2), live: true);
    final changed = first.copyWith(
        x: .25,
        y: .7,
        scale: 2.5,
        rotation: 90,
        color: 0xFF00FF00,
        opacity: .6);
    controller.updateSticker(changed, live: true);
    controller.endInteractiveTransform();
    controller.undo();
    expect(controller.project.stickers.single.toJson(), first.toJson());
    controller.redo();
    expect(controller.project.stickers.single.toJson(), changed.toJson());
    controller.duplicateSticker();
    final duplicate = controller.selectedSticker!;
    expect(duplicate.id, isNot(first.id));
    controller.reorderSticker(front: false);
    expect(controller.project.stickers.first.id, duplicate.id);
    controller.undo();
    expect(controller.project.stickers.last.id, duplicate.id);
    controller.redo();
    expect(controller.project.stickers.first.id, duplicate.id);
    controller.reorderSticker(front: true);
    expect(controller.project.stickers.last.id, duplicate.id);
    controller.removeSticker();
    expect(controller.project.stickers, hasLength(1));
    controller.undo();
    expect(controller.project.stickers, hasLength(2));
    controller.redo();
    expect(controller.project.stickers, hasLength(1));
    await controller.saveNow();
    expect(repository.saved!.stickers.single.toJson(), changed.toJson());
    expect(controller.project.photos, initial.photos);
    controller.selectSticker(first.id);
    controller.selectPhoto(initial.photos.first.id);
    expect(controller.selectedSticker, isNull);
    controller.selectSticker(first.id);
    controller.addText('Text');
    expect(controller.selectedSticker, isNull);
  });
  test(
      'Templates include stickers only by opt-in; copies have new IDs and no photo paths',
      () {
    final source =
        layoutProject().copyWith(stickers: [definition('star').create('star')]);
    for (final include in [false, true]) {
      final template = CollageTemplate.fromProject(
          id: 'template',
          name: 'Design',
          project: source,
          includeTextOverlays: false,
          includeStickers: include);
      final encoded = jsonEncode(template.toJson());
      expect(encoded, isNot(contains('/private')));
      expect(encoded, isNot(contains('localPath')));
      final loaded = CollageTemplate.fromJson(jsonDecode(encoded));
      expect(loaded.stickers.length, include ? 1 : 0);
      final target = layoutProject()
          .copyWith(stickers: [definition('circle').create('existing')]);
      final applied = loaded.applyTo(target);
      expect(applied.stickers.single.content, include ? 'star' : 'circle');
      expect(applied.stickers.single.id, include ? isNot('star') : 'existing');
    }
  });
  test(
      'Sticker bounds scale with canvas; all UI and catalogue keys cover six languages',
      () {
    final sticker =
        definition('rectangle').create('s').copyWith(x: .25, y: .75, scale: 2);
    final a = StickerRenderer.bounds(sticker, const Size(390, 780));
    final b = StickerRenderer.bounds(sticker, const Size(780, 1560));
    expect(b.center, a.center * 2);
    expect(b.size, a.size * 2);
    final keys = {
      'stickers',
      'includeStickers',
      'stEdit',
      'stSize',
      'stRotation',
      'stOpacity',
      'stColor',
      'stBackground',
      'stNoBackground',
      'stEmojiColor',
      'stDuplicate',
      'stFront',
      'stBack',
      'stHint',
      'stOnCanvas',
      'stLabelText',
      for (final item in StickerCatalog.items) item.labelKey,
      for (final category in StickerCategory.values)
        'stCategory_${category.name}',
      for (var i = 0; i < 7; i++) 'stColor$i',
    };
    for (final key in keys) {
      expect(translations[key], hasLength(6), reason: key);
      expect(translations[key]!.every((s) => s.isNotEmpty), isTrue,
          reason: key);
    }
  });
  test(
      'PNG/JPEG composite sticker z-order/opacity with photo filters, frame, background and text; gallery/social use same file',
      () async {
    final dir = await Directory.systemTemp.createTemp('sticker_export_');
    addTearDown(() => dir.delete(recursive: true));
    final bitmap = img.Image(width: 16, height: 16);
    img.fill(bitmap, color: img.ColorRgb8(100, 100, 100));
    final bytes = img.encodePng(bitmap);
    final photo = await File('${dir.path}/original.png').writeAsBytes(bytes);
    final base = layoutProject(count: 1, paths: [photo.path]);
    final project = base.copyWith(
      photos: [
        base.photos.single.copyWith(
            adjustments:
                const PhotoAdjustments(preset: PhotoFilterPreset.blackWhite))
      ],
      canvas: const CanvasSettings(
          outerMargin: 20,
          backgroundColor: 0xFFFFFF00,
          style: CanvasStyle(
              frameEnabled: true, frameColor: 0xFF00FF00, frameWidth: 5)),
      textOverlays: const [TextOverlay(id: 't', text: 'Hello', x: .5, y: .2)],
      stickers: [
        definition('rectangle')
            .create('red')
            .copyWith(color: 0xFFFF0000, scale: 2),
        definition('circle')
            .create('blue')
            .copyWith(color: 0xFF0000FF, opacity: .5)
      ],
    );
    final before = jsonEncode(project.toJson());
    final gallery = _Gallery();
    final share = _Share();
    final exporter = CollageExporter(outputDirectory: dir);
    final flow = ExportFlowController(
        render: exporter.export,
        gallery: GallerySaveService(platform: gallery),
        share: SocialShareService(platform: share));
    addTearDown(flow.dispose);
    for (final format in ExportFormat.values) {
      for (final destination in [
        SocialShareDestination.gallery,
        SocialShareDestination.instagramStory
      ]) {
        await flow.run(
            project: project,
            settings: ExportSettings(
                width: 390, height: 780, format: format, jpegQuality: 100),
            destination: destination,
            origin: const Rect.fromLTWH(0, 0, 10, 10));
        final output = img.decodeImage(await File(
                destination == SocialShareDestination.gallery
                    ? gallery.path!
                    : share.path!)
            .readAsBytes())!;
        final center = output.getPixel(195, 390);
        expect(center.r, closeTo(127, 4));
        expect(center.g, lessThan(4));
        expect(center.b, closeTo(128, 4));
        expect(output.getPixel(0, 0).g, greaterThan(250));
        expect(output.getPixel(21, 390).g, greaterThan(240));
      }
    }
    expect(jsonEncode(project.toJson()), before);
    expect(await photo.readAsBytes(), bytes);
    final repository = ProjectRepository(documentsDirectory: dir);
    await repository.save(project);
    expect(
        (await repository.loadProjects())
            .single
            .stickers
            .map((s) => s.toJson()),
        project.stickers.map((s) => s.toJson()));
  });
}
