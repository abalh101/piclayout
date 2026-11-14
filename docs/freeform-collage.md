# Freeform Collage

## Workflow

Choose **Freie Collage / Freeform Collage** on Home to open an empty 9:16
project. **Add photos** opens the native picker and selection review; order
photos before confirming. The first batch is arranged across the canvas.
Later batches fill unlocked empty slots before adding frames. Freeform projects
allow up to **20 photo frames and 20 source photos**; standard grids keep their
12-photo limit. Text and decorative layers use the existing 200-layer ceiling.

Tap a frame to select it, drag to move it, pinch to resize, or use the corner
and rotation handles (48 logical-pixel hit areas). Two-finger rotation is also
supported. Double-tap enters crop mode: dragging and pinching then change only
the image inside the frame. **Done cropping** returns to frame editing. Tap
outside to deselect; **Expand canvas** gives gestures more room on small screens.
Locked frames remain selectable but cannot be moved or edited.

The existing **Layers** panel provides source thumbnails/placeholders, names,
selection, visibility, lock state and reorder handles. Select a frame for
front/back ordering, duplication, replacement, crop/photo editing, swap/move,
clear-photo, deletion, centering, reset and fit-to-canvas actions. Frame geometry,
appearance and image edits are separate. Removing a photo retains its empty
frame and exits crop mode. Duplicates share original bytes but have independent
crop and adjustment values. Photo editing requires a selected frame.

Each completed drag, pinch, rotation or crop gesture contributes one undo step.
The existing 700 ms autosave debounce starts after the gesture ends. No-op edits
do not consume history. Guides snap within six logical pixels to canvas center,
edges, neighboring bounds and existing positive gaps. Generic story guides are
at 8%/92% height and 5%/95% width; they are not platform-specific guarantees.

## Architecture and compatibility

This extends `EditorialDesign` / `DesignLayer`; it does not add a second scene
model. Existing controller history, repository save queue, image picker,
selection review, template library, `PhotoCrop`, adjustment shaders, image cache,
style renderer, archive service and export lock remain in use.

`DesignMode.freeform` adds optional layer fields: `imageTransform`,
`adjustments`, `aspectLocked`, `empty` and `name`. Existing fields hold ID,
source reference, normalized geometry, frame rotation, z-order, visibility,
lock, opacity, corners, border and shadow. Missing overrides in old editorial
projects still inherit source-photo transforms/adjustments. The project format
version remains 1; old projects and archives continue to load. Older app binaries
are not guaranteed to understand new freeform projects.

Freeform projects can be saved with no photos. Project duplication remaps source
IDs; `.piclayout` export/import preserves frame edits and allows empty projects.
Archive validation keeps its path, size and entry checks, with a mode-aware photo
limit. Imported files are copied, never modified. Missing or undecodable photos
produce replaceable gray frames; a missing blurred-background source uses the
same fallback as the preview. An archive still requires its referenced source
files; image export's placeholder fallback does not synthesize archive photos.

## Templates

Built-in presets are structured frames: Story Mosaic 9, 12 and 15; Free Canvas;
Scrapbook; and Clean Gallery. Story mosaics mix portrait, landscape and square-like
frames, two large highlights, and consistent physical gaps at the default 9:16
ratio. Scrapbook adds slight overlap and rotation.

Saving a template removes source references and user frame names, numbers the
photo placeholders and keeps geometry, per-frame styling, crop settings,
background and optional text/stickers. Templates contain no photo bytes, file
paths or cached thumbnails. Applying one opens a reorder/confirmation dialog;
photos map by position, excess slots stay empty, and excess photos remain stored
in the project. They can be assigned through a frame's source selector. Presets
replace the current frame arrangement in one undoable step.

## Preview, export and performance

Both paths call `EditorialRenderer.paintLayer` and `StyleRenderer.photo` for
geometry, rotation, clipping, Fit/Fill, zoom, pan, flip, effects and decoration.
Freeform preview uses a repaint boundary per layer, so moving one photo does not
repaint unchanged photo layers. Widget reconciliation still visits the scene.
Selection/resize controls and snapping/crop guides are separate preview widgets.
They never enter export. PNG retains transparency; JPEG uses the existing opaque
background behavior. Empty slots export as undecorated gray placeholders.

The reference-counted preview cache decodes at most two files concurrently with
a 1024-pixel maximum edge. Canvas and thumbnails share leases. Hidden/deleted
frames release their leases; other visible consumers may retain a shared source.
Closing the canvas releases its sources. Original images are decoded sequentially
during export; each source is flattened into the output surface before the next
decode, bounding retained original-image memory. The saved project stays editable.

The Android 17 / API 37 x86_64 emulator test used 20 separate project copies of a
generated 2400 × 1800 JPEG. It verified all previews at 1024 × 768, live editing,
one-step undo/redo, crop/adjustments, deletion/reload cache counts, save/reopen,
1080 × 1920 PNG/JPEG output and byte-for-byte source preservation. Decoded preview
pixels totaled **62,914,560 bytes (60 MiB)**. One debug run measured process RSS
278,200,320 bytes before preview acquisition, 371,621,888 after export, and peak
536,088,576 bytes (about 511 MiB). These are process observations from an emulator,
not a GPU allocation accounting or a low-memory-device performance guarantee.

