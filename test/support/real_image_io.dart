import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Native file reads and image decoding need the real event loop. Advancing
/// the widget test's fake clock does not await those operations.
Future<void> withRealImageIo(
    WidgetTester tester, Future<void> Function() body) async {
  await tester.runAsync(() async {
    try {
      await body();
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      tester.binding.imageCache.clear();
      tester.binding.imageCache.clearLiveImages();
    }
  });
}

Future<void> deleteImageFixtureDirectory(
    WidgetTester tester, Directory directory) async {
  final target = p.normalize(directory.absolute.path);
  if (!p.isWithin(p.normalize(Directory.systemTemp.absolute.path), target)) {
    throw ArgumentError(
        'Image fixtures must live inside the system temporary directory');
  }
  await tester.runAsync(() async {
    // Delete files explicitly so any failure identifies the locked file rather
    // than only reporting the parent directory. No cleanup error is ignored.
    for (final entity
        in directory.listSync(recursive: true, followLinks: false)) {
      if (entity is File) await entity.delete();
    }
    await directory.delete(recursive: true);
  });
}
