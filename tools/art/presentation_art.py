"""Draw the Route 17 identity, themed panels and 50 original achievement pins."""
from pathlib import Path
import math

from PIL import Image, ImageColor, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/ui/presentation"
FONT = ROOT / "assets/fonts/OpenSans-ExtraBold.ttf"
COUNTER = ROOT / "assets/fonts/Route17Counter.ttf"
FAMILIES = ["customers", "gross", "upgrades", "locations", "staff", "training",
            "reputation", "cards", "manager_ranks", "calendar"]
OUT.mkdir(parents=True, exist_ok=True)


def fill_gradient(size, high, low):
    width, height = size
    a, b = ImageColor.getrgb(high), ImageColor.getrgb(low)
    texture = Image.new("RGBA", size)
    draw = ImageDraw.Draw(texture)
    for y in range(height):
        rgb = tuple(round(x + (z - x) * y / max(1, height - 1)) for x, z in zip(a, b))
        draw.line((0, y, width, y), fill=(*rgb, 255))
    return texture


def rounded_mask(size, frame, radius):
    mask = Image.new("L", size)
    ImageDraw.Draw(mask).rounded_rectangle(frame, radius, fill=255)
    return mask


def panel(name, high, low, edge, sheen, radius=35, size=192):
    bounds = size, size
    result = Image.new("RGBA", bounds)
    ink = Image.new("RGBA", bounds, (26, 30, 28, 0))
    drop = rounded_mask(bounds, (7, 14, size - 7, size - 6), radius).filter(ImageFilter.GaussianBlur(5))
    ink.putalpha(drop.point(lambda alpha: alpha * 45 // 100))
    result.alpha_composite(ink)
    art = fill_gradient(bounds, high, low)
    art.putalpha(rounded_mask(bounds, (6, 4, size - 7, size - 12), radius))
    result.alpha_composite(art)
    draw = ImageDraw.Draw(result)
    draw.rounded_rectangle((6, 4, size - 7, size - 12), radius, outline=edge, width=3)
    draw.rounded_rectangle((11, 8, size - 12, size - 22), radius - 4, outline=sheen, width=2)
    draw.line((radius + 9, size - 13, size - radius - 10, size - 13), fill=edge, width=5)
    result.save(OUT / f"{name}.png", optimize=True)


def path(draw, points, fill, width=8):
    draw.line(points, fill=fill, width=width, joint="curve")


def symbol(draw, name, metal, dark):
    if name == "customers":
        draw.rounded_rectangle((43, 61, 112, 100), 12, outline=metal, width=8)
        path(draw, [(51, 62), (62, 46), (94, 46), (105, 62)], metal)
        draw.ellipse((50, 92, 68, 108), fill=metal)
        draw.ellipse((88, 92, 106, 108), fill=metal)
        path(draw, [(54, 77), (67, 77)], metal, 5)
        path(draw, [(87, 77), (101, 77)], metal, 5)
    elif name == "gross":
        for y in [81, 69, 57]:
            draw.rounded_rectangle((43, y, 114, y + 24), 9, fill=metal, outline=dark, width=3)
        draw.ellipse((43, 49, 114, 76), fill=metal, outline=dark, width=3)
        path(draw, [(66, 62), (92, 62)], dark, 3)
    elif name == "upgrades":
        path(draw, [(51, 100), (51, 77), (78, 51), (102, 75), (102, 100), (51, 100)], metal)
        path(draw, [(64, 63), (94, 63)], dark, 4)
        path(draw, [(77, 89), (77, 69), (67, 79)], metal, 6)
        path(draw, [(77, 69), (88, 79)], metal, 6)
    elif name == "locations":
        for x, y in [(53, 67), (100, 57), (85, 100)]:
            draw.ellipse((x - 11, y - 11, x + 11, y + 11), fill=metal)
        path(draw, [(54, 69), (101, 57), (85, 98), (54, 69)], metal, 4)
    elif name == "staff":
        for x, y, radius in [(64, 61, 14), (96, 62, 12)]:
            draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=metal)
        draw.rounded_rectangle((43, 79, 84, 106), 12, fill=metal)
        draw.rounded_rectangle((87, 78, 112, 103), 10, fill=metal)
    elif name == "training":
        draw.polygon([(41, 65), (78, 48), (116, 65), (78, 82)], fill=metal)
        path(draw, [(54, 77), (54, 93), (79, 103), (102, 93), (102, 77)], metal, 7)
    elif name == "reputation":
        points = []
        for i in range(10):
            radius = 37 if i % 2 == 0 else 17
            angle = i * math.tau / 10 - math.pi / 2
            points.append((78 + radius * math.cos(angle), 76 + radius * math.sin(angle)))
        draw.polygon(points, fill=metal)
    elif name == "cards":
        draw.rounded_rectangle((44, 54, 95, 104), 9, outline=metal, width=6)
        draw.rounded_rectangle((64, 44, 109, 97), 9, fill=metal, outline=dark, width=3)
        draw.ellipse((77, 57, 96, 76), fill=dark)
        draw.rounded_rectangle((74, 79, 99, 87), 4, fill=dark)
    elif name == "manager_ranks":
        for y in [59, 83]:
            path(draw, [(50, y + 13), (78, y - 7), (107, y + 13)], metal, 9)
    elif name == "calendar":
        draw.rounded_rectangle((46, 54, 109, 103), 9, outline=metal, width=7)
        path(draw, [(47, 69), (106, 69)], metal, 5)
        for x in [59, 94]:
            path(draw, [(x, 46), (x, 60)], metal, 5)
        path(draw, [(62, 85), (73, 94), (94, 77)], metal, 6)


def medallion(family, tier):
    palettes = [("#527c71", "#344e56", "#d4e0bb"), ("#4a8287", "#243e65", "#bddbd8"),
                ("#826c93", "#46385f", "#ecd7e9"), ("#a26857", "#623548", "#f2c8a9"),
                ("#bb8854", "#694938", "#ffe1a0")]
    high, low, metal = palettes[tier - 1]
    canvas = Image.new("RGBA", (160, 160))
    pen = ImageDraw.Draw(canvas)
    pen.polygon([(48, 108), (75, 128), (60, 151), (52, 139), (38, 139)], fill=low)
    pen.polygon([(112, 108), (85, 128), (102, 151), (109, 139), (121, 139)], fill=low)
    pen.ellipse((13, 16, 148, 146), fill="#312f3a")
    plate = fill_gradient((160, 160), high, low)
    mask = Image.new("L", (160, 160))
    ImageDraw.Draw(mask).ellipse((12, 8, 148, 139), fill=255)
    plate.putalpha(mask)
    canvas.alpha_composite(plate)
    pen.ellipse((17, 13, 143, 135), outline=metal, width=4)
    pen.ellipse((25, 21, 135, 127), outline=high, width=2)
    for index in range(tier):
        x = 80 + (index - (tier - 1) / 2) * 11
        pen.ellipse((x - 2, 116, x + 2, 120), fill=metal)
    symbol(pen, family, metal, low)
    return canvas


def logo():
    canvas = Image.new("RGBA", (930, 410))
    crest = Image.new("RGBA", (200, 185))
    mark = ImageDraw.Draw(crest)
    shape = [(8, 23), (33, 8), (167, 8), (192, 23), (184, 114), (100, 171), (16, 114)]
    mark.polygon(shape, fill="#0f282f")
    mark.line(shape + [shape[0]], fill="#eec47e", width=6, joint="curve")
    mark.line([(35, 86), (84, 46), (108, 70), (142, 40), (176, 67)], fill="#df9763", width=5, joint="curve")
    mark.line([(44, 106), (76, 89), (111, 107), (154, 88)], fill="#62b49f", width=7, joint="curve")
    mark.text((98, 110), "17", font=ImageFont.truetype(COUNTER, 59), anchor="mm",
              fill="#fff0bd", stroke_width=2, stroke_fill="#1c363b")
    canvas.alpha_composite(crest, (365, 6))
    pen = ImageDraw.Draw(canvas)
    huge = ImageFont.truetype(FONT, 122)
    pen.text((465, 254), "HIGHWAY", font=huge, anchor="mm", fill="#102a32", stroke_width=9, stroke_fill="#102a32")
    pen.text((465, 242), "HIGHWAY", font=huge, anchor="mm", fill="#fff0cf", stroke_width=2, stroke_fill="#f2c180")
    pen.text((465, 349), "B U S I N E S S   T Y C O O N", font=ImageFont.truetype(FONT, 48),
             anchor="mm", fill="#f5c689", stroke_width=2, stroke_fill="#132c33")
    return canvas


if __name__ == "__main__":
    panel("shell", "#fff8e8", "#e9d4ad", "#aa885c", "#fffaf0")
    panel("dock", "#264955", "#173039", "#101f29", "#496774")
    panel("jade", "#408575", "#255744", "#203e35", "#76bfa2", 28)
    panel("honey", "#ffe6a2", "#e3a159", "#8f5333", "#fff0b3", 28)
    panel("lavender", "#e5daf6", "#bda9dd", "#705b8a", "#f7ecff", 28)
    panel("paper", "#fffdf0", "#f4e3c0", "#bc976d", "#fffae7", 29)
    medals = OUT / "medals"
    medals.mkdir(exist_ok=True)
    for family in FAMILIES:
        for tier in range(1, 6):
            medallion(family, tier).save(medals / f"{family}_{tier}.png", optimize=True)
    logo().save(OUT / "logo.png", optimize=True)
