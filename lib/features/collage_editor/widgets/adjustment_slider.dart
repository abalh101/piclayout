import 'package:flutter/material.dart';

/// Stable label/value columns, a 48px reset target and grouped gesture hooks.
class AdjustmentSlider extends StatelessWidget {
  const AdjustmentSlider(
      {super.key,
      required this.label,
      required this.value,
      required this.min,
      required this.max,
      required this.neutral,
      required this.onChanged,
      required this.onStart,
      required this.onEnd,
      required this.onReset,
      required this.resetLabel,
      this.formatValue,
      this.enabled = true});
  final String label, resetLabel;
  final double value, min, max, neutral;
  final ValueChanged<double> onChanged;
  final VoidCallback onStart, onEnd, onReset;
  final bool enabled;
  final String Function(double)? formatValue;

  @override
  Widget build(BuildContext context) {
    final display = formatValue?.call(value) ??
        '${((value - (min == 0 && max == 2 ? 1 : 0)) * 100).round()}';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(label)),
        SizedBox(
            width: 64,
            child: Text(display,
                textAlign: TextAlign.end,
                style: const TextStyle(
                    fontFeatures: [FontFeature.tabularFigures()]))),
        IconButton(
            tooltip: '$resetLabel: $label',
            onPressed: enabled && value != neutral ? onReset : null,
            icon: const Icon(Icons.restart_alt, size: 20)),
      ]),
      Semantics(
          label: label,
          child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              secondaryTrackValue: neutral,
              label: display,
              onChangeStart: enabled ? (_) => onStart() : null,
              onChanged: enabled ? onChanged : null,
              onChangeEnd: enabled ? (_) => onEnd() : null)),
    ]);
  }
}
