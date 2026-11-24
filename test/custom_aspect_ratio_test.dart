import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piclayout/core/localization/app_localizations.dart';
import 'package:piclayout/features/collage_editor/models/aspect_ratio_preset.dart';
import 'package:piclayout/features/collage_editor/state/collage_editor_controller.dart';
import 'package:piclayout/features/collage_editor/widgets/custom_aspect_ratio_dialog.dart';
import 'package:piclayout/features/projects/models/collage_project.dart';
import 'package:piclayout/features/templates/models/collage_template.dart';
import 'package:piclayout/features/templates/models/design_library.dart';
import 'package:piclayout/features/templates/services/design_library_repository.dart';
import 'package:piclayout/features/templates/state/design_library_providers.dart';

import 'support/custom_layout_fixtures.dart';

class _FailedLibrary extends DesignLibraryRepository {
  @override
  Future<DesignLibrary> load() async => const DesignLibrary();
  @override
  Future<void> save(DesignLibrary library) async =>
      throw const FileSystemException('write failed');
}

void main() {
  test(
      'Failed ratio persistence reports an error without keeping an unsaved entry',
      () async {
    final notifier = DesignLibraryNotifier(_FailedLibrary());
    addTearDown(notifier.dispose);
    await expectLater(notifier.saveAspectRatio(AspectRatios.parse('3', '2')),
        throwsA(isA<FileSystemException>()));
    expect(notifier.state.value!.aspectRatios, isEmpty);
    await expectLater(notifier.saveAspectRatio(AspectRatios.parse('21', '9')),
        throwsA(isA<FileSystemException>()));
    expect(notifier.state.value!.aspectRatios, isEmpty);
  });
  test(
      'Custom dimensions normalize, preserve presets and reject invalid inputs',
      () {
    expect(AspectRatios.parse('4', '5'), same(AspectRatios.byId('4_5')));
    expect(AspectRatios.parse('1920', '1080'), same(AspectRatios.byId('16_9')));
    expect(AspectRatios.parse('1,5', '1').id, 'custom_3_2');
    expect(AspectRatios.parse('21', '9').value, 21 / 9);
    expect(AspectRatios.byId('custom_7_3').value, 21 / 9);
    expect(AspectRatios.byId('custom_0_0'), same(AspectRatios.story));
    for (final value in [
      '0',
      '-1',
      'NaN',
      'Infinity',
      '1e3',
      '1.0001',
      '',
      '1000001'
    ]) {
      expect(() => AspectRatios.parse(value, '1'), throwsFormatException);
      expect(() => AspectRatios.parse('1', value), throwsFormatException);
    }
    expect(() => AspectRatios.parse('9', '1'), throwsFormatException);
    for (final ratio in [
      AspectRatios.parse('1', '8'),
      AspectRatios.parse('8', '1')
    ]) {
      for (final size in ratio.exportSizes()) {
        expect(size.width, inInclusiveRange(1, 8192));
        expect(size.height, inInclusiveRange(1, 8192));
        expect(size.width / size.height, closeTo(ratio.value, .005));
      }
      expect(ratio.exportSizes().map((size) => size.label).toSet().length,
          ratio.exportSizes().length);
    }
  });

  test(
      'Saved ratios reload, deduplicate, survive projects/templates and legacy JSON',
      () async {
    final dir = await Directory.systemTemp.createTemp('custom_ratio_test_');
    addTearDown(() => dir.delete(recursive: true));
    final repo = DesignLibraryRepository(documentsDirectory: dir);
    final notifier = DesignLibraryNotifier(repo);
    addTearDown(notifier.dispose);
    final ratio = AspectRatios.parse('3', '2');
    await notifier.saveAspectRatio(ratio);
    await notifier.saveAspectRatio(AspectRatios.parse('300', '200'));
    await notifier.saveAspectRatio(AspectRatios.story);
    expect((await repo.load()).aspectRatios.single.id, ratio.id);
    await Future.wait([
      notifier.saveAspectRatio(AspectRatios.parse('21', '9')),
      notifier.saveAspectRatio(AspectRatios.parse('2', '3')),
    ]);
    expect((await repo.load()).aspectRatios, hasLength(3));
    expect(DesignLibrary.fromJson({}).aspectRatios, isEmpty);
    expect(DesignLibrary.fromJson({'aspectRatios': 'broken'}).aspectRatios,
        isEmpty);
    expect(
        DesignLibrary.fromJson({
          'aspectRatios': ['custom_0_0', 42]
        }).aspectRatios,
        isEmpty);
    final project = layoutProject(count: 1).copyWith(aspectRatioId: ratio.id);
    expect(CollageProject.fromJson(project.toJson()).aspectRatio.value, 1.5);
    final template = CollageTemplate.fromProject(
        id: 'template',
        name: 'Custom',
        project: project,
        includeTextOverlays: false);
    expect(
        CollageTemplate.fromJson(template.toJson())
            .applyTo(layoutProject(count: 1))
            .aspectRatio
            .value,
        1.5);
  });

  testWidgets('Ratio changes group into undo/redo and autosave',
      (tester) async {
    final repo = LayoutMemoryProjects();
    final controller = CollageEditorController(
        initialProject: layoutProject(count: 1), repository: repo);
    addTearDown(controller.dispose);
    final ratio = AspectRatios.parse('21', '9');
    controller.setAspectRatio(ratio);
    expect(controller.project.aspectRatio.value, 21 / 9);
    await tester.pump(const Duration(milliseconds: 701));
    expect(repo.saved!.aspectRatioId, ratio.id);
    controller.undo();
    expect(controller.project.aspectRatioId, '1_1');
    await controller.saveNow();
    controller.redo();
    expect(controller.project.aspectRatioId, ratio.id);
    controller.setAspectRatio(ratio);
    controller.undo();
    expect(controller.project.aspectRatioId, '1_1');
    await controller.saveNow();
  });

  testWidgets('Dialog validates free dimensions and works in all languages',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final locale in AppLocalizations.supportedLocales) {
      AspectRatioPreset? selected;
      await tester.pumpWidget(MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate
          ],
          home: Scaffold(
              body: Builder(
                  builder: (context) => TextButton(
                      onPressed: () async {
                        selected = await showCustomAspectRatioDialog(context);
                      },
                      child: const Text('Open'))))));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const ValueKey('ratio-ratioWidth')), '0');
      await tester.enterText(
          find.byKey(const ValueKey('ratio-ratioHeight')), '2');
      await tester.tap(find.byKey(const ValueKey('save-ratio')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(selected, isNull);
      await tester.enterText(
          find.byKey(const ValueKey('ratio-ratioWidth')), '3');
      await tester.tap(find.byKey(const ValueKey('save-ratio')));
      await tester.pumpAndSettle();
      expect(selected!.id, 'custom_3_2');
      expect(tester.takeException(), isNull);
    }
  });
}
