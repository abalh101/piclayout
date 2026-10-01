class ExportSizePreset {
  const ExportSizePreset({
    required this.width,
    required this.height,
    required this.label,
  });

  final int width;
  final int height;
  final String label;
}

class AspectRatioPreset {
  const AspectRatioPreset({
    required this.id,
    required this.label,
    required this.width,
    required this.height,
  });

  final String id;
  final String label;
  final int width;
  final int height;

  double get value => width / height;

  List<ExportSizePreset> exportSizes() {
    const shortSide = [1080, 1440, 2160];
    return shortSide.map((base) {
      final isPortrait = height >= width;
      final exportWidth = isPortrait ? base : (base * value).round();
      final exportHeight = isPortrait ? (base / value).round() : base;
      return ExportSizePreset(
        width: exportWidth,
        height: exportHeight,
        label: '$exportWidth x $exportHeight',
      );
    }).toList();
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'label': label,
        'width': width,
        'height': height,
      };

  static AspectRatioPreset fromJson(Map<String, Object?> json) {
    return AspectRatioPreset(
      id: json['id'] as String,
      label: json['label'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
    );
  }
}

class AspectRatios {
  const AspectRatios._();

  static const story = AspectRatioPreset(
    id: '9_16',
    label: '9:16',
    width: 9,
    height: 16,
  );

  static const all = [
    story,
    AspectRatioPreset(id: '1_1', label: '1:1', width: 1, height: 1),
    AspectRatioPreset(id: '4_5', label: '4:5', width: 4, height: 5),
    AspectRatioPreset(id: '3_4', label: '3:4', width: 3, height: 4),
    AspectRatioPreset(id: '4_3', label: '4:3', width: 4, height: 3),
    AspectRatioPreset(id: '16_9', label: '16:9', width: 16, height: 9),
  ];

  static AspectRatioPreset byId(String id) {
    return all.firstWhere(
      (preset) => preset.id == id,
      orElse: () => story,
    );
  }
}
