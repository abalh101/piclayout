import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piclayout/core/localization/app_localizations.dart';
import 'package:piclayout/features/collage_editor/models/canvas_settings.dart';
import 'package:piclayout/features/collage_editor/state/collage_editor_controller.dart';
import 'package:piclayout/features/collage_editor/widgets/collage_canvas.dart';
import 'package:piclayout/features/custom_layouts/models/custom_layout.dart';
import 'package:piclayout/features/projects/models/collage_project.dart';
import 'support/custom_layout_fixtures.dart';

void main() {
  testWidgets(
      'Dragging the divider lines themselves moves both axes and clamps cells',
      (tester) async {
    final repository = LayoutMemoryProjects();
    final controller = CollageEditorController(
        initialProject: layoutProject(count: 2)
            .copyWith(canvas: const CanvasSettings(spacing: 0, outerMargin: 0)),
        repository: repository);
    addTearDown(controller.dispose);
    controller.toggleDividerEditing();
    await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [AppLocalizations.delegate],
        home: Scaffold(
            body: Center(
                child: SizedBox(
                    width: 390,
                    height: 390,
                    child: CollageCanvas(controller: controller))))));
    await tester.pumpAndSettle();
    for (final axis in DividerAxis.values) {
      controller.setLayoutTemplate(
          axis == DividerAxis.vertical ? 'grid_2x1_2' : 'grid_1x2_2');
      await tester.pump();
      final divider = controller.editableCanvasLayout!.dividers.single;
      expect(divider.axis, axis);
      final line = find.byKey(ValueKey('canvas-seam-${divider.id}'));
      final handle = find.byKey(ValueKey('canvas-divider-${divider.id}'));
      final origin = tester.getCenter(line);
      // This gesture starts on the line, outside its arrow handle.
      expect(tester.getRect(handle).contains(origin), isFalse);
      final gesture = await tester.startGesture(origin);
      await gesture.moveBy(axis == DividerAxis.vertical
          ? const Offset(78, 0)
          : const Offset(0, 78));
      await tester.pump();
      final first = controller.project.customLayout!.cells.first;
      expect(axis == DividerAxis.vertical ? first.width : first.height,
          closeTo(.7, 1e-8));
      await gesture.moveBy(axis == DividerAxis.vertical
          ? const Offset(1000, 0)
          : const Offset(0, 1000));
      await tester.pump();
      final clamped = controller.project.customLayout!.cells.first;
      expect(axis == DividerAxis.vertical ? clamped.width : clamped.height,
          closeTo(.88, 1e-8));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 701));
      expect(repository.saved!.customLayout!.toJson(),
          controller.project.customLayout!.toJson());
      controller.undo();
      expect(controller.project.customLayout, isNull);
      controller.redo();
      expect(controller.project.customLayout!.isValid, isTrue);
      await controller.saveNow();
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Canvas drags both axes live with margin, one undo and autosave per gesture',
      (tester) async {
    final repository = LayoutMemoryProjects();
    final controller = CollageEditorController(
        initialProject: layoutProject(count: 12).copyWith(
            canvas: const CanvasSettings(spacing: 14, outerMargin: 39)),
        repository: repository);
    addTearDown(controller.dispose);
    controller.toggleDividerEditing();
    await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [AppLocalizations.delegate],
        home: Scaffold(
            body: Center(
                child: SizedBox(
                    width: 390,
                    height: 390,
                    child: CollageCanvas(controller: controller))))));
    await tester.pumpAndSettle();
    final original = controller.project;
    final vertical = controller.editableCanvasLayout!.dividers
        .firstWhere((d) => d.axis == DividerAxis.vertical);
    final gesture = await tester.startGesture(tester
        .getCenter(find.byKey(ValueKey('canvas-divider-${vertical.id}'))));
    await gesture.moveBy(const Offset(31.2, 0));
    await tester.pump();
    expect(controller.project.customLayout!.cells.first.width,
        closeTo(1 / 3 + .1, 1e-6));
    expect(controller.canUndo, isFalse);
    await gesture.moveBy(const Offset(15.6, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump(const Duration(seconds: 1));
    final firstEdit = controller.project.customLayout!.toJson();
    expect(repository.saved!.customLayout!.toJson(), firstEdit);
    controller.undo();
    expect(controller.project.customLayout, original.customLayout);
    expect(controller.canUndo, isFalse);
    controller.redo();
    await tester.pump();
    final horizontal = controller.editableCanvasLayout!.dividers
        .firstWhere((d) => d.axis == DividerAxis.horizontal);
    await tester.drag(find.byKey(ValueKey('canvas-divider-${horizontal.id}')),
        const Offset(0, 20));
    await tester.pump(const Duration(seconds: 1));
    expect(controller.project.customLayout!.cells.first.height,
        closeTo(.25 + 20 / 312, 1e-6));
    controller.undo();
    expect(controller.project.customLayout!.toJson(), firstEdit);
    expect(controller.project.photos, original.photos);
    await controller.saveNow();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  test('No-op divider gestures preserve redo and the built-in layout', () {
    final controller = CollageEditorController(
        initialProject: layoutProject(count: 12),
        repository: LayoutMemoryProjects());
    addTearDown(controller.dispose);
    controller.reorderPhotos(0, 11);
    controller.undo();
    final seam = controller.editableCanvasLayout!.dividers.first;
    controller.beginDividerDrag(seam);
    controller.updateDividerDrag(seam.position);
    controller.endDividerDrag();
    expect(controller.project.customLayout, isNull);
    expect(controller.canUndo, isFalse);
    expect(controller.canRedo, isTrue);
    controller.redo();
    expect(controller.project.photos.last.id, 'photo-0');
  });

  test(
      'Direct drags clamp, survive JSON reload and do not change unsupported layouts',
      () {
    final controller = CollageEditorController(
        initialProject: layoutProject(count: 12),
        repository: LayoutMemoryProjects());
    addTearDown(controller.dispose);
    for (final axis in DividerAxis.values) {
      final seam = controller.editableCanvasLayout!.dividers
          .firstWhere((d) => d.axis == axis);
      controller.beginDividerDrag(seam);
      controller.updateDividerDrag(-100);
      controller.updateDividerDrag(100);
      controller.endDividerDrag();
      expect(controller.project.customLayout!.isValid, isTrue);
    }
    final reloaded = CollageProject.fromJson(controller.project.toJson());
    expect(reloaded.photos, hasLength(12));
    expect(reloaded.customLayout!.toJson(),
        controller.project.customLayout!.toJson());
    controller.setLayoutTemplate('hero_left_12');
    expect(controller.canEditDividers, isFalse);
    controller.toggleDividerEditing();
    expect(controller.editingDividers, isFalse);
    expect(controller.project.layoutTemplateId, 'hero_left_12');
    controller
        .setLayoutTemplate('grid_3x4_11'); // falls back to 12-photo default
    expect(controller.canEditDividers, isTrue);
    final partial = CollageEditorController(
        initialProject: layoutProject(count: 7),
        repository: LayoutMemoryProjects());
    addTearDown(partial.dispose);
    expect(partial.canEditDividers, isFalse);
    expect(partial.project.customLayout, isNull);
    partial.setLayoutTemplate('uneven_rows_7');
    expect(partial.canEditDividers, isTrue);
  });
}
