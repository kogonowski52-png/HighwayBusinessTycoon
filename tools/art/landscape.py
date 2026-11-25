"""Panel, street furniture, rocks and foliage from the Route 17 landscape kit."""
from math import cos, pi, sin, tau
import random

from kit import Model, bake_occlusion, clear_objects, export, ring_faces

METAL = "586e6a"
DARK = "29464a"
BEAM = "7f5e48"
CREAM = "ecdfbf"
TEAL = "327f73"


def pine():
    model = Model()
    model.pipe([(0, -.05, 0), (.05, .43, -.04), (-.09, 1.16, .02),
                (-.03, 2.19, .03), (.03, 3.2, 0)],
               [.224, .174, .116, .083, .027], BEAM, sides=13)
    # The mid-level crowns overlap but use irregular widths and rounded upper curves.
    for i, (height, width) in enumerate(((1.27, 1.08), (1.82, .91), (2.34, .70), (2.84, .46))):
        vertices = []
        levels = ((0, .62), (.06, .92), (.17, 1), (.38, .85), (.71, .52), (1.0, .10))
        for row, (dy, scale) in enumerate(levels):
            for j in range(16):
                t = j * tau / 16
                r = width * scale * (1 + .12 * sin(3 * t + i * .9) + .043 * cos(7 * t))
                vertices.append((r * cos(t) - .12 + i * .056,
                                 height + dy * 1.20 - .47 + .106 * sin(4 * t + i) * (1 - dy),
                                 r * sin(t) * .91))
        faces, smooth = ring_faces(16, len(levels), caps=True)
        model.add(vertices, faces, ("326352", "43785e", "53876a", "729970")[i], smooth=smooth)
    return model


def broadleaf():
    model = Model()
    model.pipe([(0, -.037, 0), (.03, .23, .07), (.12, .71, .12), (.07, 1.33, .11), (-.09, 2.43, -.11)],
               [.31, .239, .185, .158, .064], BEAM, sides=14)
    for n in range(4):
        angle = n * tau / 4 + .31
        dx, dz = cos(angle), sin(angle)
        model.pipe([(.09, .29, .09), (dx * .34, .08, dz * .35), (dx * .59, -.015, dz * .57)],
                   [.108, .087, .014], "84664f", sides=7)
    leaves = [
        (-.98, 2.40, .27, 1.04, .69, .91, "517d47"), (.78, 2.57, .28, .97, .71, .85, "73965a"),
        (-.62, 3.02, -.49, .98, .86, .93, "739650"), (.28, 3.55, -.12, 1.10, .81, .88, "9daa5f"),
        (-.39, 3.28, .56, .91, .71, .78, "779850"), (.66, 3.10, -.56, .84, .62, .75, "628852"),
        (.67, 2.82, .63, .73, .51, .67, "85a660"), (-.54, 2.65, .87, .71, .57, .63, "668f49"),
    ]
    for x, y, z, w, h, d, color in leaves:
        model.orb((x, y, z), (w, h, d), color, 16, 9, irregular=.093)
        model.pipe([(.07, 1.36, .12), (x * .42, y * .75, z * .55), (x * .78, y * .89, z * .90), (x, y, z)],
                   [.094, .072, .051, .028], "917257", sides=7)
    return model


def golden_tree():
    model = Model()
    model.parts = broadleaf().parts
    from kit import rgba
    swaps = ["ba824d", "cf9552", "cb9158", "e9b76f", "df9d51", "c78649", "d9a06b", "c98d56"]
    for i, tint in enumerate(swaps):
        model.parts[5 + i * 2].color = rgba(tint)
    return model


def hedge():
    model = Model()
    for j, (x, y, z, scale) in enumerate([(-.42, .27, .04, .56), (.22, .36, -.09, .64),
                                        (.64, .22, .08, .43), (-.20, .43, -.19, .48)]):
        model.orb((x, y, z), (scale, scale * .8, scale * .81),
                  ("4f8159", "6d9257", "95a65a", "73945b")[j], 12, 7, irregular=.16)
    return model


def stone():
    model = Model()
    model.orb((0, .27, 0), (.77, .45, .59), "89918a", 12, 7, irregular=.31)
    model.orb((-.51, .09, .42), (.35, .25, .39), "b1aa94", 11, 6, yaw=.6, irregular=.3)
    model.orb((.48, .08, -.23), (.40, .18, .33), "6d8378", 10, 6, yaw=-.4, irregular=.2)
    return model