## Changed areas

| Area | Files |
| --- | --- |
| Model and limits | `app_config.dart`, `editorial_design.dart`, `collage_project.dart` |
| Editing | `collage_editor_controller.dart`, new `freeform_controller.dart` |
| Presets and snapping | new `freeform_presets.dart`, `freeform_snapping.dart` |
| Touch/UI | `design_layer_interactions.dart`, `design_sheet.dart`, new `freeform_tools.dart`, `editor_page.dart` |
| Entry/import | `home_page.dart`, `selection_review_page.dart` |
| Photo adjustments | `photo_adjustments_studio.dart`, `photo_edit_sheet.dart` |
| Rendering | `styled_collage_scene.dart`, `editorial_renderer.dart`, `collage_exporter.dart` |
| Persistence | `project_repository.dart`, `project_archive_service.dart` |
| Templates | `collage_template.dart`, `template_preview.dart`, `templates_sheet.dart` |
| Localization | `translations.dart`, new `freeform_translations.dart` (de/en/ar/tr/fr/es) |
| Tests | new `freeform_collage_test.dart`, `freeform_device_test.dart`; updated repository test double in `layout_recommendation_ui_test.dart` |
| Documentation | this file, `README.md`, `release-checklist.md` |

The pre-existing Android `.kotlin` ignore entry is retained. No dependencies,
signing credentials, private photos or generated builds are added to source.

## Validation

`test/freeform_collage_test.dart` adds 27 focused tests: compatibility/JSON,
limits, mosaic geometry, template privacy and mapping, frame/crop separation,
gesture history/autosave, crop bounds, layer actions, snapping, repaint
invalidation, persistence/archive/original bytes, shared rendering, missing
sources, touch drag/double-tap/pinch/locking, Arabic landscape mapping and all
six languages at 320 pixels with large type and dark mode.

Executed on Windows, 14 November 2026:

| Command | Result |
| --- | --- |
| `dart format .` | 133 Dart files formatted |
| `dart format --output=none --set-exit-if-changed .` | 0 changes, exit 0 |
| `flutter analyze --no-pub` | No issues found |
| `flutter test --no-pub --reporter expanded --timeout 45s` | All 219 tests passed |
| `flutter test --no-pub --concurrency=1 --reporter expanded --timeout 45s` | All 219 tests passed; no Windows cleanup errors |
| `flutter test --no-pub integration_test/freeform_device_test.dart integration_test/photo_adjustments_device_test.dart -d emulator-5554` | All 3 native emulator tests passed |
| `flutter build apk --debug --no-pub` | Built `build/app/outputs/flutter-apk/app-debug.apk` |
| `git diff --check` | Exit 0; only Windows line-ending notices |

`--no-pub` uses the already resolved project dependencies. The
Android toolchain emits existing Kotlin-plugin/native-access/SDK-version warnings;
they do not invalidate the successful tests, but should be revisited for a future
toolchain migration. No tests were skipped or cleanup failures suppressed.

## Remaining device checks and limitations

### Follow-up bug verification, 14 November 2026

Ten additional regression tests cover rejected-design history, locked aspect
ratios at size limits, stale photo replacements, failed/cancelled import cleanup,
editor disposal, placeholder stacking and thumbnail image release. The full
Windows suite now passes **229 tests** in the normal run; analysis and formatting
also pass. The serial and emulator results above refer to the preceding feature
pass. No mobile device is connected for this follow-up. Details and affected
behaviors are recorded in [the bug audit](bug-audit.md).

### Outstanding manual checks

- Profile real Android and iOS devices with 20 distinct 12–48 MP JPEG/HEIC photos,
  repeated exports and background/resume; measure frame times, peak memory and
  thermal behavior in profile/release mode. The emulator fixture uses synthetic
  images, not a representative camera corpus.
- Test native multi-photo picking, cancellation, gallery permissions, sharing,
  storage-full and decode failures. Confirm 20-frame editing on low-memory phones
  before broad release; reduce the limit if that device evidence requires it.
- Check iPhone/iPad builds, native touch rotation and simultaneous gestures,
  TalkBack/VoiceOver, actual contrast, landscape keyboards and large accessibility
  fonts. Automated geometry/RTL tests supplement these checks.
- Snapping uses rotated axis-aligned bounds and a fixed threshold. It is not a
  general constraint solver. Preset gaps target 9:16 and change physical proportions
  with other canvas ratios. Frame centers stay on-canvas; frame edges may extend
  beyond the canvas and are clipped.
- Empty/missing slots intentionally remain visible in image exports. Source
  replacement is explicit. Export failure does not change project data.
- Low-memory handling uses bounded decoding, resource release and existing error
  UI. An OS process kill cannot be caught in Dart. No iOS/physical-device claims
  are made by the Windows and emulator results.
