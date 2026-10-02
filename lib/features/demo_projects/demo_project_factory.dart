import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../collage_editor/models/canvas_settings.dart';
import '../collage_editor/models/text_overlay.dart';
import '../projects/models/collage_project.dart';
import '../projects/services/project_repository.dart';
import '../projects/state/project_providers.dart';
import '../stickers/sticker_overlay.dart';

class DemoDesign {
  const DemoDesign(this.key, this.ratio, this.images, this.background,
      this.spacing, this.margin, this.corners);
  final String key, ratio;
  final List<int> images;
  final int background;
  final double spacing, margin, corners;
}

final demoProjectFactoryProvider =
    Provider((ref) => DemoProjectFactory(ref.read(projectRepositoryProvider)));

class DemoProjectFactory {
  DemoProjectFactory(this.repository,
      {AssetBundle? bundle, this.temporaryDirectory})
      : bundle = bundle ?? rootBundle;
  final ProjectRepository repository;
  final AssetBundle bundle;
  final Directory? temporaryDirectory;
  static const designs = [
    DemoDesign('demoStory', '9_16', [1, 2, 3], 0xFF202331, 8, 14, 18),
    DemoDesign('demoTravel', '4_3', [2, 4, 5, 1], 0xFFFFF3DF, 6, 18, 8),
    DemoDesign('demoBirthday', '4_5', [6, 3, 4], 0xFFFFE5EF, 10, 16, 24),
    DemoDesign('demoMinimal', '3_4', [5, 2], 0xFFFFFFFF, 12, 26, 0),
    DemoDesign('demoPost', '1_1', [3, 1, 6, 5], 0xFFEEE8FF, 6, 12, 12),
  ];

  /// Definitions reference only bundled assets. Each opening imports fresh files
  /// and IDs into normal project storage; the bundled originals cannot be edited.
  Future<CollageProject> createCopy(DemoDesign design,
      {required String name}) async {
    final root = temporaryDirectory ?? await getTemporaryDirectory();
    final staging = await root.createTemp('piclayout_demo_');
    CollageProject? created;
    try {
      final images = <XFile>[];
      for (final index in design.images) {
        final data = await bundle.load('assets/demo/demo_$index.png');
        final file = File('${staging.path}/demo_$index.png');
        await file.writeAsBytes(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
        images.add(XFile(file.path));
      }
      created = await repository.createFromPickedImages(images,
          aspectRatioId: design.ratio);
      final project = created.copyWith(
        name: name,
        canvas: CanvasSettings(
            backgroundColor: design.background,
            spacing: design.spacing,
            outerMargin: design.margin,
            cornerRadius: design.corners),
        textOverlays: [
          TextOverlay(
              id: const Uuid().v4(),
              text: name,
              y: .82,
              fontSize: 22,
              backgroundColor: 0xCC202331)
        ],
        stickers: design.key == 'demoBirthday' || design.key == 'demoStory'
            ? [
                StickerOverlay(
                    id: const Uuid().v4(),
                    type: StickerType.icon,
                    content: 'star',
                    x: .8,
                    y: .15,
                    color: 0xFFFFCE55)
              ]
            : [],
      );
      await repository.save(project);
      return project;
    } catch (_) {
      if (created != null) await repository.delete(created);
      rethrow;
    } finally {
      await staging.delete(recursive: true);
    }
  }
}
