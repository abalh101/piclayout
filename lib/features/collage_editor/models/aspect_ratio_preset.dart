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
    final longest = math.max(value, 1 / value);
    final maxEdge = longest > 4 ? 8192 : 4096;
    final largest = math.min(2160, (maxEdge / longest).floor());
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
    final match = RegExp(r'^custom_(\d{1,10})_(\d{1,10})$').firstMatch(id);
    if (match == null) return null;
    final w = int.parse(match[1]!);
    final h = int.parse(match[2]!);
    if (w <= 0 || h <= 0 || w / h < 1 / 8 || w / h > 8) return null;
    return AspectRatioPreset(id: id, label: '$w:$h', width: w, height: h);
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
    final normalized = _normalizeDigits(value).trim();
    return RegExp(r'^[0-9]{1,5}$').hasMatch(normalized)
        ? int.tryParse(normalized)
        : null;
  }

  static String _normalizeDigits(String input) {
    const digits = '٠١٢٣٤٥٦٧٨٩۰۱۲۳۴۵۶۷۸۹';
    return input.replaceAllMapped(
        RegExp('[$digits]'), (match) => '${digits.indexOf(match[0]!) % 10}');
  }

  /// Accept width/height units or a ratio; at most three decimal places.
  static AspectRatioPreset parse(String width, String height) {
    int units(String input) {
      final text = _normalizeDigits(input).trim().replaceAll(',', '.');
      if (!RegExp(r'^\d{1,7}(\.\d{1,3})?$').hasMatch(text)) {
        throw const FormatException('Invalid dimension');
      }
      final value = double.parse(text);
      if (value <= 0 || value > 1000000) {
        throw const FormatException('Invalid dimension');
      }
      return (value * 1000).round();
    }

    var w = units(width), h = units(height);
    if (w / h < 1 / 8 || w / h > 8) {
      throw const FormatException('Ratio must be between 1:8 and 8:1');
    }
    final divisor = w.gcd(h);
    w ~/= divisor;
    h ~/= divisor;
    for (final preset in all) {
      if (w * preset.height == h * preset.width) return preset;
    }
    return AspectRatioPreset(
        id: 'custom_${w}_$h', label: '$w:$h', width: w, height: h);
  }
}
