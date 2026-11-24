part of 'collage_editor_controller.dart';

extension FreeformEditing on CollageEditorController {
  int get freeformFrameCount =>
      project.design.layers.where((l) => l.isPhoto).length;

  void deselectFrame() {
    endInteractiveTransform();
    selectedDesignLayerId = null;
    selectedPhotoId = null;
    editingDesignCrop = false;
    _notifyFreeform();
  }

  void setFrameCrop(PhotoTransform transform, {bool live = false}) {
    final frame = selectedDesignLayer;
    if (!project.isFreeform ||
        frame == null ||
        !frame.isPhoto ||
        frame.locked) {
      return;
    }
    final photo = frame.source(project.photos);
    final metadata = photo?.metadata;
    final size = Size(390, 390 / project.aspectRatio.value);
    final clamped = PhotoCrop.clamp(
        transform,
        metadata == null
            ? Size.zero
            : Size(metadata.width.toDouble(), metadata.height.toDouble()),
        frame.rect(size).size);
    updateDesignLayer(frame.copyWith(imageTransform: clamped), live: live);
  }

  CollageProject adjustmentPreview(PhotoAdjustments value) {
    final frame = selectedDesignLayer;
    if (project.isFreeform && frame != null) {
      return project.copyWith(
          design: project.design.copyWith(layers: [
        for (final l in project.design.layers)
          l.id == frame.id ? l.copyWith(adjustments: value) : l
      ]));
    }
    return project.copyWith(photos: [
      for (final p in project.photos)
        p.id == selectedPhotoId ? p.copyWith(adjustments: value) : p
    ]);
  }

  void moveLayerTo(int destination) {
    final frame = selectedDesignLayer;
    if (frame == null || frame.locked) return;
    final layers = project.design.ordered;
    layers.removeWhere((l) => l.id == frame.id);
    layers.insert(destination.clamp(0, layers.length), frame);
    _mutate(project.copyWith(
        design: project.design.copyWith(layers: [
      for (var i = 0; i < layers.length; i++) layers[i].copyWith(z: i)
    ])));
  }

  void resetFrame({bool fitCanvas = false, bool centerOnly = false}) {
    final frame = selectedDesignLayer;
    if (frame == null || frame.locked) return;
    updateDesignLayer(frame.copyWith(
        x: .5,
        y: .5,
        width: centerOnly
            ? null
            : fitCanvas
                ? 1
                : .5,
        height: centerOnly
            ? null
            : fitCanvas
                ? 1
                : .25,
        rotation: centerOnly ? null : 0));
  }

  void addEmptyFrame() {
    if (!project.isFreeform ||
        freeformFrameCount >= AppConfig.maxFreeformFrames) {
      return;
    }
    // New empty frames are staggered rather than silently covering one another.
    final rect = FreeformPresets.gallery(
        AppConfig.maxFreeformFrames)[freeformFrameCount];
    addDesignLayer(FreeformPresets.frame(rect, freeformFrameCount, null));
  }

  void bindFramePhoto(String photoId) {
    final frame = selectedDesignLayer;
    if (frame == null ||
        frame.locked ||
        !project.photos.any((p) => p.id == photoId)) {
      return;
    }
    updateDesignLayer(frame.copyWith(
        photoId: photoId,
        empty: false,
        imageTransform: PhotoTransform.identity));
    selectedPhotoId = photoId;
  }

  void clearFramePhoto() {
    final frame = selectedDesignLayer;
    if (frame == null || frame.locked) return;
    final layers = [
      for (final l in project.design.layers)
        l.id == frame.id
            ? l.copyWith(
                clearPhotoId: true,
                empty: true,
                imageTransform: PhotoTransform.identity)
            : l
    ];
    _mutate(project.copyWith(
        design: project.design.copyWith(layers: layers),
        photos: project.photos
            .where((p) =>
                p.id != frame.photoId || layers.any((l) => l.photoId == p.id))
            .toList()));
    selectedPhotoId = null;
  }

