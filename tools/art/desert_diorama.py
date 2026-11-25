"""Original Copper Mile roadside architecture, geology and event props."""
from math import cos, pi, sin, tau
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from kit import Model, bake_occlusion, clear_objects, export, output_root, ring_faces

CREAM, CHROME, TEAL, RUST = "ffe3b8", "aeb6aa", "216963", "b74936"
RED, CLAY, DARK, GLASS = "d86a47", "d29967", "343b3b", "4c827d"
SUN, SAND, SAGE, WHITE = "f5bd61", "e5bf89", "637c5c", "fff4cc"


def slab(model, x, z, width, length, tone=SAND):
    model.custom_box((x, .033, z), (width, .095, length), tone, .49, .025)


def neon(model, point, size, tint=WHITE):
    model.box(point, size, tint, .018, "Light")


def pane(model, x, y, z, width, height, tint=GLASS):
    model.box((x, y, z), (width + .12, height + .12, .14), CHROME, .054, "Metal")
    model.custom_box((x, y, z + .086), (width, height, .055), tint, .067, .012, "Tint")
    model.box((x, y + height * .31, z + .121), (width * .82, .025, .028), "b1c2a9", .01, "Tint")
    for shift in [-.26, .26]:
        model.box((x + width * shift, y, z + .13), (.045, height, .032), CREAM, .012, "Metal")


def door(model, x, z, tint=TEAL, y=.05):
    model.box((x, y + .92, z), (.91, 1.85, .12), tint, .075, "Paint")
    pane(model, x, y + 1.19, z + .064, .66, .94)
    model.box((x + .32, y + .75, z + .18), (.07, .19, .04), CHROME, .023, "Metal")


def stripe(model, x, y, z, width, tint=CHROME):
    model.box((x, y, z), (width, .073, .073), tint, .023, "Metal")


def table(model, x, z, parasol):
    model.pipe([(x, .09, z), (x, 2.0, z)], .049, CHROME, "Metal", 7)
    model.orb((x, .71, z), (.47, .08, .45), CREAM, 12, 5)
    if parasol:
        model.orb((x, 1.98, z), (.82, .27, .79), RED, 14, 5)
        model.orb((x, 2.08, z), (.32, .18, .31), SUN, 12, 5)
    for side in [-1, 1]:
        model.box((x + side * .57, .42, z), (.28, .082, .27), TEAL, .047)
        model.pipe([(x + side * .57, .06, z), (x + side * .57, .39, z)], .035, CHROME, "Metal", 6)


def tank():
    m = Model()
    slab(m, 0, .80, 9.65, 5.88)
    m.custom_box((0, 1.13, -2.76), (7.7, 2.15, 2.55), CREAM, .29, .13)
    m.custom_box((.44, 2.24, -2.64), (7.80, .23, 2.68), "714d42", .39, .069, "Paint")
    for x in [-2.55, .25, 2.65]:
        pane(m, x, 1.36, -1.46, 1.56, .91)
    door(m, -1.07, -1.44)
    for x in [-3.45, 3.45]:
        m.pipe([(x, .08, -.70), (x, .90, -.70), (x * .87, 2.84, -.65), (x * .79, 3.22, -.46)],
               (.19, .19, .12, .12), CREAM, "Paint", 12)
        m.box((x, .22, -.70), (.66, .30, .64), RUST, .10, "Paint")
    m.custom_box((0, 3.25, .83), (9.60, .25, 4.53), CHROME, .98, .073, "Metal")
    m.custom_box((0, 3.43, .64), (9.99, .33, 4.82), TEAL, 1.00, .085, "Paint")
    m.custom_box((-.23, 3.67, .31), (8.95, .22, 3.98), RED, .98, .060, "Paint")
    m.custom_box((-2.52, 3.79, -.13), (3.80, .14, 2.13), CREAM, .58, .046, "Paint")
    for x in [-2.32, 2.31]:
        neon(m, (x, 3.096, 1.37), (2.63, .037, .12))
    m.box((.24, 3.46, 3.052), (4.83, .45, .14), TEAL, .12, "Paint")
    return m


