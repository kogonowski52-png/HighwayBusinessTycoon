"""Prepare Play artwork from the publishing capture scenes and original wordmark."""
from argparse import ArgumentParser
from functools import lru_cache
from html import escape
from pathlib import Path
from math import hypot

from PIL import Image, ImageDraw, ImageFont, ImageOps


ROOT = Path(__file__).resolve().parents[2]
FONT = ROOT / "assets/fonts/OpenSans-ExtraBold.ttf"
ICONS = ROOT / "assets/icons"
LOGO = ROOT / "assets/ui/presentation/highway-wordmark.png"
RESAMPLE = Image.Resampling.LANCZOS
VIEWS = {
    "empire": ("Zbuduj własne imperium", "Build your roadside empire"),
    "fuel-station": ("Rozwijaj stację paliw", "Upgrade your gas station"),
    "open-businesses": ("Otwieraj nowe biznesy", "Open more roadside businesses"),
    "manage-team": ("Zarządzaj ekipą", "Train and manage your crew"),
    "serve-traffic": ("Obsługuj auta i ciężarówki", "Serve cars and trucks"),
    "new-districts": ("Odkrywaj nowe lokalizacje", "Explore new districts"),
    "managers": ("Zdobywaj menedżerów", "Recruit specialist managers"),
    "offline-income": ("Rozwijaj biznes także offline", "Keep earning while you’re away"),
    "world-atlas": ("Zaplanuj dalszą rozbudowę", "Plan your next expansion"),
}


@lru_cache(maxsize=12)
def backdrop(size, highlight, shade):
    image = Image.new("RGB", size)
    pixels = image.load()
    for y in range(size[1]):
        for x in range(size[0]):
            glow = max(0.0, 1.0 - hypot((x / size[0] - 0.58) * 1.28, (y / size[1] - 0.35))) ** 1.4
            pixels[x, y] = tuple(round(low + (high - low) * glow) for low, high in zip(shade, highlight))
    return image


def trim_object(source):
    art = Image.open(source).convert("RGBA")
    return art.crop(art.getchannel("A").getbbox())


