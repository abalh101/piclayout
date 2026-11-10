import 'dart:math' as math;
import 'dart:ui';
import '../../editorial/models/editorial_design.dart';
import '../../editorial/rendering/editorial_renderer.dart';

import '../layouts/layout_library.dart';
import '../models/layout_template.dart';
import '../../projects/models/collage_project.dart';

class ResolvedLayoutCell {
  const ResolvedLayoutCell({
    required this.photoIndex,
    required this.rect,
    required this.cornerRadius,
  });

  final int photoIndex;
  final Rect rect;
  final double cornerRadius;
}

class LayoutGeometry {
  const LayoutGeometry._();

  static List<ResolvedLayoutCell> resolve(
    CollageProject project,
    Size canvasSize,
  ) {
    if (project.photos.isEmpty) return [];
    if (project.design.active) {
      return [
        for (final layer in project.design.ordered)
          if (layer.visible &&
              layer.isPhoto &&
              layer.type != DesignLayerType.callout &&
              layer.source(project.photos) != null)
            ResolvedLayoutCell(
                photoIndex:
                    project.photos.indexOf(layer.source(project.photos)!),
                rect: EditorialRenderer.bounds(layer, canvasSize),
                cornerRadius: layer.radius * canvasSize.shortestSide / 390)
      ];
    }
    final template = LayoutLibrary.byIdOrDefault(
      project.layoutTemplateId,
      project.photos.length,
    );
    final cells = project.customLayout?.photoCount == project.photos.length
        ? project.customLayout!.layoutCells
        : LayoutLibrary.cellsFor(
            template,
            staggerAmount: project.canvas.staggerAmount,
          );
    return resolveCells(
      cells,
      canvasSize,
      spacing: project.canvas.spacing,
      outerMargin: project.canvas.outerMargin,
      cornerRadius: project.canvas.cornerRadius,
    );
  }

  static List<ResolvedLayoutCell> resolveCells(
    List<LayoutCell> cells,
    Size canvasSize, {
    required double spacing,
    required double outerMargin,
    required double cornerRadius,
  }) {
    final scale = _scaleFor(canvasSize);
    var gap = spacing * scale;
    final margin = outerMargin * scale;
    final radius = cornerRadius * scale;
    final innerWidth =
        (canvasSize.width - 2 * margin).clamp(1.0, double.maxFinite).toDouble();
    final innerHeight = (canvasSize.height - 2 * margin)
        .clamp(1.0, double.maxFinite)
        .toDouble();

    // Large style spacing must not invert narrow custom cells.
    for (final cell in cells) {
      gap = math.min(
          gap,
          math.min(cell.rect.width * innerWidth,
                  cell.rect.height * innerHeight) *
              .8);
    }
    return cells.map((cell) {
      final rect = cell.rect;
      final leftGap = rect.x <= 0 ? 0.0 : gap / 2;
      final topGap = rect.y <= 0 ? 0.0 : gap / 2;
      final rightGap = rect.right >= 1 ? 0.0 : gap / 2;
      final bottomGap = rect.bottom >= 1 ? 0.0 : gap / 2;
      final left = margin + rect.x * innerWidth + leftGap;
      final top = margin + rect.y * innerHeight + topGap;
      final right = margin + rect.right * innerWidth - rightGap;
      final bottom = margin + rect.bottom * innerHeight - bottomGap;

      return ResolvedLayoutCell(
        photoIndex: cell.photoIndex,
        rect: Rect.fromLTRB(left, top, right, bottom),
        cornerRadius: radius,
      );
    }).toList();
  }

  static double _scaleFor(Size size) {
    return size.shortestSide / 390;
  }
}
