import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import 'tutorial_tip_controller.dart';

class TutorialTip extends ConsumerStatefulWidget {
  const TutorialTip({required this.id, super.key});
  final String id;
  @override
  ConsumerState<TutorialTip> createState() => _TutorialTipState();
}

class _TutorialTipState extends ConsumerState<TutorialTip> {
  bool _visible = false;
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        final show = await ref
            .read(tutorialTipControllerProvider.notifier)
            .claim(widget.id);
        if (mounted) setState(() => _visible = show);
      } catch (_) {
        // Optional hints must never prevent editing when storage is unavailable.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    final t = AppLocalizations.of(context).tr;
    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 12),
        child: Row(children: [
          const Icon(Icons.lightbulb_outline, size: 20),
          const SizedBox(width: 8),
          Expanded(
              child: Text(t(widget.id),
                  style: Theme.of(context).textTheme.bodySmall)),
          IconButton(
              tooltip: t('Schließen'),
              icon: const Icon(Icons.close, size: 18),
              onPressed: () async {
                setState(() => _visible = false);
                try {
                  await ref
                      .read(tutorialTipControllerProvider.notifier)
                      .dismiss(widget.id);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t('settingsError'))));
                  }
                }
              }),
        ]),
      ),
    );
  }
}
