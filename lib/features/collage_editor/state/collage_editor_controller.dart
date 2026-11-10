import '../../layout_recommendations/layout_recommendation_service.dart';
import '../../editorial/models/editorial_design.dart';
import '../../editorial/models/design_presets.dart';
import '../../layout_recommendations/photo_metadata_reader.dart';
import '../models/photo_metadata.dart';
import '../../stickers/sticker_overlay.dart';
import '../../custom_layouts/models/custom_layout.dart';
import '../../custom_layouts/services/layout_builder_seed.dart';
import '../models/photo_adjustments.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../projects/models/collage_project.dart';
import '../../projects/state/project_providers.dart';
import '../../projects/services/project_repository.dart';
import '../../templates/models/collage_template.dart';
import '../layouts/layout_library.dart';
import '../models/aspect_ratio_preset.dart';
import '../models/canvas_settings.dart';
import '../models/photo_asset.dart';
import '../models/photo_transform.dart';
import '../models/text_overlay.dart';
import '../rendering/text_overlay_renderer.dart';
import '../rendering/photo_crop.dart';
import '../rendering/layout_geometry.dart';

final editorControllerProvider = ChangeNotifierProvider.autoDispose
    .family<CollageEditorController, CollageProject>((ref, project) {
  final controller = CollageEditorController(
    initialProject: project,
    repository: ref.read(projectRepositoryProvider),
  );
  unawaited(controller.loadPhotoMetadata(
      reader: ref.read(photoMetadataReaderProvider)));
  return controller;
});

class CollageEditorController extends ChangeNotifier {
  CollageEditorController({
    required CollageProject initialProject,
    required ProjectRepository repository,
    Random? random,
  })  : _project = initialProject.normalizedForPhotoCount(),
        _repository = repository,
        _random = random ?? Random() {
    selectedPhotoId =
        _project.photos.isNotEmpty ? _project.photos.first.id : null;
  }

  final ProjectRepository _repository;
  final Random _random;
  final List<CollageProject> _undo = [];
  final List<CollageProject> _redo = [];
  bool _disposed = false;
  bool metadataLoading = false;
  bool saveFailed = false;
  bool _replacing = false;
  CollageProject? _interactiveStart;
  int _saveRequest = 0;
  Timer? _autosave;
  Offset? _textDragGlobalPosition;
  CollageProject? _dividerStart;
  CustomLayout? _dividerLayout;
  LayoutDivider? _dragDivider;
  bool _editingDividers = false;

  CollageProject _project;
  String? selectedPhotoId;
  String? selectedTextId;
  String? selectedStickerId;
  String? selectedDesignLayerId;
  bool editingDesignCrop = false;

  DesignLayer? get selectedDesignLayer => _project.design.layers
      .where((l) => l.id == selectedDesignLayerId)
      .firstOrNull;

  void selectDesignLayer(String id) {
    if (!_project.design.active ||
        !_project.design.layers.any((layer) => layer.id == id)) {
      return;
    }
    selectedDesignLayerId = id;
    selectedPhotoId = selectedDesignLayer?.isPhoto == true
        ? selectedDesignLayer?.source(_project.photos)?.id
        : null;
    selectedTextId = null;
    selectedStickerId = null;
    editingDesignCrop = false;
    notifyListeners();
  }

  void setDesignCropEditing(bool value) {
    editingDesignCrop = value &&
        _project.design.active &&
        selectedDesignLayer?.isPhoto == true &&
        selectedDesignLayer?.type != DesignLayerType.callout &&
        selectedDesignLayer?.locked == false;
    notifyListeners();
  }

  void applyDesign(EditorialDesign design, {bool story = false}) {
    selectedDesignLayerId = null;
    editingDesignCrop = false;
    _mutate(_project.copyWith(
        design: design, aspectRatioId: story ? AspectRatios.story.id : null));
  }

