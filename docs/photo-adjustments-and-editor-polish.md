# Photo Adjustments Studio

## Implementation plan and audit (2026-11-13)

Initial working tree clean; no AGENTS.md found in the workspace or ancestors.
Reuse PhotoAdjustments, StyleRenderer.photo, PhotoFilterRenderer, the bounded
StyledCollageScene decoder, controller gesture history, and archive serializers.
Extend optional adjustment fields without changing the project format version.
Keep the existing staged photo editor available; add a live Adjust studio.

Risks: changing matrix order would alter legacy projects; retained pictures can
hold native image memory even after image handles are disposed; slider frames
must not enqueue saves; interrupted replacement must retain valid project JSON.
Focused tests: serialization/archive/reopen, original bytes, grouped history,
shared rendering pixels, comparison isolation, cache lifetime, responsive UI,
and recovery. Existing crop, editorial, style and Windows cleanup tests remain
required regression coverage.

## Model and behavior

Open **Adjust** from the horizontally scrollable editor tool row. The existing
staged **Edit photo** dialog remains available. Adjust is live: Done closes it;
Undo reverses edits. It supports previous/next, session-local copy/paste, apply to
all, reset selected, and confirmed reset all. Apply-to-all synchronously changes
at most 12 adjustment objects; repeated identical actions add no history. Crops,
transforms, layout, order, text, stickers and canvas settings are untouched.

`PhotoAsset.adjustments` remains optional, version-1-compatible JSON. Numbers are
finite-checked and clamped. Unknown fields are ignored and unknown presets fall
back to Original. No original image is rewritten or recompressed.

| Setting | Stored range | Neutral |
| --- | --- | --- |
| Brightness, warmth, tint, highlights, shadows | -1…1 | 0 |
| Contrast, saturation | 0…2 | 1 |
| Fade, black point, vignette | 0…1 | 0 |
| Preset intensity | 0…1 | 1 |

Sliders show percentage-scale numbers; contrast/saturation show 0 at their neutral
stored value of 1. Each has a labeled reset. Style Studio uses the same component
with its original units/defaults. New strings cover all six locales. Controls use
Material touch sizes; selections use checks as well as color.

The existing gesture API cancels autosave during live updates, records one changed
snapshot at gesture end, and resumes the 700ms debounce. Paste/reset/apply-all each
use one history mutation. Ending a nonexistent gesture no longer schedules a save.
Sheet dismissal finishes active gestures; repository write serialization and final
editor-disposal saving remain intact.

Hold **Hold for before**, or toggle **Show before** for accessibility. Pointer
up/cancel restores the edited preview; navigation/dismissal clears comparison.
Comparison creates a view-local project copy never passed to the controller,
repository or exporter. Tests cover comparison-only dismissal without autosave.

## Shared processing order

Standard cells and editorial photo/callout layers call `StyleRenderer.photo`.
The legacy order is preserved so old projects keep their appearance:

1. Decode the saved original, including decoder-supported orientation.
2. Resolve source crop, rotation, flip, pan and fit/fill with existing PhotoCrop.
3. Sample the source; apply preset/intensity followed by the existing combined
   brightness/contrast/saturation/warmth matrix, then clamp RGB.
4. Tint adds `value * (0.06, -0.06, 0.06)` to straight RGB.
5. Luminance uses `(0.2126, 0.7152, 0.0722)`. Highlight weight is
   `smoothstep(.45, 1, luminance)`; shadow weight is
   `1 - smoothstep(0, .55, luminance)`. Each adds its signed value × weight × .35.
6. Black point remaps `(rgb - .25 * value) / (1 - .25 * value)` with a zero floor;
   fade mixes toward middle gray with weight `.4 * value`.
7. Vignette smoothly darkens sampled source-crop corners up to 75%, follows the
   photo transform, and is clipped to the cell.
8. Clamp and premultiply by source alpha, then composite masks, frames, editorial
   layers, text and stickers in their existing order. Canvas blur backgrounds
   retain their independent original-photo style settings.

One Flutter fragment shader implements the new operations. Its uniforms use
`PhotoAdjustments` and the existing `PhotoFilterRenderer.matrix`. Preview and
PNG/JPEG use the same path; there is no second CPU implementation. All new values
neutral use the original ColorFilter/drawImageRect path exactly. PNG preserves
alpha; JPEG retains white backing and isolate encoding. Pixel tests compare both
codecs with the shared preview renderer, allowing JPEG compression tolerance.
Highlights/shadows are tonal edits, not recovery of clipped sensor data.

