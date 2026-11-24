import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../models/photo_placement.dart';
import '../state/collage_editor_controller.dart';

Future<void> showLayersSheet(
        BuildContext context, CollageEditorController controller) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _LayersSheet(controller: controller),
    );

class _LayersSheet extends StatelessWidget {
  const _LayersSheet({required this.controller});
  final CollageEditorController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final t = strings.tr;
    final theme = Theme.of(context);
    Widget label(String name) => Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 4),
          child: Text(name, style: theme.textTheme.labelLarge),
        );

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .72,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final project = controller.project;
            return Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Expanded(
                      child:
                          Text(t('layers'), style: theme.textTheme.titleLarge)),
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(strings.done)),
                ]),
              ),
              Expanded(
                  child: ListView(
                padding: const EdgeInsets.only(bottom: 12),
                children: [
                  if (project.stickers.isNotEmpty) label(t('stickers')),
                  for (final (index, sticker)
                      in project.stickers.indexed.toList().reversed)
                    _LayerRow(
                      key: ValueKey(sticker.id),
                      title: sticker.content,
                      icon: Icons.emoji_emotions_outlined,
                      selected: controller.selectedStickerId == sticker.id,
                      select: () => controller.selectSticker(sticker.id),
                      hidden: sticker.hidden,
                      locked: sticker.locked,
                      visibility: () => controller.updateSticker(
                          sticker.copyWith(hidden: !sticker.hidden)),
                      lock: () => controller.updateSticker(
                          sticker.copyWith(locked: !sticker.locked)),
                      forward: index + 1 < project.stickers.length
                          ? () => controller.reorderStickers(index, index + 1)
                          : null,
                      backward: index > 0
                          ? () => controller.reorderStickers(index, index - 1)
                          : null,
                      duplicate: () {
                        controller.selectSticker(sticker.id);
                        controller.duplicateSticker();
                      },
                      delete: () {
                        controller.selectSticker(sticker.id);
                        controller.removeSticker();
                      },
                    ),
                  if (project.textOverlays.isNotEmpty)
                    label(strings.textOverlay),
                  for (final (index, text)
                      in project.textOverlays.indexed.toList().reversed)
                    _LayerRow(
                      key: ValueKey(text.id),
                      title: text.text,
                      icon: Icons.text_fields,
                      selected: controller.selectedTextId == text.id,
                      select: () => controller.selectText(text.id),
                      hidden: text.hidden,
                      locked: text.locked,
                      visibility: () => controller
                          .updateText(text.copyWith(hidden: !text.hidden)),
                      lock: () => controller
                          .updateText(text.copyWith(locked: !text.locked)),
                      forward: index + 1 < project.textOverlays.length
                          ? () => controller.reorderText(index, index + 1)
                          : null,
                      backward: index > 0
                          ? () => controller.reorderText(index, index - 1)
                          : null,
                      duplicate: () {
                        controller.selectText(text.id);
                        controller.duplicateSelectedText();
                      },
                      delete: () {
                        controller.selectText(text.id);
                        controller.removeSelectedText();
                      },
                    ),
                  label(t('Fotos')),
                  for (final (index, photo)
                      in project.photos.indexed.toList().reversed)
                    if ((photo.placement ?? const PhotoPlacement())
                        case final placement)
                      _LayerRow(
                        key: ValueKey(photo.id),
                        title: '${strings.photo} ${index + 1}',
                        icon: Icons.photo_outlined,
                        selected: controller.selectedPhotoId == photo.id,
                        select: () => controller.selectPhoto(photo.id),
                        hidden: project.freestyle && placement.hidden,
                        locked: project.freestyle && placement.locked,
                        visibility: project.freestyle
                            ? () => controller.updatePlacement(photo.id,
                                placement.copyWith(hidden: !placement.hidden))
                            : null,
                        lock: project.freestyle
                            ? () => controller.updatePlacement(photo.id,
                                placement.copyWith(locked: !placement.locked))
                            : null,
                        forward: project.freestyle &&
                                index + 1 < project.photos.length
                            ? () => controller.reorderPhotos(index, index + 1)
                            : null,
                        backward: project.freestyle && index > 0
                            ? () => controller.reorderPhotos(index, index - 1)
                            : null,
                        duplicate: project.freestyle && controller.canAddPhotos
                            ? () {
                                controller.selectPhoto(photo.id);
                                controller.duplicateSelectedPhoto();
                              }
                            : null,
                        delete: project.photos.length > 1
                            ? () {
                                controller.selectPhoto(photo.id);
                                controller.removeSelected();
                              }
                            : null,
                      ),
                ],
              )),
            ]);
          },
        ),
      ),
    );
  }
}

class _LayerRow extends StatelessWidget {
  const _LayerRow({
    super.key,
    required this.title,
    required this.icon,
    required this.select,
    required this.selected,
    this.hidden = false,
    this.locked = false,
    this.visibility,
    this.lock,
    this.forward,
    this.backward,
    this.duplicate,
    this.delete,
  });
  final String title;
  final IconData icon;
  final bool selected, hidden, locked;
  final VoidCallback select;
  final VoidCallback? visibility, lock, forward, backward, duplicate, delete;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).tr;
    final actions = <String, VoidCallback?>{
      hidden ? 'showLayer' : 'hideLayer': visibility,
      locked ? 'unlockLayer' : 'lockLayer': lock,
      'forwardLayer': locked ? null : forward,
      'backwardLayer': locked ? null : backward,
      'duplicate': duplicate,
      'delete': locked ? null : delete,
    }..removeWhere((_, callback) => callback == null);
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      selected: selected,
      selectedTileColor: scheme.secondaryContainer,
      onTap: select,
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      leading: Icon(hidden
          ? Icons.visibility_off_outlined
          : locked
              ? Icons.lock_outline
              : icon),
      subtitle: hidden || locked
          ? Text([if (hidden) t('layerHidden'), if (locked) t('layerLocked')]
              .join(' · '))
          : null,
      trailing: actions.isEmpty
          ? null
          : PopupMenuButton<String>(
              onSelected: (key) => actions[key]?.call(),
              itemBuilder: (context) => [
                for (final key in actions.keys)
                  PopupMenuItem(value: key, child: Text(t(key))),
              ],
            ),
    );
  }
}
