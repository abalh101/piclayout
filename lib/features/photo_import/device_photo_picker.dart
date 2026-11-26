import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class DevicePhotoPicker {
  const DevicePhotoPicker();

  static const _channel = MethodChannel('piclayout/media');

  Future<List<XFile>> pickPhotos({required int limit}) async {
    if (Platform.isIOS) {
      final paths = await _channel
          .invokeListMethod<String>('pickPhotos', {'limit': limit});
      return [for (final path in paths ?? const <String>[]) XFile(path)];
    }
    final picker = ImagePicker();
    if (limit == 1) {
      final file = await picker.pickImage(
          source: ImageSource.gallery, requestFullMetadata: false);
      return [if (file != null) file];
    }
    return picker.pickMultiImage(limit: limit, requestFullMetadata: false);
  }

  // iOS picker copies belong to one selection. Projects have their own copies.
  Future<void> release(List<XFile> files) async {
    if (!Platform.isIOS || files.isEmpty) return;
    final selection = File(files.first.path).parent.parent;
    if (!selection.path
        .split(Platform.pathSeparator)
        .last
        .startsWith('piclayout_picker_')) {
      return;
    }
    try {
      await selection.delete(recursive: true);
    } on FileSystemException {
      // The operating system can reclaim temporary files.
    }
  }
}
