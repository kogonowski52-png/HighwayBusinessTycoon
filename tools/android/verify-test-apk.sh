#!/usr/bin/env bash
set -euo pipefail

apk=${1:?Pass the signed APK}
version=${2:?Pass the expected version name}
previous=${3:-}
build_tools=${ANDROID_BUILD_TOOLS_DIR:?Set ANDROID_BUILD_TOOLS_DIR}
certificate_file="$(dirname "${BASH_SOURCE[0]}")/test-certificate.sha256"
read -r expected_certificate < "$certificate_file"

version_part='(0|[1-9][0-9]{0,2})'
if [[ ! "$version" =~ ^$version_part\.$version_part\.$version_part$ ]]; then
  echo "Version must be MAJOR.MINOR.PATCH with components below 1000." >&2
  exit 1
fi
expected_code=$((10#${BASH_REMATCH[1]} * 1000000 + 10#${BASH_REMATCH[2]} * 1000 + 10#${BASH_REMATCH[3]}))
if (( expected_code < 6000 )); then
  echo "The stable signature applies from 0.6.0." >&2
  exit 1
fi

package_id=pl.krystiandevelopment.highwaytycoon
signature=$("$build_tools/apksigner" verify --verbose --print-certs "$apk")
certificate=$(awk '/certificate SHA-256 digest:/ {print $NF}' <<< "$signature")
if [[ "$certificate" != "$expected_certificate" ]]; then
  echo "APK signing certificate differs from the enrolled test certificate." >&2
  exit 1
fi
[[ "$signature" == *"APK Signature Scheme v2): true"* ]]
unzip -tq "$apk"
badging=$("$build_tools/aapt" dump badging "$apk")
[[ "$badging" == *"name='$package_id' versionCode='$expected_code' versionName='$version'"* ]]
case "${HBT_APK_ARCHITECTURES:-both}" in
  arm64) [[ "$(sed -n '/^native-code:/p' <<< "$badging")" == "native-code: 'arm64-v8a'" ]] ;;
  x86) [[ "$badging" == *"native-code: 'x86_64'"* ]] ;;
  both) [[ "$badging" == *"native-code: 'arm64-v8a' 'x86_64'"* ]] ;;
  *) echo "Unknown APK architecture mode" >&2; exit 2 ;;
esac
case "${HBT_APK_NETWORK_MODE:-offline}" in
  offline) [[ "$badging" != *android.permission.INTERNET* ]] ;;
  native) [[ "$badging" == *android.permission.INTERNET* ]] ;;
  *) echo "Unknown APK networking mode" >&2; exit 2 ;;
esac
if [[ -n "$previous" ]]; then
  previous_signature=$("$build_tools/apksigner" verify --print-certs "$previous")
  previous_certificate=$(awk '/certificate SHA-256 digest:/ {print $NF}' <<< "$previous_signature")
  previous_manifest=$("$build_tools/aapt" dump badging "$previous")
  previous_code=$(sed -n "s/^package: name='$package_id' versionCode='\([0-9]*\)'.*/\1/p" <<< "$previous_manifest")
  if [[ "$previous_certificate" != "$certificate" || -z "$previous_code" ]] || (( previous_code >= expected_code )); then
    echo "APK pair fails Android's same-package, same-signer, increasing-version checks." >&2
    exit 1
  fi
  printf 'Upgrade-compatible APK manifests and signer (%s → %s)\n' "$previous_code" "$expected_code"
fi
printf '%s\n' "$badging" | sed -n '/^package:/p; /^native-code:/p'
printf 'Signing certificate SHA-256 %s\n' "$certificate"
