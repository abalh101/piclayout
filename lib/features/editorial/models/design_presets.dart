import 'dart:math' as math;
import 'dart:ui';
import 'package:uuid/uuid.dart';
import '../../collage_editor/models/photo_asset.dart';
import '../../collage_editor/models/text_overlay.dart';
import 'editorial_design.dart';

class DesignPreset {
  const DesignPreset(this.key, this.mode, {this.variant = 0});
  final String key;
  final DesignMode mode;
  final int variant;
  static const all = [
    DesignPreset('edWeek', DesignMode.editorial),
    DesignPreset('edTravel', DesignMode.masonry),
    DesignPreset('edMasonryOffset', DesignMode.masonry, variant: 1),
    DesignPreset('edMasonryHero', DesignMode.masonry, variant: 2),
    DesignPreset('edMemories', DesignMode.torn),
    DesignPreset('edFocus', DesignMode.detail),
    DesignPreset('edJournal', DesignMode.masonry, variant: 2),
  ];

  EditorialDesign create(List<PhotoAsset> photos, String Function(String) tr) {
    final layers = <DesignLayer>[];
    String id() => const Uuid().v4();
    final journal = key == 'edJournal';
    final hasTitle = mode == DesignMode.editorial || journal;
    var design = EditorialDesign(
        mode: mode,
        preset: key,
        variant: variant,
        header: hasTitle ? .16 : .02,
        gapY: mode == DesignMode.editorial ? .075 : .018,
        margin: mode == DesignMode.detail ? 0 : .045);
    if (hasTitle) {
      layers.add(DesignLayer(
          id: id(),
          type: DesignLayerType.text,
          x: .5,
          y: .075,
          width: .88,
          height: .1,
          z: 30,
          text: TextOverlay(
              id: id(),
              text: tr(key),
              fontSize: 29,
              color: 0xFF202020,
              fontFamily: 'serif',
              padding: 0)));
      if (journal) {
        layers.add(DesignLayer(
            id: id(),
            type: DesignLayerType.text,
            x: .5,
            y: .135,
            width: .85,
            height: .045,
            z: 30,
            text: TextOverlay(
                id: id(),
                text: tr('edSubtitle'),
                fontSize: 13,
                color: 0xFF555555,
                padding: 0)));
      }
    }
    final count =
        mode == DesignMode.detail ? math.min(1, photos.length) : photos.length;
    for (var i = 0; i < count; i++) {
      layers.add(DesignLayer(
          id: id(),
          type: mode == DesignMode.torn
              ? DesignLayerType.torn
              : DesignLayerType.cell,
          photoId: photos[i].id,
          photoSlot: i,
          layoutSlot: i,
          z: i,
          radius: mode == DesignMode.masonry ? 4 : 0,
          rotation: mode == DesignMode.torn ? (i.isEven ? -2 : 2.5) : 0,
          seed: 31 + i * 17,
          tearStyle: TearStyle.values[i % 4]));
      if (mode == DesignMode.editorial) {
        layers.add(DesignLayer(
            id: id(),
            type: DesignLayerType.caption,
            layoutSlot: i,
            photoId: photos[i].id,
            photoSlot: i,
            z: 20 + i,
            text: TextOverlay(
                id: id(),
                text: '',
                fontSize: 13,
                color: 0xFF202020,
                fontFamily: 'serif',
                padding: 0)));
      }
    }
    if (mode == DesignMode.detail && photos.isNotEmpty) {
      for (var i = 0; i < 2; i++) {
        layers.add(DesignLayer(
            id: id(),
            type: DesignLayerType.callout,
            photoId: photos.first.id,
            x: i == 0 ? .25 : .75,
            y: .77,
            width: .38,
            height: .23,
            z: 20 + i,
            borderWidth: 2,
            shape: i == 0 ? CalloutShape.circle : CalloutShape.rounded,
            radius: 12,
            crop: Rect.fromLTWH(.12 + i * .43, .25, .25, .25),
            endpoint: const Offset(.5, 0)));
      }
    }
    if (key == 'edTravel') {
      layers.add(DesignLayer(
          id: id(),
          type: DesignLayerType.location,
          x: .5,
          y: .92,
          width: .76,
          height: .11,
          z: 40,
          radius: 8,
          text: TextOverlay(
              id: id(),
              text: '${tr('edEvenings')}\n${tr('edLocationExample')}',
              fontSize: 19,
              color: 0xFFFFFFFF,
              backgroundColor: 0x88000000,
              padding: 8,
              cornerRadius: 8)));
    }
    design = design.copyWith(layers: layers);
    return reflow(design);
  }

