import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../collage_editor/models/photo_transform.dart';
import '../collage_editor/rendering/layout_geometry.dart';
import '../collage_editor/rendering/text_overlay_renderer.dart';
import '../projects/models/collage_project.dart';
import 'export_settings.dart';

class CollageExporter {
  const CollageExporter({this.outputDirectory});

  final Directory? outputDirectory;

  Future<File> export(
    CollageProject project,
    ExportSettings settings,
  ) async {
    final size = Size(settings.width.toDouble(), settings.height.toDouble());
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final background = Color(project.canvas.backgroundColor);
    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;

    canvas.drawRect(Offset.zero & size, Paint()..color = background);

    final resolved = LayoutGeometry.resolve(project, size);
    for (final cell in resolved) {
      if (cell.photoIndex >= project.photos.length) {
        continue;
      }
      final photo = project.photos[cell.photoIndex];
      final image = await _loadImage(photo.localPath);
      final rect = cell.rect;
      final rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(cell.cornerRadius),
      );

      canvas.save();
      canvas.clipRRect(rrect);
      canvas.drawRect(rect, Paint()..color = background);
      _drawPhoto(
        canvas,
        image,
        rect,
        photo.transform,
        paint,
      );
      canvas.restore();
      image.dispose();
    }

    TextOverlayRenderer.paint(canvas, size, project.textOverlays);

    final picture = recorder.endRecording();
    final outputImage = await picture.toImage(settings.width, settings.height);
    picture.dispose();

    final bytes = await switch (settings.format) {
      ExportFormat.png => _encodePng(outputImage),
      ExportFormat.jpeg => _encodeJpeg(outputImage, settings.jpegQuality),
    };
    outputImage.dispose();

    final dir = outputDirectory ?? await getTemporaryDirectory();
    final exports = Directory(p.join(dir.path, 'piclayout_exports'))
      ..createSync(recursive: true);
    final file = File(
      p.join(
        exports.path,
        'piclayout_${DateTime.now().microsecondsSinceEpoch}.${settings.extension}',
      ),
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<ui.Image> _loadImage(String path) async {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  void _drawPhoto(
    Canvas canvas,
    ui.Image image,
    Rect cell,
    PhotoTransform transform,
    Paint paint,
  ) {
    final rotation = transform.rotationQuarterTurns % 4;
    final rotatedWidth =
        rotation.isOdd ? image.height.toDouble() : image.width.toDouble();
    final rotatedHeight =
        rotation.isOdd ? image.width.toDouble() : image.height.toDouble();
    final baseScale = transform.fitMode == PhotoFitMode.fill
        ? math.max(cell.width / rotatedWidth, cell.height / rotatedHeight)
        : math.min(cell.width / rotatedWidth, cell.height / rotatedHeight);
    final userScale = transform.scale.clamp(0.5, 5.0).toDouble();
    final center = cell.center +
        Offset(
          transform.offsetX * cell.width,
          transform.offsetY * cell.height,
        );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (transform.flipX) {
      canvas.scale(-1, 1);
    }
    canvas.rotate(rotation * math.pi / 2);
    final destination = Rect.fromCenter(
      center: Offset.zero,
      width: image.width * baseScale * userScale,
      height: image.height * baseScale * userScale,
    );
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      destination,
      paint,
    );
    canvas.restore();
  }

  Future<Uint8List> _encodePng(ui.Image image) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<Uint8List> _encodeJpeg(ui.Image image, int quality) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final rgba = data!.buffer.asUint8List();
    final bitmap = img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: rgba.buffer,
      numChannels: 4,
    );
    return Uint8List.fromList(
      img.encodeJpg(bitmap, quality: quality.clamp(1, 100).toInt()),
    );
  }
}
