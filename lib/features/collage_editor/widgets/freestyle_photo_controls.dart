import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../models/photo_asset.dart';
import '../models/photo_placement.dart';
import '../state/collage_editor_controller.dart';

class FreestylePhotoControls extends StatelessWidget {
  const FreestylePhotoControls(
      {super.key, required this.photo, required this.controller});

  final PhotoAsset photo;
  final CollageEditorController controller;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).tr;
    final placement = photo.placement ?? const PhotoPlacement();
    Widget slider(String label, double value, double min, double max,
            PhotoPlacement Function(double) apply) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t(label)),
            Slider(
              value: value,
              min: min,
              max: max,
              semanticFormatterCallback: (value) =>
                  '${t(label)} ${value.toStringAsFixed(2)}',
              onChangeStart: (_) => controller.beginInteractiveTransform(),
              onChanged: (value) => controller
                  .updatePlacement(photo.id, apply(value), live: true),
              onChangeEnd: (_) => controller.endInteractiveTransform(),
            ),
          ],
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Divider(height: 24),
      slider('photoOpacity', placement.opacity, 0, 1,
          (value) => placement.copyWith(opacity: value)),
      slider('photoAngle', placement.rotation, -180, 180,
          (value) => placement.copyWith(rotation: value)),
      slider('photoCorner', placement.radius, 0, .5,
          (value) => placement.copyWith(radius: value)),
      slider('photoBorder', placement.border, 0, .18,
          (value) => placement.copyWith(border: value)),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(t('photoShadow')),
        value: placement.shadow,
        onChanged: (value) => controller.updatePlacement(
            photo.id, placement.copyWith(shadow: value)),
      ),
    ]);
  }
}
