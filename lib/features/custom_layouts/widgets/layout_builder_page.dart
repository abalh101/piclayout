import '../../stickers/sticker_renderer.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/localization/app_localizations.dart';
import '../../collage_editor/layouts/layout_library.dart';
import '../../collage_editor/rendering/layout_geometry.dart';
import '../../collage_editor/rendering/text_overlay_renderer.dart';
import '../../collage_editor/state/collage_editor_controller.dart';
import '../../collage_editor/widgets/styled_collage_scene.dart';
import '../../projects/models/collage_project.dart';
import '../models/custom_layout.dart';
import '../services/layout_builder_seed.dart';
import '../state/custom_layout_providers.dart';

Future<void> showLayoutBuilder(
    BuildContext context, CollageEditorController controller) async {
  final result = await Navigator.of(context).push<CustomLayout>(
      MaterialPageRoute(
          builder: (_) => LayoutBuilderPage(project: controller.project)));
  if (result != null) controller.applyCustomLayout(result);
}

Future<CustomLayout?> saveCustomLayoutDialog(
    BuildContext context, WidgetRef ref, CustomLayout layout) async {
  final strings = AppLocalizations.of(context);
  final name = await showDialog<String>(
      context: context,
      builder: (_) => _LayoutNameDialog(initialName: strings.tr(layout.name)));
  if (name == null || !context.mounted) return null;
  try {
    final saved = layout.savedAs(const Uuid().v4(), name);
    await ref.read(customLayoutsProvider.notifier).saveLayout(saved);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.tr('customLayoutSaved'))));
    }
    return saved;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.tr('customLayoutSaveFailed'))));
    }
    return null;
  }
}

class _LayoutNameDialog extends StatefulWidget {
  const _LayoutNameDialog({required this.initialName});
  final String initialName;
  @override
  State<_LayoutNameDialog> createState() => _LayoutNameDialogState();
}

class _LayoutNameDialogState extends State<_LayoutNameDialog> {
  late final _text = TextEditingController(text: widget.initialName);
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AlertDialog(
        title: Text(strings.tr('saveCustomLayout')),
        content: TextField(
            controller: _text,
            autofocus: true,
            maxLength: 60,
            decoration:
                InputDecoration(labelText: strings.tr('customLayoutName')),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (_text.text.trim().isNotEmpty) {
                Navigator.pop(context, _text.text.trim());
              }
            }),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(strings.cancel)),
          FilledButton(
              onPressed: _text.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(context, _text.text.trim()),
              child: Text(strings.tr('saveCustomLayout')))
        ]);
  }
}

class LayoutBuilderPage extends ConsumerStatefulWidget {
  const LayoutBuilderPage({required this.project, super.key});
  final CollageProject project;
  @override
  ConsumerState<LayoutBuilderPage> createState() => _LayoutBuilderPageState();
}

class _LayoutBuilderPageState extends ConsumerState<LayoutBuilderPage> {
  late final _seed = LayoutBuilderSeed.fromProject(widget.project);
  late CustomLayout _draft = _seed.layout;
  int _selectedCell = 0;
  bool _saving = false;
  CustomLayout? _dragStart;
  LayoutDivider? _dragDivider;
  Offset? _dragOrigin;
  double? _dragPosition;

  void _move(LayoutDivider divider, double value) {
    setState(() => _draft = _draft.moveDivider(divider, value));
  }

