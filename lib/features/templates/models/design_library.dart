import '../../collage_editor/models/layout_template.dart';
import 'collage_template.dart';

class FavoriteLayout {
  const FavoriteLayout({required this.id, required this.photoCount});

  final String id;
  final int photoCount;

  factory FavoriteLayout.fromLayout(LayoutTemplate layout) => FavoriteLayout(
        id: layout.id,
        photoCount: layout.photoCount,
      );

  Map<String, Object?> toJson() => {'id': id, 'photoCount': photoCount};

  factory FavoriteLayout.fromJson(Map<String, Object?> json) => FavoriteLayout(
        id: json['id'] as String,
        photoCount: json['photoCount'] as int? ?? 0,
      );
}

class DesignLibrary {
  const DesignLibrary({
    this.favoriteLayouts = const [],
    this.templates = const [],
  });

  final List<FavoriteLayout> favoriteLayouts;
  final List<CollageTemplate> templates;

  bool isFavorite(String id) => favoriteLayouts.any((item) => item.id == id);

  DesignLibrary copyWith({
    List<FavoriteLayout>? favoriteLayouts,
    List<CollageTemplate>? templates,
  }) =>
      DesignLibrary(
        favoriteLayouts: favoriteLayouts ?? this.favoriteLayouts,
        templates: templates ?? this.templates,
      );

  Map<String, Object?> toJson() => {
        'version': 1,
        'favoriteLayouts':
            favoriteLayouts.map((item) => item.toJson()).toList(),
        'templates': templates.map((item) => item.toJson()).toList(),
      };

  factory DesignLibrary.fromJson(Map<String, Object?> json) => DesignLibrary(
        favoriteLayouts: (json['favoriteLayouts'] as List? ?? [])
            .map((item) =>
                FavoriteLayout.fromJson(Map<String, Object?>.from(item)))
            .toList(),
        templates: (json['templates'] as List? ?? [])
            .map((item) =>
                CollageTemplate.fromJson(Map<String, Object?>.from(item)))
            .toList(),
      );
}
