import '../../collage_editor/layouts/layout_library.dart';
import '../../collage_editor/models/aspect_ratio_preset.dart';
import '../../collage_editor/models/canvas_settings.dart';
import '../../collage_editor/models/photo_asset.dart';
import '../../collage_editor/models/text_overlay.dart';

class CollageProject {
  const CollageProject({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.formatVersion,
    required this.aspectRatioId,
    required this.layoutTemplateId,
    required this.photos,
    this.canvas = const CanvasSettings(),
    this.textOverlays = const [],
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int formatVersion;
  final String aspectRatioId;
  final String layoutTemplateId;
  final List<PhotoAsset> photos;
  final CanvasSettings canvas;
  final List<TextOverlay> textOverlays;

  AspectRatioPreset get aspectRatio => AspectRatios.byId(aspectRatioId);

  CollageProject copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? formatVersion,
    String? aspectRatioId,
    String? layoutTemplateId,
    List<PhotoAsset>? photos,
    CanvasSettings? canvas,
    List<TextOverlay>? textOverlays,
  }) {
    return CollageProject(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      formatVersion: formatVersion ?? this.formatVersion,
      aspectRatioId: aspectRatioId ?? this.aspectRatioId,
      layoutTemplateId: layoutTemplateId ?? this.layoutTemplateId,
      photos: photos ?? this.photos,
      canvas: canvas ?? this.canvas,
      textOverlays: textOverlays ?? this.textOverlays,
    );
  }

  CollageProject normalizedForPhotoCount() {
    if (photos.isEmpty) {
      return this;
    }
    final template = LayoutLibrary.byIdOrDefault(
      layoutTemplateId,
      photos.length,
    );
    return copyWith(layoutTemplateId: template.id);
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'formatVersion': formatVersion,
        'aspectRatioId': aspectRatioId,
        'layoutTemplateId': layoutTemplateId,
        'photos': photos.map((photo) => photo.toJson()).toList(),
        'canvas': canvas.toJson(),
        'textOverlays':
            textOverlays.map((overlay) => overlay.toJson()).toList(),
      };

  static CollageProject fromJson(Map<String, Object?> json) {
    return CollageProject(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      formatVersion: json['formatVersion'] as int? ?? 1,
      aspectRatioId: json['aspectRatioId'] as String? ?? AspectRatios.story.id,
      layoutTemplateId: json['layoutTemplateId'] as String,
      photos: (json['photos'] as List? ?? [])
          .map((item) => PhotoAsset.fromJson(Map<String, Object?>.from(item)))
          .toList(),
      canvas: CanvasSettings.fromJson(
        Map<String, Object?>.from(json['canvas'] as Map? ?? {}),
      ),
      textOverlays: (json['textOverlays'] as List? ?? [])
          .map((item) => TextOverlay.fromJson(Map<String, Object?>.from(item)))
          .toList(),
    ).normalizedForPhotoCount();
  }
}