  void _endDrag() => setState(() {
        _dragStart = null;
        _dragDivider = null;
        _dragOrigin = null;
        _dragPosition = null;
      });

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final t = strings.tr;
    final project = widget.project.copyWith(customLayout: _draft);
    // Freeze handle identities during a drag, even if separate seams align.
    final dividers = (_dragStart ?? _draft).dividers;
    final selectedDividers =
        _draft.dividers.where((d) => d.touches(_selectedCell)).toList();
    final startingLayouts = [
      for (final template in LayoutLibrary.templatesFor(project.photos.length))
        if (LayoutBuilderSeed.fromTemplate(
                template, project.canvas.staggerAmount)
            case final layout?)
          layout
    ];
    final height = math.max(
        180.0, math.min(480.0, MediaQuery.sizeOf(context).height * .5));
    return PopScope(
        canPop: !_saving,
        child: Scaffold(
          appBar: AppBar(
              title:
                  Text(t('editCustomLayout'), overflow: TextOverflow.ellipsis),
              actions: [
                TextButton(
                    key: const ValueKey('layout-done'),
                    onPressed:
                        _saving ? null : () => Navigator.pop(context, _draft),
                    child: Text(strings.done))
              ]),
          body: SafeArea(
              child: ListView(padding: const EdgeInsets.all(16), children: [
            Text(t('layoutBuilderHint')),
            if (_seed.adjusted)
              Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(t('layoutBuilderAdjusted'))),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
                key: ValueKey(_draft.id),
                initialValue: startingLayouts.any((l) => l.id == _draft.id)
                    ? _draft.id
                    : null,
                isExpanded: true,
                decoration: InputDecoration(labelText: t('layoutBuilderStart')),
                hint: Text(t('customLayout')),
                items: [
                  for (final layout in startingLayouts)
                    DropdownMenuItem(
                        value: layout.id,
                        child: Text(t(layout.name),
                            overflow: TextOverflow.ellipsis))
                ],
                onChanged: _saving
                    ? null
                    : (id) {
                        if (id != null) {
                          setState(() => _draft =
                              startingLayouts.firstWhere((l) => l.id == id));
                        }
                      }),
            const SizedBox(height: 16),
            SizedBox(
                height: height,
                child: Center(
                    child: AspectRatio(
                        aspectRatio: project.aspectRatio.value,
                        child: LayoutBuilder(builder: (context, constraints) {
                          final size =
                              Size(constraints.maxWidth, constraints.maxHeight);
                          final margin = project.canvas.outerMargin *
                              size.shortestSide /
                              390;
                          final inner = Rect.fromLTWH(
                              margin,
                              margin,
                              math.max(1, size.width - 2 * margin),
                              math.max(1, size.height - 2 * margin));
                          return Stack(clipBehavior: Clip.none, children: [
                            Positioned.fill(
                                child: IgnorePointer(
                                    child:
                                        StyledCollageScene(project: project))),
                            Positioned.fill(
                                child: IgnorePointer(
                                    child: CustomPaint(
                                        painter: _BuilderOverlay(
                                            project,
                                            _selectedCell,
                                            dividers,
                                            inner,
                                            Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            _dragDivider?.id,
                                            _dragPosition)))),
                            Positioned.fill(
                                child: GestureDetector(
                                    key:
                                        const ValueKey('layout-builder-canvas'),
                                    behavior: HitTestBehavior.opaque,
                                    onTapUp: _saving
                                        ? null
                                        : (details) {
                                            final point = details.localPosition;
                                            for (var i = 0;
                                                i < _draft.cells.length;
                                                i++) {
                                              final c = _draft.cells[i];
                                              if (Rect.fromLTWH(
                                                      inner.left +
                                                          c.x * inner.width,
                                                      inner.top +
                                                          c.y * inner.height,
                                                      c.width * inner.width,
                                                      c.height * inner.height)
                                                  .contains(point)) {
                                                setState(
                                                    () => _selectedCell = i);
                                                break;
                                              }
                                            }
                                          })),
                            for (final divider in dividers)
                              _handle(divider, inner, t),
                          ]);
                        })))),
            const SizedBox(height: 20),
            Text(
                '${t('layoutBuilderCell')} ${_draft.cells[_selectedCell].photoIndex + 1}',
                style: Theme.of(context).textTheme.titleMedium),
            Text(t('layoutBuilderMinimum'),
                style: Theme.of(context).textTheme.bodySmall),
            if (selectedDividers.isEmpty) Text(t('layoutBuilderNoDividers')),
            for (final divider in selectedDividers) ...[
              const SizedBox(height: 10),
              Text(
                  '${t(divider.axis == DividerAxis.vertical ? 'layoutBuilderVertical' : 'layoutBuilderHorizontal')} · ${(divider.position * 100).round()}%'),
              Slider(
                  key: ValueKey('slider-${divider.id}'),
                  value: divider.position.clamp(
                      _draft.bounds(divider).$1,
                      math.max(_draft.bounds(divider).$1,
                          _draft.bounds(divider).$2)),
                  min: _draft.bounds(divider).$1,
                  max: math.max(
                      _draft.bounds(divider).$1, _draft.bounds(divider).$2),
                  label: '${(divider.position * 100).round()}%',
                  onChanged: _saving || _dragStart != null
                      ? null
                      : (value) => _move(divider, value)),
            ],
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              TextButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: Text(strings.cancel)),
              OutlinedButton.icon(
                  key: const ValueKey('layout-reset'),
                  onPressed: _saving
                      ? null
                      : () => setState(() {
                            _draft = _seed.layout;
                            _selectedCell = 0;
                          }),
                  icon: const Icon(Icons.restart_alt),
                  label: Text(t('reset'))),
              FilledButton.icon(
                  key: const ValueKey('layout-save'),
                  onPressed: _saving
                      ? null
                      : () async {
                          setState(() => _saving = true);
                          final saved = await saveCustomLayoutDialog(
                              context, ref, _draft);
                          if (mounted) {
                            setState(() {
                              if (saved != null) _draft = saved;
                              _saving = false;
                            });
                          }
                        },
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: Text(t('saveCustomLayout'))),
            ]),
          ])),
        ));
  }

  Widget _handle(LayoutDivider divider, Rect inner, String Function(String) t) {
    final position = _dragDivider?.id == divider.id
        ? _dragPosition ?? divider.position
        : divider.position;
    final point = _handlePoint(divider, inner, position);
    return Positioned(
        left: point.dx - 22,
        top: point.dy - 22,
        width: 44,
        height: 44,
        child: Semantics(
          label: t(divider.axis == DividerAxis.vertical
              ? 'layoutBuilderVertical'
              : 'layoutBuilderHorizontal'),
          child: GestureDetector(
              key: ValueKey('handle-${divider.id}'),
              dragStartBehavior: DragStartBehavior.down,
              behavior: HitTestBehavior.opaque,
              onPanStart: _saving
                  ? null
                  : (details) => setState(() {
                        _dragStart = _draft;
                        _dragDivider = divider;
                        _dragOrigin = details.globalPosition;
                        _dragPosition = divider.position;
                      }),
              onPanUpdate: _saving
                  ? null
                  : (details) {
                      final start = _dragStart;
                      final origin = _dragOrigin;
                      if (start == null || origin == null) return;
                      final delta = details.globalPosition - origin;
                      final requested = divider.position +
                          (divider.axis == DividerAxis.vertical
                              ? delta.dx / inner.width
                              : delta.dy / inner.height);
                      final (low, high) = start.bounds(divider);
                      if (low > high) return;
                      setState(() {
                        _draft = start.moveDivider(divider, requested);
                        _dragPosition = requested.clamp(low, high);
                      });
                    },
              onPanEnd: (_) => _endDrag(),
              onPanCancel: _endDrag,
              child: Center(
                  child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2)),
                      child: Icon(
                          divider.axis == DividerAxis.vertical
                              ? Icons.drag_indicator
                              : Icons.drag_handle,
                          size: 18,
                          color: Theme.of(context).colorScheme.onPrimary)))),
        ));
  }
}

