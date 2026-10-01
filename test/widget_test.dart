import 'package:flutter_test/flutter_test.dart';
import 'package:piclayout/features/collage_editor/models/photo_asset.dart';
import 'package:piclayout/features/projects/models/collage_project.dart';

void main() {
  test('saved project restores photo order and layout', () {
    final now = DateTime.utc(2026);
    final project = CollageProject(
      id: 'project',
      name: 'Test',
      createdAt: now,
      updatedAt: now,
      formatVersion: 1,
      aspectRatioId: 'story',
      layoutTemplateId: 'grid_2x3_6',
      photos: [
        for (var i = 0; i < 6; i++)
          PhotoAsset(
              id: '$i', originalFileName: '$i.jpg', localPath: '/$i.jpg'),
      ],
    );

    final restored = CollageProject.fromJson(project.toJson());
    expect(restored.photos.map((photo) => photo.id).toList(),
        ['0', '1', '2', '3', '4', '5']);
    expect(restored.layoutTemplateId, 'grid_2x3_6');
  });
}
