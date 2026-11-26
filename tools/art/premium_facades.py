"""Original architectural details for the Route 17 miniature. Coordinates are Godot metres."""
from math import cos, pi, sin

from kit import Model

INK = "214451"
JADE = "2b8c7d"
DARK_JADE = "2d615e"
MINT = "7ec2a6"
CREAM = "f7dbaa"
WHITE = "fff1c9"
COPPER = "de754d"
TERRA = "b65d46"
METAL = "90a39c"
GLASS = "8fbcb9"
TINT = "447781"
WOOD = "956547"


def lamp(m, x, y, z, radius=.18):
    m.pipe([(x, y+.045, z), (x, y+.075, z)], radius, INK, "Metal", 12)
    m.pipe([(x, y+.033, z), (x, y+.041, z)], radius*.87, WHITE, "Light", 12)


def gutter(m, x, y, z, length, left=True):
    side = -1 if left else 1
    m.pipe([(x, y, z-length/2), (x, y, z+length/2)], .043, METAL, "Metal", 8)
    m.pipe([(x, y, z+length/2), (x+side*.08, y-.17, z+length/2),
            (x+side*.08, .24, z+length/2), (x+side*.14, .13, z+length/2+.13)], .032, DARK_JADE, "Metal", 8)


def awning(m, x, y, z, width, depth, palette=(COPPER, CREAM), sections=9):
    """A sectional folded fabric shade, with alternating sealed seams and a dropped edge."""
    span = width/sections
    for i in range(sections):
        a, b = x-width/2+i*span+.008, x-width/2+(i+1)*span-.008
        section = [(y+.05,z), (y-.011,z+depth*.36), (y-.119,z+depth*.79),
                   (y-.24,z+depth), (y-.379,z+depth+.016)]
        points = [(h, t, f) for t, f in section for h in (a,b)]
        faces = [(j, j+1, j+3, j+2) for j in range(0, len(points)-2, 2)]
        m.add(points, faces, palette[i%len(palette)], smooth=True)
        m.pipe([(a, t+.017, f) for t,f in section], .014, "ead3ac", "Paint", 5)
    m.pipe([(x-width/2, y-.385, z+depth+.024), (x+width/2, y-.385, z+depth+.024)], .019, TERRA, "Paint", 7)


def sawlight(m, x, y, z, width, depth, height, color=JADE, strips=5):
    """A daylit asymmetric roof monitor with broad mullions and a curved back skin."""
    vertices = [(x+u*width/2, y+dy, z+v*depth/2)
                for u in [-1, 1] for v, dy in [(-1, 0), (-.50, height*.27), (.79, height), (1, height*.86)]]
    faces = [(i, 4+i, 5+i, i+1) for i in range(3)] + [(0, 1, 2, 3), (7, 6, 5, 4)]
    m.add(vertices, faces, color, "Paint", True)
    m.custom_box((x, y+.035, z), (width+.19, .095, depth+.14), INK, .12, .037, "Metal")
    m.box((x, y+height*.43, z+depth*.499), (width, height*.86, .055), INK, .028, "Metal")
    for i in range(strips):
        a = x+width*((i+.5)/strips-.5)
        m.box((a, y+height*.438, z+depth*.523), (width/strips-.062, height*.67, .025),
              TINT if i%2 else "679ea0", .007, "Tint")
        m.box((a, y+height*.18, z+depth*.54), (width/strips-.09, .032, .023), "f4e8bc", .008, "Light")
    for s in [-1,1]:
        m.pipe([(x+s*width/2, yy, zz) for yy,zz in [(y,z-depth/2),(y+height*.27,z-depth/4),
                (y+height,z+depth*.397),(y+height*.86,z+depth/2)]], .025, CREAM, "Paint", 7)


