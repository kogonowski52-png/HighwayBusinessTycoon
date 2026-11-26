"""Additional service buildings for the existing Route 17 map."""
from math import cos, sin, tau

from architecture import (AQUA, BRICK, COAL, CONCRETE, COOL, CORAL, CREAM, DARK,
                          IRON, LAMP, MINT, OCHRE, SAND, SEA, TEAL, WINDOW, bench,
                          bollard, north_mark, planter, slab, solar, strip, trim)
from kit import Model, bake_occlusion, clear_objects, export


def tire_shop():
    model = Model()
    slab(model, (0, .055, .48), (7.82, .11, 6.05))
    model.box((0, 1.42, -2.05), (7.28, 2.62, .34), "ba9a78", .09)
    model.custom_box((-.18, 2.73, -.28), (7.62, .27, 4.60), IRON, .27, .066, "Metal")
    model.custom_box((-.18, 2.93, -.55), (7.46, .20, 3.92), "956852", .23, .058, "Paint")
    model.custom_box((-.18, 3.092, -.92), (6.86, .15, 2.64), BRICK, .23, .050, "Paint")
    for index in range(14):
        trim(model, (-3.23 + .465 * index, 3.179, -.92), (.052, .038, 2.56), "b57a5a")
    model.box((-.18, 2.64, 2.03), (7.48, .35, .19), BRICK, .09, "Paint")
    model.box((-.18, 2.85, 2.06), (7.63, .104, .26), OCHRE, .042, "Paint")
    for x in [-3.70, -.10, 3.45]:
        model.box((x, 1.36, 1.75), (.27, 2.56, .33), IRON, .055, "Metal")
        model.box((x, .34, 1.75), (.36, .55, .40), COAL, .042, "Metal")
    for x in [-1.74, 1.72]:
        model.box((x, .10, .8), (2.49, .085, 3.13), "777e76", .049, "Metal")
        for dx in [-.87, .87]:
            model.box((x + dx, .147, .80), (.198, .04, 2.88), "96a5a0", .026, "Metal")
        strip(model, (x, 2.48, .28), (2.31, .048, .086), LAMP)
    for rack in [-2.68, -.16, 2.29]:
        model.box((rack, .63, -1.75), (1.10, 1.02, .38), CORAL, .042, "Paint")
        for y in [.44, .68, .94]:
            trim(model, (rack, y, -1.539), (.82, .038, .060), COOL)
    for stack in [(-3.34, -.38), (-.27, -.62), (2.98, -.57)]:
        x, z = stack
        for level in range(3):
            path = [(x + .366 * cos(angle * tau / 16), .22 + .205 * level,
                     z + .366 * sin(angle * tau / 16)) for angle in range(17)]
            model.pipe(path, .108, "303f3d" if level != 1 else "48534b", "Rubber", sides=8)
    model.box((3.00, .99, .59), (.63, 1.51, .45), TEAL, .058, "Paint")
    model.box((3.00, 1.40, .83), (.48, .33, .051), WINDOW, .024, "Tint")
    strip(model, (3.00, 1.50, .859), (.34, .041, .008), AQUA)
    bollard(model, 3.56, 2.57, .63)
    return model


def ev_lounge():
    model = Model()
    slab(model, (0, .06, .12), (3.62, .12, 3.83), SAND)
    model.custom_box((0, 1.09, -.31), (3.14, 1.94, 2.42), CREAM, .27, .082)
    model.custom_box((0, 2.09, -.18), (3.58, .28, 2.93), TEAL, .31, .081, "Paint")
    model.custom_box((-.28, 2.27, -.37), (2.77, .11, 2.14), MINT, .28, .035, "Paint")
    model.box((.79, 1.06, .917), (1.08, 1.55, .12), SEA, .05, "Paint")
    model.box((.79, 1.17, .991), (.88, 1.03, .028), WINDOW, .03, "Tint")
    trim(model, (1.12, .86, 1.021), (.039, .18, .037), CREAM)
    model.box((-.70, 1.12, .920), (1.38, 1.13, .105), DARK, .065)
    model.box((-.70, 1.12, .983), (1.20, .94, .028), COOL, .036, "Tint")
    for x in [-1.14, -.71, -.26]:
        model.box((x, 1.14, 1.004), (.13, .84, .028), "82aaa2", .014, "Tint")
    model.custom_box((0, 1.93, 1.19), (3.26, .19, .82), OCHRE, .20, .047, "Paint")
    strip(model, (0, 1.810, 1.28), (2.61, .049, .082))
    bench(model, -.75, 1.48, .12)
    planter(model, .84, -1.75, 1.26, y=.02)
    return model


