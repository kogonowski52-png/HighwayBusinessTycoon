"""Original manager card portraits. Run through Blender in background mode."""
import sys
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from characters import DIRECTORS, NEW_DIRECTORS, actor
from kit import Model, clear_objects, output_root

FRAMES = {
    "common": ("3f7e6d", "79b098"),
    "rare": ("455b84", "809cbb"),
    "epic": ("6b4a7c", "ab86b3"),
    "legendary": ("9c6949", "dfab69"),
}
RARE = {"iga", "maks", "zofia", "arun", "ben"}
EPIC = {"mira", "leon", "lena", "olu", "alina"}
LEGENDARY = {"vera", "jo"}


def point_at(obj, target):
    obj.rotation_euler = (target - obj.location).to_track_quat("-Z", "Y").to_euler()


def frame(rare):
    base, ring = FRAMES[rare]
    model = Model()
    model.pipe([(0, 1.56, -.41), (0, 1.56, -.36)], .49, base, "Paint", sides=48)
    model.pipe([(0, 1.56, -.36), (0, 1.56, -.340)], .464, ring, "Paint", sides=48)
    model.pipe([(0, 1.56, -.339), (0, 1.56, -.318)], .432, base, "Ceramic", sides=48)
    model.mesh("Medallion")


def render(role, index, folder):
    clear_objects()
    actor(role)
    rarity = ("legendary" if role.key in LEGENDARY else "epic" if role.key in EPIC else
              "rare" if role.key in RARE else "common")
    frame(rarity)
    target = Vector((0, .03, 1.56))
    camera = bpy.data.objects.new("Portrait Camera", bpy.data.cameras.new("Portrait Camera"))
    bpy.context.collection.objects.link(camera)
    camera.location = target + Vector((-.51 if index % 2 else .56, -3.8, .26))
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 1.10
    point_at(camera, target)

    for position, energy, color, size in [((-2, -2.5, 4), 180, (1, .89, .75), 2.5),
                                         ((2.2, -2, 2.3), 80, (.72, .87, 1), 2.5),
                                         ((0, 1.3, 3), 142, (1, .73, .47), 1.4)]:
        light = bpy.data.lights.new("Softbox", "AREA")
        light.energy, light.color, light.size = energy, color, size
        lamp = bpy.data.objects.new("Softbox", light)
        bpy.context.collection.objects.link(lamp)
        lamp.location = position
        point_at(lamp, target)
    scene = bpy.context.scene
    scene.camera = camera
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 64
    scene.cycles.use_denoising = False
    scene.render.film_transparent = True
    scene.render.resolution_x = scene.render.resolution_y = 224
    scene.render.resolution_percentage = 100
    scene.render.image_settings.color_mode = "RGBA"
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs[0].default_value = (.51, .57, .64, 1)
    scene.world.node_tree.nodes["Background"].inputs[1].default_value = .48
    scene.render.filepath = str(folder / f"{role.key}.png")
    bpy.ops.render.render(write_still=True)


destination = output_root() / "assets/ui/managers"
destination.mkdir(parents=True, exist_ok=True)
for number, director in enumerate(DIRECTORS + NEW_DIRECTORS):
    render(director, number, destination)