def cooler(m, x, z, width=1.42, floor=.28):
    """Closed refrigerator with separate glazing, lit product trays and tactile hardware."""
    h = 1.98
    m.box((x,floor+h*.50,z-.18), (width,h,.49), "ded7bd", .072, "Paint")
    m.box((x,floor+h-.09,z+.23), (width,.22,.24), JADE, .068, "Paint")
    m.box((x,floor+h-.08,z+.36), (width*.78,.067,.027), WHITE, .017, "Light")
    m.box((x,floor+.17,z+.30),(width,.26,.13), INK,.036,"Metal")
    for dx in [-width*.485,0,width*.485]:
        m.box((x+dx,floor+h*.49,z+.30),(.044,h*.80,.052),"bbcfc2",.012,"Metal")
    for row in range(4):
        y = floor+.42+row*.38
        m.box((x,y,z+.15),(width*.92,.039,.31),"c8dbcf",.008,"Metal")
        for column in range(7):
            dx=(column-3)*width*.125
            color=("de785d","74c2ac","e7b65d","778e9d","a178ae")[(row*3+column)%5]
            r=.060 if row<2 else .043
            cap=.17 if row<2 else .22
            m.pipe([(x+dx,y+.029,z+.205),(x+dx,y+cap,z+.205)],r,color,"Paint",7)
            m.pipe([(x+dx,y+cap,z+.205),(x+dx,y+cap+.033,z+.205)],r*.8,CREAM,"Metal",7)
    m.box((x,floor+h*.50,z+.315),(width*.95,h*.78,.020),GLASS,0,"Glass")
    for dx in [-.06,.06]:
        m.pipe([(x+dx,floor+.92,z+.36),(x+dx,floor+1.22,z+.36)], .024, INK, "Metal", 7)


def counter(m, x, z, y=.26):
    m.custom_box((x,y+.43,z),(1.48,.86,.64),DARK_JADE,.13,.048,"Paint")
    m.custom_box((x,y+.89,z),(1.54,.106,.72),CREAM,.14,.037)
    m.box((x+.30,y+1.075,z-.08),(.43,.27,.18),INK,.039,"Paint")
    m.box((x+.30,y+1.09,z+.022),(.32,.18,.018),GLASS,.01,"Light")
    for dx in [-.56,-.37,-.18]:
        m.box((x+dx,y+.983,z+.089),(.128,.12,.18),COPPER,.021,"Paint")


def cold_case(m, x, z, floor):
    m.custom_box((x,floor+.35,z),(1.84,.70,.80),JADE,.12,.058,"Paint")
    m.box((x,floor+.73,z),(1.68,.065,.71),INK,.021)
    for k in range(6):
        dx=(k-2.5)*.254
        m.orb((x+dx,floor+.806,z),(.09,.06,.076),("d58b51","efd090","c87357")[k%3],8,5)
    m.box((x,floor+.871,z+.31),(1.68,.22,.024),GLASS,0,"Glass")


def wash_equipment(m):
    """Dryers above the passage, small spray heads and an operator/chemical rack."""
    for y, z in [(2.32,-.88),(2.34,.57)]:
        m.pipe([(-1.90,y,z),(1.90,y,z)], .052, METAL, "Metal", 8)
        for x in [-1.49,-.75,0,.75,1.49]:
            m.pipe([(x,y,z),(x,y-.16,z+.064)], .046, JADE, "Paint", 8)
            m.pipe([(x,y-.15,z+.06),(x,y-.186,z+.087)], .058, INK, "Metal", 8)
    for x in [-1.38,0,1.38]:
        m.custom_box((x, 2.18, 1.55),(.73,.31,.70),INK,.18,.052,"Metal")
        m.pipe([(x,2.14,1.46),(x,1.99,1.61)],.169,JADE,"Paint",12)
        m.pipe([(x,1.98,1.61),(x,1.94,1.63)],.136,METAL,"Metal",12)
    m.custom_box((2.09,.665,-1.83),(.35,.83,1.20),INK,.094,.046,"Metal")
    for k in range(3):
        m.pipe([(1.91,.45,-2.17+k*.32),(1.91,.92,-2.17+k*.32)],.136,
               ("cc825e","83bfb1","e4b66c")[k],"Paint",10)
        m.pipe([(1.91,.93,-2.17+k*.32),(1.91,1.00,-2.17+k*.32)],.064,CREAM,"Metal",8)


