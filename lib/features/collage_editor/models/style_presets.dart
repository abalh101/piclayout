import 'canvas_settings.dart';
import 'canvas_style.dart';

class StylePreset {
  const StylePreset(this.name, this.settings);
  final String name;
  final CanvasSettings settings;
  static const all = [
    StylePreset('Clean White',
        CanvasSettings(spacing: 8, outerMargin: 16, cornerRadius: 8)),
    StylePreset(
        'Dark Mood',
        CanvasSettings(
            backgroundColor: 0xFF161B26,
            spacing: 10,
            outerMargin: 18,
            cornerRadius: 10,
            style: CanvasStyle(shadowEnabled: true, shadowOpacity: 0.5))),
    StylePreset(
        'Soft Cream',
        CanvasSettings(
            backgroundColor: 0xFFFFF4DE,
            spacing: 12,
            outerMargin: 20,
            cornerRadius: 12,
            style: CanvasStyle(backgroundType: BackgroundType.paper))),
    StylePreset(
        'Instagram Pop',
        CanvasSettings(
            backgroundColor: 0xFFF9A8D4,
            spacing: 12,
            outerMargin: 20,
            cornerRadius: 16,
            style: CanvasStyle(
                backgroundType: BackgroundType.gradient,
                gradientEndColor: 0xFF818CF8,
                frameEnabled: true))),
    StylePreset(
        'Minimal Black',
        CanvasSettings(
            backgroundColor: 0xFF000000, spacing: 4, outerMargin: 12)),
    StylePreset(
        'Travel Bright',
        CanvasSettings(
            backgroundColor: 0xFFE0F2FE,
            spacing: 12,
            outerMargin: 20,
            cornerRadius: 12,
            style: CanvasStyle(
                backgroundType: BackgroundType.gradient,
                gradientEndColor: 0xFFFEF3C7,
                shadowEnabled: true))),
    StylePreset(
        'Blur Poster',
        CanvasSettings(
            spacing: 14,
            outerMargin: 28,
            cornerRadius: 12,
            style: CanvasStyle(
                backgroundType: BackgroundType.blur,
                blurSigma: 20,
                brightness: -0.25,
                desaturate: true,
                frameEnabled: true,
                shadowEnabled: true))),
  ];
}
