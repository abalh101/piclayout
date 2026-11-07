import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:piclayout/features/collage_editor/models/photo_asset.dart';
import 'package:piclayout/core/localization/app_localizations.dart';
import 'package:piclayout/core/localization/translations.dart';
import 'package:piclayout/core/theme/app_theme.dart';
import 'package:piclayout/features/collage_editor/editor_page.dart';
import 'package:piclayout/features/collage_editor/models/photo_metadata.dart';
import 'package:piclayout/features/collage_editor/models/photo_adjustments.dart';
import 'package:piclayout/features/collage_editor/state/collage_editor_controller.dart';
import 'package:piclayout/features/collage_editor/widgets/collage_canvas.dart';
import 'package:piclayout/features/collage_editor/widgets/canvas_divider_layer.dart';
import 'package:piclayout/features/collage_editor/widgets/photo_edit_sheet.dart';
import 'package:piclayout/features/collage_editor/widgets/text_overlay_sheet.dart';
import 'package:piclayout/features/collage_editor/widgets/thumbnail_strip.dart';
import 'package:piclayout/features/custom_layouts/state/custom_layout_providers.dart';
import 'package:piclayout/features/home/home_page.dart';
import 'package:piclayout/features/onboarding/onboarding_repository.dart';
import 'package:piclayout/features/projects/models/collage_project.dart';
import 'package:piclayout/features/projects/state/project_providers.dart';
import 'package:piclayout/features/templates/models/design_library.dart';
import 'package:piclayout/features/templates/services/design_library_repository.dart';
import 'package:piclayout/features/templates/state/design_library_providers.dart';
import 'package:piclayout/features/tutorial_tips/tutorial_tip_controller.dart';
import 'support/custom_layout_fixtures.dart';
import 'support/onboarding_fixtures.dart';
import 'support/real_image_io.dart';

class _Projects extends LayoutMemoryProjects {
  bool fail = false;
  int saves = 0, deletes = 0;
  Completer<void>? pending;
  Completer<PhotoAsset>? replacement;
  int imports = 0;
  List<CollageProject> items = [];
  @override
  Future<void> save(CollageProject project) async {
    saves++;
    if (pending != null) await pending!.future;
    if (fail) throw StateError('disk full');
    await super.save(project);
  }

  @override
  Future<List<CollageProject>> loadProjects() async => items;
  @override
  Future<void> delete(CollageProject project) async {
    deletes++;
    if (fail) throw StateError('disk unavailable');
    items = [];
  }

  @override
  Future<PhotoAsset> importReplacement(XFile file, String projectId) {
    imports++;
    return replacement!.future;
  }
}

class _Designs extends DesignLibraryRepository {
  @override
  Future<DesignLibrary> load() async => const DesignLibrary();
}

CollageProject _project() {
  final project = layoutProject(count: 2);
  return project.copyWith(photos: [
    for (final photo in project.photos)
      photo.copyWith(metadata: const PhotoMetadata(width: 100, height: 100)),
  ]);
}

ProviderContainer _container(_Projects repository) =>
    ProviderContainer(overrides: [
      projectRepositoryProvider.overrideWithValue(repository),
      designLibraryRepositoryProvider.overrideWithValue(_Designs()),
      customLayoutRepositoryProvider.overrideWithValue(LayoutMemoryLibrary()),
      onboardingRepositoryProvider.overrideWithValue(MemoryOnboarding(
          value: const OnboardingState(
              completed: true,
              dismissedTips: {'tipPhoto', 'tipZoom', 'tipDrag', 'tipExport'}))),
    ]);

Widget _app(Widget home,
        {Locale locale = const Locale('en'),
        double scale = 1,
        bool dark = false}) =>
    MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      theme: dark ? AppTheme.dark() : AppTheme.light(),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
      home: home,
    );

