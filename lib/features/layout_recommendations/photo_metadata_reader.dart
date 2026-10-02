import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' as ui;
import '../collage_editor/models/photo_metadata.dart';

final photoMetadataReaderProvider =
    Provider((ref) => const PhotoMetadataReader());

class PhotoMetadataReader {
  const PhotoMetadataReader();

  /// Reads encoded dimensions without allocating a full-resolution pixel image.
  /// Missing/unsupported files remain unknown; count/format recommendations work.
  Future<PhotoMetadata?> read(String path) async {
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    try {
      buffer = await ui.ImmutableBuffer.fromFilePath(path);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      return PhotoMetadata(width: descriptor.width, height: descriptor.height);
    } catch (_) {
      return null;
    } finally {
      descriptor?.dispose();
      buffer?.dispose();
    }
  }
}
