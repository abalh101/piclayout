import 'photo_transform.dart';

class PhotoAsset {
  const PhotoAsset({
    required this.id,
    required this.originalFileName,
    required this.localPath,
    this.transform = PhotoTransform.identity,
  });

  final String id;
  final String originalFileName;
  final String localPath;
  final PhotoTransform transform;

  PhotoAsset copyWith({
    String? id,
    String? originalFileName,
    String? localPath,
    PhotoTransform? transform,
  }) {
    return PhotoAsset(
      id: id ?? this.id,
      originalFileName: originalFileName ?? this.originalFileName,
      localPath: localPath ?? this.localPath,
      transform: transform ?? this.transform,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'originalFileName': originalFileName,
        'localPath': localPath,
        'transform': transform.toJson(),
      };

  static PhotoAsset fromJson(Map<String, Object?> json) {
    return PhotoAsset(
      id: json['id'] as String,
      originalFileName: json['originalFileName'] as String,
      localPath: json['localPath'] as String,
      transform: PhotoTransform.fromJson(
        Map<String, Object?>.from(json['transform'] as Map? ?? {}),
      ),
    );
  }
}
