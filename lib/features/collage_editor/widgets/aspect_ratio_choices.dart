import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../settings/state/settings_controller.dart';
import '../models/aspect_ratio_preset.dart';

class AspectRatioChoices extends ConsumerWidget {
  const AspectRatioChoices({
    super.key,
    required this.selectedId,
    required this.onSelected,
  });

  final String selectedId;
  final ValueChanged<AspectRatioPreset>? onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final custom = AspectRatios.customById(selectedId);
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final ratio in [...AspectRatios.all, if (custom != null) custom])
          ChoiceChip(
            label: Text(ratio.label),
            selected: selectedId == ratio.id,
            onSelected: onSelected == null ? null : (_) => onSelected!(ratio),
          ),
        ActionChip(
          avatar: const Icon(Icons.aspect_ratio, size: 18),
          label: Text(strings.tr('customRatio')),
          onPressed: onSelected == null ? null : () => _choose(context, ref),
        ),
      ],
    );
  }

  Future<void> _choose(BuildContext context, WidgetRef ref) async {
    final chosen = await showDialog<AspectRatioPreset>(
      context: context,
      builder: (_) => _RatioDialog(initial: AspectRatios.byId(selectedId)),
    );
    if (chosen == null || !context.mounted) return;
    onSelected?.call(chosen);
    final settings = ref.read(settingsControllerProvider).value;
    if (settings == null) return;
    try {
      await ref.read(settingsControllerProvider.notifier).saveSettings(
            settings.copyWith(recentRatios: [
              chosen.id,
              ...settings.recentRatios.where((id) => id != chosen.id).take(7),
            ]),
          );
    } catch (_) {
      if (context.mounted) _settingsError(context);
    }
  }
}

class _RatioDialog extends ConsumerStatefulWidget {
  const _RatioDialog({required this.initial});

  final AspectRatioPreset initial;

  @override
  ConsumerState<_RatioDialog> createState() => _RatioDialogState();
}

class _RatioDialogState extends ConsumerState<_RatioDialog> {
  late final _width = TextEditingController(text: '${widget.initial.width}');
  late final _height = TextEditingController(text: '${widget.initial.height}');

  void _set(String width, String height) => setState(() {
        _width.text = width;
        _height.text = height;
      });

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final t = strings.tr;
    final settings = ref.watch(settingsControllerProvider).value;
    final favorites = settings?.favoriteRatios ?? const [];
    final recents = settings?.recentRatios ?? const [];
    final ratios = {...favorites, ...recents}.map(AspectRatios.byId);
    final ratio = AspectRatios.custom(
      AspectRatios.parseDimension(_width.text),
      AspectRatios.parseDimension(_height.text),
    );
    final colors = Theme.of(context).colorScheme;
    final hierarchy = Theme.of(context).textTheme;
    return AlertDialog(
      scrollable: true,
      title: Text(t('customRatio')),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: _field(_width, t('dimensionWidth'))),
                IconButton(
                  tooltip: t('swapDimensions'),
                  onPressed: () => _set(_height.text, _width.text),
                  icon: const Icon(Icons.swap_horiz),
                ),
                Expanded(child: _field(_height, t('dimensionHeight'))),
              ],
            ),
            const SizedBox(height: 12),
            if (ratio == null)
              Text(t('ratioLimits'), style: TextStyle(color: colors.error))
            else ...[
              Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: 150, maxHeight: 76),
                  child: AspectRatio(
                    aspectRatio: ratio.value,
                    child: DecoratedBox(
                        decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      border: Border.all(color: colors.primary),
                      borderRadius: BorderRadius.circular(6),
                    )),
                  ),
                ),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(ratio.label, textDirection: TextDirection.ltr),
                IconButton(
                  tooltip: favorites.contains(ratio.id)
                      ? strings.removeFavorite
                      : strings.addFavorite,
                  icon: Icon(favorites.contains(ratio.id)
                      ? Icons.star
                      : Icons.star_border),
                  onPressed: settings == null
                      ? null
                      : () async {
                          final next = favorites.contains(ratio.id)
                              ? favorites.where((id) => id != ratio.id).toList()
                              : [ratio.id, ...favorites.take(7)];
                          try {
                            await ref
                                .read(settingsControllerProvider.notifier)
                                .saveSettings(
                                    settings.copyWith(favoriteRatios: next));
                          } catch (_) {
                            if (context.mounted) _settingsError(context);
                          }
                        },
                ),
              ]),
            ],
            if (ratios.isNotEmpty) ...[
              Text(t('savedRatios'), style: hierarchy.labelLarge),
              Wrap(spacing: 8, children: [
                for (final item in ratios)
                  ActionChip(
                    avatar: favorites.contains(item.id)
                        ? const Icon(Icons.star, size: 16)
                        : null,
                    label: Text(item.label, textDirection: TextDirection.ltr),
                    onPressed: () => _set('${item.width}', '${item.height}'),
                  ),
              ]),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.cancel)),
        FilledButton(
          onPressed: ratio == null ? null : () => Navigator.pop(context, ratio),
          child: Text(strings.done),
        ),
      ],
    );
  }

  Widget _field(TextEditingController controller, String label) => TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textDirection: TextDirection.ltr,
        decoration: InputDecoration(labelText: label),
        onChanged: (_) => setState(() {}),
      );

  @override
  void dispose() {
    _width.dispose();
    _height.dispose();
    super.dispose();
  }
}

void _settingsError(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(AppLocalizations.of(context).tr('operationFailed')),
  ));
}
