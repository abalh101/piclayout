class CanvasSettings {
  const CanvasSettings({
    this.spacing = 2,
    this.outerMargin = 0,
    this.cornerRadius = 0,
    this.backgroundColor = 0xFFFFFFFF,
    this.staggerAmount = 0,
  });

  final double spacing;
  final double outerMargin;
  final double cornerRadius;
  final int backgroundColor;
  final double staggerAmount;

  CanvasSettings copyWith({
    double? spacing,
    double? outerMargin,
    double? cornerRadius,
    int? backgroundColor,
    double? staggerAmount,
  }) {
    return CanvasSettings(
      spacing: spacing ?? this.spacing,
      outerMargin: outerMargin ?? this.outerMargin,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      staggerAmount: staggerAmount ?? this.staggerAmount,
    );
  }

  Map<String, Object?> toJson() => {
        'spacing': spacing,
        'outerMargin': outerMargin,
        'cornerRadius': cornerRadius,
        'backgroundColor': backgroundColor,
        'staggerAmount': staggerAmount,
      };

  static CanvasSettings fromJson(Map<String, Object?> json) {
    return CanvasSettings(
      spacing: (json['spacing'] as num?)?.toDouble() ?? 2,
      outerMargin: (json['outerMargin'] as num?)?.toDouble() ?? 0,
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 0,
      backgroundColor: json['backgroundColor'] as int? ?? 0xFFFFFFFF,
      staggerAmount: (json['staggerAmount'] as num?)?.toDouble() ?? 0,
    );
  }
}
