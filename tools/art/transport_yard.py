"""Original dispatch shelter, tank body and flatbed payloads for Advanced Gameplay."""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from kit import Model, bake_occlusion, clear_objects, export, output_root


NAVY, TEAL, IVORY, OCHRE, BLACK = "294e57", "42897b", "f2e3b6", "df9a50", "273337"


def depot():
    m = Model()
    m.custom_box((0, .05, 0), (14, .22, 6.9), "879796", 1.1, .13)
    m.custom_box((0, .17, 0), (13.4, .23, 6.3), "657575", .86, .11)
    m.custom_box((3.63, .26, -1.4), (5.25, .22, 3.5), "b4b4a0", .53, .075)
    m.custom_box((4.50, 1.42, -1.68), (3.10, 2.25, 2.36), IVORY, .24, .105)
    m.custom_box((4.45, 2.63, -1.67), (3.40, .40, 2.74), TEAL, .38, .085, "Paint")
    m.custom_box((4.54, 2.85, -1.53), (2.18, .13, 2.05), NAVY, .24, .053)
    m.box((3.95, 1.57, -.449), (1.38, .93, .15), "263f49", .083, "Tint")
    m.box((3.97, 1.79, -.361), (1.23, .05, .07), "a9dad1", .028, "Tint")
    m.box((5.43, 1.23, -.445), (.82, 1.61, .16), TEAL, .09, "Paint")
    m.box((5.68, 1.22, -.34), (.056, .21, .06), "afbdb7", .023, "Metal")
    m.box((3.62, 2.35, -.44), (1.81, .18, .14), OCHRE, .054, "Paint")
    for x in (-5.90, -2.84, .27):
        for z in (-2.72, 1.3):
            m.pipe([(x, .18, z), (x, 2.78, z)], .13, NAVY, "Metal")
            m.box((x, .38, z), (.37, .36, .38), OCHRE, .063, "Paint")
        m.box((x + .29, .291, 2.95), (1.2, .028, .072), IVORY, .012)
    m.custom_box((-2.80, 2.85, -.83), (7.13, .32, 4.45), NAVY, .42, .085, "Metal")
    m.custom_box((-2.80, 3.07, -.83), (7.24, .21, 4.50), TEAL, .52, .071, "Paint")
    for x in (-5.06, -2.83, -.60):
        m.box((x, 3.18, -.9), (1.84, .105, 2.75), "3b677b", .055, "Tint")
        m.box((x, 2.691, .92), (1.67, .046, .08), "ffde99", .018, "Light")
        m.box((x + 1.06, .291, 1.2), (.065, .023, 2.91), IVORY, .012)
    for i in range(5):
        m.box((-6.23 + i*.25, .276, 2.18), (.105, .023, .6), OCHRE, .012, yaw=.29)
    return m


def tanker():
    m = Model()
    m.custom_box((0, .78, -1.16), (1.76, .32, 3.15), BLACK, .26, .074, "Metal")
    m.pipe([(0, 1.46, -.12),(0, 1.46, -2.58)], .694, "b6c9c3", "Metal", 18)
    for z in (-.09, -2.57):
        m.orb((0, 1.46, z), (.693, .694, .369), "bad0c7", 18, 8, "Metal")
    for z in (-.21, -1.05, -2.37):
        m.pipe([(0, 1.46, z-.047),(0, 1.46, z+.047)], .711, TEAL, "Paint", 16)
    for x in (-.82, .82):
        m.box((x, 1.46, -1.33), (.099, .17, 2.52), OCHRE, .037, "Paint")
    m.pipe([(.72, .94, -2.74),(.72, .94, -1.57),(.87, .62, -1.40)], .075, BLACK, "Metal")
    m.orb((.02, 2.18, -1.46), (.25, .10, .20), NAVY, 14, 6, "Paint")
    m.box((0, .90, -2.98), (1.74, .18, .16), "adb7af", .045, "Metal")
    for x in (-.65,.65):
        m.box((x,.95,-3.073),(.26,.11,.047),"e45149",.025,"Light")
    return m


def trailer(kind):
    m = Model()
    m.custom_box((0, .66, -4.02), (1.83, .34, 3.38), NAVY, .25, .075, "Metal")
    for x in (-.80, .80):
        m.box((x, .82, -4.02), (.13, .22, 3.18), "bcc3ab", .041, "Metal")
        for i in range(4):
            m.box((x, .78, -5.14 + i*.69), (.14, .078, .24), OCHRE, .02, "Paint")
    if kind in ("freight", "cold", "deck"):
        wall, cap = ("439684","335658") if kind == "freight" else ("e4e9df","6bafb3") if kind == "cold" else ("b9754d","7a5a4a")
        m.custom_box((0, 1.64, -4.11), (1.79, 1.63, 2.98), wall, .21, .078, "Paint")
        m.box((0, 2.50, -4.11), (1.85, .14, 3.03), cap, .065, "Metal")
        for x in (-.91, .91):
            for i in range(9):
                m.box((x, 1.64, -5.43 + i*.32), (.08, 1.40, .078), cap, .032, "Metal")
        m.box((0, 1.63, -5.62), (1.57, 1.37, .15), cap, .055, "Metal")
        m.box((0, 1.64, -5.717), (.065, 1.27, .045), "e1d5b1", .017, "Metal")
        if kind == "cold":
            m.box((0, 2.02, -2.54), (.77, .51, .24), IVORY, .081, "Paint")
            for i in range(5):
                m.box((0, 1.89 + i*.06, -2.412), (.54,.021,.034), NAVY,.010,"Metal")
    elif kind == "logging":
        for x in (-.76,.76):
            for z in (-5.32,-4.18,-2.98):
                m.box((x, 1.45, z), (.13, 1.38, .19), OCHRE, .044, "Paint")
        for i in range(9):
            y, x = 1.01 + (i // 3) * .345, (((i%3) - 1) * .43)
            m.pipe([(x,y,-2.60),(x,y,-5.54+(i%2)*.13)], .175, "805b45", "Ceramic", 11)
            m.box((x,y,-5.55+(i%2)*.13), (.21,.19,.039),"cb9b67",.08)
    else:
        for y in (.94, 1.97):
            m.custom_box((0,y,-4.09),(1.76,.15,2.99),"687c80",.15,.055,"Metal")
            for x in (-.79,.79):
                m.box((x,y+.14,-4.08),(.122,.19,2.93),OCHRE,.036,"Paint")
        for x in (-.77,.77):
            for z in (-5.38,-2.82):
                m.box((x,1.44,z),(.16,1.24,.16),NAVY,.041,"Metal")
    for x in (-.70,.70):
        m.box((x,.75,-5.76),(.24,.10,.11),"e95044",.02,"Light")
    return m


if __name__ == "__main__":
    destination = output_root() / "assets/models/transport"
    for name, model in {"depot": depot(), "tanker": tanker(),
                        **{kind: trailer(kind) for kind in ("freight","cold","deck","logging","autos")}}.items():
        clear_objects()
        obj = model.mesh(name.title())
        bake_occlusion(obj, .48, .31)
        export(destination / (name + ".glb"))
