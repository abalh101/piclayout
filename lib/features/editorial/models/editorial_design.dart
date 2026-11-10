import 'dart:ui';

import '../../collage_editor/models/photo_asset.dart';
import '../../collage_editor/models/text_overlay.dart';

enum DesignMode { standard, editorial, masonry, torn, detail, blank }

enum DesignLayerType {
  photo,
  cell,
  text,
  caption,
  background,
  torn,
  callout,
  connector,
  location
}

enum NumberStyle { parentheses, plain, padded, custom, hidden }

enum TearStyle { soft, fibrous, deckled, weathered }

enum TearEdges { top, bottom, horizontal, vertical, all }

enum CalloutShape { rectangle, square, circle, rounded }

double bounded(Object? value, double fallback, double min, double max) =>
    value is num && value.isFinite
        ? value.toDouble().clamp(min, max)
        : fallback;

T enumValue<T extends Enum>(List<T> values, Object? name, T fallback) =>
    values.where((v) => v.name == name).firstOrNull ?? fallback;

/// Normalized, immutable scene data. Photo IDs are local references, never paths.
/// photoSlot is used only by reusable templates; live layers bind to stable IDs.
class DesignLayer {
  const DesignLayer({
    required this.id,
    required this.type,
    this.x = .5,
    this.y = .5,
    this.width = .5,
    this.height = .25,
    this.rotation = 0,
    this.opacity = 1,
    this.z = 0,
    this.visible = true,
    this.locked = false,
    this.photoId,
    this.photoSlot = 0,
    this.layoutSlot = -1,
    this.text = const TextOverlay(
        id: 'style', text: '', color: 0xFF202020, fontSize: 16),
    this.color = 0xFFFFFFFF,
    this.radius = 0,
    this.borderWidth = 0,
    this.borderColor = 0xFFFFFFFF,
    this.tearStyle = TearStyle.fibrous,
    this.tearEdges = TearEdges.horizontal,
    this.tearIntensity = .35,
    this.roughness = .5,
    this.shadow = true,
    this.seed = 1,
    this.crop = const Rect.fromLTWH(.25, .25, .5, .5),
    this.shape = CalloutShape.rounded,
    this.connector = true,
    this.lineColor = 0xFFFFFFFF,
    this.lineWidth = 1,
    this.endpoint = const Offset(.5, 1),
    this.showLocationIcon = true,
  });
  final String id;
  final DesignLayerType type;
  final double x, y, width, height, rotation, opacity;
  final int z;
  final bool visible, locked;
  final String? photoId;
  final int photoSlot, layoutSlot;
  final TextOverlay text;
  final int color, borderColor, seed, lineColor;
  final double radius, borderWidth, tearIntensity, roughness, lineWidth;
  final TearStyle tearStyle;
  final TearEdges tearEdges;
  final bool shadow, connector, showLocationIcon;
  final Rect crop;
  final CalloutShape shape;
  final Offset endpoint;

  bool get isPhoto => const [
        DesignLayerType.photo,
        DesignLayerType.cell,
        DesignLayerType.torn,
        DesignLayerType.callout
      ].contains(type);
  bool get isText => const [
        DesignLayerType.text,
        DesignLayerType.caption,
        DesignLayerType.location
      ].contains(type);
  Rect rect(Size size) => Rect.fromCenter(
      center: Offset(x * size.width, y * size.height),
      width: width * size.width,
      height: height * size.height);
  PhotoAsset? source(List<PhotoAsset> photos) => photoId == null
      ? (photoSlot >= 0 && photoSlot < photos.length ? photos[photoSlot] : null)
      : photos.where((p) => p.id == photoId).firstOrNull;

