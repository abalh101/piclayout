enum PhotoFilterPreset {
  original,
  warm,
  cool,
  blackWhite,
  highContrast,
  softFade,
  vivid,
  vintage,
  sepia,
  matte
}

/// Non-destructive edits. Neutral values preserve the source pixels.
class PhotoAdjustments {
  const PhotoAdjustments(
      {this.preset = PhotoFilterPreset.original,
      this.filterIntensity = 1,
      this.brightness = 0,
      this.contrast = 1,
      this.saturation = 1,
      this.warmth = 0,
      this.tint = 0,
      this.highlights = 0,
      this.shadows = 0,
      this.fade = 0,
      this.blackPoint = 0,
      this.vignette = 0});
  final PhotoFilterPreset preset;
  final double filterIntensity, brightness, contrast, saturation, warmth;
  final double tint, highlights, shadows, fade, blackPoint, vignette;
  bool get hasStudioEffects =>
      tint != 0 ||
      highlights != 0 ||
      shadows != 0 ||
      fade != 0 ||
      blackPoint != 0 ||
      vignette != 0;
  PhotoAdjustments copyWith(
          {PhotoFilterPreset? preset,
          double? filterIntensity,
          double? brightness,
          double? contrast,
          double? saturation,
          double? warmth,
          double? tint,
          double? highlights,
          double? shadows,
          double? fade,
          double? blackPoint,
          double? vignette}) =>
      PhotoAdjustments(
          preset: preset ?? this.preset,
          filterIntensity: filterIntensity ?? this.filterIntensity,
          brightness: brightness ?? this.brightness,
          contrast: contrast ?? this.contrast,
          saturation: saturation ?? this.saturation,
          warmth: warmth ?? this.warmth,
          tint: tint ?? this.tint,
          highlights: highlights ?? this.highlights,
          shadows: shadows ?? this.shadows,
          fade: fade ?? this.fade,
          blackPoint: blackPoint ?? this.blackPoint,
          vignette: vignette ?? this.vignette);
  Map<String, Object?> toJson() => {
        'preset': preset.name,
        'filterIntensity': filterIntensity,
        'brightness': brightness,
        'contrast': contrast,
        'saturation': saturation,
        'warmth': warmth,
        'tint': tint,
        'highlights': highlights,
        'shadows': shadows,
        'fade': fade,
        'blackPoint': blackPoint,
        'vignette': vignette
      };
  factory PhotoAdjustments.fromJson(Map<String, Object?> json) {
    double number(String key, double fallback, double min, double max) {
      final value = json[key];
      return value is num && value.isFinite
          ? value.toDouble().clamp(min, max)
          : fallback;
    }

    return PhotoAdjustments(
        preset: PhotoFilterPreset.values.firstWhere(
            (p) => p.name == json['preset'],
            orElse: () => PhotoFilterPreset.original),
        filterIntensity: number('filterIntensity', 1, 0, 1),
        brightness: number('brightness', 0, -1, 1),
        contrast: number('contrast', 1, 0, 2),
        saturation: number('saturation', 1, 0, 2),
        warmth: number('warmth', 0, -1, 1),
        tint: number('tint', 0, -1, 1),
        highlights: number('highlights', 0, -1, 1),
        shadows: number('shadows', 0, -1, 1),
        fade: number('fade', 0, 0, 1),
        blackPoint: number('blackPoint', 0, 0, 1),
        vignette: number('vignette', 0, 0, 1));
  }
}
