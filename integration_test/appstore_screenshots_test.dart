import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:piclayout/core/localization/app_localizations.dart';
import 'package:piclayout/features/demo_projects/demo_project_factory.dart';
import 'package:piclayout/features/projects/services/project_repository.dart';
import 'package:piclayout/features/settings/models/app_settings.dart';
import 'package:piclayout/features/settings/services/settings_repository.dart';
import 'package:piclayout/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Capture ten PicLayout screens from the iOS app', (tester) async {
    const locale =
        String.fromEnvironment('SCREENSHOT_LOCALE', defaultValue: 'en');
    final strings = AppLocalizations(const Locale(locale));
    final t = strings.tr;
    final directory = Directory(
        '${(await getApplicationDocumentsDirectory()).path}/appstore-captures');
    if (await directory.exists()) await directory.delete(recursive: true);
    await directory.create();
    await SettingsRepository().save(const AppSettings()
        .copyWith(languageCode: locale, useSystemLanguage: false));

    final factory = DemoProjectFactory(ProjectRepository());
    for (final index in [2, 0, 4]) {
      final design = DemoProjectFactory.designs[index];
      await factory.createCopy(design, name: t(design.key));
    }

    Future<void> settle() => tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 20));

    Future<void> tap(Finder finder) async {
      expect(finder, findsOneWidget);
      await tester.ensureVisible(finder);
      await settle();
      expect(finder.hitTestable(), findsOneWidget);
      await tester.tap(finder);
      await settle();
    }

    Future<void> capture(String name) async {
      await settle();
      expect(tester.takeException(), isNull);
      final png = await binding.takeScreenshot(name);
      binding.reportData?.remove('screenshots');
      final captured = img.decodePng(Uint8List.fromList(png))!;
      final rgb = img.encodePng(captured.convert(numChannels: 3));
      await File('${directory.path}/$name.png').writeAsBytes(rgb, flush: true);
    }

    Future<void> closePanel() async {
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await settle();
    }

    app.main();
    await settle();
    await tap(find.byKey(const ValueKey('onboarding-skip')));
    expect(find.text(strings.recentProjects), findsOneWidget);
    final story = t('demoStory');
    await capture('01-home-projects');
    await tap(find.text(story));
    expect(find.text(story), findsWidgets);
    await capture('02-grid-collage');

    await tap(find.widgetWithText(ChoiceChip, t('freestyleMode')));
    await capture('03-freestyle-collage');
    await tap(find.widgetWithText(ChoiceChip, t('gridMode')));

    await tap(find.byKey(const ValueKey('open-layout-builder')));
    expect(find.byKey(const ValueKey('layout-builder-canvas')), findsOneWidget);
    await capture('04-custom-layout');
    await closePanel();

    await tap(find.byKey(const ValueKey('photo-adjustments')));
    expect(find.byType(FilterChip), findsWidgets);
    await capture('05-photo-adjustments');
    await closePanel();

    await tap(find.widgetWithText(OutlinedButton, t('projectLayers')));
    expect(find.text(t('layers')).hitTestable(), findsOneWidget);
    await capture('06-text-stickers');
    await closePanel();

    final autoLayout = find.byKey(const ValueKey('auto-layout'));
    await tester.ensureVisible(autoLayout);
    await settle();
    expect(autoLayout.hitTestable(), findsOneWidget);
    await capture('07-smart-auto-layout');

    await tap(find.widgetWithText(OutlinedButton, strings.style));
    await capture('08-style-studio');
    await closePanel();

    await tap(find.widgetWithText(OutlinedButton, strings.myTemplates));
    expect(find.text(t('builtInTemplates')), findsOneWidget);
    await capture('10-design-templates');
    await closePanel();

    await tap(find.byTooltip(strings.export));
    expect(find.text('PNG'), findsOneWidget);
    await capture('09-export-center');
  });
}