## Cache and export memory

`PreviewImageCache` belongs to one editor. Canvas, Adjust, legacy photo editing
and the design sheet share reference-counted leases keyed by source path. Slider
and chrome changes reuse the decoded source; replacements get new paths. Only two
decodes run concurrently, each capped at a 1024px long edge. Last-release disposes
the source and shader; abandoned queued requests are skipped and late results
disposed. No app-global queue can block a later editor.

Adjustment previews cache GPU shader configurations rather than extra processed
bitmaps. Keys include decoded source identity (owned by the path cache), every
adjustment, target size and source crop. Up to four configurations are retained per
decoded source so canvas and sheet sizes coexist without thrashing the cache;
changing one photo affects only that source's configurations. Matrix caching stays
bounded at 128 entries. Unchanged scene painters no longer repaint on selection-only
notifications. The compiled program is shared for the app lifetime.

Tests establish one decode for two simultaneous views plus 20 further leases,
at most two active decodes, independent shader invalidation, and full release.
Twelve square previews occupy at most about 48 MiB of RGBA pixels before engine
and encoded-data overhead. Opening Adjust does not duplicate that storage.
These are tested operation counts and calculated bounds, not device timing claims.

Export reads full-resolution originals, never previews or screenshots. Pictures
can retain native images after their Dart handles are disposed. Export now
rasterizes into an output-sized surface after each photo, releases the recording
and source, then decodes the next. Retained foreground originals are bounded to
one, alongside output surfaces and any bounded backdrop. Extra rasterization has
a latency cost to profile on devices. JPEG encoding remains off the UI isolate.
The existing export lock covers rendering, saving and sharing with localized
progress/failure feedback; existing duplicate-export and error tests still apply.

## Persistence, templates and UX

Serialized project saves flush JSON to `.tmp`. The previous valid primary is
flushed to `.bak.tmp` and renamed to `.bak`, then the primary is replaced by rename
without deleting it first. Failed staging preserves it. Loading tries primary,
then backup; partial temporary files are never treated as committed projects.
Missing images do not remove projects or photo slots. Localized preview failure
text and existing replacement/removal controls remain available.

Save/reopen, duplication and archives preserve all settings and filter intensity.
Portable paths and archive versions are unchanged. New templates optionally store
`photoStyles`: positional color values only, without photo IDs, filenames, paths or
transforms. Old templates without this field preserve destination edits, as do
neutral templates. Structured previews render layout, background, frames, text and
stickers using generic photo placeholders; no private image is loaded. A 32-entry
picture cache avoids regeneration during scrolling; invalid data has a fallback.
Existing layer selection, ordering, visibility, lock, duplication and deletion are
retained, with a new selected check badge. Existing 48px canvas handles remain.

## Validation and limitations

Tests cover legacy/full JSON, archives, save/reopen/duplicate, unchanged originals,
interrupted/corrupt saves, staging failure, missing images, gesture grouping,
reset/paste/apply-all, crop/layout preservation, comparison isolation, shader
PNG/JPEG pixels, cache lifetime/invalidation, all six locales at 320px/200% type
in light/dark themes, and landscape/tablet controls. Existing export-permission,
duplicate-operation, editorial and Windows cleanup regressions remain included.
No test is skipped and no cleanup failure is suppressed.

Sharpness is deliberately unavailable. Processing uses decoded sRGB-like RGB,
not a RAW/HDR photographic working space. Bounded preview sampling can differ from
full-resolution export in fine texture. Template placeholders cannot preview photo
content or photo-blur backgrounds. If both JSON generations are corrupt, the
project list still omits the project; files remain but no repair UI is added.
Power-loss directory durability depends on the filesystem. Device profiling and
native platform verification remain required.

Manual checks before release:

- Android/iPhone/iPad: controls, TalkBack/VoiceOver, hold/toggle comparison, RTL,
  large type, safe areas, landscape and tablets.
- Twelve large JPEG/HEIC images: memory/frame pacing, rapid gestures, navigation,
  sheet dismissal, replacement/removal and repeated exports.
- Preview/export agreement for rotated/flipped/cropped/transparent photos,
  editorial callouts, masks, blur backdrops and social export sizes.
- Force stop during saves/exports; storage full, missing files, permission denial,
  gallery/share cancellation, retry and background/resume.
