"""Fuel forecourt geometry at each level, including three full-scale canopy studies."""
from math import cos, pi, sin

from architecture import (AQUA, COAL, COOL, CREAM, DARK, IRON, MINT, OCHRE, SAND, SEA, TEAL, WINDOW,
                          WOOD, bench, bin_unit, bollard, hvac, north_mark, planter, slab, strip, trim)
from kit import Model

ZINC = "8b9b96"
CORRODED = "a37b59"
ENAMEL = "e9cf9c"
COPPER = "c57647"
INDIGO = "294858"


def shell(model, length, depth, rise, tint, frame, thickness, centre_z=0.0, finish="Paint"):
    """A cambered roof skin with a rounded plan and separately finished soffit."""
    rows, columns = 25, 7
    top, bottom = [], []
    top_faces, edges = [], []
    for row in range(rows):
        u = row / (rows - 1) * 2 - 1
        # Short chamfers at both ends keep the broad central face clear of the posts.
        width = 1.0 - 0.22 * max(0, (abs(u) - 0.83) / 0.17) ** 2
        for column in range(columns):
            v = column / (columns - 1) * 2 - 1
            point = (u * length / 2, rise(u, v), centre_z + v * depth / 2 * width)
            top.append(point)
            bottom.append((point[0], point[1] - thickness, point[2]))
            if row < rows - 1 and column < columns - 1:
                i = row * columns + column
                top_faces.append((i, i + 1, i + columns + 1, i + columns))
    outer = [i * columns for i in range(rows)]
    outer += [(rows - 1) * columns + i for i in range(1, columns)]
    outer += [i * columns + columns - 1 for i in range(rows - 2, -1, -1)]
    outer += list(range(columns - 2, 0, -1))
    offset = len(top)
    for i, left in enumerate(outer):
        right = outer[(i + 1) % len(outer)]
        edges.append((left, right, right + offset, left + offset))
    model.add(top, top_faces, tint, finish, smooth=True)
    model.add(top + bottom, edges + [tuple(i + offset for i in reversed(face)) for face in top_faces],
              frame, "Metal", smooth=True)
    return [top[row * columns + columns - 1] for row in range(rows)]


def rib(model, start, end, radius, color=ZINC):
    model.pipe([start, end], radius, color, "Metal", 8)


def leg(model, x, z, height, industrial=False, lean=0):
    slab(model, (x, 0.12, z), (0.72, 0.24, 0.63), "aaa68e")
    model.box((x, 0.29, z), (0.43, 0.43, 0.47), DARK, .062, "Metal")
    if industrial:
        model.box((x, height * 0.51, z), (.16, height - .27, .19), ZINC, .031, "Metal")
        model.box((x, .45, z + .104), (.157, .135, .023), CORRODED, .007)
    else:
        model.pipe([(x, .43, z), (x + lean * .14, 1.14, z), (x + lean, height, z)],
                   [.156, .124, .114], "c0ba9e", "Paint", 12)
        trim(model, (x, 1.29, z + .134), (.081, 1.59, .033), TEAL)
    for dx in [-.231, .231]:
        rib(model, (x + dx, .241, z + .192), (x + dx, .287, z + .192), .035, IRON)


def brace(model, x, z, height, offset=1.1):
    model.pipe([(x, height - .64, z), (x + .06, height - .17, z + offset * .64),
                (x + .06, height + .06, z + offset)], .075, COOL, "Metal", 10)


def worn():
    model = Model()
    rise = lambda u, v: 2.98 + 0.16 * u + 0.12 * v
    for x in [-1.39, 1.42]:
        leg(model, x, -.74, 2.89 + x * .105, industrial=True)
        brace(model, x, -.74, 2.81 + x * .105, 1.17)
    front = shell(model, 3.98, 2.20, rise, "b6ae8f", "687e75", .122, -.14, "Ceramic")
    for index in range(12):
        t = -.88 + index * .16
        x = t * 1.99
        rib(model, (x, rise(t, -1) + .022, -1.08), (x, rise(t, 1) + .022, .85), .032,
            CORRODED if index in (1, 2, 10) else ZINC)
    model.pipe(front, .034, CORRODED, "Metal", 7)
    model.custom_box((-.30, 2.85, .99), (1.85, .42, .16), "724c36", .12, .037, "Metal")
    slab(model, (-1.18, .077, -.63), (.72, .154, .61), "96907b")
    bin_unit(model, 1.15, -.67, "5c6b5d")
    for i in range(2):
        trim(model, (-1.69, .37 + .23 * i, -.72), (.068, .046, .35), IRON)
    return model


