import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'package:piclayout/core/localization/app_localizations.dart';
import 'package:piclayout/features/home/home_page.dart';
import 'package:piclayout/features/projects/models/collage_project.dart';
import 'package:piclayout/features/projects/services/project_repository.dart';
import 'package:piclayout/features/projects/state/project_providers.dart';
import 'package:piclayout/features/project_archive/project_archive_controller.dart';
import 'package:piclayout/features/project_archive/project_archive_service.dart';
import 'support/custom_layout_fixtures.dart';

class _Repository extends ProjectRepository {
  List<CollageProject> projects = [];
  @override
  Future<List<CollageProject>> loadProjects() async => projects;
}

class _Platform implements ProjectArchivePlatform {
  @override
  Future<XFile?> pickProject() async => null;
  @override
  Future<void> shareProject(File file, Rect origin) async {}
}

class _Controller extends ProjectArchiveController {
  _Controller(this.repository)
      : super(
            platform: _Platform(),
            service: () async => throw UnimplementedError());
  final _Repository repository;
  CollageProject? exported;
  Rect? origin;
  String? error;
  bool cancelled = false;
  @override
  Future<CollageProject?> importProject() async {
    if (error != null) throw ProjectArchiveException(error!);
    if (cancelled) return null;
    final project = layoutProject().copyWith(name: 'Backup', photos: []);
    repository.projects = [project];
    return project;
  }

  @override
  Future<void> exportProject(CollageProject project, Rect origin) async {
    exported = project;
    this.origin = origin;
  }
}

void main() {
  testWidgets(
      'Home import, cancellation/errors and project sharing work in six languages on small screens',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final locale in AppLocalizations.supportedLocales) {
      final repository = _Repository();
      final controller = _Controller(repository);
      final container = ProviderContainer(overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectArchiveControllerProvider.overrideWith((_) => controller),
      ]);
      final t = AppLocalizations(locale).tr;
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
              theme: ThemeData(brightness: Brightness.dark),
              home: const HomePage())));
      await tester.pumpAndSettle();
      controller.cancelled = true;
      await tester.tap(find.byKey(const ValueKey('import-project')));
      await tester.pumpAndSettle();
      expect(find.text(t('archiveCancelled')), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      controller.cancelled = false;
      controller.error = 'archiveNoSpace';
      await tester.tap(find.byKey(const ValueKey('import-project')));
      await tester.pumpAndSettle();
      expect(find.text(t('archiveNoSpace')), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      controller.error = null;
      await tester.tap(find.byKey(const ValueKey('import-project')));
      await tester.pumpAndSettle();
      expect(find.text(t('archiveImported')), findsOneWidget);
      expect(find.text('Backup'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(PopupMenuButton<String>));
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t('archiveExport')));
      await tester.pumpAndSettle();
      expect(controller.exported!.name, 'Backup');
      expect(controller.origin!.width, greaterThan(0));
      expect(tester.takeException(), isNull, reason: locale.languageCode);
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    }
  });
}
