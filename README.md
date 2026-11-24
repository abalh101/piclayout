# PicLayout

PicLayout is a local-first Flutter collage editor for Android and iOS. Pick and reorder 1–12 photos, compose them with a grid or a free canvas, then export an image or save a portable project for later editing.

## Editing

- **Grid and Freestyle.** Choose automatic, built-in, or custom grid layouts. In Freestyle, drag, pinch, rotate, or resize each photo with its handle. Alignment guides can snap to the canvas and other visible photos. Per-photo opacity, corners, borders, and shadows are available in the photo controls.
- **Formats.** Choose a standard or social preset, or enter a custom width and height. Custom ratios accept 1:4–4:1, with a live shape preview, orientation swap, recent ratios, and favorites.
- **Photo adjustments.** Use fit or fill, zoom, pan, flip, and quarter-turn rotation. Edit exposure, brightness, contrast, saturation, warmth, highlights, shadows, sharpness, and vignette. Grayscale and sepia are available as presets. Compare with the original, reset individual controls, copy and paste adjustments, or apply a draft to all editable photos.
- **Layers and styles.** Style Studio offers backgrounds, patterns, blur, and grid styling. Add text, stickers, and shapes. The Layers sheet manages visibility, locks, ordering, duplication, and deletion for overlay layers and Freestyle photos. Grid photos stay in the grid and can be reordered from the photo strip.
- **Design library.** Browse six built-in designs and your own templates. Search, filter by aspect ratio or photo count, and browse favorites and recently used designs. Templates store geometry and style, with optional text and stickers. They contain no photos, image paths, or photo IDs.
- **Smart Auto Layout.** Local geometry rules recommend layouts based on the original dimensions, photo order, rotation, and target canvas. Browse Best fit, Minimal crop, Balanced, Featured photo, and Creative. Recommendations preserve photo edits and overlay content.
- **Projects.** Reopen, rename, duplicate, or explicitly delete local projects. Undo, redo, and autosave apply to both modes. Versioned `.piclayout` archives let you move an editable project between devices.

PicLayout works offline. Imported originals remain unchanged. The UI supports German, English, Arabic (RTL), Turkish, French, and Spanish.

## Export Center

Export PNG or JPEG to the gallery or system share sheet. The export preview shows the selected output ratio and includes adjustments, backgrounds, text, and stickers. There are current-ratio sizes, social presets, and custom dimensions up to 4096 pixels per side. JPEG quality can be changed per export. PNG supports transparency. JPEG composites onto white.

Social presets include 1080 × 1920 for Stories and status, 1080 × 1080 and 1080 × 1350 for posts, and 1280 × 720 for a YouTube thumbnail. Android can hand an image to a supported installed app and falls back to the system share sheet when needed. iOS uses the system share sheet. The destination app handles publishing.

Export renders from project image files with the shared photo geometry and styling code. The chosen export ratio can reflow the composition. PicLayout leaves the saved project at its existing ratio.

## Development and releases

Use Flutter and the Android SDK for Android development. iOS builds require macOS and Xcode.

```bash
flutter pub get
dart format .
flutter analyze
flutter test
flutter build apk --debug
```

Run on a configured device with `flutter run`. Before a store release, configure the real support email in `lib/app/app_config.dart`, replace the example Android application ID and iOS bundle identifier with the intended production identifiers, and configure release signing. The repository currently uses Android debug signing in the release block. App version and build number come from `pubspec.yaml`.

The native picker, Android MediaStore and Android 9 legacy gallery path, iOS Photos add-only authorization, and native share integrations are described in the device checklist. Real gallery, picker, and social handoffs need device verification.

The icon and demo assets are generated locally. With Python 3 and Pillow installed, regenerate them with the following commands.

```bash
python3 tool/generate_icons.py
python3 tool/generate_demo_assets.py
```

## Further documentation

- [Editor, rendering, recovery, and device checklist](docs/editor-and-export.md)
- [Settings, languages, and photo adjustments](docs/settings-and-photo-editing.md)
- [Smart Auto Layout](docs/smart-auto-layout.md)
- [Stickers, shapes, and labels](docs/stickers.md)
- [Editable project archives](docs/project-archives.md)
- [Onboarding and examples](docs/onboarding-and-examples.md)
