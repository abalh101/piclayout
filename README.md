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

- Direct save into the system photo gallery. The app exports to a temporary file and opens the native share sheet.
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

iOS builds require macOS, Xcode, CocoaPods, a valid Apple Developer Team, and normal signing configuration. Do not store certificates or private keys in this repository. Photo picking uses the native photo picker; the iOS photo library purpose string is in `ios/Runner/Info.plist`. No Android storage permission is required for the current picker and share sheet flow.

## Suggested Next Steps

1. Configure unique Android application ID, iOS bundle identifier, release signing, and store icons before publishing.
2. Test the picker, editor, export, and share sheet on real Android and iOS devices.
3. Add direct gallery saving if the product should offer it beyond export through the share sheet.
4. Improve crop clamping so fill mode never reveals empty areas.
