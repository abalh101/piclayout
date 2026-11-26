#!/usr/bin/env bash
set -euo pipefail
umask 077

for secret in APPLE_TEAM_ID IOS_DISTRIBUTION_CERTIFICATE_BASE64 IOS_DISTRIBUTION_CERTIFICATE_PASSWORD IOS_PROVISIONING_PROFILE_BASE64 KEYCHAIN_PASSWORD; do
  if [[ -z "${!secret:-}" ]]; then
    echo "::error::Missing GitHub Secret $secret. See docs/IOS_APPSTORE_RELEASE.md."
    exit 1
  fi
done

signing="$RUNNER_TEMP/piclayout-signing"
mkdir -p "$signing"
python3 - "$signing" <<'PY'
import base64
from pathlib import Path
import os
import sys

directory = Path(sys.argv[1])
for name, file in (
    ("IOS_DISTRIBUTION_CERTIFICATE_BASE64", "distribution.p12"),
    ("IOS_PROVISIONING_PROFILE_BASE64", "profile.mobileprovision"),
):
    try:
        data = base64.b64decode("".join(os.environ[name].split()), validate=True)
    except ValueError:
        raise SystemExit(f"::error::{name} must be a Base64-encoded file.")
    (directory / file).write_bytes(data)
PY

security cms -D -i "$signing/profile.mobileprovision" -o "$signing/profile.plist" || {
  echo "::error::Unable to decode the provisioning profile. Export an App Store Connect profile from Apple Developer."
  exit 1
}

keychain="$signing/release.keychain-db"
security list-keychains -d user > "$signing/original-keychains"
security create-keychain -p "$KEYCHAIN_PASSWORD" "$keychain"
security set-keychain-settings -lut 7200 "$keychain"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$keychain"
security import "$signing/distribution.p12" -k "$keychain" \
  -P "$IOS_DISTRIBUTION_CERTIFICATE_PASSWORD" -T /usr/bin/codesign -T /usr/bin/security >/dev/null || {
    echo "::error::The distribution PKCS#12 could not be imported. Check the password and confirm that it contains the private key."
    exit 1
  }
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" "$keychain" >/dev/null

# Xcode needs the custom keychain in the search list. Preserve other runner keychains.
python3 - "$keychain" "$signing/original-keychains" <<'PY'
import shlex
from pathlib import Path
import subprocess
import sys

existing = shlex.split(Path(sys.argv[2]).read_text())
subprocess.run(["security", "list-keychains", "-d", "user", "-s", sys.argv[1], *existing], check=True)
PY
python3 tool/ios/prepare_signing.py "$signing" "$keychain"
rm -f "$signing/distribution.p12"
