import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../collage_editor/models/layout_template.dart';
import '../../projects/models/collage_project.dart';
import '../models/collage_template.dart';
import '../models/design_library.dart';
import '../services/design_library_repository.dart';

final designLibraryRepositoryProvider =
    Provider<DesignLibraryRepository>((ref) {
  return DesignLibraryRepository();
});

final designLibraryProvider =
    StateNotifierProvider<DesignLibraryNotifier, AsyncValue<DesignLibrary>>(
        (ref) {
  return DesignLibraryNotifier(ref.read(designLibraryRepositoryProvider));
});

class DesignLibraryNotifier extends StateNotifier<AsyncValue<DesignLibrary>> {
  DesignLibraryNotifier(this._repository) : super(const AsyncValue.loading()) {
    _initialLoad = _load();
  }

  final DesignLibraryRepository _repository;
  late final Future<void> _initialLoad;

  Future<void> _load() async {
    final loaded = await AsyncValue.guard(_repository.load);
    if (mounted) state = loaded;
  }

  Future<DesignLibrary> _current() async {
    await _initialLoad;
    if (state.hasError) throw state.error!;
    return state.value ?? const DesignLibrary();
  }

  Future<void> toggleFavorite(LayoutTemplate layout) async {
    final current = await _current();
    final favorites = [
      for (final item in current.favoriteLayouts)
        if (item.id != layout.id) item,
      if (!current.isFavorite(layout.id)) FavoriteLayout.fromLayout(layout),
    ];
    final next = current.copyWith(favoriteLayouts: favorites);
    state = AsyncValue.data(next);
    await _repository.save(next);
  }

  Future<CollageTemplate> saveTemplate({
    required String name,
    required CollageProject project,
    required bool includeTextOverlays,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(name, 'name');
    final current = await _current();
    final template = CollageTemplate.fromProject(
      id: const Uuid().v4(),
      name: trimmed,
      project: project,
      includeTextOverlays: includeTextOverlays,
    );
    final next = current.copyWith(templates: [...current.templates, template]);
    state = AsyncValue.data(next);
    await _repository.save(next);
    return template;
  }

  Future<void> deleteTemplate(String id) async {
    final current = await _current();
    final next = current.copyWith(
      templates: current.templates.where((item) => item.id != id).toList(),
    );
    state = AsyncValue.data(next);
    await _repository.save(next);
  }
}
