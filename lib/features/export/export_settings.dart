enum ExportFormat { png, jpeg }

class ExportSettings {
  static const maxDimension = 4096;

  static bool validDimensions(int width, int height) =>
      width > 0 &&
      height > 0 &&
      width <= maxDimension &&
      height <= maxDimension &&
      width <= height * 4 &&
      height <= width * 4;
  const ExportSettings({
    required this.width,
    required this.height,
    required this.format,
    this.jpegQuality = 92,
  });

  final int width;
  final int height;
  final ExportFormat format;
  final int jpegQuality;

  String get extension => switch (format) {
        ExportFormat.png => 'png',
        ExportFormat.jpeg => 'jpg',
      };
}
