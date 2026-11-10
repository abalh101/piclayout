import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/localization/app_localizations.dart';
import '../../collage_editor/models/canvas_style.dart';
import '../../collage_editor/models/text_overlay.dart';
import '../../collage_editor/state/collage_editor_controller.dart';
import '../../collage_editor/widgets/styled_collage_scene.dart';
import '../../collage_editor/widgets/style_studio_sheet.dart';
import '../../collage_editor/widgets/photo_edit_sheet.dart';
import '../models/editorial_design.dart';
import '../models/design_presets.dart';
import '../rendering/editorial_renderer.dart';

Future<void> showDesignSheet(
        BuildContext context, CollageEditorController controller,
        {bool layers = false}) =>
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom),
            child: DesignSheet(
                controller: controller, initialTab: layers ? 2 : 0)));

class DesignSheet extends StatelessWidget {
  const DesignSheet({required this.controller, this.initialTab = 0, super.key});
  final CollageEditorController controller;
  final int initialTab;
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).tr;
    final availableHeight = MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom;
    return DefaultTabController(
        length: 3,
        initialIndex: initialTab,
        child: SafeArea(
            child: SizedBox(
                height: availableHeight * .88,
                child: AnimatedBuilder(
                    animation: controller,
                    builder: (context, _) => Column(children: [
                          Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(children: [
                                Expanded(
                                    child: Text(t('edDesign'),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge)),
                                IconButton(
                                    tooltip: t('undo'),
                                    onPressed: controller.canUndo
                                        ? controller.undo
                                        : null,
                                    icon: const Icon(Icons.undo)),
                                IconButton(
                                    tooltip: t('done'),
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(Icons.check)),
                              ])),
                          if (availableHeight >= 320)
                            SizedBox(
                                height: availableHeight * .16,
                                child: Center(
                                    child: AspectRatio(
                                        aspectRatio: controller
                                            .project.aspectRatio.value,
                                        child: StyledCollageScene(
                                            project: controller.project)))),
                          TabBar(
                              isScrollable: true,
                              tabAlignment: TabAlignment.start,
                              tabs: [
                                Tab(text: t('edPresets')),
                                Tab(text: t('edPage')),
                                Tab(text: t('edLayers'))
                              ]),
                          Expanded(
                              child: TabBarView(children: [
                            _presets(context),
                            _page(context),
                            _layers(context)
                          ])),
                        ])))));
  }

  Future<bool> _confirm(BuildContext context) async {
    if (controller.project.design.layers.isEmpty) return true;
    final t = AppLocalizations.of(context).tr;
    return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                    title: Text(t('edChangeDesign')),
                    content: Text(t('edChangeWarning')),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(t('cancel'))),
                      FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(t('applyTemplate')))
                    ])) ??
        false;
  }

  Widget _presets(BuildContext context) {
    final t = AppLocalizations.of(context).tr;
    final design = controller.project.design;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Wrap(spacing: 8, runSpacing: 8, children: [
        ChoiceChip(
            label: Text(t('edStandard')),
            selected: !design.active,
            onSelected: (_) => controller
                .applyDesign(design.copyWith(mode: DesignMode.standard))),
        ActionChip(
            label: Text(t('edBlank')),
            avatar: const Icon(Icons.add),
            onPressed: () async {
              if (await _confirm(context)) {
                controller
                    .applyDesign(const EditorialDesign(mode: DesignMode.blank));
              }
            }),
        if (!design.active && design.layers.isNotEmpty)
          ActionChip(
              label: Text(t('edResume')),
              onPressed: () => controller.applyDesign(design.copyWith(
                  mode: DesignPreset.all
                          .where((preset) => preset.key == design.preset)
                          .firstOrNull
                          ?.mode ??
                      DesignMode.blank))),
      ]),
      const SizedBox(height: 12),
      for (final preset in DesignPreset.all)
        Card(
            child: ListTile(
          selected: design.active && design.preset == preset.key,
          leading: SizedBox(
              width: 42,
              height: 64,
              child: CustomPaint(
                  painter: _PresetThumbnail(
                      preset.create(controller.project.photos, t)))),
          title: Text(t(preset.key)),
          subtitle: Text(t('edMode_${preset.mode.name}')),
          trailing: design.active && design.preset == preset.key
              ? const Icon(Icons.check_circle)
              : null,
          onTap: () async {
            if (!await _confirm(context)) return;
            controller.applyDesign(preset.create(controller.project.photos, t),
                story: true);
          },
        )),
    ]);
  }

  Widget _page(BuildContext context) {
    final t = AppLocalizations.of(context).tr;
    final d = controller.project.design;
    void settings(EditorialDesign value, {bool live = false}) =>
        controller.updateDesignSettings(value, live: live);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(t('edSpacingHint')),
      _slider(
          context,
          'outerMargin',
          d.margin,
          0,
          .18,
          (v) => settings(controller.project.design.copyWith(margin: v),
              live: true)),
      _slider(
          context,
          'edGapX',
          d.gapX,
          0,
          .1,
          (v) => settings(controller.project.design.copyWith(gapX: v),
              live: true)),
      _slider(
          context,
          'edGapY',
          d.gapY,
          0,
          .12,
          (v) => settings(controller.project.design.copyWith(gapY: v),
              live: true)),
      _slider(
          context,
          'edTitleArea',
          d.header,
          0,
          .3,
          (v) => settings(controller.project.design.copyWith(header: v),
              live: true)),
      if (d.mode == DesignMode.editorial) ...[
        _choice<int>(context, 'edColumns', d.columns, [1, 2, 3, 4], (v) => '$v',
            (v) => settings(d.copyWith(columns: v))),
        _choice<NumberStyle>(
            context,
            'edNumbering',
            d.numberStyle,
            NumberStyle.values,
            (v) => t('edNumber_${v.name}'),
            (v) => settings(d.copyWith(numberStyle: v))),
      ],
      _color(
          context,
          'background',
          controller.project.canvas.backgroundColor,
          (color) => controller.updateCanvas(controller.project.canvas.copyWith(
              backgroundColor: color,
              style: controller.project.canvas.style
                  .copyWith(backgroundType: BackgroundType.solid)))),
      Wrap(spacing: 8, children: [
        OutlinedButton(
            onPressed: () => controller.updateCanvas(controller.project.canvas
                .copyWith(
                    style: controller.project.canvas.style
                        .copyWith(backgroundType: BackgroundType.transparent))),
            child: Text(t('edTransparent'))),
        OutlinedButton(
            onPressed: () => showStyleStudio(context, controller),
            child: Text(t('style'))),
      ]),
      Text(t('edAddTextHint')),
    ]);
  }

  Widget _layers(BuildContext context) {
    final t = AppLocalizations.of(context).tr;
    final selected = controller.selectedDesignLayer;
    final d = controller.project.design;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(t('edGestureHint')),
      Wrap(spacing: 8, runSpacing: 4, children: [
        for (final type in [
          DesignLayerType.photo,
          DesignLayerType.torn,
          DesignLayerType.callout,
          DesignLayerType.text,
          DesignLayerType.location,
          DesignLayerType.background,
          DesignLayerType.connector
        ])
          ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: Text(t('edType_${type.name}')),
              onPressed: () => _add(context, type)),
      ]),
      for (final layer in d.ordered.reversed)
        ListTile(
            dense: true,
            key: ValueKey('design-layer-${layer.id}'),
            selected: selected?.id == layer.id,
            leading: Icon(layer.locked
                ? Icons.lock
                : layer.isPhoto
                    ? Icons.photo_outlined
                    : layer.isText
                        ? Icons.text_fields
                        : Icons.layers_outlined),
            title: Text(
                layer.isText && layer.text.text.isNotEmpty
                    ? layer.text.text
                    : t('edType_${layer.type.name}'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            trailing: IconButton(
                tooltip: t(layer.visible ? 'edHide' : 'edShow'),
                icon: Icon(
                    layer.visible ? Icons.visibility : Icons.visibility_off),
                onPressed: layer.locked
                    ? null
                    : () => controller.updateDesignLayer(
                        layer.copyWith(visible: !layer.visible))),
            onTap: () => controller.selectDesignLayer(layer.id)),
      if (selected != null) ...[
        const Divider(),
        Text(t('edType_${selected.type.name}'),
            style: Theme.of(context).textTheme.titleMedium),
        Wrap(spacing: 8, runSpacing: 4, children: [
          _action(
              context,
              'edForward',
              Icons.flip_to_front,
              selected.locked
                  ? null
                  : () => controller.reorderDesignLayer(forward: true)),
          _action(
              context,
              'edBackward',
              Icons.flip_to_back,
              selected.locked
                  ? null
                  : () => controller.reorderDesignLayer(forward: false)),
          _action(context, 'duplicate', Icons.copy,
              selected.locked ? null : controller.duplicateDesignLayer),
          _action(
              context,
              selected.locked ? 'edUnlock' : 'edLock',
              selected.locked ? Icons.lock_open : Icons.lock,
              () => controller.updateDesignLayer(
                  selected.copyWith(locked: !selected.locked))),
          _action(context, 'delete', Icons.delete_outline,
              selected.locked ? null : controller.deleteDesignLayer),
        ]),
        if (!selected.locked) ..._properties(context, selected),
      ],
    ]);
  }

  void _add(BuildContext context, DesignLayerType type) {
    final t = AppLocalizations.of(context).tr;
    final photo =
        controller.selectedPhoto ?? controller.project.photos.firstOrNull;
    controller.addDesignLayer(DesignLayer(
        id: const Uuid().v4(),
        type: type,
        photoId: photo?.id,
        text: TextOverlay(
            id: const Uuid().v4(),
            text: type == DesignLayerType.location
                ? '${t('edEvenings')}\n${t('edLocationExample')}'
                : t('textOverlay'),
            fontSize: 24,
            color: 0xFF202020,
            padding: 8,
            backgroundColor:
                type == DesignLayerType.location ? 0xAAFFFFFF : null),
        width: type == DesignLayerType.background ? 1 : .5,
        height: type == DesignLayerType.background ? 1 : .25,
        borderWidth: type == DesignLayerType.callout ? 2 : 0,
        radius: type == DesignLayerType.callout ? 12 : 0));
  }

  List<Widget> _properties(BuildContext context, DesignLayer l) {
    final t = AppLocalizations.of(context).tr;
    void update(DesignLayer next) => controller.updateDesignLayer(next);
    void live(DesignLayer next) =>
        controller.updateDesignLayer(next, live: true);
    DesignLayer current() => controller.selectedDesignLayer ?? l;
    return [
      _slider(context, 'edPositionX', l.x, 0, 1,
          (v) => live(current().copyWith(x: v))),
      _slider(context, 'edPositionY', l.y, 0, 1,
          (v) => live(current().copyWith(y: v))),
      _slider(context, 'edWidth', l.width, .02, 1.5,
          (v) => live(current().copyWith(width: v))),
      _slider(context, 'edHeight', l.height, .02, 1.5,
          (v) => live(current().copyWith(height: v))),
      _slider(context, 'rotate', l.rotation, -180, 180,
          (v) => live(current().copyWith(rotation: v))),
      _slider(context, 'edOpacity', l.opacity, 0, 1,
          (v) => live(current().copyWith(opacity: v))),
      _slider(context, 'cornerRadius', l.radius, 0, 100,
          (v) => live(current().copyWith(radius: v))),
      if (l.isPhoto || l.type == DesignLayerType.connector) ...[
        _choice<String>(
            context,
            'edSource',
            l.source(controller.project.photos)?.id ?? '',
            controller.project.photos.map((p) => p.id).toList(),
            (id) =>
                '${t('Bild')} ${controller.project.photos.indexWhere((p) => p.id == id) + 1}',
            (id) => update(l.copyWith(photoId: id))),
        if (l.type != DesignLayerType.callout &&
            l.type != DesignLayerType.connector)
          _action(context, 'edEditCrop', Icons.crop, () {
            controller.setDesignCropEditing(true);
            Navigator.pop(context);
          }),
        if (l.isPhoto)
          _action(context, 'editPhoto', Icons.tune,
              () => showPhotoEditor(context, controller)),
      ],
      if (l.isText) ...[
        TextFormField(
            key: ValueKey('text-${l.id}'),
            initialValue: l.text.text,
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(labelText: t('textContent')),
            onChanged: (v) {
              update(
                  current().copyWith(text: current().text.copyWith(text: v)));
              if (l.type == DesignLayerType.caption &&
                  controller.project.design.numberStyle != NumberStyle.custom) {
                controller.updateDesignSettings(controller.project.design
                    .copyWith(numberStyle: NumberStyle.custom));
              }
            }),
        _choice<String>(
            context,
            'edFont',
            l.text.fontFamily ?? 'sans-serif',
            ['sans-serif', 'serif', 'monospace'],
            (v) => t('edFont_$v'),
            (v) => update(l.copyWith(text: l.text.copyWith(fontFamily: v)))),
        _slider(
            context,
            'fontSize',
            l.text.fontSize,
            12,
            72,
            (v) => live(current()
                .copyWith(text: current().text.copyWith(fontSize: v)))),
        _color(context, 'textColor', l.text.color,
            (v) => update(l.copyWith(text: l.text.copyWith(color: v)))),
        _color(
            context,
            'textBackground',
            l.text.backgroundColor ?? 0,
            (v) =>
                update(l.copyWith(text: l.text.copyWith(backgroundColor: v)))),
        _choice<TextOverlayAlignment>(
            context,
            'textAlignment',
            l.text.alignment,
            TextOverlayAlignment.values,
            (v) => t(v.name),
            (v) => update(l.copyWith(text: l.text.copyWith(alignment: v)))),
        _slider(
            context,
            'edPadding',
            l.text.padding,
            0,
            32,
            (v) => live(
                current().copyWith(text: current().text.copyWith(padding: v)))),
        _slider(
            context,
            'edLabelRadius',
            l.text.cornerRadius,
            0,
            40,
            (v) => live(current()
                .copyWith(text: current().text.copyWith(cornerRadius: v)))),
        if (l.type == DesignLayerType.location)
          SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t('edLocationIcon')),
              value: l.showLocationIcon,
              onChanged: (v) => update(l.copyWith(showLocationIcon: v))),
      ],
      if (l.type == DesignLayerType.background)
        _color(context, 'background', l.color,
            (v) => update(l.copyWith(color: v))),
      if (l.type == DesignLayerType.torn) ...[
        _choice<TearStyle>(
            context,
            'edTearStyle',
            l.tearStyle,
            TearStyle.values,
            (v) => t('edTear_${v.name}'),
            (v) => update(l.copyWith(tearStyle: v))),
        _choice<TearEdges>(
            context,
            'edTearEdges',
            l.tearEdges,
            TearEdges.values,
            (v) => t('edEdges_${v.name}'),
            (v) => update(l.copyWith(tearEdges: v))),
        _slider(context, 'edTearIntensity', l.tearIntensity, 0, 1,
            (v) => live(current().copyWith(tearIntensity: v))),
        _slider(context, 'edRoughness', l.roughness, 0, 1,
            (v) => live(current().copyWith(roughness: v))),
        SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t('edPaperShadow')),
            value: l.shadow,
            onChanged: (v) => update(l.copyWith(shadow: v))),
      ],
      if (l.type == DesignLayerType.callout) ...[
        _choice<CalloutShape>(context, 'edShape', l.shape, CalloutShape.values,
            (v) => t('edShape_${v.name}'), (v) => update(l.copyWith(shape: v))),
        _action(context, 'edSourceCrop', Icons.zoom_in,
            () => _sourceCrop(context, l)),
        SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t('edConnector')),
            value: l.connector,
            onChanged: (v) => update(l.copyWith(connector: v))),
      ],
      _slider(context, 'edBorderWidth', l.borderWidth, 0, 20,
          (v) => live(current().copyWith(borderWidth: v))),
      _color(context, 'edBorderColor', l.borderColor,
          (v) => update(l.copyWith(borderColor: v))),
      if (l.type == DesignLayerType.callout ||
          l.type == DesignLayerType.connector) ...[
        _color(context, 'edLineColor', l.lineColor,
            (v) => update(l.copyWith(lineColor: v))),
        _slider(context, 'edLineWidth', l.lineWidth, 0, 12,
            (v) => live(current().copyWith(lineWidth: v))),
        _slider(
            context,
            'edEndpointX',
            l.endpoint.dx,
            0,
            1,
            (v) => live(current()
                .copyWith(endpoint: Offset(v, current().endpoint.dy)))),
        _slider(
            context,
            'edEndpointY',
            l.endpoint.dy,
            0,
            1,
            (v) => live(current()
                .copyWith(endpoint: Offset(current().endpoint.dx, v)))),
      ],
    ];
  }

  Future<void> _sourceCrop(BuildContext context, DesignLayer layer) async {
    final source = layer.source(controller.project.photos);
    if (source == null) return;
    final result = await showDialog<Rect>(
        context: context,
        builder: (_) =>
            _SourceCropDialog(path: source.localPath, crop: layer.crop));
    if (result != null) {
      controller.updateDesignLayer(layer.copyWith(crop: result));
    }
  }

  Widget _action(BuildContext context, String key, IconData icon,
          VoidCallback? action) =>
      OutlinedButton.icon(
          onPressed: action,
          icon: Icon(icon, size: 18),
          label: Text(AppLocalizations.of(context).tr(key)));

  Widget _slider(BuildContext context, String key, double value, double min,
          double max, ValueChanged<double> change) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
            '${AppLocalizations.of(context).tr(key)} · ${value.toStringAsFixed(max <= 1 ? 2 : 0)}'),
        Slider(
            key: ValueKey(key),
            value: value.clamp(min, max),
            min: min,
            max: max,
            semanticFormatterCallback: (v) => v.toStringAsFixed(2),
            onChangeStart: (_) => controller.beginInteractiveTransform(),
            onChanged: change,
            onChangeEnd: (_) => controller.endInteractiveTransform()),
      ]);

  Widget _choice<T>(BuildContext context, String key, T value, List<T> values,
          String Function(T) label, ValueChanged<T> change) =>
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppLocalizations.of(context).tr(key)),
            Wrap(spacing: 8, runSpacing: 4, children: [
              for (final v in values)
                ChoiceChip(
                    label: Text(label(v)),
                    selected: v == value,
                    onSelected: (_) => change(v))
            ]),
          ]));

  Widget _color(
      BuildContext context, String key, int color, ValueChanged<int> change) {
    final t = AppLocalizations.of(context).tr;
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t(key)),
          Wrap(spacing: 8, runSpacing: 4, children: [
            for (final option in [
              (0xFFFFFFFF, 'white'),
              (0xFF000000, 'black'),
              (0xFFF4EFE6, 'edCream'),
              (0x88FFFFFF, 'edTranslucent'),
              (0x00000000, 'edTransparent')
            ])
              ChoiceChip(
                  label: Text(t(option.$2)),
                  selected: color == option.$1,
                  onSelected: (_) => change(option.$1)),
            ActionChip(
                label: Text(t('edCustomColor')),
                onPressed: () async {
                  final result = await showDialog<int>(
                      context: context, builder: (_) => _ColorDialog(color));
                  if (result != null) change(result);
                }),
          ]),
        ]));
  }
}

