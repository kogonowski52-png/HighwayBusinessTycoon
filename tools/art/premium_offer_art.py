"""Compose original store illustrations from the project's existing rendered props."""
from pathlib import Path

from PIL import Image, ImageColor, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2] / "assets/ui/premium"
OUT = ROOT / "offers"
SIZE = 480


def place(canvas, name, width, x, y):
    image = Image.open(ROOT / f"{name}.png").convert("RGBA")
    image = image.crop(image.getbbox())
    height = round(image.height * width / image.width)
    canvas.alpha_composite(image.resize((width, height), Image.Resampling.LANCZOS), (x, y))


def star(draw, x, y, size, color):
    draw.polygon([(x, y - size), (x + size // 4, y - size // 5), (x + size, y),
                  (x + size // 4, y + size // 5), (x, y + size),
                  (x - size // 4, y + size // 5), (x - size, y),
                  (x - size // 4, y - size // 5)], fill=color)


def plate(color):
    canvas = Image.new("RGBA", (SIZE, SIZE))
    shine = Image.new("RGBA", canvas.size)
    brush = ImageDraw.Draw(shine)
    brush.ellipse((97, 87, 391, 358), fill=(*color, 115))
    brush.ellipse((80, 342, 408, 396), fill=(20, 17, 43, 125))
    canvas.alpha_composite(shine.filter(ImageFilter.GaussianBlur(24)))
    return canvas


def export(name, color, props, glints):
    canvas = plate(color)
    for item in props:
        place(canvas, *item)
    draw = ImageDraw.Draw(canvas)
    for x, y, size in glints:
        star(draw, x, y, size, (255, 230, 150, 230))
    canvas.save(OUT / f"{name}.png", optimize=True)


def quiet():
    canvas = plate((77, 190, 151))
    brush = ImageDraw.Draw(canvas)
    brush.rounded_rectangle((76, 78, 408, 403), radius=79, fill="#16394a", outline="#102e3b", width=12)
    brush.rounded_rectangle((76, 55, 408, 377), radius=79, fill="#c28b44", outline="#502e34", width=11)
    brush.rounded_rectangle((87, 64, 397, 355), radius=69, fill="#f7cd71", outline="#ffe7a5", width=9)
    brush.rounded_rectangle((117, 93, 366, 328), radius=54, fill="#275b5b", outline="#ad753d", width=8)
    brush.rounded_rectangle((155, 144, 325, 272), radius=31, fill="#173b4b", outline="#74a999", width=5)
    brush.polygon([(222, 171), (222, 242), (284, 207)], fill="#eef6dd")
    brush.line((171, 278, 314, 135), fill="#173b4b", width=37)
    brush.line((172, 270, 315, 127), fill="#c88442", width=27)
    brush.line((173, 262, 315, 120), fill="#ffefb3", width=14)
    star(brush, 109, 104, 24, "#fff3c9")
    star(brush, 367, 322, 17, "#fff3c9")
    canvas.save(OUT / "quiet.png", optimize=True)


def tile(name, highlight, base):
    extent = (180, 142)
    light = ImageColor.getrgb(highlight)
    shade = ImageColor.getrgb(base)
    layer = Image.new("RGBA", extent)
    px = layer.load()
    for y in range(extent[1]):
        for x in range(extent[0]):
            glow = max(0, 1 - x / 220 - y / 168)
            px[x, y] = (*[round(start + (end - start) * glow) for start, end in zip(shade, light)], 255)
    canvas = Image.new("RGBA", extent)
    brush = ImageDraw.Draw(canvas)
    brush.rounded_rectangle((1, 4, 178, 140), radius=34, fill="#18152c")
    brush.rounded_rectangle((1, 1, 178, 136), radius=34, fill=highlight)
    mask = Image.new("L", extent)
    ImageDraw.Draw(mask).rounded_rectangle((4, 4, 175, 132), radius=31, fill=255)
    canvas.paste(layer, (0, 0), mask)
    canvas.save(OUT / f"tile_{name}.png", optimize=True)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    export("starter", (255, 190, 110), [("gems", 151, 288, 153), ("treasury", 391, 45, 117)],
           [(91, 132, 23), (397, 89, 19), (388, 317, 17)])
    export("gems_100", (184, 112, 211), [("gems", 347, 66, 140)],
           [(342, 139, 19), (120, 173, 13), (410, 282, 15)])
    export("gems_550", (155, 120, 239), [("gems", 214, 64, 105), ("gems", 310, 123, 189)],
           [(381, 136, 20), (106, 247, 15)])
    export("gems_1200", (150, 120, 245), [("gems", 221, 193, 100), ("gems", 356, 44, 170)],
           [(374, 105, 21), (106, 148, 16), (407, 305, 13)])
    export("gems_2500", (101, 145, 245), [("gems", 263, 125, 98), ("gems", 224, 210, 220),
           ("gems", 285, 48, 205)], [(104, 156, 23), (392, 118, 18), (379, 298, 18)])
    export("gems_6500", (177, 125, 237), [("treasury", 352, 75, 105),
           ("gems", 270, 48, 195), ("gems", 217, 204, 216)], [(96, 127, 20), (393, 139, 24)])
    quiet()
    for name, highlight, base in [
        ("petrol", "#467783", "#234457"), ("jade", "#428474", "#194e4a"),
        ("plum", "#795685", "#433153"), ("amber", "#8b6535", "#57402f"),
        ("berry", "#8a597b", "#513147"), ("blue", "#567f9d", "#2c4765"),
    ]:
        tile(name, highlight, base)


if __name__ == "__main__":
    main()
