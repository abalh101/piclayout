import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/app_config.dart';
import '../../../core/localization/app_localizations.dart';
import '../../collage_editor/models/photo_asset.dart';
import '../../collage_editor/rendering/preview_image_cache.dart';
import '../../collage_editor/state/collage_editor_controller.dart';
import '../../collage_editor/widgets/collage_canvas.dart';
import '../../photo_import/selection_review_page.dart';
import '../../templates/models/collage_template.dart';
import '../../templates/widgets/template_preview.dart';
import '../models/freeform_presets.dart';

Future<void> pickFreeformPhotos(
    BuildContext context, CollageEditorController controller,
    {bool replace = false}) async {
  if (controller.importingPhotos) return;
  final t = AppLocalizations.of(context).tr;
  try {
    final picker = ImagePicker();
    if (replace) {
      final photo = await picker.pickImage(
          source: ImageSource.gallery, requestFullMetadata: false);
      if (photo != null) await controller.fillFreeformFrame(photo);
    } else {
      final empty = controller.project.design.layers
          .where((l) =>
              l.isPhoto &&
              !l.locked &&
              l.source(controller.project.photos) == null)
          .length;
      final capacity = math.min(
          AppConfig.maxFreeformFrames - controller.project.photos.length,
          AppConfig.maxFreeformFrames - controller.freeformFrameCount + empty);
      if (capacity <= 0) throw StateError('ffLimit');
      // image_picker requires a multi-image limit of at least two.
      final files = capacity == 1
          ? [
              await picker.pickImage(
                  source: ImageSource.gallery, requestFullMetadata: false)
            ].whereType<XFile>().toList()
          : await picker.pickMultiImage(
              limit: capacity, requestFullMetadata: false);
      if (!context.mounted || files.isEmpty) return;
      if (files.length > capacity) throw StateError('ffLimit');
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => SelectionReviewPage(
                  files: files,
                  freeform: true,
                  onConfirm: controller.addFreeformPhotos)));
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t(error is StateError && error.message == 'ffLimit'
              ? 'ffLimit'
              : 'photoPickFailed'))));
    }
  }
}

Future<List<PhotoAsset>?> orderFreeformPhotos(
        BuildContext context, CollageEditorController controller) =>
    showDialog<List<PhotoAsset>>(
        context: context,
        builder: (_) => _PhotoOrderDialog(controller: controller));

class _PhotoOrderDialog extends StatefulWidget {
  const _PhotoOrderDialog({required this.controller});
  final CollageEditorController controller;
  @override
  State<_PhotoOrderDialog> createState() => _PhotoOrderDialogState();
}

class _PhotoOrderDialogState extends State<_PhotoOrderDialog> {
  late final photos = [...widget.controller.project.photos];
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).tr;
    return AlertDialog(
      title: Text(t('ffMapTitle')),
      content: SizedBox(
          width: 420,
          height: MediaQuery.sizeOf(context).height * .5,
          child: Column(children: [
            Text(t('ffMapHint')),
            Expanded(
                child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: photos.length,
              onReorderItem: (from, to) => setState(() {
                final p = photos.removeAt(from);
                photos.insert(to, p);
              }),
              itemBuilder: (context, index) => ListTile(
                  key: ValueKey(photos[index].id),
                  leading: FrameSourceThumbnail(
                      photo: photos[index],
                      cache: widget.controller.previewImages),
                  title: Text('${t('photo')} ${index + 1}'),
                  trailing: ReorderableDragStartListener(
                      index: index,
                      child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(Icons.drag_handle,
                              semanticLabel: t('ffReorder'))))),
            )),
          ])),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(t('cancel'))),
        FilledButton(
            onPressed: () => Navigator.pop(context, photos),
            child: Text(t('applyTemplate')))
      ],
    );
  }
}

