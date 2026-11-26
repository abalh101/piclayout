# PicLayout 1.0.0 App Store release checklist

| Field | Value |
| --- | --- |
| Name | PicLayout |
| Bundle ID | `com.abalh101.piclayout` from the existing repository. Confirm ownership in Apple Developer. |
| Platform | iOS, iPhone and iPad. Minimum iOS/iPadOS 15.0. |
| Marketing version and build | `1.0.0` and `1` for the first upload if unused. |
| Primary category and locale | Photo & Video, English (U.S.). |
| Toolchain | GitHub `macos-26` ARM64, Xcode 26.5, iOS 26-series SDK, Flutter 3.47.5 with SwiftPM. |

## Completed and verified in the working tree

- [x] Run Flutter package resolution with the lockfile enforced, Dart format and analysis, the 256-test suite, and an Android debug build on Linux.
- [x] Check the existing identity, iPhone/iPad targeting, app feature sources, and lockfile.
- [x] Review Apple’s SDK, deployment, metadata, privacy and screenshot requirements.
- [x] Check the Runner source property list, privacy manifest, six permission localizations, opaque App Store icon and branded launch assets.
- [x] Prepare the six locale directories and reviewer instructions using implemented features. Descriptions and updates have a 4,000-character limit, subtitles 30 characters, promotional text 170 characters, keywords 100 UTF-8 bytes, and review notes 4,000 bytes. First versions have no What’s New field. [Apple version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information), [Apple product page guidance](https://developer.apple.com/app-store/product-page/).

## Implemented and awaiting macOS verification

- [ ] Run **iOS validation** and verify the actual Swift build, application startup, simulator integration tests, add-only Photos saves and dependency manifests. Review the unsigned diagnostic archive for build issues.
- [ ] Run **iOS App Store screenshots**, review iPhone and iPad artifacts in English, German and Arabic, and capture any missing sets.
- [ ] Run **iOS App Store release** in artifact-only mode. Confirm the archive and IPA have the same identity and correct version. Review the build logs and contents.
- [ ] Run the release workflow with upload enabled, wait for Apple to process the build and confirm TestFlight installation. Complete the physical-device checks below.

## Requires owner configuration

- [ ] Confirm the Apple Team and registered bundle ID. Create or select the matching App Store Connect record.
- [ ] Supply signing secrets, the optional upload API secrets, and the public support and privacy variables using [the release guide](../docs/IOS_APPSTORE_RELEASE.md).
- [ ] Complete publisher identity, contact address, email and applicable retention details in the website, then publish it by choice. Validate both policy URLs and the support URL over HTTPS.
- [ ] Confirm the [App Privacy](app-privacy.md), [age rating and compliance](age-rating.md), content rights, export compliance, territories, pricing, and EU trader declarations. Enter copyright and the App Review contact details, including an international-format phone.
- [ ] Upload reviewed screenshots and localized descriptions, keywords, subtitles and promotional text. Enter `review-notes.txt` in App Review Information and select the processed build.

The initial submission depends on passing signed CI, Apple processing, a TestFlight device pass, verified public policy/support pages, and complete App Store Connect requirements. See [the release guide](../docs/IOS_APPSTORE_RELEASE.md) for manual submission and publication.

## Physical iPhone and iPad TestFlight checks

- [ ] Clean install and cold launch in airplane mode. Skip and replay onboarding, open an example, then check Home, recent projects, navigation and clean relaunch. Switch all six languages. Check Arabic layout, VoiceOver navigation and larger text on the narrowest supported screen.
- [ ] Start in Photos with 1, 2 and 12 mixed JPEG/PNG/HEIC photos, including EXIF rotation, a panorama, mixed orientations, and some 12–48 MP originals. Confirm picking and cancellation, selection ordering, changing the last slot, adding and replacing photos in Freestyle and Freeform. Try an iCloud-only asset online and offline and check the error or cancellation path.
- [ ] Verify Grid, Freestyle, Freeform frames, custom layouts and ratios, Smart Auto Layout, filters, text/stickers, layers, canvas styles, and zoom and rotate gestures. Test iPad portrait, landscape and resizable layouts.
- [ ] Test Photos add-only permission from a fresh install, denial, permission changes in iOS Settings, then save and reopen transparent PNG and opaque JPEG. Check pixel dimensions, visual crop/filter parity, recurring exports and free-space errors.
- [ ] On iPad, open and dismiss native image and .piclayout share popovers from the export button and project menus. Rotate during export before sharing. Confirm Save to Files, AirDrop if available, and an optional installed photo-app destination. Check that a missing destination leaves general sharing usable.
- [ ] Export/import an editable archive via Files, try invalid/large and cancelled imports, move a test project from Android, then reopen, delete, and clear cached exports. Verify autosave on background/return and a forced app relaunch. Confirm original photos and already-exported files are intact.
- [ ] On an older or lower-memory device, profile 12 separate high-resolution inputs with deep crops, blur and overlays, repeated largest PNG/JPEG exports, and resume/background while working. Also try a 20-frame Freeform project and a large archive within its limits. Record elapsed time, peak memory, and crashes or jetsam logs using Instruments where available, TestFlight diagnostics, or device logs.
- [ ] On the signed build, open Settings → Privacy in English and German, open Report a problem, and check the correct recipient plus mail-app fallback while keeping the draft unsent.
