"""Build original Riverbend, Snowline, Coral Key and Meridian architecture."""
from math import cos, pi, sin, tau
from pathlib import Path
import math
import random
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from kit import Model, bake_occlusion, clear_objects, export, output_root

IVORY, BLACK, SILVER, GLAZE, GLOW = "fff1d4", "323e43", "a9bdc3", "4d8595", "fff4c7"
PALETTES = {
    "valley": ("edca92", "a8513b", "f2995b", "547773", "6a5142"),
    "alpine": ("ca9a71", "486c85", "f0aa50", "699cab", "5c4c52"),
    "ocean": ("fff0c6", "009ca7", "ff875d", "669aaf", "477886"),
    "metro": ("97b0ba", "275e87", "fd9a57", "528caa", "43515c"),
}
def stonework(m, x, z, width, rows, light, dark):
    for row in range(rows):
        span = width / 10
        for i in range(10 if not row % 2 else 9):
            shift = ((i + .5 + .5 * (row % 2)) - 5) * span
            m.box((x + shift, .17 + row * .16, z), (span - .035, .13, .14),
                  light if (row * 11 + i) % 5 else dark, .045)


def glowing(m, at, size, shade=GLOW):
    m.box(at, size, shade, .023, "Light")


def glass(m, x, y, z, width, height, tint, frame=BLACK, lit=False):
    m.box((x, y, z), (width + .15, height + .16, .16), frame, .067, "Metal")
    m.box((x, y, z + .10), (width, height, .075), tint, .034, "Tint")
    if lit:
        glowing(m, (x, y - height * .35, z + .151), (width - .09, .035, .028), "c1ded7")
        m.box((x + width * .21, y - height * .23, z + .151), (width * .28, height * .24, .033),
              "70838c", .02)
    m.box((x, y + height * .29, z + .15), (width * .89, .025, .03), "a8c9c8", .013, "Tint")
    m.box((x, y, z + .154), (.045, height, .045), frame, .015, "Metal")


def door(m, x, z, color, tint, y=.15):
    m.box((x, y + 1.04, z), (1.12, 2.07, .15), color, .08, "Paint")
    glass(m, x, y + 1.16, z + .09, .83, 1.57, tint)
    m.box((x + .39, y + .79, z + .23), (.055, .22, .08), SILVER, .019, "Metal")
    m.box((x, y, z + .22), (1.56, .19, .56), "adb7ac", .055)


def gable(m, width, length, y, rise, material, snow=False, z=0):
    w, h = width * .5, length * .5
    vertices = [(-w, y, -h + z), (w, y, -h + z), (0, y + rise, -h + z),
                (-w, y, h + z), (w, y, h + z), (0, y + rise, h + z)]
    m.add(vertices, [(2, 1, 0), (3, 4, 5), (1, 4, 3, 0)], material)
    tilt = math.atan2(rise, w)
    section = math.hypot(rise, w)
    for side in (-1, 1):
        # Two solid slopes, with raised seam and softly rounded eaves.
        cx, top = side * w * .5, y + rise * .5
        half = section * .5 + .15
        floor = [(cx + side * a*cos(tilt) + b*sin(tilt), top - a*sin(tilt) + side*b*cos(tilt), z+c)
                 for a,b,c in [(-half,-.14,-h-.15),(half,-.14,-h-.15),(half,-.14,h+.15),(-half,-.14,h+.15),
                               (-half,.13,-h-.15),(half,.13,-h-.15),(half,.13,h+.15),(-half,.13,h+.15)]]
        m.add(floor, [(0,1,2,3),(4,7,6,5),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)],
              "e4f5f5" if snow else material, "Paint")
        for seam in range(6):
            along = z - h + .34 + seam * (length - .68) / 5
            m.pipe([(0, y+rise+.13, along), (side*(w+.10), y+.085, along)], .034,
                   "c6dce3" if snow else "b36850", "Metal", 6)
        m.pipe([(side*(w+.11), y+.035, z-h-.18),(side*(w+.11), y+.035, z+h+.18)],
               .105, "9eb2b3" if snow else "704d40", "Metal", 8)
    m.pipe([(0, y+rise+.12, z-h-.16), (0, y+rise+.12, z+h+.16)], .10,
           "d1e5eb" if snow else "bb7055", "Paint", 8)


