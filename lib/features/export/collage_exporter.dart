import '../collage_editor/models/photo_asset.dart';
import '../collage_editor/models/photo_placement.dart';
import '../collage_editor/rendering/crop_geometry.dart';
import 'services/gallery_save_service.dart';
import '../stickers/sticker_renderer.dart';
import '../editorial/rendering/editorial_renderer.dart';
import '../editorial/models/editorial_design.dart';
import '../layout_recommendations/photo_metadata_reader.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../collage_editor/rendering/style_renderer.dart';
import '../collage_editor/rendering/project_image_loader.dart';
import '../collage_editor/rendering/photo_filter_renderer.dart';
import '../collage_editor/rendering/layout_geometry.dart';
import '../collage_editor/rendering/text_overlay_renderer.dart';
import '../projects/models/collage_project.dart';
import 'export_settings.dart';

class CollageExporter {
  const CollageExporter({this.outputDirectory});

  final Directory? outputDirectory;
  static const _maxExportPixels = 4096 * 4096;

  Future<File> export(
    CollageProject project,
    ExportSettings settings,
  ) async {
    final w = settings.width, h = settings.height;
    if (w < 1 ||
        h < 1 ||
        w > 8192 ||
        h > 8192 ||
        w > 8 * h ||
        h > 8 * w ||
        w * h > _maxExportPixels) {
      throw const ExportFailure('exportDimensionLimits');
    }
    final size = Size(settings.width.toDouble(), settings.height.toDouble());
    var recorder = ui.PictureRecorder();
    var canvas = Canvas(recorder);
    // A recording retains native image references after Image.dispose().
    // Flatten each source into the output-sized surface before decoding the
    // next original, bounding retained source memory to one original.
    Future<void> flatten() async {
      final picture = recorder.endRecording();
      ui.Image? flattened;
      try {
        flattened = await picture.toImage(settings.width, settings.height);
      } finally {
        picture.dispose();
        recorder = ui.PictureRecorder();
        canvas = Canvas(recorder);
      }
      canvas.drawImage(flattened, Offset.zero, Paint());
      flattened.dispose();
    }

    try {
      ui.Image? backdrop;
      try {
        final photo = StyleRenderer.backdropPhoto(project);
        if (photo != null) {
          try {
            backdrop = await _loadPhoto(photo, maxEdge: 2048);
          } catch (_) {
            if (!project.isFreeform) rethrow;
          }
        }
        StyleRenderer.background(canvas, size, project.canvas,
            image: backdrop, opaque: settings.format == ExportFormat.jpeg);
      } finally {
        backdrop?.dispose();
      }
      if (project.freestyle) {
        for (final photo in project.photos) {
          final placement = photo.placement ?? const PhotoPlacement();
          if (placement.hidden || placement.opacity == 0) continue;
          Size? sourceSize;
          final image = await _loadPhoto(photo,
              cell: placement.rect(size),
              onSourceSize: (size) => sourceSize = size);
          try {
            StyleRenderer.freestylePhoto(canvas, size, photo, image,
                sourceSize: sourceSize);
            await flatten();
          } finally {
            PhotoFilterRenderer.releaseImage(image);
            image.dispose();
          }
        }
      } else if (project.design.active) {
        final sourceSizes = <String, Size?>{};
        for (final layer in project.design.ordered) {
          if (!layer.visible || layer.opacity == 0) continue;
          final photo = layer.isPhoto || layer.type == DesignLayerType.connector
              ? layer.source(project.photos)
              : null;
          if (layer.isPhoto && photo == null && !project.isFreeform) {
            throw StateError('Design photo source is missing');
          }
          if (layer.type == DesignLayerType.connector &&
              photo != null &&
              !sourceSizes.containsKey(photo.localPath)) {
            final metadata =
                await const PhotoMetadataReader().read(photo.localPath);
            sourceSizes[photo.localPath] = metadata == null
                ? null
                : Size(metadata.width.toDouble(), metadata.height.toDouble());
          }
          ui.Image? image;
          if (layer.isPhoto && photo != null) {
            try {
              image = await _loadPhoto(photo,
                  onSourceSize: (size) => sourceSizes[photo.localPath] = size);
            } catch (_) {
              if (!project.isFreeform) rethrow;
              // Missing/unreadable freeform sources retain their empty frame.
            }
          }
          try {
            EditorialRenderer.paintLayer(canvas, size, project, layer,
                image: image, sourceSize: sourceSizes[photo?.localPath]);
            if (image != null) await flatten();
          } finally {
            if (image != null) {
              PhotoFilterRenderer.releaseImage(image);
              image.dispose();
            }
          }
        }
      } else {
        final resolved = LayoutGeometry.resolve(project, size);
        StyleRenderer.shadows(canvas, size, project.canvas, resolved);
        for (final cell in resolved) {
          if (cell.photoIndex >= project.photos.length) continue;
          final photo = project.photos[cell.photoIndex];
          Size? sourceSize;
          final image = await _loadPhoto(photo,
              cell: cell.rect, onSourceSize: (size) => sourceSize = size);
          try {
            StyleRenderer.photo(
                canvas, image, cell.rect, cell.cornerRadius, photo.transform,
                adjustments: photo.adjustments, sourceSize: sourceSize);
            await flatten();
          } finally {
            PhotoFilterRenderer.releaseImage(image);
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

  Future<ui.Image> _loadPhoto(PhotoAsset photo,
      {Rect? cell, int? maxEdge, void Function(Size)? onSourceSize}) async {
    try {
      return await loadProjectImage(photo.localPath,
          maxEdge: maxEdge,
          maxPixels: _maxExportPixels,
          onSourceSize: onSourceSize,
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

  Future<Uint8List> _encodePng(ui.Image image) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<Uint8List> _encodeJpeg(ui.Image image, int quality) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final rgba = data!.buffer.asUint8List();
    return compute(_jpegBytes, (rgba, image.width, image.height, quality));
  }
}

Uint8List _jpegBytes((Uint8List, int, int, int) args) {
  final bitmap = img.Image.fromBytes(
      width: args.$2, height: args.$3, bytes: args.$1.buffer, numChannels: 4);
  return Uint8List.fromList(
      img.encodeJpg(bitmap, quality: args.$4.clamp(1, 100)));
}
