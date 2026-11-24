import '../../collage_editor/models/canvas_settings.dart';
import '../../collage_editor/models/canvas_style.dart';
import '../../collage_editor/models/photo_placement.dart';
import 'collage_template.dart';

class BuiltInDesigns {
  const BuiltInDesigns._();

  static const all = [
    CollageTemplate(
      id: 'builtin_before_after',
      name: 'templateBeforeAfter',
      photoCount: 2,
      aspectRatioId: '16_9',
      layoutTemplateId: 'grid_2x1_2',
      canvas: CanvasSettings(
          backgroundColor: 0xFF1E252B,
          spacing: 4,
          outerMargin: 10,
          cornerRadius: 2),
    ),
    CollageTemplate(
      id: 'builtin_magazine',
      name: 'templateEditorial',
      photoCount: 3,
      aspectRatioId: '4_5',
      layoutTemplateId: 'hero_top_3',
      canvas: CanvasSettings(
          backgroundColor: 0xFFFCF5EB,
          spacing: 8,
          outerMargin: 18,
          style: CanvasStyle(
              frameEnabled: true, frameColor: 0xFF3E342E, frameWidth: 1)),
    ),
    CollageTemplate(
      id: 'builtin_travel',
      name: 'templateTravel',
      photoCount: 4,
      aspectRatioId: '4_3',
      layoutTemplateId: 'grid_2x2_4',
      canvas: CanvasSettings(
          backgroundColor: 0xFFD9E8EA,
          spacing: 16,
          outerMargin: 26,
          cornerRadius: 9,
          style: CanvasStyle(
              shadowEnabled: true, shadowOpacity: .22, shadowSoftness: 6)),
    ),
    CollageTemplate(
      id: 'builtin_geometry',
      name: 'templateGeometric',
      photoCount: 6,
      aspectRatioId: '9_16',
      layoutTemplateId: 'staggered_two_columns_6',
      canvas: CanvasSettings(
          backgroundColor: 0xFFEEEAFE,
          spacing: 13,
          outerMargin: 20,
          cornerRadius: 14,
          staggerAmount: .10,
          style: CanvasStyle(backgroundType: BackgroundType.grid)),
    ),
    CollageTemplate(
      id: 'builtin_instant',
      name: 'templatePolaroid',
      photoCount: 2,
      aspectRatioId: '1_1',
      layoutTemplateId: 'grid_2x1_2',
      freestyle: true,
      placements: [
        PhotoPlacement(
            x: .34,
            y: .43,
            width: .52,
            height: .61,
            rotation: -12,
            border: .055,
            shadow: true),
        PhotoPlacement(
            x: .65,
            y: .57,
            width: .51,
            height: .57,
            rotation: 11,
            border: .055,
            shadow: true),
      ],
      canvas: CanvasSettings(
          backgroundColor: 0xFFDCB9A8,
          style: CanvasStyle(backgroundType: BackgroundType.paper)),
    ),
    CollageTemplate(
      id: 'builtin_diary',
      name: 'templateDiary',
      photoCount: 3,
      aspectRatioId: '3_4',
      layoutTemplateId: 'hero_top_3',
      freestyle: true,
      placements: [
        PhotoPlacement(
            x: .49,
            y: .31,
            width: .79,
            height: .35,
            rotation: -3,
            radius: .08,
            shadow: true),
        PhotoPlacement(
            x: .30, y: .69, width: .42, height: .36, rotation: -7, border: .04),
        PhotoPlacement(
            x: .70, y: .66, width: .40, height: .32, rotation: 8, border: .04),
      ],
      canvas: CanvasSettings(
          backgroundColor: 0xFFF3E9C8,
          style: CanvasStyle(backgroundType: BackgroundType.dots)),
    ),
  ];
}
