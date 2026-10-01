import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:piclayout/core/localization/app_localizations.dart';
import 'package:piclayout/features/collage_editor/models/photo_asset.dart';
import 'package:piclayout/features/collage_editor/state/collage_editor_controller.dart';
import 'package:piclayout/features/collage_editor/widgets/collage_canvas.dart';
import 'package:piclayout/features/collage_editor/widgets/text_overlay_sheet.dart';
import 'package:piclayout/features/projects/models/collage_project.dart';
import 'package:piclayout/features/projects/services/project_repository.dart';

void main() {
  late Directory root;
  late File photo;

  setUpAll(() async {
    root = await Directory.systemTemp.createTemp('piclayout_ui_');
    photo = File(p.join(root.path, 'photo.png'));
    await photo.writeAsBytes(img.encodePng(img.Image(width: 16, height: 16)));
  });

  tearDownAll(() => root.delete(recursive: true));

  testWidgets('text sheet adds, edits, styles and deletes an overlay',
      (tester) async {
    final now = DateTime.utc(2026);
    final controller = CollageEditorController(
      initialProject: CollageProject(
        id: 'ui',
        name: 'UI',
        createdAt: now,
        updatedAt: now,
        formatVersion: 1,
        aspectRatioId: '1_1',
        layoutTemplateId: 'grid_1x1_1',
        photos: [
          PhotoAsset(
              id: 'photo', originalFileName: 'photo.png', localPath: photo.path)
        ],
      ),
      repository: _MemoryProjectRepository(),
    );

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('de'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: Scaffold(
        body: Builder(builder: (context) {
          return Column(children: [
            TextButton(
              onPressed: () => showTextOverlaySheet(context, controller),
              child: const Text('Öffnen'),
            ),
            SizedBox(
                width: 390,
                height: 390,
                child: CollageCanvas(controller: controller)),
          ]);
        }),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Öffnen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Text hinzufügen'));
    await tester.pumpAndSettle();
    expect(controller.project.textOverlays, hasLength(1));
    await tester.enterText(find.byType(TextField), 'Sommer 2026');
    await tester.pump();
    expect(controller.project.textOverlays.single.text, 'Sommer 2026');

    await tester.ensureVisible(find.text('Gelb'));
    await tester.tap(find.text('Gelb'));
    await tester.pump();
    expect(controller.project.textOverlays.single.color, 0xFFFACC15);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await tester.dragFrom(
      tester.getCenter(find.byType(CollageCanvas)),
      const Offset(40, 20),
    );
    await tester.pump();
    expect(controller.project.textOverlays.single.x, greaterThan(0.5));
    controller.undo();
    expect(controller.project.textOverlays.single.x, 0.5);

    await tester.tap(find.text('Öffnen'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Löschen'));
    await tester.tap(find.text('Löschen'));
    await tester.pump();
    expect(controller.project.textOverlays, isEmpty);
    controller.dispose();
  });
}

class _MemoryProjectRepository extends ProjectRepository {
  @override
  Future<void> save(CollageProject project) async {}
}
