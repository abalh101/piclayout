enum LayoutTemplateKind {
  grid,
  unevenRows,
  heroLeft,
  heroTop,
  staggeredTwoColumn,
}

class NormalizedRect {
  const NormalizedRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final double x;
  final double y;
  final double width;
  final double height;

  double get right => x + width;
  double get bottom => y + height;

  bool get isValid {
    return x >= 0 &&
        y >= 0 &&
        width > 0 &&
        height > 0 &&
        right <= 1.000001 &&
        bottom <= 1.000001;
  }
}

class LayoutCell {
  const LayoutCell({
    required this.photoIndex,
    required this.rect,
  });

  final int photoIndex;
  final NormalizedRect rect;
}

class LayoutTemplate {
  const LayoutTemplate({
    required this.id,
    required this.title,
    required this.photoCount,
    required this.kind,
    this.rows = 1,
    this.columns = 1,
    this.rowPattern = const [],
  });

  final String id;
  final String title;
  final int photoCount;
  final LayoutTemplateKind kind;
  final int rows;
  final int columns;
  final List<int> rowPattern;

  bool get supportsStagger => kind == LayoutTemplateKind.staggeredTwoColumn;
}
