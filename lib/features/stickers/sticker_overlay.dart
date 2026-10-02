enum StickerType { emoji, icon, shape, label }

enum StickerCategory { emojis, shapes, arrows, hearts, story, labels }

/// Catalogue IDs and plain text only; never a file or network image source.
class StickerOverlay {
  const StickerOverlay(
      {required this.id,
      required this.type,
      required this.content,
      this.x = .5,
      this.y = .5,
      this.scale = 1,
      this.rotation = 0,
      this.color = 0xFFFF477E,
      this.backgroundColor,
      this.opacity = 1});
  final String id, content;
  final StickerType type;
  final double x, y, scale, rotation, opacity;
  final int color;
  final int? backgroundColor;
  // Project list order is the persistent back-to-front z-order.
  StickerOverlay copyWith(
          {String? id,
          String? content,
          double? x,
          double? y,
          double? scale,
          double? rotation,
          int? color,
          double? opacity,
          int? backgroundColor,
          bool clearBackground = false}) =>
      StickerOverlay(
          id: id ?? this.id,
          type: type,
          content: content ?? this.content,
          x: _bounded(x ?? this.x, .5, 0, 1),
          y: _bounded(y ?? this.y, .5, 0, 1),
          scale: _bounded(scale ?? this.scale, 1, .25, 4),
          rotation: _bounded(rotation ?? this.rotation, 0, -180, 180),
          opacity: _bounded(opacity ?? this.opacity, 1, 0, 1),
          color: color ?? this.color,
          backgroundColor:
              clearBackground ? null : backgroundColor ?? this.backgroundColor);
  Map<String, Object?> toJson() => {
        'id': id,
        'type': type.name,
        'content': content,
        'x': x,
        'y': y,
        'scale': scale,
        'rotation': rotation,
        'color': color,
        'backgroundColor': backgroundColor,
        'opacity': opacity,
      };
  static StickerOverlay? tryParse(Object? value) {
    try {
      final json = Map<String, Object?>.from(value as Map);
      final type = StickerType.values.byName(json['type'] as String);
      final content = json['content'] as String;
      final id = json['id'] as String;
      if (id.isEmpty ||
          content.length > 120 ||
          (type != StickerType.label &&
              !StickerCatalog.items
                  .any((e) => e.type == type && e.content == content))) {
        return null;
      }
      return StickerOverlay(
              id: id,
              type: type,
              content: content,
              color: json['color'] as int? ?? 0xFFFF477E,
              backgroundColor: json['backgroundColor'] as int?)
          .copyWith(
              x: (json['x'] as num?)?.toDouble(),
              y: (json['y'] as num?)?.toDouble(),
              scale: (json['scale'] as num?)?.toDouble(),
              rotation: (json['rotation'] as num?)?.toDouble(),
              opacity: (json['opacity'] as num?)?.toDouble());
    } on TypeError {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  static List<StickerOverlay> parseList(Object? value) {
    if (value is! List) return [];
    final ids = <String>{};
    return [
      for (final item in value)
        if (tryParse(item) case final sticker?)
          if (ids.add(sticker.id)) sticker
    ];
  }
}

double _bounded(double value, double fallback, double min, double max) =>
    value.isFinite ? value.clamp(min, max).toDouble() : fallback;

class StickerDefinition {
  const StickerDefinition(
      this.category, this.type, this.content, this.labelKey);
  final StickerCategory category;
  final StickerType type;
  final String content, labelKey;
  StickerOverlay create(String id, {String? label}) => StickerOverlay(
      id: id,
      type: type,
      content: label ?? content,
      backgroundColor: type == StickerType.label ? 0xFFFFFFFF : null);
}

class StickerCatalog {
  static const items = <StickerDefinition>[
    StickerDefinition(
        StickerCategory.emojis, StickerType.emoji, '❤️', 'stHeart'),
    StickerDefinition(
        StickerCategory.emojis, StickerType.emoji, '✨', 'stSparkles'),
    StickerDefinition(StickerCategory.emojis, StickerType.emoji, '⭐', 'stStar'),
    StickerDefinition(StickerCategory.emojis, StickerType.emoji, '📍', 'stPin'),
    StickerDefinition(
        StickerCategory.emojis, StickerType.emoji, '😊', 'stSmile'),
    StickerDefinition(
        StickerCategory.emojis, StickerType.emoji, '🔥', 'stFire'),
    StickerDefinition(
        StickerCategory.shapes, StickerType.shape, 'circle', 'stCircle'),
    StickerDefinition(
        StickerCategory.shapes, StickerType.shape, 'rectangle', 'stRectangle'),
    StickerDefinition(
        StickerCategory.shapes, StickerType.shape, 'rounded', 'stRounded'),
    StickerDefinition(
        StickerCategory.shapes, StickerType.shape, 'line', 'stLine'),
    StickerDefinition(
        StickerCategory.shapes, StickerType.shape, 'bubble', 'stBubble'),
    StickerDefinition(
        StickerCategory.arrows, StickerType.icon, 'left', 'stLeft'),
    StickerDefinition(
        StickerCategory.arrows, StickerType.icon, 'right', 'stRight'),
    StickerDefinition(StickerCategory.arrows, StickerType.icon, 'up', 'stUp'),
    StickerDefinition(
        StickerCategory.arrows, StickerType.icon, 'down', 'stDown'),
    StickerDefinition(
        StickerCategory.hearts, StickerType.icon, 'heart', 'stHeart'),
    StickerDefinition(
        StickerCategory.hearts, StickerType.icon, 'star', 'stStar'),
    StickerDefinition(StickerCategory.story, StickerType.icon, 'pin', 'stPin'),
    StickerDefinition(
        StickerCategory.story, StickerType.icon, 'camera', 'stCamera'),
    StickerDefinition(
        StickerCategory.story, StickerType.icon, 'celebration', 'stParty'),
    StickerDefinition(
        StickerCategory.story, StickerType.label, 'WOW!', 'stWow'),
    StickerDefinition(
        StickerCategory.labels, StickerType.label, 'date', 'stDate'),
    StickerDefinition(
        StickerCategory.labels, StickerType.label, 'place', 'stPlace'),
  ];
}