def rehab():
    model = Model()
    rise = lambda u, v: 3.20 + .14 * v + .15 * (1 - u * u)
    for x in [-2.33, 2.32]:
        leg(model, x, -.61, 3.10, industrial=True)
        brace(model, x, -.61, 3.08, 1.84)
    front = shell(model, 6.38, 2.54, rise, "a6b3a0", TEAL, .18, -.05)
    model.pipe(front, .074, "879c91", "Metal", 9)
    for i in range(9):
        t = -.88 + i * .22
        rib(model, (t * 3.19, rise(t, -.93) + .026, -1.06),
            (t * 3.19, rise(t, .93) + .026, 1.04), .027)
    model.custom_box((0, 3.18, 1.258), (3.19, .40, .16), TEAL, .103, .047, "Paint")
    strip(model, (0, 2.995, .73), (3.81, .044, .11))
    north_mark(model, -1.12, 3.178, 1.346, .25)
    return model


def clerestory(model, x, y, z, width, length):
    model.custom_box((x, y + .13, z), (width, .24, length), DARK, .23, .072, "Metal")
    model.custom_box((x, y + .43, z), (width - .21, .58, length - .19), WINDOW, .17, .069, "Tint")
    for i in range(6):
        at = x + (i - 2.5) * (width - .28) / 6
        strip(model, (at, y + .41, z + length / 2 - .074), ((width - .43) / 6, .29, .024), "bfdec5")
    slab(model, (x, y + .762, z), (width + .151, .152, length + .062), CREAM)


def service():
    model = Model()
    rise = lambda u, v: 3.54 + .20 * u * u + .10 * v
    for x in [-3.10, 3.13]:
        leg(model, x, -.56, 3.43, lean=x * -.018)
        brace(model, x, -.56, 3.31, 2.03)
    front = shell(model, 8.20, 3.35, rise, "91aa9e", TEAL, .24)
    model.pipe(front, .077, "e3bb7b", "Paint", 9)
    for x in [-2.21, -.74, .74, 2.21]:
        strip(model, (x, 3.32, .26), (1.17, .039, .17))
    clerestory(model, 1.35, 3.63, -.40, 2.97, 1.06)
    model.custom_box((-.71, 3.575, 1.726), (2.97, .39, .169), DARK, .117, .044, "Paint")
    north_mark(model, -1.81, 3.577, 1.823, .28)
    return model


def cantilever():
    model = Model()
    rise = lambda u, v: 3.77 + .29 * u * u + .13 * v
    for side in [-1, 1]:
        x = side * 3.59
        leg(model, x, -.66, 3.70, lean=-side * .17)
        brace(model, x - side * .08, -.66, 3.69, 2.44)
    front = shell(model, 9.82, 3.94, rise, ENAMEL, DARK, .27)
    model.pipe(front, .089, SEA, "Paint", 10)
    model.pipe([(x, y - .19, z + .03) for x, y, z in front], .034, "ffba73", "Light", 8)
    for x in [-3, -1.5, 0, 1.5, 3]:
        strip(model, (x, 3.49 + .22 * (x / 4.9)**2, .28), (1.02, .036, .105))
    model.custom_box((0, 3.81, 2.00), (3.59, .44, .188), TEAL, .129, .048, "Paint")
    north_mark(model, -1.37, 3.813, 2.104, .31)
    return model


def arc():
    model = Model()
    rise = lambda u, v: 3.68 + .62 * (1 - u * u) + .10 * v
    for x in [-3.51, 3.48]:
        leg(model, x, -.44, 3.73, lean=0.17)
        brace(model, x, -.44, 3.69, 2.13)
    edge = shell(model, 9.83, 4.12, rise, "a0c9bc", "385f62", .301)
    model.pipe(edge, .108, CREAM, "Paint", 10)
    model.pipe([(x, y - .19, z) for x, y, z in edge], .057, SEA, "Paint", 10)
    for t in [-.81, -.57, -.34, -.10, .14, .38, .62, .84]:
        x = t * 4.915
        rib(model, (x, rise(t, -.8) + .03, -1.62), (x, rise(t, .8) + .03, 1.66), .029)
    model.custom_box((0, 4.27, 2.13), (3.96, .60, .19), TEAL, .23, .067, "Paint")
    north_mark(model, -1.46, 4.28, 2.238, .39)
    strip(model, (0, 3.939, 1.89), (4.18, .046, .057))
    return model


