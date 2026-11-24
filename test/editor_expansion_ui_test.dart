import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piclayout/core/localization/app_localizations.dart';
import 'package:piclayout/features/collage_editor/editor_page.dart';
import 'package:piclayout/features/collage_editor/models/photo_adjustments.dart';
import 'package:piclayout/features/collage_editor/models/photo_metadata.dart';
import 'package:piclayout/features/collage_editor/models/photo_placement.dart';
import 'package:piclayout/features/collage_editor/state/collage_editor_controller.dart';
import 'package:piclayout/features/collage_editor/widgets/aspect_ratio_choices.dart';
import 'package:piclayout/features/collage_editor/widgets/collage_canvas.dart';
import 'package:piclayout/features/collage_editor/widgets/layers_sheet.dart';
import 'package:piclayout/features/collage_editor/widgets/photo_edit_sheet.dart';
import 'package:piclayout/features/collage_editor/widgets/styled_collage_scene.dart';
import 'package:piclayout/features/export/widgets/export_center.dart';
import 'package:piclayout/features/custom_layouts/state/custom_layout_providers.dart';
import 'package:piclayout/features/onboarding/onboarding_repository.dart';
import 'package:piclayout/features/projects/models/collage_project.dart';
import 'package:piclayout/features/projects/state/project_providers.dart';
import 'package:piclayout/features/settings/models/app_settings.dart';
import 'package:piclayout/features/settings/services/settings_repository.dart';
import 'package:piclayout/features/settings/state/settings_controller.dart';
import 'package:piclayout/features/stickers/sticker_overlay.dart';
import 'package:piclayout/features/templates/models/design_library.dart';
import 'package:piclayout/features/templates/services/design_library_repository.dart';
import 'package:piclayout/features/templates/state/design_library_providers.dart';
import 'package:piclayout/features/tutorial_tips/tutorial_tip_controller.dart';

import 'support/custom_layout_fixtures.dart';
import 'support/onboarding_fixtures.dart';

class _Library extends DesignLibraryRepository {
  @override
  Future<DesignLibrary> load() async => const DesignLibrary();
}

class _Settings extends SettingsRepository {
  AppSettings saved = const AppSettings();
  @override
  Future<AppSettings> load() async => saved;
  @override
  Future<void> save(AppSettings settings) async => saved = settings;
}

class _FailingProjects extends LayoutMemoryProjects {
  bool fail = true;

  @override
  Future<void> save(CollageProject project) async {
    if (fail) throw const FormatException('disk unavailable');
    await super.save(project);
  }
}

Widget _host(Widget child,
        {Locale locale = const Locale('en'), double scale = 1}) =>
    MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData.dark(),
      builder: (context, content) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: content!,
      ),
      home: Scaffold(body: child),
    );

