import 'dart:math' as math;
import 'dart:ui' as ui;
import 'photo_filter_renderer.dart';

/// Decodes up to the requested long edge and pixel area. The caller owns the image.
Future<ui.Image> loadProjectImage(String path,
    {int? maxEdge,
    int? maxPixels,
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
    var width = math.max(1, (descriptor.width * ratio).round());
    var height = math.max(1, (descriptor.height * ratio).round());
    if (maxPixels != null && width * height > maxPixels) {
      final boundedRatio =
          math.sqrt(maxPixels / (source.width * source.height));
      width = math.min(
          maxPixels, math.max(1, (descriptor.width * boundedRatio).floor()));
      height = math.min(maxPixels ~/ width,
          math.max(1, (descriptor.height * boundedRatio).floor()));
    }
    final codec = await descriptor.instantiateCodec(
        targetWidth: width, targetHeight: height);
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