  void updateDesignSettings(EditorialDesign design, {bool live = false}) {
    final previous = _project.design;
    final geometryChanged = previous.columns != design.columns ||
        previous.margin != design.margin ||
        previous.gapX != design.gapX ||
        previous.gapY != design.gapY ||
        previous.header != design.header ||
        previous.variant != design.variant ||
        previous.mode != design.mode;
    final next = _project.copyWith(
        design: design.active && geometryChanged
            ? DesignPreset.reflow(design)
            : design);
    if (live) {
      _project = next;
      notifyListeners();
    } else {
      _mutate(next);
    }
  }

  void updateDesignLayer(DesignLayer layer, {bool live = false}) {
    final old =
        _project.design.layers.where((l) => l.id == layer.id).firstOrNull;
    if (old == null || (old.locked && layer.locked)) return;
    final next = _project.copyWith(
        design: _project.design.copyWith(
            numberStyle: layer.type == DesignLayerType.caption &&
                    layer.text.text != old.text.text
                ? NumberStyle.custom
                : _project.design.numberStyle,
            layers: [
          for (final l in _project.design.layers)
            if (l.id == layer.id) layer else l
        ]));
    if (live) {
      _project = next;
      notifyListeners();
    } else {
      _mutate(next);
    }
  }

  void addDesignLayer(DesignLayer layer) {
    if (_project.design.layers.length >= 200) return;
    if (!layer.referencesPhoto) layer = layer.copyWith(clearPhotoId: true);
    var design = _project.design;
    if (!design.active && design.layers.isEmpty) {
      final size = Size(390, 390 / _project.aspectRatio.value);
      design = design.copyWith(layers: [
        for (final cell in LayoutGeometry.resolve(_project, size))
          DesignLayer(
              id: const Uuid().v4(),
              type: DesignLayerType.photo,
              photoId: _project.photos[cell.photoIndex].id,
              photoSlot: cell.photoIndex,
              x: cell.rect.center.dx / size.width,
              y: cell.rect.center.dy / size.height,
              width: cell.rect.width / size.width,
              height: cell.rect.height / size.height,
              radius: cell.cornerRadius / (size.shortestSide / 390),
              z: cell.photoIndex),
      ]);
    }
    _mutate(_project.copyWith(
        design: design.copyWith(
            mode: design.active ? design.mode : DesignMode.blank,
            layers: [
          ...design.layers,
          layer.copyWith(z: (design.ordered.lastOrNull?.z ?? 0) + 1)
        ])));
    selectDesignLayer(layer.id);
  }

  void duplicateDesignLayer() {
    final layer = selectedDesignLayer;
    if (layer == null || layer.locked) return;
    addDesignLayer(layer.copyWith(
        id: const Uuid().v4(),
        x: layer.x + .03,
        y: layer.y + .03,
        layoutSlot: -1));
  }

  void deleteDesignLayer() {
    final layer = selectedDesignLayer;
    if (layer == null || layer.locked) return;
    selectedDesignLayerId = null;
    _mutate(_project.copyWith(
        design: _project.design.copyWith(layers: [
      for (final l in _project.design.layers)
        if (l.id != layer.id) l
    ])));
  }

  void reorderDesignLayer({required bool forward}) {
    final layer = selectedDesignLayer;
    if (layer == null || layer.locked) return;
    final layers = _project.design.ordered;
    final i = layers.indexWhere((l) => l.id == layer.id);
    final target = i + (forward ? 1 : -1);
    if (target < 0 || target >= layers.length) return;
    layers.removeAt(i);
    layers.insert(target, layer);
    _mutate(_project.copyWith(
        design: _project.design.copyWith(layers: [
      for (var j = 0; j < layers.length; j++) layers[j].copyWith(z: j)
    ])));
  }

  CollageProject get project => _project;
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  // Only expose the exact current geometry; never substitute a different seed.
  CustomLayout? get editableCanvasLayout =>
      _project.customLayout ??
      (_project.photos.isEmpty
          ? null
          : LayoutBuilderSeed.fromTemplate(
              LayoutLibrary.byIdOrDefault(
                  _project.layoutTemplateId, _project.photos.length),
              _project.canvas.staggerAmount));
  bool get canEditDividers =>
      !_project.design.active &&
      (editableCanvasLayout?.dividers.isNotEmpty ?? false);
  bool get editingDividers => _editingDividers && canEditDividers;

