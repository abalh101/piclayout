import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:piclayout/core/localization/app_localizations.dart';
import 'package:piclayout/core/localization/translations.dart';
import 'package:piclayout/features/collage_editor/editor_page.dart';
import 'package:piclayout/features/collage_editor/models/photo_asset.dart';
import 'package:piclayout/features/collage_editor/models/photo_metadata.dart';
import 'package:piclayout/features/collage_editor/state/collage_editor_controller.dart';
import 'package:piclayout/features/custom_layouts/state/custom_layout_providers.dart';
import 'package:piclayout/features/layout_recommendations/layout_recommendation_service.dart';
import 'package:piclayout/features/layout_recommendations/photo_metadata_reader.dart';
import 'package:piclayout/features/layout_recommendations/recommended_layouts.dart';
import 'package:piclayout/features/onboarding/onboarding_repository.dart';
import 'package:piclayout/features/photo_import/selection_review_page.dart';
import 'package:piclayout/features/projects/models/collage_project.dart';
import 'package:piclayout/features/projects/state/project_providers.dart';
import 'package:piclayout/features/settings/models/app_settings.dart';
import 'package:piclayout/features/settings/services/settings_repository.dart';
import 'package:piclayout/features/settings/state/settings_controller.dart';
import 'package:piclayout/features/templates/models/design_library.dart';
import 'package:piclayout/features/templates/services/design_library_repository.dart';
import 'package:piclayout/features/templates/state/design_library_providers.dart';
import 'package:piclayout/features/tutorial_tips/tutorial_tip_controller.dart';
import 'support/custom_layout_fixtures.dart';
import 'support/onboarding_fixtures.dart';

const _portrait = PhotoMetadata(width: 80, height: 120);

class _Reader extends PhotoMetadataReader {
  @override
  Future<PhotoMetadata?> read(String path) async => _portrait;
}

class _Settings extends SettingsRepository {
  @override
  Future<AppSettings> load() async => const AppSettings();
}

class _Library extends DesignLibraryRepository {
  @override
  Future<DesignLibrary> load() async => const DesignLibrary();
}

class _Projects extends LayoutMemoryProjects {
  List<XFile>? picked;
  String? ratio;
  @override
  Future<List<CollageProject>> loadProjects() async => [];
  @override
  Future<CollageProject> createFromPickedImages(List<XFile> picked,
      {String aspectRatioId = '9_16'}) async {
    this.picked = picked;
    ratio = aspectRatioId;
    return layoutProject(count: picked.length)
        .copyWith(aspectRatioId: aspectRatioId, photos: [
      for (var i = 0; i < picked.length; i++)
        PhotoAsset(
            id: '$i',
            originalFileName: picked[i].name,
            localPath: picked[i].path,
            metadata: _portrait),
    ]);
  }
}

Widget host(Widget child,
        {Locale locale = const Locale('de'), double scale = 1}) =>
    MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate
      ],
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
      home: child,
    );
void main() {
  late Directory root;
  late List<XFile> files;
  setUpAll(() async {
    root = await Directory.systemTemp.createTemp('recommend_ui');
    files = [];
    for (var i = 0; i < 6; i++) {
      final file = File('${root.path}/photo$i.png');
      await file.writeAsBytes(img.encodePng(img.Image(width: 80, height: 120)));
      files.add(XFile(file.path));
    }
  });
  tearDownAll(() => root.delete(recursive: true));

  testWidgets(
      'Recommendation cards and reasons fit six languages, RTL, large text and a small screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final photos = [
      for (var i = 0; i < 6; i++)
        PhotoAsset(
            id: '$i', originalFileName: '', localPath: '', metadata: _portrait)
    ];
    final recommendations = const LayoutRecommendationService()
        .recommend(photos, targetRatio: 9 / 16);
    for (final locale in AppLocalizations.supportedLocales) {
      String? selected;
      var auto = false;
      await tester.pumpWidget(host(
          Scaffold(
              body: SingleChildScrollView(
                  child: RecommendedLayouts(
            recommendations: recommendations,
            targetRatio: 9 / 16,
            onSelected: (id) => selected = id,
            onAuto: () => auto = true,
          ))),
          locale: locale,
          scale: 1.6));
      await tester.pumpAndSettle();
      expect(Directionality.of(tester.element(find.byType(RecommendedLayouts))),
          locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr);
      await tester.tap(find.byKey(const ValueKey('auto-layout')));
      expect(auto, isTrue);
      await tester.tap(
          find.byKey(ValueKey('recommend-${recommendations.first.layout.id}')));
      expect(selected, recommendations.first.layout.id);
      expect(tester.takeException(), isNull, reason: locale.languageCode);
      await tester.pumpWidget(const SizedBox());
    }
    for (final key in [
      'recRecommended',
      'recAuto',
      'recLoading',
      'recFormat',
      'recPortrait',
      'recLandscape',
      'recSquare',
      'recMixed',
      'recStorySix',
      'recWideHero',
      'recTallHero'
    ]) {
      expect(translations[key], hasLength(6));
      expect(translations[key]!.every((value) => value.isNotEmpty), isTrue);
    }
  });

  testWidgets(
      'Review chooses target and recommended layout; Editor Auto Layout and undo work',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _Projects();
    final container = ProviderContainer(overrides: [
      photoMetadataReaderProvider.overrideWithValue(_Reader()),
      settingsRepositoryProvider.overrideWithValue(_Settings()),
      projectRepositoryProvider.overrideWithValue(repository),
      designLibraryRepositoryProvider.overrideWithValue(_Library()),
      customLayoutRepositoryProvider.overrideWithValue(LayoutMemoryLibrary()),
      onboardingRepositoryProvider.overrideWithValue(MemoryOnboarding(
          value: const OnboardingState(
              completed: true,
              dismissedTips: {'tipPhoto', 'tipZoom', 'tipDrag', 'tipExport'}))),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: host(SelectionReviewPage(files: files))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('16:9'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<RecommendedLayouts>(find.byType(RecommendedLayouts))
            .targetRatio,
        16 / 9);
    await tester.tap(find.text('9:16'));
    await tester.pumpAndSettle();
    final recommendations = tester
        .widget<RecommendedLayouts>(find.byType(RecommendedLayouts))
        .recommendations;
    final chosen = recommendations[1].layout.id;
    final card = find.byKey(ValueKey('recommend-$chosen'));
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create-collage')));
    await tester.pumpAndSettle();
    expect(repository.ratio, '9_16');
    expect(repository.picked!.map((file) => file.path),
        files.map((file) => file.path));
    expect(repository.saved!.layoutTemplateId, chosen);
    final page = tester.widget<EditorPage>(find.byType(EditorPage));
    final controller = container.read(editorControllerProvider(page.project));
    await tester.ensureVisible(find.byKey(const ValueKey('auto-layout')));
    await tester.tap(find.byKey(const ValueKey('auto-layout')));
    await tester.pumpAndSettle();
    expect(
        controller.project.layoutTemplateId, recommendations.first.layout.id);
    await tester.tap(find.byTooltip('Rückgängig'));
    await tester.pumpAndSettle();
    expect(controller.project.layoutTemplateId, chosen);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
