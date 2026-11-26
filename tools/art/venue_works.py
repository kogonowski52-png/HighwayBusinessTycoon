"""Purpose-built additions for the roadside yards and service expansions."""
from math import cos, sin, tau

from kit import Model
from premium_facades import awning, gutter, lamp, sawlight

CREAM = "ead8ae"
INK = "345354"
GLASS = "82a8ad"
GOLD = "e8ae62"
WOOD = "9c7252"

KINDS = {
    "fuel": "fuel", "market": "retail", "mall": "retail", "cafe": "food",
    "restaurant": "food", "drive_through": "food", "motel": "hotel", "parking": "parking",
    "vip_park": "parking", "truck_park": "parking", "charge": "ev", "tires": "repair",
    "workshop": "repair", "truck": "freight", "wash": "wash", "restrooms": "guest",
    "showers": "guest", "logistics": "freight", "warehouse": "freight", "dealership": "motor",
}


def post(m, x, z, h, shade, y=0.0, wide=.20):
    m.box((x, y+h*.5, z), (wide, h, wide), shade, .035, "Metal")
    m.custom_box((x, y+.10, z), (wide*1.65, .18, wide*1.65), INK, .065, .028)


def counter(m, x, y, z, wide, shade, shelves=False):
    m.box((x,y+.43,z), (wide,.82,.62), shade, .063)
    m.box((x,y+.88,z), (wide+.08,.13,.71), CREAM, .045, "Paint")
    if shelves:
        for row in range(2):
            for col in range(3):
                xx=x+(col-1)*wide*.25
                m.box((xx,y+.26+row*.31,z+.314), (.23,.16,.075),
                      (GOLD,GLASS,"cc795e")[(row+col)%3], .017, "Paint")
    m.box((x+wide*.24,y+1.02,z-.12), (.36,.27,.16), INK, .035, "Metal")
    m.box((x+wide*.24,y+1.04,z-.028), (.25,.14,.022), GLASS, .016, "Tint")


def bench(m, x, y, z, width, color=WOOD):
    for side in (-1,1):
        m.pipe([(x+side*width*.34,y,z+.26), (x+side*width*.34,y+.42,z+.21),
                (x+side*width*.34,y+.68,z-.25)], .044, INK, "Metal", 6)
    for depth in (-.18,0,.18):
        m.box((x,y+.42,z+depth), (width,.095,.15), color, .033)
    m.box((x,y+.67,z-.24), (width,.24,.095), color, .039)


def pallet(m, x, y, z, shade, load=2):
    for rail in (-.26,0,.26):
        m.box((x+rail,y+.08,z), (.16,.14,.72), WOOD, .015)
    for row in range(load):
        m.box((x,y+.34+row*.33,z), (.74,.42,.54), shade, .045)
        for band in (-.24,.24):
            m.box((x+band,y+.35+row*.33,z+.274), (.035,.38,.012), CREAM, .004)


def fixture(m, kind, x, y, z, shade):
    """The equipment is readable from the orthographic player camera."""
    if kind in ("freight","cold"):
        pallet(m,x-.49,y,z,GOLD)
        pallet(m,x+.46,y,z+.21,"ba775c",1)
        m.box((x,y+.12,z+.60), (1.82,.09,.15), shade, .025, "Metal")
    elif kind in ("repair","motor"):
        m.custom_box((x,y+.34,z),(1.5,.59,.66),shade,.12,.058,"Paint")
        for row in (.22,.42):
            m.box((x,y+row,z+.34),(1.25,.042,.023),CREAM,.012,"Metal")
        for side in (-1,1):
            m.pipe([(x+side*.58,y+.61,z), (x+side*.58,y+.93,z)],
                   .21,INK,"Rubber",12)
    elif kind in ("ev","fuel"):
        for side in (-1,1):
            xx=x+side*.54
            m.custom_box((xx,y+.61,z),(.47,1.18,.42),shade,.13,.066,"Paint")
            m.box((xx,y+.82,z+.218),(.31,.34,.037),GLASS,.047,"Tint")
            m.pipe([(xx+.21,y+.83,z),(xx+.35,y+.29,z+.1),(xx+.43,y+.13,z+.26),
                    (xx+.25,y+.54,z+.26)],.027,INK,"Rubber",7)
    elif kind == "wash":
        for side in (-1,1):
            xx=x+side*.69
            m.pipe([(xx,y+.14,z),(xx,y+.98,z)],.17,shade,sides=11)
            for i in range(5):
                h = y+.23+i*.155
                m.pipe([(xx,h,z),(xx,h+.045,z)],.224,GLASS,"Rubber",11)
    elif kind in ("hotel","parking","guest"):
        bench(m,x,y,z,1.50)
        m.box((x-.92,y+.33,z-.26),(.33,.65,.36),shade,.06,"Paint")
    elif kind in ("rent","scooter"):
        counter(m,x,y,z,1.52,shade,False)
        for i in range(3):
            m.box((x-.46+i*.25,y+.99,z+.22),(.13,.072,.091),GOLD,.017,"Metal")
    else:
        counter(m,x,y,z,1.60,shade,True)