  void toggleDividerEditing() {
    endDividerDrag();
    _editingDividers = !_editingDividers && canEditDividers;
    notifyListeners();
  }

  void beginDividerDrag(LayoutDivider divider) {
    endDividerDrag();
    final layout = editableCanvasLayout;
    if (layout == null) return;
    final matching = layout.dividers.where((item) => item.id == divider.id);
    if (matching.isEmpty) return;
    _autosave?.cancel();
    _dividerStart = _project;
    _dividerLayout = layout;
    _dragDivider = matching.first;
  }

  void updateDividerDrag(double position) {
    if (!position.isFinite) return;
    final start = _dividerStart;
    final layout = _dividerLayout;
    final divider = _dragDivider;
    if (start == null || layout == null || divider == null) return;
    final moved = layout.moveDivider(divider, position);
    if (identical(moved, layout)) {
      _project = _project.copyWith(
          customLayout: start.customLayout,
          clearCustomLayout: start.customLayout == null);
    } else {
      _project = _project.copyWith(customLayout: moved);
    }
    notifyListeners();
  }

  /// A whole gesture is one history entry, including many live updates.
  void endDividerDrag() {
    final start = _dividerStart;
    if (start == null) return;
    final changed = _project.customLayout != start.customLayout;
    _dividerStart = null;
    _dividerLayout = null;
    _dragDivider = null;
    if (changed) {
      _undo.add(start);
      if (_undo.length > 80) _undo.removeAt(0);
      _redo.clear();
    }
    _scheduleAutosave();
    notifyListeners();
  }

  bool get canVaryLayout =>
      _project.customLayout != null ||
      LayoutLibrary.templatesFor(_project.photos.length)
          .any((layout) => layout.id != _project.layoutTemplateId);

  PhotoAsset? get selectedPhoto {
    final id = selectedPhotoId;
    if (id == null) {
      return null;
    }
    return _project.photos.where((photo) => photo.id == id).firstOrNull;
  }

  TextOverlay? get selectedText {
    final id = selectedTextId;
    if (id == null) return null;
    return _project.textOverlays.where((item) => item.id == id).firstOrNull;
  }

  void selectPhoto(String photoId) {
    selectedDesignLayerId = null;
    editingDesignCrop = false;
    selectedStickerId = null;
    selectedPhotoId = photoId;
    selectedTextId = null;
    notifyListeners();
  }

  void selectText(String textId) {
    selectedDesignLayerId = null;
    editingDesignCrop = false;
    selectedStickerId = null;
    selectedTextId = textId;
    selectedPhotoId = null;
    notifyListeners();
  }

  TextOverlay addText(String text) {
    final overlay = TextOverlay(id: const Uuid().v4(), text: text);
    selectedDesignLayerId = null;
    editingDesignCrop = false;
    selectedStickerId = null;
    selectedTextId = overlay.id;
    selectedPhotoId = null;
    _mutate(
        _project.copyWith(textOverlays: [..._project.textOverlays, overlay]));
    return overlay;
  }

  void updateText(TextOverlay overlay) {
    _mutate(_replaceText(overlay));
  }

  void updateTextLive(TextOverlay overlay) {
    _project = _replaceText(overlay);
    notifyListeners();
  }

  void beginTextDrag(String id, Offset globalPosition) {
    selectText(id);
    _textDragGlobalPosition = globalPosition;
    beginInteractiveTransform();
  }

  void updateTextDrag(Offset globalPosition, Size canvasSize) {
    final previous = _textDragGlobalPosition;
    final text = selectedText;
    if (previous == null || text == null) return;
    _textDragGlobalPosition = globalPosition;
    updateTextLive(
      TextOverlayRenderer.moveBy(text, canvasSize, globalPosition - previous),
    );
  }

