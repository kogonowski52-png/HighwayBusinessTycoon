#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
mode="${1:-test}"
output="${2:?Specify an absolute APK or AAB path}"
template="${HBT_ANDROID_TEMPLATE:?Set HBT_ANDROID_TEMPLATE to android_source.zip for Godot 4.7.2}"
[[ "$output" = /* ]]
[[ -f "$template" ]]

sign_bundle=false
require_verifier() {
  local expected_mode="$1"
  [[ "${HBT_PLAY_BACKEND:-}" =~ ^https://[A-Za-z0-9.-]+(:[0-9]+)?(/[A-Za-z0-9/_-]*)?$ ]]
  [[ "${HBT_GOOGLE_CLIENT_ID:-}" =~ ^[0-9]+-[a-zA-Z0-9_-]+\.apps\.googleusercontent\.com$ ]]
  if ! curl --proto '=https' --fail --silent --show-error --max-time 15 "${HBT_PLAY_BACKEND%/}/health" \
      | python3 -c 'import json, sys; result=json.load(sys.stdin); sys.exit(result.get("status") != "ready" or result.get("mode") != sys.argv[1])' "$expected_mode" 2>/dev/null; then
    printf 'The HTTPS purchase verifier must report ready in %s mode.\n' "$expected_mode" >&2
    exit 2
  fi
}

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
  play-unsigned|play-closed|play-test|production)
    [[ "$output" = *.aab ]]
    if [[ "$mode" = play-unsigned ]]; then
      [[ "$output" = *-unsigned.aab ]]
    else
      tools/android/sign-play-bundle.sh --check-key
      sign_bundle=true
    fi
    target="Android Play"
    export_flag=--export-release
    case "$mode" in
      play-test) require_verifier sandbox; mode=test ;;
      play-unsigned|play-closed) mode=closed ;;
    esac
    ;;
  *) printf 'Mode must be test, test-x86, play-unsigned, play-closed, play-test or production\n' >&2; exit 2 ;;
esac

if [[ "$mode" = production ]]; then
    for key in HBT_ADMOB_APP_ID HBT_REWARDED_BOOST_ID HBT_REWARDED_OFFLINE_ID HBT_REWARDED_GEMS_ID HBT_REWARDED_BONUS_ID HBT_PLAY_BACKEND HBT_GOOGLE_CLIENT_ID HBT_PRIVACY_URL; do
      if [[ -z "${!key:-}" || "${!key}" = ca-app-pub-3940256099942544* ]]; then
        printf 'Provide a valid production value for %s\n' "$key" >&2
        exit 2
      fi
    done
    [[ "$HBT_ADMOB_APP_ID" =~ ^ca-app-pub-[0-9]{16}~[0-9]{10}$ ]]
    for key in HBT_REWARDED_BOOST_ID HBT_REWARDED_OFFLINE_ID HBT_REWARDED_GEMS_ID HBT_REWARDED_BONUS_ID; do
      [[ "${!key}" =~ ^ca-app-pub-[0-9]{16}/[0-9]{10}$ ]]
    done
    if [[ "${HBT_INTERSTITIALS:-}" != off ]]; then
      [[ "${HBT_INTERSTITIAL_ID:-}" =~ ^ca-app-pub-[0-9]{16}/[0-9]{10}$ ]]
      [[ "$HBT_INTERSTITIAL_ID" != ca-app-pub-3940256099942544* ]]
    fi
    [[ "$HBT_PRIVACY_URL" =~ ^https://[A-Za-z0-9.-]+(/[A-Za-z0-9/_.-]*)?$ ]]
    require_verifier production
fi
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
if "$sign_bundle"; then
  staging=$(mktemp -d "$(dirname "$output")/.hbt-bundle-XXXXXXXX")
  trap 'rm -rf "$staging"' EXIT
  godot --headless --path . "$export_flag" "$target" "$staging/build.aab"
  tools/android/sign-play-bundle.sh "$staging/build.aab" "$output"
else
  godot --headless --path . "$export_flag" "$target" "$output"
fi
test -s "$output"
