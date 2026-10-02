import 'package:piclayout/features/onboarding/onboarding_repository.dart';

class MemoryOnboarding extends OnboardingRepository {
  MemoryOnboarding({this.value = const OnboardingState()});
  OnboardingState value;
  bool failSave = false;
  @override
  Future<OnboardingState> load() async => value;
  @override
  Future<void> save(OnboardingState state) async {
    if (failSave) throw StateError('storage unavailable');
    value = state;
  }
}