  void endTextDrag() {
    _textDragGlobalPosition = null;
    endInteractiveTransform();
  }

  void removeSelectedText() {
    final text = selectedText;
    if (text == null) return;
    selectedTextId = null;
    _mutate(_project.copyWith(
      textOverlays:
          _project.textOverlays.where((item) => item.id != text.id).toList(),
    ));
  }

  StickerOverlay? get selectedSticker =>
      _project.stickers.where((s) => s.id == selectedStickerId).firstOrNull;

  void selectSticker(String id) {
    selectedDesignLayerId = null;
    editingDesignCrop = false;
    selectedStickerId = id;
    selectedPhotoId = null;
    selectedTextId = null;
    notifyListeners();
  }

  StickerOverlay addSticker(StickerDefinition definition, {String? label}) {
    final sticker = definition.create(const Uuid().v4(), label: label);
    selectSticker(sticker.id);
    _mutate(_project.copyWith(stickers: [..._project.stickers, sticker]));
    return sticker;
  }

  void updateSticker(StickerOverlay sticker, {bool live = false}) {
    if (!_project.stickers.any((s) => s.id == sticker.id)) return;
    final next = _project.copyWith(stickers: [
      for (final s in _project.stickers)
        if (s.id == sticker.id) sticker else s,
    ]);
    if (live) {
      _project = next;
      notifyListeners();
    } else {
      _mutate(next);
    }
  }

  void removeSticker() {
    final sticker = selectedSticker;
    if (sticker == null) return;
    selectedStickerId = null;
    _mutate(_project.copyWith(stickers: [
      for (final s in _project.stickers)
        if (s.id != sticker.id) s,
    ]));
  }

  void duplicateSticker() {
    final sticker = selectedSticker;
    if (sticker == null) return;
    final copy = sticker.copyWith(
        id: const Uuid().v4(), x: sticker.x + .04, y: sticker.y + .04);
    selectedStickerId = copy.id;
    _mutate(_project.copyWith(stickers: [..._project.stickers, copy]));
  }

  void reorderSticker({required bool front}) {
    final sticker = selectedSticker;
    if (sticker == null) return;
    final rest = _project.stickers.where((s) => s.id != sticker.id).toList();
    if ((front ? _project.stickers.last : _project.stickers.first).id ==
        sticker.id) {
      return;
    }
    _mutate(_project.copyWith(
        stickers: front ? [...rest, sticker] : [sticker, ...rest]));
  }

  void _validateStickerSelection() {
    if (selectedSticker == null) selectedStickerId = null;
    if (selectedStickerId != null) {
      selectedPhotoId = null;
      selectedTextId = null;
    }
  }

  void _validateDesignSelection() {
    final layer = selectedDesignLayer;
    if (!_project.design.active || layer == null) {
      selectedDesignLayerId = null;
      editingDesignCrop = false;
      return;
    }
    selectedTextId = null;
    selectedStickerId = null;
    selectedPhotoId = layer.isPhoto ? layer.source(_project.photos)?.id : null;
    if (layer.locked ||
        !layer.isPhoto ||
        layer.type == DesignLayerType.callout) {
      editingDesignCrop = false;
    }
  }

  void setAspectRatio(AspectRatioPreset preset) {
    if (_project.aspectRatioId == preset.id) return;
    _mutate(_project.copyWith(aspectRatioId: preset.id));
  }

  bool applyCustomLayout(CustomLayout layout) {
    if (layout.photoCount != _project.photos.length) return false;
    if (!_project.design.active && identical(_project.customLayout, layout)) {
      return true;
    }
    _mutate(_project.copyWith(
        customLayout: layout,
        design: _project.design.copyWith(mode: DesignMode.standard)));
    return true;
  }

  void setLayoutTemplate(String layoutTemplateId) {
    final template = LayoutLibrary.byIdOrDefault(
      layoutTemplateId,
      _project.photos.length,
    );
    _mutate(_project.copyWith(
        layoutTemplateId: template.id,
        clearCustomLayout: true,
        design: _project.design.copyWith(mode: DesignMode.standard)));
  }

