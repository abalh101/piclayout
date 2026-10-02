import 'dart:math' as math;
import '../../collage_editor/models/layout_template.dart';

enum DividerAxis { vertical, horizontal }

class CustomLayoutCell {
  const CustomLayoutCell(
      {required this.photoIndex,
      required this.x,
      required this.y,
      required this.width,
      required this.height});
  final int photoIndex;
  final double x, y, width, height;
  double get right => x + width;
  double get bottom => y + height;
  LayoutCell get layoutCell => LayoutCell(
      photoIndex: photoIndex,
      rect: NormalizedRect(x: x, y: y, width: width, height: height));
  Map<String, Object?> toJson() => {
        'photoIndex': photoIndex,
        'x': x,
        'y': y,
        'width': width,
        'height': height
      };
  factory CustomLayoutCell.fromJson(Map<String, Object?> json) =>
      CustomLayoutCell(
          photoIndex: json['photoIndex'] as int,
          x: (json['x'] as num).toDouble(),
          y: (json['y'] as num).toDouble(),
          width: (json['width'] as num).toDouble(),
          height: (json['height'] as num).toDouble());
}

/// A connected internal seam. IDs refer to cell edges, never photo IDs.
class LayoutDivider {
  LayoutDivider(
      {required this.axis,
      required this.position,
      required this.start,
      required this.end,
      required List<int> before,
      required List<int> after})
      : before = List.unmodifiable(before),
        after = List.unmodifiable(after);
  final DividerAxis axis;
  final double position, start, end;
  final List<int> before, after;
  String get id => '${axis.name}:${before.join(',')}:${after.join(',')}';
  bool touches(int index) => before.contains(index) || after.contains(index);
}

/// Immutable, photo-free rectangular partition of the normalized canvas.
class CustomLayout {
  CustomLayout(
      {required this.id,
      required this.name,
      required this.photoCount,
      required this.createdAt,
      required this.updatedAt,
      required List<CustomLayoutCell> cells})
      : cells = List.unmodifiable(cells) {
    if (!isValid) {
      throw const FormatException('Invalid custom layout partition');
    }
  }
  static const minSize = .12;
  static const epsilon = 1e-8;
  final String id, name;
  final int photoCount;
  final DateTime createdAt, updatedAt;
  final List<CustomLayoutCell> cells;
  List<LayoutCell> get layoutCells =>
      cells.map((cell) => cell.layoutCell).toList();

  bool get isValid {
    if (id.isEmpty ||
        name.trim().isEmpty ||
        photoCount < 1 ||
        photoCount > 12 ||
        cells.length != photoCount) {
      return false;
    }
    final indexes = cells.map((c) => c.photoIndex).toSet();
    if (indexes.length != photoCount ||
        indexes.any((i) => i < 0 || i >= photoCount)) {
      return false;
    }
    var area = 0.0;
    for (var i = 0; i < cells.length; i++) {
      final a = cells[i];
      if (![a.x, a.y, a.width, a.height].every((v) => v.isFinite) ||
          a.x < 0 ||
          a.y < 0 ||
          a.right > 1 + epsilon ||
          a.bottom > 1 + epsilon ||
          a.width < minSize - epsilon ||
          a.height < minSize - epsilon) {
        return false;
      }
      area += a.width * a.height;
      for (var j = 0; j < i; j++) {
        final b = cells[j];
        if (math.min(a.right, b.right) - math.max(a.x, b.x) > epsilon &&
            math.min(a.bottom, b.bottom) - math.max(a.y, b.y) > epsilon) {
          return false;
        }
      }
    }
    // Inside unit square + no intersections + total unit area => no gaps.
    return (area - 1).abs() < epsilon;
  }

  factory CustomLayout.fromCells(
      {required String id,
      required String name,
      required List<LayoutCell> cells,
      DateTime? now}) {
    final date = now ?? DateTime.now();
    return CustomLayout(
        id: id,
        name: name,
        photoCount: cells.length,
        createdAt: date,
        updatedAt: date,
        cells: [
          for (final cell in cells)
            CustomLayoutCell(
                photoIndex: cell.photoIndex,
                x: cell.rect.x,
                y: cell.rect.y,
                width: cell.rect.width,
                height: cell.rect.height)
        ]);
  }