def garage_equipment(m):
    """A stocked repair wall, hose compressor and mobile wheel service stand."""
    m.box((1.92,1.69,-2.04),(2.45,.82,.095),"856e51",.036,"Paint")
    for i in range(7):
        x=1.05+i*.278
        top=1.88+(.04 if i%2 else 0)
        m.pipe([(x,1.42,-1.98),(x,top,-1.972)],.027,METAL if i%3 else COPPER,"Metal",7)
        m.pipe([(x,top-.032,-1.97),(x,top+.015,-1.94)],.050,CREAM,"Metal",8)
    m.pipe([(2.97,.56,-.98),(2.97,.56,-.18)],.194,COPPER,"Paint",14)
    m.orb((2.97,.56,-.98),(.194,.194,.103),COPPER,10,6,"Paint")
    m.orb((2.97,.56,-.18),(.194,.194,.103),COPPER,10,6,"Paint")
    m.box((2.97,.83,-.53),(.24,.18,.42),INK,.050,"Metal")
    m.pipe([(2.95,.90,-.31),(2.95,1.03,-.24),(2.80,1.14,-.11),(2.70,.93,.05)],
           .025,"e1af60","Rubber",8)
    for z in [-.92,-.23]:
        m.pipe([(3.06,.45,z),(3.12,.45,z)],.103,INK,"Rubber",10)
    for i in range(3):
        y=.38+i*.159
        m.pipe([(-2.84,y,-1.67),(-2.84,y+.115,-1.67)], [ .29,.275], "354648","Rubber",14)
        m.pipe([(-2.84,y+.119,-1.67),(-2.84,y+.139,-1.67)],.17,"677c77","Metal",14)


def garage_portal(m, x, y, z, width, height, color=COPPER):
    m.pipe([(x-width/2,y,z),(x-width/2,y+height-.24,z),(x-width/2+.18,y+height,z),
            (x+width/2-.18,y+height,z),(x+width/2,y+height-.24,z),(x+width/2,y,z)],
           .116,color,"Paint",9)
    for side in [-1,1]:
        m.box((x+side*width/2,y+.33,z+.020),(.25,.58,.24),INK,.052,"Metal")
        m.box((x+side*width/2,y+.58,z+.15),(.17,.094,.022),WHITE,.009,"Light")


def north_detail(name, m):
    if name == "market":
        sawlight(m,.08,3.515,-.56,4.25,1.25,.70,DARK_JADE,6)
        awning(m,.33,2.57,2.42,3.42,.94,(COPPER,"ebc482","f5db9e"),9)
        cooler(m,.87,-1.62,1.54)
        cold_case(m,.87,.77,.267)
        counter(m,2.42,1.30)
        gutter(m,3.769,2.89,-.28,4.1,False)
    elif name == "wash":
        sawlight(m,-.70,3.28,-.43,2.64,3.03,.81,JADE,5)
        garage_portal(m,0,.31,2.98,4.31,2.38,MINT)
        wash_equipment(m)
        for x in [-2.51,2.53]:
            m.box((x,1.41,2.87),(.55,1.33,.18),INK,.075,"Paint")
            for k in range(3):
                m.box((x,1.09+k*.268,2.972),(.34,.07,.025),CREAM if k==0 else MINT,.012,"Light")
    elif name == "workshop":
        sawlight(m,-.49,3.75,-.50,5.27,1.50,.66,"c17358",7)
        garage_portal(m,1.68,.29,2.72,2.87,2.12,"c37457")
        garage_equipment(m)
        gutter(m,3.57,2.90,-.41,4.4,False)
    elif name == "restaurant":
        awning(m,-.03,2.451,1.97,6.05,.83,(COPPER,CREAM),13)
        sawlight(m,-.40,3.04,-.74,3.72,1.49,.556,"bd705c")
        cold_case(m,1.71,-.79,.32)
        counter(m,.17,-.66,.32)
        for x in [-2.71,-.86,1.1,2.80]:
            lamp(m,x,2.25,1.91,.154)
    elif name in ("island", "pump_vintage"):
        # Integrated yard-side footplates, screen surround and a visible service tower.
        m.box((-.02,.162,.15),(1.76,.08,.87),"809387",.038,"Metal")
        for x in [-.57,.58]:
            m.box((x,.294,.55),(.17,.24,.076),COPPER,.018,"Paint")
        m.box((-.045,1.48 if name=="island" else 1.51,.349),(.54,.055,.025),WHITE,.009,"Light")
    elif name == "price_sign":
        for x in [-.65,.65]:
            m.pipe([(x,.165,.040),(x,.42,.041),(x,1.66,.005),(x*.74,2.05,.005)],
                   .058,COPPER,"Paint",9)
        m.custom_box((0,3.65,.065),(1.39,.23,.87),DARK_JADE,.20,.056,"Paint")
        m.custom_box((0,3.799,.065),(1.18,.077,.69),CREAM,.15,.027,"Paint")
    return m