def pump():
    m = Model()
    slab(m, 0, 0, .87, 1.71, "ac9e7c")
    m.custom_box((0, .74, 0), (.62, 1.40, .54), RED, .13, .085, "Paint")
    m.custom_box((0, 1.36, 0), (.69, .35, .61), CREAM, .13, .075, "Paint")
    m.box((0, 1.36, .311), (.43, .22, .041), DARK, .065, "Tint")
    neon(m, (0, 1.38, .343), (.31, .05, .024), "b4ead2")
    m.pipe([(.28, 1.00, .03), (.44, .93, .14), (.54, .50, .16), (.51, .21, -.05),
            (.38, .27, -.30), (.28, .79, -.29)], .035, DARK, "Rubber", 8)
    m.box((.277, .83, -.28), (.13, .22, .14), TEAL, .04)
    return m


def cafe():
    m = Model()
    slab(m, 0, .45, 7.6, 5.12)
    m.custom_box((0, 1.22, 0), (5.92, 2.35, 3.91), CREAM, .88, .15)
    m.custom_box((0, 2.39, -.03), (6.33, .29, 4.23), RUST, .91, .067, "Paint")
    m.custom_box((-.18, 2.56, -.68), (4.96, .18, 2.82), RED, .77, .060, "Paint")
    m.box((0, .58, 1.988), (4.44, .47, .19), "cd634d", .077, "Paint")
    stripe(m, 0, .85, 2.09, 4.50)
    stripe(m, 0, .38, 2.09, 4.57)
    for x in [-1.77, .72, 2.10]:
        pane(m, x, 1.39, 1.99, .98 if x > 0 else 1.39, .79)
    door(m, -.63, 1.99)
    m.custom_box((0, 2.14, 2.21), (4.80, .19, 1.03), TEAL, .40, .060, "Paint")
    neon(m, (0, 2.034, 2.56), (3.91, .043, .079))
    table(m, 3.34, 1.23, True)
    m.orb((1.12, 2.67, -.19), (.62, .09, .54), CHROME, 13, 5, "Metal")
    m.custom_box((1.12, 2.93, -.19), (.58, .46, .55), TEAL, .23, .083, "Paint")
    m.pipe([(1.35, 2.88, -.17), (1.60, 2.84, -.17), (1.67, 3.0, -.17), (1.46, 3.05, -.17)],
           .056, TEAL, "Paint", 8)
    return m


def washrooms(truck=False):
    m = Model()
    turn = -1 if truck else 1
    span = 5.2 if truck else 4.5
    slab(m, 0, 0, span + .55, 3.8)
    m.custom_box((0, 1.20, 0), (span, 2.30, 3.2), "8fa595" if truck else CLAY, .33, .13)
    m.custom_box((.09, 2.43, -.12), (span + .47, .24, 3.51), TEAL if truck else RUST, .39, .075, "Paint")
    m.box((0, 2.60, -.50), (span * .65, .15, 1.52), "afc5ae" if truck else RED, .069, "Paint")
    for x in [-1.31, 1.31]:
        m.box((x, 1.09, 1.63 * turn), (1.03, 1.91, .12), DARK, .096, "Paint")
        m.box((x, 1.03, 1.70 * turn), (.88, 1.72, .105), TEAL if truck else CREAM, .075, "Paint")
        m.box((x, 1.69, 1.77 * turn), (.56, .25, .06), "bad0bc", .052, "Tint")
        m.box((x + .31, .91, 1.79 * turn), (.083, .14, .06), CHROME, .02, "Metal")
    m.box((0, 1.4, 1.69 * turn), (.60, .62, .116), TEAL, .093, "Paint")
    if truck:
        for x in [-.42, .42]:
            m.orb((x, 2.86, .22), (.37, .37, .50), CHROME, 11, 6, "Metal")
            m.pipe([(x, 2.87, .53), (x, 2.89, .90), (x, 2.62, 1.07)], .058, RED, "Paint", 8)
    else:
        for x in [-2.03, 2.03]:
            m.box((x, 1.16, 1.79), (.25, 2.30, .28), RUST, .07)
    return m


