import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/settings/state/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_theme.dart';
import '../features/home/home_page.dart';
import 'app_config.dart';

class PicLayoutApp extends ConsumerWidget {
  const PicLayoutApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode =
        ref.watch(settingsControllerProvider).value?.languageCode;
    return MaterialApp(
      title: AppConfig.appName,
      locale: languageCode == null ? null : Locale(languageCode),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomePage(),
    );
  }
}