def canopy_trim(m, key):
    if key == "canopy_worn":
        gutter(m,1.80,2.79,-.15,1.70,False)
        m.box((-.93,.35,-.81),(.43,.44,.29),"915f4c",.042,"Metal")
        for y in [.23,.43]:
            m.box((-.93,y,-.649),(.39,.028,.022),METAL,.009,"Metal")
    elif key == "canopy_rehab":
        for x in [-2.20,2.21]:
            lamp(m,x,3.03,.77,.24)
            m.pipe([(x,2.98,.77),(x,3.10,1.02),(x,3.197,1.15)],.035,COPPER,"Paint",8)
        sawlight(m,1.31,3.305,-.62,1.44,.76,.35,DARK_JADE,3)
    elif key == "canopy_service":
        sawlight(m,-1.54,3.56,-.68,2.43,1.24,.69,JADE,4)
        for x in [-3.02,3.02]:
            lamp(m,x,3.24,1.12,.23)
            m.pipe([(x,2.81,.06),(x,3.0,.65),(x,3.42,1.37)],.067,COPPER,"Paint",8)
    elif key == "canopy_cantilever":
        for x in [-3.12,2.92]:
            sawlight(m,x,4.001,-.78,2.35,1.52,.78,DARK_JADE,4)
            m.pipe([(x,3.05,-.59),(x*.96,3.41,.56),(x*.98,3.88,1.79)],.098,COPPER,"Paint",9)
    elif key == "canopy_ridge":
        sawlight(m,-2.69,4.31,-.54,3.03,1.83,.98,"167c77",5)
        for side in [-1,1]:
            x=side*3.34
            for z in [-.82, 1.08]:
                m.pipe([(x,2.91,-.70),(x+side*.31,3.47,z*.60),(x+side*.64,4.24+side*.17,z)],
                       .079,COPPER,"Paint",10)
            lamp(m,x,3.90+side*.16,1.58,.265)
        m.custom_box((-.03,4.48,-.51),(1.93,.40,1.06),INK,.20,.084,"Paint")
        m.custom_box((-.03,4.715,-.51),(1.88,.11,.98),CREAM,.19,.035,"Paint")
    return m


def spinner():
    """Animation-friendly brush mesh centered around a local vertical axle."""
    m=Model()
    m.pipe([(0,-.67,0),(0,.67,0)],.126,INK,"Metal",12)
    for tier in range(11):
        h=(tier-5)*.109
        outer=.40+(sin(tier/10*pi)*.055)
        points=[]
        for i in range(24):
            angle=i*pi/12+tier*.19
            r=outer if i%2 else outer*.86
            points.append((cos(angle)*r,h+(-.055 if i%2 else .02),sin(angle)*r))
        vertices=[(0,h+.026,0)]+points
        faces=[(0,(i+1)%24+1,i+1) for i in range(24)]
        m.add(vertices,faces,"4a9c8d" if tier%3 else "96d7c0","Rubber",True)
    for y in [-.68,.68]:
        m.pipe([(0,y-.037,0),(0,y+.037,0)],.195,METAL,"Metal",12)
    return m


