import 'dart:math' as math;
import 'dart:ui';
import 'package:uuid/uuid.dart';
import '../../collage_editor/models/photo_asset.dart';
import '../../collage_editor/models/photo_transform.dart';
import '../../collage_editor/models/photo_adjustments.dart';
import 'editorial_design.dart';

/// Structured frame geometry, never flattened assets or user thumbnails.
class FreeformPresets {
  static const keys = [
    'ffStory9',
    'ffStory12',
    'ffStory15',
    'ffCanvas',
    'ffScrapbook',
    'ffGallery'
  ];

  static EditorialDesign create(String key, List<PhotoAsset> photos) {
    final count = switch (key) {
      'ffStory9' => 9,
      'ffStory12' => 12,
      'ffStory15' => 15,
      'ffCanvas' => photos.length,
      'ffScrapbook' => math.max(9, photos.length),
      _ => math.max(12, photos.length),
    };
    final rects = key.startsWith('ffStory') ? mosaic(count) : gallery(count);
    return EditorialDesign(mode: DesignMode.freeform, preset: key, layers: [
      for (var i = 0; i < rects.length; i++)
        frame(rects[i], i, i < photos.length ? photos[i] : null).copyWith(
          rotation: key == 'ffScrapbook' ? (i.isEven ? -3.0 : 3.5) : 0,
          width: rects[i].width * (key == 'ffScrapbook' ? 1.08 : 1),
          height: rects[i].height * (key == 'ffScrapbook' ? 1.08 : 1),
          shadow: key == 'ffScrapbook',
          borderWidth: key == 'ffScrapbook' ? 3 : 0,
        ),
    ]);
  }

  static DesignLayer frame(Rect rect, int index, PhotoAsset? photo) =>
      DesignLayer(
        id: const Uuid().v4(),
        type: DesignLayerType.photo,
        photoId: photo?.id,
        photoSlot: index,
        empty: photo == null,
        x: rect.center.dx,
        y: rect.center.dy,
        width: rect.width,
        height: rect.height,
        z: index,
        shadow: false,
        radius: 2,
        imageTransform: photo?.transform ?? PhotoTransform.identity,
        adjustments: photo?.adjustments ?? const PhotoAdjustments(),
      );

  static List<Rect> gallery(int count) {
    if (count == 0) return [];
    final columns = math.max(1, math.sqrt(count * 9 / 16).ceil());
    final rows = (count / columns).ceil();
    return [
      for (var i = 0; i < count; i++)
        _inset(Rect.fromLTWH((i % columns) / columns, (i ~/ columns) / rows,
            1 / columns, 1 / rows))
    ];
  }

  // Equal physical horizontal/vertical gaps on the default 9:16 story canvas.
  static Rect _inset(Rect r) => Rect.fromLTRB(
      .02 + r.left * .96 + .004,
      .012 + r.top * .976 + .00225,
      .02 + r.right * .96 - .004,
      .012 + r.bottom * .976 - .00225);

  static List<Rect> mosaic(int count) {
    final regions = <(Rect, bool)>[
      (const Rect.fromLTWH(0, 0, .64, .34), true),
      (const Rect.fromLTWH(.64, 0, .36, .17), false),
      (const Rect.fromLTWH(.64, .17, .36, .17), false),
      (const Rect.fromLTWH(0, .34, .25, .24), false),
      (const Rect.fromLTWH(.25, .34, .45, .24), false),
      (const Rect.fromLTWH(.70, .34, .30, .24), false),
      (const Rect.fromLTWH(0, .58, .55, .42), true),
      (const Rect.fromLTWH(.55, .58, .45, .21), false),
      (const Rect.fromLTWH(.55, .79, .45, .21), false),
    ];
    while (regions.length < count) {
      var index = -1, area = -1.0;
      for (var i = 0; i < regions.length; i++) {
        final r = regions[i].$1;
        if (!regions[i].$2 && r.width * r.height > area) {
          index = i;
          area = r.width * r.height;
        }
      }
      final r = regions.removeAt(index).$1;
      final vertical = r.width * 9 / 16 > r.height;
      regions.insertAll(
          index,
          vertical
              ? [
                  (Rect.fromLTWH(r.left, r.top, r.width / 2, r.height), false),
                  (
                    Rect.fromLTWH(r.center.dx, r.top, r.width / 2, r.height),
                    false
                  ),
                ]
              : [
                  (Rect.fromLTWH(r.left, r.top, r.width, r.height / 2), false),
                  (
                    Rect.fromLTWH(r.left, r.center.dy, r.width, r.height / 2),
                    false
                  ),
                ]);
    }
    return regions.map((r) => _inset(r.$1)).toList();
  }
}