class _ColorDialog extends StatefulWidget {
  const _ColorDialog(this.color);
  final int color;
  @override
  State<_ColorDialog> createState() => _ColorDialogState();
}

class _ColorDialogState extends State<_ColorDialog> {
  late final input = TextEditingController(
      text: widget.color.toRadixString(16).padLeft(8, '0').toUpperCase());
  int? value;
  @override
  void initState() {
    super.initState();
    value = widget.color;
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).tr;
    return AlertDialog(
        title: Text(t('edCustomColor')),
        content: TextField(
            controller: input,
            maxLength: 8,
            decoration: InputDecoration(
                labelText: t('edHexColor'),
                errorText: value == null ? t('edInvalidColor') : null),
            onChanged: (v) => setState(() => value =
                RegExp(r'^[0-9a-fA-F]{8}$').hasMatch(v)
                    ? int.tryParse(v, radix: 16)
                    : null)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('cancel'))),
          FilledButton(
              onPressed:
                  value == null ? null : () => Navigator.pop(context, value),
              child: Text(t('done')))
        ]);
  }
}

class _SourceCropDialog extends StatefulWidget {
  const _SourceCropDialog({required this.path, required this.crop});
  final String path;
  final Rect crop;
  @override
  State<_SourceCropDialog> createState() => _SourceCropDialogState();
}

