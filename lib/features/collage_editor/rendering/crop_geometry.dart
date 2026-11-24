import 'dart:math' as math;
import 'dart:ui';

import '../models/photo_transform.dart';

class CropGeometry {
  const CropGeometry._();

  static ({Offset center, Size imageSize, double zoom}) resolve(
    Rect cell,
    Size source,
    PhotoTransform transform,
  ) {
    final rotated = transform.rotationQuarterTurns.isOdd
        ? Size(source.height, source.width)
        : source;
    final widthScale = cell.width / rotated.width;
    final heightScale = cell.height / rotated.height;
    if (transform.fitMode == PhotoFitMode.fit) {
      return (
        center: cell.center,
        imageSize: source * math.min(widthScale, heightScale),
        zoom: 1,
      );
    }
    final zoom = transform.scale.isFinite
        ? transform.scale.clamp(1.0, 5.0).toDouble()
        : 1.0;
    final scale = math.max(widthScale, heightScale) * zoom;
    final maxX = math.max(0.0, (rotated.width * scale - cell.width) / 2);
    final maxY = math.max(0.0, (rotated.height * scale - cell.height) / 2);
    double clampOffset(double value, double limit) =>
        value.isFinite ? value.clamp(-limit, limit).toDouble() : 0;
    return (
      center: cell.center +
          Offset(
            clampOffset(transform.offsetX * cell.width, maxX),
            clampOffset(transform.offsetY * cell.height, maxY),
          ),
      imageSize: source * scale,
      zoom: zoom,
    );
  }

  static PhotoTransform gesture(
    Rect cell,
    Size source,
    PhotoTransform current, {
    required Offset focalPoint,
    required Offset focalDelta,
    required double scaleChange,
  }) {
    final before = resolve(cell, source, current);
    final zoom = (before.zoom * scaleChange).clamp(1.0, 5.0).toDouble();
    final previousFocal = focalPoint - focalDelta;
    final center =
        focalPoint + (before.center - previousFocal) * (zoom / before.zoom);
    final delta = center - cell.center;
    final candidate = current.copyWith(
      scale: zoom,
      offsetX: delta.dx / cell.width,
      offsetY: delta.dy / cell.height,
    );
    final clamped = resolve(cell, source, candidate).center - cell.center;
    return candidate.copyWith(
      offsetX: clamped.dx / cell.width,
      offsetY: clamped.dy / cell.height,
    );
  }
}
