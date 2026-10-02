import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piclayout/core/localization/app_localizations.dart';
import 'package:piclayout/features/collage_editor/state/collage_editor_controller.dart';
import 'package:piclayout/features/custom_layouts/models/custom_layout.dart';
import 'package:piclayout/features/custom_layouts/state/custom_layout_providers.dart';
import 'package:piclayout/features/custom_layouts/widgets/custom_layout_section.dart';
import 'package:piclayout/features/custom_layouts/widgets/layout_builder_page.dart';
import 'support/custom_layout_fixtures.dart';

Widget host(ProviderContainer container, Widget home,
        {String language = 'de'}) =>
    UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            locale: Locale(language),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate
            ],
            home: home));

Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 150,
      scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'Drag is a draft, Done commits once with undo/autosave, reset and cancel preserve project',
      (tester) async {
    final repository = LayoutMemoryProjects();
    final controller = CollageEditorController(
        initialProject: layoutProject(), repository: repository);
    addTearDown(controller.dispose);
    final container = ProviderContainer(overrides: [
      customLayoutRepositoryProvider.overrideWithValue(LayoutMemoryLibrary())
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(host(
        container,
        Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () => showLayoutBuilder(context, controller),
                    child: const Text('Open'))))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final initial = gridLayout();
    final divider =
        initial.dividers.firstWhere((d) => d.axis == DividerAxis.vertical);
    await tester.drag(
        find.byKey(ValueKey('handle-${divider.id}')), const Offset(50, 0));
    await tester.pumpAndSettle();
    expect(controller.project.customLayout, isNull);
    await tester.tap(find.byKey(const ValueKey('layout-done')));
    await tester.pumpAndSettle();
    expect(controller.project.customLayout!.cells.first.width, greaterThan(.5));
    await tester.pump(const Duration(seconds: 1));
    expect(repository.saved!.customLayout, isNotNull);
    controller.undo();
    expect(controller.project.customLayout, isNull);
    controller.redo();
    final committed = controller.project.customLayout!.toJson();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final seam = controller.project.customLayout!.dividers
        .firstWhere((d) => d.axis == DividerAxis.vertical);
    await tester.drag(
        find.byKey(ValueKey('handle-${seam.id}')), const Offset(-40, 0));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const ValueKey('layout-reset')));
    await tester.tap(find.byKey(const ValueKey('layout-reset')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('layout-done')));
    await tester.pumpAndSettle();
    expect(controller.project.customLayout!.toJson(), committed);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.drag(
        find.byKey(ValueKey('handle-${seam.id}')), const Offset(-40, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(controller.project.customLayout!.toJson(), committed);
    await controller.saveNow();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'Named layout is reusable; library hides incompatible counts and failed saves stay drafts',
      (tester) async {
    final library = LayoutMemoryLibrary();
    library.layouts = [
      gridLayout(count: 2, id: 'incompatible', name: 'Hidden two photos')
    ];
    final controller = CollageEditorController(
        initialProject: layoutProject(), repository: LayoutMemoryProjects());
    addTearDown(controller.dispose);
    final container = ProviderContainer(
        overrides: [customLayoutRepositoryProvider.overrideWithValue(library)]);
    addTearDown(container.dispose);
    await tester.pumpWidget(host(
        container,
        Scaffold(
            body: SingleChildScrollView(
                child: CustomLayoutSection(controller: controller)))));
    await tester.pumpAndSettle();
    expect(find.text('Hidden two photos'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('open-layout-builder')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const ValueKey('layout-save')));
    await tester.tap(find.byKey(const ValueKey('layout-save')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'My six photos');
    await tester
        .tap(find.widgetWithText(FilledButton, 'Als Layout speichern').last);
    await tester.pumpAndSettle();
    expect(library.layouts, hasLength(2));
    expect(library.layouts.last.name, 'My six photos');
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    // Saving to library is explicit; leaving the draft does not apply it.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(controller.project.customLayout, isNull);
    await tester.tap(find.widgetWithText(ChoiceChip, 'My six photos'));
    await tester.pumpAndSettle();
    expect(controller.project.customLayout!.name, 'My six photos');
    await tester.tap(find.byKey(const ValueKey('open-layout-builder')));
    await tester.pumpAndSettle();
    library.fail = true;
    await reveal(tester, find.byKey(const ValueKey('layout-save')));
    await tester.tap(find.byKey(const ValueKey('layout-save')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Should fail');
    await tester
        .tap(find.widgetWithText(FilledButton, 'Als Layout speichern').last);
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Layout konnte nicht gespeichert werden. Bitte erneut versuchen.'),
        findsOneWidget);
    expect(library.layouts, hasLength(2));
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await controller.saveNow();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'Cell selection and sliders are usable on a 320px screen in all six languages',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(overrides: [
      customLayoutRepositoryProvider.overrideWithValue(LayoutMemoryLibrary())
    ]);
    addTearDown(container.dispose);
    for (final language in ['de', 'en', 'ar', 'tr', 'fr', 'es']) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(host(
          container,
          LayoutBuilderPage(
              key: ValueKey(language), project: layoutProject(count: 9)),
          language: language));
      await tester.pumpAndSettle();
      final canvas = find.byKey(const ValueKey('layout-builder-canvas'));
      await tester.ensureVisible(canvas);
      await tester.pumpAndSettle();
      final rect = tester.getRect(canvas);
      await tester.tapAt(
          Offset(rect.left + rect.width * .16, rect.top + rect.height * .84));
      await tester.pumpAndSettle();
      final strings = AppLocalizations(Locale(language));
      expect(find.text('${strings.tr('layoutBuilderCell')} 7'), findsOneWidget);
      final sliderKey = ValueKey(
          'slider-${gridLayout(count: 9).dividers.firstWhere((d) => d.axis == DividerAxis.vertical).id}');
      await tester.scrollUntilVisible(find.byKey(sliderKey), 100,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Slider).first, const Offset(30, 0));
      await tester.pumpAndSettle();
      expect(Directionality.of(tester.element(canvas)),
          language == 'ar' ? TextDirection.rtl : TextDirection.ltr);
      await reveal(tester, find.byKey(const ValueKey('layout-save')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: language);
    }
  });
}
