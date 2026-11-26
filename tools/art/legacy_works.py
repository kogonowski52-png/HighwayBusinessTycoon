"""Regenerate the structural additions on all six legacy maps with Blender."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from kit import bake_occlusion, clear_objects, export, output_root
from venue_works import KINDS, annex, roof_work
from regional_atlas import BUILDERS, expansion, write


def write_model(family, name, model):
    from kit import Model

    clear_objects()
    glass = Model()
    glass.parts = [part for part in model.parts if part.finish == "Glass"]
    model.parts = [part for part in model.parts if part.finish != "Glass"]
    part = model.mesh(name.title().replace("_", ""))
    bake_occlusion(part, .56)
    if glass.parts:
        glass.mesh("Glazing")
    export(output_root() / "assets/models" / family / (name + ".glb"))


NORTH = {
    "motel": ("eed2a5","487e7a","d58d55",2.33),
    "parking": ("dfd3ab","47756d","edad66",2.08),
    "truck": ("ded0aa","426e77","d39a59",2.80),
    "tires": ("d5c9a9","537281","d37753",2.09),
    "charge": ("eee5ca","508485","71bfad",1.93),
    "truck_park": ("e4ceb3","496f81","d3985f",2.63),
}

DESERT = {
    "fuel": ("e1c39e","a06048","e9b65d"), "cafe": ("ecd6ad","a36753","dda35c"),
    "restrooms": ("dacfb1","58887c","e9bc72"), "vip_park": ("dbc5a7","598984","e4a965"),
    "truck": ("d7c6a4","687c73","e4b263"), "showers": ("dbc19d","8f6359","cfa36c"),
    "motel": ("e5c597","9a6056","e3a95d"), "truck_park": ("d6b88d","776555","e1b470"),
    "drive_through": ("e7cea2","aa624d","e6bb6d"), "charge": ("e6d1a8","557b7a","81c5a3"),
}


def generate():
    from kit import Model

    for service, (wall, trim, accent, width) in NORTH.items():
        for stage in range(2,6):
            write_model("architecture",f"annex_{service}_{stage}",
                        annex(KINDS[service],stage-1,0,0,wall,trim,accent,width))
    for service, (wall, trim, accent) in DESERT.items():
        for stage in range(1,5):
            if stage < 3:
                model = annex(KINDS[service],stage,0,0,wall,trim,accent,2.19)
            else:
                model = Model()
                roof_work(model,KINDS[service],stage,0,0,0,trim,accent)
            write_model("desert", f"{service}_works_{stage}", model)
    for region, businesses in BUILDERS.items():
        for service in ["fuel", *businesses]:
            for stage in range(1,5):
                write(region,f"{service}_{stage}",expansion(region,service,stage))


if __name__ == "__main__":
    generate()
