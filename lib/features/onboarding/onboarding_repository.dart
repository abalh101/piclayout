import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class OnboardingState {
  const OnboardingState(
      {this.completed = false,
      this.tipViews = const {},
      this.dismissedTips = const {}});
  final bool completed;
  final Map<String, int> tipViews;
  final Set<String> dismissedTips;

  bool canShow(String id) =>
      !dismissedTips.contains(id) && (tipViews[id] ?? 0) < 2;
  Map<String, Object?> toJson() => {
        'completed': completed,
        'tipViews': tipViews,
        'dismissedTips': dismissedTips.toList()
      };
  factory OnboardingState.fromJson(Map<String, dynamic> json) =>
      OnboardingState(
        completed: json['completed'] == true,
        tipViews: {
          for (final e in (json['tipViews'] as Map? ?? {}).entries)
            if (e.key is String && e.value is int && e.value >= 0)
              e.key as String: e.value as int
        },
        dismissedTips:
            (json['dismissedTips'] as List? ?? []).whereType<String>().toSet(),
      );
}

class OnboardingRepository {
  OnboardingRepository({this.directory});
  final Directory? directory;
  Future<File> _file() async => File(
      '${(directory ?? await getApplicationSupportDirectory()).path}/onboarding.json');
  Future<OnboardingState> load() async {
    final file = await _file();
    if (!await file.exists()) return const OnboardingState();
    try {
      return OnboardingState.fromJson(
          jsonDecode(await file.readAsString()) as Map<String, dynamic>);
    } on FormatException {
      return const OnboardingState();
    } on TypeError {
      return const OnboardingState();
    }
  }

  Future<void> save(OnboardingState value) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    final pending = File('${file.path}.tmp');
    await pending.writeAsString(jsonEncode(value.toJson()), flush: true);
    await pending.rename(file.path);
  }
}
