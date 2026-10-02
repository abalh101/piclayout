import '../../tutorial_tips/tutorial_tip.dart';
import '../../../core/localization/app_localizations.dart';
import '../services/gallery_save_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/models/app_settings.dart';
import '../../settings/state/settings_controller.dart';
import '../../collage_editor/models/canvas_style.dart';
import 'package:flutter/material.dart';
import '../../projects/models/collage_project.dart';
import '../export_settings.dart';
import '../models/social_share_preset.dart';
import '../services/export_flow_controller.dart';

Future<void> showExportCenter(BuildContext context, CollageProject project) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => Consumer(
          builder: (context, ref, _) => ref
              .watch(settingsControllerProvider)
              .when(
                  data: (settings) => ExportCenter(
                      project: project,
                      defaults: settings,
                      showTutorialTip: true),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) =>
                      ExportCenter(project: project, showTutorialTip: true))),
    );

class ExportCenter extends StatefulWidget {
  const ExportCenter(
      {required this.project,
      this.defaults = const AppSettings(),
      this.showTutorialTip = false,
      super.key});
  final CollageProject project;
  final AppSettings defaults;
  final bool showTutorialTip;
  @override
  State<ExportCenter> createState() => _ExportCenterState();
}

class _ExportCenterState extends State<ExportCenter> {
  final _flow = ExportFlowController();
  late SocialShareDestination _destination =
      widget.defaults.exportAction == ExportAction.gallery
          ? SocialShareDestination.gallery
          : SocialShareDestination.general;
  late ExportFormat _format = widget.defaults.exportFormat;
  String? _message;
  late final List<SocialSharePreset> _originals = [
    for (final size in widget.project.aspectRatio.exportSizes())
      SocialSharePreset('original_${size.width}', 'Aktuell · ${size.label}',
          size.width, size.height),
  ];
  SocialSharePreset get _original => _originals.first;
  late SocialSharePreset _preset = _original;

  @override
  void dispose() {
    _flow.dispose();
    super.dispose();
  }

  IconData _icon(SocialShareDestination target) => switch (target) {
        SocialShareDestination.gallery => Icons.photo_library_outlined,
        SocialShareDestination.instagramStory ||
        SocialShareDestination.snapchat =>
          Icons.stay_current_portrait,
        SocialShareDestination.instagramPost => Icons.grid_on,
        SocialShareDestination.tiktok => Icons.music_note_outlined,
        SocialShareDestination.whatsapp => Icons.chat_bubble_outline,
        SocialShareDestination.facebook => Icons.people_outline,
        _ => Icons.share_outlined,
      };

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _flow,
        builder: (context, _) {
          final t = AppLocalizations.of(context).tr;
          final scheme = Theme.of(context).colorScheme;
          final presets = [
            if (_destination.app == null) ..._originals,
            ...SocialSharePreset.forDestination(_destination),
          ];
          return PopScope(
            canPop: !_flow.busy,
            child: SafeArea(
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.88,
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
                    child: Row(children: [
                      const Icon(Icons.ios_share),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(AppLocalizations.of(context).export,
                              style: Theme.of(context).textTheme.titleLarge)),
                      IconButton(
                          tooltip: t('Schließen'),
                          onPressed:
                              _flow.busy ? null : () => Navigator.pop(context),
                          icon: const Icon(Icons.close)),
                    ]),
                  ),
                  Expanded(
                      child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.showTutorialTip)
                            const TutorialTip(id: 'tipExport'),
                          Text(t('Wohin soll deine Collage?'),
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            for (final target in SocialShareDestination.values)
                              ChoiceChip(
                                avatar: Icon(_icon(target), size: 18),
                                label: Text(t(target.label)),
                                selected: _destination == target,
                                onSelected: _flow.busy
                                    ? null
                                    : (_) => setState(() {
                                          _destination = target;
                                          _preset = target.app == null
                                              ? _original
                                              : SocialSharePreset
                                                      .forDestination(target)
                                                  .first;
                                        }),
                              ),
                          ]),
                          const SizedBox(height: 20),
                          Text(t('Bildgröße'),
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            for (final preset in presets)
                              ChoiceChip(
                                  label: Text(t(preset.label)),
                                  selected: _preset.id == preset.id,
                                  onSelected: _flow.busy
                                      ? null
                                      : (_) =>
                                          setState(() => _preset = preset)),
                          ]),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: scheme.primaryContainer,
                                borderRadius: BorderRadius.circular(16)),
                            child: Text(
                                '${_preset.width} × ${_preset.height} Pixel',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                        color: scheme.onPrimaryContainer)),
                          ),
                          if (_preset.differsStrongly(
                              widget.project.aspectRatio.value))
                            Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(t(
                                    'Das Exportformat weicht deutlich ab. Bildausschnitte und Textpositionen werden für den Export neu eingepasst. Dein Projekt bleibt erhalten.'))),
                          const SizedBox(height: 20),
                          SegmentedButton<ExportFormat>(
                            segments: const [
                              ButtonSegment(
                                  value: ExportFormat.png, label: Text('PNG')),
                              ButtonSegment(
                                  value: ExportFormat.jpeg, label: Text('JPEG'))
                            ],
                            selected: {_format},
                            onSelectionChanged: _flow.busy
                                ? null
                                : (value) =>
                                    setState(() => _format = value.first),
                          ),
                          if (widget.project.canvas.style.backgroundType ==
                              BackgroundType.transparent)
                            Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(_format == ExportFormat.png
                                    ? t('PNG exportiert den Hintergrund transparent.')
                                    : t('JPEG ersetzt den transparenten Hintergrund durch Weiß.'))),
                          const SizedBox(height: 16),
                          Text(
                              t('Social-Media-Ziele öffnen die Ziel-App oder das Teilen-Menü. Wähle dort Story, Post oder Status und bestätige den Upload selbst.'),
                              style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 16),
                        ]),
                  )),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      if (_message != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(_message!,
                              maxLines: 4, overflow: TextOverflow.ellipsis),
                        ),
                      SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _flow.busy ? null : _export,
                            icon: _flow.busy
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : Icon(_icon(_destination)),
                            label: Text(_flow.busy
                                ? t('Bild wird vorbereitet …')
                                : _destination == SocialShareDestination.gallery
                                    ? t('In Galerie speichern')
                                    : t('Bild vorbereiten & teilen')),
                          )),
                    ]),
                  ),
                ]),
              ),
            ),
          );
        },
      );

  Future<void> _export() async {
    final box = context.findRenderObject()! as RenderBox;
    final origin = box.localToGlobal(Offset.zero) & box.size;
    final messenger = ScaffoldMessenger.of(context);
    void notice(String message) {
      message = AppLocalizations.of(context).tr(message);
      if (mounted) setState(() => _message = message);
    }

    try {
      final result = await _flow.run(
          project: widget.project,
          settings: ExportSettings(
              width: _preset.width,
              height: _preset.height,
              format: _format,
              jpegQuality: widget.defaults.jpegQuality),
          destination: _destination,
          origin: origin,
          onNotice: notice);
      if (mounted &&
          result != null &&
          _destination == SocialShareDestination.gallery) {
        Navigator.pop(context);
        messenger.showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).tr(result))));
      }
    } catch (error) {
      if (mounted) {
        notice(error is ExportFailure ? error.message : 'operationFailed');
      }
    }
  }
}
