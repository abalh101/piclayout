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
      this.warmth = 0});
  final PhotoFilterPreset preset;
  final double filterIntensity, brightness, contrast, saturation, warmth;
  PhotoAdjustments copyWith(
          {PhotoFilterPreset? preset,
          double? filterIntensity,
          double? brightness,
          double? contrast,
          double? saturation,
          double? warmth}) =>
      PhotoAdjustments(
          preset: preset ?? this.preset,
          filterIntensity: filterIntensity ?? this.filterIntensity,
          brightness: brightness ?? this.brightness,
          contrast: contrast ?? this.contrast,
          saturation: saturation ?? this.saturation,
          warmth: warmth ?? this.warmth);
  Map<String, Object?> toJson() => {
        'preset': preset.name,
        'filterIntensity': filterIntensity,
        'brightness': brightness,
        'contrast': contrast,
        'saturation': saturation,
        'warmth': warmth
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
        warmth: number('warmth', 0, -1, 1));
  }
}
