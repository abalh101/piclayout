import 'dart:math' as math;
import 'dart:ui';

import '../models/photo_transform.dart';

/// Shared screen-space bounds for preview, gestures and original-file export.
class PhotoCrop {
  const PhotoCrop._();

  static PhotoTransform clamp(
      PhotoTransform transform, Size source, Size cell) {
    final rotation = transform.rotationQuarterTurns % 4;
    final fill = transform.fitMode == PhotoFitMode.fill;
    final scale = (transform.scale.isFinite ? transform.scale : 1.0)
        .clamp(fill ? 1.0 : .5, 5.0)
        .toDouble();
    double safe(double value) => value.isFinite ? value : 0;
    if (!fill || source.isEmpty || cell.isEmpty) {
      return transform.copyWith(
          scale: scale,
          offsetX: safe(transform.offsetX).clamp(-1.5, 1.5).toDouble(),
          offsetY: safe(transform.offsetY).clamp(-1.5, 1.5).toDouble());
    }
    final width = rotation.isOdd ? source.height : source.width;
    final height = rotation.isOdd ? source.width : source.height;
    final base = math.max(cell.width / width, cell.height / height);
    final maxX =
        math.max(0.0, (width * base * scale - cell.width) / (2 * cell.width));
    final maxY = math.max(
        0.0, (height * base * scale - cell.height) / (2 * cell.height));
    return transform.copyWith(
        scale: scale,
        offsetX: safe(transform.offsetX).clamp(-maxX, maxX).toDouble(),
        offsetY: safe(transform.offsetY).clamp(-maxY, maxY).toDouble());
  }
}
