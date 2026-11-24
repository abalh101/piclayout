# Editorial & Story Designs

## Implementation plan and architecture audit

The working tree was clean at the start of this feature. No AGENTS.md was found
in the workspace or its parent directories.

1. Extend `CollageProject` with an optional, independently versioned design scene.
   Reuse project JSON, relative photo paths, repository writes, controller snapshots,
   the 700 ms autosave and the existing template opt-in for text.
2. Add immutable normalized scene layers and structured preset factories. Keep
   original photos and legacy layouts intact. Remap source IDs on duplication and
   archive import; templates store slots rather than source IDs or file paths.
3. Share geometry, deterministic procedural tears and drawing code between the
   bounded preview cache and original-file exporter. Reuse crop clamping, filters,
   background rendering and text styles. Keep editor guides in a separate widget.
4. Integrate Design and Layers sheets and direct manipulation into `CollageCanvas`.
   Keep existing photo editing, custom formats, dividers, text, stickers, favorites,
   gallery, sharing and export locking. Add all UI strings in six languages.
5. Add model, history, persistence, geometry, pixel and responsive tests. Run format,
   analysis, full and serial Windows suites, Android build and available-device checks.

## Editor workflow

Open **Design** in the editor for seven built-in presets: a numbered editorial
grid, three masonry variants, torn photo strips, detail callouts and a journal
page. Presets switch to the 9:16 story format; other canvas ratios remain editable.
Existing design layers require confirmation before replacement. **Standard
layout** keeps the stored design available through **Show design again**, which
restores the original preset mode. A blank design keeps the project's source
photos available for new layers.

The **Page** tab controls margins, horizontal/vertical gaps, title area,
editorial columns and numbering. Numbering supports parentheses, plain numbers,
zero padding, custom captions and hidden captions. Spacing changes reflow preset
slots while preserving source bindings, text and locked layers.

The **Layers** tab adds photos, torn strips, detail callouts, text, location
labels, backgrounds and connector lines. Layers support visibility, locking,
ordering, duplication, deletion, position, dimensions, rotation, opacity, borders
and color. Text adds font family, alignment, label padding and rounded corners.
The sheet stays above the software keyboard and scrolls on small screens.

Tap a canvas layer to select it; drag to move it and use the handles to resize
or rotate. Pinching a photo zooms its crop. **Edit crop** enables photo panning;
**Done** leaves crop mode. Double-tap a photo for its existing photo tools, or
long-press a layer to edit its properties. A callout uses its own source rectangle
and a separate crop dialog, with rectangle, square, circle and rounded shapes.
Its connector and editor-only source guide follow the main photo's transform.
Four deterministic tear styles expose edge selection, intensity, roughness
and an optional shadow.

## Storage and rendering

- `editorial_design.dart` stores independently versioned, normalized scene data.
  Old projects default to standard layouts; unknown layer types and malformed
  optional entries are isolated. Parsing and editor additions cap scenes at 200
  layers. Layer coordinates, dimensions and effect values are bounded.
- Controller history and the existing 700 ms autosave include scene changes.
  A drag or slider gesture is one history step. Source changes keep photo-tool
  selection synchronized through undo/redo; changing selection or leaving design
  mode clears crop editing.
- Project duplication, photo replacement and archive import remap source IDs.
  Templates use photo slots and generic layer/text IDs, never original paths or
  private photo IDs. Text content is included only when explicitly selected.
  Applying a template with fewer photos clamps its slots to available sources;
  it preserves the template's number of layers.
- `editorial_renderer.dart` shares geometry and painting between preview and
  export. Preview image decoding remains cached and capped at a 1024-pixel long
  edge. Export reads original files and disposes decoded resources per layer.
  Repeated layers of one photo currently decode that original again during export.
- Callout crops refer to original source coordinates and inherit photo filters.
  Ordinary photo layers retain Fill/Fit, rotation and mirroring. Existing text
  overlays and stickers remain above the design scene. Selection handles,
  source guides and the transparency checkerboard never enter exported images.
- PNG preserves alpha; JPEG uses a white backing. Existing gallery and social
  export flows remain unchanged. All new interface strings cover German,
  English, Arabic, Turkish, French and Spanish.

## Validation (10 November 2026)

- Full Windows suite: **163 tests passed** in both normal and
  `--concurrency=1` runs, including 29 editorial tests. No tests were skipped
  and no cleanup failures were suppressed.
- `flutter analyze --no-pub`: no issues; `dart format lib test`: 118 files.
- `flutter build apk --debug --no-pub`: successful, output at
  `build/app/outputs/flutter-apk/app-debug.apk`.
- Model tests cover all presets with 1–12 photos, bounds, masonry variants,
  serialization, private-free templates, source remapping, history and autosave.
- Rendering tests compare shared painting pixel-for-pixel with PNG export for
  every preset, verify JPEG backing, alpha masks, filters and original-source
  callout crops, and assert source files remain unchanged.
- Widget tests cover all six languages at 320 × 640 with 200% text, keyboard
  avoidance with RTL, preset replacement/resumption, gestures and locks. The
  canvas test waits for photo decoding and verifies actual image pixels.
- Visual artifacts from `--dart-define=EDITORIAL_VISUAL_QA=true` are under
  `build/editorial-qa/` (ignored by Git). All seven preset layouts and the loaded
  canvas were inspected. Widget tests use Flutter's block-shaped test font;
  these images do not validate native font appearance.
- Build warnings remain for native Java access, KGP use by `package_info_plus`
  and `share_plus`, and differing Android SDK XML versions. They did not prevent
  the debug build.

## Remaining device checks

`flutter devices` found Windows, Chrome and Edge only. No Android/iOS device
test, signed release build or iOS compilation was performed in this pass.

1. Check native fonts, multiline Arabic labels, screen readers, large text,
   landscape, dark mode, keyboard opening/dismissal and touch gestures.
2. Compare each preset and edited design against PNG/JPEG exports, including
   transparent backgrounds, rotated/mirrored crops, callouts and torn edges.
3. Exercise 12 large photos and repeated source layers for decoding time, peak
   memory, rapid slider changes and repeated exports.
4. Save/restart/reopen; duplicate, replace/remove photos, apply templates and
   transfer archives between Android and iOS. Verify undo/redo and originals.
5. Complete native gallery, sharing and permission checks from the release
   checklist. iOS builds still require macOS/Xcode.
