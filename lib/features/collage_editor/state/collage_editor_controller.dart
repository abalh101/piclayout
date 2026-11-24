import '../../layout_recommendations/layout_recommendation_service.dart';
import '../../layout_recommendations/photo_metadata_reader.dart';
import '../models/photo_metadata.dart';
import '../../stickers/sticker_overlay.dart';
import '../../custom_layouts/models/custom_layout.dart';
import '../models/photo_adjustments.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../app/app_config.dart';
import '../../projects/models/collage_project.dart';
import '../../projects/state/project_providers.dart';
import '../../projects/services/project_repository.dart';
import '../../templates/models/collage_template.dart';
import '../layouts/layout_library.dart';
import '../models/aspect_ratio_preset.dart';
import '../models/canvas_settings.dart';
import '../models/photo_asset.dart';
import '../models/photo_placement.dart';
import '../models/photo_transform.dart';
import '../models/text_overlay.dart';
import '../rendering/text_overlay_renderer.dart';
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
  bool snapFreestyle = true;
  PhotoAdjustments? copiedAdjustments;
  Timer? _autosave;
  Future<void>? _saving;
  CollageProject? _interactiveStart;
  bool _interactiveChanged = false;
  Offset? _textDragGlobalPosition;

  CollageProject _project;
  String? selectedPhotoId;
  String? selectedTextId;
  String? selectedStickerId;

  CollageProject get project => _project;
  CollageProject get projectAtGestureStart => _interactiveStart ?? _project;
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
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

  bool get selectedPhotoEditable =>
      selectedPhoto != null &&
      (!_project.freestyle || selectedPhoto?.placement?.locked != true);

  void setFreestyle(bool enabled) {
    if (_project.freestyle == enabled) return;
    final size = Size(_project.aspectRatio.value * 1000, 1000);
    final cells = {
      for (final cell in LayoutGeometry.resolve(_project, size))
        cell.photoIndex: cell.rect
    };
    PhotoPlacement seed(Rect rect) => const PhotoPlacement().copyWith(
          x: rect.center.dx / size.width,
          y: rect.center.dy / size.height,
          width: rect.width / size.width,
          height: rect.height / size.height,
        );
    _mutate(_project.copyWith(freestyle: enabled, photos: [
      for (final (index, photo) in _project.photos.indexed)
        if (enabled && photo.placement == null && cells.containsKey(index))
          photo.copyWith(placement: seed(cells[index]!))
        else
          photo,
    ]));
  }

  void setSnapFreestyle(bool enabled) {
    snapFreestyle = enabled;
    notifyListeners();
  }

  void updatePlacement(String id, PhotoPlacement placement,
      {bool live = false}) {
    final before = _project.photos.where((item) => item.id == id).firstOrNull;
    if (before == null ||
        mapEquals(before.placement?.toJson(), placement.toJson())) {
      return;
    }
    final next = _project.copyWith(photos: [
      for (final photo in _project.photos)
        if (photo.id == id) photo.copyWith(placement: placement) else photo,
    ]);
    if (live) {
      _interactiveChanged = true;
      _project = next;
      notifyListeners();
    } else {
      _mutate(next);
    }
  }

  bool get canAddPhotos => _project.photos.length < AppConfig.maxPhotos;

  Future<void> addPhotos(List<XFile> picked) async {
    if (!_project.freestyle || !canAddPhotos) return;
    final added = <PhotoAsset>[];
    for (final file
        in picked.take(AppConfig.maxPhotos - _project.photos.length)) {
      final imported = await _repository.importReplacement(file, _project.id);
      final offset = (added.length % 4) * .045;
      added.add(imported.copyWith(
          placement: PhotoPlacement(x: .44 + offset, y: .44 + offset)));
    }
    if (_disposed || !_project.freestyle || !canAddPhotos || added.isEmpty) {
      return;
    }
    final accepted =
        added.take(AppConfig.maxPhotos - _project.photos.length).toList();
    selectedPhotoId = accepted.last.id;
    selectedTextId = selectedStickerId = null;
    _mutate(_project.copyWith(photos: [..._project.photos, ...accepted]));
  }

  void duplicateSelectedPhoto() {
    final photo = selectedPhoto;
    if (!_project.freestyle || photo == null || !canAddPhotos) return;
    final placement = photo.placement ?? const PhotoPlacement();
    final copy = photo.copyWith(
        id: const Uuid().v4(),
        placement: placement.copyWith(
          x: placement.x + .04,
          y: placement.y + .04,
          locked: false,
          hidden: false,
        ));
    selectedPhotoId = copy.id;
    _mutate(_project.copyWith(photos: [..._project.photos, copy]));
  }

  TextOverlay? get selectedText {
    final id = selectedTextId;
    if (id == null) return null;
    return _project.textOverlays.where((item) => item.id == id).firstOrNull;
  }

  void selectPhoto(String photoId) {
    if (selectedPhotoId == photoId &&
        selectedTextId == null &&
        selectedStickerId == null) {
      return;
    }
    selectedStickerId = null;
    selectedPhotoId = photoId;
    selectedTextId = null;
    notifyListeners();
  }

  void selectText(String textId) {
    selectedStickerId = null;
    selectedTextId = textId;
    selectedPhotoId = null;
    notifyListeners();
  }

  TextOverlay addText(String text) {
    final overlay = TextOverlay(id: const Uuid().v4(), text: text);
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
    _interactiveChanged = true;
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

  void duplicateSelectedText() {
    final text = selectedText;
    if (text == null) return;
    final copy = text.copyWith(
        id: const Uuid().v4(),
        x: text.x + .04,
        y: text.y + .04,
        hidden: false,
        locked: false);
    selectedTextId = copy.id;
    _mutate(_project.copyWith(textOverlays: [..._project.textOverlays, copy]));
  }

  void reorderText(int from, int to) => _mutate(_project.copyWith(
      textOverlays: _reordered(_project.textOverlays, from, to)));

  void reorderStickers(int from, int to) => _mutate(
      _project.copyWith(stickers: _reordered(_project.stickers, from, to)));

  StickerOverlay? get selectedSticker =>
      _project.stickers.where((s) => s.id == selectedStickerId).firstOrNull;

  void selectSticker(String id) {
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
      _interactiveChanged = true;
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
        id: const Uuid().v4(),
        x: sticker.x + .04,
        y: sticker.y + .04,
        hidden: false,
        locked: false);
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

  void setAspectRatio(AspectRatioPreset preset) {
    if (_project.aspectRatioId == preset.id) return;
    _mutate(_project.copyWith(aspectRatioId: preset.id));
  }

  bool applyCustomLayout(CustomLayout layout) {
    if (layout.photoCount != _project.photos.length) return false;
    if (identical(_project.customLayout, layout)) return true;
    _mutate(_project.copyWith(customLayout: layout));
    return true;
  }

  void setLayoutTemplate(String layoutTemplateId) {
    final template = LayoutLibrary.byIdOrDefault(
      layoutTemplateId,
      _project.photos.length,
    );
    if (_project.customLayout == null &&
        _project.layoutTemplateId == template.id) {
      return;
    }
    _mutate(_project.copyWith(
        layoutTemplateId: template.id, clearCustomLayout: true));
  }

  List<LayoutRecommendation> get layoutRecommendations =>
      const LayoutRecommendationService().recommend(_project.photos,
          targetRatio: _project.aspectRatio.value,
          staggerAmount: _project.canvas.staggerAmount,
          canvas: _project.canvas);

  bool autoLayout() {
    final recommendations = layoutRecommendations;
    if (metadataLoading || recommendations.isEmpty) return false;
    final id = recommendations.first.layout.id;
    if (_project.customLayout == null && _project.layoutTemplateId == id) {
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
      final start = _interactiveStart;
      if (start != null) _interactiveStart = enrich(start);
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
        layoutTemplateId: choice.id, clearCustomLayout: true));
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
      _interactiveChanged = true;
      _project = _project.copyWith(canvas: settings);
      notifyListeners();
    } else {
      _mutate(_project.copyWith(canvas: settings));
    }
  }

  void setAdjustments(String photoId, PhotoAdjustments adjustments,
      {bool all = false}) {
    _mutate(_project.copyWith(photos: [
      for (final photo in _project.photos)
        if ((all || photo.id == photoId) &&
            (!_project.freestyle || photo.placement?.locked != true))
          photo.copyWith(adjustments: adjustments)
        else
          photo,
    ]));
  }

  void setTransform(String photoId, PhotoTransform transform) {
    _mutate(_replaceTransform(photoId, transform));
  }

  void beginInteractiveTransform() {
    _interactiveStart ??= _project;
  }

  void updateTransformLive(String photoId, PhotoTransform transform) {
    final previous = _project.photos
        .where((item) => item.id == photoId)
        .firstOrNull
        ?.transform;
    if (previous == null ||
        (previous.scale == transform.scale &&
            previous.offsetX == transform.offsetX &&
            previous.offsetY == transform.offsetY &&
            previous.rotationQuarterTurns == transform.rotationQuarterTurns &&
            previous.flipX == transform.flipX &&
            previous.fitMode == transform.fitMode)) {
      return;
    }
    _interactiveChanged = true;
    _project = _replaceTransform(photoId, transform);
    notifyListeners();
  }

  void endInteractiveTransform() {
    final start = _interactiveStart;
    _interactiveStart = null;
    final changed = _interactiveChanged;
    _interactiveChanged = false;
    if (start == null || !changed) return;
    _recordUndo(start);
    notifyListeners();
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
    if (photo == null) {
      return;
    }
    final replacement =
        await _repository.importReplacement(picked, _project.id);
    if (_disposed || !_project.photos.any((item) => item.id == photo.id)) {
      return;
    }
    final photos = [
      for (final item in _project.photos)
        if (item.id == photo.id)
          replacement.copyWith(
              transform: item.transform, placement: item.placement)
        else
          item,
    ];
    if (selectedPhotoId == photo.id) selectedPhotoId = replacement.id;
    _mutate(_project.copyWith(photos: photos));
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
      ),
    );
  }

  void reorderPhotos(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    _mutate(_project.copyWith(
        photos: _reordered(_project.photos, oldIndex, newIndex)));
  }

  List<T> _reordered<T>(List<T> items, int from, int to) {
    final result = List<T>.of(items);
    final item = result.removeAt(from);
    result.insert(to, item);
    return result;
  }

  void undo() {
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
    notifyListeners();
    _scheduleAutosave();
  }

  void redo() {
    if (_redo.isEmpty) {
      return;
    }
    _undo.add(_project);
    _project = _redo.removeLast();
    _validateStickerSelection();
    if (!_project.textOverlays.any((item) => item.id == selectedTextId)) {
      selectedTextId = null;
    }
    if (selectedTextId == null && selectedStickerId == null) {
      selectedPhotoId = selectedPhoto?.id ?? _project.photos.firstOrNull?.id;
    }
    notifyListeners();
    _scheduleAutosave();
  }

  Future<void> saveNow() async {
    _autosave?.cancel();
    final pending = _repository.save(_project);
    _saving = pending;
    try {
      await pending;
      if (identical(_saving, pending) && saveFailed && !_disposed) {
        saveFailed = false;
        notifyListeners();
      }
    } catch (_) {
      if (identical(_saving, pending) && !saveFailed && !_disposed) {
        saveFailed = true;
        notifyListeners();
      }
      rethrow;
    } finally {
      if (identical(_saving, pending)) _saving = null;
    }
  }

  Future<void> flushPendingSave() async {
    if (_autosave?.isActive == true || _interactiveChanged || saveFailed) {
      await saveNow();
    } else {
      await _saving;
    }
  }

  CollageProject _replaceTransform(String photoId, PhotoTransform transform) {
    return _project.copyWith(
      photos: [
        for (final photo in _project.photos)
          if (photo.id == photoId)
            photo.copyWith(transform: transform)
          else
            photo,
      ],
    );
  }

  CollageProject _replaceText(TextOverlay overlay) => _project.copyWith(
        textOverlays: [
          for (final item in _project.textOverlays)
            if (item.id == overlay.id) overlay else item,
        ],
      );

  void _mutate(CollageProject next) {
    final start = _interactiveStart;
    _interactiveStart = null;
    _interactiveChanged = false;
    _recordUndo(start ?? _project);
    _project = next.normalizedForPhotoCount();
    notifyListeners();
    _scheduleAutosave();
  }

  void _recordUndo(CollageProject project) {
    _undo.add(project);
    if (_undo.length > 80) {
      _undo.removeAt(0);
    }
    _redo.clear();
  }

  void _scheduleAutosave() {
    _autosave?.cancel();
    _autosave = Timer(const Duration(milliseconds: 700), () {
      unawaited(saveNow().catchError((Object _) {}));
    });
  }

  @override
  void dispose() {
    _disposed = true;
    if (_autosave?.isActive == true || _interactiveChanged) {
      unawaited(saveNow().catchError((Object _) {}));
    }
    super.dispose();
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
