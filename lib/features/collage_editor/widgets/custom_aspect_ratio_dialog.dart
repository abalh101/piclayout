import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/app_localizations.dart';
import '../models/aspect_ratio_preset.dart';

Future<AspectRatioPreset?> showCustomAspectRatioDialog(BuildContext context) =>
    showDialog<AspectRatioPreset>(
        context: context, builder: (_) => const _RatioDialog());

class _RatioDialog extends StatefulWidget {
  const _RatioDialog();
  @override
  State<_RatioDialog> createState() => _RatioDialogState();
}

class _RatioDialogState extends State<_RatioDialog> {
  final _width = TextEditingController();
  final _height = TextEditingController();
  bool _invalid = false;
  @override
  void dispose() {
    _width.dispose();
    _height.dispose();
    super.dispose();
  }

  void _apply() {
    try {
      Navigator.pop(context, AspectRatios.parse(_width.text, _height.text));
    } on FormatException {
      setState(() => _invalid = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    Widget field(TextEditingController controller, String key) => TextField(
        key: ValueKey('ratio-$key'),
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [LengthLimitingTextInputFormatter(11)],
        decoration: InputDecoration(labelText: strings.tr(key)),
        onSubmitted: (_) => _apply());
    return AlertDialog(
      title: Text(strings.tr('customRatio')),
      content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(strings.tr('ratioHint')),
        field(_width, 'ratioWidth'),
        field(_height, 'ratioHeight'),
        if (_invalid)
          Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(strings.tr('ratioError'),
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error))),
      ])),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.cancel)),
        FilledButton(
            key: const ValueKey('save-ratio'),
            onPressed: _apply,
            child: Text(strings.tr('ratioSave'))),
      ],
    );
  }
}
