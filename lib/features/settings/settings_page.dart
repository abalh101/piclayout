import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.settings)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Icon(
              Icons.lock_outline,
              size: 44,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              strings.localPrivacyNote,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Card(
              child: ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Deutsch / English'),
                subtitle: Text(
                  Localizations.localeOf(context).languageCode == 'de'
                      ? 'Gerätesprache wird verwendet'
                      : 'Device language is used',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
