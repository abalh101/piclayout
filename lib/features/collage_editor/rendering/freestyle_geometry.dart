import 'dart:math' as math;
import 'dart:ui';

import '../models/photo_placement.dart';

class FreestyleGeometry {
  const FreestyleGeometry._();

  static ({PhotoPlacement placement, double? guideX, double? guideY}) snap(
    PhotoPlacement photo,
    Size canvas, {
    Iterable<PhotoPlacement> neighbors = const [],
    double tolerance = 7,
  }) {
    Rect bounds(PhotoPlacement placement) {
      final rect = placement.rect(canvas);
      final cos = math.cos(placement.radians).abs();
      final sin = math.sin(placement.radians).abs();
      return Rect.fromCenter(
        center: rect.center,
        width: rect.width * cos + rect.height * sin,
        height: rect.width * sin + rect.height * cos,
      );
    }

    final current = bounds(photo);
    final targets = [
      for (final item in neighbors)
        if (!item.hidden) bounds(item)
    ];
    final horizontal = _snapAxis(
      current.left,
      current.center.dx,
      current.right,
      canvas.width,
      [
        for (final item in targets) ...[item.left, item.center.dx, item.right]
      ],
      tolerance,
    );
    final vertical = _snapAxis(
      current.top,
      current.center.dy,
      current.bottom,
      canvas.height,
      [
        for (final item in targets) ...[item.top, item.center.dy, item.bottom]
      ],
      tolerance,
    );
    return (
      placement: photo.copyWith(
        x: (current.center.dx + horizontal.delta) / canvas.width,
        y: (current.center.dy + vertical.delta) / canvas.height,
      ),
      guideX: horizontal.guide,
      guideY: vertical.guide,
    );
  }

  static ({double delta, double? guide}) _snapAxis(
    double leading,
    double center,
    double trailing,
    double extent,
    List<double> neighbors,
    double tolerance,
  ) {
    var nearest = tolerance;
    var delta = 0.0;
    double? guide;
    void consider(double from, double to) {
      final distance = to - from;
      if (distance.abs() >= nearest ||
          center + distance < 0 ||
          center + distance > extent) {
        return;
      }
      nearest = distance.abs();
      delta = distance;
      guide = to;
    }

    consider(center, extent / 2);
    consider(leading, 0);
    consider(trailing, extent);
    for (final neighbor in neighbors) {
      consider(leading, neighbor);
      consider(center, neighbor);
      consider(trailing, neighbor);
    }
    return (delta: delta, guide: guide);
  }
}
