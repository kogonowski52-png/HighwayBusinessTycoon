"""Northpoint architecture, furnishings and additive station structures."""
from math import cos, pi, sin

from kit import Model, clear_objects, export

COAL = "19363c"
DARK = "24464b"
TEAL = "24776c"
SEA = "3e9382"
MINT = "91c9ae"
SAND = "e2cba0"
CREAM = "f4e6c7"
OCHRE = "eeb357"
WOOD = "a97145"
BRICK = "bb6450"
CORAL = "de775b"
COOL = "738e91"
IRON = "41575b"
GLASS = "84c5bd"
WINDOW = "3d6d73"
LAMP = "ffdda5"
AQUA = "90f0e0"
CONCRETE = "9d9e8d"


def slab(model, pos, size, color=CONCRETE):
    model.custom_box(pos, size, color, 0.33, 0.055)


def trim(model, pos, size, color=COAL):
    model.box(pos, size, color, 0.012, "Metal")


def strip(model, pos, size, color=LAMP):
    model.box(pos, size, color, 0.012, "Light")


def planter(model, x, z, width=1.75, color=CREAM, y=0.0):
    model.custom_box((x, y + 0.19, z), (width, 0.37, 0.62), color, 0.19, 0.05)
    model.custom_box((x, y + 0.374, z), (width - 0.12, 0.057, 0.51), "554c40", 0.15, 0.012)
    for i in range(5):
        dx = (i - 2) * (width - 0.2) / 5
        scale = (0.24, 0.30, 0.27, 0.31, 0.23)[i]
        model.orb((x + dx, y + 0.49 + 0.03 * (i % 2), z + 0.03 * (i % 2)),
                  (scale, scale * 0.73, 0.24), ("66874b", "84a65b", "447b59")[i % 3],
                  10, 6, irregular=0.14)
        if i % 2 == 0:
            model.orb((x + dx, y + 0.64, z + 0.045), (0.062, 0.052, 0.068), OCHRE, 8, 5)


def bollard(model, x, z, height=0.71, color=OCHRE, y=0):
    model.box((x, y + 0.055, z), (0.24, 0.11, 0.24), IRON, 0.033, "Metal")
    model.box((x, y + height / 2, z), (0.16, height, 0.16), color, 0.065, "Paint")
    model.box((x, y + height - 0.16, z), (0.164, 0.082, 0.164), COAL, 0.014)


def bench(model, x, z, y=0.0):
    for dx in [-0.68, 0.68]:
        model.pipe([(x + dx, y, z + 0.16), (x + dx, y + 0.36, z + 0.16),
                    (x + dx, y + 0.41, z - 0.22), (x + dx, y + 0.76, z - 0.27)],
                   0.052, COAL, "Metal", sides=8)
    for i in range(4):
        model.box((x, y + 0.42, z + 0.2 - i * 0.115), (1.63, 0.068, 0.092), WOOD, 0.020)
    for i in range(2):
        model.box((x, y + 0.62 + i * 0.115, z - 0.235), (1.63, 0.082, 0.068), WOOD, 0.020)


def bin_unit(model, x, z, color=DARK, y=0):
    model.box((x, y + 0.31, z), (0.47, 0.62, 0.43), color, 0.11, "Paint")
    model.box((x, y + 0.61, z), (0.50, 0.13, 0.46), COOL, 0.055, "Metal")
    model.box((x, y + 0.48, z + 0.218), (0.30, 0.11, 0.022), COAL, 0.01, "Rubber")
    model.box((x, y + 0.29, z + 0.221), (0.12, 0.146, 0.018), MINT, 0.007)


def hvac(model, x, y, z, yaw=0.0):
    # Service module faces forward. Roof versions also expose a top fan grille.
    model.box((x, y, z), (0.95, 0.47, 0.52), "bcc8bb", 0.072, "Paint", yaw)
    for i in range(7):
        model.box((x - 0.30 + 0.1 * i, y, z + 0.263), (0.035, 0.27, 0.014), COOL, 0.008, "Metal")
    model.pipe([(x, y + 0.235, z), (x, y + 0.252, z)], 0.155, IRON, "Metal", sides=14)
    for i in range(5):
        model.box((x - 0.105 + 0.052 * i, y + 0.263, z), (0.018, 0.012, 0.20), COOL, 0, "Metal")


def north_mark(model, x, y, z, size=0.44, color=OCHRE):
    # Twin route peaks, extruded as a single enamel mark.
    for j in range(2):
        start = x + (j - 0.62) * size * 0.50
        model.pipe([(start - size * 0.34, y - size * 0.26, z),
                    (start, y + size * 0.30, z),
                    (start + size * 0.34, y - size * 0.26, z)],
                   size * 0.065, color, "Light", 8)


