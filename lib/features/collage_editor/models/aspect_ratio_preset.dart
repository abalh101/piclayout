import 'dart:math' as math;

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
    final largest = math.min(2160, (4096 / math.max(value, 1 / value)).floor());
    return [.5, 2 / 3, 1].map((fraction) {
      final isPortrait = height >= width;
      final short = (largest * fraction).round();
      final exportWidth = (isPortrait ? short : short * value).round();
      final exportHeight = (isPortrait ? short / value : short).round();
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
    return customById(id) ??
        all.firstWhere(
          (preset) => preset.id == id,
          orElse: () => story,
        );
  }

  static AspectRatioPreset? customById(String id) {
    final match = RegExp(r'^custom_([0-9]{1,5})_([0-9]{1,5})$').firstMatch(id);
    return match == null
        ? null
        : custom(int.parse(match[1]!), int.parse(match[2]!));
  }

  static AspectRatioPreset? custom(int? width, int? height) {
    if (width == null ||
        height == null ||
        width < 1 ||
        height < 1 ||
        width > 10000 ||
        height > 10000 ||
        width > height * 4 ||
        height > width * 4) {
      return null;
    }
    final divisor = width.gcd(height);
    final w = width ~/ divisor;
    final h = height ~/ divisor;
    return AspectRatioPreset(
        id: 'custom_${w}_$h', label: '$w:$h', width: w, height: h);
  }

  static int? parseDimension(String value) {
    const digits = '٠١٢٣٤٥٦٧٨٩۰۱۲۳۴۵۶۷۸۹';
    final normalized = value.trim().replaceAllMapped(
        RegExp('[$digits]'), (match) => '${digits.indexOf(match[0]!) % 10}');
    return RegExp(r'^[0-9]{1,5}$').hasMatch(normalized)
        ? int.tryParse(normalized)
        : null;
  }
}
