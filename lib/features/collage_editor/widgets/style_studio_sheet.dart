import '../../../core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import '../models/canvas_style.dart';
import '../models/style_presets.dart';
import '../state/collage_editor_controller.dart';

Future<void> showStyleStudio(
        BuildContext context, CollageEditorController controller) =>
    showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (context) => SafeArea(
                child: SizedBox(
                    height: MediaQuery.sizeOf(context).height * .62,
                    child: _StyleStudio(controller))))
        .whenComplete(controller.endCanvasEdit);

class _StyleStudio extends StatelessWidget {
  const _StyleStudio(this.controller);
  final CollageEditorController controller;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = AppLocalizations.of(context).tr;
        final settings = controller.project.canvas;
        final style = settings.style;
        void change(CanvasStyle value) =>
            controller.updateCanvas(settings.copyWith(style: value));
        Widget slider(String label, double value, double min, double max,
                ValueChanged<double> update) =>
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${t(label)} · ${value.toStringAsFixed(1)}'),
              Slider(
                  value: value.clamp(min, max),
                  min: min,
                  max: max,
                  onChangeStart: (_) => controller.beginCanvasEdit(),
                  onChanged: update,
                  onChangeEnd: (_) => controller.endCanvasEdit())
            ]);
        Widget colors(int value, ValueChanged<int> update) =>
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final entry in const <String, int>{
                'Weiß': 0xFFFFFFFF,
                'Schwarz': 0xFF000000,
                'Creme': 0xFFFFF4DE,
                'Blau': 0xFF2563EB,
                'Rosa': 0xFFF9A8D4,
                'Mint': 0xFFB9E9E4,
                'Gelb': 0xFFFFD54F,
                'Rot': 0xFFEF4444
              }.entries)
                ChoiceChip(
                    label: Text(t(entry.key)),
                    avatar: CircleAvatar(
                        backgroundColor: Color(entry.value), radius: 8),
                    selected: value == entry.value,
                    onSelected: (_) => update(entry.value))
            ]);
        Widget page(List<Widget> children) =>
            ListView(padding: const EdgeInsets.all(16), children: [
              for (final child in children)
                Padding(
                    padding: const EdgeInsets.only(bottom: 12), child: child)
            ]);
        return DefaultTabController(
            length: 4,
            child: Column(children: [
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    Expanded(
                        child: Text(t('Style Studio'),
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold))),
                    TextButton(
                        onPressed: controller.resetStyle,
                        child: Text(t('Reset')))
                  ])),
              TabBar(isScrollable: true, tabs: [
                Tab(text: t('Hintergrund')),
                Tab(text: t('Rahmen')),
                Tab(text: t('Schatten')),
                Tab(text: t('Presets'))
              ]),
              Expanded(
                  child: TabBarView(children: [
                page([
                  Wrap(spacing: 6, children: [
                    for (final entry in const <BackgroundType, String>{
                      BackgroundType.solid: 'Einfarbig',
                      BackgroundType.gradient: 'Verlauf',
                      BackgroundType.blur: 'Foto-Blur',
                      BackgroundType.paper: 'Papier',
                      BackgroundType.grid: 'Soft Grid',
                      BackgroundType.dots: 'Dots',
                      BackgroundType.transparent: 'Transparent'
                    }.entries)
                      ChoiceChip(
                          label: Text(t(entry.value)),
                          selected: style.backgroundType == entry.key,
                          onSelected: (_) =>
                              change(style.copyWith(backgroundType: entry.key)))
                  ]),
                  if (style.backgroundType == BackgroundType.transparent)
                    Text(t(
                        'PNG bleibt transparent. JPEG erhält einen weißen Hintergrund. Das Schachbrett dient nur der Vorschau.')),
                  if (style.backgroundType != BackgroundType.transparent) ...[
                    Text(t('Hintergrundfarbe')),
                    colors(
                        settings.backgroundColor,
                        (value) => controller.updateCanvas(
                            settings.copyWith(backgroundColor: value)))
                  ],
                  if (style.backgroundType == BackgroundType.gradient) ...[
                    Text(t('Zweite Farbe')),
                    colors(
                        style.gradientEndColor,
                        (value) =>
                            change(style.copyWith(gradientEndColor: value))),
                    slider('Verlaufsrichtung', style.gradientAngle, -180, 180,
                        (value) => change(style.copyWith(gradientAngle: value)))
                  ],
                  if (style.backgroundType == BackgroundType.blur) ...[
                    Wrap(spacing: 6, children: [
                      ActionChip(
                          label: Text(t('Kein Blur')),
                          onPressed: () => change(style.copyWith(
                              backgroundType: BackgroundType.solid))),
                      ActionChip(
                          label: Text(t('Aktives Bild')),
                          onPressed: controller.selectedPhotoId == null
                              ? null
                              : () => change(style.copyWith(
                                  blurPhotoIndex: controller.project.photos
                                      .indexWhere((p) =>
                                          p.id ==
                                          controller.selectedPhotoId)))),
                      for (int i = 0; i < controller.project.photos.length; i++)
                        ChoiceChip(
                            label: Text('${t('Bild')} ${i + 1}'),
                            selected: style.blurPhotoIndex == i,
                            onSelected: (_) =>
                                change(style.copyWith(blurPhotoIndex: i)))
                    ]),
                    slider('Blur-Stärke', style.blurSigma, 0, 40,
                        (v) => change(style.copyWith(blurSigma: v))),
                    slider('Dunkler / heller', style.brightness, -1, 1,
                        (v) => change(style.copyWith(brightness: v))),
                    SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(t('Sättigung reduzieren')),
                        value: style.desaturate,
                        onChanged: (v) =>
                            change(style.copyWith(desaturate: v))),
                    Text(t(
                        'Die Quelle ist die gewählte Bildposition. Originaldateien bleiben unverändert.'))
                  ],
                  slider(
                      'Bildabstand',
                      settings.spacing,
                      0,
                      40,
                      (v) => controller
                          .updateCanvas(settings.copyWith(spacing: v))),
                  slider(
                      'Außenrand',
                      settings.outerMargin,
                      0,
                      60,
                      (v) => controller
                          .updateCanvas(settings.copyWith(outerMargin: v))),
                  slider(
                      'Eckenradius',
                      settings.cornerRadius,
                      0,
                      40,
                      (v) => controller
                          .updateCanvas(settings.copyWith(cornerRadius: v))),
                ]),
                page([
                  SwitchListTile(
                      title: Text(t('Bildrahmen')),
                      value: style.frameEnabled,
                      onChanged: (v) =>
                          change(style.copyWith(frameEnabled: v))),
                  if (style.frameEnabled) ...[
                    colors(style.frameColor,
                        (v) => change(style.copyWith(frameColor: v))),
                    slider('Rahmenstärke', style.frameWidth, 0, 20,
                        (v) => change(style.copyWith(frameWidth: v)))
                  ],
                  Text(t(
                      'Direkt aneinanderliegende Bilder erhalten einen gemeinsamen Außenrahmen.'))
                ]),
                page([
                  SwitchListTile(
                      title: Text(t('Schatten')),
                      value: style.shadowEnabled,
                      onChanged: (v) =>
                          change(style.copyWith(shadowEnabled: v))),
                  if (style.shadowEnabled) ...[
                    slider('Schattenstärke', style.shadowOpacity, 0, 1,
                        (v) => change(style.copyWith(shadowOpacity: v))),
                    slider('Weichheit', style.shadowSoftness, 0, 30,
                        (v) => change(style.copyWith(shadowSoftness: v)))
                  ]
                ]),
                page([
                  for (final preset in StylePreset.all)
                    Card(
                        child: ListTile(
                            leading: CircleAvatar(
                                backgroundColor:
                                    Color(preset.settings.backgroundColor),
                                child: Icon(Icons.palette_outlined,
                                    color:
                                        Color(preset.settings.backgroundColor)
                                                    .computeLuminance() >
                                                .5
                                            ? Colors.black
                                            : Colors.white)),
                            title: Text(preset.name),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => controller.updateCanvas(preset.settings
                                .copyWith(
                                    staggerAmount: settings.staggerAmount)))),
                  Text(t(
                      'Presets ändern nur den Stil. Fotos, Reihenfolge und Texte bleiben erhalten.'))
                ]),
              ]))
            ]));
      });
}
