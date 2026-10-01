enum ExportFormat { png, jpeg }

class ExportSettings {
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