def canopy():
    model = Model()
    for x in [-3.64, 3.52]:
        model.custom_box((x, 0.12, 0.16), (0.83, 0.24, 0.91), CONCRETE, 0.18, 0.05)
        model.box((x, 0.41, 0.16), (0.51, 0.58, 0.54), DARK, 0.075, "Paint")
        model.box((x, 1.94, 0.16), (0.325, 3.13, 0.42), CREAM, 0.073, "Paint")
        model.box((x, 1.77, 0.384), (0.105, 2.04, 0.048), TEAL, 0.019, "Metal")
        model.pipe([(x, 2.74, 0.16), (x, 3.16, 0.51), (x, 3.31, 1.12)],
                   0.09, IRON, "Metal", 12)
        model.pipe([(x, 2.74, 0.16), (x, 3.16, -0.23), (x, 3.31, -0.97)],
                   0.09, IRON, "Metal", 12)
    model.custom_box((0, 3.40, 0), (9.40, 0.25, 3.75), COAL, 0.52, 0.065, "Metal")
    model.custom_box((0, 3.57, 0), (9.63, 0.155, 3.97), OCHRE, 0.53, 0.045, "Paint")
    model.custom_box((0, 3.76, 0), (9.67, 0.31, 4.02), TEAL, 0.57, 0.096, "Paint")
    model.custom_box((0, 3.94, -0.03), (9.27, 0.14, 3.66), "7ab4a3", 0.46, 0.048)
    model.custom_box((0, 4.016, -0.08), (8.63, 0.034, 3.13), "619a8c", 0.34, 0.012)
    for x in [-3.3, -1.65, 0, 1.65, 3.30]:
        slab(model, (x, 3.251, 0.01), (1.35, 0.067, 2.16), DARK)
        for z in [-0.69, 0.65]:
            strip(model, (x, 3.209, z), (0.96, 0.031, 0.092))
        trim(model, (x + 0.77, 3.267, 0), (0.045, 0.064, 3.34), "6a8280")
    north_mark(model, -1.76, 3.77, 2.012, 0.29, "ffdd90")
    strip(model, (0, 3.486, 1.992), (6.1, 0.023, 0.022), "ffc575")
    return model


def island():
    model = Model()
    slab(model, (0, 0.11, 0), (3.70, 0.22, 1.21), CREAM)
    model.custom_box((0, 0.227, 0), (3.47, 0.044, 0.99), "b9b29c", 0.24, 0.016)
    model.box((0, 0.34, 0), (1.02, 0.23, 0.56), COAL, 0.078, "Rubber")
    model.box((0, 0.86, 0), (0.96, 1.16, 0.58), TEAL, 0.145, "Paint")
    model.box((0, 1.34, 0.015), (1.08, 0.54, 0.62), CREAM, 0.139, "Paint")
    model.box((0, 1.56, 0.013), (1.02, 0.15, 0.59), OCHRE, 0.068, "Paint")
    model.box((0, 1.30, 0.335), (0.76, 0.281, 0.051), COAL, 0.04)
    model.box((0, 1.35, 0.367), (0.53, 0.125, 0.025), "27474d", 0.013, "Tint")
    for x, color in [(-0.17, CORAL), (-0.04, OCHRE), (0.09, MINT)]:
        strip(model, (x, 1.232, 0.37), (0.077, 0.035, 0.022), color)
    model.box((0.22, 0.95, 0.31), (0.106, 0.24, 0.034), COAL, 0.015)
    strip(model, (0.22, 1.006, 0.337), (0.064, 0.057, 0.022), AQUA)
    north_mark(model, -0.13, 0.731, 0.307, 0.27)
    for sign in [-1, 1]:
        side = sign * 0.56
        model.pipe([(side, 1.39, -0.07), (side * 1.20, 1.00, -0.09),
                    (side * 1.26, 0.37, -0.04), (side * 1.18, 0.31, 0.08),
                    (side * 1.09, 0.53, 0.19), (side, 1.08, 0.21)],
                   0.038, COAL, "Rubber", sides=10)
        model.box((side, 1.04, 0.241), (0.134, 0.235, 0.112), MINT if sign == 1 else OCHRE, 0.037, "Paint")
        trim(model, (sign * 1.64, 0.248, 0.02), (0.14, 0.025, 0.50), COOL)
        bollard(model, sign * 1.54, 0.32, 0.59, OCHRE, 0.21)
    return model


