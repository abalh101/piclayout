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
- Custom layouts with draggable dividers, local reuse, undo/redo and PNG/JPEG export.
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

## Background & Style Studio

Open **Style** in the editor. The scrollable sheet has Hintergrund, Rahmen,
Schatten and Presets tabs and updates the collage live. Backgrounds: solid,
two-color directional gradient, photo blur, procedural paper / soft grid / dots,
and transparent. PNG preserves transparency; JPEG composites onto white. The
checkerboard and selection outlines are preview-only. The export sheet explains
the format difference.

Blur supports the first photo, currently active photo or any numbered photo,
strength, darken/lighten and reduced saturation. Its source is a **photo position**,
not a file path or photo ID. Reordering changes that position's source; applying a
template to fewer photos clamps it to the last available photo. No photos means
the configured solid background is used. Originals are only read, never rewritten.

Presets: **Clean White, Dark Mood, Soft Cream, Instagram Pop, Minimal Black,
Travel Bright, Blur Poster**. Presets and Reset preserve photos, order, text,
layout and stagger offset. Reset restores default canvas settings. Style changes,
preset application and Reset support Undo/Redo; a slider gesture is one action.
Existing autosave and “Als Vorlage speichern” include all new canvas settings.
Templates and built-in presets contain no image files or image paths.

Implementation and changed files:

- `lib/features/collage_editor/models/canvas_style.dart` (new),
  `canvas_settings.dart`, `style_presets.dart` (new): version-compatible optional
  style JSON; old projects retain their original solid background.
- `lib/features/collage_editor/rendering/style_renderer.dart` (new),
  `project_image_loader.dart` (new), `layout_geometry.dart`: shared canvas rendering,
  bounded decoding, consistent scale relative to a 390-unit short canvas edge.
- `lib/features/collage_editor/widgets/styled_collage_scene.dart` (new),
  `style_studio_sheet.dart` (new), `collage_canvas.dart`: cached preview, controls,
  separate editor-only hit targets and selection outlines.
- `lib/features/collage_editor/state/collage_editor_controller.dart`,
  `lib/features/collage_editor/editor_page.dart`: integration, Reset and grouped undo.
- `lib/features/export/collage_exporter.dart`,
  `lib/features/export/widgets/export_center.dart`: shared rendering and transparent
  format feedback. Social sharing and gallery storage keep their existing flow.
- `test/style_studio_test.dart` (new), this `README.md`.

Preview decoding is capped at 1024 pixels on the long edge, cached by project file
path and released when removed or disposed. Slider changes do not decode photos.
Export decodes background photos up to 2048 pixels; foreground photos use original
resolution. Both call the same StyleRenderer and TextOverlayRenderer, rendering
from saved files, not a screenshot. Blur sharpness may differ slightly because of
preview resolution. Frames and shadows use the union of rounded photo cells:
separate cells have separate outlines; touching cells share an outside outline,
without doubled internal edges. Background patterns are generated locally.

Validation: `dart format .`, `flutter analyze`, `flutter test` (33 passing tests).
Seven new tests cover legacy JSON, full style round-trip and private-free
saved templates, presets/source bounds, grouped undo/reset, shared-edge contours,
actual PNG/JPEG pixels (including patterns and unchanged originals), plus a
320×640 sheet with preset application/autosave/reset. Existing text, template,
favorite, variation and social-export tests remain green.
`flutter build apk --debug` was attempted: **No Android SDK found**. Native Android
and iOS rendering/performance remain unverified in this Linux environment.

Manual device checks for this feature:

1. Compare editor and PNG/JPEG exports for every background, aspect ratio, rotated
   or mirrored photo, fit/fill, frame and shadow; check touching and staggered cells.
2. Check blur on 12 large photos, rapid slider gestures, switching source, removing
   photos, editor reopen/background-resume and repeated exports for memory/jank.
3. Check transparent PNG edges in an alpha-aware viewer and white JPEG backing;
   gallery and social target apps may display transparency differently.
4. Verify text stays above styles, selection borders/checkerboards never export,
   save/restart/reopen and template application with different photo counts.
5. Check small screens, large system font, landscape, dark mode, tab scrolling,
   live preview visibility and Undo/Redo after preset, slider and Reset operations.

## Einstellungen, Sprachen und Foto-Filter

Die App bietet lokal gespeicherte Einstellungen, sechs manuell wählbare Sprachen
(inklusive Arabisch/RTL), Problem melden per E-Mail sowie nicht-destruktive
Foto-Filter mit Undo/Redo und Autosave. Bedienung, Datenmodell, Rendering,
Gerätetests und die zu ersetzende Support-Adresse sind in
[docs/settings-and-photo-editing.md](docs/settings-and-photo-editing.md) beschrieben.

## Eigene Layouts

Im Editor öffnet **Eigenes Layout** den Layout-Editor. Dort lassen sich eine
Ausgangsaufteilung wählen und innere Trennlinien per Griff oder Schieberegler
verschieben. Durch Antippen einer Zelle erscheinen ihre verstellbaren Grenzen.
Jede Zelle behält mindestens 12 % der Breite und Höhe der inneren Collagefläche;
die Aufteilung bleibt lückenlos und ohne Überlappungen. Nicht geeignete
Ausgangslayouts werden mit einem Hinweis durch eine passende Aufteilung ersetzt.

