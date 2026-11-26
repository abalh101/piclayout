#!/usr/bin/env bash
set -u

signing="$RUNNER_TEMP/piclayout-signing"
if [[ -f "$signing/installed-profile" ]]; then
  rm -f -- "$(cat "$signing/installed-profile")"
fi
if [[ -f "$signing/original-keychains" ]]; then
  python3 - "$signing/original-keychains" <<'PY'
from pathlib import Path
import shlex
import subprocess
import sys

subprocess.run(["security", "list-keychains", "-d", "user", "-s",
                *shlex.split(Path(sys.argv[1]).read_text())])
PY
fi
if [[ -f "$signing/release.keychain-db" ]]; then
  security delete-keychain "$signing/release.keychain-db"
fi
rm -rf -- "$signing"
rm -f ios/Flutter/LocalIdentity.xcconfig ios/Flutter/ReleaseSigning.xcconfig