def service_depot():
    m = Model()
    slab(m, 0, 1.26, 12.91, 6.81, "baa487")
    m.box((0, 2.28, -2.52), (12.38, 4.56, .52), "a37960", .14)
    m.custom_box((0, 4.46, -.44), (13.28, .47, 5.88), TEAL, .48, .12, "Paint")
    m.custom_box((1.1, 4.76, -.99), (10.49, .23, 3.85), "82a697", .40, .07, "Metal")
    for seam in range(15):
        stripe(m, 0, 4.889, -2.70 + seam * .23, 10.45, "9eb9a1")
    for x in [-6.14, -.05, 6.14]:
        m.box((x, 2.16, 2.25), (.34, 4.07, .48), "675e53", .066, "Metal")
        m.box((x, .44, 2.25), (.46, .67, .55), SUN, .080, "Paint")
    for x in [-3.36, 3.36]:
        m.box((x, .59, -1.83), (2.17, 1.03, .45), RUST, .10, "Paint")
        for y in [.32, .53, .74, .96]:
            stripe(m, x, y, -1.592, 1.96)
        for side in [-1, 1]:
            m.box((x + side * 1.54, .12, 1.97), (.42, .13, 2.41), CHROME, .04, "Metal")
        neon(m, (x, 4.19, 1.97), (3.2, .07, .19))
    return m


def motel():
    m = Model()
    slab(m, 0, 1.05, 11.0, 6.03)
    m.custom_box((0, 1.07, -.23), (10.43, 2.03, 3.13), CREAM, .34, .12)
    m.custom_box((1.02, 2.98, -.53), (8.31, 1.88, 3.03), CLAY, .34, .11)
    m.custom_box((1.00, 4.06, -.49), (8.78, .28, 3.61), TEAL, .44, .075, "Paint")
    m.box((.86, 2.07, 1.34), (8.65, .22, 1.60), "c6ad83", .09)
    for index in range(4):
        x = -3.68 + index * 2.45
        door(m, x, 1.35, RUST)
        pane(m, x + .90, 1.20, 1.35, .67, .66)
        if index > 0:
            door(m, x, 1.02, TEAL, 2.17)
            pane(m, x + .90, 3.32, 1.02, .67, .66)
    for side in [-1, 1]:
        stripe(m, 1.00, 2.77 if side > 0 else 2.51, 2.08, 8.70)
    for x in range(9):
        m.pipe([(-3.12 + x * .95, 2.17, 2.09), (-3.12 + x * .95, 2.82, 2.09)], .036, CHROME, "Metal", 6)
    for index in range(10):
        m.box((-4.83, .145 + index * .193, 3.89 - index * .233), (1.16, .128, .37), "c1a17b", .048)
    m.pipe([(-5.42, .67, 3.89), (-5.42, 2.52, 1.53)], .059, TEAL, "Metal", 8)
    return m


def drive_through():
    m = Model()
    slab(m, 0, 1.09, 6.84, 4.58)
    m.custom_box((.19, 1.11, -.43), (5.53, 2.09, 3.0), "d2ad87", .42, .105)
    m.custom_box((0, 2.24, -.24), (6.66, .29, 3.89), RUST, .56, .073, "Paint")
    m.custom_box((1.47, 2.46, -.35), (3.05, .26, 3.25), TEAL, .39, .075, "Paint")
    pane(m, -1.52, 1.28, 1.11, 1.39, .88)
    pane(m, 1.71, 1.28, 1.11, 1.52, .88)
    for x in [-1.52, 1.71]:
        m.box((x, .92, 1.35), (1.60, .11, .35), CHROME, .046, "Metal")
    door(m, .13, 1.11)
    m.box((-2.95, 1.00, 1.85), (.49, 1.63, .39), TEAL, .068, "Paint")
    m.box((-2.95, 1.46, 2.06), (.38, .41, .073), "f2ddae", .035, "Tint")
    return m