  CustomLayout savedAs(String newId, String newName, {DateTime? now}) {
    final date = now ?? DateTime.now();
    return CustomLayout(
        id: newId,
        name: newName.trim(),
        photoCount: photoCount,
        createdAt: date,
        updatedAt: date,
        cells: cells);
  }

  List<LayoutDivider> get dividers {
    final result = <LayoutDivider>[];
    for (final axis in DividerAxis.values) {
      final edges = <_Edge>[];
      for (var i = 0; i < cells.length; i++) {
        final c = cells[i];
        final vertical = axis == DividerAxis.vertical;
        final start = vertical ? c.y : c.x;
        final end = vertical ? c.bottom : c.right;
        final near = vertical ? c.x : c.y;
        final far = vertical ? c.right : c.bottom;
        if (near > epsilon) edges.add(_Edge(i, near, start, end, false));
        if (far < 1 - epsilon) edges.add(_Edge(i, far, start, end, true));
      }
      edges.sort((a, b) => a.position.compareTo(b.position));
      while (edges.isNotEmpty) {
        final position = edges.first.position;
        final line = edges
            .where((e) => (e.position - position).abs() < epsilon)
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));
        edges.removeWhere((e) => (e.position - position).abs() < epsilon);
        while (line.isNotEmpty) {
          final group = <_Edge>[line.removeAt(0)];
          var end = group.first.end;
          while (line.isNotEmpty && line.first.start <= end + epsilon) {
            final next = line.removeAt(0);
            group.add(next);
            end = math.max(end, next.end);
          }
          final before =
              group.where((e) => e.before).map((e) => e.index).toList()..sort();
          final after = group
              .where((e) => !e.before)
              .map((e) => e.index)
              .toList()
            ..sort();
          if (before.isNotEmpty && after.isNotEmpty) {
            result.add(LayoutDivider(
                axis: axis,
                position: position,
                start: group.first.start,
                end: end,
                before: before,
                after: after));
          }
        }
      }
    }
    return result;
  }

  (double, double) bounds(LayoutDivider divider) {
    final vertical = divider.axis == DividerAxis.vertical;
    var low = 0.0;
    var high = 1.0;
    for (final i in divider.before) {
      low = math.max(low, (vertical ? cells[i].x : cells[i].y) + minSize);
    }
    for (final i in divider.after) {
      high = math.min(
          high, (vertical ? cells[i].right : cells[i].bottom) - minSize);
    }
    return (low, high);
  }

  CustomLayout moveDivider(LayoutDivider divider, double position) {
    if (!position.isFinite) return this;
    // Stale/foreign seams must not mutate arbitrary cell edges.
    final matches = dividers.where((d) =>
        d.id == divider.id && (d.position - divider.position).abs() < epsilon);
    if (matches.isEmpty) return this;
    final (low, high) = bounds(divider);
    if (low > high) return this;
    final target = position.clamp(low, high);
    if ((target - divider.position).abs() < epsilon) return this;
    final vertical = divider.axis == DividerAxis.vertical;
    final updated = <CustomLayoutCell>[];
    for (var i = 0; i < cells.length; i++) {
      final c = cells[i];
      final left = vertical && divider.after.contains(i) ? target : c.x;
      final right = vertical && divider.before.contains(i) ? target : c.right;
      final top = !vertical && divider.after.contains(i) ? target : c.y;
      final bottom =
          !vertical && divider.before.contains(i) ? target : c.bottom;
      updated.add(CustomLayoutCell(
          photoIndex: c.photoIndex,
          x: left,
          y: top,
          width: right - left,
          height: bottom - top));
    }
    return CustomLayout(
        id: id,
        name: name,
        photoCount: photoCount,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        cells: updated);
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'photoCount': photoCount,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'cells': cells.map((c) => c.toJson()).toList()
      };
  factory CustomLayout.fromJson(Map<String, Object?> json) => CustomLayout(
      id: json['id'] as String,
      name: json['name'] as String,
      photoCount: json['photoCount'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      cells: (json['cells'] as List)
          .map((c) =>
              CustomLayoutCell.fromJson(Map<String, Object?>.from(c as Map)))
          .toList());
  static CustomLayout? tryParse(Object? json) {
    try {
      return CustomLayout.fromJson(Map<String, Object?>.from(json as Map));
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}

class _Edge {
  const _Edge(this.index, this.position, this.start, this.end, this.before);
  final int index;
  final double position, start, end;
  final bool before;
}
