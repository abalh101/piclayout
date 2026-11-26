#!/usr/bin/env bash
set -euo pipefail

developer_dir=/Applications/Xcode_26.5.app/Contents/Developer
if [[ ! -d "$developer_dir" ]]; then
  echo "::error::Xcode 26.5 is missing. Check the macos-26 runner inventory and update this pin with the simulator runtime."
  exit 1
fi
export DEVELOPER_DIR="$developer_dir"
xcodebuild -version
sdk="$(xcrun --sdk iphoneos --show-sdk-version)"
simulator_sdk="$(xcrun --sdk iphonesimulator --show-sdk-version)"
echo "iPhoneOS SDK $sdk and iPhoneSimulator SDK $simulator_sdk"
if [[ "$(xcodebuild -version | head -1)" != 'Xcode 26.5' || "$sdk" != 26.* || "$simulator_sdk" != 26.* ]]; then
  echo "::error::Expected Xcode 26.5 and iOS 26 SDKs."
  exit 1
fi
echo "DEVELOPER_DIR=$developer_dir" >> "$GITHUB_ENV"
