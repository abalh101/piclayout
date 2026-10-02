import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../onboarding/onboarding_repository.dart';

final onboardingRepositoryProvider = Provider((ref) => OnboardingRepository());
final tutorialTipControllerProvider =
    AsyncNotifierProvider<TutorialTipController, OnboardingState>(
        TutorialTipController.new);

/// All introduction preferences share a serialized, atomic local write queue.
class TutorialTipController extends AsyncNotifier<OnboardingState> {
  Future<void> _pending = Future.value();
  @override
  Future<OnboardingState> build() =>
      ref.read(onboardingRepositoryProvider).load();

  Future<void> _update(OnboardingState Function(OnboardingState) change) {
    final operation = _pending.then((_) async {
      final current = await future;
      final next = change(current);
      if (identical(next, current)) return;
      await ref.read(onboardingRepositoryProvider).save(next);
      state = AsyncData(next);
    });
    _pending = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> complete() => _update((s) => OnboardingState(
      completed: true, tipViews: s.tipViews, dismissedTips: s.dismissedTips));
  Future<bool> claim(String id) async {
    var shown = false;
    await _update((s) {
      if (!s.canShow(id)) return s;
      shown = true;
      return OnboardingState(
          completed: s.completed,
          tipViews: {...s.tipViews, id: (s.tipViews[id] ?? 0) + 1},
          dismissedTips: s.dismissedTips);
    });
    return shown;
  }

  Future<void> dismiss(String id) => _update((s) => OnboardingState(
      completed: s.completed,
      tipViews: s.tipViews,
      dismissedTips: {...s.dismissedTips, id}));
  Future<void> resetTips() =>
      _update((s) => OnboardingState(completed: s.completed));
}
