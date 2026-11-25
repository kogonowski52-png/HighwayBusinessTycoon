"""Bake an original seamless aggregate and ground variation map."""
from pathlib import Path
from random import Random

from PIL import Image, ImageColor, ImageDraw, ImageFilter

SIZE = 256


def field(size, seed):
    random = Random(seed)
    grid = [[random.random() for _ in range(size)] for _ in range(size)]

    def sample(x, y):
        col, tx = divmod(x * size, SIZE)
        row, ty = divmod(y * size, SIZE)
        tx, ty = tx / SIZE, ty / SIZE
        tx, ty = tx * tx * (3 - 2 * tx), ty * ty * (3 - 2 * ty)
        a = grid[row][col] * (1 - tx) + grid[row][(col + 1) % size] * tx
        b = grid[(row + 1) % size][col] * (1 - tx) + grid[(row + 1) % size][(col + 1) % size] * tx
        return a * (1 - ty) + b * ty

    return sample


def main():
    grit, rock = field(105, 118), field(42, 417)
    variation, patches = field(7, 672), field(16, 287)
    pixels = []
    for y in range(SIZE):
        for x in range(SIZE):
            detail = grit(x, y) * 0.69 + rock(x, y) * 0.31
            tonal = variation(x, y) * 0.69 + patches(x, y) * 0.31
            pixels.append((round(detail * 255), round(tonal * 255), 128))
    texture = Image.new("RGB", (SIZE, SIZE))
    texture.putdata(pixels)
    target = Path(__file__).resolve().parents[2] / "assets/textures/paving_noise.png"
    texture.save(target, optimize=True)

    ui = target.parents[1] / "ui"
    panel(ui / "panel_ivory.png", "#fffaf0", "#f7e6c9", "#c9aa85", 27)
    panel(ui / "button_mint.png", "#3f9c82", "#257863", "#1f6456", 17)
    panel(ui / "button_honey.png", "#ffe5a6", "#efb75f", "#b48443", 17)


def panel(path, high, low, rim, radius):
    # The transparent corner includes a short contact shadow. Use with a 9-slice style box.
    scale, side = 3, 96
    edge = 3 * scale
    size = side * scale
    box = (edge, edge, size - edge - 1, size - edge * 2 - 1)
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(box, radius * scale, fill=255)
    shadow = Image.new("L", (size, size), 0)
    ImageDraw.Draw(shadow).rounded_rectangle((box[0], box[1] + 6, box[2], box[3] + 6),
                                            radius * scale, fill=88)
    result = Image.new("RGBA", mask.size, "#3f473b")
    result.putalpha(shadow.filter(ImageFilter.GaussianBlur(3.2 * scale)))
    paint = Image.new("RGBA", mask.size)
    brush = ImageDraw.Draw(paint)
    lighter, darker = ImageColor.getrgb(high), ImageColor.getrgb(low)
    for y in range(size):
        t = y / (size - 1)
        brush.line((0, y, size - 1, y), fill=tuple(round(a + (b - a) * t) for a, b in zip(lighter, darker)))
    brush.rounded_rectangle(box, radius * scale, outline=rim, width=6)
    paint.putalpha(mask)
    result.alpha_composite(paint)
    result.resize((side, side), Image.Resampling.LANCZOS).save(path, optimize=True)


if __name__ == "__main__":
    main()
