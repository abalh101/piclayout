import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/custom_layout.dart';
import '../services/custom_layout_repository.dart';

final customLayoutRepositoryProvider =
    Provider((ref) => CustomLayoutRepository());
final customLayoutsProvider =
    AsyncNotifierProvider<CustomLayoutsController, List<CustomLayout>>(
        CustomLayoutsController.new);

class CustomLayoutsController extends AsyncNotifier<List<CustomLayout>> {
  Future<void> _pending = Future.value();
  @override
  Future<List<CustomLayout>> build() =>
      ref.read(customLayoutRepositoryProvider).load();
  Future<void> saveLayout(CustomLayout layout) {
    final operation = _pending.catchError((Object _) {}).then((_) async {
      final current = await future;
      final next = [
        for (final item in current)
          if (item.id != layout.id) item,
        layout
      ];
      await ref.read(customLayoutRepositoryProvider).save(next);
      state = AsyncData(next);
    });
    _pending = operation;
    return operation;
  }
}
