#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

tools_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
bundle=${1:?Provide an AAB}
signature_mode=${2:?Pass signed or unsigned}
bundletool=${HBT_BUNDLETOOL_JAR:?Provide the official bundletool-all JAR}
version_name=${HBT_RELEASE_VERSION:-1.0.0-beta.2}
version_code=${HBT_EXPECTED_VERSION_CODE:-10002}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

unzip -tq "$bundle"
java -jar "$bundletool" validate --bundle="$bundle" > "$work/validation"
java -jar "$bundletool" dump manifest --bundle="$bundle" --module=base > "$work/manifest.xml"
java -jar "$bundletool" dump config --bundle="$bundle" > "$work/config.json"
python3 - "$bundle" "$work" "$version_name" "$version_code" "$signature_mode" <<'PY'
import json
import re
from pathlib import Path
from sys import argv
import xml.etree.ElementTree as ET
from zipfile import ZipFile

bundle, directory, version_name, version_code, signature_mode = argv[1:]
assert signature_mode in {"signed", "unsigned"}, "Specify signed or unsigned explicitly"
path = Path(directory)
android = "{http://schemas.android.com/apk/res/android}"
manifest = ET.parse(path / "manifest.xml").getroot()
assert manifest.get("package") == "pl.krystiandevelopment.highwaytycoon"
assert manifest.get(android + "versionName") == version_name
assert manifest.get(android + "versionCode") == version_code
sdk = manifest.find("uses-sdk")
assert sdk.get(android + "targetSdkVersion") == "36"
assert sdk.get(android + "minSdkVersion") == "24"
app = manifest.find("application")
assert app.get(android + "debuggable", "false") == "false"
assert app.get(android + "usesCleartextTraffic", "false") == "false"
meta = {node.get(android + "name"): node.get(android + "value") for node in app.findall("meta-data")}
assert meta.get("highwaytycoon.mode") == "closed"
assert meta.get("highwaytycoon.billing") == "false"
assert meta.get("com.google.android.play.billingclient.version") == "9.1.0"
assert meta.get("com.google.android.gms.ads.APPLICATION_ID") == "ca-app-pub-3940256099942544~3347511713"
assert all(meta.get(f"highwaytycoon.rewarded_{unit}") == "ca-app-pub-3940256099942544/5224354917"
           for unit in ("boost", "offline", "gems", "bonus"))
assert not any(f"highwaytycoon.{key}" in meta for key in ("diagnostics", "backend", "oauth_client"))

config = json.loads((path / "config.json").read_text())
native = config["optimizations"]["uncompressNativeLibraries"]
assert native["alignment"] == "PAGE_ALIGNMENT_16K"
with ZipFile(bundle) as archive:
    names = archive.namelist()
    architecture = {name.split("/")[2] for name in names if name.startswith("base/lib/") and name.endswith(".so")}
    assert architecture == {"arm64-v8a"}, architecture
    signatures = [name for name in names if re.fullmatch(r"META-INF/[^/]+\.(?:RSA|DSA|EC|SF)", name, re.I)]
    assert bool(signatures) == (signature_mode == "signed"), signatures
    excluded = ("base/assets/tests/", "base/assets/backend/", "base/assets/docs/", "base/assets/screenshots/",
                "base/assets/scripts/core/runtime_diagnostics.")
    assert not any(name.startswith(excluded) for name in names)
    assert not any(re.search(r"(?:\.p12|\.jks|\.keystore|/\.env|/keystore-password\.txt)$", name, re.I) for name in names)
    dex = b"".join(archive.read(name) for name in names if name.startswith("base/dex/") and name.endswith(".dex"))
    for marker in (b"HighwayRewarded", b"BillingClient", b"OnUserEarnedRewardListener", b"UserMessagingPlatform"):
        assert marker in dex, marker
    assert b"-----BEGIN PRIVATE KEY-----" not in dex and b"-----BEGIN RSA PRIVATE KEY-----" not in dex

print(f"{version_name} ({version_code}), API 36, min 24, ARM64 release, PAGE_ALIGNMENT_16K")
print("Native bridge, four rewarded test units, Billing 9.1.0 and UMP verified. Checkout and diagnostics disabled.")
PY
python3 "$tools_dir/check-page-size.py" "$bundle"
if [[ "$signature_mode" = signed ]]; then
  : "${HBT_PLAY_UPLOAD_SHA256:?Provide the Play upload certificate SHA-256}"
  expected=$(printf '%s' "$HBT_PLAY_UPLOAD_SHA256" | tr -d ':[:space:]' | tr '[:upper:]' '[:lower:]')
  verification=$(jarsigner -verify "$bundle")
  [[ "$verification" == *'jar verified.'* && "$verification" != *'unsigned entries'* ]]
  actual=$(keytool -printcert -jarfile "$bundle" | awk '/SHA256:/ {print $NF}' | tr -d ':[:space:]' | tr '[:upper:]' '[:lower:]')
  read -r test_signer < "$tools_dir/test-certificate.sha256"
  [[ "$actual" == "$expected" && "$actual" != "$test_signer" ]]
  printf 'Registered upload signature verified: %s\n' "$actual"
else
  printf 'Unsigned verification only. Sign with the registered upload key before uploading.\n'
fi
stat -c 'Bundle size: %s bytes' "$bundle"
sha256sum "$bundle"
