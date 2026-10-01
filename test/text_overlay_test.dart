import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:piclayout/features/collage_editor/models/photo_asset.dart';
import 'package:piclayout/features/collage_editor/models/text_overlay.dart';
import 'package:piclayout/features/collage_editor/rendering/text_overlay_renderer.dart';
import 'package:piclayout/features/export/collage_exporter.dart';
import 'package:piclayout/features/export/export_settings.dart';
import 'package:piclayout/features/projects/models/collage_project.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  CollageProject projectWith(List<TextOverlay> overlays, String imagePath) {
    final now = DateTime.utc(2026);
    return CollageProject(
      id: 'test',
      name: 'Text',
      createdAt: now,
      updatedAt: now,
      formatVersion: 1,
      aspectRatioId: '1_1',
      layoutTemplateId: 'grid_1x1_1',
      photos: [
        PhotoAsset(
            id: 'photo', originalFileName: 'photo.png', localPath: imagePath)
      ],
      textOverlays: overlays,
    );
  }

  test('text settings round-trip and legacy JSON remains readable', () {
    const overlay = TextOverlay(
      id: 'stable-id',
      text: 'Reise\n2026',
      x: 0.25,
      y: 0.75,
      fontSize: 44,
      color: 0xFF2563EB,
      backgroundColor: 0x99000000,
      rotation: 25,
      alignment: TextOverlayAlignment.right,
    );
    final project = projectWith([overlay], '/image.png');
    final restored = CollageProject.fromJson(project.toJson());
    expect(restored.textOverlays.single.toJson(), overlay.toJson());

    final legacy = project.toJson()..remove('textOverlays');
    expect(CollageProject.fromJson(legacy).textOverlays, isEmpty);
  });

  test('drag and decoded positions remain on the canvas', () {
    final overlay = TextOverlay.fromJson({
      'id': 'x',
      'text': 'A long text',
      'x': -2,
      'y': 4,
      'fontSize': 200,
      'rotation': 40,
    });
    expect(overlay.x, 0);
    expect(overlay.y, 1);
    expect(overlay.fontSize, 72);
    final moved = TextOverlayRenderer.moveBy(
      overlay,
      const Size(390, 390),
      const Offset(10000, -10000),
    );
    expect(moved.x, inInclusiveRange(0, 1));
    expect(moved.y, inInclusiveRange(0, 1));
    final layout = TextOverlayRenderer.layout(moved, const Size(390, 390));
    expect(layout.center.dx, inInclusiveRange(0, 390));
    expect(layout.center.dy, inInclusiveRange(0, 390));
    layout.dispose();
  });

  test('PNG and JPEG export render text over the stored image', () async {
    final root = await Directory.systemTemp.createTemp('piclayout_text_');
    addTearDown(() => root.delete(recursive: true));
    final source = File(p.join(root.path, 'source.png'));
    final black = img.Image(width: 64, height: 64);
    img.fill(black, color: img.ColorRgb8(0, 0, 0));
    await source.writeAsBytes(img.encodePng(black));
    final exporter = CollageExporter(outputDirectory: root);
    const png =
        ExportSettings(width: 390, height: 390, format: ExportFormat.png);
    const jpeg =
        ExportSettings(width: 390, height: 390, format: ExportFormat.jpeg);
    final plainFile = await exporter.export(projectWith([], source.path), png);
    final plainBytes = await plainFile.readAsBytes();
    final textProject = projectWith(
      [const TextOverlay(id: 'title', text: 'HELLO', fontSize: 64)],
      source.path,
    );
    final textFile = await exporter.export(textProject, png);
    final textBytes = await textFile.readAsBytes();
    expect(textBytes, isNot(plainBytes));
    final rendered = img.decodePng(textBytes)!;
    var brightPixels = 0;
    for (var y = 140; y < 250; y++) {
      for (var x = 40; x < 350; x++) {
        if (rendered.getPixel(x, y).r > 100) brightPixels++;
      }
    }
    expect(brightPixels, greaterThan(100));

    final jpegFile = await exporter.export(textProject, jpeg);
    expect(img.decodeJpg(await jpegFile.readAsBytes()), isNotNull);
    expect(await source.readAsBytes(), img.encodePng(black));
  });
}
