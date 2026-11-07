import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('generated icon assets match iOS catalog and Android configuration', () {
    const root = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
    final catalog = jsonDecode(File('$root/Contents.json').readAsStringSync())
        as Map<String, dynamic>;
    for (final item in catalog['images'] as List) {
      final image =
          img.decodePng(File('$root/${item['filename']}').readAsBytesSync())!;
      final points = double.parse((item['size'] as String).split('x').first);
      final scale = double.parse((item['scale'] as String).replaceAll('x', ''));
      expect(image.width, (points * scale).round());
      expect(image.height, image.width);
      expect(image.numChannels, 3, reason: 'iOS icons must be opaque');
    }
    for (final density in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
      final size = {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192
      }[density]!;
      final icon = img.decodePng(
          File('android/app/src/main/res/mipmap-$density/ic_launcher.png')
              .readAsBytesSync())!;
      final foreground = img.decodePng(File(
              'android/app/src/main/res/mipmap-$density/ic_launcher_foreground.png')
          .readAsBytesSync())!;
      expect([icon.width, icon.height], [size, size]);
      expect([foreground.width, foreground.height],
          [(size * 108 / 48).round(), (size * 108 / 48).round()]);
      expect(
          File('android/app/src/main/res/mipmap-$density/ic_launcher.png')
              .existsSync(),
          isTrue);
      expect(
          File('android/app/src/main/res/mipmap-$density/ic_launcher_foreground.png')
              .existsSync(),
          isTrue);
    }
    expect(
        File('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml')
            .readAsStringSync(),
        contains('adaptive-icon'));
    expect(File('README.md').readAsStringSync(),
        contains('python3 tool/generate_icons.py'));
    for (final folder in ['drawable', 'drawable-v21']) {
      expect(
          File('android/app/src/main/res/$folder/launch_background.xml')
              .readAsStringSync(),
          contains('?android:colorBackground'));
    }
  });
}
