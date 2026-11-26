"""Render the original Route 17 HUD icons with Blender's CPU renderer."""
import sys
from math import cos, pi, sin, tau
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from kit import Model, clear_objects, output_root

TEAL = "3b9b83"
MINT = "8bd2b2"
COAL = "314e55"
CREAM = "fff1cf"
GOLD = "f2b853"
CORAL = "db815e"


def wallet():
    model = Model()
    for i, (x, z) in enumerate([(-.14, .07), (.08, -.05), (-.09, .08)]):
        y = .13 + i * .16
        model.box((x, y, z), (1.19, .16, .74), ("428a68", "6eae7e", "91c891")[i], .058)
        model.box((x, y + .025, z), (.28, .182, .77), CREAM, .031)
        for h in [-.043, .014]:
            model.box((x + .39, y + h, z + .37), (.27, .015, .01), MINT, .006)
    for i in range(3):
        y = .101 + i * .079
        model.pipe([(.57,y,.28),(.57,y+.065,.28)],.212,GOLD,"Paint",16)
    model.pipe([(.57,.317,.28),(.57,.328,.28)],.157,"ffe5a7","Metal",16)
    return model


def fuel():
    model = Model()
    model.custom_box((0, .07, 0), (1.17, .14, .69), CREAM, .20, .04)
    model.box((-.11, .58, 0), (.76, 1.10, .48), TEAL, .137, "Paint")
    model.box((-.11, 1.06, .012), (.83, .22, .52), GOLD, .089, "Paint")
    model.box((-.11, .85, .244), (.56, .25, .08), COAL, .044)
    model.box((-.11, .889, .288), (.42, .067, .017), MINT, .021, "Paint")
    for x in [-.26, -.11, .04]:
        model.box((x, .791, .283), (.068, .033, .025), CREAM, .01)
    model.pipe([(.25, .87, -.09), (.51, .76, -.04), (.61, .35, .09), (.53, .24, .24),
                (.38, .42, .34), (.39, .68, .31)], .035, COAL, "Rubber", 11)
    model.box((.37, .68, .32), (.17, .24, .14), GOLD, .046, "Paint", yaw=.30)
    return model


def road():
    model = Model()
    model.custom_box((0, .09, 0), (1.15, .18, 1.44), "cfba97", .21, .055)
    model.custom_box((0, .203, 0), (.98, .12, 1.33), "596c77", .159, .046)
    for z in [-.43, 0, .43]:
        model.box((0, .268, z), (.057, .011, .205), CREAM, .004)
    for x in [-.38, .38]:
        model.box((x, .269, 0), (.036, .012, 1.02), GOLD, .005)
    return model


def sites():
    model = Model()
    model.custom_box((0, .06, 0), (1.28, .12, 1.03), CREAM, .20, .037)
    model.box((.08, .44, -.08), (.94, .66, .66), CREAM, .09)
    model.custom_box((.08, .86, -.08), (1.12, .20, .79), CORAL, .22, .068, "Paint")
    model.custom_box((-.22, .69, .37), (.65, .11, .49), TEAL, .15, .038, "Paint")
    for x in [-.18, .27]:
        model.box((x, .39, .256), (.31, .38, .067), "79aaa8", .047, "Tint")
        model.box((x, .38, .294), (.02, .30, .009), MINT, .004)
    from premium_facades import sawlight
    sawlight(model,.15,.955,-.08,.75,.46,.25,"458e80",3)
    return model


def people():
    model = Model()
    for x, z, scale, tint in [(.25, -.17, .75, "6f9e97"), (-.17, .14, 1, TEAL)]:
        model.orb((x, .26 * scale, z), (.37 * scale, .25 * scale, .23 * scale), tint, 19, 13)
        model.orb((x, .63 * scale, z + .018), (.207 * scale, .226 * scale, .193 * scale),
                  "d99a73" if scale == 1 else "a46750", 18, 13)
        model.orb((x, .764 * scale, z - .034), (.220 * scale, .151 * scale, .18 * scale),
                  GOLD if scale == 1 else COAL, 18, 11)
        if scale == 1:
            model.orb((x, .755, z + .125), (.238, .044, .166), GOLD, 17, 9, "Paint")
            model.box((x, .389, z + .212), (.155, .112, .036), CREAM, .032)
        for side in [-1,1]:
            model.orb((x+side*.079*scale,.647*scale,z+.188*scale),
                      (.020*scale,.024*scale,.013*scale),COAL,8,5)
    return model


def goals():
    model = Model()
    model.box((0, .59, 0), (.83, 1.11, .17), TEAL, .149, "Paint")
    model.box((0, .57, .087), (.69, .88, .06), CREAM, .084)
    model.box((0, 1.08, .099), (.39, .189, .123), GOLD, .067, "Paint")
    model.pipe([(-.22, .628, .132), (-.075, .480, .136), (.219, .776, .14)], .047, TEAL, "Paint", 10)
    model.box((0, .318, .131), (.325, .045, .017), "bdad8a", .012)
    return model


def finance():
    model = Model()
    for x, z, layers in [(-.32, .16, 3), (.28, -.15, 5)]:
        for i in range(layers):
            y = .05 + i * .095
            model.pipe([(x, y, z), (x, y + .081, z)], .277, GOLD, "Paint", 22)
            model.pipe([(x, y + .065, z), (x, y + .084, z)], .285, "eaa448", "Paint", 22)
        y = .061 + layers * .095
        model.pipe([(x, y - .021, z), (x, y, z)], .212, "ffe19a", "Paint", 22)
        model.box((x, y + .008, z), (.173, .018, .062), "d99547", .008)
    return model


