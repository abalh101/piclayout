import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../services/settings_repository.dart';

final settingsRepositoryProvider = Provider((ref) => SettingsRepository());
final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, AppSettings>(
        SettingsController.new);

class SettingsController extends AsyncNotifier<AppSettings> {
  Future<void> _pending = Future.value();
  AppSettings _persisted = const AppSettings();
  @override
  Future<AppSettings> build() async {
    _persisted = await ref.read(settingsRepositoryProvider).load();
    return _persisted;
  }

  Future<void> saveSettings(AppSettings settings) {
    state = AsyncData(settings);
    // Serialize writes so quick changes cannot overwrite newer preferences.
    final operation = _pending.then((_) async {
      try {
        await ref.read(settingsRepositoryProvider).save(settings);
        _persisted = settings;
      } catch (_) {
        if (identical(state.value, settings)) state = AsyncData(_persisted);
        rethrow;
      }
    });
    _pending = operation.catchError((Object _) {});
    return operation;
  }
}
