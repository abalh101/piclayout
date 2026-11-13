import 'dart:math' as math;
import 'dart:ui';
import '../models/editorial_design.dart';

class SnapGuide {
  const SnapGuide(this.vertical, this.position);
  final bool vertical;
  final double position;
}

class FreeformSnapResult {
  const FreeformSnapResult(this.layer, this.guides);
  final DesignLayer layer;
  final List<SnapGuide> guides;
}

class FreeformSnapping {
  static FreeformSnapResult move(
      DesignLayer frame, List<DesignLayer> layers, Size size) {
    if (size.isEmpty) return FreeformSnapResult(frame, const []);
    // Use the rotated frame's axis-aligned extent, rather than an incorrect
    // unrotated edge when snapping a scrapbook frame.
    Rect bounds(DesignLayer l) {
      final r = l.rect(size), angle = l.rotation * math.pi / 180;
      return Rect.fromCenter(
          center: r.center,
          width: r.width * math.cos(angle).abs() +
              r.height * math.sin(angle).abs(),
          height: r.width * math.sin(angle).abs() +
              r.height * math.cos(angle).abs());
    }

    final rect = bounds(frame);
    final others = layers
        .where((l) => l.id != frame.id && l.visible && l.opacity > 0)
        .map(bounds)
        .toList();
    final guides = <SnapGuide>[];
    double snap(bool vertical) {
      final extent = vertical ? size.width : size.height;
      final start = vertical ? rect.left : rect.top;
      final end = vertical ? rect.right : rect.bottom;
      final points = [start, (start + end) / 2, end];
      final targets = <double>[
        0,
        extent / 2,
        extent,
        extent * (vertical ? .05 : .08),
        extent * (vertical ? .95 : .92)
      ];
      for (final other in others) {
        targets.addAll(vertical
            ? [other.left, other.center.dx, other.right]
            : [other.top, other.center.dy, other.bottom]);
      }
      // Reuse existing positive neighbor gaps, including equal spacing between
      // two neighbors. Candidates outside the canvas are harmless and ignored.
      for (final a in others) {
        for (final b in others) {
          final aEnd = vertical ? a.right : a.bottom;
          final bStart = vertical ? b.left : b.top;
          final overlap = vertical
              ? math.min(a.bottom, b.bottom) - math.max(a.top, b.top)
              : math.min(a.right, b.right) - math.max(a.left, b.left);
          final gap = bStart - aEnd;
          if (gap > 0 && gap < extent * .12 && overlap > 0) {
            targets.add((vertical ? b.right : b.bottom) + gap);
            targets.add((vertical ? a.left : a.top) - gap);
          }
        }
      }
      var delta = 0.0, distance = 6.0;
      double? guide;
      for (final target in targets) {
        if (target < 0 || target > extent) continue;
        for (final point in points) {
          final d = target - point;
          if (d.abs() < distance) {
            distance = d.abs();
            delta = d;
            guide = target;
          }
        }
      }
      if (guide != null) guides.add(SnapGuide(vertical, guide / extent));
      return delta / extent;
    }

    final dx = snap(true), dy = snap(false);
    return FreeformSnapResult(
        frame.copyWith(x: frame.x + dx, y: frame.y + dy), guides);
  }
}