def shelter(kind):
    m = Model()
    width, width_post = {"vip_park": (10.77, 4.65), "truck_park": (13.92, 6.20), "charge": (7.99, 3.47)}[kind]
    top = 4.20 if kind == "truck_park" else 2.79
    slab(m, 0, .51, width + .55, 4.3, "b59f7d")
    for x in [-width_post, width_post]:
        m.pipe([(x, .07, -.28), (x * .97, top * .62, -.43), (x * .87, top, -.55)], .124, TEAL, "Metal", 10)
        m.box((x, .25, -.28), (.5, .42, .5), RUST, .07, "Paint")
    m.custom_box((0, top, -.46), (width, .23, 2.28), CHROME, .42, .065, "Metal")
    m.custom_box((0, top + .13, -.58), (width - .14, .21, 2.06), TEAL, .36, .062, "Paint")
    if kind == "charge":
        for ix in range(6):
            x = -2.95 + ix * 1.15
            m.box((x, top + .278, -.65), (1.04, .086, 1.72), "3a6071", .043, "Tint")
            for z in [-1.20, -.74, -.28]:
                stripe(m, x, top + .33, z, .96, "69a2a5")
    else:
        for ix in range(13):
            x = (ix / 12 - .5) * (width - .6)
            m.box((x, top + .263, -.58), (.079, .047, 1.81), "81aa95", .017)
    neon(m, (0, top - .155, .49), (width - 1.1, .041, .113))
    return m


def charger():
    m = Model()
    m.custom_box((0, .80, 0), (.53, 1.51, .49), CREAM, .16, .086, "Paint")
    m.box((0, 1.35, .25), (.38, .28, .048), DARK, .064, "Tint")
    neon(m, (0, 1.37, .284), (.25, .05, .018), "6af2bf")
    m.pipe([(.21, 1.01, .11), (.36, .92, .13), (.45, .50, .14), (.43, .29, -.16), (.25, .77, -.20)],
           .044, DARK, "Rubber", 8)
    return m


def buttress():
    m = Model()
    rows = [(0.0, 1.02), (.20, .95), (.42, .65), (.61, .55), (.68, .43), (.71, .41),
            (1.45, .32), (1.54, .31), (2.18, .28), (2.33, .25), (2.53, .24), (2.60, .22)]
    shades = ["ca916b", "c9825c", "b06049", "c4744d", "eea773", "d6875d",
              "bf664d", "e69b67", "ae614d", "d58053", "e5a070", "e8ae77"]
    points = []
    for height, radius in rows:
        for side in range(15):
            angle = side * tau / 15
            swell = .89 + .20 * sin(3*angle + height) + .12 * cos(5*angle)
            points.append((cos(angle) * radius * 2.7 * swell + height * .12,
                           height + max(0, min(.14, height * .10)) * sin(angle * 4), sin(angle) * radius * 1.78 * swell))
    faces, normals = ring_faces(15, len(rows), caps=True)
    m.add(points, faces, shades[0], smooth=normals, vertex_colors=[tone for tone in shades for _ in range(15)])
    return m


