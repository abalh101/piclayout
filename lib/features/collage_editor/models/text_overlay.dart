enum TextOverlayAlignment { left, center, right }

class TextOverlay {
  const TextOverlay({
    required this.id,
    required this.text,
    this.x = 0.5,
    this.y = 0.5,
    this.fontSize = 32,
    this.color = 0xFFFFFFFF,
    this.backgroundColor,
    this.rotation = 0,
    this.alignment = TextOverlayAlignment.center,
  });

  final String id;
  final String text;
  final double x;
  final double y;
  final double fontSize;
  final int color;
  final int? backgroundColor;
  final double rotation; // Degrees.
  final TextOverlayAlignment alignment;

  TextOverlay copyWith({
    String? id,
    String? text,
    double? x,
    double? y,
    double? fontSize,
    int? color,
    Object? backgroundColor = _unchanged,
    double? rotation,
    TextOverlayAlignment? alignment,
  }) {
    return TextOverlay(
      id: id ?? this.id,
      text: text ?? this.text,
      x: (x ?? this.x).clamp(0.0, 1.0).toDouble(),
      y: (y ?? this.y).clamp(0.0, 1.0).toDouble(),
      fontSize: (fontSize ?? this.fontSize).clamp(12.0, 72.0).toDouble(),
      color: color ?? this.color,
      backgroundColor: identical(backgroundColor, _unchanged)
          ? this.backgroundColor
          : backgroundColor as int?,
      rotation: (rotation ?? this.rotation).clamp(-180.0, 180.0).toDouble(),
      alignment: alignment ?? this.alignment,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'text': text,
        'x': x,
        'y': y,
        'fontSize': fontSize,
        'color': color,
        'backgroundColor': backgroundColor,
        'rotation': rotation,
        'alignment': alignment.name,
      };

  static TextOverlay fromJson(Map<String, Object?> json) {
    final alignmentName = json['alignment'] as String?;
    return TextOverlay(
      id: json['id'] as String,
      text: json['text'] as String? ?? '',
      x: 0.5,
      y: 0.5,
      fontSize: 32,
      color: json['color'] as int? ?? 0xFFFFFFFF,
      backgroundColor: json['backgroundColor'] as int?,
      alignment: TextOverlayAlignment.values.firstWhere(
        (value) => value.name == alignmentName,
        orElse: () => TextOverlayAlignment.center,
      ),
    ).copyWith(
      x: (json['x'] as num?)?.toDouble() ?? 0.5,
      y: (json['y'] as num?)?.toDouble() ?? 0.5,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 32,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
    );
  }
}

const Object _unchanged = Object();