def price_sign():
    model = Model()
    slab(model, (0, 0.11, 0), (1.52, 0.22, 1.10), CREAM)
    model.box((0, 1.0, 0.04), (0.57, 1.82, 0.52), DARK, 0.13, "Metal")
    model.box((0, 2.46, 0), (1.53, 2.18, 0.46), TEAL, 0.18, "Paint")
    model.box((0, 3.50, 0), (1.50, 0.24, 0.46), OCHRE, 0.089, "Paint")
    model.box((0, 2.49, 0.239), (1.35, 1.11, 0.065), COAL, 0.07, "Tint")
    for y in [2.10, 2.49, 2.89]:
        model.box((0, y, 0.28), (1.22, 0.032, 0.023), "496466", 0.008, "Metal")
    north_mark(model, -0.39, 3.25, 0.245, 0.32)
    strip(model, (0, 1.56, 0.246), (1.13, 0.033, 0.02), AQUA)
    return model


def market():
    model = Model()
    slab(model, (0, 0.13, 0), (7.75, 0.26, 5.39), CREAM)
    slab(model, (0, 0.257, 0.09), (7.47, 0.045, 5.02), "b3ad99")
    model.box((0, 1.55, -2.07), (7.41, 2.62, 0.32), SAND, 0.12)
    model.box((-3.59, 1.54, -0.18), (0.25, 2.55, 4.21), SAND, 0.09)
    model.box((3.59, 1.34, -0.72), (0.25, 2.13, 2.97), SAND, 0.09)
    model.box((0, 2.68, 0.01), (7.42, 0.29, 4.87), TEAL, 0.095, "Paint")
    model.custom_box((0, 2.88, -0.03), (7.88, 0.29, 5.16), COAL, 0.32, 0.061)
    model.custom_box((0, 3.03, -0.06), (7.67, 0.08, 4.91), "658f84", 0.28, 0.028, "Paint")
    # Raised roof volume with seams and a mechanical enclosure behind it.
    model.custom_box((-1.12, 3.22, -0.18), (4.64, 0.38, 3.69), DARK, 0.29, 0.09, "Metal")
    model.custom_box((-1.12, 3.43, -0.20), (4.46, 0.16, 3.50), "789891", 0.24, 0.05, "Paint")
    for j in range(9):
        trim(model, (-3.08 + j * 0.49, 3.518, -0.20), (0.054, 0.03, 3.32), "456562")
    hvac(model, 2.42, 3.32, -0.91)
    hvac(model, 2.42, 3.32, 0.02)
    model.pipe([(2.48, 3.23, -1.26), (2.51, 3.13, -1.54),
                (3.09, 3.10, -1.54), (3.09, 2.43, -1.54)], 0.047, COOL, "Metal")
    # Timber service end, side window and electrical cabinets.
    for i in range(12):
        model.box((3.735, 1.13, -1.86 + i * 0.147), (0.092, 1.71, 0.084), WOOD, 0.02)
    model.box((3.67, 0.60, -1.37), (0.20, 0.49, 0.74), COOL, 0.05, "Paint")
    for x in [-3.48, -1.95, -0.62, 0.71, 2.02, 3.51]:
        trim(model, (x, 1.37, 2.209), (0.099, 2.19, 0.114))
    for y in [0.37, 2.47]:
        trim(model, (0, y, 2.207), (7.09, 0.088, 0.132))
    for x in [-2.72, -1.29, 1.36, 2.77]:
        model.box((x, 1.41, 2.208), (1.19, 1.98, 0.041), GLASS, 0, "Glass")
        trim(model, (x, 0.97, 2.238), (1.21, 0.035, 0.021), "62998d")
        model.box((x - 0.35, 1.76, 2.231), (0.038, 1.24, 0.012), "b7efe2", 0, "Glass")
    for x in [-0.282, 0.37]:
        model.box((x, 1.39, 2.231), (0.61, 2.02, 0.045), GLASS, 0, "Glass")
        trim(model, (x, 0.413, 2.238), (0.62, 0.16, 0.075))
        trim(model, (x, 2.388, 2.238), (0.62, 0.096, 0.075))
    trim(model, (0.044, 1.39, 2.244), (0.05, 2.02, 0.105))
    for x in [-0.113, 0.188]:
        model.box((x, 1.26, 2.304), (0.057, 0.38, 0.089), CREAM, 0.026, "Metal")
    for z in [0.94, 1.68]:
        model.box((3.606, 1.53, z), (0.036, 1.60, 0.63), GLASS, 0, "Glass")
    for z in [0.58, 1.31, 2.0]:
        trim(model, (3.61, 1.39, z), (0.082, 2.13, 0.092))
    trim(model, (3.61, 0.68, 1.30), (0.085, 0.10, 1.48))
    # Sign band over a separate rounded awning.
    model.custom_box((0, 2.64, 2.35), (6.87, 0.31, 0.73), DARK, 0.22, 0.063, "Paint")
    strip(model, (0, 2.478, 2.59), (6.27, 0.029, 0.06))
    north_mark(model, -2.28, 2.662, 2.726, 0.28)
    slab(model, (0.08, 0.125, 2.98), (2.0, 0.25, 0.83), CONCRETE)
    model.box((0.07, 0.256, 2.96), (1.21, 0.026, 0.53), COAL, 0.012, "Rubber")
    for j in range(8):
        trim(model, (-0.45 + j * 0.15, 0.273, 2.96), (0.027, 0.014, 0.43), COOL)
    planter(model, -2.48, 2.78, 1.40)
    bin_unit(model, 2.87, 2.74, DARK)
    # Shelving visible through the front and side glazing.
    for x in [-2.47, -0.78]:
        shelves(model, x, -0.86)
    shelves(model, -2.07, 0.67, 1.04)
    model.custom_box((2.25, 0.724, 0.07), (1.32, 0.95, 0.76), WOOD, 0.085, 0.042)
    model.box((2.25, 1.21, 0.07), (1.40, 0.10, 0.82), CREAM, 0.031)
    model.box((2.18, 1.339, 0.03), (0.37, 0.19, 0.25), COAL, 0.040, "Paint")
    strip(model, (2.18, 1.36, 0.166), (0.25, 0.072, 0.02), AQUA)
    for x in [-2.2, 0, 2.2]:
        strip(model, (x, 2.508, 1.63), (1.43, 0.049, 0.105))
    return model


