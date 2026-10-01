import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:piclayout/features/collage_editor/layouts/layout_library.dart';
import 'package:piclayout/features/collage_editor/models/canvas_settings.dart';
import 'package:piclayout/features/collage_editor/models/photo_asset.dart';
import 'package:piclayout/features/collage_editor/models/text_overlay.dart';
import 'package:piclayout/features/collage_editor/state/collage_editor_controller.dart';
import 'package:piclayout/features/projects/models/collage_project.dart';
import 'package:piclayout/features/projects/services/project_repository.dart';
import 'package:piclayout/features/templates/models/collage_template.dart';

CollageProject _project(int count) {
  final now = DateTime.utc(2026);
  return CollageProject(
    id: 'project',
    name: 'Test',
    createdAt: now,
    updatedAt: now,
    formatVersion: 1,
    aspectRatioId: '1_1',
    layoutTemplateId: LayoutLibrary.defaultFor(count).id,
    photos: [
      for (var i = 0; i < count; i++)
        PhotoAsset(id: '$i', originalFileName: '$i.jpg', localPath: '/$i.jpg'),
    ],
    canvas: const CanvasSettings(spacing: 9),
    textOverlays: const [TextOverlay(id: 'title', text: 'Title')],
  );
}

class _MemoryProjectRepository extends ProjectRepository {
  @override
  Future<void> save(CollageProject project) async {}
}

void main() {
  test('variation picks another compatible layout and preserves content', () {
    final controller = CollageEditorController(
      initialProject: _project(6),
      repository: _MemoryProjectRepository(),
      random: Random(7),
    );
    final before = controller.project;
    expect(controller.varyLayout(), isTrue);
    final after = controller.project;
    expect(after.layoutTemplateId, isNot(before.layoutTemplateId));
    expect(LayoutLibrary.templatesFor(6).map((item) => item.id),
        contains(after.layoutTemplateId));
    expect(after.photos.map((item) => item.id).toList(),
        before.photos.map((item) => item.id).toList());
    expect(after.canvas.spacing, 9);
    expect(after.textOverlays.single.text, 'Title');
    controller.undo();
    expect(controller.project.layoutTemplateId, before.layoutTemplateId);
    controller.redo();
    expect(controller.project.layoutTemplateId, after.layoutTemplateId);
    controller.dispose();
  });

  test('apply template is one undoable action and retains photos', () {
    final controller = CollageEditorController(
      initialProject: _project(4),
      repository: _MemoryProjectRepository(),
    );
    final original = controller.project;
    final source = _project(6).copyWith(
      canvas: const CanvasSettings(spacing: 24, outerMargin: 10),
    );
    final template = CollageTemplate.fromProject(
      id: 'template',
      name: 'Saved',
      project: source,
      includeTextOverlays: false,
    );
    controller.applyTemplate(template);
    expect(controller.project.photos, original.photos);
    expect(controller.project.canvas.spacing, 24);
    expect(controller.project.layoutTemplateId, LayoutLibrary.defaultFor(4).id);
    controller.undo();
    expect(controller.project.canvas.spacing, 9);
    controller.redo();
    expect(controller.project.canvas.spacing, 24);
    controller.dispose();
  });

  test('single photo has no variation', () {
    final controller = CollageEditorController(
      initialProject: _project(1),
      repository: _MemoryProjectRepository(),
    );
    expect(controller.canVaryLayout, isFalse);
    expect(controller.varyLayout(), isFalse);
    expect(controller.canUndo, isFalse);
    controller.dispose();
  });
}
