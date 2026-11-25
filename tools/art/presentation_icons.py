"""Blender-rendered metal and enamel icons for the Route 17 HUD."""
from math import cos, sin, tau
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))

from hud_icons import Model, render, COAL, CREAM, TEAL, MINT, GOLD, CORAL


def settings():
    model = Model()
    model.pipe([(0, 0.11, 0), (0, .28, 0)], .49, "789294", "Metal", 38)
    for n in range(10):
        theta = n * tau / 10
        model.box((cos(theta) * .49, .19, sin(theta) * .49), (.28, .22, .18),
                  "8ca9a7", .053, "Metal", yaw=-theta)
    model.pipe([(0, .27, 0), (0, .322, 0)], .385, "b4ccbd", "Metal", 38)
    model.pipe([(0, .322, 0), (0, .339, 0)], .241, COAL, "Paint", 24)
    model.pipe([(0, .339, 0), (0, .390, 0)], .179, MINT, "Paint", 24)
    return model


def cards():
    model = Model()
    for x, y, z, tint, yaw in [(-.17, .11, -.12, "748db1", .32), (.16, .21, .04, "ae88ad", -.23)]:
        model.custom_box((x, y, z), (.73, .159, .97), tint, .138, .059, "Paint", yaw=yaw)
    model.custom_box((0, .30, .03), (.77, .139, 1.02), "5f7a88", .13, .051, "Paint", yaw=.13)
    model.custom_box((0, .373, .03), (.683, .040, .92), CREAM, .102, .014, "Paint", yaw=.13)
    model.orb((.011, .411, -.113), (.115, .042, .129), CORAL, 18, 10)
    model.orb((.023, .403, .123), (.212, .035, .105), TEAL, 20, 9)
    return model


def gift():
    model = Model()
    model.custom_box((0, .31, .035), (1.04, .61, .78), "6b6594", .169, .087, "Paint")
    model.custom_box((0, .643, .024), (1.17, .24, .88), "ab88be", .189, .068, "Paint")
    model.box((0, .643, .48), (.257, .25, .037), GOLD, .012, "Paint")
    model.box((0, .372, .429), (.247, .48, .037), GOLD, .012, "Paint")
    model.box((0, .776, .04), (.25, .027, .85), GOLD, .011, "Paint")
    for side in [-1, 1]:
        model.pipe([(0, .791, .06), (side * .259, .974, .034), (side * .35, .843, .018),
                    (side * .12, .806, .054), (0, .791, .06)], .065, "ffda81", "Paint", 12)
    return model


def calendar():
    model = Model()
    model.custom_box((0, .42, -.049), (.93, .83, .19), CORAL, .076, .059, "Paint")
    model.box((0, .39, .054), (.769, .55, .062), CREAM, .044, "Paint")
    for x in [-.26, .25]:
        model.pipe([(x, .702, -.106), (x, .848, -.057), (x, .818, .10), (x, .733, .134)],
                   .033, COAL, "Metal", 10)
    for x in [-.23, .00, .23]:
        for y in [.275, .470]:
            model.box((x, y, .096), (.125, .102, .024), GOLD if y > .4 and x == .23 else MINT, .023, "Paint")
    return model


def help_sign():
    model = Model()
    model.custom_box((0, .050, 0), (.82, .11, .66), COAL, .14, .031, "Metal")
    model.box((0, .39, 0), (.08, .70, .10), "8eb5aa", .034, "Metal")
    model.box((0, .69, .03), (1.01, .47, .19), TEAL, .09, "Paint")
    model.box((0, .69, .142), (.87, .343, .057), CREAM, .072, "Paint")
    model.pipe([(-.27, .666, .181), (.26, .666, .181), (.11, .791, .185)], .034, TEAL, "Paint", 12)
    return model


if __name__ == "__main__":
    for title, icon in {"settings": settings, "cards": cards, "gift": gift, "calendar": calendar, "help": help_sign}.items():
        render(title, icon)
