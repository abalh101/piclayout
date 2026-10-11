# Up to 12 photos and direct canvas divider editing

PicLayout supports 1–12 selected photos. The native picker and review screen share
`AppConfig.maxPhotos`; review shows the selected count. Imports explicitly reject
zero or more than 12 photos before creating a project. Model normalization,
layout generation, custom layouts, recommendations and archive limits use the
same cap. Existing 1–6 photo layouts and stored layout IDs remain compatible.

## Larger layouts and unused slots

| Photos | Built-in choices include |
| --- | --- |
| 7 | 3×3 and 4×2 grids, complete 2/2/3 rows, staggered columns |
| 8 | 3×3, complete 2×4 and 4×2 grids, complete 2/3/3 rows |
| 9 | Complete 3×3 grid and staggered columns |
| 10 | 3×4, complete 2×5 and 5×2 grids, complete 3/3/4 rows |
| 11 | 3×4 and 4×3 grids, complete 3/4/4 rows, staggered columns |
| 12 | Complete 3×4 and 4×3 grids and staggered columns |

Hero layouts also remain available. A partial grid creates cells only for real
photos: unused slots display the canvas background, with no missing-image icon,
photo interaction target, duplicated image or phantom export cell. Choose balanced
rows or a complete grid if you want the whole canvas filled. Removing a photo
selects a layout for the remaining count and drops incompatible custom geometry;
undo restores it. Templates embed custom geometry only for matching photo counts.

## Direct divider editing

In the editor's layout tools, select **Edit dividers**. Drag an inner line or its
round arrow handle directly on the collage; vertical dividers move horizontally,
horizontal dividers vertically. Photo, text and sticker gestures pause in this
mode while all visual content stays visible. Select **Done editing dividers** to
resume photo/overlay editing. Text, stickers, filters and photo transforms are
preserved. The separate custom layout builder and its sliders remain available.

Geometry updates live. Every complete drag is one undo/redo action, followed by
autosave. A gesture with no geometry change preserves redo and does not convert
a built-in layout. The first actual edit embeds a custom layout in the project;
it can be reused through saved custom layouts or design templates. Selecting a
built-in layout resets the edited partition.

Each photo cell keeps at least **12% of the inner canvas width and height**.
The same normalized partition, margin/spacing math and Fill crop clamping are
used in preview and PNG/JPEG export. Handles and editing lines never export.

### Limitations

Direct editing is available only for the exact current layout when it is a
complete, non-overlapping rectangular partition with every cell at least 12% on
both axes. Partial grids, Hero layouts with holes or undersized cells, and a
single-photo layout have no draggable dividers. They are not silently replaced.
Choose a complete grid, balanced rows, staggered columns, or a saved custom
layout instead. The separate builder may offer its existing explicit fallback.
Outer borders are fixed; use outer-margin and spacing controls for those.
The 12% constraint is relative to the canvas, not a fixed physical touch size;
very extreme aspect ratios still need device usability testing.

## Validation and device checks

Tests cover 12-photo import/reopen, invalid counts, complete/partial layouts,
recommendations, reorder/replace/remove, templates and overlay preservation,
direct gestures on both axes with margins, minimum-size clamping, grouped undo,
autosave, JSON reload, and pixel-for-pixel PNG consistency with shared preview
rendering after a divider edit. JPEG checks sample every cell.

On Android and iOS, test 12 large photos, image replacement/reordering, multi-touch
crop after leaving divider mode, close/reopen and undo/redo, transparent PNG/JPEG,
gallery saving, social sharing and project archives. Check narrow screens, RTL,
large text and rapid divider drags for touch/memory/performance issues.

Current validation after the Windows cleanup fix: formatting completed, static
analysis found no issues, and **all 116 tests pass**, both with normal concurrency
and `--concurrency=1`. All ten feature tests succeed, including direct line
dragging without touching the arrow handles. The former fixture cleanup failures
are described in [windows-test-cleanup.md](windows-test-cleanup.md).
The GitHub macOS workflow is a template and has not yet been executed remotely.

## Changed files

- `lib/core/localization/translations.dart`
- `lib/features/collage_editor/editor_page.dart`
- `lib/features/collage_editor/layouts/layout_library.dart`
- `lib/features/collage_editor/state/collage_editor_controller.dart`
- `lib/features/collage_editor/widgets/canvas_divider_layer.dart` (new)
- `lib/features/collage_editor/widgets/collage_canvas.dart`
- `lib/features/custom_layouts/models/custom_layout.dart`
- `lib/features/layout_recommendations/layout_recommendation_service.dart`
- `lib/features/photo_import/selection_review_page.dart`
- `lib/features/projects/models/collage_project.dart`
- `lib/features/projects/services/project_repository.dart`
- `lib/features/stickers/sticker_layer.dart`
- `test/canvas_divider_test.dart` (new)
- `test/twelve_photo_test.dart` (new)
- `test/layout_library_test.dart`
- `test/layout_recommendation_ui_test.dart`
- `test/project_repository_test.dart`
- `.github/workflows/ios-ipa.yml` (new)
- `README.md`
- `docs/release-checklist.md`
- `docs/twelve-photos-and-dividers.md` (new)
- `docs/ios-ipa-builds.md` (new)
