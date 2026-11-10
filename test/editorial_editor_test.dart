import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:piclayout/core/localization/app_localizations.dart';
import 'package:piclayout/features/editorial/models/editorial_design.dart';
import 'package:piclayout/features/editorial/models/design_presets.dart';
import 'package:piclayout/features/editorial/widgets/design_sheet.dart';
import 'package:piclayout/features/editorial/widgets/design_layer_interactions.dart';
import 'package:piclayout/features/collage_editor/models/text_overlay.dart';
import 'package:piclayout/features/collage_editor/state/collage_editor_controller.dart';
import 'package:piclayout/features/collage_editor/widgets/collage_canvas.dart';
import 'support/editorial_fixtures.dart';
import 'support/real_image_io.dart';

Widget localized(Widget child, String language, {double scale = 1}) =>
    MaterialApp(
        locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!),
        home: Scaffold(body: child));

void main() {
  for (final locale in ['de', 'en', 'ar', 'tr', 'fr', 'es']) {
    testWidgets(
        'Design sheets and text input fit 320px at 200% text in $locale',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final p = editorialProject(count: 3);
      final c = CollageEditorController(
          initialProject: p.copyWith(
              design: DesignPreset.all.first.create(p.photos, (k) => k)),
          repository: EditorialMemoryRepository());
      c.selectDesignLayer(c.project.design.layers.first.id);
      addTearDown(c.dispose);
      await tester.pumpWidget(localized(
          DesignSheet(controller: c, initialTab: 2), locale,
          scale: 2));
      await tester.pumpAndSettle();
      final text = find.byKey(ValueKey('text-${c.selectedDesignLayerId}'));
      await tester.scrollUntilVisible(text, 300,
          scrollable: find
              .descendant(
                  of: find.byType(ListView).last,
                  matching: find.byType(Scrollable))
              .first,
          maxScrolls: 60);
      await tester.pumpAndSettle();
      await tester.enterText(text, 'أمسيات في\nسانتوريني');
      await tester.pump(const Duration(seconds: 1));
      expect(c.selectedDesignLayer!.text.text, 'أمسيات في\nسانتوريني');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final labelRadius = find.byKey(const ValueKey('edLabelRadius'));
      final scrollable = find
          .descendant(
              of: find.byType(ListView).last, matching: find.byType(Scrollable))
          .first;
      for (var i = 0; i < 60 && labelRadius.evaluate().isEmpty; i++) {
        final position = tester.state<ScrollableState>(scrollable).position;
        position
            .jumpTo((position.pixels + 200).clamp(0, position.maxScrollExtent));
        await tester.pump();
      }
      await tester.ensureVisible(labelRadius);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });
  }
  testWidgets(
      'Presets confirm replacement and blank preserves original photo files',
      (tester) async {
    final p = editorialProject(count: 3);
    final c = CollageEditorController(
        initialProject: p, repository: EditorialMemoryRepository());
    addTearDown(c.dispose);
    await tester.pumpWidget(localized(DesignSheet(controller: c), 'en'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A Week in Pictures'));
    await tester.pumpAndSettle();
    expect(c.project.design.mode, DesignMode.editorial);
    await tester.ensureVisible(find.text('Travel Masonry'));
    await tester.tap(find.text('Travel Masonry'));
    await tester.pumpAndSettle();
    expect(find.text('Change design?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(c.project.design.mode, DesignMode.editorial);
    expect(c.project.photos, p.photos);
    final presetsScroll = find.descendant(
        of: find.byType(ListView).first, matching: find.byType(Scrollable));
    tester.state<ScrollableState>(presetsScroll.first).position.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Standard layout'));
    await tester.pumpAndSettle();
    expect(c.project.design.active, isFalse);
    await tester.tap(find.text('Show design again'));
    await tester.pumpAndSettle();
    expect(c.project.design.mode, DesignMode.editorial);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
  testWidgets('Design sheet stays above the keyboard with large RTL text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final p = editorialProject(count: 1);
    final c = CollageEditorController(
        initialProject: p.copyWith(
            design: DesignPreset.all.first.create(p.photos, (k) => k)),
        repository: EditorialMemoryRepository());
    addTearDown(c.dispose);
    c.selectDesignLayer(c.project.design.layers.first.id);
    await tester.pumpWidget(localized(
        Builder(
            builder: (context) => TextButton(
                onPressed: () => showDesignSheet(context, c, layers: true),
                child: const Text('Open'))),
        'ar',
        scale: 2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(tester.getBottomRight(find.byType(DesignSheet)).dy,
        lessThanOrEqualTo(340));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
  testWidgets(
      'Canvas drag, resize, rotate and locked hit targets use grouped history',
      (tester) async {
    final p = editorialProject(count: 1);
    const l = DesignLayer(
        id: 'free',
        type: DesignLayerType.text,
        x: .4,
        y: .4,
        width: .3,
        height: .2,
        text: TextOverlay(id: 'text', text: 'Editorial'));
    final c = CollageEditorController(
        initialProject: p.copyWith(
            design: const EditorialDesign(mode: DesignMode.blank, layers: [l])),
        repository: EditorialMemoryRepository());
    addTearDown(c.dispose);
    await tester.pumpWidget(localized(
        Center(
            child: SizedBox(
                width: 300,
                height: 500,
                child: AnimatedBuilder(
                    animation: c,
                    builder: (_, __) => Stack(children: [
                          DesignLayerInteractions(
                              controller: c,
                              size: const Size(300, 500),
                              onEditLayer: () {})
                        ])))),
        'en'));
    final target = find.byType(DesignLayerInteractions);
    await tester.pumpAndSettle();
    final origin = tester.getTopLeft(target);
    await tester.tapAt(origin + const Offset(120, 200));
    await tester.pump();
    await tester.dragFrom(
        origin + const Offset(120, 200), const Offset(30, 40));
    await tester.pump();
    expect(c.selectedDesignLayer!.x, greaterThan(.4));
    expect(c.selectedDesignLayer!.y, greaterThan(.4));
    c.undo();
    await tester.pump();
    expect(c.selectedDesignLayer!.x, .4);
    final resize = find.byTooltip('Resize');
    await tester.drag(resize, const Offset(24, 15));
    await tester.pump();
    expect(c.selectedDesignLayer!.width, greaterThan(.3));
    c.undo();
    await tester.pump();
    await tester.drag(find.byTooltip('Rotate'), const Offset(30, 0));
    await tester.pump();
    expect(c.selectedDesignLayer!.rotation, greaterThan(0));
    c.undo();
    await tester.pump();
    c.updateDesignLayer(c.selectedDesignLayer!.copyWith(locked: true));
    await tester.pump();
    await tester.dragFrom(
        origin + const Offset(120, 200), const Offset(30, 40));
    await tester.pump();
    expect(c.selectedDesignLayer!.x, .4);
    expect(c.selectedDesignLayer!.y, .4);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
  testWidgets(
      'Preview shows a complete editorial canvas and guides stay separate',
      (tester) async {
    final dir = await tester
        .runAsync(() => Directory.systemTemp.createTemp('editorial_widget_'));
    addTearDown(() => deleteImageFixtureDirectory(tester, dir!));
    final file = File('${dir!.path}/source.png');
    await tester.runAsync(() => file.writeAsBytes(img.encodePng(
        img.Image(width: 100, height: 100)
          ..clear(img.ColorRgb8(180, 120, 70)))));
    final p = editorialProject(count: 9, path: file.path);
    final c = CollageEditorController(
        initialProject: p.copyWith(
            design: DesignPreset.all.first.create(p.photos, (k) => k)),
        repository: EditorialMemoryRepository());
    addTearDown(c.dispose);
    final key = GlobalKey();
    await withRealImageIo(tester, () async {
      await tester.pumpWidget(localized(
          Center(
              child: SizedBox(
                  width: 300,
                  height: 533,
                  child: RepaintBoundary(
                      key: key, child: CollageCanvas(controller: c)))),
          'en'));
      await tester.pumpAndSettle();
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (find.byIcon(Icons.image_outlined).evaluate().isNotEmpty &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await tester.pump();
      }
      expect(find.byIcon(Icons.image_outlined), findsNothing);
      expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
      c.selectDesignLayer(
          c.project.design.layers.firstWhere((l) => l.isPhoto).id);
      await tester.pump();
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage();
      expect(image.width, 300);
      expect(image.height, 533);
      final pixels = await image.toByteData(format: ui.ImageByteFormat.png);
      final bitmap = img.decodePng(pixels!.buffer.asUint8List())!;
      expect(bitmap.getPixel(60, 150).r, 180);
      expect(bitmap.getPixel(60, 150).g, 120);
      if (const bool.fromEnvironment('EDITORIAL_VISUAL_QA')) {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final out = Directory('build/editorial-qa');
        await out.create(recursive: true);
        await File('${out.path}/editorial-canvas.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
      }
      image.dispose();
      expect(tester.takeException(), isNull);
    });
  });
}
