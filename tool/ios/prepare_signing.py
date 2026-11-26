"""Check the real distribution identity against Apple's profile and configure Xcode."""
from datetime import datetime, timezone
from hashlib import sha1
import os
from pathlib import Path
import plistlib
import re
import shutil
import subprocess
import sys
from uuid import UUID

from configure_release import require

directory = Path(sys.argv[1])
keychain = sys.argv[2]
with (directory / "profile.plist").open("rb") as file:
    profile = plistlib.load(file)

team = os.environ["APPLE_TEAM_ID"]
bundle = os.environ["PICLAYOUT_BUNDLE_ID"]
entitlements = profile.get("Entitlements", {})
require(re.fullmatch(r"[A-Z0-9]{10}", team), "APPLE_TEAM_ID must be your 10-character Apple Developer Team ID.")
require(team in profile.get("TeamIdentifier", []) and entitlements.get("com.apple.developer.team-identifier") == team,
        "Provisioning profile belongs to a different Apple Developer Team.")
app_id = entitlements.get("application-identifier", "")
prefix, _, profile_bundle = app_id.partition(".")
require(prefix in profile.get("ApplicationIdentifierPrefix", []) and profile_bundle == bundle,
        "The provisioning profile must use the explicit app identifier selected by IOS_BUNDLE_ID.")
expiry = profile.get("ExpirationDate")
require(isinstance(expiry, datetime) and expiry.replace(tzinfo=timezone.utc) > datetime.now(timezone.utc),
        "The App Store provisioning profile has expired.")
require("iOS" in profile.get("Platform", []) and "ProvisionedDevices" not in profile
        and not profile.get("ProvisionsAllDevices") and entitlements.get("get-task-allow") is False,
        "Use an iOS App Store Connect distribution profile.")
try:
    profile_uuid = str(UUID(profile["UUID"])).upper()
except (KeyError, ValueError, TypeError):
    raise SystemExit("::error::Invalid provisioning profile UUID.")

identities = subprocess.check_output(
    ["security", "find-identity", "-v", "-p", "codesigning", keychain], text=True)
profile_fingerprints = {sha1(cert).hexdigest().upper() for cert in profile.get("DeveloperCertificates", [])}
matched = [
    fingerprint for fingerprint, certificate_team in
    re.findall(r'([A-Fa-f0-9]{40}) "Apple Distribution: [^\r\n]+ \(([A-Z0-9]{10})\)"', identities)
    if fingerprint.upper() in profile_fingerprints and certificate_team == team
]
require(len(matched) == 1,
        "The PKCS#12 must contain a valid Apple Distribution certificate and matching private key selected by the profile. Check the certificate chain and Apple Team.")

profiles = Path.home() / "Library/Developer/Xcode/UserData/Provisioning Profiles"
profiles.mkdir(parents=True, exist_ok=True)
installed = profiles / f"{profile_uuid}.mobileprovision"
require(not installed.exists(), "The runner already has this profile installed. Use a fresh GitHub-hosted runner.")
(directory / "installed-profile").write_text(str(installed))
shutil.copyfile(directory / "profile.mobileprovision", installed)
Path("ios/Flutter/ReleaseSigning.xcconfig").write_text(
    f"CODE_SIGN_STYLE[sdk=iphoneos*] = Manual\n"
    f"DEVELOPMENT_TEAM[sdk=iphoneos*] = {team}\n"
    f"CODE_SIGN_IDENTITY[sdk=iphoneos*] = {matched[0]}\n"
    f"PROVISIONING_PROFILE_SPECIFIER[sdk=iphoneos*] = {profile_uuid}\n")
with (directory / "ExportOptions.plist").open("wb") as file:
    plistlib.dump({
        "method": "app-store-connect", "destination": "export", "teamID": team,
        "signingStyle": "manual", "signingCertificate": matched[0],
        "provisioningProfiles": {bundle: profile_uuid},
        "manageAppVersionAndBuildNumber": False,
        "testFlightInternalTestingOnly": False,
    }, file)