def meadow():
    rng = random.Random(7482)
    model = Model()
    for i in range(11):
        x, z = rng.uniform(-.63, .63), rng.uniform(-.45, .45)
        st = rng.uniform(.10, .34)
        a = rng.uniform(0, tau)
        dx, dz = cos(a) * .059, sin(a) * .059
        model.add([(x-dx, .00, z-dz), (x+dx, .00, z+dz), (x+dx*.34, st*.55, z+dz*.34),
                   (x+dx*.42, st, z-dz*.53), (x-dx*.43, st*.51, z-dz*.43)],
                  [(0, 1, 2, 3, 4)],
                  ("779651", "9eac62", "7c8c52", "b2ae71")[i % 4])
        if i in (1, 4, 7):
            model.orb((x, st+.016, z), (.047, .041, .043),
                      ("f0c66b", "ffe29a", "bd8b64")[i % 3], 7, 4)
    return model


def contour(angle, radius):
    width = radius * (1 + .081 * sin(3 * angle + .5) + .062 * cos(5 * angle))
    return cos(angle) * width, sin(angle) * width


def landform(profile, closed=True):
    sides = 36
    points, colors = [], []
    for radius, height, tint in profile:
        for i in range(sides):
            angle = i * tau / sides
            x, z = contour(angle, radius)
            points.append((x, height, z))
            colors.append(tint)
    faces, smooth = ring_faces(sides, len(profile), caps=closed)
    model = Model()
    model.add(points, faces, profile[0][2], smooth=smooth, vertex_colors=colors)
    return model


def bank():
    return landform([(1, -.04, "78985e"), (.85, .12, "7a9c63"),
                     (.61, .52, "8fad70"), (.38, .79, "a4b67a"), (.13, .92, "aabb80")])


def wetland():
    return landform([(1.06, -.040, "7b9b5e"), (1.01, .049, "94a873"), (.97, .087, "b0ae80"),
                     (.92, .055, "a49e75"), (.88, -.015, "7d957b")], closed=False)


def water():
    vertices = []
    for i in range(36):
        x, z = contour(i * tau / 36, .936)
        vertices.append((x, .036, z))
    model = Model()
    model.add(vertices, [tuple(reversed(range(36)))], "69aca2")
    return model


def reeds():
    model = Model()
    rng = random.Random(812)
    for i in range(11):
        x, z = rng.uniform(-.38, .38), rng.uniform(-.24, .24)
        height = rng.uniform(.31, .70)
        dx, dz = rng.uniform(-.15, .15), rng.uniform(-.11, .11)
        stem = [(x, -.035, z), (x + dx * .46, height * .55, z + dz * .65), (x + dx, height, z + dz)]
        model.pipe(stem, [.022, .016, .006], ("517950", "73905a", "8d9c60")[i % 3], sides=6)
        if i % 3 == 0:
            model.orb(stem[-1], (.033, .083, .031), "8a654c", 8, 6)
    return model


def overlook():
    model = Model()
    model.custom_box((0, .055, 0), (6.75, .19, 3.21), "cbb891", .66, .065)
    for z in [-1.04, -.78, -.52, -.26, 0, .26, .52, .78, 1.04]:
        model.box((0, .177, z), (5.73, .075, .244), "ab875f" if z < 0 else "bd986f", .028)
    for x in [-1.54, 1.54]:
        for dx in [-.56, .56]:
            model.pipe([(x + dx, .214, -.80), (x + dx, .49, -.78), (x + dx, .78, -1.02)],
                       .040, DARK, "Metal", 8)
        model.box((x, .513, -.66), (1.45, .087, .41), "d0a376", .033)
        model.box((x, .733, -.97), (1.46, .14, .082), "be9166", .038)
    for x in [-2.77, 2.77]:
        model.box((x, .39, .46), (.355, .44, .389), TEAL, .077, "Paint")
        model.box((x, .617, .46), (.302, .072, .326), "998670", .030)
        for j in range(3):
            model.orb((x - .12 + j * .116, .68 + j * .014, .48), (.17, .20, .159),
                      ("648d5b", "729b61", "a0ae67")[j], 10, 6, irregular=.12)
    return model


