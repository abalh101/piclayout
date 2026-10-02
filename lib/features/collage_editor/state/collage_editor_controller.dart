import 'dart:async';
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

final editorControllerProvider = ChangeNotifierProvider.autoDispose
    .family<CollageEditorController, CollageProject>((ref, project) {
  final controller = CollageEditorController(
    initialProject: project,
    repository: ref.read(projectRepositoryProvider),
  );
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
  Timer? _autosave;
  Offset? _textDragGlobalPosition;

  CollageProject _project;
  String? selectedPhotoId;
  String? selectedTextId;

  CollageProject get project => _project;
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  bool get canVaryLayout => LayoutLibrary.templatesFor(_project.photos.length)
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
    selectedPhotoId = photoId;
    selectedTextId = null;
    notifyListeners();
  }

  void selectText(String textId) {
    selectedTextId = textId;
    selectedPhotoId = null;
    notifyListeners();
  }

  TextOverlay addText(String text) {
    final overlay = TextOverlay(id: const Uuid().v4(), text: text);
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

  void setAspectRatio(AspectRatioPreset preset) {
    _mutate(_project.copyWith(aspectRatioId: preset.id));
  }

  void setLayoutTemplate(String layoutTemplateId) {
    final template = LayoutLibrary.byIdOrDefault(
      layoutTemplateId,
      _project.photos.length,
    );
    _mutate(_project.copyWith(layoutTemplateId: template.id));
  }

  bool varyLayout() {
    final candidates = LayoutLibrary.templatesFor(_project.photos.length)
        .where((layout) => layout.id != _project.layoutTemplateId)
        .toList();
    if (candidates.isEmpty) return false;
    final choice = candidates[_random.nextInt(candidates.length)];
    _mutate(_project.copyWith(layoutTemplateId: choice.id));
    return true;
  }

  void applyTemplate(CollageTemplate template) {
    _mutate(template.applyTo(_project));
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

  void setTransform(String photoId, PhotoTransform transform) {
    _mutate(_replaceTransform(photoId, transform));
  }

  void beginInteractiveTransform() {
    _undo.add(_project);
    _redo.clear();
    notifyListeners();
  }

  void updateTransformLive(String photoId, PhotoTransform transform) {
    _project = _replaceTransform(photoId, transform);
    notifyListeners();
  }

  void endInteractiveTransform() {
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
    final photos = [
      for (final item in _project.photos)
        if (item.id == photo.id)
          replacement.copyWith(transform: photo.transform)
        else
          item,
    ];
    selectedPhotoId = replacement.id;
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
    final photos = [..._project.photos];
    final photo = photos.removeAt(oldIndex);
    photos.insert(newIndex, photo);
    _mutate(_project.copyWith(photos: photos));
  }

  void undo() {
    if (_undo.isEmpty) {
      return;
    }
    _redo.add(_project);
    _project = _undo.removeLast();
    selectedPhotoId =
        _project.photos.any((photo) => photo.id == selectedPhotoId)
            ? selectedPhotoId
            : (_project.photos.isNotEmpty ? _project.photos.first.id : null);
    if (!_project.textOverlays.any((item) => item.id == selectedTextId)) {
      selectedTextId = null;
    }
    if (selectedTextId != null) selectedPhotoId = null;
    notifyListeners();
    _scheduleAutosave();
  }

  void redo() {
    if (_redo.isEmpty) {
      return;
    }
    _undo.add(_project);
    _project = _redo.removeLast();
    if (!_project.textOverlays.any((item) => item.id == selectedTextId)) {
      selectedTextId = null;
    }
    notifyListeners();
    _scheduleAutosave();
  }

  Future<void> saveNow() async {
    _autosave?.cancel();
    await _repository.save(_project);
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
    _undo.add(_project);
    if (_undo.length > 80) {
      _undo.removeAt(0);
    }
    _redo.clear();
    _project = next.normalizedForPhotoCount();
    notifyListeners();
    _scheduleAutosave();
  }

  void _scheduleAutosave() {
    _autosave?.cancel();
    _autosave = Timer(const Duration(milliseconds: 700), () {
      _repository.save(_project);
    });
  }

  @override
  void dispose() {
    _autosave?.cancel();
    unawaited(_repository.save(_project));
    super.dispose();
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