def deck(m, center, width, depth, shade="bdab90"):
    m.custom_box(center, (width, .23, depth), shade, .67, .056)


def planter(m, x, z, color, leaf):
    m.custom_box((x, .27, z), (1.44, .50, .64), color, .19, .065)
    for i in range(3):
        m.orb((x + (i-1)*.4, .57, z), (.27, .31-(i%2)*.06, .23), leaf, 9, 5, irregular=.13)


def station(region):
    m = Model()
    wall, trim, accent, tint, foundation = PALETTES[region]
    deck(m, (0, .11, -.55), 8.4, 7.3, "a9ad9e" if region != "ocean" else "e7d8af")
    m.custom_box((0, 1.25, -1.92), (6.3, 2.48, 3.26), wall, .37, .11)
    stonework(m, 0, -.22, 6.01, 3, foundation, trim)
    for x in (-2.1, 1.93):
        glass(m, x, 1.48, -.234, 1.72, .96, tint, foundation, True)
    door(m, -.08, -.18, trim, tint)
    if region in ("valley", "alpine"):
        gable(m, 7.1, 3.96, 2.48, 1.13 if region == "valley" else 1.48, trim, region == "alpine", -1.92)
        m.box((1.98, 2.83, -2.65), (.61, 1.22, .56), foundation, .09)
        m.box((1.98, 3.49, -2.65), (.82, .18, .72), trim, .06)
    else:
        roof = 3.09 if region == "metro" else 2.70
        m.custom_box((.04, roof, -1.92), (7.2, .49, 4.10), trim, .88, .13, "Paint")
        m.custom_box((.04, roof + .30, -1.92), (6.54, .18, 3.65), IVORY, .72, .058)
        if region == "metro":
            for x in (-2.6, -1.93, -1.26):
                m.box((x, 3.52, -2.52), (.44, .45, 1.74), "718a92", .066, "Metal")
    for x in (-3.34, 3.34):
        m.box((x, 1.46, 1.27), (.34, 2.88, .37), foundation, .07, "Metal")
        m.box((x, .47, 1.27), (.49, .92, .50), accent, .08, "Paint")
        m.box((x, 2.12, 1.27), (.49, .15, .44), IVORY, .036, "Metal")
    deck(m, (0, 3.04, 1.06), 7.94, 2.34, accent)
    m.custom_box((0, 3.23, 1.09), (8.05, .39, 2.37), trim, .62, .09, "Paint")
    glowing(m, (0, 3.205, 2.254), (6.6, .037, .042))
    for x in (-2.8, 2.8):
        glowing(m, (x, 2.96, 1.48), (.90, .025, .12))
    m.custom_box((0, 3.49, 1.96), (3.70, .49, .39), trim, .18, .063, "Paint")
    planter(m, -3.62, -.53, foundation, "89a46d" if region != "alpine" else "6a867c")
    return m


