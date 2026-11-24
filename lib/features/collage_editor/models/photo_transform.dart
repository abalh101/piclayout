enum PhotoFitMode { fill, fit }

class PhotoTransform {
  const PhotoTransform({
    this.scale = 1,
    this.offsetX = 0,
    this.offsetY = 0,
    this.rotationQuarterTurns = 0,
    this.flipX = false,
    this.fitMode = PhotoFitMode.fill,
  });

  final double scale;
  final double offsetX;
  final double offsetY;
  final int rotationQuarterTurns;
  final bool flipX;
  final PhotoFitMode fitMode;

  PhotoTransform copyWith({
    double? scale,
    double? offsetX,
    double? offsetY,
    int? rotationQuarterTurns,
    bool? flipX,
    PhotoFitMode? fitMode,
  }) {
    return PhotoTransform(
      scale: scale ?? this.scale,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      rotationQuarterTurns:
          (rotationQuarterTurns ?? this.rotationQuarterTurns) % 4,
      flipX: flipX ?? this.flipX,
      fitMode: fitMode ?? this.fitMode,
    );
  }

  Map<String, Object?> toJson() => {
        'scale': scale,
        'offsetX': offsetX,
        'offsetY': offsetY,
        'rotationQuarterTurns': rotationQuarterTurns,
        'flipX': flipX,
        'fitMode': fitMode.name,
      };

  static PhotoTransform fromJson(Map<String, Object?> json) {
    double finite(Object? value, double fallback) =>
        value is num && value.isFinite ? value.toDouble() : fallback;
    return PhotoTransform(
      scale: finite(json['scale'], 1),
      offsetX: finite(json['offsetX'], 0),
      offsetY: finite(json['offsetY'], 0),
      rotationQuarterTurns: json['rotationQuarterTurns'] is int
          ? (json['rotationQuarterTurns'] as int) % 4
          : 0,
      flipX: json['flipX'] == true,
      fitMode: PhotoFitMode.values.firstWhere(
        (mode) => mode.name == json['fitMode'],
        orElse: () => PhotoFitMode.fill,
      ),
    );
  }

  static const identity = PhotoTransform();
}
