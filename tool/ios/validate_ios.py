"""Validate PicLayout's iOS sources and inspect built app bundles on macOS."""
import argparse
from decimal import Decimal
import json
from pathlib import Path
import plistlib
import re
import struct
import subprocess
import xml.etree.ElementTree as ET

from configure_release import require

RUNNER = Path("ios/Runner")
LOCALES = ("en", "de", "ar", "tr", "fr", "es")
PERMISSIONS = {"NSPhotoLibraryUsageDescription", "NSPhotoLibraryAddUsageDescription"}
FILE_TIMESTAMPS = {
    "NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryFileTimestamp",
    "NSPrivacyAccessedAPITypeReasons": ["C617.1"],
}
PLUGIN_MANIFESTS = ("Flutter.framework", "file_selector_ios", "image_picker_ios",
                    "package_info_plus", "share_plus", "url_launcher_ios")


def plist(path):
    require(path.is_file(), f"Missing {path}.")
    with path.open("rb") as file:
        return plistlib.load(file)


def check_info(info):
    require(info.get("CFBundleDisplayName") == "PicLayout", "Unexpected display name.")
    require({key for key in info if key.startswith("NS") and key.endswith("UsageDescription")} == PERMISSIONS,
            "Photo reading and adding are the only expected purpose strings.")
    require(all(isinstance(info[key], str) and "PicLayout" in info[key] for key in PERMISSIONS),
            "Missing PicLayout photo purpose strings.")
    require("LSApplicationQueriesSchemes" not in info, "iOS sharing uses no installed-app queries.")
    require(len(info.get("UISupportedInterfaceOrientations~ipad", [])) == 4,
            "iPad must support all four orientations.")
    require(info.get("UILaunchStoryboardName") == "LaunchScreen", "Incorrect launch storyboard.")


def check_manifest(manifest_path, reasons=None):
    manifest = plist(manifest_path)
    require(manifest.get("NSPrivacyTracking") is False
            and not manifest.get("NSPrivacyTrackingDomains")
            and not manifest.get("NSPrivacyCollectedDataTypes"),
            f"Unexpected collection or tracking declaration in {manifest_path}. Review the shipping SDKs.")
    if reasons is not None:
        require(manifest.get("NSPrivacyAccessedAPITypes") == reasons,
                f"Unexpected Required Reason API declarations in {manifest_path}. Review changes.")


def png_header(path):
    with path.open("rb") as file:
        header = file.read(29)
    require(len(header) == 29 and header[:16] == b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR", f"Invalid PNG {path}.")
    return struct.unpack(">IIBB", header[16:26])


def check_assets():
    assets = RUNNER / "Assets.xcassets"
    app_icons = assets / "AppIcon.appiconset"
    images = json.loads((app_icons / "Contents.json").read_text())["images"]
    slots = {(entry["idiom"], entry["size"], entry["scale"]) for entry in images}
    expected = {
        "iphone": ("20x20@2x", "20x20@3x", "29x29@1x", "29x29@2x", "29x29@3x", "40x40@2x",
                   "40x40@3x", "60x60@2x", "60x60@3x"),
        "ipad": ("20x20@1x", "20x20@2x", "29x29@1x", "29x29@2x", "40x40@1x",
                 "40x40@2x", "76x76@1x", "76x76@2x", "83.5x83.5@2x"),
        "ios-marketing": ("1024x1024@1x",),
    }
    require(len(slots) == len(images) and slots == {
        (idiom, *item.split("@")) for idiom, entries in expected.items() for item in entries
    }, "Incorrect iPhone, iPad or App Store icon slots.")
    for entry in images:
        path = app_icons / entry["filename"]
        width, height, depth, color = png_header(path)
        size = int(Decimal(entry["size"].split("x")[0]) * int(entry["scale"][:-1]))
        require((width, height, depth, color) == (size, size, 8, 2),
                f"{path} must be a {size} × {size} RGB PNG.")
        require(b"tRNS" not in path.read_bytes(), f"{path} must be opaque.")
    launch = assets / "LaunchImage.imageset"
    for entry in json.loads((launch / "Contents.json").read_text())["images"]:
        size = 112 * int(entry["scale"][:-1])
        require(png_header(launch / entry["filename"])[:2] == (size, size),
                "Incorrect launch logo asset dimensions.")
    storyboard = ET.parse(RUNNER / "Base.lproj/LaunchScreen.storyboard")
    require(storyboard.getroot().get("launchScreen") == "YES"
            and storyboard.find(".//imageView[@image='LaunchImage']") is not None,
            "The launch storyboard must use the branded asset.")


def check_sources():
    check_info(plist(RUNNER / "Info.plist"))
    check_manifest(RUNNER / "PrivacyInfo.xcprivacy", [FILE_TIMESTAMPS])
    for locale in LOCALES:
        path = RUNNER / f"{locale}.lproj/InfoPlist.strings"
        entries = dict(re.findall(r'^"([^"]+)"\s*=\s*"([^"]+)";$', path.read_text(), re.M))
        require(set(entries) == PERMISSIONS and all("PicLayout" in text for text in entries.values()),
                f"Missing localized photo purposes in {path}.")
    check_assets()
    print("iOS source plist, privacy manifest, six translations, app icons and launch logo verified.")


def check_app(app, bundle, version, build):
    info = plist(app / "Info.plist")
    check_info(info)
    require(info.get("CFBundleIdentifier") == bundle, "App bundle identifier differs from the expected value.")
    if version:
        require(info.get("CFBundleShortVersionString") == version and info.get("CFBundleVersion") == build,
                "Built app version or build number differs from workflow inputs.")
    require(set(info.get("UIDeviceFamily", [])) == {1, 2} and info.get("MinimumOSVersion") == "15.0",
            "Expected iPhone and iPad support with iOS 15.0 deployment.")
    require(re.fullmatch(r"(iphoneos|iphonesimulator)26(?:\.\d+)*", info.get("DTSDKName", "")),
            "Runner was not built with an iOS 26 SDK.")
    require((app / info["CFBundleExecutable"]).is_file() and (app / "Assets.car").is_file()
            and (app / "Base.lproj/LaunchScreen.storyboardc").is_dir(),
            "Missing app executable, compiled asset catalog or launch screen.")
    for locale in LOCALES:
        path = app / f"{locale}.lproj/InfoPlist.strings"
        subprocess.run(["plutil", "-lint", str(path)], check=True)
        localized = plistlib.loads(subprocess.check_output(["plutil", "-convert", "xml1", "-o", "-", str(path)]))
        require(set(localized) == PERMISSIONS and all("PicLayout" in text for text in localized.values()),
                f"Invalid or incomplete built purpose strings in {locale}.")
    check_manifest(app / "PrivacyInfo.xcprivacy", [FILE_TIMESTAMPS])
    manifests = list(app.rglob("PrivacyInfo.xcprivacy"))
    require(all(any(sdk in str(path.relative_to(app)) for path in manifests) for sdk in PLUGIN_MANIFESTS),
            "A Flutter or plugin privacy manifest is missing from the built app. Review SwiftPM resources.")
    for path in manifests:
        check_manifest(path)
        print(path.relative_to(app))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--app", type=Path)
    parser.add_argument("--bundle", default="com.abalh101.piclayout")
    parser.add_argument("--version")
    parser.add_argument("--build")
    args = parser.parse_args()
    check_sources()
    if args.app:
        check_app(args.app, args.bundle, args.version, args.build)