def cactus():
    model = Model()
    for pos, scale, yaw in [((0, .62, 0), 1.0, .18), ((-.29, .44, .014), .65, -.20), ((.3, .44, -.06), .59, .28)]:
        x, y, z = pos
        model.orb(pos, (.27 * scale, .61 * scale, .207 * scale), "56906b", 18, 13,
                  yaw=yaw, irregular=.14)
        for i in [-1, 0, 1]:
            dx = i * .115 * scale
            model.pipe([(x + dx * .77, y - .36 * scale, z + .145 * scale),
                        (x + dx, y, z + .207 * scale),
                        (x + dx * .76, y + .39 * scale, z + .143 * scale)],
                       .019 * scale, "76a77b", sides=6)
    model.orb((-.158, 1.20, .041), (.096, .082, .085), "e6a064", 12, 8, irregular=.10)
    model.orb((-.157, 1.22, .078), (.050, .051, .048), "f8cf80", 10, 6)
    return model


def service_yard():
    model = Model()
    for x in [-.73, .37]:
        for z in [-.46, -.26, -.06, .14, .34]:
            model.box((x, .106, z), (.95, .078, .17), "aa7b4d", .018)
    for x, size, y in [(-.69, (.69, .50, .61), .39), (-.69, (.49, .37, .49), .82)]:
        model.box((x, y, -.07), size, "bb8c5d", .054)
        for dx in [-.19, .19]:
            model.box((x + dx, y, -.07 + size[2] * .508), (.076, size[1] * .87, .042), "dfb482", .015)
    for x, z, tint in [(0.14, .19, "cc885f"), (.65, -.27, "598b87")]:
        model.pipe([(x, .19, z), (x, .65, z)], .198, tint, "Paint", 16)
        for height in [.23, .58]:
            model.pipe([(x, height, z), (x, height + .043, z)], .21, METAL, "Metal", 16)
        model.pipe([(x + .062, .647, z), (x + .062, .667, z)], .049, DARK, "Metal", 12)
    for y in [.123, .30, .48]:
        model.pipe([(1.18, y - .071, .32), (1.18, y + .071, .32)], .27, "465052", "Rubber", 16)
        model.pipe([(1.18, y + .071, .32), (1.18, y + .080, .32)], .139, "282f32", "Rubber", 12)
    return model


def air_service():
    model = Model()
    model.custom_box((0, .079, 0), (1.64, .158, 1.21), "b0a78d", .20, .044)
    model.pipe([(-.41, .42, -.09), (-.32, .42, -.09), (.32, .42, -.09), (.43, .42, -.09)],
               [.138, .209, .209, .137], "c88552", "Paint", 16)
    for x in [-.30, .29]:
        model.box((x, .265, -.095), (.092, .189, .26), DARK, .029, "Metal")
    model.box((.16, .695, -.09), (.39, .191, .33), METAL, .058, "Metal")
    model.pipe([(-.046, .63, -.06), (-.19, .81, -.07), (-.31, .805, .17), (-.31, .805, .231)],
               .035, "a8aa99", "Metal", 10)
    model.pipe([(-.31, .805, .205), (-.31, .805, .276)], .09, CREAM, "Paint", 16)
    model.box((-.31, .802, .286), (.021, .102, .018), "9d5e41", .009, yaw=.29)
    points = []
    for i in range(35):
        theta = i * tau / 12
        points.append((-.10 + cos(theta) * .222, .185 + .003 * i, .34 + sin(theta) * .194))
    model.pipe(points, .028, "ddac58", "Rubber", 7)
    model.pipe([(0.40, .42, -.09), (.53, .45, .08), (.43, .20, .39), (.13, .183, .49)], .027, "ddb25f", "Rubber", 7)
    return model


def water_tower():
    model = Model()
    for side in [-1, 1]:
        for depth in [-1, 1]:
            x, z = side * .98, depth * .93
            model.custom_box((x, .11, z), (.47, .22, .47), "a59a84", .12, .046)
            model.pipe([(x, .22, z), (x * .94, 1.80, z * .94), (x * .79, 3.51, z * .79)], .084, BEAM, "Metal", 8)
            model.pipe([(x * .90, .68, z * .90), (-x * .79, 3.19, z * .81)], .039, "a7a084", "Metal", 7)
    model.pipe([(0, 3.36, 0), (0, 3.60, 0), (0, 3.72, 0), (0, 4.96, 0), (0, 5.17, 0)],
               [.69, .91, 1.08, 1.08, .85], "849994", "Metal", 28)
    model.pipe([(0, 5.03, 0), (0, 5.25, 0), (0, 5.51, 0)], [1.09, .92, .161], "b5a780", "Paint", 28)
    for y in [3.79, 4.72]:
        model.pipe([(0, y, 0), (0, y + .058, 0)], 1.096, "a2a58f", "Metal", 28)
    for dx in [-.125, .125]:
        model.pipe([(dx + .64, .78, .91), (dx + .64, 3.15, .91), (dx + .64, 3.45, .78)], .021, DARK, "Metal", 7)
    for y in [.97, 1.20, 1.43, 1.66, 1.89, 2.12, 2.35, 2.58, 2.81, 3.04, 3.26]:
        model.pipe([(.515, y, .914), (.765, y, .914)], .019, METAL, "Metal", 7)
    return model


