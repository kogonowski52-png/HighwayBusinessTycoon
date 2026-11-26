"""Compose the RC wordmark and store assets from the in-engine brand camera."""
from argparse import ArgumentParser
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps

ROOT = Path(__file__).resolve().parents[2]
UI = ROOT / "assets/ui/presentation"
ICONS = ROOT / "assets/icons"
STORE = ROOT / "release/play"
FONT = ROOT / "assets/fonts/OpenSans-ExtraBold.ttf"
RESAMPLE = Image.Resampling.LANCZOS


def mark() -> Image.Image:
    art = Image.new("RGBA", (1200, 376))
    ink = ImageDraw.Draw(art)
    # The badge follows the line of a low canopy, with paint stripes on its lower edge.
    outline = [(126, 22), (1091, 22), (1164, 72), (1120, 279), (1077, 338),
               (112, 338), (44, 277), (77, 72)]
    ink.polygon([(x, y + 14) for x, y in outline], fill="#0a222a")
    ink.polygon(outline, fill="#183b41", outline="#efc27d", width=7)
    ink.line([(130, 36), (1085, 36), (1147, 78)], fill="#fff0bd", width=3)
    ink.line([(64, 272), (122, 322), (1073, 322)], fill="#2c5d61", width=4)
    heavy = ImageFont.truetype(FONT, 178)
    ink.text((607, 146), "HIGHWAY", font=heavy, anchor="mm", fill="#142626",
             stroke_width=5, stroke_fill="#142626")
    ink.text((607, 136), "HIGHWAY", font=heavy, anchor="mm", fill="#fff0d1",
             stroke_width=2, stroke_fill="#fff0d1")
    small = ImageFont.truetype(FONT, 72)
    ink.text((607, 261), "BUSINESS TYCOON", font=small, anchor="mm", fill="#ffcd76")
    for x in [480, 552, 624, 696]:
        ink.rounded_rectangle((x, 306, x + 42, 312), radius=3, fill="#f5b96d")
    return art


def studio() -> Image.Image:
    art = Image.new("RGBA", (948, 160))
    ink = ImageDraw.Draw(art)
    ink.rounded_rectangle((14, 14, 148, 146), radius=33, fill="#1d4b50",
                          outline="#eec68d", width=4)
    ink.line([(46, 116), (69, 44)], fill="#fdd291", width=14)
    ink.line([(54, 90), (113, 45)], fill="#fff2d0", width=14)
    ink.line([(70, 80), (108, 114)], fill="#fff2d0", width=14)
    ink.text((183, 80), "KRYSTIAN DEVELOPMENT", font=ImageFont.truetype(FONT, 53),
             anchor="lm", fill="#fff0d1")
    return art


def compose(captures: Path) -> None:
    logo = mark()
    logo.save(UI / "highway-wordmark.png", optimize=True)
    studio().save(UI / "krystian-development.png", optimize=True)
    source = Image.open(captures / "station-icon.png").convert("RGB")
    # Fill the square with the car and the station; the Play listing applies its own mask.
    icon = source.crop((12, 24, 756, 768)).resize((512, 512), RESAMPLE)
    icon.convert("RGBA").save(STORE / "icon-512.png", optimize=True)
    icon.resize((192, 192), RESAMPLE).save(ICONS / "highway-rc.png", optimize=True)
    layer = Image.new("RGBA", (432, 432))
    centre = icon.resize((300, 300), RESAMPLE).convert("RGBA")
    alpha = Image.new("L", (300, 300))
    ImageDraw.Draw(alpha).rounded_rectangle((1, 1, 298, 298), radius=56, fill=255)
    centre.putalpha(alpha)
    layer.alpha_composite(centre, (66, 66))
    layer.save(ICONS / "highway-foreground.png", optimize=True)
    Image.new("RGB", (432, 432), "#19383e").save(ICONS / "highway-background.png", optimize=True)

    original = Image.open(captures / "station-title.png").convert("RGB")
    ImageOps.fit(original, (768, 1024), RESAMPLE).save(UI / "rc-station-portrait.jpg",
                                                     quality=92, optimize=True)
    original = Image.open(captures / "station-feature.png").convert("RGB")
    banner = ImageOps.fit(original, (1024, 500), RESAMPLE).convert("RGBA")
    overlay = Image.new("RGBA", banner.size)
    brush = ImageDraw.Draw(overlay)
    for x in range(620):
        opacity = round(230 * max(0.0, 1.0 - x / 620) ** .85)
        brush.line((x, 0, x, 500), fill=(16, 41, 47, opacity))
    banner.alpha_composite(overlay)
    banner.alpha_composite(logo.resize((486, 152), RESAMPLE), (26, 171))
    banner.convert("RGB").save(STORE / "feature-1024x500.png", optimize=True)


if __name__ == "__main__":
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("captures", type=Path)
    compose(parser.parse_args().captures)