def saguaro():
    m = Model()
    m.pipe([(0, -.06, 0), (.00, .43, 0), (.045, 1.28, .015), (.02, 2.32, .08), (.02, 2.52, .08)],
           [.17, .205, .184, .14, .073], "458062", sides=11)
    for sign, y in [(-1, 1.06), (1, 1.41)]:
        m.pipe([(.03, y, 0), (sign * .33, y + .02, -.04), (sign * .56, y + .32, -.02),
                (sign * .62, y + .65, .02), (sign * .64, y + .78, .04)],
               [.125, .138, .130, .101, .062], "568d68", sides=9)
    for j in range(7):
        a = j * tau / 7.0
        x, z = cos(a) * .167, sin(a) * .167
        m.pipe([(x, .1, z), (x * 1.16, .52, z * 1.16), (.045 + x, 1.28, .015 + z),
                (.02 + x * .76, 2.29, .08 + z * .76)], .016, "7caa79", sides=6)
    return m


def agave():
    m = Model()
    for index in range(12):
        angle = index * tau / 8.5
        radius = .50 + .14 * cos(index * 7.1)
        x, z = cos(angle) * radius, sin(angle) * radius
        m.pipe([(0, .052, 0), (x * .5, .18, z * .5), (x * .81, .29, z * .81),
                (x, .47 + index % 3 * .11, z)], [.11, .089, .046, .012],
               ["819174", "6d9b85", "b0af68"][index % 3], sides=6)
    return m


def pylon():
    m = Model()
    slab(m, 0, 0, 1.18, .84, "b48059")
    m.pipe([(-.22,.06,0),(-.22, 3.76, 0)], .13, CHROME, "Metal", 10)
    m.pipe([(.14,.06,0),(.14, 3.41, 0)], .08, RUST, "Paint", 9)
    m.custom_box((.11, 3.50, 0), (2.24, .99, .34), TEAL, .16, .09, "Paint", yaw=.04)
    m.custom_box((.16, 3.50, .21), (2.04, .76, .11), "163f43", .27, .04, "Paint")
    m.custom_box((.02, 2.58, .07), (1.80, .64, .26), RED, .16, .060, "Paint")
    for x in [-.78, .87]:
        neon(m, (x, 3.49, .274), (.072, .55, .046), SUN)
    return m


def expansion(kind):
    m = Model()
    if kind == "storage":
        for i in range(3):
            m.custom_box((-.68+i*.64,.28,0),(.58,.49,.69),["c78457","a76e48","e0b481"][i],.10,.046)
            m.box((-.68+i*.64,.34,.351),(.38,.07,.06),CREAM,.021)
        m.box((0, .075, 0), (2.08, .115, .84), "755c4e", .036)
    elif kind == "porch":
        for x in [-.86,.86]:
            m.pipe([(x,0,0),(x,1.61,0)],.065,TEAL,"Metal",8)
        m.custom_box((0,1.67,0),(2.08,.18,1.47),RED,.31,.063,"Paint")
        m.box((0,.46,0),(1.64,.13,.35),CREAM,.06)
        neon(m,(0,1.555,.49),(1.57,.042,.072))
    elif kind == "solar":
        m.custom_box((0,.22,0),(1.65,.24,1.14),CHROME,.18,.07,"Metal")
        m.custom_box((0,.378,-.04),(1.48,.10,1.00),"3c687c",.14,.03,"Tint")
        for j in range(5):
            stripe(m,0,.434,-.45+j*.211,1.3,"84aba5")
    else:
        m.box((0, .37, 0), (.63, .72, .62), TEAL, .12, "Paint")
        m.orb((0, .81, 0), (.54, .20, .52), CHROME, 12, 6, "Metal")
        neon(m, (0, 1.06, 0), (.61, .30, .42), SUN)
        m.orb((0,1.29,0),(.51,.14,.43),RUST,12,6)
    return m