**Fertig** übernimmt den Entwurf als einen rückgängig machbaren Schritt und löst
Autosave aus. Zurück oder Abbrechen verwirft den Entwurf; Zurücksetzen stellt den
Zustand beim Öffnen wieder her. **Als Layout speichern** speichert separat eine
benannte Kopie in der lokalen Layout-Bibliothek, auch ohne den Entwurf zu übernehmen.
Unter **Eigene Layouts** erscheinen die gespeicherten Layouts für die aktuelle
Fotoanzahl. Sie enthalten nur Aufteilung und Metadaten, keine Fotos oder Dateipfade.

Eigene Layouts sind zusätzlich im Projekt und in gespeicherten Designvorlagen
enthalten. Foto-Reihenfolge, Zuschnitt, Filter, Text und Stil bleiben beim Anwenden
erhalten. Ein Standardlayout oder eine Layout-Variation ersetzt die eigene
Aufteilung. Ändert sich die Fotoanzahl, greift ein passendes Standardlayout;
Undo stellt die vorherige Aufteilung wieder her. Vorschau und PNG/JPEG-Export
verwenden dieselbe Geometrie. Bei engen Zellen wird der Abstand begrenzt, damit
die Bildflächen eine positive Größe behalten.

Automatisierte Tests prüfen Geometrie einschließlich zufälliger Verschiebungen,
Speicherung und Fehlerfälle, Projekt- und Vorlagenkompatibilität, Undo/Redo,
Export-Pixel sowie die Bedienung auf einem 320-Pixel-Bildschirm in allen sechs
Sprachen einschließlich Arabisch/RTL. Auf echten Geräten sind Touch-Bedienung,
große Systemschrift und die Leistung mit zwölf hochauflösenden Fotos noch zu prüfen.

Validierung dieses Arbeitsstands: `flutter analyze` ohne Befunde,
`flutter test` mit 59 erfolgreichen Tests.

## Sticker, Emojis und Formen

Der Editor bietet einen lokalen Sticker-Katalog mit 23 Emojis, Formen, Symbolen
und Textlabels. Sticker unterstützen Verschieben, Skalieren, Drehen, Farbe,
Deckkraft, Duplizieren, Reihenfolge, Undo/Redo und Autosave. Vorlagen können Sticker
optional übernehmen; alle Exportwege zeichnen sie mit demselben Renderer.
Bedienung, Ebenenfolge, Dateiliste, Tests und Geräteprüfung stehen in
[docs/stickers.md](docs/stickers.md).

## Projektdateien sichern und übertragen

**Projekt exportieren** im Projektkarten- oder Editor-Menü erstellt eine
bearbeitbare `.piclayout`-Datei und öffnet das Teilen-Menü. **Projekt importieren**
auf der Startseite legt daraus ein neues lokales Projekt an. Das ZIP-basierte
Format enthält versioniertes JSON und portable PNG-Kopien mit relativen Pfaden;
Text, Sticker, Filter, Stil und eigene Layouts bleiben editierbar.
Format, Größenlimits, Dateiliste und Geräteprüfungen:
[docs/project-archives.md](docs/project-archives.md).

## Onboarding, Beispielprojekte und Einstiegstipps

Beim ersten Start erklärt eine überspringbare Einführung die fünf wichtigsten
Schritte. Fünf lokale Beispielprojekte sind über Startseite, Einführung und
Einstellungen erreichbar; jedes Öffnen erstellt eine unabhängige bearbeitbare
Kopie. Sechs abstrakte, nummerierte PNGs unter `assets/demo/` benötigen zusammen
nur rund 23 KiB. Dezente Editor- und Exporttipps erscheinen höchstens zweimal
pro Thema, sind schließbar und lassen sich in den Einstellungen zurücksetzen.
Dort kann auch die Einführung erneut geöffnet werden.

Alle neuen Texte sind in sechs Sprachen verfügbar, einschließlich Arabisch/RTL.
Bedienung, Speicherung, Asset-Generator und Gerätecheckliste stehen in
[docs/onboarding-and-examples.md](docs/onboarding-and-examples.md).
Validierung: `dart format .`, `flutter analyze` ohne Befunde und `flutter test`
mit **84 erfolgreichen Tests**. Der Android-Debug-Build wurde versucht und
scheiterte am fehlenden Android SDK.

## Smart Auto Layout und Empfehlungen

Der Layout-Bereich zeigt drei lokal berechnete Empfehlungen mit schematischen
Vorschauen und kurzen Begründungen. **Auto Layout** übernimmt die beste Wahl als
einen Undo-Schritt, ohne Foto-Reihenfolge, gespeicherte Zuschnitte, Filter, Text,
Sticker oder Style zu verändern. Im Foto-Auswahlschritt lassen sich Zielformat
und Empfehlung bereits vor der Projekterstellung wählen.

Die Regeln berücksichtigen Fotoanzahl, lokale Bildabmessungen, Editor-Drehung,
Zielformat, Zellproportionen und Flächennutzung. Dazu kommen Boni für Story-Raster,
Hoch-/Querformat, gemischte Formate und passende Hero-Fotos. Alte Projekte bleiben
kompatibel; fehlende Abmessungen werden beim Öffnen im Editor lokal nachgeladen.
Keine Cloud, Motiverkennung oder KI-API. Regeln, Dateien, Tests und Geräteprüfungen:
[docs/smart-auto-layout.md](docs/smart-auto-layout.md).

Validierung für Smart Auto Layout: `dart format .` erfolgreich,
`flutter analyze` ohne Befunde und `flutter test` mit **95 erfolgreichen Tests**.
`flutter build apk --debug` scheiterte am fehlenden Android SDK.