void _screen(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('Editor keeps canvas and controls side by side in RTL landscape',
      (tester) async {
    _screen(tester, const Size(840, 420));
    final base = layoutProject(count: 3);
    final project = base.copyWith(photos: [
      for (final photo in base.photos)
        photo.copyWith(metadata: const PhotoMetadata(width: 160, height: 120)),
    ]);
    await tester.pumpWidget(ProviderScope(
        overrides: [
          projectRepositoryProvider.overrideWithValue(LayoutMemoryProjects()),
          designLibraryRepositoryProvider.overrideWithValue(_Library()),
          customLayoutRepositoryProvider
              .overrideWithValue(LayoutMemoryLibrary()),
          onboardingRepositoryProvider.overrideWithValue(MemoryOnboarding(
              value: const OnboardingState(
            completed: true,
            dismissedTips: {'tipPhoto', 'tipDrag'},
          ))),
        ],
        child: _host(EditorPage(project: project),
            locale: const Locale('ar'), scale: 1.55)));
    await tester.pumpAndSettle();
    final mode = find.text('تصميم حر');
    await tester.ensureVisible(mode);
    final preview = find.byType(CollageCanvas);
    expect(
        tester.getCenter(preview).dx, greaterThan(tester.getCenter(mode).dx));
    await tester.tap(mode);
    await tester.pump(const Duration(milliseconds: 750));
    expect(find.byKey(ValueKey('freestyle-${project.photos.first.id}')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Freestyle drag, pinch and rotation record one undo per gesture',
      (tester) async {
    final project = layoutProject(count: 1);
    final repository = LayoutMemoryProjects();
    final controller = CollageEditorController(
      initialProject: project.copyWith(freestyle: true, photos: [
        project.photos.single.copyWith(placement: const PhotoPlacement()),
      ]),
      repository: repository,
    );
    addTearDown(controller.dispose);
    controller.setSnapFreestyle(false);
    await tester.pumpWidget(_host(Center(
      child: SizedBox.square(
          dimension: 280, child: CollageCanvas(controller: controller)),
    )));
    await tester.pumpAndSettle();
    final tile = find.byKey(ValueKey('freestyle-${project.photos.single.id}'));
    final center = tester.getCenter(tile);

    final drag = await tester.startGesture(center);
    await drag.moveBy(const Offset(18, 0));
    await drag.moveBy(const Offset(25, 15));
    await tester.pump();
    await drag.moveBy(const Offset(23, 8));
    await tester.pump();
    await drag.up();
    await tester.pump();
    expect(controller.selectedPhoto!.placement!.x, greaterThan(.55));
    controller.undo();
    expect(controller.selectedPhoto!.placement!.x, .5);
    expect(controller.canUndo, isFalse);

    final first = await tester.startGesture(center - const Offset(28, 0));
    final second = await tester.startGesture(center + const Offset(28, 0));
    await first.moveTo(center - const Offset(38, 19));
    await second.moveTo(center + const Offset(42, 24));
    await tester.pump();
    await first.moveTo(center - const Offset(45, 27));
    await tester.pump();
    await second.up();
    await first.moveBy(const Offset(12, 0));
    await first.moveBy(const Offset(10, 6));
    await first.up();
    await tester.pump();
    final moved = controller.selectedPhoto!.placement!;
    expect(moved.width, greaterThan(.56));
    expect(moved.rotation.abs(), greaterThan(8));
    controller.undo();
    expect(controller.selectedPhoto!.placement!.toJson(),
        const PhotoPlacement().toJson());
    expect(controller.canUndo, isFalse);
    controller.redo();
    expect(controller.selectedPhoto!.placement!.toJson(), moved.toJson());
    await tester.pump();
    final handle = find.byWidgetPredicate((widget) =>
        widget is Semantics && widget.properties.label == 'Resize photo');
    final resize = await tester.startGesture(tester.getCenter(handle));
    await resize.moveBy(const Offset(23, 23));
    await resize.moveBy(const Offset(21, 20));
    await resize.up();
    await tester.pump(const Duration(milliseconds: 350));
    expect(
        controller.selectedPhoto!.placement!.width, greaterThan(moved.width));
    controller.undo();
    expect(controller.selectedPhoto!.placement!.toJson(), moved.toJson());
    await controller.flushPendingSave();
    expect(repository.saved!.photos.single.placement!.toJson(), moved.toJson());
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Layers show and lock freestyle photos in Arabic on a narrow screen',
      (tester) async {
    _screen(tester, const Size(320, 640));
    final project = layoutProject(count: 2);
    final controller = CollageEditorController(
      initialProject: project.copyWith(freestyle: true),
      repository: LayoutMemoryProjects(),
    );
    addTearDown(controller.dispose);
    controller.addText('عنوان');
    controller.addSticker(StickerCatalog.items.first);
    await tester.pumpWidget(_host(
        Builder(
            builder: (context) => TextButton(
                onPressed: () => showLayersSheet(context, controller),
                child: const Text('Open'))),
        locale: const Locale('ar'),
        scale: 1.35));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final layer = find.byKey(ValueKey(project.photos.last.id));
    await tester.ensureVisible(layer);
    expect(Directionality.of(tester.element(layer)), TextDirection.rtl);
    final menu = find.descendant(
        of: layer, matching: find.byType(PopupMenuButton<String>));
    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('إخفاء الطبقة'));
    await tester.pumpAndSettle();
    expect(controller.project.photos.last.placement!.hidden, isTrue);
    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('قفل الطبقة'));
    await tester.pumpAndSettle();
    expect(controller.project.photos.last.placement!.locked, isTrue);
    controller.undo();
    expect(controller.project.photos.last.placement!.locked, isFalse);
    expect(controller.project.photos.last.placement!.hidden, isTrue);
    await controller.flushPendingSave();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Custom ratio validates Arabic digits and saves favorites and history',
      (tester) async {
    _screen(tester, const Size(320, 640));
    final repository = _Settings();
    String? chosen;
    await tester.pumpWidget(ProviderScope(
      overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
      child: _host(
          AspectRatioChoices(
              selectedId: '1_1', onSelected: (value) => chosen = value.id),
          locale: const Locale('ar'),
          scale: 1.3),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('نسبة مخصصة'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.first, '٧');
    await tester.enterText(fields.last, '٠');
    await tester.pumpAndSettle();
    expect(
        tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed,
        isNull);
    await tester.enterText(fields.last, '٥');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final strings = AppLocalizations(const Locale('ar'));
    await tester.tap(find.byTooltip(strings.addFavorite));
    await tester.pumpAndSettle();
    expect(repository.saved.favoriteRatios, ['custom_7_5']);
    await tester.tap(find.text(strings.done));
    await tester.pumpAndSettle();
    expect(chosen, 'custom_7_5');
    expect(repository.saved.recentRatios, ['custom_7_5']);
    await tester.tap(find.text('نسبة مخصصة'));
    await tester.pumpAndSettle();
    final recent = find.widgetWithText(ActionChip, '7:5');
    await tester.ensureVisible(recent);
    await tester.tap(recent);
    await tester.pump();
    await tester.tap(find.byTooltip(strings.tr('swapDimensions')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings.done));
    await tester.pumpAndSettle();
    expect(chosen, 'custom_5_7');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Compare and apply-to-all use a single reversible photo edit',
      (tester) async {
    final controller = CollageEditorController(
      initialProject: layoutProject(count: 2),
      repository: LayoutMemoryProjects(),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(Builder(
        builder: (context) => TextButton(
              onPressed: () => showPhotoEditor(context, controller),
              child: const Text('Open'),
            ))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Warm'));
    await tester.tap(find.text('Apply to all photos'));
    await tester.pumpAndSettle();
    CollageProject preview() => tester
        .widget<StyledCollageScene>(find.byType(StyledCollageScene))
        .project;
    expect(
        preview().photos.every(
            (photo) => photo.adjustments.preset == PhotoFilterPreset.warm),
        isTrue);
    await tester.tap(find.text('Show original'));
    await tester.pumpAndSettle();
    expect(
        preview().photos.every(
            (photo) => photo.adjustments.preset == PhotoFilterPreset.original),
        isTrue);
    await tester.tap(find.text('Copy adjustments'));
    expect(controller.copiedAdjustments!.preset, PhotoFilterPreset.warm);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(controller.project.photos.last.adjustments.preset,
        PhotoFilterPreset.warm);
    controller.undo();
    expect(controller.project.photos.last.adjustments.preset,
        PhotoFilterPreset.original);
    expect(controller.canUndo, isFalse);
    await controller.flushPendingSave();
  });

  testWidgets(
      'Custom export size and JPEG quality are editable without changing the project',
      (tester) async {
    _screen(tester, const Size(320, 740));
    final project = layoutProject(count: 1);
    final original = project.toJson();
    await tester.pumpWidget(_host(ExportCenter(project: project), scale: 1.2));
    await tester.pumpAndSettle();
    final custom = find.text('Custom pixel size');
    await tester.ensureVisible(custom);
    await tester.tap(custom);
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.first, '4097');
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Done'))
            .onPressed,
        isNull);
    await tester.enterText(fields.first, '700');
    await tester.enterText(fields.last, '500');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Done'));
    await tester.pumpAndSettle();
    expect(find.text('700 × 500 pixels'), findsOneWidget);
    expect(find.textContaining('reflows the composition'), findsOneWidget);
    final jpeg = find.text('JPEG');
    await tester.ensureVisible(jpeg);
    await tester.tap(jpeg);
    await tester.pumpAndSettle();
    final quality = find.byType(Slider);
    expect(tester.widget<Slider>(quality).value, 92);
    await tester.ensureVisible(quality);
    await tester.tap(quality);
    await tester.pumpAndSettle();
    expect(tester.widget<Slider>(quality).value, isNot(92));
    expect(project.toJson(), original);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Failed autosave stays retryable and a clean gesture keeps redo',
      (tester) async {
    final repository = _FailingProjects();
    final controller = CollageEditorController(
      initialProject: layoutProject(count: 1),
      repository: repository,
    );
    addTearDown(controller.dispose);
    controller.setFreestyle(true);
    controller.undo();
    controller.beginInteractiveTransform();
    controller.endInteractiveTransform();
    expect(controller.canRedo, isTrue);
    controller.redo();
    await tester.pump(const Duration(milliseconds: 750));
    expect(controller.saveFailed, isTrue);
    expect(repository.saved, isNull);
    repository.fail = false;
    await controller.flushPendingSave();
    expect(controller.saveFailed, isFalse);
    expect(repository.saved!.freestyle, isTrue);
    expect(tester.takeException(), isNull);
  });
}
