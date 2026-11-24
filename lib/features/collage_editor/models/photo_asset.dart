import 'photo_metadata.dart';
import 'photo_adjustments.dart';
import 'photo_transform.dart';
import 'photo_placement.dart';

class PhotoAsset {
  const PhotoAsset({
    required this.id,
    required this.originalFileName,
    required this.localPath,
    this.metadata,
    this.transform = PhotoTransform.identity,
    this.adjustments = const PhotoAdjustments(),
    this.placement,
  });

  final PhotoMetadata? metadata;
  final String id;
  final String originalFileName;
  final String localPath;
  final PhotoTransform transform;
  final PhotoAdjustments adjustments;
  final PhotoPlacement? placement;

  PhotoAsset copyWith({
    PhotoMetadata? metadata,
    bool clearMetadata = false,
    String? id,
    String? originalFileName,
    String? localPath,
    PhotoTransform? transform,
    PhotoAdjustments? adjustments,
    PhotoPlacement? placement,
    bool clearPlacement = false,
  }) {
    return PhotoAsset(
      metadata: clearMetadata ? null : metadata ?? this.metadata,
      id: id ?? this.id,
      originalFileName: originalFileName ?? this.originalFileName,
      localPath: localPath ?? this.localPath,
      transform: transform ?? this.transform,
      adjustments: adjustments ?? this.adjustments,
      placement: clearPlacement ? null : placement ?? this.placement,
    );
  }

  Map<String, Object?> toJson() => {
        if (metadata != null) 'metadata': metadata!.toJson(),
        'id': id,
        'originalFileName': originalFileName,
        'localPath': localPath,
        'transform': transform.toJson(),
        'adjustments': adjustments.toJson(),
        if (placement != null) 'placement': placement!.toJson(),
      };

  static PhotoAsset fromJson(Map<String, Object?> json) {
    return PhotoAsset(
      metadata: PhotoMetadata.tryParse(json['metadata']),
      placement: PhotoPlacement.tryParse(json['placement']),
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
