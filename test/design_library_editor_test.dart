import 'package:piclayout/features/collage_editor/models/photo_metadata.dart';
import 'package:piclayout/features/stickers/sticker_overlay.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:piclayout/core/localization/app_localizations.dart';
import 'package:piclayout/features/collage_editor/editor_page.dart';
import 'package:piclayout/features/collage_editor/layouts/layout_library.dart';
import 'package:piclayout/features/collage_editor/models/photo_asset.dart';
import 'package:piclayout/features/collage_editor/state/collage_editor_controller.dart';
import 'package:piclayout/features/custom_layouts/state/custom_layout_providers.dart';
import 'package:piclayout/features/projects/models/collage_project.dart';
import 'package:piclayout/features/projects/services/project_repository.dart';
import 'package:piclayout/features/projects/state/project_providers.dart';
import 'package:piclayout/features/templates/models/design_library.dart';
import 'package:piclayout/features/templates/services/design_library_repository.dart';
import 'package:piclayout/features/templates/state/design_library_providers.dart';

import 'support/custom_layout_fixtures.dart';

class _MemoryDesignLibraryRepository extends DesignLibraryRepository {
  DesignLibrary data = const DesignLibrary();

  @override
  Future<DesignLibrary> load() async => data;

  @override
  Future<void> save(DesignLibrary library) async {
    data = library;
  }
}

class _MemoryProjectRepository extends ProjectRepository {
  @override
  Future<void> save(CollageProject project) async {}
}

void main() {
  late Directory root;
  late File image;

  setUpAll(() async {
    root = await Directory.systemTemp.createTemp('piclayout_design_ui_');
    image = File(p.join(root.path, 'image.png'));
    await image.writeAsBytes(img.encodePng(img.Image(width: 16, height: 16)));
  });
  tearDownAll(() => root.delete(recursive: true));

  testWidgets('editor favorites, saves and applies a template', (tester) async {
    final now = DateTime.utc(2026);
    final project = CollageProject(
      id: 'ui',
      name: 'UI',
      createdAt: now,
      updatedAt: now,
      formatVersion: 1,
      aspectRatioId: '1_1',
      layoutTemplateId: LayoutLibrary.defaultFor(2).id,
      photos: [
        for (var i = 0; i < 2; i++)
          PhotoAsset(
              id: '$i',
              originalFileName: '$i.png',
              localPath: image.path,
              metadata: const PhotoMetadata(width: 16, height: 16)),
      ],
    );
    final libraryRepository = _MemoryDesignLibraryRepository();
    final container = ProviderContainer(overrides: [
      customLayoutRepositoryProvider.overrideWithValue(LayoutMemoryLibrary()),
      designLibraryRepositoryProvider.overrideWithValue(libraryRepository),
      projectRepositoryProvider.overrideWithValue(_MemoryProjectRepository()),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('de'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: EditorPage(project: project),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byIcon(Icons.star_border).first);
    await tester.tap(find.byIcon(Icons.star_border).first);
    await tester.pump();
    expect(libraryRepository.data.favoriteLayouts, hasLength(1));

    final controller = container.read(editorControllerProvider(project));
    controller.addSticker(StickerCatalog.items.first);
    await tester.pumpAndSettle();
    final saveButton = find.text('Als Vorlage speichern');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Mein Design');
    await tester.tap(find.text('Sticker übernehmen'));
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.tap(find.text('Vorlage speichern'));
    await tester.pumpAndSettle();
    expect(libraryRepository.data.templates.single.name, 'Mein Design');
    expect(libraryRepository.data.templates.single.includeStickers, isTrue);
    expect(libraryRepository.data.templates.single.stickers, hasLength(1));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    controller.updateCanvas(controller.project.canvas.copyWith(spacing: 20));
    final myTemplates = find.text('Meine Vorlagen');
    await tester.ensureVisible(myTemplates);
    await tester.tap(myTemplates);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mein Design'));
    await tester.pumpAndSettle();
    expect(controller.project.canvas.spacing, 2);
    expect(
        controller.project.photos.map((item) => item.id).toList(), ['0', '1']);
    await tester.ensureVisible(myTemplates);
    await tester.tap(myTemplates);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Löschen').last);
    await tester.pumpAndSettle();
    expect(libraryRepository.data.templates, isEmpty);
    await controller.saveNow();
  });
}