  /// Writes geometry into scene data; both preview and export consume it verbatim.
  /// Existing layer IDs, captions and photo edits survive spacing changes.
  static EditorialDesign reflow(EditorialDesign design) {
    final cells = design.layers
        .where((l) => l.isPhoto && l.layoutSlot >= 0)
        .toList()
      ..sort((a, b) => a.layoutSlot.compareTo(b.layoutSlot));
    if (cells.isEmpty) return design;
    final n = cells.length;
    final m = design.margin;
    final top = m + design.header;
    final availableH = 1 - top - m;
    final bounds = <int, Rect>{};
    if (design.mode == DesignMode.detail) {
      bounds[cells.first.layoutSlot] = const Rect.fromLTWH(0, 0, 1, 1);
    } else if (design.mode == DesignMode.torn) {
      final gap = math.min(design.gapY, availableH / (n * 3));
      final h = (availableH - gap * (n - 1)) / n;
      for (var i = 0; i < n; i++) {
        bounds[cells[i].layoutSlot] =
            Rect.fromLTWH(m, top + i * (h + gap), 1 - 2 * m, h);
      }
    } else if (design.mode == DesignMode.editorial) {
      final columns = math.min(design.columns, n);
      final rows = (n / columns).ceil();
      final gx = math.min(design.gapX, (1 - 2 * m) / (columns * 3));
      final gy = math.min(design.gapY, availableH / (rows * 3));
      final w = (1 - 2 * m - gx * (columns - 1)) / columns;
      final rowH = (availableH - gy * (rows - 1)) / rows;
      final captionH = math.min(.035, rowH * .24);
      for (var i = 0; i < n; i++) {
        bounds[cells[i].layoutSlot] = Rect.fromLTWH(
            m + (i % columns) * (w + gx),
            top + (i ~/ columns) * (rowH + gy),
            w,
            rowH - captionH);
      }
    } else {
      final cols = math.min(n, design.variant == 1 && n >= 6 ? 3 : 2);
      final gx = math.min(design.gapX, (1 - 2 * m) / (cols * 3));
      final widths = cols == 2 && design.variant == 2
          ? [.6, .4]
          : List.filled(cols, 1 / cols);
      var left = m;
      for (var col = 0; col < cols; col++) {
        final indexes = [for (var i = col; i < n; i += cols) i];
        final weights = [
          for (var j = 0; j < indexes.length; j++)
            1.0 + ((j * 3 + col * 2 + design.variant) % 4) * .45
        ];
        final sum = weights.fold(0.0, (a, b) => a + b);
        final gap = math.min(design.gapY, availableH / (indexes.length * 3));
        final height = availableH - gap * (indexes.length - 1);
        final w = (1 - 2 * m - gx * (cols - 1)) * widths[col];
        var y = top;
        for (var j = 0; j < indexes.length; j++) {
          final h = height * weights[j] / sum;
          bounds[cells[indexes[j]].layoutSlot] = Rect.fromLTWH(left, y, w, h);
          y += h + gap;
        }
        left += w + gx;
      }
    }
    return design.copyWith(layers: [
      for (final l in design.layers)
        if (bounds[l.layoutSlot] case final Rect r when !l.locked)
          if (l.type == DesignLayerType.caption)
            l.copyWith(
                x: r.center.dx,
                y: r.bottom + .018,
                width: r.width,
                height: .035)
          else if (l.isPhoto)
            l.copyWith(
                x: r.center.dx,
                y: r.center.dy,
                width: r.width,
                height: r.height)
          else
            l
        else
          l
    ]);
  }

  static String caption(EditorialDesign design, DesignLayer layer) {
    final number = layer.photoSlot + 1;
    return switch (design.numberStyle) {
      NumberStyle.parentheses => '($number)',
      NumberStyle.plain => '$number',
      NumberStyle.padded => number.toString().padLeft(2, '0'),
      NumberStyle.custom => layer.text.text,
      NumberStyle.hidden => '',
    };
  }
}