  List<LayoutRecommendation> get layoutRecommendations =>
      const LayoutRecommendationService().recommend(_project.photos,
          targetRatio: _project.aspectRatio.value,
          staggerAmount: _project.canvas.staggerAmount);

  bool autoLayout() {
    final recommendations = layoutRecommendations;
    if (metadataLoading || recommendations.isEmpty) return false;
    final id = recommendations.first.layout.id;
    if (!_project.design.active &&
        _project.customLayout == null &&
        _project.layoutTemplateId == id) {
      return false;
    }
    setLayoutTemplate(id);
    return true;
  }

  /// Enrich current state and undo snapshots without adding an editing action.
  /// Merge by ID/path so an in-flight read never overwrites edits or replacements.
  Future<void> loadPhotoMetadata(
      {PhotoMetadataReader reader = const PhotoMetadataReader()}) async {
    if (metadataLoading || _disposed) return;
    final missing = _project.photos.where((p) => p.metadata == null).toList();
    if (missing.isEmpty) return;
    metadataLoading = true;
    final found = <String, PhotoMetadata>{};
    for (final photo in missing) {
      final value = await reader.read(photo.localPath);
      if (_disposed) return;
      if (value != null) found['${photo.id}\n${photo.localPath}'] = value;
    }
    CollageProject enrich(CollageProject project) => project.copyWith(photos: [
          for (final photo in project.photos)
            photo.metadata != null
                ? photo
                : photo.copyWith(
                    metadata: found['${photo.id}\n${photo.localPath}']),
        ]);
    if (found.isNotEmpty) {
      _project = enrich(_project);
      if (_dividerStart != null) _dividerStart = enrich(_dividerStart!);
      for (var i = 0; i < _undo.length; i++) {
        _undo[i] = enrich(_undo[i]);
      }
      for (var i = 0; i < _redo.length; i++) {
        _redo[i] = enrich(_redo[i]);
      }
      _scheduleAutosave();
    }
    metadataLoading = false;
    notifyListeners();
  }

  bool varyLayout() {
    final candidates = LayoutLibrary.templatesFor(_project.photos.length)
        .where((layout) =>
            _project.customLayout != null ||
            layout.id != _project.layoutTemplateId)
        .toList();
    if (candidates.isEmpty) return false;
    final choice = candidates[_random.nextInt(candidates.length)];
    _mutate(_project.copyWith(
        layoutTemplateId: choice.id,
        clearCustomLayout: true,
        design: _project.design.copyWith(mode: DesignMode.standard)));
    return true;
  }

  void applyTemplate(CollageTemplate template) {
    _mutate(template.applyTo(_project));
    _validateStickerSelection();
    if (selectedTextId != null &&
        !_project.textOverlays.any((item) => item.id == selectedTextId)) {
      selectedTextId = null;
    }
  }

  void resetStyle() => updateCanvas(const CanvasSettings()
      .copyWith(staggerAmount: _project.canvas.staggerAmount));

  bool _editingCanvas = false;
  void beginCanvasEdit() {
    _editingCanvas = true;
    beginInteractiveTransform();
  }

  void endCanvasEdit() {
    if (!_editingCanvas) return;
    _editingCanvas = false;
    endInteractiveTransform();
  }

  void updateCanvas(CanvasSettings settings) {
    if (_editingCanvas) {
      _project = _project.copyWith(canvas: settings);
      notifyListeners();
    } else {
      _mutate(_project.copyWith(canvas: settings));
    }
  }

  void setAdjustments(String photoId, PhotoAdjustments adjustments) {
    _mutate(_project.copyWith(photos: [
      for (final photo in _project.photos)
        if (photo.id == photoId)
          photo.copyWith(adjustments: adjustments)
        else
          photo,
    ]));
  }

  void setTransform(String photoId, PhotoTransform transform) {
    _mutate(_replaceTransform(photoId, transform));
  }

  void beginInteractiveTransform() {
    _autosave?.cancel();
    _interactiveStart ??= _project;
  }

