import 'package:flutter_test/flutter_test.dart';
import 'package:piclayout/features/collage_editor/layouts/layout_library.dart';
import 'package:piclayout/features/collage_editor/models/layout_template.dart';

void main() {
  test('classic 2 x 3 layout keeps row-major order for six photos', () {
    final template = LayoutLibrary.templatesFor(6).firstWhere(
      (item) => item.id == 'grid_2x3_6',
    );
    final cells = LayoutLibrary.cellsFor(template);

    expect(cells, hasLength(6));
    expect(cells.map((cell) => cell.photoIndex), [0, 1, 2, 3, 4, 5]);
    expect(cells[0].rect.x, 0);
    expect(cells[0].rect.y, 0);
    expect(cells[1].rect.x, closeTo(0.5, 0.0001));
    expect(cells[1].rect.y, 0);
    expect(cells[2].rect.x, 0);
    expect(cells[2].rect.y, closeTo(1 / 3, 0.0001));
    expect(cells[5].rect.x, closeTo(0.5, 0.0001));
    expect(cells[5].rect.y, closeTo(2 / 3, 0.0001));
  });

  test('all generated cells stay inside the normalized canvas', () {
    for (var count = 1; count <= 12; count++) {
      for (final template in LayoutLibrary.templatesFor(count)) {
        final cells = LayoutLibrary.cellsFor(template, staggerAmount: 0.16);
        expect(cells, hasLength(count), reason: template.id);
        for (final cell in cells) {
          expect(cell.rect.isValid, isTrue, reason: template.id);
        }
      }
    }
  });

  test('staggered two-column layout keeps odd/even photo columns', () {
    final template = LayoutLibrary.templatesFor(6).firstWhere(
      (item) => item.kind == LayoutTemplateKind.staggeredTwoColumn,
    );
    final cells = LayoutLibrary.cellsFor(template, staggerAmount: 0.15);
    final byPhoto = {for (final cell in cells) cell.photoIndex: cell.rect};

    expect(byPhoto[0]!.x, 0);
    expect(byPhoto[2]!.x, 0);
    expect(byPhoto[4]!.x, 0);
    expect(byPhoto[1]!.x, 0.5);
    expect(byPhoto[3]!.x, 0.5);
    expect(byPhoto[5]!.x, 0.5);
    expect(byPhoto[1]!.height, isNot(closeTo(1 / 3, 0.0001)));
  });

  test('stagger amount is clamped so cells do not become unusably small', () {
    final template = LayoutLibrary.templatesFor(12).firstWhere(
      (item) => item.kind == LayoutTemplateKind.staggeredTwoColumn,
    );
    final cells = LayoutLibrary.cellsFor(template, staggerAmount: 0.9);

    for (final cell in cells) {
      expect(cell.rect.height, greaterThanOrEqualTo(0.12));
      expect(cell.rect.isValid, isTrue);
    }
  });
}