def centre(layer, foreground, y=0):
    layer.alpha_composite(foreground, ((layer.width - foreground.width) // 2,
                                      (layer.height - foreground.height) // 2 + y))


def icons(brand, package, android):
    folder = package / "04_IKONA"
    folder.mkdir(parents=True, exist_ok=True)
    choices = {
        "copper": ((188, 119, 69), (67, 37, 50)),
        "jade": ((47, 143, 138), (18, 48, 62)),
        "blue-hour": ((83, 120, 176), (26, 34, 65)),
    }
    for name, (light, dark) in choices.items():
        foreground = trim_object(brand / f"icon-{name}.png")
        foreground.thumbnail((462, 402), RESAMPLE)
        image = backdrop((512, 512), light, dark).convert("RGBA")
        centre(image, foreground)
        image.save(folder / f"variant-{name}.png", optimize=True)
    selected = Image.open(folder / "variant-jade.png")
    selected.save(folder / "app_icon_512.png", optimize=True)

    foreground = trim_object(brand / "icon-jade.png")
    foreground.thumbnail((255, 214), RESAMPLE)
    layer = Image.new("RGBA", (432, 432))
    centre(layer, foreground)
    background = backdrop((432, 432), *choices["jade"])
    adaptive = folder / "adaptive"
    adaptive.mkdir(exist_ok=True)
    layer.save(adaptive / "highway-foreground.png", optimize=True)
    background.save(adaptive / "highway-background.png", optimize=True)
    if android:
        selected.resize((192, 192), RESAMPLE).save(ICONS / "highway-rc.png", optimize=True)
        layer.save(ICONS / "highway-foreground.png", optimize=True)
        background.save(ICONS / "highway-background.png", optimize=True)


def feature(brand, package):
    target = package / "05_GRAFIKA_PROMOCYJNA"
    target.mkdir(parents=True, exist_ok=True)
    frame = ImageOps.fit(Image.open(brand / "business-panorama.png").convert("RGBA"), (1024, 500), RESAMPLE)
    shade = Image.new("RGBA", frame.size)
    draw = ImageDraw.Draw(shade)
    for y in range(360, 500):
        draw.line(((0, y), (1023, y)), fill=(14, 28, 42, round(134 * (y - 360) / 140)))
    frame.alpha_composite(shade)
    logo = Image.open(LOGO).convert("RGBA").resize((304, 95), RESAMPLE)
    frame.alpha_composite(logo, (28, 388))
    frame.convert("RGB").save(target / "feature_graphic_1024x500.png", optimize=True)


def listing_frame(source, destination, caption):
    destination.parent.mkdir(parents=True, exist_ok=True)
    picture = Image.open(source).convert("RGB")
    w, h = picture.size
    title_height = round(h * 0.084)
    margin = round(w * 0.032)
    background = backdrop((180, 320), (40, 92, 103), (16, 35, 50)).resize((w, h), RESAMPLE)
    ink = ImageDraw.Draw(background)
    frame = ImageOps.contain(picture, (w - 2 * margin, h - title_height - margin), RESAMPLE)
    x, y = (w - frame.width) // 2, title_height + 3
    background.paste(frame, (x, y))
    ink.rectangle((x - 1, y - 1, x + frame.width, y + frame.height), outline="#658a8f", width=2)
    typography = ImageFont.truetype(FONT, round(w * 0.043))
    while ink.textlength(caption, font=typography) > w - 4 * margin:
        typography = ImageFont.truetype(FONT, typography.size - 1)
    ink.text((w / 2, title_height * 0.44), caption, font=typography, anchor="mm", fill="#fff2ce")
    width = round(w * .12)
    line = round(title_height * .76)
    ink.rounded_rectangle((w / 2 - width, line, w / 2 + width, line + 4), radius=2, fill="#e5af66")
    background.save(destination, quality=94, subsampling=0, optimize=True)


def listing(captures, package):
    for slot in ("06_TELEFON", "07_TABLET_7", "08_TABLET_10"):
        for index, language in enumerate(("PL", "EN")):
            for source in sorted((captures / slot / language).glob("*.jpg")):
                title = VIEWS[source.stem.split("-", 1)[1]][index]
                listing_frame(source, package / slot / language / source.name, title)


def gallery(package):
    variants = sorted((package / "04_IKONA").glob("variant-*.png"))
    adaptive = package / "04_IKONA/adaptive"
    showcase = [package / "04_IKONA/app_icon_512.png",
                package / "05_GRAFIKA_PROMOCYJNA/feature_graphic_1024x500.png",
                package / "09_ZWIASTUN/thumbnail_1280x720.jpg"]
    panels = [("Materiały promocyjne", showcase), ("Trzy warianty ikony", variants),
              ("Warstwy ikony Androida", sorted(adaptive.glob("*.png")))]
    for directory, title in (("06_TELEFON", "Telefon"), ("07_TABLET_7", "Tablet 7″"),
                             ("08_TABLET_10", "Tablet 10″")):
        for lang in ("PL", "EN"):
            panels.append((f"{title} · {lang}", sorted((package / directory / lang).glob("*.jpg"))))
    return panels


def preview(package):
    folder = package / "PODGLAD"
    folder.mkdir(parents=True, exist_ok=True)
    panels = gallery(package)
    fragments = []
    for heading, files in panels:
        cards = []
        for file in files:
            url = f"../{file.relative_to(package).as_posix()}"
            label = escape(file.stem.replace("-", " "))
            cards.append(f'<figure><a href="{url}"><img loading="lazy" src="{url}" alt="{label}"></a>'
                         f'<figcaption>{label}</figcaption></figure>')
        fragments.append(f'<section><h2>{heading}</h2><div class="art">{"".join(cards)}</div></section>')
    (folder / "index.html").write_text("""<!doctype html>
<html lang="pl">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Highway Business Tycoon · Materiały Google Play</title>
<style>
  :root { background:#132632; color:#fff0cc; font:1rem/1.5 system-ui,sans-serif; color-scheme:dark }
  body { max-width:84rem; padding:clamp(1rem,3vw,2rem); margin:auto }
  header, section { margin-block:1.3rem 2.5rem }
  h1,h2 { line-height:1.2 }
  .art { display:grid; grid-template-columns:repeat(auto-fit,minmax(min(100%,10rem),1fr)); gap:.8rem }
  figure { margin:0; background:#213a43; border-radius:.75rem; overflow:hidden }
  img { display:block; width:100%; height:auto; max-height:35rem; object-fit:contain }
  figcaption { padding:.5rem .7rem; overflow-wrap:anywhere }
  a { color:#f5c77c }
</style>
<header><h1>Highway Business Tycoon</h1><p>Materiały Google Play · 1.0.0-beta.2</p>
<p><a href="../09_ZWIASTUN/trailer_1920x1080.mp4">Obejrzyj zwiastun</a>
 · <a href="../00_START/START_TUTAJ_GOOGLE_PLAY.md">Instrukcja Google Play</a></p></header>
<main>""" + "\n".join(fragments) + "</main>\n</html>\n", encoding="utf-8")

    width = 1490
    panel_height = 368
    sheet = Image.new("RGB", (width, 148 + panel_height * len(panels)), "#132632")
    ink = ImageDraw.Draw(sheet)
    ink.text((36, 34), "Highway Business Tycoon", font=ImageFont.truetype(FONT, 52), fill="#fff0cc")
    ink.text((38, 103), "Materiały Google Play · 1.0.0-beta.2", font=ImageFont.truetype(FONT, 22), fill="#88bcb5")
    for index, (heading, files) in enumerate(panels):
        row = 139 + index * panel_height
        ink.text((38, row), heading, font=ImageFont.truetype(FONT, 29), fill="#edbe78")
        cell = (width - 72) / len(files)
        for offset, file in enumerate(files):
            art = ImageOps.contain(Image.open(file).convert("RGBA"), (int(cell) - 13, 290), RESAMPLE)
            x = round(36 + cell * (offset + .5) - art.width / 2)
            y = row + 48 + (290 - art.height) // 2
            sheet.paste(art, (x, y), art)
    sheet.save(folder / "podglad_wszystkich.jpg", quality=91, optimize=True)


def main():
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("package", type=Path)
    parser.add_argument("--brand", type=Path)
    parser.add_argument("--listing", type=Path)
    parser.add_argument("--android", action="store_true")
    parser.add_argument("--preview", action="store_true")
    options = parser.parse_args()
    if options.brand:
        icons(options.brand, options.package, options.android)
        feature(options.brand, options.package)
    if options.listing:
        listing(options.listing, options.package)
    if options.preview:
        preview(options.package)


if __name__ == "__main__":
    main()
