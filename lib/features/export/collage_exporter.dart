import '../stickers/sticker_renderer.dart';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../collage_editor/models/photo_placement.dart';
import '../collage_editor/models/photo_asset.dart';
import '../collage_editor/rendering/crop_geometry.dart';
import '../collage_editor/rendering/photo_detail_renderer.dart';
import '../collage_editor/rendering/style_renderer.dart';
import '../collage_editor/rendering/project_image_loader.dart';
import '../collage_editor/rendering/layout_geometry.dart';
import '../collage_editor/rendering/text_overlay_renderer.dart';
import '../projects/models/collage_project.dart';
import 'export_settings.dart';
import 'services/gallery_save_service.dart';

class CollageExporter {
  const CollageExporter({this.outputDirectory});

  final Directory? outputDirectory;

  Future<File> export(
    CollageProject project,
    ExportSettings settings,
  ) async {
    if (!ExportSettings.validDimensions(settings.width, settings.height)) {
      throw const ExportFailure('exportDimensionLimits');
    }
    final size = Size(settings.width.toDouble(), settings.height.toDouble());
    final needsDetail = project.photos.any((photo) =>
        photo.adjustments.usesDetail &&
        (!project.freestyle ||
            (photo.placement?.hidden != true &&
                photo.placement?.opacity != 0)));
    final detailProgram = needsDetail ? await PhotoDetailRenderer.load() : null;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    try {
      ui.Image? backdrop;
      try {
        final photo = StyleRenderer.backdropPhoto(project);
        if (photo != null) backdrop = await _loadPhoto(photo, maxEdge: 2048);
        StyleRenderer.background(canvas, size, project.canvas,
            image: backdrop, opaque: settings.format == ExportFormat.jpeg);
      } finally {
        backdrop?.dispose();
      }
      if (project.freestyle) {
        final clip = Offset.zero & size;
        canvas.clipRect(clip);
        for (final photo in project.photos) {
          final placement = photo.placement ?? const PhotoPlacement();
          if (placement.hidden || placement.opacity == 0) continue;
          final image = await _loadPhoto(photo, cell: placement.rect(size));
          try {
            StyleRenderer.freestylePhoto(canvas, size, photo, image,
                detailProgram: detailProgram);
          } finally {
            image.dispose();
          }
        }
      } else {
        final resolved = LayoutGeometry.resolve(project, size);
        StyleRenderer.shadows(canvas, size, project.canvas, resolved);
        for (final cell in resolved) {
          if (cell.photoIndex >= project.photos.length) continue;
          final photo = project.photos[cell.photoIndex];
          final image = await _loadPhoto(photo, cell: cell.rect);
          try {
            StyleRenderer.photo(
                canvas, image, cell.rect, cell.cornerRadius, photo.transform,
                adjustments: photo.adjustments, detailProgram: detailProgram);
          } finally {
            image.dispose();
          }
        }
        StyleRenderer.frames(canvas, size, project.canvas, resolved);
      }
      TextOverlayRenderer.paint(canvas, size, project.textOverlays);
      StickerRenderer.paint(canvas, size, project.stickers);
    } catch (_) {
      recorder.endRecording().dispose();
      rethrow;
    }

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
    await _removeExpiredExports(exports);
    return file;
  }

  Future<void> _removeExpiredExports(Directory directory) async {
    final cutoff = DateTime.now().subtract(const Duration(days: 2));
    final ownedName = RegExp(r'^piclayout_[0-9]+\.(png|jpg)$');
    try {
      await for (final entity in directory.list(followLinks: false)) {
        if (entity is File &&
            ownedName.hasMatch(p.basename(entity.path)) &&
            (await entity.lastModified()).isBefore(cutoff)) {
          try {
            await entity.delete();
          } on FileSystemException {
            // Another export or the settings screen might already have removed it.
          }
        }
      }
    } on FileSystemException {
      // Cache housekeeping does not affect an already-rendered export.
    }
  }

  Future<Uint8List> _encodePng(ui.Image image) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<ui.Image> _loadPhoto(PhotoAsset photo,
      {Rect? cell, int? maxEdge}) async {
    try {
      return await loadProjectImage(photo.localPath,
          maxEdge: maxEdge,
          usefulEdge: cell == null
              ? null
              : (source) => CropGeometry.resolve(cell, source, photo.transform)
                  .imageSize
                  .longestSide
                  .ceil());
    } catch (_) {
      throw const ExportFailure('exportUnreadablePhoto');
    }
  }

  Future<Uint8List> _encodeJpeg(ui.Image image, int quality) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final width = image.width;
    final height = image.height;
    final rgba = TransferableTypedData.fromList(
        [data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes)]);
    return Isolate.run(() => img.encodeJpg(
        img.Image.fromBytes(
          width: width,
          height: height,
          bytes: rgba.materialize(),
          numChannels: 4,
        ),
        quality: quality.clamp(1, 100)));
  }
}
