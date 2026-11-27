"""Check Play listing media, limits, catalogue, Android metadata and file digests."""

from argparse import ArgumentParser
import csv
import json
from math import hypot
from pathlib import Path
import re
from subprocess import check_output
import xml.etree.ElementTree as ET
from zipfile import ZipFile

from PIL import Image

from publishing_data import ANDROID, backend_catalog, sha256


SLOTS = {
    "06_TELEFON": ((1080, 1920), 8),
    "07_TABLET_7": ((1200, 1920), 4),
    "08_TABLET_10": ((1600, 2560), 4),
}
REQUIRED = {
    "00_START": ("START_TUTAJ_GOOGLE_PLAY.md", "APP_DETAILS.txt", "CHECKLISTA_PUBLIKACJI.md",
                 "BLOKERY_PUBLIKACJI.md", "ASO_I_NAZWA.md"),
    "01_AAB": ("RAPORT_WERYFIKACJI.md", "SHA256SUMS.txt"),
    "09_ZWIASTUN": ("trailer_1920x1080.mp4", "thumbnail_1280x720.jpg", "DODANIE_FILMU.md",
                   "youtube_title.txt", "youtube_description.txt"),
    "10_POLITYKA_PRYWATNOSCI": ("highway-business-tycoon-privacy.html", "privacy_PL.md", "privacy_EN.md",
                               "UMIESZCZENIE_NA_STRONIE.md"),
    "11_FORMULARZE_GOOGLE_PLAY": ("DATA_SAFETY_PL.md", "REKLAMY.md", "ADVERTISING_ID.md", "APP_ACCESS.md",
                                 "IARC.md", "GRUPA_DOCELOWA.md", "POZOSTALE_DEKLARACJE.md"),
    "12_MONETYZACJA": ("ADMOB.md", "BILLING_I_TESTERZY.md", "PRODUKTY_PL_EN.tsv", "CENNIK_PLN.tsv",
                      "WERYFIKATOR_HTTPS.md"),
    "13_TESTY_ZAMKNIETE": ("TESTY_ZAMKNIETE.md", "LISTA_DLA_TESTERA.md", "FORMULARZ_ZGLOSZENIA.md",
                          "SZABLON_RAPORTU.md"),
    "14_RAPORTY": ("RAPORT_TESTOW.md", "RAPORT_WYDAJNOSCI.md", "RAPORT_ZGODNOSCI.md",
                  "RAPORT_TECHNICZNY_AAB.md", "LICENCJE_ZASOBOW.md", "KATALOG_Z_GODOTA.json",
                  "AndroidManifest-AAB.xml", "Apache-2.0.txt", "LICENSE-Open-Sans.txt"),
    "PODGLAD": ("index.html", "podglad_wszystkich.jpg"),
}


def read(path):
    value = path.read_text(encoding="utf-8").strip()
    assert value and "\ufffd" not in value, path
    return value


def check_image(path, size, format, *, opaque=True, limit=None):
    with Image.open(path) as picture:
        assert picture.size == size and picture.format == format, path
        picture.load()
        if opaque:
            assert "transparency" not in picture.info, path
            if "A" in picture.getbands():
                assert picture.getchannel("A").getextrema() == (255, 255), path
    if limit is not None:
        assert path.stat().st_size <= limit, path