- iOS compilation/signing and platform GPU verification. A Windows APK build
  validates compilation only. The focused emulator checks below supplement it;
  physical-device performance and iOS checks remain open.

## Android emulator follow-up (2026-11-13)

Added `integration_test/photo_adjustments_device_test.dart` and the Flutter SDK's
`integration_test` development dependency. Run on a connected Android device:

```sh
flutter test integration_test/photo_adjustments_device_test.dart -d <device-id> --no-pub --reporter expanded
```

Both integration tests passed on the Medium_Phone emulator: Android 17 / API 37,
x86_64, debug mode, Impeller OpenGLES (confirmed in the runtime log).

- The actual platform shader produces nonblank pixels and matches PNG/JPEG
  exports at sampled interior pixels, with codec tolerance, for the combined
  adjustment settings, crop, zoom, quarter-turn rotation and horizontal flip.
- Twelve separate imported copies of a synthetic 1600×1200 PNG decode to bounded
  1024×768 previews. A real slider gesture changes tint; one Undo returns to
  neutral and Redo restores the edit. The comparison toggle leaves stored edits
  unchanged. Apply-to-all and repository reopen preserve all twelve adjustment
  sets and source bytes. Both 600×600 export formats succeed. Unmounting and
  releasing leases empties preview and shader caches.

The complete host suite was rerun: 192 tests passed. Code analysis and the new
test's format check passed. Local logs are in
`build/photo-adjustments-device-tests.log` and
`build/photo-adjustments-regression-tests.log` (ignored by Git).
The normal `lib/main.dart` debug APK was rebuilt successfully after the test run,
so `build/app/outputs/flutter-apk/app-debug.apk` contains the application rather
than the integration-test entry point. Kotlin's generated local session directory
is now ignored alongside Gradle output.

These are focused component integration tests using native plugins and rendering,
not a full picker/gallery/share journey or a performance benchmark. Real camera
JPEG/HEIC files, transparent sources, editorial effects, accessibility services,
process termination, memory pressure, gallery permissions, physical devices and
iOS remain release checks. Test fixtures use an isolated temporary directory and
are removed after each successful run. No application behavior was changed in
this follow-up.

## Changed files

Validation executed on Windows (2026-11-13):

| Command | Result |
| --- | --- |
| `dart format .` | Exit 0; 125 Dart files processed |
| `flutter analyze` | Exit 0; no issues |
| `flutter test` | Exit 0; 192 passed |
| `flutter test --concurrency=1` | Exit 0; 192 passed; no Windows cleanup errors |
| `flutter build apk --debug` | Exit 0; debug APK built |
| `git diff --check` | Exit 0; no whitespace errors |

24 tests were added and archive fixtures expanded. An intermediate regression
exposed global preview-queue lifetime coupling; the editor-owned cache fixed it
without weakening existing tests. Final review also corrected rounded geometry
cache-key collisions and retained separate canvas/sheet shader configurations.
Build warnings concern existing Kotlin-plugin migration, native Java access and
SDK tooling versions; dependency versions were unchanged in the initial pass.
The emulator follow-up above adds development-only test dependencies and native
verification. Remote CI, physical devices and iOS remain unverified. No commits
or pushes were made.

- Model/rendering: `photo_adjustments.dart`, `photo_filter_renderer.dart`,
  `project_image_loader.dart`, new `preview_image_cache.dart`, `style_renderer.dart`
  under `lib/features/collage_editor`; `shaders/photo_adjustments.frag` and `pubspec.yaml`.
- Editor: `editor_page.dart`, `state/collage_editor_controller.dart`,
  `widgets/collage_canvas.dart`, `photo_edit_sheet.dart`, `style_studio_sheet.dart`,
  `styled_collage_scene.dart`, new `adjustment_slider.dart` and
  `photo_adjustments_studio.dart`.
- Other features: `editorial/widgets/design_sheet.dart`, `export/collage_exporter.dart`,
  `projects/services/project_repository.dart`, `templates/models/collage_template.dart`,
  `templates/widgets/templates_sheet.dart` and new `template_preview.dart`.
- Localization: `lib/core/localization/translations.dart` and new
  `adjustment_translations.dart`.
- Tests: new `test/photo_adjustments_studio_test.dart`, new
  `test/preview_image_cache_test.dart`, extended `test/project_archive_test.dart`.
- Documentation: `README.md`, this document, `docs/release-checklist.md`, and
  `docs/settings-and-photo-editing.md`.
