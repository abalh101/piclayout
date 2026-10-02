import 'dart:math' as math;
import '../collage_editor/layouts/layout_library.dart';
import '../collage_editor/models/layout_template.dart';
import '../collage_editor/models/photo_asset.dart';
import '../collage_editor/models/photo_metadata.dart';

class PhotoOrientationStats {
  PhotoOrientationStats(Iterable<PhotoMetadata?> photos) {
    for (final photo in photos) {
      if (photo == null) {
        unknown++;
        continue;
      }
      switch (photo.orientation) {
        case PhotoOrientation.portrait:
          portraits++;
        case PhotoOrientation.landscape:
          landscapes++;
        case PhotoOrientation.square:
          squares++;
      }
    }
  }
  int portraits = 0, landscapes = 0, squares = 0, unknown = 0;
  int get known => portraits + landscapes + squares;
  bool get mixed => portraits > 0 && landscapes > 0;
}

class LayoutScore {
  const LayoutScore(
      {required this.fit, required this.coverage, required this.ruleBonus});
  final double fit, coverage, ruleBonus;
  double get total => fit * 60 + coverage * 8 + ruleBonus;
  Map<String, Object?> toJson() => {
        'fit': fit,
        'coverage': coverage,
        'ruleBonus': ruleBonus,
        'total': total
      };
}

class LayoutRecommendation {
  const LayoutRecommendation(
      {required this.layout, required this.score, required this.reasonKey});
  final LayoutTemplate layout;
  final LayoutScore score;
  final String reasonKey;
  Map<String, Object?> toJson() =>
      {'layoutId': layout.id, 'score': score.toJson(), 'reasonKey': reasonKey};
}

/// Pure local rules. Evaluates each cell against the photo at that exact index;
/// never reorders photos and never includes photo identities or paths in results.
class LayoutRecommendationService {
  const LayoutRecommendationService();
  List<LayoutRecommendation> recommend(List<PhotoAsset> photos,
      {required double targetRatio, double staggerAmount = 0}) {
    if (photos.isEmpty ||
        photos.length > 12 ||
        !targetRatio.isFinite ||
        targetRatio <= 0) {
      return const [];
    }
    final metadata = [
      for (final photo in photos)
        photo.metadata?.rotated(photo.transform.rotationQuarterTurns)
    ];
    final stats = PhotoOrientationStats(metadata);
    final results = <LayoutRecommendation>[];
    for (final layout in LayoutLibrary.templatesFor(photos.length)) {
      final cells =
          LayoutLibrary.cellsFor(layout, staggerAmount: staggerAmount);
      var fit = 0.0, coverage = 0.0, portraitCells = 0, landscapeCells = 0;
      for (final cell in cells) {
        final ratio = targetRatio * cell.rect.width / cell.rect.height;
        final source = metadata[cell.photoIndex]?.aspectRatio;
        fit += source == null ? .65 : math.min(source / ratio, ratio / source);
        coverage += cell.rect.width * cell.rect.height;
        if (ratio < .95) portraitCells++;
        if (ratio > 1.05) landscapeCells++;
      }
      var bonus = 0.0;
      var reason = 'recFormat';
      if (stats.known > 0 &&
          stats.portraits / photos.length >= .67 &&
          portraitCells / cells.length >= .67) {
        bonus += 12;
        reason = 'recPortrait';
      }
      if (stats.known > 0 &&
          stats.landscapes / photos.length >= .67 &&
          landscapeCells / cells.length >= .67) {
        bonus += 12;
        reason = 'recLandscape';
      }
      if ((targetRatio - 1).abs() < .05 &&
          layout.kind == LayoutTemplateKind.grid &&
          coverage > .99) {
        bonus += 12;
        reason = 'recSquare';
      }
      if (stats.mixed &&
          (layout.kind == LayoutTemplateKind.unevenRows ||
              layout.kind == LayoutTemplateKind.heroLeft ||
              layout.kind == LayoutTemplateKind.heroTop)) {
        bonus += 18;
        reason = 'recMixed';
      }
      if (photos.length == 6 &&
          (targetRatio - 9 / 16).abs() < .02 &&
          ((layout.kind == LayoutTemplateKind.grid &&
                  layout.columns == 2 &&
                  layout.rows == 3) ||
              layout.kind == LayoutTemplateKind.staggeredTwoColumn)) {
        bonus += 22;
        reason = 'recStorySix';
      }
      // Hero cells contain photo 0 in the existing layout library. Only reward
      // them when that photo actually benefits; a later panorama is not moved.
      final first = metadata.first;
      final heroRatio =
          targetRatio * cells.first.rect.width / cells.first.rect.height;
      if (first?.shape == PhotoShape.veryWide &&
          layout.kind == LayoutTemplateKind.heroTop &&
          heroRatio > 1) {
        bonus += 28;
        reason = 'recWideHero';
      }
      if (first?.shape == PhotoShape.veryTall &&
          layout.kind == LayoutTemplateKind.heroLeft &&
          heroRatio < 1) {
        bonus += 28;
        reason = 'recTallHero';
      }
      results.add(LayoutRecommendation(
          layout: layout,
          score: LayoutScore(
              fit: fit / photos.length, coverage: coverage, ruleBonus: bonus),
          reasonKey: reason));
    }
    results.sort((a, b) {
      final score = b.score.total.compareTo(a.score.total);
      return score != 0 ? score : a.layout.id.compareTo(b.layout.id);
    });
    return List.unmodifiable(results);
  }
}
