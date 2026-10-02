enum PhotoOrientation { portrait, landscape, square }

enum PhotoShape { veryWide, veryTall, normal }

/// Dimensions as displayed by Flutter's image decoder, before editor rotation.
/// No EXIF, location, filenames or other private metadata is retained.
class PhotoMetadata {
  const PhotoMetadata({required this.width, required this.height})
      : assert(width > 0),
        assert(height > 0);
  final int width, height;
  double get aspectRatio => width / height;
  PhotoOrientation get orientation => width == height
      ? PhotoOrientation.square
      : width > height
          ? PhotoOrientation.landscape
          : PhotoOrientation.portrait;
  PhotoShape get shape => aspectRatio >= 2
      ? PhotoShape.veryWide
      : aspectRatio <= .5
          ? PhotoShape.veryTall
          : PhotoShape.normal;
  PhotoMetadata rotated(int quarterTurns) =>
      quarterTurns.isOdd ? PhotoMetadata(width: height, height: width) : this;
  Map<String, Object?> toJson() => {'width': width, 'height': height};
  static PhotoMetadata? tryParse(Object? value) {
    if (value is! Map) return null;
    final w = value['width'], h = value['height'];
    if (w is! int ||
        h is! int ||
        w <= 0 ||
        h <= 0 ||
        w > 1000000 ||
        h > 1000000) {
      return null;
    }
    return PhotoMetadata(width: w, height: h);
  }
}
