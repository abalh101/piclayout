import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../demo_projects/demo_projects_page.dart';
import '../home/home_page.dart';
import '../settings/state/settings_controller.dart';
import '../tutorial_tips/tutorial_tip_controller.dart';

class OnboardingGate extends ConsumerWidget {
  const OnboardingGate({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(tutorialTipControllerProvider);
    // Wait for the saved language before showing the first introduction screen.
    if (ref.watch(settingsControllerProvider).isLoading ||
        preferences.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (preferences.hasError) {
      final t = AppLocalizations.of(context).tr;
      return Scaffold(
          body: SafeArea(
              child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(t('settingsError')),
        TextButton(
            onPressed: () => ref.invalidate(tutorialTipControllerProvider),
            child: Text(t('retry'))),
      ]))));
    }
    if (preferences.requireValue.completed) return const HomePage();
    return OnboardingPage(onFinished: (demo) {
      if (demo) openDemoProjects(context);
    });
  }
}

Future<void> replayOnboarding(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => OnboardingPage(onFinished: (demo) {
              Navigator.of(context).pop();
              if (demo) openDemoProjects(context);
            })));

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({required this.onFinished, super.key});
  final ValueChanged<bool> onFinished;
  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pages = PageController();
  int _index = 0;
  bool _busy = false;
  static const _icons = [
    Icons.auto_awesome_mosaic_outlined,
    Icons.photo_library_outlined,
    Icons.dashboard_customize_outlined,
    Icons.auto_fix_high_outlined,
    Icons.ios_share
  ];
  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish(bool demo) async {
    setState(() => _busy = true);
    try {
      await ref.read(tutorialTipControllerProvider.notifier).complete();
      if (mounted) widget.onFinished(demo);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context).tr('settingsError'))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).tr;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('PicLayout'), actions: [
          TextButton(
              key: const ValueKey('onboarding-skip'),
              onPressed: _busy ? null : () => _finish(false),
              child: Text(t('introSkip')))
        ]),
        body: SafeArea(
            child: LayoutBuilder(
                builder: (context, constraints) => Column(children: [
                      Expanded(
                          child: PageView.builder(
                        controller: _pages,
                        itemCount: 5,
                        onPageChanged: (index) =>
                            setState(() => _index = index),
                        itemBuilder: (context, index) => SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(children: [
                            Icon(_icons[index],
                                size: 72,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(height: 24),
                            Text(t('introTitle$index'),
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                                textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            Text(t('introBody$index'),
                                style: Theme.of(context).textTheme.bodyLarge,
                                textAlign: TextAlign.center),
                          ]),
                        ),
                      )),
                      // This footer scrolls as well when accessibility text leaves little room.
                      ConstrainedBox(
                          constraints: BoxConstraints(
                              maxHeight: constraints.maxHeight * .55),
                          child: SingleChildScrollView(
                              child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text('${_index + 1} / 5',
                                      textAlign: TextAlign.center),
                                  const SizedBox(height: 8),
                                  if (_index < 4)
                                    FilledButton(
                                        key: const ValueKey('onboarding-next'),
                                        onPressed: _busy
                                            ? null
                                            : () => _pages.nextPage(
                                                duration: const Duration(
                                                    milliseconds: 200),
                                                curve: Curves.easeOut),
                                        child: Text(t('introNext')))
                                  else ...[
                                    FilledButton(
                                        key: const ValueKey('onboarding-start'),
                                        onPressed:
                                            _busy ? null : () => _finish(false),
                                        child: Text(t('introStart'))),
                                    OutlinedButton(
                                        key: const ValueKey('onboarding-demo'),
                                        onPressed:
                                            _busy ? null : () => _finish(true),
                                        child: Text(t('demoOpen'))),
                                  ],
                                  if (_index > 0)
                                    TextButton(
                                        onPressed: _busy
                                            ? null
                                            : () => _pages.previousPage(
                                                duration: const Duration(
                                                    milliseconds: 200),
                                                curve: Curves.easeOut),
                                        child: Text(t('introBack'))),
                                  if (_busy) const LinearProgressIndicator(),
                                ]),
                          ))),
                    ]))),
      ),
    );
  }
}