def trellis(m, x, y, z, width, length, tint=DARK_JADE, posts=True):
    """Ventilated pergola with rounded rails over the existing paved bays."""
    for side in [-1,1]:
        at=x+side*width*.45
        if posts:
            for step in [-1,1]:
                m.pipe([(at,.12,z+step*length*.40),(at,y-.33,z+step*length*.40),
                        (at-side*.10,y,z+step*length*.33)],.076,WOOD,"Paint",8)
        m.pipe([(at,y,z-length*.50),(at,y,z+length*.50)],.091,tint,"Paint",9)
    for i in range(9):
        depth=z+length*(i/8-.5)
        m.pipe([(x-width*.50,y+.08,depth),(x+width*.50,y+.08,depth)],.053,tint,"Paint",8)


def boxed_vent(m, x, y, z, width, depth, tint=INK):
    m.custom_box((x,y+.13,z),(width,.26,depth),tint,.14,.047,"Metal")
    for j in range(5):
        m.box((x,y+.26,z+depth*(j-2)*.147),(width*.80,.034,.083),"a1aca3",.009,"Metal")


def ribbon_loop(m, x, y, z, w, h, tint, rail=.084):
    m.pipe([(x-w*.50,y,z),(x-w*.50,y+h*.66,z),(x-w*.42,y+h*.93,z),
            (x-w*.31,y+h,z),(x+w*.31,y+h,z),(x+w*.42,y+h*.93,z),
            (x+w*.50,y+h*.66,z),(x+w*.50,y,z)],rail,tint,"Paint",10)


def solar_fins(m, x, y, z, width, depth, tint):
    for step in range(4):
        dx=(step-1.5)*width/4
        m.custom_box((x+dx,y+.04,z),(width/4-.06,.104,depth),tint,.099,.034,"Tint")
        m.pipe([(x+dx-width*.096,y+.096,z+depth*.43),(x+dx+width*.096,y+.096,z+depth*.43)],
               .017,MINT,"Metal",6)


def roadside_extra(name,m):
    if name == "motel":
        awning(m,.41,3.39,2.15,3.41,.56,("dc845f","e6bd8f"),9)
        sawlight(m,-1.7,4.30,-.74,2.50,1.75,.61,"376e70")
        boxed_vent(m,2.81,4.24,-.62,1.03,.88)
    elif name == "parking":
        for x in [-3.63,3.62]:
            lamp(m,x,2.21,-1.63,.181)
            ribbon_loop(m,x,.104,-2.68,.65,1.06,"d18b57",.045)
        for x in [-.98,.98]:
            m.pipe([(x,.063,-.20),(x,.108,-.20)], .159, "b6a284","Metal",12)
    elif name == "truck_canopy":
        for x in [-2.61,.76,2.73]:
            sawlight(m,x,5.431,1.14,1.42,2.21,.52,"3a7473",4)
            lamp(m,x,4.93,2.88,.231)
        for x in [-3.42,3.42]:
            m.pipe([(x,4.23,-.51),(x,4.64,1.62),(x*.84,5.28,4.77)],.102,"d98a58","Paint",9)
    elif name == "tire_shop":
        sawlight(m,-.96,3.17,-.30,3.22,1.49,.59,"a9634f")
        for x in [-2.45,2.45]:
            lamp(m,x,2.30,1.78,.155)
    elif name == "ev_lounge":
        solar_fins(m,.01,2.40,-.10,2.52,1.54,"4e7d87")
        for x in [-1.36,1.36]:
            lamp(m,x,1.72,1.14,.111)
    elif name == "freight_office":
        boxed_vent(m,.43,2.68,-.20,1.15,.93)
        awning(m,.09,2.11,1.24,1.99,.66,("ce925d","e0c08e"),7)
    return m


