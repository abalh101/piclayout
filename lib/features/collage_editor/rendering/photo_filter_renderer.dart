import 'dart:ui';
import '../models/photo_adjustments.dart';

/// The same affine RGB transform is used in preview and file-based export.
/// Bounded cache avoids recalculating matrices for unchanged photos.
class PhotoFilterRenderer {
  static FragmentProgram? _program;
  static Future<void>? _loading;
  static final _shaders = <Image, Map<String, FragmentShader>>{};
  static int get cachedSourceCount => _shaders.length;

  /// One compiled program, with four cached view configurations per source.
  /// Canvas and sheet sizes can coexist without evicting each other every frame.
  /// The image owner must call releaseImage before disposing that image.
  static Future<void> initialize() => _loading ??= _initialize();
  static Future<void> _initialize() async {
    try {
      _program =
          await FragmentProgram.fromAsset('shaders/photo_adjustments.frag');
    } catch (_) {
      _loading = null;
      rethrow;
    }
  }

  static void releaseImage(Image image) {
    for (final shader in _shaders.remove(image)?.values ?? <FragmentShader>[]) {
      shader.dispose();
    }
  }

  static FragmentShader studioShader(
      Image image, PhotoAdjustments a, Size target, Rect crop) {
    // Size/Rect.toString round coordinates and can collide for nearby crops.
    final key = [
      ...a.toJson().values,
      target.width,
      target.height,
      crop.left,
      crop.top,
      crop.width,
      crop.height
    ].join(':');
    final configurations = _shaders.putIfAbsent(image, () => {});
    final cached = configurations.remove(key);
    if (cached != null) {
      configurations[key] = cached;
      return cached;
    }
    final shader = _program!.fragmentShader();
    final m = matrix(a);
    final values = <double>[
      target.width,
      target.height,
      crop.left,
      crop.top,
      crop.width,
      crop.height,
      ...m.sublist(0, 4),
      ...m.sublist(5, 9),
      ...m.sublist(10, 14),
      m[4] / 255,
      m[9] / 255,
      m[14] / 255,
      a.tint,
      a.highlights,
      a.shadows,
      a.fade,
      a.blackPoint,
      a.vignette,
    ];
    for (var i = 0; i < values.length; i++) {
      shader.setFloat(i, values[i]);
    }
    shader.setImageSampler(0, image);
    configurations[key] = shader;
    if (configurations.length > 4) {
      configurations.remove(configurations.keys.first)!.dispose();
    }
    return shader;
  }

  static final _cache = <String, ColorFilter>{};
  static const identity = <double>[
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0
  ];
  static ColorFilter filter(PhotoAdjustments a) {
    final key = a.toJson().values.join(':');
    return _cache.putIfAbsent(key, () {
      if (_cache.length >= 128) _cache.remove(_cache.keys.first);
      return ColorFilter.matrix(matrix(a));
    });
  }

  static List<double> _compose(List<double> a, List<double> b) => [
        for (var row = 0; row < 4; row++)
          for (var col = 0; col < 5; col++)
            (col == 4 ? a[row * 5 + 4] : 0.0) +
                List.generate(4, (k) => a[row * 5 + k] * b[k * 5 + col])
                    .reduce((x, y) => x + y)
      ];
  static List<double> _tone(
      double contrast, double brightness, double saturation, double warmth) {
    final s = saturation;
    final inv = 1 - s;
    final lum = [.2126, .7152, .0722];
    final offset = 128 * (1 - contrast) + brightness * 255;
    return [
      for (var r = 0; r < 4; r++)
        for (var c = 0; c < 5; c++)
          if (r == 3)
            (c == 3 ? 1.0 : 0.0)
          else if (c == 4)
            offset +
                (r == 0
                    ? warmth * 32
                    : r == 2
                        ? -warmth * 32
                        : 0)
          else if (c == 3)
            0.0
          else
            contrast * (lum[c] * inv + (r == c ? s : 0))
    ];
  }

  static List<double> matrix(PhotoAdjustments a) {
    final preset = switch (a.preset) {
      PhotoFilterPreset.original => identity,
      PhotoFilterPreset.warm => _tone(1, .02, 1.05, .65),
      PhotoFilterPreset.cool => _tone(1, .01, 1, -.65),
      PhotoFilterPreset.blackWhite => _tone(1, 0, 0, 0),
      PhotoFilterPreset.highContrast => _tone(1.4, 0, 1.05, 0),
      PhotoFilterPreset.softFade => _tone(.78, .06, .85, .1),
      PhotoFilterPreset.vivid => _tone(1.12, .01, 1.5, .08),
      PhotoFilterPreset.vintage => _tone(.9, .025, .65, .5),
      PhotoFilterPreset.sepia => <double>[
          .393,
          .769,
          .189,
          0,
          0,
          .349,
          .686,
          .168,
          0,
          0,
          .272,
          .534,
          .131,
          0,
          0,
          0,
          0,
          0,
          1,
          0
        ],
      PhotoFilterPreset.matte => _tone(.72, .03, .9, 0),
    };
    final amount = a.filterIntensity.clamp(0.0, 1.0);
    final mixed = List<double>.generate(
        20, (i) => identity[i] + (preset[i] - identity[i]) * amount);
    return _compose(
        _tone(a.contrast, a.brightness, a.saturation, a.warmth), mixed);
  }
}
