import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piclayout/app/piclayout_app.dart';
import 'package:piclayout/core/localization/app_localizations.dart';
import 'package:piclayout/core/localization/translations.dart';
import 'package:piclayout/features/demo_projects/demo_projects_page.dart';
import 'package:piclayout/features/home/home_page.dart';
import 'package:piclayout/features/onboarding/onboarding_page.dart';
import 'package:piclayout/features/onboarding/onboarding_repository.dart';
import 'package:piclayout/features/projects/models/collage_project.dart';
import 'package:piclayout/features/projects/services/project_repository.dart';
import 'package:piclayout/features/projects/state/project_providers.dart';
import 'package:piclayout/features/settings/models/app_settings.dart';
import 'package:piclayout/features/settings/services/settings_repository.dart';
import 'package:piclayout/features/settings/state/settings_controller.dart';
import 'package:piclayout/features/tutorial_tips/tutorial_tip.dart';
import 'package:piclayout/features/tutorial_tips/tutorial_tip_controller.dart';
import 'support/onboarding_fixtures.dart';

class _Settings extends SettingsRepository {
  @override
  Future<AppSettings> load() async => const AppSettings(languageCode: 'de');
}

class _Projects extends ProjectRepository {
  @override
  Future<List<CollageProject>> loadProjects() async => [];
}

ProviderContainer _container(MemoryOnboarding repository) =>
    ProviderContainer(overrides: [
      onboardingRepositoryProvider.overrideWithValue(repository),
      settingsRepositoryProvider.overrideWithValue(_Settings()),
      projectRepositoryProvider.overrideWithValue(_Projects()),
    ]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'Introduction and dismissed hints survive a fresh repository; malformed data recovers',
      () async {
    final dir = await Directory.systemTemp.createTemp('intro_test');
    addTearDown(() => dir.delete(recursive: true));
    final repository = OnboardingRepository(directory: dir);
    expect((await repository.load()).completed, isFalse);
    await repository.save(const OnboardingState(
        completed: true,
        tipViews: {'tipPhoto': 2},
        dismissedTips: {'tipZoom'}));
    final restored = await OnboardingRepository(directory: dir).load();
    expect(restored.completed, isTrue);
    expect(restored.canShow('tipPhoto'), isFalse);
    expect(restored.canShow('tipZoom'), isFalse);
    await File('${dir.path}/onboarding.json').writeAsString('{broken');
    expect((await repository.load()).completed, isFalse);
  });
  test(
      'Hints are shown at most twice; dismiss and reset persist without resetting onboarding',
      () async {
    final repository = MemoryOnboarding();
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(tutorialTipControllerProvider.future);
    final controller = container.read(tutorialTipControllerProvider.notifier);
    await controller.complete();
    expect(
        await Future.wait([
          controller.claim('tipPhoto'),
          controller.claim('tipPhoto'),
          controller.claim('tipPhoto')
        ]),
        [true, true, false]);
    await controller.dismiss('tipZoom');
    expect(await controller.claim('tipZoom'), isFalse);
    await controller.resetTips();
    expect(repository.value.completed, isTrue);
    expect(repository.value.dismissedTips, isEmpty);
    expect(await controller.claim('tipZoom'), isTrue);
    repository.failSave = true;
    await expectLater(controller.dismiss('tipDrag'), throwsStateError);
    expect(
        container
            .read(tutorialTipControllerProvider)
            .requireValue
            .canShow('tipDrag'),
        isTrue);
    repository.failSave = false;
    await controller.dismiss('tipDrag');
    expect(repository.value.canShow('tipDrag'), isFalse);
  });
  testWidgets(
      'First launch completes all pages, restart skips intro, Settings replays and resets tips',
      (tester) async {
    final repository = MemoryOnboarding();
    var container = _container(repository);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const PicLayoutApp()));
    await tester.pumpAndSettle();
    expect(find.text('Willkommen bei PicLayout'), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byKey(const ValueKey('onboarding-next')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const ValueKey('onboarding-start')));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    expect(repository.value.completed, isTrue);
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    container = _container(repository);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const PicLayoutApp()));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingPage), findsNothing);
    await tester.tap(find.byTooltip('Einstellungen'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('replay-onboarding')));
    await tester.pumpAndSettle();
    expect(find.text('Willkommen bei PicLayout'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding-skip')));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingPage), findsNothing);
    await container
        .read(tutorialTipControllerProvider.notifier)
        .dismiss('tipPhoto');
    await tester.ensureVisible(find.byKey(const ValueKey('reset-tips')));
    await tester.tap(find.byKey(const ValueKey('reset-tips')));
    await tester.pumpAndSettle();
    expect(repository.value.canShow('tipPhoto'), isTrue);
    expect(repository.value.completed, isTrue);
  });
  testWidgets(
      'Final demo action completes onboarding and opens the five examples',
      (tester) async {
    final repository = MemoryOnboarding();
    final container = _container(repository);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const PicLayoutApp()));
    await tester.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byKey(const ValueKey('onboarding-next')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const ValueKey('onboarding-demo')));
    await tester.pumpAndSettle();
    expect(find.byType(DemoProjectsPage), findsOneWidget);
    expect(repository.value.completed, isTrue);
    expect(find.text('Instagram Story Collage'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'A dismissed hint stays hidden when remounted and returns after reset',
      (tester) async {
    final container = _container(MemoryOnboarding());
    addTearDown(container.dispose);
    Widget app(Widget child) => UncontrolledProviderScope(
        container: container, child: MaterialApp(home: Scaffold(body: child)));
    await tester.pumpWidget(app(const TutorialTip(id: 'tipPhoto')));
    await tester.pumpAndSettle();
    expect(
        find.text('Tippe ein Foto an, um es zu bearbeiten.'), findsOneWidget);
    await tester.tap(find.byTooltip('Schließen'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(app(const SizedBox()));
    await tester.pumpWidget(app(const TutorialTip(id: 'tipPhoto')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.lightbulb_outline), findsNothing);
    await container.read(tutorialTipControllerProvider.notifier).resetTips();
    await tester.pumpWidget(app(const SizedBox()));
    await tester.pumpWidget(app(const TutorialTip(id: 'tipPhoto')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
  });
  testWidgets(
      'All five onboarding pages fit six languages, dark mode, large text and RTL',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final locale in AppLocalizations.supportedLocales) {
      final container = _container(MemoryOnboarding());
      await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate
            ],
            theme: ThemeData.dark(),
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.6)),
                child: child!),
            home: OnboardingPage(onFinished: (_) {}),
          )));
      await tester.pumpAndSettle();
      expect(Directionality.of(tester.element(find.byType(OnboardingPage))),
          locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr);
      for (var i = 0; i < 4; i++) {
        expect(tester.takeException(), isNull,
            reason: '${locale.languageCode}: $i');
        await tester.tap(find.byKey(const ValueKey('onboarding-next')));
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const ValueKey('onboarding-demo')), findsOneWidget);
      tester.view.physicalSize = const Size(640, 320);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('onboarding-demo')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: 'landscape ${locale.languageCode}');
      tester.view.physicalSize = const Size(320, 640);
      expect(tester.takeException(), isNull, reason: locale.languageCode);
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    }
    for (final entry in translations.entries
        .where((e) => RegExp(r'^(intro|demo|tip)').hasMatch(e.key))) {
      expect(entry.value.length, 6, reason: entry.key);
      expect(entry.value.every((s) => s.trim().isNotEmpty), isTrue,
          reason: entry.key);
    }
  });
}
