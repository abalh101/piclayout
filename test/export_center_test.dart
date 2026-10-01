import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piclayout/features/projects/models/collage_project.dart';
import 'package:piclayout/features/collage_editor/models/photo_asset.dart';
import 'package:piclayout/features/export/models/social_share_preset.dart';
import 'package:piclayout/features/export/services/gallery_save_service.dart';
import 'package:piclayout/features/export/services/social_share_service.dart';
import 'package:piclayout/features/export/services/export_flow_controller.dart';
import 'package:piclayout/features/export/widgets/export_center.dart';
import 'package:piclayout/features/export/export_settings.dart';

class FakeGallery implements GalleryPlatform {
  String? saved;
  String? error;
  @override
  Future<void> save(String path) async {
    if (error != null) throw PlatformException(code: error!);
    saved = path;
  }
}

class FakeShare implements SocialSharePlatform {
  bool? installed = true;
  bool direct = false;
  int directCalls = 0;
  int sheets = 0;
  @override
  Future<bool?> isInstalled(String app) async => installed;
  @override
  Future<bool> shareDirect(String app, String path) async {
    directCalls++;
    return direct;
  }

  @override
  Future<void> shareSheet(String path, Rect origin) async {
    sheets++;
  }
}

CollageProject project() => CollageProject(
      id: 'p',
      name: 'Test',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      formatVersion: 1,
      aspectRatioId: '1_1',
      layoutTemplateId: 'grid_1x1_1',
      photos: const [
        PhotoAsset(
            id: 'photo', originalFileName: 'a.png', localPath: '/original.png')
      ],
    );
void main() {
  late Directory root;
  late File file;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('piclayout_export_');
    file = await File('${root.path}/export.png').writeAsBytes([1, 2, 3]);
  });
  tearDown(() => root.delete(recursive: true));

  test('social presets have exact dimensions and ratios', () {
    for (final target in [
      SocialShareDestination.instagramStory,
      SocialShareDestination.snapchat,
      SocialShareDestination.tiktok,
      SocialShareDestination.whatsapp
    ]) {
      final preset = SocialSharePreset.forDestination(target).single;
      expect([preset.width, preset.height], [1080, 1920]);
      expect(preset.aspectRatio, 9 / 16);
    }
    for (final target in [
      SocialShareDestination.instagramPost,
      SocialShareDestination.facebook
    ]) {
      final presets = SocialSharePreset.forDestination(target);
      expect(presets.map((p) => [p.width, p.height]), [
        [1080, 1080],
        [1080, 1350]
      ]);
      expect(presets.last.aspectRatio, 4 / 5);
    }
    expect([SocialSharePreset.youtube.width, SocialSharePreset.youtube.height],
        [1280, 720]);
    expect(SocialSharePreset.youtube.aspectRatio, 16 / 9);
    expect(SocialSharePreset.story.differsStrongly(1), isTrue);
    expect(SocialSharePreset.story.differsStrongly(9 / 16), isFalse);
  });
  test('gallery delegates file and translates native failures', () async {
    final platform = FakeGallery();
    final service = GallerySaveService(platform: platform);
    await service.save(file);
    expect(platform.saved, file.path);
    for (final entry in {
      'permission_denied': 'abgelehnt',
      'unavailable': 'nicht verfügbar',
      'save_failed': 'fehlgeschlagen'
    }.entries) {
      platform.error = entry.key;
      await expectLater(
          service.save(file),
          throwsA(isA<ExportFailure>()
              .having((e) => e.message, 'message', contains(entry.value))));
    }
    await expectLater(service.save(File('${root.path}/missing.jpg')),
        throwsA(isA<ExportFailure>()));
  });
  test('missing app informs user and falls back to share sheet', () async {
    final platform = FakeShare()..installed = false;
    String? notice;
    await SocialShareService(platform: platform).share(
        file,
        SocialShareDestination.instagramStory,
        const Rect.fromLTWH(0, 0, 10, 10),
        onNotice: (value) => notice = value);
    expect(notice, contains('nicht installiert'));
    expect(platform.directCalls, 0);
    expect(platform.sheets, 1);
  });
  test('unsupported direct sharing and unknown installation use sheet',
      () async {
    final platform = FakeShare();
    final service = SocialShareService(platform: platform);
    await service.share(file, SocialShareDestination.snapchat,
        const Rect.fromLTWH(0, 0, 10, 10));
    expect(platform.directCalls, 1);
    expect(platform.sheets, 1);
    platform.installed = null;
    await service.share(
        file, SocialShareDestination.tiktok, const Rect.fromLTWH(0, 0, 10, 10));
    expect(platform.sheets, 2);
    platform.installed = true;
    platform.direct = true;
    await service.share(file, SocialShareDestination.whatsapp,
        const Rect.fromLTWH(0, 0, 10, 10));
    expect(platform.sheets, 2);
  });
  test('export is locked until rendering and saving complete', () async {
    final pending = Completer<File>();
    var renders = 0;
    final flow = ExportFlowController(
        render: (project, settings) {
          renders++;
          return pending.future;
        },
        gallery: GallerySaveService(platform: FakeGallery()));
    final original = project();
    final json = original.toJson();
    Future<String?> run() => flow.run(
        project: original,
        settings: SocialSharePreset.story.settings(ExportFormat.png),
        destination: SocialShareDestination.gallery,
        origin: const Rect.fromLTWH(0, 0, 10, 10));
    final first = run();
    expect(flow.busy, isTrue);
    expect(await run(), isNull);
    expect(renders, 1);
    pending.complete(file);
    expect(await first, 'In Galerie gespeichert');
    expect(flow.busy, isFalse);
    expect(original.toJson(), json);
    flow.dispose();
  });
  test('failed rendering releases the export lock', () async {
    final flow = ExportFlowController(
        render: (_, settings) async => throw const ExportFailure('failed'));
    await expectLater(
        flow.run(
            project: project(),
            settings: SocialSharePreset.square.settings(ExportFormat.jpeg),
            destination: SocialShareDestination.general,
            origin: Rect.zero),
        throwsA(isA<ExportFailure>()));
    expect(flow.busy, isFalse);
    flow.dispose();
  });
  testWidgets('export choices fit small screens in light and dark mode',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Scaffold(body: ExportCenter(project: project()))));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Instagram Story'));
      await tester.pumpAndSettle();
      expect(find.text('1080 × 1920 Pixel'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
