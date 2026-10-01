import '../models/layout_template.dart';

class LayoutLibrary {
  const LayoutLibrary._();

  static List<LayoutTemplate> templatesFor(int photoCount) {
    if (photoCount <= 0) {
      return const [];
    }

    final templates = <LayoutTemplate>[
      ..._classicGrids(photoCount),
      ..._unevenRows(photoCount),
      if (photoCount >= 3)
        LayoutTemplate(
          id: 'hero_left_$photoCount',
          title: 'Hero links',
          photoCount: photoCount,
          kind: LayoutTemplateKind.heroLeft,
        ),
      if (photoCount >= 3)
        LayoutTemplate(
          id: 'hero_top_$photoCount',
          title: 'Hero oben',
          photoCount: photoCount,
          kind: LayoutTemplateKind.heroTop,
        ),
      if (photoCount >= 2)
        LayoutTemplate(
          id: 'staggered_two_columns_$photoCount',
          title: 'Versetzt',
          photoCount: photoCount,
          kind: LayoutTemplateKind.staggeredTwoColumn,
          rows: (photoCount / 2).ceil(),
          columns: 2,
        ),
    ];

    final seen = <String>{};
    return templates.where((template) => seen.add(template.id)).toList();
  }

  static LayoutTemplate defaultFor(int photoCount) {
    return templatesFor(photoCount).first;
  }

  static LayoutTemplate byIdOrDefault(String id, int photoCount) {
    return templatesFor(photoCount).firstWhere(
      (template) => template.id == id,
      orElse: () => defaultFor(photoCount),
    );
  }

  static List<LayoutCell> cellsFor(
    LayoutTemplate template, {
    double staggerAmount = 0,
  }) {
    return switch (template.kind) {
      LayoutTemplateKind.grid => _gridCells(
          template.photoCount,
          rows: template.rows,
          columns: template.columns,
        ),
      LayoutTemplateKind.unevenRows => _unevenRowCells(
          template.photoCount,
          template.rowPattern,
        ),
      LayoutTemplateKind.heroLeft => _heroLeftCells(template.photoCount),
      LayoutTemplateKind.heroTop => _heroTopCells(template.photoCount),
      LayoutTemplateKind.staggeredTwoColumn => _staggeredTwoColumnCells(
          template.photoCount,
          staggerAmount,
        ),
    };
  }

  static List<LayoutTemplate> _classicGrids(int count) {
    if (count == 1) {
      return const [
        LayoutTemplate(
          id: 'grid_1x1_1',
          title: '1 Bild',
          photoCount: 1,
          kind: LayoutTemplateKind.grid,
          rows: 1,
          columns: 1,
        ),
      ];
    }

    final templates = <LayoutTemplate>[];
    void add(int columns, int rows, String title) {
      if (columns * rows >= count) {
        templates.add(
          LayoutTemplate(
            id: 'grid_${columns}x${rows}_$count',
            title: title,
            photoCount: count,
            kind: LayoutTemplateKind.grid,
            rows: rows,
            columns: columns,
          ),
        );
      }
    }

    switch (count) {
      case 2:
        add(2, 1, '2 nebeneinander');
        add(1, 2, '2 übereinander');
      case 3:
        add(3, 1, '3 Spalten');
        add(1, 3, '3 Reihen');
      case 4:
        add(2, 2, '2 x 2');
      case 6:
        add(2, 3, '2 x 3');
        add(3, 2, '3 x 2');
      case 9:
        add(3, 3, '3 x 3');
      case 12:
        add(3, 4, '3 x 4');
        add(4, 3, '4 x 3');
      default:
        final columns = count <= 4 ? 2 : 3;
        final rows = (count / columns).ceil();
        add(columns, rows, '$columns x $rows');
    }

    return templates;
  }

  static List<LayoutTemplate> _unevenRows(int count) {
    final pattern = switch (count) {
      5 => const [2, 3],
      7 => const [2, 2, 3],
      8 => const [2, 3, 3],
      10 => const [3, 3, 4],
      11 => const [3, 4, 4],
      _ => const <int>[],
    };

    if (pattern.isEmpty) {
      return const [];
    }

    return [
      LayoutTemplate(
        id: 'uneven_rows_$count',
        title: 'Ausgewogene Reihen',
        photoCount: count,
        kind: LayoutTemplateKind.unevenRows,
        rows: pattern.length,
        columns: pattern.reduce((a, b) => a > b ? a : b),
        rowPattern: pattern,
      ),
    ];
  }

