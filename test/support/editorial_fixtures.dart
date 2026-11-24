import 'package:piclayout/features/collage_editor/layouts/layout_library.dart';
import 'package:piclayout/features/collage_editor/models/photo_asset.dart';
import 'package:piclayout/features/collage_editor/models/photo_metadata.dart';
import 'package:piclayout/features/projects/models/collage_project.dart';
import 'package:piclayout/features/projects/services/project_repository.dart';

CollageProject editorialProject({int count = 6, String? path}) =>
    CollageProject(
        id: 'editorial',
        name: 'Editorial',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        formatVersion: 1,
        aspectRatioId: '9_16',
        layoutTemplateId: LayoutLibrary.defaultFor(count).id,
        photos: [
          for (var i = 0; i < count; i++)
            PhotoAsset(
                id: 'private-photo-$i',
                originalFileName: 'private-$i.png',
                localPath: path ?? '/private/photo-$i.png',
                metadata: const PhotoMetadata(width: 100, height: 100))
        ]);

class EditorialMemoryRepository extends ProjectRepository {
  CollageProject? saved;
  @override
  Future<void> save(CollageProject project) async {
    saved = project;
  }
}