def shelves(model, x, z, height=1.89):
    model.box((x, 0.29 + height / 2, z - 0.18), (1.35, height, 0.072), DARK, 0.028)
    for dx in [-0.65, 0.65]:
        model.box((x + dx, 0.29 + height / 2, z), (0.067, height, 0.47), WOOD, 0.021)
    for row in range(3):
        y = 0.33 + height * (row + 0.3) / 3.3
        model.box((x, y, z), (1.38, 0.068, 0.47), CREAM, 0.020)
        for j in range(5):
            colors = (OCHRE, CORAL, MINT, COOL, SAND)
            color = colors[(row * 3 + j) % len(colors)]
            dy = 0.12 + 0.065 * ((row * 3 + j) % 3)
            model.box((x - 0.49 + j * 0.243, y + dy / 2 + 0.037, z + 0.09),
                      (0.16, dy, 0.13), color, 0.014, "Paint")
            model.box((x - 0.49 + j * 0.243, y + dy * 0.52, z + 0.155),
                      (0.11, 0.055, 0.006), CREAM, 0.001)


def solar(model, x, y, z, width, length):
    model.custom_box((x, y, z), (width, 0.12, length), COAL, 0.045, 0.024, "Metal")
    for col in range(4):
        for row in range(3):
            model.box((x + width * (col - 1.5) / 4, y + 0.066, z + length * (row - 1) / 3),
                      (width / 4 - 0.041, 0.016, length / 3 - 0.045),
                      ("345969", "406576", "497381")[(col + row) % 3], 0.008, "Tint")
    for dx in [-0.40, 0.40]:
        model.box((x + width * dx, y - 0.132, z), (0.087, 0.21, length * 0.92), IRON, 0.02, "Metal")


def stage_two():
    model = Model()
    # Raised shaded pickup point, a separate canopy with seating and a joined plinth.
    slab(model, (5.35, 0.14, -1.78), (3.67, 0.28, 2.99), CREAM)
    for x in [4.0, 6.63]:
        model.box((x, 1.56, -2.62), (0.22, 2.55, 0.25), DARK, 0.057, "Metal")
        model.pipe([(x, 2.0, -2.62), (x, 2.69, -2.02), (x, 2.84, -1.08)],
                   0.043, IRON, "Metal", 8)
    model.custom_box((5.3, 2.86, -1.86), (3.47, 0.22, 2.18), CORAL, 0.42, 0.065, "Paint")
    model.custom_box((5.3, 2.999, -1.86), (3.31, 0.09, 2.04), SAND, 0.36, 0.028)
    strip(model, (5.33, 2.73, -0.89), (2.13, 0.055, 0.12))
    bench(model, 5.26, -2.28, 0.27)
    planter(model, 5.38, -3.08, 2.51, COAL)
    bollard(model, 7.03, -0.60, 0.64, OCHRE)
    bin_unit(model, 6.58, -1.32, TEAL, 0.27)
    return model


