import 'dart:math' as math;
import 'dart:ui';

class PhotoPlacement {
  const PhotoPlacement({
    this.x = .5,
    this.y = .5,
    this.width = .56,
    this.height = .56,
    this.rotation = 0,
    this.opacity = 1,
    this.radius = 0,
    this.border = 0,
    this.shadow = false,
    this.hidden = false,
    this.locked = false,
  });

  final double x, y, width, height, rotation, opacity, radius, border;
  final bool shadow, hidden, locked;

  Rect rect(Size canvas) => Rect.fromCenter(
        center: Offset(x * canvas.width, y * canvas.height),
        width: width * canvas.width,
        height: height * canvas.height,
      );

  double get radians => rotation * math.pi / 180;

  PhotoPlacement copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    double? opacity,
    double? radius,
    double? border,
    bool? shadow,
    bool? hidden,
    bool? locked,
  }) =>
      PhotoPlacement(
        x: (x ?? this.x).clamp(0, 1),
        y: (y ?? this.y).clamp(0, 1),
        width: (width ?? this.width).clamp(.025, 2),
        height: (height ?? this.height).clamp(.025, 2),
        rotation: _angle(rotation ?? this.rotation),
        opacity: (opacity ?? this.opacity).clamp(0, 1),
        radius: (radius ?? this.radius).clamp(0, .5),
        border: (border ?? this.border).clamp(0, .18),
        shadow: shadow ?? this.shadow,
        hidden: hidden ?? this.hidden,
        locked: locked ?? this.locked,
      );

  PhotoPlacement resized(double factor) {
    final minimum = .025 / math.min(width, height);
    final maximum = 2 / math.max(width, height);
    final scale = factor.clamp(minimum, maximum);
    return copyWith(width: width * scale, height: height * scale);
  }

  static double _angle(double degrees) =>
      degrees >= -180 && degrees <= 180 ? degrees : (degrees + 180) % 360 - 180;

  Map<String, Object?> toJson() => {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'rotation': rotation,
        'opacity': opacity,
        'radius': radius,
        'border': border,
        'shadow': shadow,
        'hidden': hidden,
        'locked': locked,
      };

  static PhotoPlacement? tryParse(Object? value) {
    if (value is! Map) return null;
    double? number(String key) {
      final item = value[key];
      return item is num && item.isFinite ? item.toDouble() : null;
    }

    return const PhotoPlacement().copyWith(
      x: number('x'),
      y: number('y'),
      width: number('width'),
      height: number('height'),
      rotation: number('rotation'),
      opacity: number('opacity'),
      radius: number('radius'),
      border: number('border'),
      shadow: value['shadow'] == true,
      hidden: value['hidden'] == true,
      locked: value['locked'] == true,
    );
  }
}
