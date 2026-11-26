#!/usr/bin/env bash
set -euo pipefail
umask 077

for secret in APP_STORE_CONNECT_API_KEY_ID APP_STORE_CONNECT_ISSUER_ID APP_STORE_CONNECT_API_PRIVATE_KEY; do
  if [[ -z "${!secret:-}" ]]; then
    echo "::error::Missing GitHub Secret $secret. Configure the App Store Connect team API key for upload."
    exit 1
  fi
done
if [[ ! "$APP_STORE_CONNECT_API_KEY_ID" =~ ^[A-Z0-9]{10}$ ||
      ! "$APP_STORE_CONNECT_ISSUER_ID" =~ ^[0-9a-fA-F-]{36}$ ||
      "$APP_STORE_CONNECT_API_PRIVATE_KEY" != *'-----BEGIN PRIVATE KEY-----'* ]]; then
  echo "::error::Check the API key ID, issuer UUID and the complete multiline AuthKey .p8 contents."
  exit 1
fi
key_dir="$(mktemp -d "$RUNNER_TEMP/piclayout-asc.XXXXXX")"
trap 'rm -rf -- "$key_dir"' EXIT
printf '%s\n' "$APP_STORE_CONNECT_API_PRIVATE_KEY" > "$key_dir/AuthKey_${APP_STORE_CONNECT_API_KEY_ID}.p8"
unset APP_STORE_CONNECT_API_PRIVATE_KEY
export API_PRIVATE_KEYS_DIR="$key_dir"
xcrun altool --validate-app -f "$1" -t ios --apiKey "$APP_STORE_CONNECT_API_KEY_ID" --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID"
xcrun altool --upload-app -f "$1" -t ios --apiKey "$APP_STORE_CONNECT_API_KEY_ID" --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID"