def stage_three():
    model = Model()
    for col in range(4):
        for row in range(2):
            solar(model, -1.62 + col * 1.26, 4.18 + row * 0.075, -0.35 + row * 1.10, 1.16, 0.96)
    # Attached maintenance wing with visible shutters, vent, pipes and roof access.
    slab(model, (-2.63, 0.12, -4.69), (2.81, 0.24, 3.11), CONCRETE)
    model.box((-2.63, 1.22, -4.7), (2.54, 2.20, 2.87), SAND, 0.113)
    model.custom_box((-2.63, 2.39, -4.7), (2.77, 0.25, 3.01), TEAL, 0.29, 0.055, "Paint")
    model.box((-2.63, 1.15, -3.244), (1.72, 1.66, 0.072), DARK, 0.069, "Metal")
    for y in range(7):
        trim(model, (-2.63, 0.47 + y * 0.215, -3.191), (1.62, 0.033, 0.029), COOL)
    hvac(model, -2.85, 2.73, -4.9)
    for z in [-5.34, -4.17]:
        model.pipe([(-1.32, 1.88, z), (-1.18, 1.82, z), (-1.18, 0.36, z)], 0.054, IRON, "Metal", 10)
    return model


def stage_four():
    model = Model()
    # A second, lower structure gives the service garden its own roofline.
    slab(model, (2.1, 0.135, -4.98), (5.23, 0.27, 3.28), CREAM)
    for x in [-0.13, 4.28]:
        model.box((x, 1.48, -6.12), (0.28, 2.66, 0.31), COAL, 0.069, "Metal")
        model.box((x, 1.48, -3.84), (0.28, 2.66, 0.31), COAL, 0.069, "Metal")
    model.custom_box((2.1, 2.82, -5.04), (5.19, 0.29, 3.10), COAL, 0.43, 0.066, "Metal")
    for x in [0.35, 1.25, 2.15, 3.05, 3.95]:
        model.box((x, 3.015, -5.07), (0.61, 0.17, 3.06), SEA, 0.067, "Paint")
    strip(model, (2.10, 2.656, -3.73), (4.10, 0.052, 0.107))
    for x in [0.95, 3.21]:
        model.box((x, 0.78, -4.05), (0.45, 1.02, 0.43), "f4d5a0", 0.14, "Paint")
        model.box((x, 1.041, -3.824), (0.32, 0.19, 0.035), DARK, 0.026)
        strip(model, (x, 1.048, -3.806), (0.21, 0.076, 0.025), AQUA)
    planter(model, 2.1, -6.09, 3.59, TEAL, 0.29)
    return model


def stage_five():
    model = Model()
    # Northpoint's rooftop lantern and a wood-slat link to the market.
    model.custom_box((0.70, 4.33, -0.34), (4.46, 0.21, 1.25), COAL, 0.25, 0.065, "Metal")
    for x in [-1.36, -0.69, -0.02, 0.65, 1.32, 1.99, 2.67]:
        trim(model, (x, 4.78, -0.35), (0.083, 0.77, 1.18), "8eb0a3")
    model.custom_box((0.69, 4.83, -0.33), (4.28, 0.89, 1.19), WINDOW, 0.21, 0.083, "Tint")
    for x in [-1.16, -0.54, 0.08, 0.70, 1.32, 1.94, 2.56]:
        strip(model, (x, 4.82, 0.283), (0.52, 0.36, 0.036), "c4dec8")
    model.custom_box((0.69, 5.27, -0.33), (4.53, 0.265, 1.41), CREAM, 0.29, 0.083, "Paint")
    model.custom_box((0.69, 5.43, -0.31), (4.15, 0.112, 1.15), SEA, 0.24, 0.035, "Paint")
    for x in [-4.15, -2.82]:
        model.box((x, 1.52, -1.74), (0.185, 2.71, 0.24), COAL, 0.053, "Metal")
    for i in range(9):
        model.box((-4.45 + i * 0.244, 2.89, -1.55), (0.173, 0.114, 2.64), WOOD, 0.034)
    for z in [-2.63, -0.53]:
        model.box((-3.41, 2.791, z), (2.46, 0.18, 0.17), DARK, 0.049, "Metal")
    strip(model, (-3.41, 2.707, -0.43), (2.05, 0.045, 0.064))
    planter(model, -3.39, -1.69, 1.72, CREAM)
    return model