Offset _handlePoint(LayoutDivider divider, Rect inner, double position) {
  // Different anchor fractions avoid overlapping handles at grid intersections.
  final fraction = divider.axis == DividerAxis.vertical ? .25 : .75;
  final along = divider.start + (divider.end - divider.start) * fraction;
  return divider.axis == DividerAxis.vertical
      ? Offset(
          inner.left + position * inner.width, inner.top + along * inner.height)
      : Offset(inner.left + along * inner.width,
          inner.top + position * inner.height);
}

class _BuilderOverlay extends CustomPainter {
  const _BuilderOverlay(this.project, this.selectedCell, this.dividers,
      this.inner, this.color, this.dragId, this.dragPosition);
  final CollageProject project;
  final int selectedCell;
  final List<LayoutDivider> dividers;
  final Rect inner;
  final Color color;
  final String? dragId;
  final double? dragPosition;
  @override
  void paint(Canvas canvas, Size size) {
    TextOverlayRenderer.paint(canvas, size, project.textOverlays);
    StickerRenderer.paint(canvas, size, project.stickers);
    final cells = LayoutGeometry.resolve(project, size);
    final selectedIndex = project.customLayout!.cells[selectedCell].photoIndex;
    for (final cell in cells.where((c) => c.photoIndex == selectedIndex)) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              cell.rect, Radius.circular(cell.cornerRadius)),
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
    }
    for (final divider in dividers) {
      final position = divider.id == dragId
          ? dragPosition ?? divider.position
          : divider.position;
      final vertical = divider.axis == DividerAxis.vertical;
      final start = Offset(
          inner.left + (vertical ? position : divider.start) * inner.width,
          inner.top + (vertical ? divider.start : position) * inner.height);
      final end = Offset(
          inner.left + (vertical ? position : divider.end) * inner.width,
          inner.top + (vertical ? divider.end : position) * inner.height);
      canvas.drawLine(
          start,
          end,
          Paint()
            ..color = Colors.white
            ..strokeWidth = 4);
      canvas.drawLine(
          start,
          end,
          Paint()
            ..color = color
            ..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant _BuilderOverlay oldDelegate) => true;
}