class _SourceCropDialogState extends State<_SourceCropDialog> {
  late Rect crop = widget.crop;
  Rect start = Rect.zero;
  Offset focal = Offset.zero;
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).tr;
    return AlertDialog(
        title: Text(t('edSourceCrop')),
        content: SizedBox(
            width: 340,
            child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(t('edCropHint')),
              Image.file(File(widget.path),
                  cacheWidth: 768,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Text(t('photoLoadFailed')),
                  frameBuilder: (context, image, frame, sync) =>
                      Stack(children: [
                        image,
                        Positioned.fill(
                            child: LayoutBuilder(
                                builder: (context, box) => GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onScaleStart: (d) {
                                      start = crop;
                                      focal = d.focalPoint;
                                    },
                                    onScaleUpdate: (d) {
                                      final delta = d.focalPoint - focal;
                                      setState(() => crop = const DesignLayer(
                                              id: 'crop',
                                              type: DesignLayerType.callout)
                                          .copyWith(
                                              crop: Rect.fromCenter(
                                                  center: start.center +
                                                      Offset(
                                                          delta.dx /
                                                              box.maxWidth,
                                                          delta.dy /
                                                              box.maxHeight),
                                                  width: start.width / d.scale,
                                                  height:
                                                      start.height / d.scale))
                                          .crop);
                                    },
                                    child: CustomPaint(
                                        painter: _CropPainter(crop))))),
                      ])),
              for (final axis in [true, false])
                Column(children: [
                  Text(t(axis ? 'edWidth' : 'edHeight')),
                  Slider(
                      value: axis ? crop.width : crop.height,
                      min: .01,
                      max: 1,
                      onChanged: (v) => setState(() => crop = const DesignLayer(
                              id: 'crop', type: DesignLayerType.callout)
                          .copyWith(
                              crop: Rect.fromLTWH(
                                  crop.left,
                                  crop.top,
                                  axis ? v : crop.width,
                                  axis ? crop.height : v))
                          .crop))
                ]),
            ]))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(context, crop),
              child: Text(t('done')))
        ]);
  }
}

class _CropPainter extends CustomPainter {
  const _CropPainter(this.crop);
  final Rect crop;
  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(crop.left * size.width, crop.top * size.height,
        crop.width * size.width, crop.height * size.height);
    canvas.drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(Offset.zero & size)
          ..addRect(r),
        Paint()..color = const Color(0x77000000));
    canvas.drawRect(
        r,
        Paint()
          ..color = Colors.cyanAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant _CropPainter old) => old.crop != crop;
}

class _PresetThumbnail extends CustomPainter {
  const _PresetThumbnail(this.design);
  final EditorialDesign design;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    for (final l in design.ordered) {
      final r = EditorialRenderer.bounds(l, size);
      if (l.isPhoto) {
        canvas.drawPath(
            EditorialRenderer.clipPath(l, r, size),
            Paint()
              ..color = Color.lerp(const Color(0xFF9CADA9),
                  const Color(0xFF385762), (l.photoSlot % 4) / 4)!);
      } else if (l.isText) {
        canvas.drawRect(
            Rect.fromCenter(
                center: r.center,
                width: r.width * .65,
                height: math.min(2, r.height)),
            Paint()..color = const Color(0xFF555555));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PresetThumbnail old) => old.design != design;
}