def wash():
    model = Model()
    slab(model, (0, 0.13, 0.09), (6.37, 0.26, 6.51), CONCRETE)
    for x in [-2.66, 2.66]:
        model.box((x, 1.58, -0.135), (0.89, 2.73, 5.66), SAND, 0.15)
        model.box((x, 1.47, 2.49), (1.02, 2.44, 0.24), TEAL, 0.1, "Paint")
    model.box((0, 1.58, -2.65), (5.80, 2.71, 0.49), TEAL, 0.15, "Paint")
    model.custom_box((0, 2.95, -0.16), (6.44, 0.41, 5.89), DARK, 0.50, 0.11, "Paint")
    model.custom_box((0, 3.17, -0.16), (6.18, 0.10, 5.65), "6cae9d", 0.38, 0.034)
    model.custom_box((-0.64, 3.243, -0.45), (2.16, 0.17, 3.89), COAL, 0.26, 0.05, "Metal")
    for panel in range(4):
        model.custom_box((-0.64, 3.344, -1.88 + panel * 0.935), (1.91, 0.08, 0.83),
                         ("76b8b1", "8bc8bb")[panel % 2], 0.14, 0.027, "Tint")
    for x in [-2.18, 2.18]:
        trim(model, (x, 3.229, -0.25), (0.08, 0.05, 4.76), SEA)
    for z in [-2.03, -0.51, 1.18, 2.58]:
        points = [(-2.05, 0.26, z), (-2.05, 1.66, z)]
        points.extend((2.05 * cos(pi - i * pi / 12), 1.66 + 1.02 * sin(pi - i * pi / 12), z)
                      for i in range(1, 12))
        points.extend([(2.05, 1.66, z), (2.05, 0.26, z)])
        model.pipe(points, 0.148, SEA if z < 2 else MINT, "Paint", 12)
    model.box((0, 2.82, 2.83), (3.70, 0.45, 0.17), SEA, 0.13, "Paint")
    strip(model, (0, 2.571, 2.92), (3.06, 0.055, 0.047), AQUA)
    for side in [-1, 1]:
        x = side * 1.65
        model.pipe([(x, 0.46, -0.54), (x, 2.18, -0.54)], 0.29, COOL, "Metal")
        for k in range(8):
            model.custom_box((x, 0.58 + k * 0.207, -0.54), (0.83, 0.122, 0.84),
                             "499786" if k % 2 else "80b7a7", 0.36, 0.032, "Rubber")
        bollard(model, side * 2.58, 3.02, 0.72)
        for k in range(7):
            model.box((side * 1.24, 0.271, -2.0 + k * 0.70), (0.081, 0.016, 0.48), OCHRE, 0.006)
    for j in range(17):
        trim(model, (-1.35 + j * 0.17, 0.269, 2.74), (0.085, 0.013, 0.18), COAL)
    model.box((2.63, 1.34, 2.648), (0.31, 0.33, 0.09), COAL, 0.06, "Paint")
    strip(model, (2.63, 1.395, 2.708), (0.20, 0.08, 0.028), AQUA)
    hvac(model, 1.61, 3.39, -1.60)
    return model


def restaurant():
    model = Model()
    slab(model, (0, 0.16, 0), (7.91, 0.32, 5.85), CREAM)
    model.box((0, 1.42, -1.57), (7.24, 2.29, 1.49), BRICK, 0.17)
    model.box((-3.4, 1.42, -0.31), (0.44, 2.29, 3.83), BRICK, 0.12)
    model.custom_box((0, 2.54, -0.41), (7.46, 0.34, 4.12), CORAL, 0.58, 0.087, "Paint")
    model.custom_box((0.33, 2.76, -0.60), (6.21, 0.26, 3.11), "d3a681", 0.41, 0.081)
    model.custom_box((0.33, 2.947, -0.62), (6.02, 0.12, 2.97), "d9bb93", 0.40, 0.051, "Paint")
    for k in range(6):
        trim(model, (-1.57 + k * 0.73, 3.012, -0.53), (0.042, 0.018, 2.61), "b69170")
    model.custom_box((0.12, 2.38, 1.55), (6.33, 0.14, 1.36), CORAL, 0.34, 0.049, "Paint")
    model.custom_box((0.12, 2.44, 1.55), (6.18, 0.08, 1.24), "f5c28d", 0.32, 0.026, "Paint")
    strip(model, (0.07, 2.292, 2.102), (5.42, 0.053, 0.080))
    for x in [-3.35, -2.10, -0.90, 0.90, 2.15, 3.38]:
        trim(model, (x, 1.36, 1.62), (0.085, 2.07, 0.103), DARK)
    for x in [-2.72, -1.49, 0, 1.50, 2.77]:
        w = 1.64 if x == 0 else 1.13
        model.box((x, 1.35, 1.63), (w, 2.0, 0.045), GLASS, 0, "Glass")
        trim(model, (x, 0.72, 1.66), (w, 0.061, 0.07))
    for z in [-1.37, -0.1, 1.01]:
        model.box((3.44, 1.43, z), (0.08, 2.04, 1.12), GLASS, 0, "Glass")
        trim(model, (3.46, 1.43, z + 0.55), (0.09, 2.08, 0.10))
    for x in [-2.42, 2.56]:
        model.box((x, 0.69, 0.4), (1.38, 0.74, 0.48), TEAL, 0.13, "Paint")
        model.box((x, 0.95, 0.64), (1.38, 0.19, 0.45), CORAL, 0.11)
    model.custom_box((0, 2.70, 1.653), (2.76, 0.51, 0.22), COAL, 0.095, 0.042, "Paint")
    for x in [-2.49, 2.63]:
        model.pipe([(x, 0.31, 2.38), (x, 2.26, 2.38)], 0.043, DARK, "Metal")
        model.pipe([(x, 1.0, 2.38), (x, 1.065, 2.38)], 0.48, WOOD, sides=16)
        for dx in [-0.61, 0.61]:
            model.box((x + dx, 0.52, 2.44), (0.29, 0.42, 0.31), TEAL, 0.065, "Paint")
        vertices = [(x, 2.29, 2.38)]
        vertices.extend((x + cos(j * pi / 4) * 0.91, 2.07, 2.38 + sin(j * pi / 4) * 0.91) for j in range(8))
        for i in range(8):
            model.add(vertices, [(0, (i + 1) % 8 + 1, i + 1)], CORAL if i % 2 else CREAM)
    planter(model, 3.45, -1.82, 1.20, BRICK)
    hvac(model, -1.99, 3.17, -1.25)
    return model


