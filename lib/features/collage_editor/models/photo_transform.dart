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
    return PhotoTransform(
      scale: (json['scale'] as num?)?.toDouble() ?? 1,
      offsetX: (json['offsetX'] as num?)?.toDouble() ?? 0,
      offsetY: (json['offsetY'] as num?)?.toDouble() ?? 0,
      rotationQuarterTurns: json['rotationQuarterTurns'] as int? ?? 0,
      flipX: json['flipX'] as bool? ?? false,
      fitMode: PhotoFitMode.values.firstWhere(
        (mode) => mode.name == json['fitMode'],
        orElse: () => PhotoFitMode.fill,
      ),
    );
  }

  static const identity = PhotoTransform();
}
