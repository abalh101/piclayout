# App Store screenshots

Apple accepts one to ten PNG or JPEG screenshots per device size. For PicLayout, prepare the iPhone Dynamic Island medium and iPad 13-inch sets. The workflow captures portrait iPhone 17 Pro at **1206 × 2622** and iPad Pro 13-inch (M5) at **2064 × 2752**. In Media Manager, check the required slots Apple presents. The workflow also provides iPhone 17 Pro Max at **1320 × 2868** for the large iPhone slot. See the live table for accepted alternatives and scaling. [Apple screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications).

## Capture on GitHub from Linux

1. Once the changes are available on the repository’s default branch, open **Actions → iOS App Store screenshots → Run workflow**, select **main**, then run it. Apple secrets are unnecessary.
2. Download the artifacts `PicLayout-screenshots-{iphone,iphone-large,ipad}-{en,de,ar}`. Each passing job checks for ten PNGs at its device’s native dimensions. The integration test runs the actual app with bundled example artwork and saves native UIKit Simulator captures. It seeds three ordinary local projects and sets the app language through its normal settings repository.
3. Open every capture. Check the status bar, text legibility, clipping, correct locale, Arabic RTL, project title, and expected visible controls and canvas. Confirm the Canvas contains the real composition and that each image represents a distinct workflow. Upload only reviewed images.
4. For other app languages, use the macOS commands below with `SCREENSHOT_LOCALE=tr`, `fr`, or `es`. App Store Connect can reuse primary-language images as applicable. Prefer localized screenshots when the UI contains significant translated text.

## Scenario order

| File | Scene to check |
| --- | --- |
| 01-home-projects | Home after onboarding with three recent example projects. |
| 02-grid-collage | Open the Story example in Grid with artwork, text and star. |
| 03-freestyle-collage | Select Freestyle and show the canvas with its independent photo controls. |
| 04-custom-layout | Return to Grid and open the custom layout builder with its canvas and dividers. |
| 05-photo-adjustments | Open Adjustments for a photo. Show the photo preview and filter or light controls. |
| 06-text-stickers | Open Layers for the example containing a caption and a star sticker. |
| 07-smart-auto-layout | In Grid, scroll to the automatic layout action and recommendations. |
| 08-style-studio | Open Style Studio with background controls. |
| 09-export-center | Open Export and show PNG/JPEG, destination and size choices. |
| 10-design-templates | Open My Templates and show the built-in designs and search. |

The sample artwork is generated in [tool/generate_demo_assets.py](../tool/generate_demo_assets.py). For any additional capture, use owned or appropriately licensed images. Keep personal photos, account information, and private files out of the artifact.

## macOS reproduction or manual fallback

Run these from the repository root on a Mac with Xcode 26.5, iOS 26.5 Simulator, and Flutter 3.47.5. Use a clean simulator for each locale. The GitHub jobs use isolated runners per device and locale.

```bash
export DEVELOPER_DIR=/Applications/Xcode_26.5.app/Contents/Developer
xcrun simctl list devices available
SIMULATOR_UDID='paste-uuid-from-list'
SCREENSHOT_LOCALE=en
xcrun simctl boot "$SIMULATOR_UDID"
xcrun simctl bootstatus "$SIMULATOR_UDID" -b
xcrun simctl uninstall "$SIMULATOR_UDID" com.abalh101.piclayout # Only on an expendable simulator with old app data
xcrun simctl ui "$SIMULATOR_UDID" appearance light
xcrun simctl status_bar "$SIMULATOR_UDID" override --time '9:41' --dataNetwork wifi --wifiMode active --wifiBars 3 --cellularMode active --cellularBars 4 --batteryState unplugged --batteryLevel 100
flutter pub get
flutter test --no-pub --no-uninstall -d "$SIMULATOR_UDID" --dart-define="SCREENSHOT_LOCALE=$SCREENSHOT_LOCALE" integration_test/appstore_screenshots_test.dart
data="$(xcrun simctl get_app_container "$SIMULATOR_UDID" com.abalh101.piclayout data)"
mkdir -p build/appstore-screenshots
cp "$data"/Documents/appstore-captures/*.png build/appstore-screenshots/
python3 tool/ios/check_screenshots.py build/appstore-screenshots 1206 2622
```

For iPad use `2064 2752`. For iPhone 17 Pro Max use `1320 2868`. If a scripted screen fails or needs recomposition, open the Simulator window, install the standard app and navigate to the scenario above. Use **Settings → Language** to select the app language. Open several examples and return Home to populate Recent Projects. For each screen, use the Simulator screenshot menu or the command shown below. Confirm native dimensions and save in the appropriate locale and display slot.

```bash
flutter run -d "$SIMULATOR_UDID"
# Run this in a second terminal once the desired scene is on screen.
xcrun simctl io "$SIMULATOR_UDID" screenshot 01-home-projects.png
```

To capture on a physical iPhone or iPad use the matching TestFlight build, the same example workflow, and the device screenshot shortcut. Transfer full-resolution files without rescaling. The simulator workflow and its outputs still require the first macOS run and visual review.