def ridge():
    model = Model()
    rise = lambda u, v: 3.92 + .37 * u + .66 * u * u + .19 * v
    for side in [-1, 1]:
        x = side * 3.32
        height = rise(x / 5.19, -.42) - .20
        leg(model, x, -.72, height, lean=-side * .26)
        model.pipe([(x - side * .18, height - .82, -.72), (x - side * .42, height - .18, .12),
                    (x - side * .62, height + .09, 1.60)], .091, ZINC, "Metal", 12)
    edge = shell(model, 10.38, 4.20, rise, ENAMEL, TEAL, .30)
    model.pipe(edge, .107, "f9eed4", "Paint", 10)
    model.pipe([(x, y - .207, z + .009) for x, y, z in edge], .053, COPPER, "Paint", 9)
    model.pipe([(x, y - .247, z + .012) for x, y, z in edge[3:-3]], .025, "fbd099", "Light", 7)
    for u in [-.86, -.69, -.52, -.35, -.18, -.01, .16, .33, .50, .67, .84]:
        points = [(u * 5.19, rise(u, v) + .022, v * 1.95) for v in [-1, -.60, -.20, .20, .60, 1]]
        model.pipe(points, .028, "bc9e69", "Metal", 7)
    for u in [-.58, -.27, .04, .35, .66]:
        strip(model, (u * 5.19, rise(u, .20) - .34, .40), (1.04, .048, .18), "ffe8b8")
    clerestory(model, 2.85, 4.28, -.78, 2.79, 1.21)
    model.custom_box((-.26, 3.998, 2.14), (3.67, .64, .227), TEAL, .185, .067, "Paint")
    north_mark(model, -1.49, 4.018, 2.268, .41)
    return model


def terrace():
    model = Model()
    for x in [-3.50, 3.48]:
        for z in [-1.36, .42]:
            leg(model, x, z, 4.04)
        brace(model, x, .42, 3.86, 1.30)
    model.custom_box((0, 4.08, 0), (10.02, .39, 4.25), SEA, .51, .10, "Paint")
    slab(model, (0, 4.31, 0), (9.76, .16, 4.00), SAND)
    clerestory(model, -.54, 4.37, -.32, 5.14, 1.78)
    for x in [-3.58, 3.41]:
        planter(model, x, .74, 1.38, CREAM, 4.39)
    for x in [-4.17, -2.84, -1.51, -.18, 1.16, 2.49, 3.81]:
        rib(model, (x, 4.40, 1.82), (x, 4.96, 1.82), .035, "6f8d82")
    rib(model, (-4.28, 4.94, 1.82), (4.18, 4.94, 1.82), .046, COOL)
    model.custom_box((0, 4.09, 2.154), (3.63, .53, .18), INDIGO, .14, .056, "Paint")
    north_mark(model, -1.33, 4.10, 2.251, .38)
    return model


def shuttered_market():
    model = Model()
    slab(model, (0, .124, 0), (7.62, .248, 5.29), "a69e87")
    model.box((-.33, 1.26, -.37), (6.84, 2.12, 3.75), "bfa67f", .126, "Ceramic")
    model.custom_box((-.33, 2.34, -.39), (7.10, .262, 4.14), "758b7f", .27, .076, "Metal")
    roof = lambda u, v: 2.53 + .59 * (1 - abs(v)) + .08 * u
    shell(model, 6.80, 3.94, roof, "a78d6a", "736f60", .158, -.37, "Ceramic")
    for x in [-3.33, -2.64, -1.94, -1.25, -.55, .15, .84, 1.53, 2.23, 2.92]:
        t = x / 3.40
        model.pipe([(x, roof(t, v) + .021, -.37 + 1.93 * v) for v in [-.96, -.46, 0, .46, .96]],
                   .027, "776d57", "Metal", 6)
    for x in [-2.01, .51]:
        model.custom_box((x, 1.36, 1.543), (2.17, 1.70, .125), "5e7269", .16, .046, "Metal")
        for i in range(8):
            trim(model, (x, .64 + i * .181, 1.615), (1.92, .031, .041), ZINC)
        for dx in [-.566, .566]:
            model.box((x + dx, 1.26, 1.676), (.103, 1.48, .065), WOOD, .025, yaw=.09 * dx)
    slab(model, (-.84, .164, 2.009), (5.62, .285, .85), "b0a085")
    bench(model, 1.63, 2.30, .28)
    planter(model, -2.97, 1.96, .83, "af8971", .24)
    hvac(model, 2.73, 2.49, -.75)
    model.custom_box((-.57, 2.145, 1.684), (3.71, .405, .163), "71634d", .145, .054, "Paint")
    return model


MODELS = {"canopy_worn": worn, "canopy_rehab": rehab, "canopy_service": service, "canopy_cantilever": cantilever,
          "canopy_arc": arc, "canopy_ridge": ridge, "canopy_terrace": terrace, "market_shuttered": shuttered_market}