  static List<LayoutCell> _gridCells(
    int count, {
    required int rows,
    required int columns,
  }) {
    final cells = <LayoutCell>[];
    final width = 1 / columns;
    final height = 1 / rows;

    for (var index = 0; index < count; index++) {
      final row = index ~/ columns;
      final column = index % columns;
      cells.add(
        LayoutCell(
          photoIndex: index,
          rect: NormalizedRect(
            x: column * width,
            y: row * height,
            width: width,
            height: height,
          ),
        ),
      );
    }

    return cells;
  }

  static List<LayoutCell> _unevenRowCells(int count, List<int> rowPattern) {
    final cells = <LayoutCell>[];
    final rowHeight = 1 / rowPattern.length;
    var photoIndex = 0;

    for (var row = 0; row < rowPattern.length; row++) {
      final items = rowPattern[row];
      final cellWidth = 1 / items;
      for (var column = 0; column < items && photoIndex < count; column++) {
        cells.add(
          LayoutCell(
            photoIndex: photoIndex,
            rect: NormalizedRect(
              x: column * cellWidth,
              y: row * rowHeight,
              width: cellWidth,
              height: rowHeight,
            ),
          ),
        );
        photoIndex++;
      }
    }

    return cells;
  }

  static List<LayoutCell> _heroLeftCells(int count) {
    final cells = <LayoutCell>[
      const LayoutCell(
        photoIndex: 0,
        rect: NormalizedRect(x: 0, y: 0, width: 0.58, height: 1),
      ),
    ];
    final remaining = count - 1;
    final height = 1 / remaining;
    for (var i = 0; i < remaining; i++) {
      cells.add(
        LayoutCell(
          photoIndex: i + 1,
          rect: NormalizedRect(
            x: 0.58,
            y: i * height,
            width: 0.42,
            height: height,
          ),
        ),
      );
    }
    return cells;
  }

  static List<LayoutCell> _heroTopCells(int count) {
    final cells = <LayoutCell>[
      const LayoutCell(
        photoIndex: 0,
        rect: NormalizedRect(x: 0, y: 0, width: 1, height: 0.56),
      ),
    ];
    final remaining = count - 1;
    final columns = remaining <= 3 ? remaining : 3;
    final rows = (remaining / columns).ceil();
    final width = 1 / columns;
    final height = 0.44 / rows;

    for (var i = 0; i < remaining; i++) {
      final row = i ~/ columns;
      final column = i % columns;
      cells.add(
        LayoutCell(
          photoIndex: i + 1,
          rect: NormalizedRect(
            x: column * width,
            y: 0.56 + row * height,
            width: width,
            height: height,
          ),
        ),
      );
    }
    return cells;
  }

  static List<LayoutCell> _staggeredTwoColumnCells(
    int count,
    double staggerAmount,
  ) {
    final leftIndexes = <int>[];
    final rightIndexes = <int>[];
    for (var index = 0; index < count; index++) {
      if (index.isEven) {
        leftIndexes.add(index);
      } else {
        rightIndexes.add(index);
      }
    }

    final safeStagger = staggerAmount.clamp(0.0, 0.18).toDouble();
    return [
      ..._columnCells(
        indexes: leftIndexes,
        x: 0,
        width: 0.5,
        stagger: -safeStagger * 0.35,
      ),
      ..._columnCells(
        indexes: rightIndexes,
        x: 0.5,
        width: 0.5,
        stagger: safeStagger,
      ),
    ]..sort((a, b) => a.photoIndex.compareTo(b.photoIndex));
  }

  static List<LayoutCell> _columnCells({
    required List<int> indexes,
    required double x,
    required double width,
    required double stagger,
  }) {
    if (indexes.isEmpty) {
      return const [];
    }

    final count = indexes.length;
    final edges = List<double>.generate(count + 1, (index) => index / count);
    for (var i = 1; i < edges.length - 1; i++) {
      final direction = i.isOdd ? 1 : -1;
      edges[i] = (edges[i] + stagger * direction)
          .clamp(edges[i - 1] + 0.12, 1 - (count - i) * 0.12)
          .toDouble();
    }

    return [
      for (var i = 0; i < indexes.length; i++)
        LayoutCell(
          photoIndex: indexes[i],
          rect: NormalizedRect(
            x: x,
            y: edges[i],
            width: width,
            height: edges[i + 1] - edges[i],
          ),
        ),
    ];
  }
}
