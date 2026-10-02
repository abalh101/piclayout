import '../../collage_editor/layouts/layout_library.dart';
import '../../collage_editor/models/layout_template.dart';
import '../../projects/models/collage_project.dart';
import '../models/custom_layout.dart';

class LayoutBuilderSeed {
  const LayoutBuilderSeed(this.layout, {this.adjusted = false});
  final CustomLayout layout;
  final bool adjusted;
  static CustomLayout? fromTemplate(LayoutTemplate template, double stagger) {
    try {
      return CustomLayout.fromCells(
          id: 'draft_${template.id}',
          name: template.title,
          cells: LayoutLibrary.cellsFor(template, staggerAmount: stagger));
    } on FormatException {
      return null;
    }
  }

  static LayoutBuilderSeed fromProject(CollageProject project) {
    if (project.customLayout case final layout?) {
      return LayoutBuilderSeed(layout);
    }
    final initial = fromTemplate(
        LayoutLibrary.byIdOrDefault(
            project.layoutTemplateId, project.photos.length),
        project.canvas.staggerAmount);
    if (initial != null) return LayoutBuilderSeed(initial);
    // Some built-ins intentionally leave unused grid slots or use <12% cells.
    for (final template in LayoutLibrary.templatesFor(project.photos.length)) {
      final layout = fromTemplate(template, project.canvas.staggerAmount);
      if (layout != null) return LayoutBuilderSeed(layout, adjusted: true);
    }
    throw StateError('No editable layout for photo count');
  }
}
