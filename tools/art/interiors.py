"""Make the service cutaways and detachable roofs in Blender."""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from kit import Model, bake_occlusion, clear_objects, export, output_root

CREAM, TILE, TEAL, NAVY, BRASS, WOOD = "f5ead2", "b8c9bd", "539494", "314b52", "e2a358", "b18c67"
PAL = {
    "market": ("64aaa3", "d6a26d", "ece1c8"),
    "workshop": ("55868b", "dd8b54", "9eaaa3"),
    "restaurant": ("a26454", "d8ae79", "f1dfbd"),
    "wash": ("4e94aa", "70cabb", "a9c6bf"),
    "hotel": ("565a78", "d9ad73", "e5d4bd"),
    "dealership": ("376880", "ca9864", "b8c6cc"),
    "mall": ("687690", "71ada0", "ead8c9"),
    "warehouse": ("6f8488", "c8a05d", "b2b6a1"),
    "logistics": ("326a77", "f0ad54", "9bacaa"),
}


def counter(m, x, z, w, d, face, top=CREAM):
    m.custom_box((x,.51,z),(w,.86,d),face,.22,.075)
    m.custom_box((x,.97,z),(w+.13,.13,d+.14),top,.23,.048,"Ceramic")
    m.box((x,.23,z+d/2), (w*.83,.12,.06), NAVY,.024,"Metal")


def stool(m, x, z, accent):
    m.pipe([(x,.23,z),(x,.66,z)], .082, NAVY, "Metal")
    m.orb((x,.68,z),(.35,.13,.32),accent,14,6,"Paint")


def sofa(m,x,z,material):
    m.custom_box((x,.41,z),(1.87,.54,.82),material,.20,.09)
    m.custom_box((x,.77,z-.33),(1.91,.52,.28),material,.15,.08)
    for dx in (-.92,.92):
        m.custom_box((x+dx,.58,z),(0.22,.49,.93),CREAM,.15,.068)


def crate(m, x, y, z, width, tint):
    m.custom_box((x,y,z),(width,.50,.57),tint,.13,.048)
    for side in (-1,1):
        m.box((x+width*.32*side,y,z+.30),(.062,.48,.045), "d9bf89", .019)
    m.box((x,y+.08,z+.325), (width*.35,.135,.022), CREAM,.017)


def shelf(m, x, z, refrigerated=False, wide=2.25):
    trim = "7cb7b6" if refrigerated else WOOD
    for side in (-1,1):
        m.box((x+wide*.5*side,1.14,z),(.13,2.04,.67),trim,.05,"Paint")
    m.box((x,1.15,z-.29),(wide,.2+1.82,.105),NAVY,.047,"Metal")
    colors = ("d4ab64","8ead78","cf755e","8eb3b2","c49070","a6859e")
    for level in range(4):
        y = .43 + level*.45
        m.box((x,y,z),(wide,.09,.62),CREAM,.031)
        for i in range(5):
            dx = wide*(i-2)/5.6
            m.custom_box((x+dx,y+.166,z+.063),(wide*.125,.21+(i%2)*.072,.27),colors[(i+2*level)%6],.066,.024,"Paint")
    if refrigerated:
        m.box((x,2.17,z),(wide,.16,.63),"a7dbd0",.044,"Light")


