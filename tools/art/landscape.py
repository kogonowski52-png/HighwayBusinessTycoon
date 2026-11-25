"""Panel, street furniture, rocks and foliage from the Route 17 landscape kit."""
from math import cos, pi, sin, tau
import random

from kit import Model, clear_objects, export, ring_faces

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
    main = (-.06, 2.36, -.04)
    model.pipe([(0, -.025, 0), (.12, .45, .08), (.02, 1.27, .07), main],
               [.28, .23, .16, .10], BEAM, sides=13)
    leaves = [
        (-.83, 2.28, .35, .98, .87, .84, "517d47"), (.78, 2.49, .28, .95, 1.02, .88, "73965a"),
        (-.64, 3.10, -.41, .93, 1.01, .89, "739650"), (.30, 3.59, -.02, .93, 1.03, .91, "9daa5f"),
        (-.25, 3.44, .44, 1.06, .95, .85, "779850"), (.64, 3.06, -.58, .89, .96, .80, "628852"),
        (.58, 2.70, .70, .84, .77, .73, "85a660"), (-.47, 2.71, .87, .87, .85, .68, "668f49"),
    ]
    for x, y, z, w, h, d, color in leaves:
        model.orb((x, y, z), (w, h, d), color, 14, 10, irregular=.077)
    for x, y, z in [(-.68, 2.47, .30), (.53, 2.57, -.26), (.42, 2.54, .54)]:
        model.pipe([(.03, 1.38, .03), (x * .62, y * .87, z * .76), (x, y, z)],
                   [.14, .093, .058], "917257", sides=10)
    return model


def golden_tree():
    model = Model()
    model.parts = broadleaf().parts
    from kit import rgba
    swaps = ["99614a", "b98a4f", "cd9b5b", "dfa95f", "ba824d",
             "cc9b5f", "c48a4d", "d6a04c", "af774c"]
    for index, part in enumerate(model.parts[:len(swaps)]):
        part.color = rgba(swaps[index])
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
              cactus=cactus, service_yard=service_yard,
              lamp=lamp, rail=rail, billboard=billboard, pole=utility_pole, route_sign=route_sign)


def generate(root):
    for name, make in MODELS.items():
        clear_objects()
        make().mesh(name.capitalize())
        if name == "wetland":
            water().mesh("Water")
        export(root / "assets/models/landscape" / f"{name}.glb")
