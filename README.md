# PicLayout

PicLayout is a local-first Flutter photo collage editor for iOS and Android.

The app focuses on the core workflow:

1. Pick 1 to 12 photos.
2. Confirm or reorder the selection.
3. Choose an aspect ratio and layout.
4. Adjust image crop, zoom, spacing, margin, corners, background, and staggered layouts.
5. Export as PNG or JPEG and share through the native share sheet.

## Current Status

The Android and iOS platform projects are included. The source is formatted, `flutter analyze` reports no issues, and `flutter test` passes with Flutter 3.47.5 / Dart 3.13.4.

Implemented:

- Start page with recent local projects.
- Native photo picking through `image_picker`.
- Selection review with drag-and-drop ordering and numeric positions.
- Local project storage in the app documents directory.
- Project rename, duplicate, and delete.
- Editor for aspect ratio, layout, spacing, outer margin, corner radius, background color, and stagger amount.
- Photo selection, pan, zoom, fill/fit, reset, rotate, flip, replace, remove, and thumbnail reordering.
- Undo and redo for editor changes.
- Text overlays with drag, rotation, size, color, background, alignment, undo/redo, and project persistence.
- Locally saved favorite layouts and reusable design templates without photos or image paths.
- Undoable layout variation that keeps photo order, canvas style, and text.
- Data-driven layout library with classic grids, uneven rows, hero layouts, and staggered two-column layouts.
- PNG and JPEG export from original local image files, not from a screen screenshot.
- German and English app strings.
- Layout tests for the most fragile geometry rules.

Not implemented yet:

- Platform gallery and social sharing still require the device checks below.
- Custom aspect ratio entry.
- High-fidelity crop boundary clamping for every rotation/fit combination.
- Production signing, bundle identifiers, store assets, and release settings.

## Setup

Install Flutter and the Android SDK. From this folder run:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Run on Android:

```bash
flutter run
```

Run on iOS:

```bash
flutter run -d ios
```

iOS builds require macOS, Xcode, CocoaPods, a valid Apple Developer Team, and normal signing configuration. Do not store certificates or private keys in this repository. Photo picking uses the native photo picker; the iOS photo library purpose string is in `ios/Runner/Info.plist`. Android 10+ gallery saving uses MediaStore without storage permission; Android 9 and earlier request WRITE_EXTERNAL_STORAGE (limited to maxSdkVersion 28). iOS includes NSPhotoLibraryAddUsageDescription.

## Suggested Next Steps

1. Configure unique Android application ID, iOS bundle identifier, release signing, and store icons before publishing.
2. Test the picker, editor, export, and share sheet on real Android and iOS devices.
3. Complete gallery permission and social destination tests below.
4. Improve crop clamping so fill mode never reveals empty areas.


## Export Center and gallery

The Export Center offers Gallery, general sharing, Instagram Story, Instagram Post,
Snapchat, TikTok/Reels, WhatsApp Status, Facebook and Other App. General sharing
and Gallery also expose a YouTube thumbnail preset. PNG/JPEG and pixel dimensions
are shown before export. The original 1080/1440/2160 short-side sizes remain available.

| Preset | Output |
| --- | --- |
| Instagram/Snapchat Story, TikTok/Reels, WhatsApp Status | 1080 × 1920 (9:16) |
| Instagram/Facebook square | 1080 × 1080 (1:1) |
| Instagram/Facebook portrait | 1080 × 1350 (4:5) |
| YouTube thumbnail | 1280 × 720 (16:9) |

The exporter reflows a copy into the requested dimensions and renders from the
project image files with text overlays. It never captures the preview. It does not
change the project, original files, photo order, saved transforms, templates or favorites.
A warning appears for aspect ratios that differ by more than 20%; crops and text
placement can change in the export. Final publishing always happens in the target app.
The export lock spans rendering, saving and sharing, and is released on error.

Android attempts documented ACTION_SEND image sharing to installed target packages.
This opens the target's supported image import flow, not necessarily its Story/Status
screen. Unsupported image sharing or a missing activity falls back to share_plus.
iOS uses the system activity sheet, with a source rectangle for iPad popovers.
Instagram, Snapchat, WhatsApp and Facebook have installation probes; TikTok on iOS
returns unknown and uses the sheet without claiming it is absent. Alternative app
editions may require choosing the app manually. A detected missing app is reported.
No private publishing API, account, developer social SDK or automatic upload is used.

GallerySaveService is separate from CollageExporter. Its native MethodChannel uses:

- Android 10+: MediaStore pending insertion into Pictures/PicLayout, finalized only
  after copying succeeds. Failed pending entries are removed.
- Android 9 and earlier: runtime storage permission, a unique Pictures/PicLayout
  file and MediaScannerConnection.
- iOS 14+: Photos add-only authorization and PHPhotoLibrary.performChanges.
  Older iOS uses the photo-library authorization fallback.

Permission denial, missing files, unavailable gallery and saving failures become
readable messages. On success the sheet closes and shows “In Galerie gespeichert”.

Official platform references:
[Android file sharing](https://developer.android.com/training/secure-file-sharing),
[Android MediaStore](https://developer.android.com/reference/android/provider/MediaStore.Images.Media),
[Apple Photos](https://developer.apple.com/documentation/photos/phphotolibrary),
[Apple app availability](https://developer.apple.com/documentation/uikit/uiapplication/canopenurl(_:)),
[share_plus 10.1.4](https://pub.dev/packages/share_plus/versions/10.1.4).

## App icon generation

The logo is an original geometric 2×2 collage mark, authored as code. No downloaded
brand assets or image-generation service is used. Regenerate all assets with:

```bash
# Requires Python 3 and Pillow (tested with Pillow 10.2.0).
python3 tool/generate_icons.py
```

The script defines the geometry and emits:

- assets/branding/app_logo.svg — editable vector logo.
- assets/branding/app_icon.png — opaque 1024×1024 master.
- assets/branding/app_logo.png — rounded transparent logo used in the app.
- assets/branding/adaptive_foreground.png — transparent Android foreground.
- android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png
  and ic_launcher_foreground.png.
- android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml and
  values/icon_colors.xml — adaptive icon configuration.
- Every PNG referenced by ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json,
  including the opaque 1024×1024 App Store icon.

Keep changes in tool/generate_icons.py; SVG and raster files are generated together.
No launcher-icon dependency is needed. iOS applies its own rounded mask.

## Export validation and device checks

Dart tests cover preset dimensions, gallery fakes and error mapping, missing-app
messages, direct-share fallback, duplicate-export prevention, lock release after
failure, project preservation, PNG/JPEG text rendering, and a small export screen
in light and dark mode. Native platform code is not validated by flutter analyze.

This Linux environment has no Android SDK or connected Android/iOS device.
`flutter build apk --debug` was attempted and stopped with “No Android SDK found”.
An iOS build requires macOS/Xcode; the new Kotlin and Swift paths still need builds
and device validation before release.

On actual devices check:

1. Android 10+ and Android 9: PNG/JPEG save, gallery visibility, permission denied
   and granted, storage unavailable/full, and reopening the saved image.
2. iPhone/iPad: add-only permission denied/granted, repeated save, exact dimensions,
   text overlays, Share Sheet popover placement and cancellation.
3. Each social app installed and absent: direct image import on Android, fallback,
   readable missing-app message, choosing Story/Post/Status in the target app.
4. Repeated rapid export taps, backing out during export, app background/resume,
   large photos, and unchanged project after selecting a different export ratio.
5. Small screens, large system text, landscape, dark mode and keyboard dismissal.
6. Android round/squircle launcher masks and iOS home-screen/App Store icon appearance.
