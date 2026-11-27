#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
apk="${1:?APK path required}"
prior="${2:-}"
android_tools="${ANDROID_BUILD_TOOLS_DIR:?Provide Android SDK Build Tools directory}"
version="${HBT_RELEASE_VERSION:-0.9.5}"
architectures="${HBT_APK_ARCHITECTURES:-arm64}"
if [[ "$version" = 0.7.0 ]]; then architectures=both; fi
HBT_APK_ARCHITECTURES="$architectures" HBT_APK_NETWORK_MODE=native tools/android/verify-test-apk.sh "$apk" "$version" "$prior"
tree=$(mktemp)
trap 'rm -f "$tree"' EXIT
"$android_tools/aapt" dump xmltree "$apk" AndroidManifest.xml > "$tree"
for meta in org.godotengine.plugin.v2.HighwayRewarded highwaytycoon.rewarded_boost   highwaytycoon.rewarded_offline highwaytycoon.rewarded_bonus com.google.android.gms.ads.APPLICATION_ID   com.android.vending.BILLING android.permission.INTERNET; do
  if ! rg -q -F "$meta" "$tree"; then
    printf 'Missing native capability %s\n' "$meta" >&2
    exit 1
  fi
done
if [[ "$version" != 0.7.0 ]]; then
  rg -q -F 'highwaytycoon.diagnostics' "$tree"
  "$android_tools/zipalign" -c -P 16 4 "$apk"
  python3 tools/android/check-page-size.py "$apk"
fi
rg -q -F 'ca-app-pub-3940256099942544~3347511713' "$tree"
python3 - "$apk" <<'PY'
import sys, zipfile
with zipfile.ZipFile(sys.argv[1]) as archive:
    names = archive.namelist()
    assert not any(name.startswith(("assets/tests/", "assets/backend/")) for name in names)
    dex = b"".join(archive.read(name) for name in names if name.startswith("classes") and name.endswith(".dex"))
    for value in [b"HighwayRewarded", b"OnUserEarnedRewardListener", b"BillingClient", b"UserMessagingPlatform", b"CredentialManager"]:
        assert value in dex, value
print("Native bridge, test AdMob metadata, Play Billing, UMP and Credential Manager verified")
PY
