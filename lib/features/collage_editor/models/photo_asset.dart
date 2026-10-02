import 'photo_adjustments.dart';
import 'photo_transform.dart';

class PhotoAsset {
  const PhotoAsset({
    required this.id,
    required this.originalFileName,
    required this.localPath,
    this.transform = PhotoTransform.identity,
    this.adjustments = const PhotoAdjustments(),
  });

  final String id;
  final String originalFileName;
  final String localPath;
  final PhotoTransform transform;
  final PhotoAdjustments adjustments;

  PhotoAsset copyWith({
    String? id,
    String? originalFileName,
    String? localPath,
    PhotoTransform? transform,
    PhotoAdjustments? adjustments,
  }) {
    return PhotoAsset(
      id: id ?? this.id,
      originalFileName: originalFileName ?? this.originalFileName,
      localPath: localPath ?? this.localPath,
      transform: transform ?? this.transform,
      adjustments: adjustments ?? this.adjustments,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'originalFileName': originalFileName,
        'localPath': localPath,
        'transform': transform.toJson(),
        'adjustments': adjustments.toJson(),
      };

  static PhotoAsset fromJson(Map<String, Object?> json) {
    return PhotoAsset(
      adjustments: PhotoAdjustments.fromJson(
          Map<String, Object?>.from(json['adjustments'] as Map? ?? {})),
      id: json['id'] as String,
      originalFileName: json['originalFileName'] as String,
      localPath: json['localPath'] as String,
      transform: PhotoTransform.fromJson(
        Map<String, Object?>.from(json['transform'] as Map? ?? {}),
      ),
    );
  }
}