def desert_detail(name,m):
    red="cc6c48"
    oxide="92604d"
    coral="dc7c4a"
    if name == "copper_mile":
        # Art Deco flutes and sun blades emerge from the colored stepped roof.
        sawlight(m,-2.30,3.79,-.13,3.25,1.48,.72,"378985",5)
        sawlight(m,2.58,3.75,.48,2.83,1.31,.62,red,4)
        for x in [-3.10,3.14]:
            m.pipe([(x,2.96,-.31),(x,3.10,1.26),(x*.86,3.49,2.73)],.080,"db955f","Paint",9)
            lamp(m,x,3.06,2.26,.221)
    elif name in ("cafe","drive_through"):
        width=3.83 if name=="cafe" else 2.32
        awning(m,-.15,1.98 if name=="cafe" else 2.07,2.49 if name=="cafe" else 1.87,width,.77,
               ("dd8861","f1c38e"),9)
        if name == "drive_through":
            boxed_vent(m,-1.2,2.63,-.39,1.12,.93)
    elif name in ("restrooms","showers"):
        sawlight(m,-.58,2.68,-.41,2.23,1.11,.44,oxide)
        for x in [-1.61,1.61]:
            lamp(m,x,2.08,1.53,.13)
    elif name == "truck":
        for x in [-3.55,3.55]:
            sawlight(m,x,4.90,-.64,3.28,1.78,.64,oxide,5)
            garage_portal(m,x,.28,2.48,4.91,3.58,"be7954")
    elif name == "motel":
        for x in [-2.29,.11,2.50]:
            awning(m,x,3.71,1.24,1.71,.65,(coral,"efd19c"),7)
        boxed_vent(m,1.93,4.18,-.49,1.77,1.04)
    elif name in ("vip_park","truck_park","charge"):
        top=4.48 if name=="truck_park" else 3.05
        width=4.98 if name=="truck_park" else 2.80
        solar_fins(m,-.36,top,-.54,width,1.86,"507d84")
        for x in [-width*.5,width*.5]:
            lamp(m,x,top-.51,.32,.148)
    elif name == "pump":
        m.box((0,1.50,.317),(.48,.085,.036),"ebc784",.012,"Light")
        m.pipe([(-.31,.30,-.14),(-.323,1.08,-.14)],.033,"df9759","Metal",8)
    return m