def rural_shop(region, kind):
    m = Model()
    wall, trim, accent, tint, foundation = PALETTES[region]
    width = {"orchard": 7.3, "mill": 7.6, "greenbank": 7.2, "embers": 8.5, "snowline": 11.2}[kind]
    depth = 5.0 if kind != "snowline" else 6.3
    height = 4.2 if kind == "snowline" else 2.65
    front = depth * .5
    deck(m, (0, .10, .3), width + 1.0, depth + 1.45)
    m.custom_box((0, height * .5, 0), (width, height, depth), wall, .31, .087)
    stonework(m, 0, front + .013, width - .18, 4 if region == "alpine" else 3, foundation, "77716c")
    gable(m, width + .65, depth + .60, height, 1.58 if region == "alpine" else 1.21, trim, region == "alpine")
    for x in [-width*.42, width*.42]:
        m.box((x, height * .5, front + .04), (.18, height-.08, .21), foundation, .045)
    if kind == "mill":
        for x in (-1.92, 1.94):
            m.box((x, 1.20, front+.08), (3.2, 2.27, .25), foundation, .16)
            m.custom_box((x, 1.18, front+.22), (2.95, 2.05, .15), trim, .075, .036, "Metal")
            for row in range(8):
                m.box((x, .26 + row*.25, front + .311), (2.9, .045, .063), "d58061", .018, "Metal")
            glowing(m, (x, 2.43, front + .24), (2.32, .073, .055))
        for i in range(4):
            m.orb((width*.5+.28, .22+i*.23, front-.61), (.29, .116, .29), BLACK, 12, 5, "Rubber")
    else:
        door(m, .12, front + .01, trim, tint)
        for x in [-width*.35, width*.35]:
            glass(m, x, 1.48, front + .02, 1.58, 1.16, tint, foundation, True)
            if kind == "orchard":
                planter(m, x, front+.55, "ac644c", "879959")
        for x in (-width * .43, width * .43):
            m.box((x, 1.18, front+.84), (.18, 2.3, .18), foundation, .048)
        deck(m, (0, 2.5, front + .42), width*.94, 1.38, accent)
        if kind == "snowline":
            for x in (-4.0,-2.05,0,2.02,4.01):
                glass(m, x, 3.41, front+.037, 1.34, .85, tint, foundation, True)
                m.box((x, 2.94, front+.35), (1.58, .12, .61), foundation, .065)
            for x in (-2.56,2.56):
                m.box((x, 4.17, -.82), (.88, 1.22, .84), "7b7777", .09)
                m.box((x, 4.8, -.82), (1.05, .24, 1.01), "e5eef1", .085)
        if kind == "greenbank":
            for i,x in enumerate((-2.32,-1.41,1.52,2.46)):
                m.box((x, .43, front+.59), (.72, .55, .55), "995b40", .065)
                for j in range(5):
                    m.orb((x+(j%2-.5)*.22, .74+(j%3)*.07, front+.45+(j//2)*.18),
                          (.13,.13,.13), ("da7a39","8fa447","d95849","e4a84f")[i], 8, 5)
    for x in (-width * .28, width * .28):
        glowing(m, (x, 2.35, front+.25), (.26, .15, .13))
    m.box((0, 2.77 if kind != "snowline" else 2.60, front+.70), (4.22, .47, .22), trim, .083, "Paint")
    return m


def resort(kind):
    m = Model()
    wall, trim, accent, tint, foundation = PALETTES["ocean"]
    width = 8.6 if kind != "coral" else 9.9
    height = 3.0 if kind == "tidal" else 4.5 if kind == "coral" else 2.8
    deck(m, (0, .11, .35), width + .94, 6.21, "e0c99c")
    m.custom_box((0, height*.5, -.27), (width, height, 4.93), wall, 1.25, .20)
    m.custom_box((0, height+.16, -.27), (width+.52, .39, 5.30), trim, 1.34, .14, "Paint")
    m.custom_box((0, height+.44, -.36), (width-.18, .25, 4.78), IVORY, 1.18, .082)
    if kind == "pearl":
        for x in (-2.0,2.0):
            m.custom_box((x, 1.29, 2.32), (3.21, 2.51, .68), accent, .42, .14, "Paint")
            m.custom_box((x, 1.25, 2.70), (2.68, 2.12, .20), "426e80", .32, .065)
            for offset in (-.88,-.44,0,.44,.88):
                m.box((x+offset, 1.31, 2.84), (.20, 1.89, .13), "82b5c0", .065)
            glowing(m, (x, 2.55, 2.70), (2.6,.079,.08), "d4fbef")
    else:
        door(m, 0, 2.18, trim, tint)
        for x in (-2.71, 2.71):
            glass(m, x, 1.40, 2.19, 2.30, 1.71, tint, "439696", True)
            planter(m, x, 2.83, "db9779", "77a779")
        if kind == "coral":
            for x in (-3.24,-1.25,1.25,3.24):
                glass(m, x, 3.44, 2.22, 1.44, 1.31, tint, foundation, True)
                m.custom_box((x, 2.80, 2.54), (1.65,.17,.86), "ffce9e", .23, .054)
                for rail in (-.64,.64):
                    m.pipe([(x+rail,2.85,2.95),(x+rail,3.38,2.95)], .035, trim, "Metal", 7)
                m.pipe([(x-.68,3.35,2.95),(x+.68,3.35,2.95)], .046, trim, "Metal", 8)
        else:
            for x in (-3.86,3.86):
                m.box((x, 1.16, 3.33), (.19, 2.22, .21), "d48d72", .053)
            m.custom_box((0, 2.41, 2.88), (8.00, .23, 1.88), accent, .58, .073, "Paint")
            for index in range(9):
                m.box(((index-4)*.78, 2.57, 3.08), (.43,.11,1.51), IVORY, .038)
    m.custom_box((0, height+.23, 2.30), (4.33, .51, .34), trim, .19, .07, "Paint")
    glowing(m,(0,height-.05,2.50),(3.55,.045,.07),"bef9e8")
    return m


def industrial(kind):
    m = Model()
    logistics = kind == "freight"
    width, length, height = (20.6, 7.8, 5.30) if logistics else (19.8, 8.0, 4.76)
    face = length * .5
    stripe = "ce7848" if logistics else "3c97a0"
    deck(m, (0,.125,.5), width+1.2, length+2.0,"929e9e")
    m.custom_box((0, height*.5, 0), (width, height, length), "94afbc" if logistics else "88979d", .6,.14)
    m.custom_box((0,height+.16,-.07),(width+.45,.51,length+.46),"40586b",.62,.115,"Paint")
    for x in (-width*.37, 0, width*.37):
        m.box((x,height+.51,-1.25),(2.25,.48,3.53),"829ba4",.14,"Metal")
        for i in range(5):
            m.box((x-.71+i*.35,height+.78,-1.25),(.14,.09,3.22),"537182",.029)
    for i in range(22):
        x = (i-10.5)*.88
        m.box((x, height-.72,face+.056),(.11,1.21,.12),"b8cbd1",.026,"Metal")
    for x in [-4.55,4.55]:
        m.custom_box((x,1.58,face+.039),(4.59,3.13,.35),"45535c",.26,.09,"Metal")
        m.box((x,1.53,face+.24),(4.04,2.81,.13),"293a46",.081,"Metal")
        for j in (0,1):
            stand=x+(-2.03 if j==0 else 2.03)
            m.box((stand,.78,face+.30),(.245,1.55,.42),"e7a453",.075,"Paint")
            for row in (0,1,2):
                m.box((stand,.28+row*.44,face+.53),(.245,.14,.035),"52606a",.025)
        glowing(m,(x,3.47,face+.32),(3.82,.11,.09),"ffc780" if logistics else "a6ffe1")
        m.box((x,.21,face+.86),(4.25,.40,1.34),"576c74",.09,"Metal")
    for x in (-width*.41,width*.41):
        glass(m,x,2.33,face+.055,2.15,2.30,"528da0","465e6b",True)
        for row in range(3):
            m.box((x+.10,.22+row*.29,face+.98),(1.71,.20,.72),"aa8771",.054)
    m.custom_box((0,height-.77,face+.34),(7.63,.85,.40),stripe,.22,.085,"Paint")
    for y in (.60, height -1.38):
        m.box((0,y,face+.062),(width-.33,.13,.16),stripe,.047,"Metal")
    return m


def storefront(kind):
    m = Model()
    dealer = kind == "apex"
    width, length, height = (10.2,6.0,3.42) if dealer else (13.4,6.1,4.20)
    face = length*.5
    accent = "29899c" if dealer else "df875b"
    deck(m,(0,.11,.25),width+1.05,length+1.35,"a9b4b2")
    m.custom_box((0,height*.5,0),(width,height,length),"6c8997" if dealer else "af9e91",.92,.16)
    m.custom_box((0,height+.24,-.12),(width+.63,.65,length+.39),"345977" if dealer else "7e5363",1.07,.145,"Paint")
    m.custom_box((0,height+.64,-.18),(width+.13,.25,length-.15),"bfcdd3",.89,.079,"Metal")
    for x in (-width*.37,-width*.19,width*.19,width*.37):
        glass(m,x,1.67 if dealer else 1.68,face+.022,1.70 if dealer else 2.18,2.69,
              GLAZE if dealer else "528994",BLACK,True)
        if not dealer:
            m.custom_box((x,2.63,face+.39),(1.61,.33,.27),accent,.09,.055,"Paint")
    door(m,0,face+.055,accent,GLAZE)
    # Distinct angled front and roof shed light on the dealership's showcase pad.
    m.custom_box((0, height-.18,face+.53),(width*.91,.40,1.28),accent,.61,.08,"Paint")
    glowing(m,(0,height-.22,face+1.18),(width*.77,.075,.041),"bcfff6" if dealer else "ffdcb4")
    if dealer:
        for side in [-1,1]:
            m.custom_box((side*5.12,.19,.08),(1.82,.32,3.81),"779ba9",.42,.09,"Metal")
        for x in [-width*.34,width*.34]:
            m.pipe([(x,.32,face+1.38),(x,height-.22,face+1.38)],.09,"e0e5db","Metal",10)
    else:
        for x in (-width*.44,width*.44):
            m.box((x,height*.53,face+.33),(.45,height*.91,.49),"87576c",.10,"Paint")
            glowing(m,(x,height*.53,face+.59),(.066,height*.73,.032),"ffd1a3")
        for x in (-2.5,2.5):
            planter(m,x,face+.70,"998778","619a83")
    return m


def shelter(region, kind):
    m = Model()
    wall, trim, accent, tint, foundation = PALETTES[region]
    width = 15.8 if kind == "exchange" else 7.8
    roof = 4.77 if kind == "exchange" else 2.95
    deck(m,(0,.115,.0),width+.82,4.20,"a4ada6")
    for x in (-width*.44,width*.44):
        for z in (-1.37,1.30):
            m.box((x,roof*.48,z),(.31,roof*.94,.38),foundation,.052,"Metal")
            m.box((x,.36,z),(.53,.71,.58),accent,.089,"Paint")
    if region == "alpine":
        gable(m,width,4.01,roof,.89,trim,True)
    else:
        m.custom_box((0,roof,0),(width,.40,4.01),trim,.59,.096,"Paint")
        m.custom_box((0,roof+.27,-.039),(width-.45,.18,3.76),wall,.54,.058)
    for x in (-width*.24,width*.24):
        glowing(m,(x,roof-.23,1.05),(1.70,.039,.086))
    m.custom_box((0,roof+.02,1.96),(4.40,.61,.37),trim,.17,.072,"Paint")
    if kind == "pulse":
        for x in (-2.6,0,2.6):
            m.custom_box((x,1.02,.11),(.59,1.99,.54),"c9d8ca",.23,.11,"Paint")
            glowing(m,(x,1.37,.401),(.23,.39,.055),"81f5cc")
            m.pipe([(x+.29,1.29,.18),(x+.57,.28,.35),(x+.80,.33,.31),(x+.68,1.02,.39)],.042,BLACK,"Rubber",8)
    return m


def expansion(region, service, stage):
    """Each step adds geometry in a different part of the business parcel."""
    m = Model()
    wall, trim, accent, tint, foundation = PALETTES[region]
    large = service in ("logistics", "warehouse")
    wide = service in ("motel", "dealership", "mall")
    width = 9.5 if large else 5.0 if wide else 3.8
    roof = {"fuel": 3.7, "logistics": 5.60, "warehouse": 5.02, "dealership": 4.07, "mall": 4.88,
            "motel": 4.93 if region == "ocean" else 5.52, "restaurant": 3.44, "truck_park": 5.01}.get(service, 3.32)
    if stage == 1:
        x, z = -width-.72, -.48
        if large:
            deck(m,(x,.12,z),3.78,3.98,"8b999d")
            for row in range(3):
                for j in range(3):
                    shade = ["ca8757","a17b65","bf9c72"][(row+j)%3]
                    m.box((x+(j-1)*.55,.39+row*.48,z),(.52,.45,1.33),shade,.067)
            for offset in (-1.02,1.02):
                m.box((x+offset,.88,z),(.10,1.64,1.77),trim,.045,"Metal")
        else:
            deck(m,(x,.14,z),2.29,2.68)
            for dz in (-.69,.57):
                m.box((x,.52,z+dz),(1.40,.65,.87),foundation,.09)
                for ix in (-.43,0,.43):
                    m.orb((x+ix,.94,z+dz),(.33,.27,.37),"85a070" if region != "alpine" else "7c9d8d",10,6)
    elif stage == 2:
        x, z = width + 1.10, -.48
        deck(m,(x,.11,z),2.73 if not large else 3.42,3.11)
        for dx in (-.92,.92):
            m.box((x+dx,1.02,z+.85),(.18,1.99,.20),foundation,.046,"Metal")
        m.custom_box((x,2.18,z),(2.51 if not large else 3.16,.28,2.50),accent,.51,.08,"Paint")
        m.box((x,1.14,z-.66),(1.9,1.57,.90),wall,.135)
        glass(m,x,1.35,z-.165,1.42,.73,tint,foundation,True)
        glowing(m,(x,2.02,z+1.06),(1.52,.061,.052))
    elif stage == 3:
        for x in (-1.85,0,1.85):
            m.custom_box((x,roof+.21,-.49),(1.45,.36,2.15),foundation,.19,.068,"Metal")
            m.custom_box((x,roof+.39,-.49),(1.36,.12,1.95),"537aa0",.17,.038,"Tint")
            for j in range(5):
                m.box((x,roof+.459,-1.24+j*.37),(1.20,.014,.024),"9ab7c0",.007,"Metal")
            for dx in (-.23,.23):
                m.box((x+dx,roof+.459,-.50),(.027,.014,1.80),"aac8cf",.008,"Metal")
    else:
        x, z = width*.40, .86
        y = roof+.32
        for dx in (-.68,.68):
            m.pipe([(x+dx,y-.33,z),(x+dx,y+1.49,z)],.075,foundation,"Metal",8)
        m.custom_box((x,y+1.36,z),(2.91,.91,.36),trim,.25,.10,"Paint")
        glowing(m,(x,y+1.39,z+.208),(2.17,.09,.036),accent)
        m.orb((x,y+1.63,z+.242),(.25,.25,.13),"ffda9e",12,7,"Light")
    return m


def mountain(seed, snowy):
    rng = random.Random(seed)
    m = Model()
    segments = 22 if snowy else 16
    rim = [(.85+rng.random()*.27) for _ in range(segments)]
    points = []
    heights = [0,.65,2.75,4.35,5.18,5.64]
    radii = [1,.93,.68,.45,.28,.04]
    colors = []
    for r, h in enumerate(heights):
        for i, shift in enumerate(rim):
            a = i*tau/segments
            if snowy:
                slope = cos(a*3 + seed*.19) + .33*sin(a*7 + r*.63)
                shoulder = sin(a + seed)*r*.20
                reach = radii[r] * (shift + slope*.105)
                height = h + (.11+slope*.32)*sin(r*pi/5) + rng.uniform(-.14,.14)*int(0 < r < 5)
                points.append((6.4*reach*cos(a)+shoulder, height, 4.4*reach*sin(a)-r*.13))
                strata = ("768b9d","91a6b2","aebfcb","cedbe3","f0f5f3","f9fbf5")
                colors.append(strata[min(5, max(0, r + int(0 < r < 4 and slope > .52)))])
            else:
                points.append((6.4*radii[r]*shift*cos(a)+r*.12,h+rng.uniform(-.18,.20)*(r<5),
                               4.4*radii[r]*shift*sin(a)+r*.11))
                colors.append(("7b8b65","87996d","93a476","9eae7c","aaba82","a9b47a")[r])
    faces = []
    for layer in range(len(heights)-1):
        for i in range(segments):
            a,b=layer*segments+i,layer*segments+(i+1)%segments
            faces.extend([(a,a+segments,b+segments),(a,b+segments,b)])
    faces.append(tuple(reversed(range(segments*(len(heights)-1),len(points)))))
    m.add(points, faces, colors[0], "Ceramic", True, vertex_colors=colors)
    return m


def vegetation(region):
    from premium_botany import conifer_outline, deciduous, palms

    if region == "ocean":
        return palms()
    if region == "alpine":
        m = Model()
        conifer_outline(m, 0, 0, snow=True)
        return m
    if region == "valley":
        return deciduous()
    m = Model()
    from premium_botany import canopy
    m.pipe([(0,0,0),(.03,1.70,.03),(.11,2.54,.17)],.12,"857363","Ceramic",9)
    for i,x in enumerate((-.53,.0,.49)):
        canopy(m,(x,2.22+(i%2)*.40,.07),(.68,.86,.63),("4c756d","618f77","7aaa82","a3b993"),i,12)
    return m


BUILDERS = {
    "valley": {"restaurant": "orchard", "workshop": "mill", "market": "greenbank"},
    "alpine": {"restaurant": "embers", "motel": "snowline", "parking": "overlook"},
    "ocean": {"restaurant": "tidal", "motel": "coral", "vip_park": "marina", "wash": "pearl"},
    "metro": {"logistics": "freight", "warehouse": "junction", "dealership": "apex", "mall": "crossline", "charge": "pulse", "truck_park": "exchange"},
}


def venue(region, kind):
    if kind in ("overlook","marina","pulse","exchange"):
        return shelter(region,kind)
    if region in ("valley","alpine"):
        return rural_shop(region,kind)
    if region == "ocean":
        return resort(kind)
    if kind in ("freight","junction"):
        return industrial(kind)
    return storefront(kind)


def write(region, key, model, bake=True):
    clear_objects()
    obj = model.mesh(key.title().replace("_", ""))
    if bake:
        bake_occlusion(obj,radius=1.12,strength=.48)
    export(output_root() / "assets/models/regions" / f"{region}_{key}.glb")


if __name__ == "__main__":
    import sys

    from premium_facades import regional_detail

    for region, businesses in BUILDERS.items():
        write(region,"fuel",regional_detail(region,"fuel",station(region)))
        write(region,"foliage",vegetation(region))
        for service, key in businesses.items():
            write(region,service,regional_detail(region,service,venue(region,key)))
        detail_only = "--facades-only" in sys.argv
        if not detail_only and region in ("valley","alpine"):
            for seed in (25,74):
                write(region,f"ridge_{seed}",mountain(seed,region=="alpine"))
        for service in ["fuel", *businesses]:
            for stage in ([3] if detail_only else range(1,5)):
                write(region,f"{service}_{stage}",regional_detail(region,service,expansion(region,service,stage),stage))
