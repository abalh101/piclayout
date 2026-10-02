import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

/// Decodes only up to the requested long edge; callers own and dispose the image.
Future<ui.Image> loadProjectImage(String path, {int? maxEdge}) async {
  final buffer =
      await ui.ImmutableBuffer.fromUint8List(await File(path).readAsBytes());
  ui.ImageDescriptor? descriptor;
  try {
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    final ratio = maxEdge == null
        ? 1.0
        : math.min(
            1.0, maxEdge / math.max(descriptor.width, descriptor.height));
    final codec = await descriptor.instantiateCodec(
      targetWidth: math.max(1, (descriptor.width * ratio).round()),
      targetHeight: math.max(1, (descriptor.height * ratio).round()),
    );
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  } finally {
    descriptor?.dispose();
    buffer.dispose();
  }
}
