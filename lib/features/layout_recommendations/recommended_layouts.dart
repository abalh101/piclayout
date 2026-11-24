import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../collage_editor/layouts/layout_library.dart';
import '../collage_editor/models/layout_template.dart';
import 'layout_recommendation_service.dart';

class RecommendedLayouts extends StatefulWidget {
  const RecommendedLayouts(
      {required this.recommendations,
      required this.targetRatio,
      required this.onSelected,
      this.selectedId,
      this.onAuto,
      this.loading = false,
      this.staggerAmount = 0,
      super.key});
  final List<LayoutRecommendation> recommendations;
  final double targetRatio, staggerAmount;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final VoidCallback? onAuto;
  final bool loading;

  @override
  State<RecommendedLayouts> createState() => _RecommendedLayoutsState();
}

class _RecommendedLayoutsState extends State<RecommendedLayouts> {
  LayoutFocus _focus = LayoutFocus.bestFit;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).tr;
    final groups = {
      for (final item in LayoutFocus.values)
        item: const LayoutRecommendationService()
            .rankBy(widget.recommendations, item),
    };
    final focus = groups[_focus]!.isEmpty ? LayoutFocus.bestFit : _focus;
    final recommendations = groups[focus]!;
    final loading = widget.loading;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(
          spacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(t('recRecommended'),
                style: Theme.of(context).textTheme.titleMedium),
            if (widget.onAuto != null)
              FilledButton.tonalIcon(
                  key: const ValueKey('auto-layout'),
                  onPressed: loading || recommendations.isEmpty
                      ? null
                      : () {
                          if (focus == LayoutFocus.bestFit) {
                            widget.onAuto!();
                          } else {
                            widget.onSelected(recommendations.first.layout.id);
                          }
                        },
                  icon: const Icon(Icons.auto_awesome_mosaic_outlined),
                  label: Text(t('recAuto'))),
          ]),
      if (widget.recommendations.length > 1)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final item in LayoutFocus.values)
              if (groups[item]!.isNotEmpty)
                Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                        label: Text(t('layoutFocus_${item.name}')),
                        selected: focus == item,
                        onSelected: loading
                            ? null
                            : (_) => setState(() => _focus = item))),
          ]),
        ),
      if (loading) ...[
        const LinearProgressIndicator(),
        Text(t('recLoading'), style: Theme.of(context).textTheme.bodySmall),
      ],
      SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final item in recommendations.take(3))
              SizedBox(
                  width: 190,
                  child: Semantics(
                      button: true,
                      selected: widget.selectedId == item.layout.id,
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        color: widget.selectedId == item.layout.id
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        child: InkWell(
                          key: ValueKey('recommend-${item.layout.id}'),
                          onTap: loading
                              ? null
                              : () => widget.onSelected(item.layout.id),
                          child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                        height: 88,
                                        child: Center(
                                            child: AspectRatio(
                                                aspectRatio: widget.targetRatio,
                                                child: CustomPaint(
                                                    painter:
                                                        LayoutPreviewPainter(
                                                            item.layout,
                                                            staggerAmount: widget
                                                                .staggerAmount,
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .primary))))),
                                    const SizedBox(height: 8),
                                    Text(t(item.layout.title),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall),
                                    const SizedBox(height: 4),
                                    Text(
                                        t(focus == LayoutFocus.bestFit
                                            ? item.reasonKey
                                            : 'layoutReason_${focus.name}'),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                  ])),
                        ),
                      ))),
          ])),
      const SizedBox(height: 12),
    ]);
  }
}

/// Uses the same normalized cells and photo indices as editor/export geometry.
class LayoutPreviewPainter extends CustomPainter {
  const LayoutPreviewPainter(this.layout,
      {required this.color, this.staggerAmount = 0});
  final LayoutTemplate layout;
  final Color color;
  final double staggerAmount;
  @override
  void paint(Canvas canvas, Size size) {
    for (final cell
        in LayoutLibrary.cellsFor(layout, staggerAmount: staggerAmount)) {
      final rect = Rect.fromLTWH(
          cell.rect.x * size.width,
          cell.rect.y * size.height,
          cell.rect.width * size.width,
          cell.rect.height * size.height);
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(2)),
          Paint()
            ..color =
                color.withValues(alpha: .45 + (cell.photoIndex % 3) * .22));
    }
  }

  @override
  bool shouldRepaint(LayoutPreviewPainter old) =>
      old.layout.id != layout.id ||
      old.color != color ||
      old.staggerAmount != staggerAmount;
}