def lamp():
    model = Model()
    model.box((0, .079, 0), (.36, .16, .36), "a39d89", .065)
    model.pipe([(0, .11, 0), (0, .57, 0), (.012, 2.45, 0), (.012, 3.31, 0)],
               [.085, .063, .051, .047], METAL, "Metal")
    model.pipe([(.012, 2.93, 0), (.012, 3.23, .23), (.012, 3.34, .50), (.012, 3.34, .80)],
               .042, DARK, "Metal")
    model.custom_box((.012, 3.31, .84), (.37, .13, .52), DARK, .16, .039, "Paint")
    model.custom_box((.012, 3.247, .85), (.29, .041, .42), "ffd996", .12, .014, "Light")
    return model


def rail():
    model = Model()
    for x in [-1.71, 1.69]:
        model.box((x, .27, 0), (.117, .56, .149), METAL, .019, "Metal")
        model.box((x, .066, 0), (.24, .13, .28), "afa593", .03)
    model.box((0, .395, .045), (3.91, .25, .146), METAL, .041, "Metal")
    for y in [.32, .46]:
        model.box((0, y, .128), (3.97, .064, .073), "b6bfb0", .022, "Metal")
    model.box((-1.69, .404, .177), (.14, .073, .022), "f5c76d", .012, "Light")
    return model


def billboard():
    model = Model()
    for x in [-1.43, 1.43]:
        model.box((x, .15, 0), (.59, .29, .61), "aca18b", .065)
        model.box((x, 1.44, 0), (.208, 2.74, .22), DARK, .041, "Metal")
    model.custom_box((0, 2.75, 0), (4.27, 1.42, .27), DARK, .19, .072, "Paint")
    model.box((0, 2.75, .141), (4.02, 1.15, .057), TEAL, .045, "Paint")
    for i in range(4):
        model.box((-1.64+i*.56, 2.28, .179), (.37, .071, .028), "ebc478", .012, "Light")
    return model


def utility_pole():
    model = Model()
    model.pipe([(0, -.01, 0), (0, 1.82, -.04), (0, 4.37, -.09)],
               [.133, .101, .069], "7c634e", sides=12)
    model.box((0, 3.96, -.07), (.26, .15, 1.28), "60716a", .05, "Metal")
    for z in [-.56, .43]:
        model.pipe([(0, 4.03, z), (0, 4.23, z)], [.095, .061], "a5afa1", "Paint")
        model.pipe([(0, 4.17, z), (0, 4.263, z)], .083, "bac4b4", "Paint")
    return model


def route_sign():
    model = Model()
    model.box((0, .99, 0), (.102, 1.93, .113), METAL, .03, "Metal")
    model.box((0, 1.76, .07), (1.25, .51, .11), "397679", .11, "Paint")
    model.box((0, 1.13, .06), (.829, .43, .09), "b6a36c", .093, "Paint")
    return model


MODELS = dict(pine=pine, broadleaf=broadleaf, golden_tree=golden_tree, hedge=hedge, stone=stone,
              meadow=meadow, bank=bank, wetland=wetland, reeds=reeds, overlook=overlook,
              cactus=cactus, service_yard=service_yard, air_service=air_service, water_tower=water_tower,
              lamp=lamp, rail=rail, billboard=billboard, pole=utility_pole, route_sign=route_sign)


def generate(root):
    for name, make in MODELS.items():
        clear_objects()
        mesh = make().mesh(name.capitalize())
        if name in ("broadleaf", "golden_tree", "air_service", "water_tower", "service_yard", "overlook"):
            bake_occlusion(mesh, .69, .35)
        if name == "wetland":
            water().mesh("Water")
        export(root / "assets/models/landscape" / f"{name}.glb")