  void updateTransformLive(String photoId, PhotoTransform transform) {
    _project = _replaceTransform(photoId, transform);
    notifyListeners();
  }

  void endInteractiveTransform() {
    final start = _interactiveStart;
    _interactiveStart = null;
    if (start != null &&
        jsonEncode(start.toJson()) != jsonEncode(_project.toJson())) {
      _undo.add(start);
      if (_undo.length > 80) _undo.removeAt(0);
      _redo.clear();
      notifyListeners();
    }
    _scheduleAutosave();
  }

  void resetSelectedTransform() {
    final photo = selectedPhoto;
    if (photo == null) {
      return;
    }
    setTransform(photo.id, PhotoTransform.identity);
  }

  void rotateSelected() {
    final photo = selectedPhoto;
    if (photo == null) {
      return;
    }
    setTransform(
      photo.id,
      photo.transform.copyWith(
        rotationQuarterTurns: photo.transform.rotationQuarterTurns + 1,
      ),
    );
  }

  void flipSelected() {
    final photo = selectedPhoto;
    if (photo == null) {
      return;
    }
    setTransform(
        photo.id, photo.transform.copyWith(flipX: !photo.transform.flipX));
  }

  void setSelectedFitMode(PhotoFitMode mode) {
    final photo = selectedPhoto;
    if (photo == null) {
      return;
    }
    setTransform(photo.id, photo.transform.copyWith(fitMode: mode));
  }

  Future<void> replaceSelected(XFile picked) async {
    final photo = selectedPhoto;
    if (photo == null || _replacing || _disposed) {
      return;
    }
    _replacing = true;
    try {
      final replacement =
          await _repository.importReplacement(picked, _project.id);
      if (_disposed || !_project.photos.any((item) => item.id == photo.id)) {
        return;
      }
      final photos = [
        for (final item in _project.photos)
          if (item.id == photo.id)
            replacement.copyWith(
                transform: item.transform, adjustments: item.adjustments)
          else
            item,
      ];
      selectedPhotoId = replacement.id;
      _mutate(_project.copyWith(
          photos: photos,
          design: _project.design.remapPhotos({photo.id: replacement.id})));
    } finally {
      _replacing = false;
    }
  }

  void removeSelected() {
    final photo = selectedPhoto;
    if (photo == null || _project.photos.length <= 1) {
      return;
    }
    final photos =
        _project.photos.where((item) => item.id != photo.id).toList();
    final template = LayoutLibrary.defaultFor(photos.length);
    selectedPhotoId = photos.first.id;
    _mutate(
      _project.copyWith(
        photos: photos,
        layoutTemplateId: template.id,
        design: _project.design.copyWith(layers: [
          for (final layer in _project.design.layers)
            if (layer.source(_project.photos)?.id != photo.id)
              layer
            else if (!layer.referencesPhoto)
              layer.copyWith(clearPhotoId: true),
        ]),
      ),
    );
  }

  void reorderPhotos(int oldIndex, int newIndex) {
    final photos = [..._project.photos];
    final photo = photos.removeAt(oldIndex);
    photos.insert(newIndex, photo);
    _mutate(_project.copyWith(photos: photos));
  }

  void undo() {
    endInteractiveTransform();
    endDividerDrag();
    if (_undo.isEmpty) {
      return;
    }
    _redo.add(_project);
    _project = _undo.removeLast();
    _validateStickerSelection();
    selectedPhotoId =
        _project.photos.any((photo) => photo.id == selectedPhotoId)
            ? selectedPhotoId
            : (_project.photos.isNotEmpty ? _project.photos.first.id : null);
    if (!_project.textOverlays.any((item) => item.id == selectedTextId)) {
      selectedTextId = null;
    }
    if (selectedTextId != null || selectedStickerId != null) {
      selectedPhotoId = null;
    }
    _validateDesignSelection();
    notifyListeners();
    _scheduleAutosave();
  }