  DesignLayer copyWith(
      {String? id,
      DesignLayerType? type,
      double? x,
      double? y,
      double? width,
      double? height,
      double? rotation,
      double? opacity,
      int? z,
      bool? visible,
      bool? locked,
      String? photoId,
      bool clearPhotoId = false,
      int? photoSlot,
      int? layoutSlot,
      TextOverlay? text,
      int? color,
      double? radius,
      double? borderWidth,
      int? borderColor,
      TearStyle? tearStyle,
      TearEdges? tearEdges,
      double? tearIntensity,
      double? roughness,
      bool? shadow,
      int? seed,
      Rect? crop,
      CalloutShape? shape,
      bool? connector,
      int? lineColor,
      double? lineWidth,
      Offset? endpoint,
      bool? showLocationIcon}) {
    final c = crop ?? this.crop;
    final cw = bounded(c.width, .5, .01, 1);
    final ch = bounded(c.height, .5, .01, 1);
    return DesignLayer(
        id: id ?? this.id,
        type: type ?? this.type,
        x: bounded(x ?? this.x, .5, 0, 1),
        y: bounded(y ?? this.y, .5, 0, 1),
        width: bounded(width ?? this.width, .5, .02, 1.5),
        height: bounded(height ?? this.height, .25, .02, 1.5),
        rotation: bounded(rotation ?? this.rotation, 0, -180, 180),
        opacity: bounded(opacity ?? this.opacity, 1, 0, 1),
        z: z ?? this.z,
        visible: visible ?? this.visible,
        locked: locked ?? this.locked,
        photoId: clearPhotoId ? null : photoId ?? this.photoId,
        photoSlot: photoSlot ?? this.photoSlot,
        layoutSlot: layoutSlot ?? this.layoutSlot,
        text: text ?? this.text,
        color: color ?? this.color,
        radius: bounded(radius ?? this.radius, 0, 0, 100),
        borderWidth: bounded(borderWidth ?? this.borderWidth, 0, 0, 20),
        borderColor: borderColor ?? this.borderColor,
        tearStyle: tearStyle ?? this.tearStyle,
        tearEdges: tearEdges ?? this.tearEdges,
        tearIntensity: bounded(tearIntensity ?? this.tearIntensity, .35, 0, 1),
        roughness: bounded(roughness ?? this.roughness, .5, 0, 1),
        shadow: shadow ?? this.shadow,
        seed: seed ?? this.seed,
        crop: Rect.fromLTWH(bounded(c.left, .25, 0, 1 - cw),
            bounded(c.top, .25, 0, 1 - ch), cw, ch),
        shape: shape ?? this.shape,
        connector: connector ?? this.connector,
        lineColor: lineColor ?? this.lineColor,
        lineWidth: bounded(lineWidth ?? this.lineWidth, 1, 0, 12),
        endpoint: Offset(bounded((endpoint ?? this.endpoint).dx, .5, 0, 1),
            bounded((endpoint ?? this.endpoint).dy, 1, 0, 1)),
        showLocationIcon: showLocationIcon ?? this.showLocationIcon);
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type.name,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'rotation': rotation,
        'opacity': opacity,
        'z': z,
        'visible': visible,
        'locked': locked,
        if (photoId != null) 'photoId': photoId,
        'photoSlot': photoSlot,
        'layoutSlot': layoutSlot,
        'text': text.toJson(),
        'color': color,
        'radius': radius,
        'borderWidth': borderWidth,
        'borderColor': borderColor,
        'tearStyle': tearStyle.name,
        'tearEdges': tearEdges.name,
        'tearIntensity': tearIntensity,
        'roughness': roughness,
        'shadow': shadow,
        'seed': seed,
        'crop': [crop.left, crop.top, crop.width, crop.height],
        'shape': shape.name,
        'connector': connector,
        'lineColor': lineColor,
        'lineWidth': lineWidth,
        'endpoint': [endpoint.dx, endpoint.dy],
        'showLocationIcon': showLocationIcon,
      };

  static DesignLayer? tryParse(Object? value) {
    if (value is! Map) return null;
    try {
      final j = Map<String, Object?>.from(value);
      final type =
          DesignLayerType.values.where((t) => t.name == j['type']).firstOrNull;
      if (type == null || j['id'] is! String || (j['id'] as String).isEmpty) {
        return null;
      }
      double n(String k, double d, double lo, double hi) =>
          bounded(j[k], d, lo, hi);
      final crop = j['crop'];
      final end = j['endpoint'];
      return DesignLayer(
        id: j['id'] as String,
        type: type,
        photoId: j['photoId'] as String?,
        photoSlot: bounded(j['photoSlot'], 0, 0, 11).round(),
        layoutSlot: bounded(j['layoutSlot'], -1, -1, 199).round(),
        z: bounded(j['z'], 0, -10000, 10000).round(),
        visible: j['visible'] != false,
        locked: j['locked'] == true,
        text: j['text'] is Map
            ? TextOverlay.fromJson(Map<String, Object?>.from(j['text'] as Map))
            : const TextOverlay(id: 'style', text: ''),
        color: j['color'] as int? ?? 0xFFFFFFFF,
        borderColor: j['borderColor'] as int? ?? 0xFFFFFFFF,
        tearStyle:
            enumValue(TearStyle.values, j['tearStyle'], TearStyle.fibrous),
        tearEdges:
            enumValue(TearEdges.values, j['tearEdges'], TearEdges.horizontal),
        shape: enumValue(CalloutShape.values, j['shape'], CalloutShape.rounded),
        shadow: j['shadow'] != false,
        connector: j['connector'] != false,
        seed: j['seed'] as int? ?? 1,
        lineColor: j['lineColor'] as int? ?? 0xFFFFFFFF,
        showLocationIcon: j['showLocationIcon'] != false,
      ).copyWith(
          x: n('x', .5, 0, 1),
          y: n('y', .5, 0, 1),
          width: n('width', .5, .02, 1.5),
          height: n('height', .25, .02, 1.5),
          rotation: n('rotation', 0, -180, 180),
          opacity: n('opacity', 1, 0, 1),
          radius: n('radius', 0, 0, 100),
          borderWidth: n('borderWidth', 0, 0, 20),
          tearIntensity: n('tearIntensity', .35, 0, 1),
          roughness: n('roughness', .5, 0, 1),
          lineWidth: n('lineWidth', 1, 0, 12),
          crop: crop is List && crop.length == 4
              ? Rect.fromLTWH(
                  bounded(crop[0], .25, 0, 1),
                  bounded(crop[1], .25, 0, 1),
                  bounded(crop[2], .5, .01, 1),
                  bounded(crop[3], .5, .01, 1))
              : null,
          endpoint: end is List && end.length == 2
              ? Offset(bounded(end[0], .5, 0, 1), bounded(end[1], 1, 0, 1))
              : null);
    } on TypeError {
      return null;
    } on FormatException {
      return null;
    }
  }
}

