"""Small original articles carried from the parcel van to the market."""
from kit import Model, bake_occlusion, clear_objects, export


def generate(root):
    clear_objects()
    box = Model()
    box.custom_box((.0, .08, .16), (.35, .30, .38), "c89256", .045, .023)
    box.box((.0, .234, .16), (.105, .023, .362), "ead1a6", .009)
    box.box((.0, .082, .357), (.101, .271, .016), "ead1a6", .005)
    box.box((-.092, .189, .361), (.082, .051, .008), "8b7461", .003)
    box.box((.0, -.075, .16), (.344, .019, .36), "9a6944", .007)
    baked = box.mesh("Parcel")
    bake_occlusion(baked, .18, .27)
    export(root / "assets/models/landscape/parcel_carton.glb")