  void redo() {
    endInteractiveTransform();
    endDividerDrag();
    if (_redo.isEmpty) {
      return;
    }
    _undo.add(_project);
    _project = _redo.removeLast();
    _validateStickerSelection();
    if (!_project.textOverlays.any((item) => item.id == selectedTextId)) {
      selectedTextId = null;
    }
    selectedPhotoId = selectedTextId != null || selectedStickerId != null
        ? null
        : (_project.photos.any((photo) => photo.id == selectedPhotoId)
            ? selectedPhotoId
            : _project.photos.firstOrNull?.id);
    _validateDesignSelection();
    notifyListeners();
    _scheduleAutosave();
  }

  Future<void> saveNow() async {
    endDividerDrag();
    _autosave?.cancel();
    // The repository serializes writes. Only the newest request updates feedback.
    final request = ++_saveRequest;
    try {
      await _repository.save(_project);
      if (request == _saveRequest) saveFailed = false;
    } catch (_) {
      if (request == _saveRequest) saveFailed = true;
      rethrow;
    } finally {
      if (!_disposed && request == _saveRequest) notifyListeners();
    }
  }

  Future<void> _saveInBackground() async {
    try {
      await saveNow();
    } catch (_) {
      // Keep the current project in memory and expose a retry in the editor.
    }
  }

  CollageProject _replaceTransform(String photoId, PhotoTransform transform) {
    return _clampPhotos(
        _project.copyWith(
          photos: [
            for (final photo in _project.photos)
              if (photo.id == photoId)
                photo.copyWith(transform: transform)
              else
                photo,
          ],
        ),
        onlyId: photoId,
        selectedLayer: selectedDesignLayer);
  }

  static CollageProject _clampPhotos(CollageProject project,
      {String? onlyId, DesignLayer? selectedLayer}) {
    final ratio = project.aspectRatio.value;
    final size = ratio >= 1 ? Size(390 * ratio, 390) : Size(390, 390 / ratio);
    final cells = LayoutGeometry.resolve(project, size);
    return project.copyWith(photos: [
      for (var i = 0; i < project.photos.length; i++)
        onlyId != null && project.photos[i].id != onlyId
            ? project.photos[i]
            : project.photos[i].metadata == null
                ? project.photos[i].copyWith(
                    transform: PhotoCrop.clamp(
                        project.photos[i].transform, Size.zero, Size.zero))
                : project.photos[i].copyWith(
                    transform: PhotoCrop.clamp(
                        project.photos[i].transform,
                        Size(project.photos[i].metadata!.width.toDouble(),
                            project.photos[i].metadata!.height.toDouble()),
                        project.design.active &&
                                selectedLayer?.isPhoto == true &&
                                selectedLayer!.type !=
                                    DesignLayerType.callout &&
                                selectedLayer.source(project.photos)?.id ==
                                    project.photos[i].id
                            ? selectedLayer.rect(size).size
                            : cells
                                    .where((cell) => cell.photoIndex == i)
                                    .firstOrNull
                                    ?.rect
                                    .size ??
                                Size.zero)),
    ]);
  }

  CollageProject _replaceText(TextOverlay overlay) => _project.copyWith(
        textOverlays: [
          for (final item in _project.textOverlays)
            if (item.id == overlay.id) overlay else item,
        ],
      );

  void _mutate(CollageProject next) {
    endInteractiveTransform();
    endDividerDrag();
    _undo.add(_project);
    if (_undo.length > 80) {
      _undo.removeAt(0);
    }
    _redo.clear();
    _project = next.normalizedForPhotoCount();
    _validateDesignSelection();
    if (!canEditDividers) _editingDividers = false;
    notifyListeners();
    _scheduleAutosave();
  }

  void _scheduleAutosave() {
    _autosave?.cancel();
    _autosave = Timer(const Duration(milliseconds: 700), () {
      unawaited(_saveInBackground());
    });
  }

  @override
  void dispose() {
    endDividerDrag();
    _disposed = true;
    _autosave?.cancel();
    unawaited(_saveInBackground());
    super.dispose();
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
