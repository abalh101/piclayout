import '../../stickers/sticker_overlay.dart';
import '../../custom_layouts/models/custom_layout.dart';
import 'package:uuid/uuid.dart';

import '../../collage_editor/layouts/layout_library.dart';
import '../../collage_editor/models/aspect_ratio_preset.dart';
import '../../collage_editor/models/canvas_settings.dart';
import '../../collage_editor/models/photo_placement.dart';
import '../../collage_editor/models/text_overlay.dart';
import '../../projects/models/collage_project.dart';

class CollageTemplate {
  const CollageTemplate({
    required this.id,
    required this.name,
    required this.photoCount,
    required this.aspectRatioId,
    required this.layoutTemplateId,
    required this.canvas,
    this.includeTextOverlays = false,
    this.textOverlays = const [],
    this.customLayout,
    this.includeStickers = false,
    this.stickers = const [],
    this.freestyle = false,
    this.placements = const [],
  });

  final bool includeStickers;
  final List<StickerOverlay> stickers;
  final String id;
  final String name;
  final int photoCount;
  final String aspectRatioId;
  final String layoutTemplateId;
  final CustomLayout? customLayout;
  final CanvasSettings canvas;
  final bool includeTextOverlays;
  final List<TextOverlay> textOverlays;
  final bool freestyle;
  final List<PhotoPlacement?> placements;

  factory CollageTemplate.fromProject({
    required String id,
    required String name,
    required CollageProject project,
    required bool includeTextOverlays,
    bool includeStickers = false,
  }) {
    return CollageTemplate(
      includeStickers: includeStickers,
      stickers: includeStickers ? List.of(project.stickers) : const [],
      id: id,
      name: name.trim(),
      photoCount: project.photos.length,
      aspectRatioId: project.aspectRatioId,
      layoutTemplateId: project.layoutTemplateId,
      customLayout: project.customLayout,
      freestyle: project.freestyle,
      placements: project.freestyle
          ? [for (final photo in project.photos) photo.placement]
          : const [],
      canvas: project.canvas,
      includeTextOverlays: includeTextOverlays,
      textOverlays:
          includeTextOverlays ? List.of(project.textOverlays) : const [],
    );
  }

  CollageProject applyTo(CollageProject project) {
    final layout = LayoutLibrary.byIdOrDefault(
      layoutTemplateId,
      project.photos.length,
    );
    return project.copyWith(
      stickers: includeStickers
          ? [for (final s in stickers) s.copyWith(id: const Uuid().v4())]
          : project.stickers,
      aspectRatioId: AspectRatios.byId(aspectRatioId).id,
      freestyle: freestyle,
      photos: freestyle
          ? [
              for (var i = 0; i < project.photos.length; i++)
                project.photos[i].copyWith(
                  placement: i < placements.length
                      ? placements[i]
                      : const PhotoPlacement(),
                  clearPlacement:
                      i < placements.length && placements[i] == null,
                ),
            ]
          : project.photos,
      layoutTemplateId: layout.id,
      customLayout: customLayout?.photoCount == project.photos.length
          ? customLayout
          : null,
      clearCustomLayout: customLayout?.photoCount != project.photos.length,
      canvas: canvas,
      textOverlays: includeTextOverlays
          ? [
              for (final overlay in textOverlays)
                overlay.copyWith(id: const Uuid().v4()),
            ]
          : project.textOverlays,
    );
  }

  Map<String, Object?> toJson() => {
        'includeStickers': includeStickers,
        'stickers': includeStickers
            ? stickers.map((s) => s.toJson()).toList()
            : const <Object>[],
        'id': id,
        'name': name,
        'photoCount': photoCount,
        'aspectRatioId': aspectRatioId,
        if (freestyle) 'freestyle': true,
        if (freestyle)
          'placements': [for (final item in placements) item?.toJson()],
        'layoutTemplateId': layoutTemplateId,
        if (customLayout != null) 'customLayout': customLayout!.toJson(),
        'canvas': canvas.toJson(),
        'includeTextOverlays': includeTextOverlays,
        'textOverlays': includeTextOverlays
            ? textOverlays.map((overlay) => overlay.toJson()).toList()
            : const <Object>[],
      };

  factory CollageTemplate.fromJson(Map<String, Object?> json) {
    final includeText = json['includeTextOverlays'] as bool? ?? false;
    return CollageTemplate(
      includeStickers: json['includeStickers'] == true,
      stickers: json['includeStickers'] == true
          ? StickerOverlay.parseList(json['stickers'])
          : const [],
      customLayout: CustomLayout.tryParse(json['customLayout']),
      freestyle: json['freestyle'] == true,
      placements: json['placements'] is List
          ? (json['placements'] as List)
              .take(12)
              .map(PhotoPlacement.tryParse)
              .toList()
          : const [],
      id: json['id'] as String,
      name: json['name'] as String,
      photoCount: json['photoCount'] as int? ?? 0,
      aspectRatioId: json['aspectRatioId'] as String? ?? AspectRatios.story.id,
      layoutTemplateId: json['layoutTemplateId'] as String,
      canvas: CanvasSettings.fromJson(
        Map<String, Object?>.from(json['canvas'] as Map? ?? {}),
      ),
      includeTextOverlays: includeText,
      textOverlays: includeText
          ? (json['textOverlays'] as List? ?? [])
              .map((item) =>
                  TextOverlay.fromJson(Map<String, Object?>.from(item)))
              .toList()
          : const [],
    );
  }
}