void main() {
  test('replacement rejects overlap and ignores completion after removal',
      () async {
    final repository = _Projects()..replacement = Completer<PhotoAsset>();
    final controller = CollageEditorController(
        initialProject: _project(), repository: repository);
    addTearDown(controller.dispose);
    final replacement =
        controller.project.photos.first.copyWith(id: 'replacement');
    final first = controller.replaceSelected(XFile('unused.png'));
    await controller.replaceSelected(XFile('unused.png'));
    expect(repository.imports, 1);
    controller.removeSelected();
    repository.replacement!.complete(replacement);
    await first;
    expect(controller.project.photos.single.id, 'photo-1');
    expect(controller.selectedPhoto!.id, 'photo-1');
    repository.replacement = Completer<PhotoAsset>();
    final retry = controller.replaceSelected(XFile('unused.png'));
    repository.replacement!.complete(replacement);
    await retry;
    expect(controller.selectedPhoto!.id, 'replacement');
    controller.undo();
    expect(controller.project.photos.single.id, 'photo-1');
  });

  testWidgets(
      'filter reset is a draft, original intensity is disabled and cancel preserves edits',
      (tester) async {
    await withRealImageIo(tester, () async {
      final controller = CollageEditorController(
          initialProject: _project(), repository: _Projects());
      addTearDown(controller.dispose);
      controller.setAdjustments(
          'photo-0',
          const PhotoAdjustments(
              preset: PhotoFilterPreset.warm, filterIntensity: .4));
      final original = controller.project.toJson();
      await tester.pumpWidget(_app(Builder(
          builder: (context) => Scaffold(
              body: TextButton(
                  onPressed: () => showPhotoEditor(context, controller),
                  child: const Text('open'))))));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final reset = find.widgetWithText(
          TextButton, AppLocalizations(const Locale('en')).tr('reset'));
      await tester.scrollUntilVisible(reset, 180,
          scrollable: find.byType(Scrollable).last);
      await tester.tap(reset);
      await tester.pump();
      await tester.scrollUntilVisible(
          find.byKey(const ValueKey('filterIntensity')), -180,
          scrollable: find.byType(Scrollable).last);
      expect(
          tester
              .widget<Slider>(find.byKey(const ValueKey('filterIntensity')))
              .onChanged,
          isNull);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(controller.project.toJson(), original);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets(
      'editor keeps real demo images dominant on large phones and landscape',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await withRealImageIo(tester, () async {
      final container = _container(_Projects());
      addTearDown(container.dispose);
      if (const bool.fromEnvironment('PICLAYOUT_CAPTURE')) {
        final artifacts =
            File(Platform.resolvedExecutable).parent.parent.parent;
        for (final entry in {
          'Roboto': 'roboto-regular.ttf',
          'MaterialIcons': 'materialicons-regular.otf'
        }.entries) {
          final loader = FontLoader(entry.key)
            ..addFont(File('${artifacts.path}/material_fonts/${entry.value}')
                .readAsBytes()
                .then((bytes) => ByteData.sublistView(bytes)));
          await loader.load();
        }
      }
      final source = _project();
      final project = source.copyWith(photos: [
        for (var i = 0; i < source.photos.length; i++)
          source.photos[i].copyWith(
              localPath: File('assets/demo/demo_${i + 1}.png').absolute.path)
      ]);
      final boundary = GlobalKey();
      for (final size in [const Size(430, 932), const Size(740, 360)]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(UncontrolledProviderScope(
            container: container,
            child: _app(RepaintBoundary(
                key: boundary, child: EditorPage(project: project)))));
        await tester.pumpAndSettle();
        for (final image in tester.widgetList<Image>(find.byType(Image))) {
          await precacheImage(
              image.image, tester.element(find.byType(Image).first));
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (const bool.fromEnvironment('PICLAYOUT_CAPTURE')) {
          // Wait for the preview's independent native decoder, not just thumbnails.
          final deadline = DateTime.now().add(const Duration(seconds: 5));
          while (find.byIcon(Icons.image_outlined).evaluate().isNotEmpty &&
              DateTime.now().isBefore(deadline)) {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            await tester.pump();
          }
          expect(find.byIcon(Icons.image_outlined), findsNothing);
          final image = await (boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('build/refinement-${size.width.toInt()}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        }
      }
    });
  });
  test('refinement messages are translated in every supported language', () {
    for (final key in [
      'projectSaveFailed',
      'photoPickFailed',
      'photoLoadFailed',
      'deleteProjectConfirm',
      'exportSaving',
      'exportSharing',
      'exportPixels'
    ]) {
      expect(translations[key], hasLength(6));
      for (final locale in AppLocalizations.supportedLocales) {
        expect(AppLocalizations(locale).tr(key), isNot(anyOf(isEmpty, key)));
      }
    }
  });

  testWidgets('failed autosave is handled and retry saves the newest edit',
      (tester) async {
    final repository = _Projects()..fail = true;
    final controller = CollageEditorController(
        initialProject: _project(), repository: repository);
    addTearDown(controller.dispose);
    controller.rotateSelected();
    await tester.pump(const Duration(milliseconds: 701));
    expect(controller.saveFailed, isTrue);
    expect(tester.takeException(), isNull);
    controller.flipSelected();
    repository.fail = false;
    await controller.saveNow();
    expect(controller.saveFailed, isFalse);
    expect(repository.saved!.toJson(), controller.project.toJson());
  });

  test('no-op gestures preserve redo; changed gesture is one undo step',
      () async {
    final controller = CollageEditorController(
        initialProject: _project(), repository: _Projects());
    addTearDown(controller.dispose);
    controller.rotateSelected();
    controller.undo();
    controller.beginInteractiveTransform();
    controller.endInteractiveTransform();
    expect(controller.canUndo, isFalse);
    expect(controller.canRedo, isTrue);
    controller.beginInteractiveTransform();
    for (final scale in [1.2, 1.5, 2.0]) {
      controller.updateTransformLive(controller.selectedPhotoId!,
          controller.selectedPhoto!.transform.copyWith(scale: scale));
    }
    controller.endInteractiveTransform();
    expect(controller.canRedo, isFalse);
    controller.undo();
    expect(controller.selectedPhoto!.transform.scale, 1);
    expect(controller.canUndo, isFalse);
    controller.redo();
    expect(controller.selectedPhoto!.transform.scale, 2);
    await controller.saveNow();
  });

  test('redo restores a valid photo selection after removal', () {
    final controller = CollageEditorController(
        initialProject: _project(), repository: _Projects());
    addTearDown(controller.dispose);
    controller.removeSelected();
    controller.undo();
    controller.selectPhoto('photo-0');
    controller.redo();
    expect(controller.selectedPhoto?.id, 'photo-1');
  });

  testWidgets(
      'back waits for save, blocks repeat back, and retains failed edits',
      (tester) async {
    await withRealImageIo(tester, () async {
      final repository = _Projects()..fail = true;
      final container = _container(repository);
      addTearDown(container.dispose);
      final project = _project();
      await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: _app(Builder(
              builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                              builder: (_) => EditorPage(project: project))),
                      child: const Text('open')))))));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      container.read(editorControllerProvider(project)).rotateSelected();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(EditorPage), findsOneWidget);
      expect(find.text('Project not saved. Please retry.'), findsOneWidget);
      repository.fail = false;
      repository.pending = Completer<void>();
      final before = repository.saves;
      await tester.pageBack();
      await tester.pump();
      await tester.pageBack();
      await tester.pump();
      expect(repository.saves, before + 1);
      expect(find.byType(EditorPage), findsOneWidget);
      repository.pending!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(EditorPage), findsNothing);
      expect(repository.saved!.photos.first.transform.rotationQuarterTurns, 1);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('project deletion requires confirmation and reports failure',
      (tester) async {
    await withRealImageIo(tester, () async {
      final repository = _Projects()..items = [_project()];
      final container = _container(repository);
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
          container: container, child: _app(const HomePage())));
      await tester.pumpAndSettle();
      Future<void> openDelete() async {
        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();
      }

      await openDelete();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repository.deletes, 0);
      repository.fail = true;
      await openDelete();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(repository.deletes, 1);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(repository.items, hasLength(1));
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets(
      'thumbnail taps select, errors stay usable, and selection is semantic',
      (tester) async {
    await withRealImageIo(tester, () async {
      final semantics = tester.ensureSemantics();

      final controller = CollageEditorController(
          initialProject: _project(), repository: _Projects());
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(Scaffold(
          body: AnimatedBuilder(
              animation: controller,
              builder: (context, child) =>
                  ThumbnailStrip(controller: controller)))));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('photo-1')));
      await tester.pumpAndSettle();
      expect(controller.selectedPhotoId, 'photo-1');
      expect(
          tester
              .getSemantics(find.bySemanticsLabel(RegExp(r'^Image 2')))
              .flagsCollection
              .isSelected,
          ui.Tristate.isTrue);
      for (final image in tester.widgetList<Image>(find.byType(Image))) {
        await precacheImage(
            image.image, tester.element(find.byType(Image).first),
            onError: (error, stack) {});
      }
      await tester.pump();
      expect(find.byIcon(Icons.broken_image_outlined), findsNWidgets(2));
      semantics.dispose();
      expect(controller.canUndo, isFalse);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets(
      'divider exposes a 48px target and accessible undoable adjustment',
      (tester) async {
    final semantics = tester.ensureSemantics();

    final controller = CollageEditorController(
        initialProject: _project(), repository: _Projects());
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(Scaffold(
        body: AnimatedBuilder(
            animation: controller,
            builder: (context, child) => SizedBox.square(
                dimension: 300,
                child: CanvasDividerLayer(
                    controller: controller, size: const Size.square(300)))))));
    await tester.pumpAndSettle();
    final divider = controller.editableCanvasLayout!.dividers.single;
    final target = find.byKey(ValueKey('canvas-divider-${divider.id}'));
    expect(tester.getSize(target), const Size.square(48));
    final node = tester.getSemantics(target);
    tester.binding.renderViews.first.owner!.semanticsOwner!
        .performAction(node.id, SemanticsAction.increase);
    await tester.pump();
    expect(controller.editableCanvasLayout!.dividers.single.position,
        closeTo(divider.position + .02, .00001));
    controller.undo();
    expect(controller.project.customLayout, isNull);
    await controller.saveNow();
    semantics.dispose();
  });

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets(
        'editor and sheets fit narrow large text in ${locale.languageCode}',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await withRealImageIo(tester, () async {
        final repository = _Projects();
        final container = _container(repository);
        addTearDown(container.dispose);
        final project = _project();
        await tester.pumpWidget(UncontrolledProviderScope(
            container: container,
            child: _app(EditorPage(project: project),
                locale: locale, scale: 2, dark: true)));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final controller = container.read(editorControllerProvider(project));
        final context = tester.element(find.byType(EditorPage));
        unawaited(showPhotoEditor(context, controller));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(
            ChoiceChip, AppLocalizations(locale).tr('warm')));
        await tester.pump();
        await tester.scrollUntilVisible(
            find.byKey(const ValueKey('filterIntensity')), 160,
            scrollable: find.byType(Scrollable).last);
        final intensity = tester
            .widget<Slider>(find.byKey(const ValueKey('filterIntensity')));
        expect(intensity.onChanged, isNotNull);
        expect(intensity.semanticFormatterCallback!(.5), '50%');
        intensity.onChanged!(.5);
        await tester.pump();
        await tester.tap(
            find.widgetWithText(FilledButton, AppLocalizations(locale).done));
        await tester.pumpAndSettle();
        expect(controller.selectedPhoto!.adjustments.filterIntensity, .5);
        expect(controller.selectedPhoto!.adjustments.preset,
            PhotoFilterPreset.warm);
        controller.undo();
        expect(controller.selectedPhoto!.adjustments.preset,
            PhotoFilterPreset.original);
        unawaited(showTextOverlaySheet(context, controller));
        await tester.pumpAndSettle();
        await tester.tap(find.text(AppLocalizations(locale).addText));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
            find.byWidgetPredicate((widget) => widget is SegmentedButton));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        Navigator.of(tester.element(find.byType(TextField))).pop();
        await tester.pumpAndSettle();
        tester.view.physicalSize = const Size(740, 360);
        await tester.pumpAndSettle();
        expect(tester.getSize(find.byType(CollageCanvas)).height,
            greaterThan(200));
        expect(tester.takeException(), isNull);
      });
    });
  }
}
