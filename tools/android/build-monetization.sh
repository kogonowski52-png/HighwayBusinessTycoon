#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
mode="${1:-test}"
output="${2:?Specify an absolute APK or AAB path}"
template="${HBT_ANDROID_TEMPLATE:?Set HBT_ANDROID_TEMPLATE to android_source.zip for Godot 4.7.2}"
[[ "$output" = /* ]]
[[ -f "$template" ]]

case "$mode" in
  test|test-x86)
    [[ "$output" = *.apk ]]
    : "${GODOT_ANDROID_KEYSTORE_DEBUG_PATH:?Use the existing test certificate}"
    : "${GODOT_ANDROID_KEYSTORE_DEBUG_USER:?Use the existing test alias}"
    : "${GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD:?Supply the existing test password privately}"
    target="Android Test"
    if [[ "$mode" = test-x86 ]]; then target="Android Test x86_64"; fi
    mode=test
    export_flag=--export-debug
    ;;
  production)
    [[ "$output" = *.aab ]]
    : "${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:?Use the registered Play upload keystore}"
    : "${GODOT_ANDROID_KEYSTORE_RELEASE_USER:?Set the upload key alias}"
    : "${GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD:?Supply the upload key password privately}"
    for key in HBT_ADMOB_APP_ID HBT_REWARDED_BOOST_ID HBT_REWARDED_OFFLINE_ID HBT_REWARDED_BONUS_ID HBT_PLAY_BACKEND HBT_GOOGLE_CLIENT_ID HBT_PRIVACY_URL; do
      if [[ -z "${!key:-}" || "${!key}" = ca-app-pub-3940256099942544* ]]; then
        printf 'Provide a valid production value for %s\n' "$key" >&2
        exit 2
      fi
    done
    [[ "$HBT_ADMOB_APP_ID" =~ ^ca-app-pub-[0-9]{16}~[0-9]{10}$ ]]
    for key in HBT_REWARDED_BOOST_ID HBT_REWARDED_OFFLINE_ID HBT_REWARDED_BONUS_ID; do
      [[ "${!key}" =~ ^ca-app-pub-[0-9]{16}/[0-9]{10}$ ]]
    done
    if [[ "${HBT_INTERSTITIALS:-}" != off ]]; then
      [[ "${HBT_INTERSTITIAL_ID:-}" =~ ^ca-app-pub-[0-9]{16}/[0-9]{10}$ ]]
      [[ "$HBT_INTERSTITIAL_ID" != ca-app-pub-3940256099942544* ]]
    fi
    [[ "$HBT_PLAY_BACKEND" =~ ^https://[A-Za-z0-9.-]+(:[0-9]+)?(/[A-Za-z0-9/_-]*)?$ ]]
    [[ "$HBT_GOOGLE_CLIENT_ID" =~ ^[0-9]+-[a-zA-Z0-9_-]+\.apps\.googleusercontent\.com$ ]]
    [[ "$HBT_PRIVACY_URL" =~ ^https://[A-Za-z0-9.-]+(/[A-Za-z0-9/_.-]*)?$ ]]
    if ! curl --proto '=https' --fail --silent --show-error --max-time 15 "${HBT_PLAY_BACKEND%/}/health" \
        | python3 -c 'import json, sys; result=json.load(sys.stdin); sys.exit(result.get("status") != "ready" or result.get("mode") != "production")' 2>/dev/null; then
      printf 'The HTTPS purchase verifier must report ready before a production export.\n' >&2
      exit 2
    fi
    target="Android Play"
    export_flag=--export-release
    ;;
  *) printf 'Mode must be test, test-x86 or production\n' >&2; exit 2 ;;
esac
mkdir -p "$(dirname "$output")"
mkdir -p android
touch android/.gdignore
if [[ ! -f android/build/gradlew ]]; then
  mkdir -p android/build
  unzip -q "$template" -d android/build
  godot --version | cut -d. -f1-4 > android/.build_version
fi
gradle --no-daemon --project-dir tools/android_rewarded assembleRelease
cp tools/android_rewarded/build/outputs/aar/HighwayRewarded-release.aar addons/highway_rewarded/highway-rewarded.aar

export HBT_ANDROID_MODE="$mode"
godot --headless --path . --editor --import
godot --headless --path . "$export_flag" "$target" "$output"
test -s "$output"
