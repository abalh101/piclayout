import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/custom_layout.dart';

class CustomLayoutRepository {
  CustomLayoutRepository({this.directory});
  final Directory? directory;
  Future<void> _pending = Future.value();
  Future<File> _file() async {
    final root = directory ?? await getApplicationDocumentsDirectory();
    await root.create(recursive: true);
    return File('${root.path}/piclayout_custom_layouts.json');
  }

  Future<List<CustomLayout>> load() async {
    final file = await _file();
    if (!await file.exists()) return [];
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return [
      for (final entry in json['layouts'] as List? ?? [])
        if (CustomLayout.tryParse(entry) case final layout?) layout
    ];
  }

  Future<void> save(List<CustomLayout> layouts) {
    final snapshot = List<CustomLayout>.of(layouts);
    final operation = _pending.catchError((Object _) {}).then((_) async {
      final file = await _file();
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(
          jsonEncode({
            'version': 1,
            'layouts': snapshot.map((l) => l.toJson()).toList()
          }),
          flush: true);
      await tmp.rename(file.path);
    });
    _pending = operation;
    return operation;
  }
}
