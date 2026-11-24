import 'dart:math' as math;
import 'dart:ui' as ui;
import 'photo_filter_renderer.dart';

/// Decodes only up to the requested long edge; callers own and dispose the image.
Future<ui.Image> loadProjectImage(String path,
    {int? maxEdge,
    void Function(ui.Size size)? onSourceSize,
    int Function(ui.Size source)? usefulEdge}) async {
  final buffer = await ui.ImmutableBuffer.fromFilePath(path);
  ui.ImageDescriptor? descriptor;
  try {
    await PhotoFilterRenderer.initialize();
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    final source =
        ui.Size(descriptor.width.toDouble(), descriptor.height.toDouble());
    onSourceSize?.call(source);
    final limit = maxEdge ?? usefulEdge?.call(source);
    final ratio =
        limit == null ? 1.0 : math.min(1.0, limit / source.longestSide);
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
