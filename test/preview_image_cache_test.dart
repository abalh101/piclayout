import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:piclayout/features/collage_editor/rendering/project_image_loader.dart';
import 'package:piclayout/features/collage_editor/rendering/preview_image_cache.dart';

Future<ui.Image> tinyImage() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawColor(const ui.Color(0xFFABCDEF), ui.BlendMode.src);
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(2, 2);
  } finally {
    picture.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('export decode caps source pixels while keeping original crop geometry',
      () async {
    final root = await Directory.systemTemp.createTemp('piclayout-decode-');
    addTearDown(() => root.delete(recursive: true));
    final file = await File('${root.path}/source.png')
        .writeAsBytes(img.encodePng(img.Image(width: 600, height: 400)));
    ui.Size? sourceSize;
    final image = await loadProjectImage(file.path,
        maxPixels: 60000,
        usefulEdge: (_) => 2000,
        onSourceSize: (size) => sourceSize = size);
    try {
      expect(sourceSize, const ui.Size(600, 400));
      expect((image.width, image.height), (300, 200));
    } finally {
      image.dispose();
    }
  });

  test(
      'Canvas and sheet share one bounded source; chrome and adjustment changes need no decode',
      () async {
    var decodes = 0;
    final cache =
        PreviewImageCache(decode: (path, {maxEdge, onSourceSize}) async {
      decodes++;
      expect(maxEdge, 1024);
      onSourceSize?.call(const ui.Size(4000, 3000));
      return tinyImage();
    });
    final canvas = cache.acquire('same-source');
    final sheet = cache.acquire('same-source');
    expect(identical(await canvas.image, await sheet.image), isTrue);
    expect(decodes, 1);
    expect(cache.sourceCount, 1);
    // Rebuilding/changing effects does not participate in the source cache key.
    for (var i = 0; i < 20; i++) {
      final lease = cache.acquire('same-source');
      expect(identical(await lease.image, await canvas.image), isTrue);
      lease.release();
    }
    expect(decodes, 1);
    canvas.release();
    expect(cache.sourceCount, 1);
    expect(sheet.sourceSize, const ui.Size(4000, 3000));
    sheet.release();
    sheet.release();
    expect(cache.sourceCount, 0);
  });
  test(
      'At most two decodes; removed queued and disposed in-flight sources release safely',
      () async {
    final pending = <Completer<ui.Image>>[];
    final cache = PreviewImageCache(decode: (path, {maxEdge, onSourceSize}) {
      final completer = Completer<ui.Image>();
      pending.add(completer);
      return completer.future;
    });
    final first = cache.acquire('one');
    final second = cache.acquire('two');
    final third = cache.acquire('three');
    expect(pending.length, 2);
    first.release();
    third.release();
    pending.first.complete(await tinyImage());
    expect(await first.image, isNull);
    expect(await third.image, isNull);
    expect(pending.length, 2);
    pending.last.complete(await tinyImage());
    expect(await second.image, isNotNull);
    second.release();
    expect(cache.sourceCount, 0);
  });
  test('Missing image failures are shared and a new lifetime can retry',
      () async {
    var calls = 0;
    final cache =
        PreviewImageCache(decode: (path, {maxEdge, onSourceSize}) async {
      calls++;
      throw StateError('missing');
    });
    final a = cache.acquire('missing');
    final b = cache.acquire('missing');
    expect(await a.image, isNull);
    expect(await b.image, isNull);
    expect(calls, 1);
    a.release();
    b.release();
    final retry = cache.acquire('missing');
    expect(await retry.image, isNull);
    expect(calls, 2);
    retry.release();
    expect(cache.sourceCount, 0);
  });
}
