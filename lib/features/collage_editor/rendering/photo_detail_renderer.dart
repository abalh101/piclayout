import 'dart:math' as math;
import 'dart:ui';

import '../models/photo_adjustments.dart';

class PhotoDetailRenderer {
  const PhotoDetailRenderer._();
  static Future<FragmentProgram>? _loading;

  static Future<FragmentProgram> load() => _loading ??=
      FragmentProgram.fromAsset('assets/shaders/photo_detail.frag');

  static void paint(
    Canvas canvas,
    Image image,
    Rect destination,
    Paint paint,
    PhotoAdjustments adjustments,
    FragmentProgram program,
  ) {
    final edge = math.max(image.width, image.height);
    final shader = program.fragmentShader()
      ..setFloat(0, destination.left)
      ..setFloat(1, destination.top)
      ..setFloat(2, destination.width)
      ..setFloat(3, destination.height)
      ..setFloat(4, edge / image.width * .002)
      ..setFloat(5, edge / image.height * .002)
      ..setFloat(6, adjustments.highlights)
      ..setFloat(7, adjustments.shadows)
      ..setFloat(8, adjustments.sharpness)
      ..setImageSampler(0, image, filterQuality: FilterQuality.medium);
    try {
      canvas.drawRect(destination, paint..shader = shader);
    } finally {
      shader.dispose();
    }
  }
}