def foot(m, x, y, z, width, depth):
    m.custom_box((x,y+.08,z),(width,.16,depth),"b5ab8e",.24,.061)


def annex(kind, stage, x, z, wall, trim, accent, width=2.50):
    m = Model()
    foot(m,x,0,z,width,2.48)
    if stage == 1:
        fixture(m,kind,x,.16,z-.15,trim)
        bench(m,x,.16,z-.80,width*.74)
        return m
    if stage == 2:
        roof = 2.37
        for dx in (-.40,.40):
            post(m,x+dx*width,z+.68,roof,trim,wide=.14)
        m.custom_box((x,roof,z),(width,.27,2.47),accent,.26,.063,"Paint")
        fixture(m,kind,x,.16,z-.05,trim)
        lamp(m,x,roof-.17,z+.68,.16)
        return m
    roof = 2.77 if stage == 3 else 3.23
    m.custom_box((x,roof*.45,z-.68),(width*.91,roof*.90,.84),wall,.19,.076)
    m.box((x,roof*.54,z-.246),(width*.66,.72,.046),GLASS,.048,"Tint")
    for dx in (-.42,.42):
        post(m,x+dx*width,z+.73,roof,trim,wide=.15)
    m.custom_box((x,roof,z),(width,.30,2.55),trim,.29,.08,"Paint")
    fixture(m,kind,x,.17,z+.10,accent)
    if stage == 3:
        sawlight(m,x,roof+.17,z-.20,width*.76,1.38,.48,accent,3)
    else:
        if kind not in ("freight","cold","wash","repair"):
            awning(m,x,roof-.13,z+.80,width*.94,.70,(accent,CREAM),6)
        else:
            m.custom_box((x,roof-.17,z+1.24),(width*.96,.34,.27),accent,.15,.052,"Metal")
        for dx in (-.29,.29):
            lamp(m,x+dx*width,roof-.23,z+.59,.16)
        gutter(m,x+.42*width,roof-.12,z-.08,1.96)
    return m


def roof_work(m, kind, stage, x, y, z, trim, accent):
    if stage == 3:
        if kind in ("food","hotel","retail","guest","rent"):
            sawlight(m,x,y+.10,z,2.10,1.67,.59,accent,4)
            for shift in (-1.23,1.23):
                m.pipe([(x+shift,y,z+.24),(x+shift,y+.76,z+.24)],
                       [.139,.092],trim,"Metal",9)
        elif kind in ("parking","ev","fuel"):
            for shift in (-.69,.69):
                m.custom_box((x+shift,y+.23,z),(1.30,.15,1.76),GLASS,.15,.032,"Tint")
                for i in range(4):
                    m.box((x+shift,y+.314,z-.55+i*.36),(1.18,.022,.027),
                          CREAM,.006,"Metal")
        else:
            for shift in (-.59,.59):
                a=x+shift
                m.custom_box((a,y+.31,z),(.86,.60,1.21),trim,.135,.061,"Metal")
                m.pipe([(a,y+.61,z),(a,y+.67,z)], .29,INK,"Metal",13)
                for strip in range(3):
                    m.box((a,y+.24+strip*.126,z+.608),(.63,.040,.046),
                          CREAM,.008,"Metal")
        return
    for shift in (-.65,.65):
        post(m,x+shift,z,1.38,trim,y,.11)
    m.custom_box((x,y+1.20,z),(1.78,.56,.25),trim,.18,.065,"Paint")
    if kind in ("wash","ev","cold"):
        for shift in (-.46,0,.46):
            m.pipe([(x+shift,y+1.05,z+.135),(x+shift,y+1.36,z+.135)],
                   .041,accent,"Light",8)
    elif kind in ("hotel","food","retail"):
        for shift in (-.40,.40):
            m.orb((x+shift,y+1.25,z+.14),(.18,.18,.038),accent,12,6,"Light")
    else:
        m.box((x,y+1.20,z+.138),(1.34,.092,.028),accent,.021,"Light")