def token(kind):
    m = Model()
    slab(m, 0, 0, 1.06, .86, "8e775e")
    if kind == "snow":
        for y, radius in zip([.32,.77,1.25],[.38,.29,.20]):
            m.orb((0,y,0),(radius,radius,radius), WHITE,12,7)
        stripe(m, 0, .98, .22, .38, RED)
        m.box((.14,.83,.28),(.105,.29,.086), RED, .026)
        m.orb((0,1.237,.174),(.061,.052,.14),SUN,9,5)
        for x in [-.076,.076]:
            m.orb((x,1.31,.173),(.035,.035,.027),DARK,9,5)
    elif kind == "holiday":
        m.pipe([(0,.04,0),(0,.54,0)], .087, CLAY, sides=8)
        for rank in range(3):
            h = .53 + rank * .34
            radius = .61 - rank * .14
            m.pipe([(0,h,0),(0,h+.075,0),(0,h+.55,0)], [radius,radius,.024],
                   [TEAL,"398075","629070"][rank], sides=12)
            for a in range(6):
                theta = a*tau/6.0+rank*.70
                m.orb((cos(theta)*radius*.81,h+.101,sin(theta)*radius*.81),(.073,.073,.073),
                      SUN if a%2 else RED,9,5,"Light")
        m.orb((0,1.81,0),(.12,.16,.10),SUN,10,5,"Light")
        for x,z in [(-.35,.26),(.42,.21),(.12,-.36)]:
            m.custom_box((x,.16,z),(.29,.28,.27), RUST, .056,.026,"Paint")
            m.box((x,.305,z),(.064,.051,.30),SUN,.016,"Paint")
    elif kind == "summer":
        table(m,0,0,True)
    elif kind == "green":
        m = agave()
        m.custom_box((0,.106,0),(.84,.23,.80),TEAL,.18,.055,"Paint")
        neon(m,(0,.30,.356),(.49,.11,.052),"88e9a9")
    elif kind == "sport":
        m.pipe([(0,.07,0),(0,.42,0)], .10, CHROME, "Metal", 10)
        m.orb((0,.70,0),(.42,.41,.22), RUST, 16, 9, "Paint")
        m.orb((0,.69,.179),(.29,.29,.094), SUN, 15, 7, "Metal")
        for x, direction in [(-.38, -1), (.38, 1)]:
            m.pipe([(x,.09,-.05),(x*.85,1.55,-.05)], .037, CHROME, "Metal", 8)
            for row in range(3):
                for cell in range(4):
                    m.box((x*0.84+.081*direction*cell,1.45-row*.074,-.043),(.096,.080,.034),
                          WHITE if (row+cell)%2 else DARK,.012,"Paint")
    elif kind == "truck":
        m.custom_box((0,.23,.02),(1.20,.31,.77),TEAL,.19,.048,"Paint")
        for x,z,c in [(-.34,.12,"c09769"),(.26,.14,"b57b56"),(0,-.17,"b47951")]:
            m.custom_box((x,.61,z),(.49,.48,.49),c,.068,.046)
            for width in [-.185,.185]:
                m.box((x+width,.61,z+.246),(.075,.46,.044),CHROME,.023,"Metal")
        m.pipe([(0,.83,-.12),(0,1.42,-.12)],.07,TEAL,"Metal",8)
        m.custom_box((0,1.34,-.12),(.94,.36,.31),TEAL,.16,.059,"Paint")
        neon(m,(0,1.35,.056),(.63,.085,.041),SUN)
    return m


models = {
    "copper_mile": tank(), "pump": pump(), "cafe": cafe(), "restrooms": washrooms(), "showers": washrooms(True),
    "truck": service_depot(), "motel": motel(), "drive_through": drive_through(), "vip_park": shelter("vip_park"),
    "truck_park": shelter("truck_park"), "charge": shelter("charge"), "charger": charger(),
    "buttress": buttress(), "saguaro": saguaro(), "agave": agave(), "pylon": pylon(),
    **{f"upgrade_{item}": expansion(item) for item in ["storage", "porch", "solar", "beacon"]},
    **{f"event_{item}": token(item) for item in ["snow","holiday","sport","truck","summer","green"]},
}
for name, model in models.items():
    clear_objects()
    obj = model.mesh(name.title().replace("_", ""))
    bake_occlusion(obj, radius=1.08, strength=.50)
    export(output_root() / "assets/models/desert" / f"{name}.glb")
