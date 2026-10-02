import 'package:piclayout/features/collage_editor/models/photo_asset.dart';
import 'package:piclayout/features/collage_editor/layouts/layout_library.dart';
import 'package:piclayout/features/custom_layouts/models/custom_layout.dart';
import 'package:piclayout/features/custom_layouts/services/custom_layout_repository.dart';
import 'package:piclayout/features/projects/models/collage_project.dart';
import 'package:piclayout/features/projects/services/project_repository.dart';

CollageProject layoutProject({int count = 6, List<String>? paths}) =>
    CollageProject(
        id: 'project',
        name: 'Test',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        formatVersion: 1,
        aspectRatioId: '1_1',
        layoutTemplateId: LayoutLibrary.defaultFor(count).id,
        photos: [
          for (var i = 0; i < count; i++)
            PhotoAsset(
                id: 'photo-$i',
                originalFileName: 'original-$i.png',
                localPath: paths?[i] ?? '/private/photo-$i.png')
        ]);

CustomLayout gridLayout(
        {int count = 6, String id = 'custom', String name = 'My layout'}) =>
    CustomLayout.fromCells(
        id: id,
        name: name,
        now: DateTime.utc(2026),
        cells: LayoutLibrary.cellsFor(LayoutLibrary.defaultFor(count)));

class LayoutMemoryProjects extends ProjectRepository {
  CollageProject? saved;
  @override
  Future<void> save(CollageProject project) async {
    saved = project;
  }
}

class LayoutMemoryLibrary extends CustomLayoutRepository {
  List<CustomLayout> layouts = [];
  bool fail = false;
  @override
  Future<List<CustomLayout>> load() async => layouts;
  @override
  Future<void> save(List<CustomLayout> value) async {
    if (fail) throw const FormatException('write failed');
    layouts = List.of(value);
  }
}
