enum BackgroundType { solid, gradient, blur, paper, grid, dots, transparent }

class CanvasStyle {
  const CanvasStyle({
    this.backgroundType = BackgroundType.solid,
    this.gradientEndColor = 0xFFB9E9E4,
    this.gradientAngle = 45,
    this.blurPhotoIndex = 0,
    this.blurSigma = 16,
    this.brightness = 0,
    this.desaturate = false,
    this.frameEnabled = false,
    this.frameColor = 0xFFFFFFFF,
    this.frameWidth = 3,
    this.shadowEnabled = false,
    this.shadowOpacity = 0.25,
    this.shadowSoftness = 8,
  });
  final BackgroundType backgroundType;
  final int gradientEndColor;
  final double gradientAngle;
  final int blurPhotoIndex;
  final double blurSigma;
  final double brightness;
  final bool desaturate;
  final bool frameEnabled;
  final int frameColor;
  final double frameWidth;
  final bool shadowEnabled;
  final double shadowOpacity;
  final double shadowSoftness;
  CanvasStyle copyWith(
          {BackgroundType? backgroundType,
          int? gradientEndColor,
          double? gradientAngle,
          int? blurPhotoIndex,
          double? blurSigma,
          double? brightness,
          bool? desaturate,
          bool? frameEnabled,
          int? frameColor,
          double? frameWidth,
          bool? shadowEnabled,
          double? shadowOpacity,
          double? shadowSoftness}) =>
      CanvasStyle(
          backgroundType: backgroundType ?? this.backgroundType,
          gradientEndColor: gradientEndColor ?? this.gradientEndColor,
          gradientAngle: gradientAngle ?? this.gradientAngle,
          blurPhotoIndex: blurPhotoIndex ?? this.blurPhotoIndex,
          blurSigma: blurSigma ?? this.blurSigma,
          brightness: brightness ?? this.brightness,
          desaturate: desaturate ?? this.desaturate,
          frameEnabled: frameEnabled ?? this.frameEnabled,
          frameColor: frameColor ?? this.frameColor,
          frameWidth: frameWidth ?? this.frameWidth,
          shadowEnabled: shadowEnabled ?? this.shadowEnabled,
          shadowOpacity: shadowOpacity ?? this.shadowOpacity,
          shadowSoftness: shadowSoftness ?? this.shadowSoftness);
  Map<String, Object?> toJson() => {
        'backgroundType': backgroundType.name,
        'gradientEndColor': gradientEndColor,
        'gradientAngle': gradientAngle,
        'blurPhotoIndex': blurPhotoIndex,
        'blurSigma': blurSigma,
        'brightness': brightness,
        'desaturate': desaturate,
        'frameEnabled': frameEnabled,
        'frameColor': frameColor,
        'frameWidth': frameWidth,
        'shadowEnabled': shadowEnabled,
        'shadowOpacity': shadowOpacity,
        'shadowSoftness': shadowSoftness
      };
  factory CanvasStyle.fromJson(Map<String, Object?> json) => CanvasStyle(
        backgroundType: BackgroundType.values.firstWhere(
            (value) => value.name == json['backgroundType'],
            orElse: () => BackgroundType.solid),
        gradientEndColor: json['gradientEndColor'] as int? ?? 0xFFB9E9E4,
        gradientAngle: ((json['gradientAngle'] as num?)?.toDouble() ?? 45)
            .clamp(-180.0, 180.0)
            .toDouble(),
        blurPhotoIndex: (json['blurPhotoIndex'] as int? ?? 0).clamp(0, 11),
        blurSigma: ((json['blurSigma'] as num?)?.toDouble() ?? 16)
            .clamp(0.0, 40.0)
            .toDouble(),
        brightness: ((json['brightness'] as num?)?.toDouble() ?? 0)
            .clamp(-1.0, 1.0)
            .toDouble(),
        desaturate: json['desaturate'] as bool? ?? false,
        frameEnabled: json['frameEnabled'] as bool? ?? false,
        frameColor: json['frameColor'] as int? ?? 0xFFFFFFFF,
        frameWidth: ((json['frameWidth'] as num?)?.toDouble() ?? 3)
            .clamp(0.0, 20.0)
            .toDouble(),
        shadowEnabled: json['shadowEnabled'] as bool? ?? false,
        shadowOpacity: ((json['shadowOpacity'] as num?)?.toDouble() ?? 0.25)
            .clamp(0.0, 1.0)
            .toDouble(),
        shadowSoftness: ((json['shadowSoftness'] as num?)?.toDouble() ?? 8)
            .clamp(0.0, 30.0)
            .toDouble(),
      );
}
