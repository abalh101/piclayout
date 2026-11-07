# PicLayout editor refinement audit

Reviewed 2026-11-07 on Windows. No applicable AGENTS.md was present in the
workspace or parent directories. The initial working tree was clean.

## Architecture and compatibility

Flutter Material 3 with Riverpod; local repositories own projects, settings,
designs and custom layouts. `CollageEditorController` owns history, selection and
autosave. Preview and export share `LayoutGeometry`, `PhotoCrop`, style, filter,
text and sticker renderers. Export uses original image files and native gallery /
sharing services. This pass changes no project JSON, archive versions, renderer
math, dependencies or services. The existing 1–12-photo workflow remains intact.

## Prioritized findings

| Priority | Finding | Resolution |
| --- | --- | --- |
| High | Autosave errors were unhandled; back navigation left before the final save completed. | Handle background failures, retain the editor on failed exit, expose retry, block repeated exit and editing during the final save. |
| High | Project deletion immediately removed the project and its local photo copies. | Confirm the named project; cancel is harmless; report repository failures. |
| High | Picker / replacement exceptions escaped and repeated actions could overlap. | Guard the picker and replacement operation, report errors, ignore stale replacement completion after disposal/removal. |
| Medium | Starting an unchanged photo/text gesture cleared redo and inserted an undo entry; redo could select a removed photo. | Commit one history entry only for changed gestures; validate photo selection after redo. |
| Medium | Portrait-style stacking reduced the usable canvas in phone landscape; tool rows and text header were fragile with large type. | Side-by-side landscape panels, wrapping tool/header/footer controls, vertical text alignment segments at large type. |
| Medium | Thumbnail borders were covered by images, failed files had no fallback, full-sized thumbnail decoding wasted memory, and immediate reorder competed with scrolling. | Stable inset border, bounded decoding, missing-image fallback, selected semantics and long-press reorder. Bound review and home thumbnail decoding too. |
| Medium | Canvas photo/text targets lacked selection semantics; text hit regions could be very small; dividers had no screen-reader adjustment action. | Label photo/text targets, enlarge text hit regions without changing rendering, 48px divider handles with bounded increase/decrease actions and grouped undo. |
| Medium | Export displayed “preparing” throughout save/share; pixel unit was German-only. | Rendering/saving/sharing phases, localized units, cleared retry notices, safe notification lifecycle. Existing operation lock and gallery success confirmation retained. |
| Low | Cards and buttons used 14px radii while many controls used 8px; sheets/dialogs were inconsistent. | Shared 8px component shapes; compact layout diagram avatars; explicit filter percentages and inactive Original-filter intensity. |
| Low | Failed/decoding canvas images were communicated only by color; fallback Android splash was white. | Preview-only status icons and localized semantics; theme-aware fallback splash. API 21+ already used the theme background. |

## Complete journey review

| Area | Reviewed behavior and remaining limits |
| --- | --- |
| Home / creation | Recent projects, loading/error/empty states, picker cancellation, archive import and project menus. Added load retry and pull-to-refresh even for short content. No permission-error message for a normal picker cancellation. Project cards still show the first source photo rather than an exact collage thumbnail. |
| Photo selection, 1–12 | Existing count limit, review, reordering, removal minimum, format and recommendation selection, creation busy guard. Count now announces updates and review thumbnails decode at bounded size. |
| Layouts / favorites / templates / variations | Reviewed local libraries, compatible layout fallback, custom formats and grouped variation history. Added diagrams to standard choices and surfaced favorite-write errors. Template/favorite writes still need a broader transactional rollback pass on storage failure. |
| Canvas / editing | Shared crop math, selection ordering, pan/scale callbacks, rotate, flip, fit/fill and reset. History/selection fixes do not change saved geometry. Large original images and fast pinch gestures still need device profiling. |
| Filters | Live draft preview, Original/other presets, percentage intensity, neutral reset and Cancel/Done behavior. Presets retain text chips and the shared live preview; this pass adds no separately decoded per-filter image thumbnails. |
| Text / stickers | Reviewed hit testing, text sheet keyboard insets, alignment, rotation, color, and shared rendering. Text selection is accessible and has a minimum hit region; existing sticker functionality remains unchanged. |
| Formats / dividers | Validated existing bounds, built-in compatibility and custom-layout geometry tests. Accessible divider adjustments use the same controller path as dragging and remain undoable/autosaved. |
| Undo / autosave | Grouped changed gestures, no-op redo preservation, photo selection, failure/retry and save-before-back covered by focused tests. Repository serialization remains authoritative. Sudden process termination and storage-loss recovery require additional hardening. |
| Export / save / share | Existing render/save/share lock, permission mapping, share fallback and success notification preserved; added stage feedback and disposal protection. Native gallery and destination behavior require devices. |
| Settings / languages / reporting | Six locales including Arabic/RTL, local defaults, cache clearing and configured support-email fallback reviewed. No support mailbox is invented. New strings supplied in all six locales. |
| Feedback / validation | Existing format/layout validators and busy states retained. Added visible save retry, picker/replacement errors, decode fallback and export stage feedback. Corrupt projects remain silently omitted by the repository loader; document recovery is a follow-up. |
| Responsive / accessibility | Tests cover 320×640 at 200% text in all locales, dark mode and 740×360 landscape. Existing export/theme tests cover light/dark. Device screen readers, touch collisions in dense 12-photo layouts, keyboard behavior and platform text scaling remain manual checks. |

