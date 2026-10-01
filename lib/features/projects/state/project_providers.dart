import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/collage_project.dart';
import '../services/project_repository.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository();
});

final projectsProvider =
    StateNotifierProvider<ProjectsNotifier, AsyncValue<List<CollageProject>>>(
  (ref) => ProjectsNotifier(ref.read(projectRepositoryProvider))..reload(),
);

class ProjectsNotifier extends StateNotifier<AsyncValue<List<CollageProject>>> {
  ProjectsNotifier(this._repository) : super(const AsyncValue.loading());

  final ProjectRepository _repository;

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.loadProjects);
  }

  Future<CollageProject> add(CollageProject project) async {
    final current = state.value ?? [];
    state = AsyncValue.data([project, ...current]);
    return project;
  }

  Future<void> rename(CollageProject project, String name) async {
    await _repository.rename(project, name);
    await reload();
  }

  Future<CollageProject> duplicate(CollageProject project) async {
    final copy = await _repository.duplicate(project);
    await reload();
    return copy;
  }

  Future<void> delete(CollageProject project) async {
    await _repository.delete(project);
    await reload();
  }
}
