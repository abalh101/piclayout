import 'dart:io';
import 'package:piclayout/features/settings/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piclayout/app/piclayout_app.dart';
import 'package:piclayout/core/localization/app_localizations.dart';
import 'package:piclayout/core/localization/translations.dart';
import 'package:piclayout/features/export/export_settings.dart';
import 'package:piclayout/features/projects/models/collage_project.dart';
import 'package:piclayout/features/projects/services/project_repository.dart';
import 'package:piclayout/features/projects/state/project_providers.dart';
import 'package:piclayout/features/settings/models/app_settings.dart';
import 'package:piclayout/features/settings/services/problem_report_service.dart';
import 'package:piclayout/features/settings/services/settings_repository.dart';
import 'package:piclayout/features/settings/state/settings_controller.dart';

class MemorySettings extends SettingsRepository {
  AppSettings value = const AppSettings();
  @override
  Future<AppSettings> load() async => value;
  @override
  Future<void> save(AppSettings settings) async {
    value = settings;
  }
}

class EmptyProjects extends ProjectRepository {
  @override
  Future<List<CollageProject>> loadProjects() async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Settings and manual language persist; system language removes override',
      () async {
    final dir = await Directory.systemTemp.createTemp('settings_test');
    addTearDown(() => dir.delete(recursive: true));
    final repository = SettingsRepository(directory: dir);
    expect((await repository.load()).languageCode, isNull);
    const settings = AppSettings(
        languageCode: 'ar',
        aspectRatioId: '4_5',
        exportFormat: ExportFormat.jpeg,
        jpegQuality: 73,
        exportAction: ExportAction.share);
    await repository.save(settings);
    expect((await SettingsRepository(directory: dir).load()).toJson(),
        settings.toJson());
    await repository.save(settings.copyWith(useSystemLanguage: true));
    expect((await repository.load()).languageCode, isNull);
    await File('${dir.path}/settings.json')
        .writeAsString('{"languageCode":"fr"}');
    final legacy = await repository.load();
    expect(legacy.languageCode, 'fr');
    expect(legacy.jpegQuality, 92);
    expect(legacy.aspectRatioId, '9_16');
    expect(
        AppSettings.fromJson({'languageCode': 'xx', 'jpegQuality': 999})
            .languageCode,
        isNull);
    expect(AppSettings.fromJson({'jpegQuality': 999}).jpegQuality, 100);
    await File('${dir.path}/settings.json').writeAsString('broken');
    expect((await repository.load()).toJson(), const AppSettings().toJson());
  });
  test('Concurrent setting writes persist the newest selection', () async {
    final repository = MemorySettings();
    final container = ProviderContainer(
        overrides: [settingsRepositoryProvider.overrideWithValue(repository)]);
    addTearDown(container.dispose);
    await container.read(settingsControllerProvider.future);
    final controller = container.read(settingsControllerProvider.notifier);
    await Future.wait([
      controller.saveSettings(const AppSettings(languageCode: 'de')),
      controller.saveSettings(const AppSettings(languageCode: 'es'))
    ]);
    expect(repository.value.languageCode, 'es');
    expect(
        container.read(settingsControllerProvider).value!.languageCode, 'es');
  });
  test(
      'Mail contains allowed metadata and encoded prompt, no attachments or paths',
      () async {
    Uri? launched;
    final service = ProblemReportService(launch: (uri) async {
      launched = uri;
      return true;
    });
    const metadata = AppMetadata(
        version: '1.2.3+4', platform: 'android', device: 'Android device');
    const prompt = 'Bitte beschreibe hier dein Problem & Details';
    expect(await service.open(metadata, prompt: prompt), isTrue);
    expect(launched!.scheme, 'mailto');
    expect(launched!.path, 'support@example.com');
    expect(launched!.queryParameters.keys, ['subject', 'body']);
    expect(launched!.queryParameters['body'], contains(prompt));
    expect(launched!.queryParameters['body'], contains('1.2.3+4'));
    expect(launched!.queryParameters['body'], contains('android'));
    expect(launched!.queryParameters['body'], contains('PicLayout'));
    for (final forbidden in [
      'attachment',
      'localPath',
      '/private',
      'file:',
      '.jpg'
    ]) {
      expect(launched.toString(), isNot(contains(forbidden)));
    }
    expect(
        await ProblemReportService(launch: (_) async => false)
            .open(metadata, prompt: prompt),
        isFalse);
    expect(
        await ProblemReportService(launch: (_) async => throw Exception())
            .open(metadata, prompt: prompt),
        isFalse);
  });
  test('Cache cleaning leaves photos and unrelated temporary files intact',
      () async {
    final dir = await Directory.systemTemp.createTemp('cache_test');
    addTearDown(() => dir.delete(recursive: true));
    final exports = Directory('${dir.path}/piclayout_exports');
    await exports.create();
    await File('${exports.path}/image.jpg').writeAsString('export');
    final original = File('${dir.path}/original.jpg');
    await original.writeAsString('original');
    await ExportCache(directory: dir).clear();
    await ExportCache(directory: dir).clear();
    expect(await exports.exists(), isFalse);
    expect(await original.readAsString(), 'original');
  });
  test('Every translation has six nonempty languages', () {
    for (final entry in translations.entries) {
      expect(entry.value, hasLength(6), reason: entry.key);
      expect(entry.value.every((value) => value.isNotEmpty), isTrue);
    }
  });
  testWidgets(
      'Manual locale changes immediately, Arabic is RTL, system restores device locale',
      (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('tr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final repository = MemorySettings();
    final container = ProviderContainer(overrides: [
      settingsRepositoryProvider.overrideWithValue(repository),
      projectRepositoryProvider.overrideWithValue(EmptyProjects())
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const PicLayoutApp()));
    await tester.pumpAndSettle();
    BuildContext context() => tester.element(find.byType(Scaffold).first);
    expect(Localizations.localeOf(context()).languageCode, 'tr');
    await container
        .read(settingsControllerProvider.notifier)
        .saveSettings(const AppSettings(languageCode: 'ar'));
    await tester.pumpAndSettle();
    expect(Directionality.of(context()), TextDirection.rtl);
    expect(AppLocalizations.of(context()).settings, 'الإعدادات');
    await container
        .read(settingsControllerProvider.notifier)
        .saveSettings(const AppSettings());
    await tester.pumpAndSettle();
    expect(Localizations.localeOf(context()).languageCode, 'tr');
    expect(Directionality.of(context()), TextDirection.ltr);
  });
  testWidgets(
      'Settings language picker and missing-mail fallback work on a small screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = MemorySettings()
      ..value = const AppSettings(languageCode: 'de');
    final container = ProviderContainer(overrides: [
      settingsRepositoryProvider.overrideWithValue(repository),
      projectRepositoryProvider.overrideWithValue(EmptyProjects()),
      appMetadataProvider.overrideWith((ref) async => const AppMetadata(
          version: '1.0+1', platform: 'android', device: 'Android device')),
      problemReportServiceProvider
          .overrideWithValue(ProblemReportService(launch: (_) async => false)),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const PicLayoutApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Einstellungen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('العربية').last);
    await tester.pumpAndSettle();
    expect(repository.value.languageCode, 'ar');
    expect(Directionality.of(tester.element(find.byType(SettingsPage))),
        TextDirection.rtl);
    await tester.tap(find.text('الإبلاغ عن مشكلة'));
    await tester.pumpAndSettle();
    expect(find.text('support@example.com'), findsOneWidget);
    expect(find.text('نسخ'), findsOneWidget);
    await tester.tap(find.text('تم'));
    await tester.pumpAndSettle();
    for (final language in AppSettings.languages) {
      await container
          .read(settingsControllerProvider.notifier)
          .saveSettings(AppSettings(languageCode: language));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      // Framework reports any layout failures.
    }
  });
}
