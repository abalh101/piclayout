import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../collage_editor/models/canvas_style.dart';
import '../collage_editor/rendering/style_renderer.dart';
import '../collage_editor/rendering/project_image_loader.dart';
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
    try {
      ui.Image? backdrop;
      try {
        if (project.canvas.style.backgroundType == BackgroundType.blur &&
            project.photos.isNotEmpty) {
          backdrop = await loadProjectImage(
              project
                  .photos[StyleRenderer.photoIndex(
                      project.canvas.style, project.photos.length)]
                  .localPath,
              maxEdge: 2048);
        }
        StyleRenderer.background(canvas, size, project.canvas,
            image: backdrop, opaque: settings.format == ExportFormat.jpeg);
      } finally {
        backdrop?.dispose();
      }
      final resolved = LayoutGeometry.resolve(project, size);
      StyleRenderer.shadows(canvas, size, project.canvas, resolved);
      for (final cell in resolved) {
        if (cell.photoIndex >= project.photos.length) continue;
        final photo = project.photos[cell.photoIndex];
        final image = await loadProjectImage(photo.localPath);
        try {
          StyleRenderer.photo(
              canvas, image, cell.rect, cell.cornerRadius, photo.transform);
        } finally {
          image.dispose();
        }
      }
      StyleRenderer.frames(canvas, size, project.canvas, resolved);
    } catch (_) {
      recorder.endRecording().dispose();
      rethrow;
    }

    TextOverlayRenderer.paint(canvas, size, project.textOverlays);

    final picture = recorder.endRecording();
    late ui.Image outputImage;
    try {
      outputImage = await picture.toImage(settings.width, settings.height);
    } finally {
      picture.dispose();
    }
    late Uint8List bytes;
    try {
      bytes = await switch (settings.format) {
        ExportFormat.png => _encodePng(outputImage),
        ExportFormat.jpeg => _encodeJpeg(outputImage, settings.jpegQuality),
      };
    } finally {
      outputImage.dispose();
    }

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