def ev_column():
    model = Model()
    slab(model, (0, .075, 0), (.78, .15, .81), "b3b6a1")
    model.box((0, .86, 0), (.44, 1.53, .41), CREAM, .08, "Paint")
    model.box((0, 1.62, .003), (.48, .22, .432), TEAL, .085, "Paint")
    model.box((0, 1.27, .226), (.306, .27, .056), DARK, .047)
    strip(model, (0, 1.30, .257), (.211, .049, .011), AQUA)
    model.pipe([(-.22, 1.25, .092), (-.36, 1.10, .081), (-.39, .38, .051),
                (-.37, .28, -.114), (-.29, .53, -.13), (-.29, .93, -.057)],
               .036, COAL, "Rubber", 8)
    model.box((-.257, .967, -.049), (.131, .212, .127), SEA, .036, "Paint")
    for x in [-.29, .29]:
        bollard(model, x, .34, .40, MINT, .10)
    return model


def freight_office():
    model = Model()
    slab(model, (0, .08, .13), (3.22, .16, 3.12), "a9a88f")
    model.custom_box((0, 1.30, -.13), (2.81, 2.25, 2.34), "a7b4a1", .22, .082)
    model.custom_box((0, 2.46, -.14), (3.10, .29, 2.63), IRON, .28, .059, "Metal")
    model.custom_box((0, 2.61, -.04), (2.95, .13, 2.56), OCHRE, .24, .043, "Paint")
    model.box((-.56, 1.16, 1.064), (.85, 1.74, .117), IRON, .069)
    model.box((-.56, 1.40, 1.137), (.71, 1.10, .058), WINDOW, .055, "Tint")
    for x in [.30, .86]:
        model.box((x, 1.38, 1.13), (.41, .86, .121), WINDOW, .067, "Tint")
    model.box((.53, 1.57, 1.205), (.866, .034, .015), COOL, .008, "Tint")
    trim(model, (-.301, .94, 1.183), (.04, .160, .036), CREAM)
    model.custom_box((-.17, 2.15, 1.27), (2.58, .169, .94), TEAL, .20, .046, "Paint")
    strip(model, (-.09, 2.040, 1.37), (1.88, .060, .073))
    bench(model, .55, 1.54, .12)
    return model


def freight_sign():
    model = Model()
    slab(model, (0, .065, 0), (.91, .13, .67), "a0a99a")
    model.box((0, .83, 0), (.16, 1.46, .146), IRON, .035, "Metal")
    model.custom_box((0, 1.41, .018), (.70, .59, .15), SEA, .07, .045, "Paint")
    model.box((0, 1.41, .107), (.583, .437, .027), DARK, .048, "Tint")
    strip(model, (0, 1.71, .038), (.58, .028, .069), LAMP)
    return model


def ev_solar():
    model = Model()
    for x in [-1.22, 1.22]:
        model.pipe([(x, .065, -1.46), (x, 2.66, -1.46), (x, 2.85, -.86)], .085, IRON, "Metal", 10)
        model.pipe([(x, 2.19, -1.46), (x, 2.90, .02)], .051, COOL, "Metal", 9)
    model.custom_box((0, 2.933, -.53), (2.74, .15, 2.08), DARK, .17, .035)
    solar(model, 0, 3.084, -.53, 2.56, 1.91)
    strip(model, (0, 2.848, .37), (2.34, .041, .066), AQUA)
    return model


MODELS = {
    "tire_shop": tire_shop, "ev_lounge": ev_lounge, "ev_column": ev_column, "ev_solar": ev_solar,
    "freight_office": freight_office, "freight_sign": freight_sign,
}


def generate(root, selection=None):
    from premium_facades import roadside_extra
    folder = root / "assets/models/architecture"
    for key, make in MODELS.items():
        if selection and key not in selection:
            continue
        clear_objects()
        mesh = roadside_extra(key, make()).mesh(key)
        bake_occlusion(mesh, .73)
        export(folder / f"{key}.glb")
