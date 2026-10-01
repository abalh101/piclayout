import 'package:uuid/uuid.dart';

import '../../collage_editor/layouts/layout_library.dart';
import '../../collage_editor/models/aspect_ratio_preset.dart';
import '../../collage_editor/models/canvas_settings.dart';
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
  });

  final String id;
  final String name;
  final int photoCount;
  final String aspectRatioId;
  final String layoutTemplateId;
  final CanvasSettings canvas;
  final bool includeTextOverlays;
  final List<TextOverlay> textOverlays;

  factory CollageTemplate.fromProject({
    required String id,
    required String name,
    required CollageProject project,
    required bool includeTextOverlays,
  }) {
    return CollageTemplate(
      id: id,
      name: name.trim(),
      photoCount: project.photos.length,
      aspectRatioId: project.aspectRatioId,
      layoutTemplateId: project.layoutTemplateId,
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
      aspectRatioId: AspectRatios.byId(aspectRatioId).id,
      layoutTemplateId: layout.id,
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
        'id': id,
        'name': name,
        'photoCount': photoCount,
        'aspectRatioId': aspectRatioId,
        'layoutTemplateId': layoutTemplateId,
        'canvas': canvas.toJson(),
        'includeTextOverlays': includeTextOverlays,
        'textOverlays': includeTextOverlays
            ? textOverlays.map((overlay) => overlay.toJson()).toList()
            : const <Object>[],
      };

  factory CollageTemplate.fromJson(Map<String, Object?> json) {
    final includeText = json['includeTextOverlays'] as bool? ?? false;
    return CollageTemplate(
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
