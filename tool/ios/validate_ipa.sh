#!/usr/bin/env bash
set -euo pipefail

archive=build/ios/archive/Runner.xcarchive
app="$archive/Products/Applications/Runner.app"
if [[ ! -d "$app" ]]; then
  echo "::error::The signed Xcode archive was not produced."
  exit 1
fi
python3 tool/ios/validate_ios.py --app "$app" --bundle "$PICLAYOUT_BUNDLE_ID" \
  --version "$MARKETING_VERSION" --build "$BUILD_NUMBER"
codesign --verify --deep --strict --verbose=2 "$app"
shopt -s nullglob
ipas=(build/ios/ipa/*.ipa)
if [[ "${#ipas[@]}" != 1 ]]; then
  echo "::error::Expected one IPA. Inspect the Xcode archive/export log and verify signing configuration."
  exit 1
fi
ipa="${ipas[0]}"
unzip -tq "$ipa"
expanded="$(mktemp -d "$RUNNER_TEMP/piclayout-ipa.XXXXXX")"
trap 'rm -rf -- "$expanded"' EXIT
ditto -x -k "$ipa" "$expanded"
apps=("$expanded"/Payload/*.app)
if [[ "${#apps[@]}" != 1 ]]; then
  echo "::error::Expected exactly one application bundle in the IPA Payload."
  exit 1
fi
app="${apps[0]}"
python3 tool/ios/validate_ios.py --app "$app" --bundle "$PICLAYOUT_BUNDLE_ID" \
  --version "$MARKETING_VERSION" --build "$BUILD_NUMBER"
codesign --verify --deep --strict --verbose=2 "$app"
codesign --display --entitlements "$expanded/entitlements.plist" "$app"
python3 - "$expanded/entitlements.plist" "$RUNNER_TEMP/piclayout-signing/profile.plist" <<'PY'
import os
import plistlib
import sys

with open(sys.argv[1], "rb") as file:
    signing = plistlib.load(file)
with open(sys.argv[2], "rb") as file:
    profile = plistlib.load(file)["Entitlements"]
if (signing.get("application-identifier") != profile["application-identifier"]
        or signing.get("com.apple.developer.team-identifier") != os.environ["APPLE_TEAM_ID"]
        or signing.get("get-task-allow", False)):
    raise SystemExit("::error::The IPA entitlements do not match the App Store distribution identity.")
PY
executable="$(/usr/libexec/PlistBuddy -c 'Print CFBundleExecutable' "$app/Info.plist")"
if [[ "$(xcrun lipo -archs "$app/$executable")" != arm64 ]] ||
    ! xcrun vtool -show-build "$app/$executable" | grep -E '^[[:space:]]*platform[[:space:]]+IOS[[:space:]]*$'; then
  echo "::error::Expected an arm64 executable targeting iPhoneOS."
  exit 1
fi
echo "ipa=$ipa" >> "$GITHUB_OUTPUT"