def room(key):
    trim, accent, floor = PAL[key]
    m = Model()
    m.custom_box((0,.06,0),(11.5,.24,8.12),NAVY,.595,.13,"Paint")
    m.custom_box((0,.201,0),(11.24,.07,7.89),floor,.52,.055)
    for i in range(1,14):
        m.box((-5.5+i*.788,.240,0),(.022,.012,7.55), "d5c6a9" if key in ("market","hotel","restaurant","mall") else "869994", .008)
    for j in range(1,9):
        m.box((0,.24,-3.92+j*.865),(10.78,.012,.026),"cfc1a6" if key in ("hotel","restaurant","mall") else "95aaa2",.008)
    for pos,size in (((0,1.58,-3.89),(11.24,2.72,.28)),((-5.54,1.33,-1.56),(.28,2.26,4.50))):
        m.custom_box(pos,size,CREAM,.23,.089)
        m.box((pos[0],.46,pos[2]+.155), (size[0],.26,.102), trim,.041,"Paint")
    for x in (-4.0,-.7,2.7):
        m.custom_box((x,1.88,-3.716),(2.12,1.06,.099),NAVY,.21,.065,"Metal")
        m.custom_box((x,1.87,-3.65),(1.94,.89,.066),"73a9ab",.17,.042,"Tint")
        m.box((x,2.06,-3.609),(1.66,.045,.077),"b7dfd4",.022,"Tint")
        m.box((x,1.85,-3.594),(.067,.90,.077),CREAM,.025,"Paint")
    m.pipe([(-5.28,2.66,-3.61),(4.98,2.66,-3.61)], .095,trim,"Metal")
    m.box((0,2.53,-3.59),(8.4,.075,.085),"ffe2a8",.028,"Light")
    for x in (-4.69,4.55):
        m.custom_box((x,.40,3.60),(1.25,.37,.48),trim,.16,.053,"Paint")
    match key:
        case "market":
            shelf(m,-3,-2.89,True)
            shelf(m,-5.04,-.54,True,1.05)
            shelf(m,-2.2,.92)
            shelf(m,.63,.92)
            shelf(m,3.56,-2.89,True)
            counter(m,3.08,2.16,2.57,1.1,trim)
            m.custom_box((3.65,1.19,2.12),(.52,.46,.76),NAVY,.09,.041,"Metal")
            m.box((3.69,1.33,2.54),(.352,.119,.09),"a9ddd3",.022,"Tint")
            m.box((2.43,1.07,2.13),(.93,.10,.70),"384a4e",.07,"Metal")
        case "workshop":
            for x in (-2.38,.48):
                m.custom_box((x,1.33,.6),(.28,2.12,.31), trim,.08,.052,"Metal")
                m.box((x,.41,.94),(.90,.13,1.58), accent,.039,"Metal")
            counter(m,3.41,-2.50,2.74,1.11,trim,WOOD)
            for j in range(5):
                m.box((3.40,.45+j*.10,-1.92),(2.38,.055,.09),accent,.022,"Paint")
            for j in range(4):
                m.pipe([(2.7+j*.39,1.56,-3.58),(2.7+j*.39,1.98,-3.54),(2.83+j*.39,2.13,-3.53)],.045,"abb4ac","Metal")
            for y in (.40,.67,.94):
                m.pipe([(-4.29,y-.14,-2.3),(-4.29,y+.12,-2.3)], .42, "354149","Metal",17)
            m.orb((-3.7,.78,2.19),(.43,.55,.51),accent,12,6,"Paint")
        case "restaurant":
            for x in (-3.5,-.9,1.75):
                sofa(m,x,-.98,trim)
                counter(m,x,.02,1.55,.93,WOOD)
                for dx in (-.49,.49):
                    stool(m,x+dx,1.05,accent)
                for dx in (-.42,.38):
                    m.orb((x+dx,1.04,.02),(.18,.04,.16),CREAM,12,5,"Ceramic")
            counter(m,2.12,-2.37,4.52,.97,trim)
            counter(m,3.92,1.28,1.45,1.02,WOOD)
            for x in (.96,1.53,2.07):
                m.orb((x,1.09,-2.33),(.21,.068,.20),NAVY,14,5,"Metal")
        case "wash":
            for x in (-2.86,2.86):
                m.custom_box((x,1.69,.25),(.60,2.96,1.04),trim,.18,.10,"Metal")
                m.box((x,1.76,.79),(.18,2.31,.14),"b3e1d3",.055,"Light")
                m.pipe([(x,.36,2.95),(x,.36,-2.7)],.092,"d1dec1","Metal")
            m.custom_box((0,3.19,.25),(6.33,.51,1.16),trim,.30,.107,"Paint")
            for z in (-2.5,-1.9,1.9,2.5):
                m.box((0,.249,z),(4.5,.022,.093),accent,.011)
            for j in range(10):
                m.box((-.42+j*.092,.247,.25),(.049,.026,6.15),NAVY,.012,"Metal")
            counter(m,4.46,-1.92,1.37,1.65,NAVY)
        case "hotel":
            counter(m,2.71,1.65,3.34,1.09,trim)
            sofa(m,-3.41,1.52,trim)
            counter(m,-3.41,2.55,1.65,.62,WOOD)
            for x in (-3.04,-.33,2.37,4.51):
                m.custom_box((x,1.31,-3.56),(1.02,1.96,.20),trim,.16,.084,"Paint")
                m.box((x+.31,1.34,-3.42),(.13,.052,.071),accent,.018,"Metal")
                m.box((x,2.15,-3.40),(.59,.12,.079),accent,.037,"Light")
            m.custom_box((.41,.267,2.16),(2.81,.068,2.04),trim,.53,.030,"Ceramic")
            for x in (-.66,1.45):
                m.box((x,.31,2.16),(.047,.022,1.77),accent,.013)
        case "dealership":
            for x in (-3.38, .04, 3.52):
                m.custom_box((x,.34,-.82),(2.92,.28,4.3),trim,.68,.075,"Paint")
                m.box((x,.497,1.18),(2.32,.05,.13),accent,.021,"Light")
            counter(m,3.58,2.54,1.89,.68,trim)
            sofa(m,-3.60,2.31,accent)
        case "mall":
            for x in (-4.0,-1.09,1.8):
                counter(m,x,-1.70,2.1,1.30,trim,accent)
                shelf(m,x,-3.14,False,1.92)
                for j in range(4):
                    m.box((x-.72+j*.48,2.58,-1.59),(.46,.19,1.48),accent if j%2 else CREAM,.045,"Paint")
            sofa(m,2.75,2.12,trim)
            shelf(m,4.49,.14,True,1.21)
            counter(m,-3.78,2.11,1.61,.81,trim)
        case "warehouse" | "logistics":
            for x in (-3.6,-.05,3.47):
                for side in (-1,1):
                    m.box((x+side*1.16,1.46,-2.62),(.19,2.73,1.04),trim,.072,"Metal")
                for row in range(3):
                    y = .39 + row*.86
                    m.box((x,y,-2.62),(2.34,.13,1.06),accent,.052,"Metal")
                    for i, tint in enumerate(("bc8460","849f96","cfa26c")):
                        crate(m,x+(i-1)*.67,y+.33,-2.57,.58,tint)
            for x in (-2.6,2.4):
                m.box((x,.249,1.43),(.074,.022,4.59),accent,.014,"Paint")
            if key == "logistics":
                for x in (-3.10,3.10):
                    m.box((x,1.79,1.47),(.37,3.12,.47),trim,.08,"Metal")
                m.custom_box((0,3.48,1.47),(6.81,.38,.73),accent,.22,.079,"Metal")
            else:
                counter(m,3.62,1.30,1.65,1.16,trim)
            crate(m,-3.74,.69,2.26,1.0,accent)
    return m


def roof(key):
    trim, accent, _ = PAL[key]
    m = Model()
    m.custom_box((0,3.07,0),(11.44,.35,8.18),trim,.50,.11,"Paint")
    m.custom_box((0,3.263,0),(10.78,.11,7.41),accent,.53,.058,"Paint")
    for x in (-4.21,-2.28,-.25,1.76,3.74):
        m.box((x,3.36,0),(.061,.12,7.35),trim,.028,"Metal")
    return m


if __name__ == "__main__":
    for name in PAL:
        clear_objects()
        art = room(name).mesh("Room")
        bake_occlusion(art, .49, .39)
        roof(name).mesh("Roof")
        export(output_root() / "assets/models/interiors" / (name + ".glb"))
