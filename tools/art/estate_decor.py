"""Five distinct coordinated options for each freestanding scenery slot."""
from pathlib import Path
import sys
from math import tau, cos, sin

sys.path.insert(0, str(Path(__file__).resolve().parent))
from kit import Model, clear_objects, bake_occlusion, export, output_root

PRIMARY = ["7496a2", "d3a169", "728d71", "8b75a4", "c76d58"]
ACCENT = ["c6e0d8", "f0d396", "e4cf9a", "d8bde3", "eac2a4"]
DARK = "364d50"


def decor(key, variant):
    m = Model()
    base, edge = PRIMARY[variant], ACCENT[variant]
    match key:
        case "sign" | "billboard":
            scale = 1.72 if key == "billboard" else 1.0
            wide = (2.40 + variant * .12) * scale
            for x in ([-.59, .59] if variant != 4 else [0]):
                m.pipe([(x*scale,.09,0),(x*scale,1.63*scale,0)], .10*scale,DARK,"Metal")
                m.box((x*scale,.12,0),(.36*scale,.23,.37*scale),base,.07,"Paint")
            y = 1.86 * scale
            m.custom_box((0,y,0),(wide,.77*scale,.24),base,.26*scale,.09,"Paint")
            m.custom_box((0,y,.156),(wide-.28,.56*scale,.07),DARK,.18,.033,"Tint")
            m.box((0,y+.31*scale,.156),(wide*.76,.053,.071),edge,.021,"Light")
            if variant in (1, 2, 3):
                m.orb((-wide*.45,y+.22*scale,.21),(.23*scale,.26*scale,.10),edge,12,6,"Paint")
        case "lights":
            for index, x in enumerate((-1.25, .0, 1.25)):
                h = 2.18 + (index%2)*.39 + variant*.17
                m.custom_box((x,.14,0),(.49,.27,.48),DARK,.15,.07)
                m.pipe([(x,.24,0),(x,h,0),(x+.17*variant,h+.13,0)],.073,base,"Metal")
                m.orb((x+.17*variant,h+.14,0),(.28,.16+.018*variant,.27),edge,12,7,"Light")
        case "fence":
            for i in range(7 + variant):
                x = -2.75 + i*5.5/(6+variant)
                m.custom_box((x,.55+(i%2)*.06,0),(.13+.028*variant,1.10+(i%2)*.12,.22),base,.051,.025,"Paint")
                m.orb((x,1.10+(i%2)*.12,0),(.125,.094,.114),edge,10,6)
            for height in (.37, .75) if variant != 4 else (.63,):
                m.box((0,height,0),(5.59,.13,.132),edge,.040,"Metal")
        case "paving":
            for y in range(3 + variant % 2):
                for x in range(5):
                    color = edge if (x+2*y+variant) % (2+variant) == 0 else base
                    width = .87 if variant % 2 else .72
                    m.custom_box(((x-2)*width + ((y%2)*.28 if variant > 1 else 0),.065,(y-1)*.54),
                                 (width-.07,.11,.48),color,.10+.033*variant,.036)
        case "planter":
            for x in [-.66,.66] if variant == 4 else [0]:
                m.custom_box((x,.25,0),(2.55 if variant<3 else 1.20,.45,.79),base,.14+variant*.052,.075)
                m.custom_box((x,.476,0),(2.31 if variant<3 else 1.02,.092,.71),edge,.18,.043,"Paint")
                for i in range(3):
                    scale=.20+.048*((i+variant)%3)
                    m.orb((x+(i-1)*.33,.59+scale, 0),(scale,.29+variant*.018,.22),"5b876d",12,6)
                    m.orb((x+(i-1)*.335,.72+scale,.071),(.137,.099,.146),edge,10,5,"Paint")
        case "bench":
            for x in (-.81,.81):
                m.custom_box((x,.21,0),(.19,.39,.57),DARK,.074,.048,"Metal")
            for i in range(3+variant):
                p = -.34+i*(.68/(2+variant))
                m.box((0,.49,p),(2.31,.127,.15),edge,.055,"Paint")
            if variant != 4:
                m.custom_box((0,.89,-.34),(2.31,.49-.036*variant,.19),base,.15,.063,"Paint")
            for x in (-.91,.91):
                m.pipe([(x,.37,.18),(x,.67,.19),(x,.67,-.45)],.062,DARK,"Metal")
        case "fountain":
            m.orb((0,.18,0),(1.26+.09*variant,.26,1.01),base,26,8,"Paint")
            m.orb((0,.35,0),(1.08+.09*variant,.114,.87),"70c1c9",24,7,"Tint")
            for j in range(2 + variant):
                offset = tau*j/(2+variant)
                x,z = cos(offset)*.37, sin(offset)*.30
                m.pipe([(0,.52,0),(x*.34,1.03+.08*variant,z*.28),(x,.46,z)],.029,"bde3db","Tint",8)
            m.orb((0,.56,0),(.27,.31,.25),edge,14,7)
    return m


if __name__ == "__main__":
    for slot in ("sign","lights","fence","paving","planter","bench","fountain","billboard"):
        for variant in range(5):
            clear_objects()
            asset = decor(slot, variant).mesh(slot.title())
            bake_occlusion(asset,.38,.23)
            export(output_root() / "assets/models/estates" / f"{slot}_{variant+1}.glb")