def diamond():
    model = Model()
    vertices = [(0, -.08, .01)]
    for y, radius in [(.38, .56), (.65, .34)]:
        vertices.extend((cos(i * tau / 6 + .28) * radius, y, sin(i * tau / 6 + .28) * radius * .86)
                        for i in range(6))
    shades = ["ac8edf", "8760c2", "c4a2f1", "936dcb", "7252ad", "bea0ec"]
    for i, tint in enumerate(shades):
        j = (i + 1) % 6
        model.add(vertices, [(0, 1 + i, 1 + j), (1 + i, 7 + i, 7 + j, 1 + j)], tint, "Paint")
    model.add(vertices, [tuple(reversed(range(7, 13)))], "d0b3f7", "Tint")
    return model


def reput():
    model = Model()
    layers = [(0.0, .88), (.047, 1), (.163, .97), (.202, .81)]
    vertices = []
    for z, scale in layers:
        for i in range(10):
            t = pi / 2 + i * tau / 10
            radius = (.62 if i % 2 == 0 else .312) * scale
            vertices.append((cos(t) * radius, .58 + sin(t) * radius, z))
    faces = [tuple(reversed(range(10)))]
    for layer in range(len(layers) - 1):
        for i in range(10):
            j = (i + 1) % 10
            faces.append((layer * 10 + i, layer * 10 + j, (layer + 1) * 10 + j, (layer + 1) * 10 + i))
    faces.append(tuple(range(30, 40)))
    model.add(vertices, faces, GOLD, "Paint")
    model.orb((-.097, .606, .205), (.081, .146, .017), "ffe5ae", 10, 6, yaw=.34)
    return model


def ticket():
    model = Model()
    for offset, tint in [(-.057, "9b5944"), (.037, CORAL)]:
        model.box((offset, .463 + offset, 0), (.99, .78, .154), tint, .157, "Paint")
    model.box((.04, .478, .085), (.679, .523, .065), CREAM, .096)
    model.pipe([(-.226, .440, .131), (-.115, .543, .135), (-.017, .431, .135),
                (.090, .552, .135), (.194, .439, .133)], .029, CORAL, "Paint", 8)
    return model


def upgrade():
    model = Model()
    model.box((0, .167, 0), (.93, .232, .62), "ce9451", .099, "Paint")
    vertices = [(-.216, .26, -.14), (.216, .26, -.14), (.216, .62, -.14), (.434, .62, -.14),
                (0, 1.07, -.14), (-.434, .62, -.14), (-.216, .62, -.14)]
    model.add(vertices + [(x, y, z + .318) for x, y, z in vertices],
              [tuple(reversed(range(7))), tuple(range(7, 14))] +
              [(i, (i + 1) % 7, (i + 1) % 7 + 7, i + 7) for i in range(7)], GOLD, "Paint")
    model.pipe([(-.241, .669, .195), (0, .902, .197), (.24, .665, .195)], .034, CREAM, "Paint", 8)
    return model


def point_at(obj, target):
    obj.rotation_euler = (target - obj.location).to_track_quat("-Z", "Y").to_euler()


def render(name, make):
    clear_objects()
    mesh = make().mesh(name)
    bounds = [Vector(corner) for corner in mesh.bound_box]
    target = sum(bounds, Vector()) / len(bounds)
    camera = bpy.data.objects.new("Icon Camera", bpy.data.cameras.new("Icon Camera"))
    bpy.context.collection.objects.link(camera)
    camera.location = target + Vector((2.8, -6.0, 3.7))
    point_at(camera, target)
    camera.data.type = "ORTHO"
    rotation = camera.rotation_euler.to_matrix().transposed()
    projected = [rotation @ (corner - target) for corner in bounds]
    camera.data.ortho_scale = 2.30 * max(abs(p.x) for p in projected)
    camera.data.ortho_scale = max(camera.data.ortho_scale, 2.30 * max(abs(p.y) for p in projected))
    for position, energy, color, size in [((-3, -4, 6), 560, (1, .91, .79), 4),
                                         ((3, -1, 3), 240, (.71, .88, 1), 3),
                                         ((0, 4, 5), 350, (1, .85, .64), 3)]:
        lamp = bpy.data.lights.new("Softbox", "AREA")
        lamp.energy, lamp.color, lamp.size = energy, color, size
        obj = bpy.data.objects.new("Softbox", lamp)
        bpy.context.collection.objects.link(obj)
        obj.location = position
        point_at(obj, target)
    scene = bpy.context.scene
    scene.camera = camera
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 96
    scene.cycles.use_denoising = False
    scene.render.film_transparent = True
    scene.render.resolution_x = scene.render.resolution_y = 152
    scene.render.resolution_percentage = 100
    scene.render.image_settings.color_mode = "RGBA"
    scene.world.use_nodes = True
    scene.world.node_tree.nodes.get("Background").inputs[0].default_value = (.52, .61, .68, 1)
    scene.world.node_tree.nodes.get("Background").inputs[1].default_value = .45
    scene.view_settings.view_transform = "AgX"
    folder = output_root() / "assets/ui"
    folder.mkdir(parents=True, exist_ok=True)
    scene.render.filepath = str(folder / f"icon_{name}.png")
    bpy.ops.render.render(write_still=True)


if __name__ == "__main__":
    picks = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    icons = dict(cash=wallet, fuel=fuel, road=road, sites=sites, staff=people, goals=goals, finance=finance,
                 diamond=diamond, reputation=reput, event=ticket, upgrade=upgrade)
    for key, make in icons.items():
        if not picks or key in picks:
            render(key, make)

    from premium_facades import canopy_trim
    from station_designs import worn, rehab, service, cantilever, ridge

    for number, make in enumerate((worn, rehab, service, cantilever, ridge), start=1):
        if not picks or "stages" in picks:
            render(f"stage_{number}", lambda: canopy_trim(make(), "canopy_" + make.__name__))