Future<void> showFreeformPresets(
        BuildContext context, CollageEditorController controller) =>
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) {
          final t = AppLocalizations.of(context).tr;
          return SafeArea(
              child: SizedBox(
                  height: MediaQuery.sizeOf(context).height * .8,
                  child: ListView(padding: const EdgeInsets.all(16), children: [
                    Text(t('ffTitle'),
                        style: Theme.of(context).textTheme.titleLarge),
                    Text(t('ffGestureHint')),
                    for (final key in FreeformPresets.keys)
                      Card(
                          child: ListTile(
                        leading: TemplatePreview(
                            template: CollageTemplate(
                                id: key,
                                name: '',
                                photoCount: 0,
                                aspectRatioId: '9_16',
                                layoutTemplateId: 'grid_1x1_1',
                                canvas: controller.project.canvas,
                                design: FreeformPresets.create(key, const []))),
                        title: Text(t(key)),
                        onTap: () async {
                          final ordered =
                              await orderFreeformPhotos(context, controller);
                          if (ordered == null || !context.mounted) return;
                          controller.applyDesign(
                              FreeformPresets.create(key, ordered),
                              story: true);
                          Navigator.pop(context);
                        },
                      )),
                  ])));
        });

/// Shares the editor's bounded source decode; no additional file image cache.
class FrameSourceThumbnail extends StatefulWidget {
  const FrameSourceThumbnail({super.key, this.photo, required this.cache});
  final PhotoAsset? photo;
  final PreviewImageCache cache;
  @override
  State<FrameSourceThumbnail> createState() => _FrameSourceThumbnailState();
}

class _FrameSourceThumbnailState extends State<FrameSourceThumbnail> {
  PreviewImageLease? lease;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    lease = widget.photo == null
        ? null
        : widget.cache.acquire(widget.photo!.localPath);
  }

  @override
  void didUpdateWidget(covariant FrameSourceThumbnail old) {
    super.didUpdateWidget(old);
    if (old.photo?.localPath != widget.photo?.localPath ||
        old.cache != widget.cache) {
      lease?.release();
      _load();
    }
  }

  @override
  void dispose() {
    lease?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
      width: 40,
      height: 48,
      child: FutureBuilder<ui.Image?>(
          key: ObjectKey(lease),
          future: lease?.image,
          builder: (context, snapshot) => snapshot.data == null
              ? const Icon(Icons.photo_outlined)
              : RawImage(image: snapshot.data, fit: BoxFit.cover)));
}

Future<void> showFreeformCanvas(
    BuildContext context, CollageEditorController controller) async {
  try {
    await Navigator.push<void>(
        context,
        MaterialPageRoute(
            builder: (context) => AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) {
                    final t = AppLocalizations.of(context).tr;
                    return Scaffold(
                      appBar: AppBar(
                          title: Text(t(controller.editingDesignCrop
                              ? 'edEditCrop'
                              : 'ffTitle')),
                          actions: [
                            IconButton(
                                tooltip: t('undo'),
                                onPressed:
                                    controller.canUndo ? controller.undo : null,
                                icon: const Icon(Icons.undo)),
                            IconButton(
                                tooltip: t('redo'),
                                onPressed:
                                    controller.canRedo ? controller.redo : null,
                                icon: const Icon(Icons.redo))
                          ]),
                      body: SafeArea(
                          child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                  child:
                                      CollageCanvas(controller: controller)))),
                      bottomNavigationBar: SafeArea(
                          child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 8,
                                  children: [
                                    if (controller
                                                .selectedDesignLayer?.isPhoto ==
                                            true &&
                                        controller
                                                .selectedDesignLayer?.locked ==
                                            false)
                                      FilledButton.icon(
                                          icon: Icon(
                                              controller.editingDesignCrop
                                                  ? Icons.check
                                                  : Icons.crop),
                                          label: Text(t(
                                              controller.editingDesignCrop
                                                  ? 'edCropDone'
                                                  : 'edEditCrop')),
                                          onPressed: () => controller
                                              .setDesignCropEditing(!controller
                                                  .editingDesignCrop)),
                                    OutlinedButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(t('done'))),
                                  ]))),
                    );
                  },
                )));
  } finally {
    controller.endInteractiveTransform();
  }
}