def regional_detail(region, name, m, stage=0):
    if stage:
        if stage == 3:
            height = {"fuel":3.7,"logistics":5.6,"warehouse":5.02,"dealership":4.07,
                      "mall":4.88,"motel":5.50 if region=="alpine" else 4.93,
                      "restaurant":3.44,"truck_park":5.01}.get(name,3.32)
            boxed_vent(m,.15,height+.16,1.03,1.25,.53,"537c81" if region!="alpine" else "7e999b")
        return m
    if name=="fuel":
        tint={"valley":"b59560","alpine":"656e8d","ocean":"d47f66","metro":"426f95"}[region]
        for x in [-2.67,2.47]:
            sawlight(m,x,3.43,.61,2.10,1.10,.56,tint,4)
            lamp(m,x,2.90,1.40,.20)
        if region in ("valley","alpine"):
            awning(m,.44,2.35,-.20,2.58,.51,(tint,CREAM),7)
    elif region=="valley":
        if name == "workshop":
            for x in [-1.87,1.88]:
                garage_portal(m,x,.14,2.86,2.83,2.23,"ae7756")
            boxed_vent(m,2.38,3.41,-1.11,1.01,1.34)
        else:
            awning(m,.03,2.46,2.67,4.56,.86,("b37f53","e9c283"),11)
            for x in [-2.51,2.49]:
                lamp(m,x,2.18,2.92,.177)
    elif region == "alpine":
        if name=="parking":
            trellis(m,0,2.36,-1.05,5.12,1.85,"809a9a",False)
        else:
            w,front = (7.6,3.15) if name=="motel" else (5.74,2.50)
            trellis(m,0,2.18,front+.57,w,1.07,"895a51",False)
            for x in [-w*.37,w*.33]:
                lamp(m,x,2.14,front+.31,.154)
    elif region == "ocean":
        if name=="vip_park":
            trellis(m,.37,3.25,-.38,6.0,2.30,"78a9a1",False)
        elif name=="wash":
            sawlight(m,-.85,3.34,-.62,4.61,2.41,.78,"4c9b9a",7)
            for x in [-1.95,1.95]:
                garage_portal(m,x,.26,2.93,2.47,2.16,"8cc5be")
        else:
            y=3.90 if name=="motel" else 2.58
            for x in [-2.22,2.18]:
                awning(m,x,y,2.48,2.24,.59,("d88a72","edc49c"),7)
            sawlight(m,.66,4.96 if name=="motel" else 3.64,-.67,3.80,1.72,.56,"568f92")
    else:
        if name in ("logistics","warehouse"):
            top=5.64 if name=="logistics" else 5.09
            for x in [-5.98,.44,6.08]:
                sawlight(m,x,top,-.40,2.66,2.45,.64,"689096",5)
            for x in [-5.88,5.91]:
                lamp(m,x,3.29,4.52,.266)
        elif name in ("dealership","mall"):
            top=4.24 if name=="dealership" else 5.00
            sawlight(m,0,top,-.71,6.25,2.28,.72,"3c7d91",8)
            for x in [-4.11,4.11]:
                lamp(m,x,top-.98,3.76,.196)
        elif name in ("charge","truck_park"):
            solar_fins(m,0,3.33 if name=="charge" else 5.16,-.05,5.38,2.10,"478195")
    return m


def north_annex(service, stage):
    """An accessory building on each service's usable side, growing by four distinct silhouettes."""
    m=Model()
    tint={"market":"25796e","wash":"579d97","workshop":"be724f","restaurant":"bf755b"}[service]
    width=1.92 if service in ("market","restaurant") else 1.61
    m.custom_box((0,.09,0),(width+.32,.18,1.76),"aa9c80",.15,.047)
    if stage == 2:
        for x in [-.53,.53]:
            m.box((x,.31,-.29),(.67,.46,.62),tint,.055,"Paint")
            m.box((x,.555,-.29),(.71,.074,.65),CREAM,.022)
            m.pipe([(x-.139,.568,-.04),(x+.139,.568,-.04)],.025,INK,"Metal",7)
    else:
        m.custom_box((0,.68,-.29),(width,.98,.92),tint,.14,.052,"Paint")
        m.custom_box((0,1.21,-.23),(width+.150,.16,1.12),CREAM,.18,.061)
        for x in [-.48,.48]:
            m.box((x,.84,.180),(.63,.45,.046),"456d74",.027,"Tint")
            m.pipe([(x-.22,.68,.205),(x+.22,.68,.205)],.023,MINT,"Metal",7)
            m.pipe([(x,.66,.205),(x,1.04,.205)],.019,INK,"Metal",7)
        if stage >= 4:
            trellis(m,0,2.19,.01,width+.30,1.87,tint)
            awning(m,0,2.12,.05,width+.08,.69,(tint,CREAM),7)
        if stage == 5:
            sawlight(m,0,2.28,-.38,width,.91,.52,tint,4)
            for x in [-.57,.57]:
                lamp(m,x,1.94,.51,.11)
            m.custom_box((0,1.70,.14),(1.27,.287,.109),INK,.094,.04,"Paint")
            for x in [-.32,0,.32]:
                m.pipe([(x,1.72,.207),(x+.083,1.72,.207)],.032,CREAM,"Light",8)
    return m


ANNEXES = ("market", "wash", "workshop", "restaurant")
