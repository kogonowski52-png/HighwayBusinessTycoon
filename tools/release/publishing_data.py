"""Write publication data from the actual bundle, APK and Godot catalogue."""

from argparse import ArgumentParser
import ast
import csv
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
from subprocess import check_output
import xml.etree.ElementTree as ET
from zipfile import ZipFile


ROOT = Path(__file__).resolve().parents[2]
ANDROID = "{http://schemas.android.com/apk/res/android}"


def sha256(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def save_tsv(path, headers, rows):
    with path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.writer(stream, delimiter="\t", lineterminator="\n")
        writer.writerow(headers)
        writer.writerows(rows)


def backend_catalog():
    source = ROOT / "backend/play/service.py"
    assignments = {node.targets[0].id: node.value for node in ast.parse(source.read_text()).body
                   if isinstance(node, ast.Assign) and isinstance(node.targets[0], ast.Name)}
    consumable = ast.literal_eval(assignments["CONSUMABLE"])
    return consumable | ast.literal_eval(assignments["PRODUCTS"].right), consumable


def product_copy(product_id, spec):
    if product_id == "remove_ads":
        return ("Wyłącza przerywniki. Pozostawia dobrowolne reklamy nagradzane.",
                "Turns off interstitial ads. Optional rewarded ads remain available.")
    if spec["section"] == "season":
        dates = [datetime.fromtimestamp(spec[key], timezone.utc).date().isoformat() for key in ("start", "end")]
        period = "–".join(dates)
        return (f"Ścieżka premium i nagrody danego sezonu. Rozgrywka {period} UTC.",
                f"Premium reward track for this season. Play period {period} UTC.")
    item = spec["item"]
    translations = {
        "cash": ("{} gotówki w grze", "{} in-game cash"),
        "diamond": ("{} diamentów", "{} gems"),
        "card": ("karta menedżera {}", "{} manager card"),
        "decor": ("dekoracja {}", "{} decoration"),
        "voucher": ("{} kuponów premii +25% przez 3 min", "{} vouchers for +25% income for 3 minutes"),
    }
    names = {"sana": ("Sana Ito", "Sana Ito"), "reese": ("Reese Morgan", "Reese Morgan"),
             "gold_gate": ("Złota brama", "Golden Entrance Arch")}
    lines = []
    for lang in range(2):
        parts = [translations[key][lang].format(names[value][lang] if key in ("card", "decor") else value)
                 for key, value in item.items()]
        sentence = ", ".join(parts) + "."
        lines.append(sentence[0].upper() + sentence[1:])
    return tuple(lines)


def products(catalog, folder):
    authoritative, consumable = backend_catalog()
    assert set(catalog) == authoritative, "the game and HTTPS verifier expose different SKUs"
    rows = []
    prices = []
    for key, spec in catalog.items():
        repeat = spec["kind"] == "consumable"
        assert repeat == (key in consumable), key
        price = f'{spec["price_pln"]/100:.2f}'.replace(".", ",")
        pl, en = product_copy(key, spec)
        rows.append([key, *spec["label"], pl, en, price,
                     "Jednorazowy, konsumowalny" if repeat else "Jednorazowy, niekonsumowalny",
                     json.dumps(spec["item"], ensure_ascii=False) if spec["item"] else pl,
                     "Tak, po konsumpcji" if repeat else "Nie dla tego SKU"])
        prices.append([key, price, "PLN"])
    save_tsv(folder / "PRODUKTY_PL_EN.tsv",
             ("SKU", "Nazwa PL", "Nazwa EN", "Opis PL", "Opis EN", "Propozycja PLN", "Typ", "Skład z gry", "Ponowny zakup"), rows)
    save_tsv(folder / "CENNIK_PLN.tsv", ("SKU", "Sugerowana cena", "Waluta"), prices)


def package_data(catalog, manifest_file, apk, aab, aapt, kit):
    root = ET.parse(manifest_file).getroot()
    sdk = root.find("uses-sdk")
    application = root.find("application")
    permissions = [entry.get(ANDROID + "name") for entry in root.findall("uses-permission")]
    code = root.get(ANDROID + "versionCode")
    version = root.get(ANDROID + "versionName")
    package = root.get("package")
    assert package == "pl.krystiandevelopment.highwaytycoon"
    assert version == catalog["version"]
    badging = check_output([aapt, "dump", "badging", apk], text=True)
    assert f"name='{package}' versionCode='{code}' versionName='{version}'" in badging
    assert sdk.get(ANDROID + "minSdkVersion") == "24"
    assert sdk.get(ANDROID + "targetSdkVersion") == "36"
    with ZipFile(aab) as artifact:
        names = artifact.namelist()
        libraries = [name for name in names if name.startswith("base/lib/") and name.endswith(".so")]
        abi = sorted({name.split("/")[2] for name in libraries})
        assert abi == ["arm64-v8a"]
        assert not any(re.fullmatch(r"META-INF/[^/]+\.(RSA|DSA|EC|SF)", name, re.I) for name in names)
    assert application.get(ANDROID + "debuggable", "false") == "false"
    metadata = {entry.get(ANDROID + "name"): entry.get(ANDROID + "value") for entry in application.findall("meta-data")}
    assert metadata["highwaytycoon.mode"] == "closed" and metadata["highwaytycoon.billing"] == "false"
    assert "highwaytycoon.privacy_url" not in metadata
    assert "com.google.android.gms.permission.AD_ID" in permissions
    header = kit / "00_START/APP_DETAILS.txt"
    header.write_text(f"""Nazwa aplikacji: Highway Business Tycoon
Nazwa pakietu: {package}
Application ID: {package}
Deweloper: Krystian Development
Typ: Gra
Kategoria: Symulacyjne (Simulation)
Tagi: kandydaci do wyszukania w Manage tags w pliku ASO_I_NAZWA.md
Język domyślny karty: polski (pl-PL)
Języki gry: polski i angielski
Dystrybucja: proponowana bezpłatna; kraje i grupy do zatwierdzenia
Reklamy: Tak; testowe Rewarded oraz Interstitial
Zakupy: wyłączone w AAB closed; Billing {metadata['com.google.android.play.billingclient.version']} spakowany
Kontakt: kogonowski52@gmail.com
Strona: https://warszawa-uslugi.pl/
Polityka prywatności: https://warszawa-uslugi.pl/highway-business-tycoon-privacy.html (adres docelowy; publikacja i test HTTPS do potwierdzenia)
VersionName: {version}
VersionCode: {code}
Minimum: Android 7.0 / API {sdk.get(ANDROID + 'minSdkVersion')}
Target SDK: API {sdk.get(ANDROID + 'targetSdkVersion')}
Architektura AAB i APK: {', '.join(abi)}
AAB release do podpisania: {aab.name} — {aab.stat().st_size} bajtów
APK testowe podpisane: {apk.name} — {apk.stat().st_size} bajtów
""", encoding="utf-8")
    stage = kit / "01_AAB"
    (stage / "SHA256SUMS.txt").write_text(f"{sha256(aab)}  {aab.name}\n{sha256(apk)}  {apk.name}\n")
    evidence = kit / "14_RAPORTY"
    source = manifest_file.read_text(encoding="utf-8").splitlines()
    (evidence / "AndroidManifest-AAB.xml").write_text(
        "\n".join(line.rstrip() for line in source if line.strip()) + "\n", encoding="utf-8")
    counts = {"lokalizacje": len(catalog["services"]), "obiekty_uslugowe": sum(map(len, catalog["services"].values())),
              "modele_pojazdow": len(catalog["vehicles"]), "menedzerowie": len(catalog["managers"]), "produkty": len(catalog["products"])}
    (evidence / "KATALOG_Z_GODOTA.json").write_text(json.dumps({**counts, **catalog}, indent=2, ensure_ascii=False) + "\n")
    return counts


def main():
    parser = ArgumentParser(description=__doc__)
    for key in ("kit", "catalog", "manifest", "apk", "aab", "aapt"):
        parser.add_argument(f"--{key}", required=True, type=Path)
    args = parser.parse_args()
    for directory in ("00_START", "01_AAB", "12_MONETYZACJA", "14_RAPORTY"):
        (args.kit / directory).mkdir(parents=True, exist_ok=True)
    catalog = json.loads(args.catalog.read_text())
    products(catalog["products"], args.kit / "12_MONETYZACJA")
    print(package_data(catalog, args.manifest, args.apk, args.aab, args.aapt, args.kit))


if __name__ == "__main__":
    main()
