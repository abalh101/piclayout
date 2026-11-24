# Editor, export, and recovery

## Freestyle and the layer panel

Choose Freestyle in the editor. The first switch seeds each photo from its grid cell. Grid remains available, and switching back to Freestyle restores the previous placements. Selecting a photo shows its outline and resize handle. Drag to move. Pinch or rotate with two fingers. Double-tap to open photo controls. The central axes, canvas edges, and nearby visible photo bounds can provide alignment guides. The Snap to guides chip controls snapping for the editing session.

Placement is relative to the canvas on both axes. Photos keep their source proportions inside the placement frame using fit or fill. A different canvas ratio can change the shape of a frame and its crop. Fit centers the whole rotated photo. Fill clamps pan to the area that can cover the cell, including after rotation, mirroring, changing layouts, or changing the canvas ratio. Previous fill offsets and zoom remain available when switching back from fit. A continuous gesture records one undo step.

Freestyle photos are painted back to front in project photo order. They support opacity, rounded corners, a white frame, a shadow, replacement, and duplication. Add photos up to a total of 12. Every collage retains at least one photo. Styles such as blur and patterns apply to the full canvas. Grid frames and shadows are managed in Style Studio. Freestyle frames and shadows are managed per photo.

The Layers panel lists stickers and shapes above text, above photos. You can select, show, hide, lock, unlock, duplicate, delete, and move elements within their respective groups. Grid photos use their cell order and can be reordered via the photo strip. Reordering Freestyle photos also changes the order used if you switch back to Grid. The opacity and visibility state of a Freestyle photo is used when rendering that mode. A hidden photo is omitted from the Freestyle composition and cannot act as the blur source.

## Formats, adjustments, and templates

The ratio picker accepts integer width and height from 1 to 10,000, with a ratio between 1:4 and 4:1. Equivalent inputs share one normalized ID. Recents and favorites each retain eight ratios. Arabic and Persian numerals are accepted. The project stores the normalized ratio ID. A template keeps the same ratio and, for Freestyle designs, placement data keyed by photo position. If a template has fewer positions than the destination project has photos, additional photos receive a centered default placement.

The adjustment sheet stages edits until Done. It supports a preview of the unadjusted image, copying and pasting within the editor session, individual resets, and application to all editable photos in one undo step. Exposure uses a gain. Highlights, shadows, and sharpness use a shared Flutter fragment shader. Vignette draws a radial falloff within the visible photo. Projects and archives store optional adjustment values. Older projects retain neutral defaults. Preset intensity controls grayscale and sepia with the other filters.

The six built-in templates are procedural and offline. They cover before/after, magazine, travel, geometric, instant prints, and photo diary compositions. Favorite and recently used templates are stored locally. Search and filters work across the current library view.

## Export and memory

Export uses the selected aspect ratio and renders before native gallery or share handoff. A preview includes the background, photos, text, stickers, and shapes. PNG keeps alpha where the canvas requests transparency. JPEG uses a white backing and its own 1–100 quality slider. Custom export dimensions allow 1–4096 pixels per side, with a ratio from 1:4 through 4:1. Main photo decodes are sized to the projected raster footprint, including the crop zoom. Zoomed large photos can still require large decodes. The export backdrop has its own 2048-pixel decode cap. JPEG encoding runs off the UI isolate. Native handoffs and rendering are guarded against repeated taps. Once started, an export runs through completion or error.

Preview decoding uses at most two concurrent loads per scene and caches by file path. The editor caps previews at 1024 pixels on the long edge, with smaller limits on recent cards and export/adjustment previews. The background has a separate repaint boundary so foreground gestures can reuse the backdrop. Pointer updates repaint the canvas without recalculating the layout recommendations on every move. After exporting, PicLayout removes its own cached image exports that are more than two days old.

## Project recovery

The repository serializes writes for each project. It writes and flushes a pending metadata file, then renames it over the primary. A previous valid snapshot remains in `project.json.bak`. When the primary cannot be read, PicLayout tries the backup and then a complete pending snapshot. It reports recovery in the editor. Missing photos remain listed with placeholders. Replace the image before exporting a visible missing layer. Autosave flushes on leave or when the editor goes inactive. A save error in the editor offers a retry. Metadata files that cannot be parsed from any snapshot remain on disk for recovery outside the app.

Project metadata is version 1 with additive fields. Freestyle positions travel with the corresponding photo during duplication, replacement, storage, and archive import. Archive import gives projects and photos new IDs. Archive extraction uses a bounded allowlist and staging directory. See the [archive format and limits](project-archives.md).

## Validation

The baseline passed 95 tests with Flutter 3.47.5 and Dart 3.13.4. The updated suite passed 116 tests, including crop geometry for all four rotations, Freestyle projects with 1–12 photos, PNG/JPEG pixel assertions, project recovery, archive round-trips, and Arabic RTL widget tests. `flutter pub get`, `dart format .`, `flutter analyze`, and `git diff --check` succeeded. Static analysis reported no issues.

The Android debug build produced `build/app/outputs/flutter-apk/app-debug.apk`. Its manifest reports version `0.1.0` with build number `1`, minimum API 24, and target API 36. Gradle reports a future built-in Kotlin migration for the existing `package_info_plus` and `share_plus` plugins.

The iOS Info.plist parsed successfully. This Linux host has no Xcode and no connected mobile devices, so iOS compilation and native picker, gallery, and sharing checks require the device checklist.

## Device checklist

1. On Android and iOS, use the native picker with 1, 2, and 12 images. Include EXIF rotation, HEIC where supported, large panoramas, and a mix of portrait and landscape.
2. In Grid, test edge pans, pinch zoom, rotation, mirroring, and toggling fit/fill. Change the layout and ratio, export, and compare crop edges and photo order.
3. In Freestyle, test dragging and snapping, resizing at the handle, rotating with two fingers, locked and overlapping layers, replacement, and the 12-photo limit. Verify one-step undo and restore via redo.
4. Use custom ratios, favorites, and portrait/landscape swap. Search and favorite a template, reopen the library, apply a different photo count, and compare preview, undo, and exported output.
5. Compare photo adjustments and shader output in PNG/JPEG on target Android and iOS devices. Include edge sharpness, shadow and highlight controls, transparent images, and large blurred backgrounds.
6. Put the app in the background while editing and reopen it. Test missing project images and low storage on a disposable test project. Verify the previous snapshot remains readable and archive transfers preserve effects and placement.
7. Save PNG/JPEG to the gallery with permission granted and denied, including the Android 9 legacy path where supported. Check repeated taps, app backgrounding, the iPad share popover, installed and absent social apps, and the share fallback.
8. Test a small phone, tablet, and landscape, with the largest system font, a screen reader, light and dark themes, and Arabic RTL. Check that the keyboard and sheets leave all primary actions reachable.
9. Profile interaction with twelve full-resolution photos, a blur background, multiple overlays, and repeated maximum-size exports on a memory-constrained device.
