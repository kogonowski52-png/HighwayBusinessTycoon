#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

tools_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
: "${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:?Use the Play upload keystore}"
: "${GODOT_ANDROID_KEYSTORE_RELEASE_USER:?Set the upload key alias}"
: "${GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD:?Set the upload keystore password privately}"
: "${HBT_PLAY_UPLOAD_SHA256:?Set the Upload key certificate SHA-256 from Play Console}"

expected=$(printf '%s' "$HBT_PLAY_UPLOAD_SHA256" | tr -d ':[:space:]' | tr '[:upper:]' '[:lower:]')
[[ "$expected" =~ ^[0-9a-f]{64}$ ]]
read -r test_signer < "$tools_dir/test-certificate.sha256"
if [[ "$expected" == "$test_signer" ]]; then
  printf 'The APK test certificate cannot serve as the Play upload certificate.\n' >&2
  exit 2
fi
actual=$(keytool -exportcert -keystore "$GODOT_ANDROID_KEYSTORE_RELEASE_PATH" \
  -storepass:env GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD \
  -alias "$GODOT_ANDROID_KEYSTORE_RELEASE_USER" | sha256sum | cut -d ' ' -f1)
if [[ "$actual" != "$expected" ]]; then
  printf 'Upload keystore certificate does not match HBT_PLAY_UPLOAD_SHA256.\n' >&2
  exit 2
fi
if [[ "${1:-}" = --check-key ]]; then exit 0; fi

unsigned=${1:?Provide the unsigned AAB}
output=${2:?Provide the signed AAB output path}
[[ "$output" = *.aab && "$output" != *-unsigned.aab && "$output" != "$unsigned" ]]
python3 - "$unsigned" <<'PY'
from zipfile import ZipFile
from sys import argv
with ZipFile(argv[1]) as archive:
    if any(name.upper().startswith("META-INF/") and name.upper().endswith((".RSA", ".DSA", ".EC", ".SF"))
           for name in archive.namelist()):
        raise SystemExit("Expected an unsigned AAB")
PY
umask 077
staging=$(mktemp -d "$(dirname "$output")/.hbt-signed-XXXXXXXX")
trap 'rm -rf "$staging"' EXIT
password_args=()
if [[ -n "${HBT_PLAY_UPLOAD_KEY_PASSWORD:-}" ]]; then
  password_args+=(-keypass:env HBT_PLAY_UPLOAD_KEY_PASSWORD)
fi
jarsigner -keystore "$GODOT_ANDROID_KEYSTORE_RELEASE_PATH" \
  -storepass:env GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD "${password_args[@]}" \
  -signedjar "$staging/bundle.aab" "$unsigned" "$GODOT_ANDROID_KEYSTORE_RELEASE_USER"
verification=$(jarsigner -verify "$staging/bundle.aab")
[[ "$verification" == *'jar verified.'* && "$verification" != *'unsigned entries'* ]]
certificate=$(keytool -printcert -jarfile "$staging/bundle.aab" | awk '/SHA256:/ {print $NF}' | tr -d ':[:space:]' | tr '[:upper:]' '[:lower:]')
[[ "$certificate" == "$expected" ]]
mv "$staging/bundle.aab" "$output"
sha256sum "$output"
