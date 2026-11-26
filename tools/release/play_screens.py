"""Prepare the device slots for Google Play from real Godot viewport captures."""
from argparse import ArgumentParser
from pathlib import Path

from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[2] / "release/play"
PHONE = (
    ("presentation", "05-modernizacja.png", "01-upgrade"),
    ("presentation", "07-pracownicy.png", "02-crew"),
    ("regional", "35-meridian-autostrada.jpg", "03-highway-traffic"),
    ("regional", "32-pearl-bay-myjnia.jpg", "04-car-wash"),
    ("regional", "19-mill-i-motor.jpg", "05-repair-shop"),
    ("regional", "03-atlas-szesciu-lokalizacji.jpg", "06-expansion"),
    ("regional", "47-menedzer-dev.jpg", "07-manager"),
    ("regional", "05-wydarzenie-wakacyjny-kurort.jpg", "08-special-event"),
)
TABLETS = {"7-inch": ("services", "team"), "10-inch": ("services", "atlas")}


def put(source: Path, target: Path, size=None) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    with Image.open(source) as original:
        capture = original.convert("RGB")
        if size:
            capture = ImageOps.fit(capture, size, Image.Resampling.LANCZOS)
        assert 320 <= min(capture.size) and max(capture.size) <= 3840, capture.size
        assert max(capture.size) <= 2 * min(capture.size), capture.size
        capture.save(target, quality=92, optimize=True)


def compose(regional: Path, presentation: Path, tablets: Path) -> None:
    sources = {"regional": regional, "presentation": presentation}
    for folder, source, target in PHONE:
        put(sources[folder] / source, ROOT / "phone" / (target + ".jpg"), (1080, 1920))
    for tablet, scenes in TABLETS.items():
        for number, scene in enumerate(scenes, start=1):
            tag = f"{number:02d}-{scene}.jpg"
            put(tablets / f"{tablet}-{tag}", ROOT / ("tablet-" + tablet) / tag)


if __name__ == "__main__":
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("regional", type=Path)
    parser.add_argument("presentation", type=Path)
    parser.add_argument("tablets", type=Path)
    options = parser.parse_args()
    compose(options.regional, options.presentation, options.tablets)
