import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piclayout/core/localization/app_localizations.dart';
import 'package:piclayout/features/collage_editor/state/collage_editor_controller.dart';
import 'package:piclayout/features/collage_editor/widgets/collage_canvas.dart';
import 'package:piclayout/features/stickers/sticker_overlay.dart';
import 'package:piclayout/features/stickers/sticker_sheet.dart';
import 'support/custom_layout_fixtures.dart';

Widget host(CollageEditorController controller,
        {Locale locale = const Locale('de'),
        Brightness brightness = Brightness.light}) =>
    MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        theme: ThemeData(brightness: brightness),
        home: Scaffold(
            body: Builder(
                builder: (context) => Column(children: [
                      SizedBox(
                          width: 300,
                          height: 300,
                          child: CollageCanvas(controller: controller)),
                      TextButton(
                          onPressed: () =>
                              showStickerPicker(context, controller),
                          child: const Text('Picker')),
                      TextButton(
                          onPressed: () =>
                              showStickerEditor(context, controller),
                          child: const Text('Edit')),
                    ]))));
void main() {
  testWidgets(
      'Picker adds, canvas selects/drags, edits autosave and undo restores gesture',
      (tester) async {
    final repository = LayoutMemoryProjects();
    final controller = CollageEditorController(
        initialProject: layoutProject(count: 1), repository: repository);
    addTearDown(controller.dispose);
    await tester.pumpWidget(host(controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Picker'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Formen'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('catalog-circle')));
    await tester.pumpAndSettle();
    final sticker = controller.selectedSticker!;
    expect(sticker.content, 'circle');
    await tester.pump(const Duration(seconds: 1));
    expect(repository.saved!.stickers.single.id, sticker.id);
    final target = find.byKey(ValueKey('sticker-${sticker.id}'));
    await tester.drag(target, const Offset(40, 30));
    await tester.pumpAndSettle();
    expect(controller.selectedSticker!.x, greaterThan(sticker.x));
    controller.undo();
    await tester.pumpAndSettle();
    expect(controller.project.stickers.single.toJson(), sticker.toJson());
    final center = tester.getCenter(target);
    final finger1 =
        await tester.startGesture(center - const Offset(15, 0), pointer: 1);
    final finger2 =
        await tester.startGesture(center + const Offset(15, 0), pointer: 2);
    await tester.pump();
    await finger1.moveTo(center - const Offset(30, 12));
    await tester.pump();
    await finger2.moveTo(center + const Offset(30, 12));
    await tester.pump();
    await finger1.up();
    await finger2.up();
    await tester.pumpAndSettle();
    expect(controller.selectedSticker!.scale, greaterThan(1));
    expect(controller.selectedSticker!.rotation.abs(), greaterThan(1));
    controller.undo();
    await tester.pumpAndSettle();
    expect(controller.project.stickers.single.toJson(), sticker.toJson());
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Slider).first, const Offset(40, 0));
    await tester.pumpAndSettle();
    expect(controller.selectedSticker!.scale, greaterThan(1));
    await tester.tap(find.text('Fertig'));
    await tester.pumpAndSettle();
    controller.undo();
    await tester.pumpAndSettle();
    expect(controller.selectedSticker!.scale, 1);
    await controller.saveNow();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'Picker and editing work in six languages, RTL, dark mode and small screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final locale in AppLocalizations.supportedLocales) {
      final controller = CollageEditorController(
          initialProject: layoutProject(count: 1),
          repository: LayoutMemoryProjects());
      final t = AppLocalizations(locale).tr;
      await tester.pumpWidget(
          host(controller, locale: locale, brightness: Brightness.dark));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Picker'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t('stCategory_labels')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('catalog-place')));
      await tester.pumpAndSettle();
      expect(controller.selectedSticker!.type, StickerType.label);
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(Directionality.of(tester.element(find.byType(TextFormField))),
          locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr);
      await tester.enterText(find.byType(TextFormField),
          locale.languageCode == 'ar' ? 'برلين' : 'Berlin');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(controller.selectedSticker!.content,
          locale.languageCode == 'ar' ? 'برلين' : 'Berlin');
      await tester.scrollUntilVisible(find.text(t('stDuplicate')), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(t('stDuplicate')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t('stDuplicate')));
      await tester.pumpAndSettle();
      expect(controller.project.stickers, hasLength(2));
      await tester.ensureVisible(find.text(AppLocalizations(locale).delete));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppLocalizations(locale).delete));
      await tester.pumpAndSettle();
      expect(controller.project.stickers, hasLength(1));
      expect(tester.takeException(), isNull, reason: locale.languageCode);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    }
  });
}