  /// Swap only image content and edits; frame geometry and decoration stay put.
  /// Swapping with an empty placeholder also implements moving a photo.
  void swapFramePhotos(String otherId) {
    final a = selectedDesignLayer;
    final b = project.design.layers.where((l) => l.id == otherId).firstOrNull;
    if (!project.isFreeform ||
        a == null ||
        b == null ||
        a.id == b.id ||
        a.locked ||
        b.locked ||
        !a.isPhoto ||
        !b.isPhoto) {
      return;
    }
    DesignLayer content(DesignLayer target, DesignLayer from) =>
        target.copyWith(
          photoId: from.source(project.photos)?.id,
          clearPhotoId: from.source(project.photos) == null,
          empty: from.source(project.photos) == null,
          imageTransform: from.transformFor(from.source(project.photos)),
          adjustments: from.adjustmentsFor(from.source(project.photos)),
        );
    _mutate(project.copyWith(
        design: project.design.copyWith(layers: [
      for (final l in project.design.layers)
        l.id == a.id
            ? content(a, b)
            : l.id == b.id
                ? content(b, a)
                : l
    ])));
  }

  Future<void> fillFreeformFrame(XFile file) async {
    final frame = selectedDesignLayer;
    if (!project.isFreeform ||
        _disposed ||
        frame == null ||
        !frame.isPhoto ||
        frame.locked ||
        importingPhotos) {
      return;
    }
    importingPhotos = true;
    _notifyFreeform();
    final sourceId = frame.source(project.photos)?.id;
    PhotoAsset? imported;
    var committed = false;
    try {
      final replacement = await _repository.importReplacement(file, project.id);
      imported = replacement;
      if (_disposed || !project.isFreeform) return;
      final current =
          project.design.layers.where((l) => l.id == frame.id).firstOrNull;
      if (current == null ||
          !current.isPhoto ||
          current.locked ||
          current.empty != frame.empty ||
          current.source(project.photos)?.id != sourceId) {
        return;
      }
      final layers = [
        for (final l in project.design.layers)
          l.id == frame.id
              ? l.copyWith(
                  photoId: replacement.id,
                  empty: false,
                  imageTransform: PhotoTransform.identity)
              : l
      ];
      final photos = project.photos
          .where((p) =>
              p.id != current.photoId || layers.any((l) => l.photoId == p.id))
          .toList();
      if (photos.length >= AppConfig.maxFreeformFrames) {
        throw StateError('ffLimit');
      }
      _mutate(project.copyWith(
          photos: [...photos, replacement],
          design: project.design.copyWith(layers: layers)));
      committed = true;
    } finally {
      try {
        if (!committed && imported != null) {
          await _repository.discardImportedPhotos(project.id, [imported]);
        }
      } finally {
        importingPhotos = false;
        if (!_disposed) _notifyFreeform();
      }
    }
  }

  Future<void> addFreeformPhotos(List<XFile> files) async {
    if (_disposed || !project.isFreeform || files.isEmpty || importingPhotos) {
      return;
    }
    final empty = project.design.ordered
        .where(
            (l) => l.isPhoto && !l.locked && l.source(project.photos) == null)
        .length;
    if (project.photos.length + files.length > AppConfig.maxFreeformFrames ||
        freeformFrameCount + files.length - empty >
            AppConfig.maxFreeformFrames) {
      throw StateError('ffLimit');
    }
    importingPhotos = true;
    _notifyFreeform();
    final imported = <PhotoAsset>[];
    var committed = false;
    try {
      for (final file in files) {
        imported.add(await _repository.importReplacement(file, project.id));
        if (_disposed || !project.isFreeform) return;
      }
      if (_disposed || !project.isFreeform) return;
      final layers = [...project.design.ordered];
      final blank = layers.where((l) => l.isPhoto).isEmpty;
      final rects = FreeformPresets.gallery(imported.length);
      for (var i = 0; i < imported.length; i++) {
        final photo = imported[i];
        final slot = layers.indexWhere((l) =>
            l.isPhoto &&
            !l.locked &&
            l.source([...project.photos, ...imported]) == null);
        if (slot >= 0) {
          layers[slot] = layers[slot].copyWith(
              photoId: photo.id,
              empty: false,
              imageTransform: PhotoTransform.identity);
        } else {
          final count = layers.where((l) => l.isPhoto).length;
          if (count >= AppConfig.maxFreeformFrames) throw StateError('ffLimit');
          layers.add(FreeformPresets.frame(
                  blank ? rects[i] : FreeformPresets.gallery(20)[count],
                  count,
                  photo)
              .copyWith(z: (layers.lastOrNull?.z ?? -1) + 1));
        }
      }
      _mutate(project.copyWith(
          photos: [...project.photos, ...imported],
          design: project.design.copyWith(layers: layers)));
      committed = true;
    } finally {
      try {
        if (!committed && imported.isNotEmpty) {
          await _repository.discardImportedPhotos(project.id, imported);
        }
      } finally {
        importingPhotos = false;
        if (!_disposed) _notifyFreeform();
      }
    }
  }
}