## Branding

Retained the original collage mark and authored SVG/master assets. Android
adaptive foreground/background wiring and all launcher density dimensions are
covered by tests. All referenced iOS icon sizes and opaque RGB icons are checked.
The iOS launch storyboard still uses the existing LaunchImage; its appearance and
dark-mode behavior require Xcode/device review. No new source art is required for
this pass and no third-party logos or generated substitute branding were added.

## Remaining checks and next improvement

Run gallery permission/grant/denial, storage-full, picker cancellation, native
share cancellation/fallback, process interruption, safe-area, accessibility and
12-large-photo memory/gesture checks on Android and iPhone/iPad. A successful APK
build validates compilation only. Windows cannot validate iOS compilation.

Recommended next improvement: harden local persistence with recoverable project
writes and explicit reporting of corrupt/unreadable projects, then transactional
design-library updates. This is deliberately outside this focused UI pass.

## Verification

Completed the interrupted verification pass on 2026-11-07:

- `dart format --output=none --set-exit-if-changed .`: 108 files, no changes.
- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub --reporter expanded`: all 134 tests passed.
- `flutter test --no-pub --concurrency=1 --reporter expanded`: all 134 tests
  passed in the serial Windows run too; no skipped tests or suppressed failures.
- `flutter build apk --debug --no-pub`: successful; output is
  `build/app/outputs/flutter-apk/app-debug.apk`. Non-blocking warnings concern
  Java native access, KGP usage in `package_info_plus` / `share_plus`, and the
  installed SDK command-line tools' XML version support. No dependency upgrade
  was included in this pass.
- `git diff --check`: no whitespace errors (Git reports the existing Windows
  line-ending conversion notice for `canvas_divider_layer.dart`).
- Visually inspected the existing `build/refinement-430.png` (430 × 932) and
  `build/refinement-740.png` (740 × 360) captures: canvas, selection borders,
  thumbnail strip and responsive panel arrangement remain legible and unclipped.

The first full test run exposed an outdated demo assertion: the current bundled
`.png` asset keys contain JPEG bytes at 896 × 1195, while the test required PNG
at width 480. The test now detects the encoded format, verifies successful
decoding, checks dimensions against each source asset and compares every copied
image byte-for-byte. Existing copy isolation and PNG/JPEG export checks remain.
No asset was replaced. Updated `onboarding-and-examples.md` to distinguish the
current bundled files from the optional PNG generator output.

Changed-file inventory for the complete refinement pass:

- Theme/localization/platform: `app_theme.dart`, `translations.dart`, Android
  `drawable/launch_background.xml`.
- Editor: `editor_page.dart`, `collage_editor_controller.dart`,
  `canvas_divider_layer.dart`, `collage_canvas.dart`, `photo_edit_sheet.dart`,
  `styled_collage_scene.dart`, `text_overlay_sheet.dart`, `thumbnail_strip.dart`.
- Creation/home/export: `home_page.dart`, `selection_review_page.dart`,
  `export_flow_controller.dart`, `export_center.dart`.
- Tests: new `editor_refinement_test.dart`; updated `demo_projects_test.dart`,
  `export_center_test.dart`, `icon_assets_test.dart`.
- Documentation: this audit, `onboarding-and-examples.md` and the current
  verification status in `release-checklist.md`.