class EditorialDesign {
  const EditorialDesign(
      {this.mode = DesignMode.standard,
      this.layers = const [],
      this.preset = '',
      this.columns = 3,
      this.margin = .06,
      this.gapX = .025,
      this.gapY = .07,
      this.header = .15,
      this.numberStyle = NumberStyle.parentheses,
      this.variant = 0});
  final DesignMode mode;
  final List<DesignLayer> layers;
  final String preset;
  final int columns, variant;
  final double margin, gapX, gapY, header;
  final NumberStyle numberStyle;
  bool get active => mode != DesignMode.standard;
  List<DesignLayer> get ordered {
    final indexed = layers.indexed.toList()
      ..sort((a, b) {
        final z = a.$2.z.compareTo(b.$2.z);
        return z != 0 ? z : a.$1.compareTo(b.$1);
      });
    return indexed.map((v) => v.$2).toList();
  }

  EditorialDesign copyWith(
          {DesignMode? mode,
          List<DesignLayer>? layers,
          String? preset,
          int? columns,
          double? margin,
          double? gapX,
          double? gapY,
          double? header,
          NumberStyle? numberStyle,
          int? variant}) =>
      EditorialDesign(
          mode: mode ?? this.mode,
          layers: List.unmodifiable(layers ?? this.layers),
          preset: preset ?? this.preset,
          columns: (columns ?? this.columns).clamp(1, 4),
          margin: bounded(margin ?? this.margin, .06, 0, .18),
          gapX: bounded(gapX ?? this.gapX, .025, 0, .1),
          gapY: bounded(gapY ?? this.gapY, .07, 0, .12),
          header: bounded(header ?? this.header, .15, 0, .3),
          numberStyle: numberStyle ?? this.numberStyle,
          variant: variant ?? this.variant);

  EditorialDesign remapPhotos(Map<String, String> ids) => copyWith(
      layers: [for (final l in layers) l.copyWith(photoId: ids[l.photoId])]);

  EditorialDesign asTemplate(List<PhotoAsset> photos,
          {required bool includeText}) =>
      copyWith(layers: [
        for (var i = 0; i < layers.length; i++)
          if (includeText ||
              !layers[i].isText ||
              (layers[i].type == DesignLayerType.caption &&
                  numberStyle != NumberStyle.custom))
            layers[i].copyWith(
                id: 'layer-$i',
                clearPhotoId: true,
                photoSlot: photos
                    .indexWhere((p) => p.id == layers[i].photoId)
                    .clamp(0, 11),
                text: includeText
                    ? layers[i].text.copyWith(id: 'text-$i')
                    : const TextOverlay(id: 'style', text: '')),
      ]);
  EditorialDesign bindPhotos(List<PhotoAsset> photos) => copyWith(layers: [
        for (final l in layers)
          l.copyWith(
              photoId: photos.isEmpty
                  ? null
                  : photos[l.photoSlot.clamp(0, photos.length - 1)].id),
      ]);
  Map<String, Object?> toJson() => {
        'version': 1,
        'mode': mode.name,
        'preset': preset,
        'columns': columns,
        'margin': margin,
        'gapX': gapX,
        'gapY': gapY,
        'header': header,
        'numberStyle': numberStyle.name,
        'variant': variant,
        'layers': layers.map((l) => l.toJson()).toList()
      };
  static EditorialDesign fromJson(Object? value) {
    if (value is! Map || (value['version'] ?? 1) != 1) {
      return const EditorialDesign();
    }
    final ids = <String>{};
    return EditorialDesign(
      mode: enumValue(DesignMode.values, value['mode'], DesignMode.standard),
      preset: value['preset'] is String ? value['preset'] as String : '',
      numberStyle: enumValue(
          NumberStyle.values, value['numberStyle'], NumberStyle.parentheses),
      layers: List.unmodifiable(value['layers'] is List
          ? (value['layers'] as List)
              .take(200)
              .map(DesignLayer.tryParse)
              .whereType<DesignLayer>()
              .where((l) => ids.add(l.id))
          : <DesignLayer>[]),
    ).copyWith(
        columns: bounded(value['columns'], 3, 1, 4).round(),
        margin: bounded(value['margin'], .06, 0, .18),
        gapX: bounded(value['gapX'], .025, 0, .1),
        gapY: bounded(value['gapY'], .07, 0, .12),
        header: bounded(value['header'], .15, 0, .3),
        variant: bounded(value['variant'], 0, 0, 2).round());
  }
}