def workshop():
    model = Model()
    slab(model, (0, 0.12, 0.15), (7.55, 0.24, 6.38), CONCRETE)
    model.box((0, 1.45, -2.34), (7.02, 2.62, 0.46), "b7bbb0", 0.10)
    for x in [-3.36, 3.36]:
        model.box((x, 1.45, -0.20), (0.32, 2.62, 4.48), COOL, 0.10)
    model.box((0, 1.46, 2.04), (0.35, 2.58, 0.27), DARK, 0.055, "Paint")
    model.custom_box((0, 2.73, -0.16), (7.42, 0.36, 5.02), COAL, 0.29, 0.087, "Metal")
    model.custom_box((0, 2.971, -0.65), (7.12, 0.22, 3.49), "6f8e91", 0.26, 0.079, "Paint")
    for j in range(12):
        x = -3.12 + j * 0.569
        trim(model, (x, 3.086, -0.65), (0.055, 0.047, 3.36), "426971")
    model.custom_box((-0.36, 3.34, -0.49), (5.47, 0.52, 1.48), WINDOW, 0.24, 0.095, "Tint")
    for j in range(7):
        trim(model, (-2.80 + j * 0.83, 3.34, 0.261), (0.10, 0.49, 0.060), COOL)
    model.custom_box((-0.36, 3.64, -0.49), (5.67, 0.20, 1.64), "658c87", 0.29, 0.066, "Paint")
    model.box((0, 2.62, 2.39), (6.75, 0.36, 0.20), SEA, 0.09, "Paint")
    for x in [-1.73, 1.72]:
        strip(model, (x, 2.394, 2.36), (2.46, 0.069, 0.104), AQUA)
        for sign in [-1, 1]:
            model.box((x + sign * 0.95, 1.28, 0.13), (0.20, 2.27, 0.26), OCHRE, 0.053, "Paint")
            model.box((x + sign * 0.77, 0.73, 0.30), (0.42, 0.115, 0.70), IRON, 0.037, "Metal")
    model.box((-1.72, 1.73, 1.94), (2.66, 1.26, 0.11), TEAL, 0.075, "Paint")
    for i in range(7):
        trim(model, (-1.72, 1.195 + i * 0.163, 2.002), (2.54, 0.036, 0.043), COOL)
    model.box((1.98, 0.717, -1.72), (1.38, 0.97, 0.56), CORAL, 0.085, "Paint")
    for i in range(4):
        trim(model, (1.98, 0.42 + i * 0.19, -1.407), (1.22, 0.056, 0.063), CREAM)
    model.pipe([(2.74, 2.98, -1.86), (2.74, 3.75, -1.86)], 0.19, IRON, "Metal", 16)
    model.pipe([(2.74, 3.74, -1.86), (2.74, 3.84, -1.86)], 0.27, COOL, "Metal", 16)
    bin_unit(model, -3.33, 2.44)
    return model


