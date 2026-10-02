import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../app/app_config.dart';
import '../../core/localization/app_localizations.dart';
import '../collage_editor/editor_page.dart';
import '../collage_editor/models/aspect_ratio_preset.dart';
import '../collage_editor/models/photo_asset.dart';
import '../collage_editor/models/photo_metadata.dart';
import '../layout_recommendations/layout_recommendation_service.dart';
import '../layout_recommendations/photo_metadata_reader.dart';
import '../layout_recommendations/recommended_layouts.dart';
import '../projects/state/project_providers.dart';
import '../settings/state/settings_controller.dart';

class SelectionReviewPage extends ConsumerStatefulWidget {
  const SelectionReviewPage({required this.files, super.key});
  final List<XFile> files;
  @override
  ConsumerState<SelectionReviewPage> createState() =>
      _SelectionReviewPageState();
}

class _SelectionReviewPageState extends ConsumerState<SelectionReviewPage> {
  late final List<XFile> _files =
      widget.files.take(AppConfig.maxPhotos).toList();
  final _metadata = <String, PhotoMetadata?>{};
  bool _creating = false, _loading = true, _formatChosen = false;
  String _ratioId = '9_16';
  String? _selectedLayout;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await ref.read(settingsControllerProvider.future);
      if (!mounted) return;
      if (!_formatChosen) setState(() => _ratioId = settings.aspectRatioId);
    } catch (_) {
      // The visible Story default remains usable if preferences are unavailable.
    }
    if (!mounted) return;
    final reader = ref.read(photoMetadataReaderProvider);
    for (final file in List<XFile>.of(_files)) {
      final metadata = await reader.read(file.path);
      if (!mounted) return;
      _metadata[file.path] = metadata;
    }
    if (mounted) setState(() => _loading = false);
  }

  List<LayoutRecommendation> get _recommendations =>
      const LayoutRecommendationService().recommend([
        for (var i = 0; i < _files.length; i++)
          PhotoAsset(
              id: '$i',
              originalFileName: '',
              localPath: '',
              metadata: _metadata[_files[i].path]),
      ], targetRatio: AspectRatios.byId(_ratioId).value);

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final recommendations = _recommendations;
    final selected = _selectedLayout ?? recommendations.firstOrNull?.layout.id;
    return PopScope(
        canPop: !_creating,
        child: Scaffold(
          appBar: AppBar(title: Text(strings.selectedPhotos)),
          body: SafeArea(
              child: Column(children: [
            Expanded(
                child: ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              header: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.format,
                        style: Theme.of(context).textTheme.titleMedium),
                    Wrap(spacing: 8, children: [
                      for (final ratio in AspectRatios.all)
                        ChoiceChip(
                          label: Text(ratio.label),
                          selected: _ratioId == ratio.id,
                          onSelected: _creating
                              ? null
                              : (_) => setState(() {
                                    _ratioId = ratio.id;
                                    _formatChosen = true;
                                    _selectedLayout = null;
                                  }),
                        )
                    ]),
                    const SizedBox(height: 12),
                    RecommendedLayouts(
                        recommendations: recommendations,
                        targetRatio: AspectRatios.byId(_ratioId).value,
                        selectedId: selected,
                        loading: _loading || _creating,
                        onSelected: (id) =>
                            setState(() => _selectedLayout = id)),
                  ]),
              itemCount: _files.length,
              onReorderItem: (oldIndex, newIndex) {
                if (_creating) return;
                setState(() {
                  final file = _files.removeAt(oldIndex);
                  _files.insert(newIndex, file);
                });
              },
              itemBuilder: (context, index) {
                final file = _files[index];
                return Card(
                    key: ObjectKey(file),
                    child: ListTile(
                      leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(File(file.path),
                              width: 54,
                              height: 54,
                              fit: BoxFit.cover,
                              errorBuilder: (_, error, stack) =>
                                  const Icon(Icons.broken_image_outlined))),
                      title: Text('${strings.tr('Bild')} ${index + 1}'),
                      subtitle: Text(file.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                          tooltip: strings.remove,
                          icon: const Icon(Icons.close),
                          onPressed: _creating || _files.length <= 1
                              ? null
                              : () => setState(() {
                                    _files.removeAt(index);
                                    _selectedLayout = null;
                                  })),
                    ));
              },
            )),
            Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  key: const ValueKey('create-collage'),
                  onPressed: _creating || _loading || _files.isEmpty
                      ? null
                      : _createProject,
                  icon: _creating
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome_mosaic),
                  label: Text(strings.createCollage),
                )),
          ])),
        ));
  }

  Future<void> _createProject() async {
    setState(() => _creating = true);
    final navigator = Navigator.of(context);
    final repository = ref.read(projectRepositoryProvider);
    final projects = ref.read(projectsProvider.notifier);
    try {
      var project = await repository.createFromPickedImages(List.of(_files),
          aspectRatioId: _ratioId);
      if (_selectedLayout != null) {
        project = project
            .copyWith(layoutTemplateId: _selectedLayout)
            .normalizedForPhotoCount();
        await repository.save(project);
      }
      await projects.add(project);
      if (!mounted) return;
      navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => EditorPage(project: project)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context).tr('operationFailed'))));
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }
}
