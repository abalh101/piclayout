import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/design_library.dart';

class DesignLibraryRepository {
  DesignLibraryRepository({Directory? documentsDirectory})
      : _documentsDirectory = documentsDirectory;

  final Directory? _documentsDirectory;
  Future<void> _pendingWrite = Future<void>.value();

  Future<DesignLibrary> load() async {
    final file = await _file();
    if (!await file.exists()) return const DesignLibrary();
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return DesignLibrary.fromJson(json);
  }

  Future<void> save(DesignLibrary library) {
    final pending = _pendingWrite.catchError((Object _) {}).then((_) async {
      final file = await _file();
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(
        const JsonEncoder.withIndent('  ').convert(library.toJson()),
        flush: true,
      );
      if (await file.exists()) await file.delete();
      await temporary.rename(file.path);
    });
    _pendingWrite = pending;
    return pending;
  }

  Future<File> _file() async {
    final documents =
        _documentsDirectory ?? await getApplicationDocumentsDirectory();
    await documents.create(recursive: true);
    return File(p.join(documents.path, 'piclayout_design_library.json'));
  }
}
