import 'dart:io';

import 'package:flutter/material.dart';

import '../state/collage_editor_controller.dart';

class ThumbnailStrip extends StatelessWidget {
  const ThumbnailStrip({
    required this.controller,
    super.key,
  });

  final CollageEditorController controller;

  @override
  Widget build(BuildContext context) {
    final photos = controller.project.photos;
    return SizedBox(
      height: 86,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        buildDefaultDragHandles: false,
        itemCount: photos.length,
        onReorderItem: controller.reorderPhotos,
        itemBuilder: (context, index) {
          final photo = photos[index];
          final selected = photo.id == controller.selectedPhotoId;
          return ReorderableDragStartListener(
            key: ValueKey(photo.id),
            index: index,
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => controller.selectPhoto(photo.id),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Stack(
                      children: [
                        Image.file(
                          File(photo.localPath),
                          width: 68,
                          height: 68,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          left: 4,
                          top: 4,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
