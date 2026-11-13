import 'dart:async';
import 'dart:collection';
import 'dart:ui' as ui;
import 'photo_filter_renderer.dart';
import 'project_image_loader.dart';

typedef PreviewDecoder = Future<ui.Image> Function(String path,
    {int? maxEdge, void Function(ui.Size)? onSourceSize});

/// Reference-counted originals shared by the canvas and adjustment sheet.
/// No idle images are retained. At most two bounded decodes run concurrently.
class PreviewImageCache {
  PreviewImageCache({PreviewDecoder? decode})
      : _decode = decode ?? loadProjectImage;
  final PreviewDecoder _decode;
  final _entries = <String, _Entry>{};
  final _queue = Queue<(_Entry, String)>();
  int _running = 0;
  int get sourceCount => _entries.length;

  PreviewImageLease acquire(String path) {
    var entry = _entries[path];
    if (entry == null) {
      entry = _Entry();
      _entries[path] = entry;
      _queue.add((entry, path));
    }
    entry.references++;
    final lease = PreviewImageLease._(entry, () => _release(path, entry!));
    _drain();
    return lease;
  }

  void _release(String path, _Entry entry) {
    entry.references--;
    if (entry.references != 0) return;
    if (identical(_entries[path], entry)) _entries.remove(path);
    final image = entry.image;
    if (image != null) {
      PhotoFilterRenderer.releaseImage(image);
      image.dispose();
      entry.image = null;
    }
  }

  void _drain() {
    while (_running < 2 && _queue.isNotEmpty) {
      final item = _queue.removeFirst();
      if (item.$1.references == 0) {
        item.$1.result.complete(null);
        continue;
      }
      _running++;
      unawaited(_load(item.$1, item.$2));
    }
  }

  Future<void> _load(_Entry entry, String path) async {
    try {
      final image = await _decode(path,
          maxEdge: 1024, onSourceSize: (size) => entry.sourceSize = size);
      if (entry.references == 0) {
        image.dispose();
        entry.result.complete(null);
      } else {
        entry.image = image;
        entry.result.complete(image);
      }
    } catch (_) {
      entry.result.complete(null);
    } finally {
      _running--;
      _drain();
    }
  }
}

class _Entry {
  int references = 0;
  ui.Image? image;
  ui.Size? sourceSize;
  final result = Completer<ui.Image?>();
}

class PreviewImageLease {
  PreviewImageLease._(this._entry, this._release);
  final _Entry _entry;
  final void Function() _release;
  bool _released = false;
  Future<ui.Image?> get image => _entry.result.future;
  ui.Size? get sourceSize => _entry.sourceSize;
  void release() {
    if (_released) return;
    _released = true;
    _release();
  }
}
