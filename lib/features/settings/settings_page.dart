import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/app_config.dart';
import '../../core/localization/app_localizations.dart';
import '../collage_editor/models/aspect_ratio_preset.dart';
import '../export/export_settings.dart';
import 'models/app_settings.dart';
import 'services/problem_report_service.dart';
import 'services/settings_repository.dart';
import 'state/settings_controller.dart';

final problemReportServiceProvider = Provider((ref) => ProblemReportService());

final appMetadataProvider = FutureProvider((ref) => AppMetadata.load());

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final t = strings.tr;
    final metadata = ref.watch(appMetadataProvider);
    Future<void> update(AppSettings value) async {
      try {
        await ref.read(settingsControllerProvider.notifier).saveSettings(value);
      } catch (_) {
        if (context.mounted) {
          _notice(context, t('settingsError'));
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(strings.settings)),
      body: SafeArea(
          child: ref.watch(settingsControllerProvider).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                    child: TextButton(
                        onPressed: () =>
                            ref.invalidate(settingsControllerProvider),
                        child: Text('${t('settingsError')} ${t('retry')}'))),
                data: (settings) =>
                    ListView(padding: const EdgeInsets.all(20), children: [
                  _choice<String>(
                      t('language'),
                      settings.languageCode ?? 'system',
                      {
                        'system': t('systemLanguage'),
                        'de': 'Deutsch',
                        'en': 'English',
                        'ar': 'العربية',
                        'tr': 'Türkçe',
                        'fr': 'Français',
                        'es': 'Español',
                      },
                      (value) => update(settings.copyWith(
                          languageCode: value,
                          useSystemLanguage: value == 'system'))),
                  ListTile(
                      leading: const Icon(Icons.mail_outline),
                      title: Text(t('reportProblem')),
                      onTap: () async {
                        final service = ref.read(problemReportServiceProvider);
                        final info = await ref
                            .read(appMetadataProvider.future)
                            .catchError((Object _) => const AppMetadata(
                                version: '—', platform: '—', device: '—'));
                        final opened =
                            await service.open(info, prompt: t('reportPrompt'));
                        if (!opened && context.mounted) {
                          await showDialog<void>(
                              context: context,
                              builder: (context) => AlertDialog(
                                    title: Text(t('reportProblem')),
                                    content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(t('noMail')),
                                          const SizedBox(height: 12),
                                          const SelectableText(
                                              AppConfig.supportEmail)
                                        ]),
                                    actions: [
                                      TextButton(
                                          onPressed: () async {
                                            await Clipboard.setData(
                                                const ClipboardData(
                                                    text: AppConfig
                                                        .supportEmail));
                                            if (context.mounted) {
                                              _notice(context, t('copied'));
                                            }
                                          },
                                          child: Text(t('copy'))),
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text(strings.done))
                                    ],
                                  ));
                        }
                      }),
                  const Divider(),
                  Text(t('defaults'),
                      style: Theme.of(context).textTheme.titleMedium),
                  _choice<String>(
                      t('defaultRatio'),
                      settings.aspectRatioId,
                      {
                        for (final ratio in AspectRatios.all)
                          ratio.id: ratio.label
                      },
                      (value) =>
                          update(settings.copyWith(aspectRatioId: value))),
                  _choice<ExportFormat>(
                      strings.format,
                      settings.exportFormat,
                      {ExportFormat.png: 'PNG', ExportFormat.jpeg: 'JPEG'},
                      (value) =>
                          update(settings.copyWith(exportFormat: value))),
                  ListTile(
                      title: Text(t('jpegQuality')),
                      subtitle: Slider(
                          value: settings.jpegQuality.toDouble(),
                          min: 1,
                          max: 100,
                          divisions: 99,
                          label: '${settings.jpegQuality}',
                          onChanged: (value) => update(
                              settings.copyWith(jpegQuality: value.round()))),
                      trailing: Text('${settings.jpegQuality}%')),
                  _choice<ExportAction>(
                      t('defaultAction'),
                      settings.exportAction,
                      {
                        ExportAction.gallery: t('gallery'),
                        ExportAction.share: strings.share
                      },
                      (value) =>
                          update(settings.copyWith(exportAction: value))),
                  ListTile(
                      leading: const Icon(Icons.cleaning_services_outlined),
                      title: Text(t('clearCache')),
                      onTap: () async {
                        try {
                          await ExportCache().clear();
                          if (context.mounted) {
                            _notice(context, t('cacheCleared'));
                          }
                        } catch (_) {
                          if (context.mounted) {
                            _notice(context, t('operationFailed'));
                          }
                        }
                      }),
                  const Divider(),
                  ExpansionTile(title: Text(t('privacy')), children: [
                    Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(strings.localPrivacyNote))
                  ]),
                  ListTile(
                      title: Text(t('version')),
                      subtitle: Text(metadata.value?.version ?? '—')),
                  ExpansionTile(title: Text(t('about')), children: [
                    Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(t('aboutBody')))
                  ]),
                ]),
              )),
    );
  }

  Widget _choice<T>(String title, T value, Map<T, String> choices,
          ValueChanged<T> changed) =>
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: DropdownButtonFormField<T>(
              initialValue: value,
              key: ValueKey('$title:$value'),
              isExpanded: true,
              decoration: InputDecoration(labelText: title),
              items: [
                for (final entry in choices.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value))
              ],
              onChanged: (value) {
                if (value != null) changed(value);
              }));
  static void _notice(BuildContext context, String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
