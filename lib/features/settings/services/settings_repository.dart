import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/app_settings.dart';

class SettingsRepository {
  SettingsRepository({this.directory});
  final Directory? directory;
  Future<File> _file() async => File(
      '${(directory ?? await getApplicationSupportDirectory()).path}/settings.json');
  Future<AppSettings> load() async {
    final file = await _file();
    if (!await file.exists()) return const AppSettings();
    try {
      return AppSettings.fromJson(
          jsonDecode(await file.readAsString()) as Map<String, dynamic>);
    } on FormatException {
      return const AppSettings();
    } on TypeError {
      return const AppSettings();
    }
  }

  Future<void> save(AppSettings settings) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    final pending = File('${file.path}.tmp');
    await pending.writeAsString(jsonEncode(settings.toJson()), flush: true);
    await pending.rename(file.path);
  }
}

/// Removes only files owned by the export pipeline, never imported photos.
class ExportCache {
  ExportCache({this.directory});
  final Directory? directory;
  Future<void> clear() async {
    final root = directory ?? await getTemporaryDirectory();
    final exports = Directory('${root.path}/piclayout_exports');
    if (await exports.exists()) await exports.delete(recursive: true);
  }
}