def motel():
    model = Model()
    slab(model, (0, 0.15, 0.35), (10.82, 0.30, 6.20), CREAM)
    model.box((-0.41, 2.1, -0.64), (8.88, 3.62, 3.63), "d4ae86", 0.145)
    for y in [0.283, 2.17]:
        model.custom_box((-0.41, y, 1.53), (9.19, 0.26, 1.64), "b4ab97", 0.24, 0.053)
    model.custom_box((-0.41, 3.961, -0.15), (9.56, 0.35, 4.94), TEAL, 0.47, 0.087, "Paint")
    model.custom_box((-0.43, 4.197, -0.38), (9.25, 0.24, 4.32), "719f8f", 0.35, 0.065)
    model.custom_box((1.77, 4.36, -0.75), (3.60, 0.15, 2.03), SAND, 0.24, 0.045)
    model.custom_box((1.77, 4.452, -0.75), (3.42, 0.064, 1.81), WOOD, 0.21, 0.023)
    for k in range(7):
        trim(model, (0.35 + 0.46 * k, 4.486, -0.76), (0.048, 0.019, 1.68), "c8955b")
    for x in [-4.46, -1.38, 1.64, 4.03]:
        model.box((x, 2.18, 2.14), (0.22, 3.67, 0.24), CREAM, 0.060, "Paint")
    for y in [0.28, 2.16]:
        for x in [-3.62, -1.59, 0.47, 2.52]:
            model.box((x, y + 0.77, 1.199), (0.65, 1.45, 0.11), TEAL, 0.056, "Paint")
            model.box((x + 0.70, y + 0.93, 1.198), (0.58, 0.78, 0.12), COAL, 0.056)
            model.box((x + 0.70, y + 0.93, 1.267), (0.48, 0.65, 0.037), "517779", 0.022, "Tint")
            trim(model, (x + 0.15, y + 0.79, 1.273), (0.041, 0.16, 0.05), CREAM)
            strip(model, (x + 0.27, y + 1.53, 1.264), (0.16, 0.073, 0.075))
    for y in [2.45, 3.03]:
        model.pipe([(-4.72, y, 2.19), (4.12, y, 2.19)], 0.039, DARK, "Metal", 9)
    for i in range(20):
        x = -4.68 + i * 0.456
        model.box((x, 2.73, 2.199), (0.040, 0.56, 0.051), WOOD, 0.013)
    # Open exterior staircase on the visible end.
    for i in range(10):
        model.box((4.59, 0.25 + i * 0.20, 2.83 - i * 0.252),
                  (0.91, 0.111, 0.32), "879c94", 0.034, "Metal")
    for x in [4.14, 5.03]:
        model.pipe([(x, 0.81, 2.96), (x, 2.89, 0.49), (x, 2.89, -0.27)],
                   0.044, DARK, "Metal", 9)
        for i in range(4):
            z = 2.84 - i * 0.654
            y = 0.69 + i * 0.49
            model.pipe([(x, y - 0.50, z), (x, y + 0.064, z)], 0.039, DARK, "Metal", 8)
    model.box((4.13, 3.45, 2.199), (1.09, 1.21, 0.22), CORAL, 0.185, "Paint")
    north_mark(model, 4.135, 3.69, 2.319, 0.45)
    hvac(model, -2.04, 4.535, -1.11)
    planter(model, 2.58, 2.84, 2.17, TEAL)
    return model


def parking():
    model = Model()
    slab(model, (0, 0.07, 0), (7.71, 0.14, 6.07), CONCRETE)
    model.custom_box((0, 0.148, 0.07), (7.42, 0.03, 5.68), "6c7774", 0.25, 0.01)
    for x in [-2.75, -0.91, 0.93, 2.77]:
        model.box((x, 0.170, 0.13), (0.07, 0.027, 3.35), CREAM, 0.008)
        model.box((x + 0.85, 0.215, -1.24), (1.13, 0.12, 0.23), CONCRETE, 0.05)
    for x in [-3.46, 3.46]:
        model.box((x, 1.12, -2.27), (0.24, 2.0, 0.30), DARK, 0.058, "Metal")
        bollard(model, x, 1.71, 0.63)
    model.custom_box((0, 2.15, -1.85), (7.23, 0.20, 2.16), TEAL, 0.37, 0.065, "Paint")
    for j in range(10):
        model.box((-3.25 + j * 0.722, 2.302, -1.85), (0.42, 0.13, 2.02), SEA, 0.042, "Paint")
    strip(model, (0, 2.027, -0.86), (6.28, 0.043, 0.085))
    model.box((-3.9, 1.11, 1.9), (0.135, 2.07, 0.14), IRON, 0.05, "Metal")
    model.box((-3.90, 1.95, 1.9), (0.72, 0.74, 0.13), "438e9b", 0.13, "Paint")
    planter(model, 0, -2.73, 2.9, CREAM)
    bin_unit(model, 2.95, 2.51)
    return model


MODELS = {
    "canopy": canopy, "island": island, "price_sign": price_sign, "market": market,
    "stage_2": stage_two, "stage_3": stage_three, "stage_4": stage_four, "stage_5": stage_five,
    "wash": wash, "restaurant": restaurant, "workshop": workshop, "motel": motel, "parking": parking,
}


def generate(root):
    folder = root / "assets/models/architecture"
    for name, make in MODELS.items():
        clear_objects()
        model = make()
        glass = Model()
        glass.parts = [part for part in model.parts if part.finish == "Glass"]
        model.parts = [part for part in model.parts if part.finish != "Glass"]
        model.mesh(name.capitalize())
        if glass.parts:
            glass.mesh("Glazing")
        export(folder / f"{name}.glb")