def check_art(kit):
    icon = kit / "04_IKONA"
    for name in ("app_icon_512", "variant-copper", "variant-jade", "variant-blue-hour"):
        check_image(icon / f"{name}.png", (512, 512), "PNG", limit=1_000_000)
    assert sha256(icon / "app_icon_512.png") == sha256(icon / "variant-jade.png"), "selected variant"
    check_image(icon / "adaptive/highway-background.png", (432, 432), "PNG")
    foreground = icon / "adaptive/highway-foreground.png"
    check_image(foreground, (432, 432), "PNG", opaque=False)
    with Image.open(foreground) as artwork:
        alpha = artwork.getchannel("A")
        assert alpha.getextrema() == (0, 255)
        radius = max(hypot(i % 432 - 215.5, i // 432 - 215.5) for i, value in enumerate(alpha.tobytes()) if value)
        assert radius <= 132, f"adaptive artwork radius: {radius}"
    feature = kit / "05_GRAFIKA_PROMOCYJNA/feature_graphic_1024x500.png"
    check_image(feature, (1024, 500), "PNG")
    with Image.open(feature) as art:
        assert art.mode == "RGB", "feature graphic uses 24-bit RGB"
    for slot, (dimensions, count) in SLOTS.items():
        for language in ("PL", "EN"):
            folder = kit / slot / language
            pictures = sorted(folder.glob("*.jpg"))
            assert len(pictures) == count and set(pictures) == set(folder.iterdir()), (slot, language)
            assert [int(p.name[:2]) for p in pictures] == list(range(1, count + 1)), (slot, language)
            for p in pictures:
                check_image(p, dimensions, "JPEG", limit=8_000_000)
            print(f"{slot}/{language}: {count} JPEG, {dimensions[0]} × {dimensions[1]}")
    folder = kit / "09_ZWIASTUN"
    check_image(folder / "thumbnail_1280x720.jpg", (1280, 720), "JPEG", limit=2_000_000)
    data = json.loads(check_output(["ffprobe", "-v", "error", "-show_streams", "-show_format", "-of",
                                    "json", folder / "trailer_1920x1080.mp4"]))
    streams = {stream["codec_type"]: stream for stream in data["streams"]}
    video = streams["video"]
    assert (video["width"], video["height"], video["codec_name"]) == (1920, 1080, "h264")
    assert streams["audio"]["codec_name"] == "aac" and 25 <= float(data["format"]["duration"]) <= 40
    print(f"Icon variants: 3; adaptive radius: {radius:.1f} px; banner: 1024 × 500 RGB")
    print(f'Trailer: 1920 × 1080 H.264 + AAC, {float(data["format"]["duration"]):.2f} s')


def check_copy(kit):
    for slot, lang in (("02_OPISY_PL", "PL"), ("03_OPISY_EN", "EN")):
        fields = {"app_name": 30, "short_description": 80, "full_description": 4000, "release_notes": 500}
        result = {}
        for field, limit in fields.items():
            value = read(kit / slot / f"{field}_{lang}.txt")
            result[field] = len(value)
            assert 0 < len(value) <= limit, (field, lang, len(value))
            assert "Roadside Empire" not in value and "<pl-PL>" not in value, (field, lang)
            if field == "full_description":
                assert all(re.search(rf"\b{count}\b", value) for count in (12, 84, 48, 33)), lang
        options = read(kit / slot / f"short_variants_{lang}.txt").splitlines()
        assert len(options) == 3 and all(0 < len(text) <= 80 for text in options), lang
        print(f"{lang}: name {result['app_name']}, short {result['short_description']}, full "
              f"{result['full_description']}, notes {result['release_notes']}, short options {list(map(len, options))}")
    names = read(kit / "00_START/ASO_I_NAZWA.md").split("## Intencja gracza", 1)[0]
    candidates = [name for name in re.findall(r"^\| (Highway [^|]+|Roadside [^|]+) ", names, re.M)]
    assert len(set(candidates)) == 5 and all(len(name.strip()) <= 30 for name in candidates), candidates
    policy = read(kit / "10_POLITYKA_PRYWATNOSCI/highway-business-tycoon-privacy.html")
    for lang in ("pl", "en"):
        assert f'<article id="{lang}" lang="{lang}">' in policy
        assert f'href="#{lang}"' in policy
    assert policy.count("mailto:kogonowski52@gmail.com") == 2 and "<script" not in policy.lower()
    print("Five alternative names under 30 characters; two languages in the static privacy policy")


def check_catalogue(kit):
    data = json.loads(read(kit / "14_RAPORTY/KATALOG_Z_GODOTA.json"))
    for field, count in (("lokalizacje", 12), ("obiekty_uslugowe", 84), ("modele_pojazdow", 48), ("menedzerowie", 33), ("produkty", 19)):
        assert data[field] == count, field
    with (kit / "12_MONETYZACJA/PRODUKTY_PL_EN.tsv").open(encoding="utf-8", newline="") as listing:
        products = list(csv.DictReader(listing, delimiter="\t"))
    with (kit / "12_MONETYZACJA/CENNIK_PLN.tsv").open(encoding="utf-8", newline="") as listing:
        prices = list(csv.DictReader(listing, delimiter="\t"))
    sku = {row["SKU"] for row in products}
    assert len(products) == len(prices) == len(sku) == 19
    assert sku == backend_catalog()[0] == set(data["products"]) == {row["SKU"] for row in prices}
    assert sum(data["products"][key]["section"] == "season" for key in sku) == 6
    for row in products:
        assert all(row.values()) and len(row["Nazwa PL"]) <= 55 and len(row["Nazwa EN"]) <= 55, row["SKU"]
        assert len(row["Opis PL"]) <= 200 and len(row["Opis EN"]) <= 200, row["SKU"]
    print("Game catalogue and verifier: 19 SKUs, including 6 season passes; 12/84/48/33 listing totals match")


def check_android(kit, artifacts):
    manifest = ET.parse(kit / "14_RAPORTY/AndroidManifest-AAB.xml").getroot()
    assert manifest.get("package") == "pl.krystiandevelopment.highwaytycoon"
    assert manifest.get(ANDROID + "versionCode") == "10002"
    assert manifest.get(ANDROID + "versionName") == "1.0.0-beta.2"
    uses = manifest.find("uses-sdk")
    assert uses.get(ANDROID + "minSdkVersion") == "24" and uses.get(ANDROID + "targetSdkVersion") == "36"
    assert manifest.find("application").get(ANDROID + "debuggable", "false") == "false"
    sums = [entry.split() for entry in read(kit / "01_AAB/SHA256SUMS.txt").splitlines()]
    assert len(sums) == 2 and {name for _, name in sums} == {
        "HighwayBusinessTycoon-1.0.0-beta.2-unsigned.aab", "HighwayBusinessTycoon-1.0.0-beta.2-test.apk"
    }
    for digest, name in sums:
        file = artifacts / name
        assert sha256(file) == digest, file
        with ZipFile(file) as android:
            assert android.testzip() is None, file
            entries = android.namelist()
            assert not any(re.search(r"(?:\.jks|\.p12|\.keystore|\.pem|\.env)$", name, re.I) for name in entries), file
            if file.suffix == ".aab":
                assert not any(re.fullmatch(r"META-INF/[^/]+\.(RSA|DSA|EC|SF)", name, re.I) for name in entries), file
            print(f"{file.name}: ZIP and SHA-256 verified; {file.stat().st_size} bytes")


def main():
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("kit", type=Path)
    parser.add_argument("--artifacts", required=True, type=Path)
    args = parser.parse_args()
    for folder, names in REQUIRED.items():
        assert all((args.kit / folder / name).stat().st_size > 0 for name in names), folder
    for file in args.kit.rglob("*"):
        assert not file.is_symlink(), file
        assert not re.search(r"(?:\.jks|\.p12|\.keystore|\.pem|\.env|password\.txt)$", file.name, re.I), file
    check_art(args.kit)
    check_copy(args.kit)
    check_catalogue(args.kit)
    check_android(args.kit, args.artifacts)
    print("Play material checks passed. Upload signature is still required for this release.")


if __name__ == "__main__":
    main()
