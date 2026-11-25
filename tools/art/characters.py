"""Eight original uniforms and a shared low-cost articulated skeleton."""
from dataclasses import dataclass

import bpy
from kit import Model, bake_occlusion, clear_objects, export, orientation


@dataclass(frozen=True)
class Outfit:
    key: str
    skin: str
    hair: str
    top: str
    inset: str
    pants: str
    hat: str = ""
    apron: str = ""
    reflective: bool = False


ROLES = [
    Outfit("customer", "de9c74", "694632", "e1b76f", "f2d9a4", "647b56"),
    Outfit("driver", "b87956", "493d2f", "c66d47", "efd096", "36556a", "354d50"),
    Outfit("cashier", "b47857", "47332a", "6ea99a", "d2e0be", "4c6259", apron="346e64"),
    Outfit("mechanic", "d09975", "69442d", "446b74", "e6bb68", "344b54", "305260", reflective=True),
    Outfit("attendant", "7f503b", "343034", "327c6d", "ead18c", "374f56", "dfac65", reflective=True),
    Outfit("wash_worker", "ddb194", "78543b", "739fa9", "e2cfab", "354f58", "e7bb7b", apron="3a7f82"),
    Outfit("server", "a16950", "4b362c", "f1e0ba", "8a5440", "526860", apron="b7644c"),
    Outfit("manager", "deab88", "716054", "746b83", "f2deb1", "465363"),
]


DIRECTORS = [
    Outfit("ada", "c89974", "804e39", "517b92", "f3d29c", "4c5d71"),
    Outfit("iga", "945f48", "453735", "ab605b", "f7d7a7", "704d59", hat="b96860"),
    Outfit("maks", "c58b65", "373c3a", "677c59", "d8deb4", "374f52"),
    Outfit("mira", "daa780", "563b36", "a88745", "f4d1a8", "626067", hat="a17a57"),
    Outfit("leon", "aa7359", "564945", "715b80", "e7ccaf", "445766"),
]

SUPPORT = {
    "pelvis": ((0, .968, 0), None),
    "spine": ((0, 1.055, 0), "pelvis"),
    "head": ((0, 1.55, .01), "spine"),
}
for suffix, side in (("l", 1), ("r", -1)):
    SUPPORT.update({
        f"arm_{suffix}": ((side * .252, 1.39, .00), "spine"),
        f"elbow_{suffix}": ((side * .309, 1.179, .015), f"arm_{suffix}"),
        f"hand_{suffix}": ((side * .321, .989, .045), f"elbow_{suffix}"),
        f"leg_{suffix}": ((side * .133, .965, 0), "pelvis"),
        f"knee_{suffix}": ((side * .145, .523, .030), f"leg_{suffix}"),
        f"foot_{suffix}": ((side * .153, .169, .006), f"knee_{suffix}"),
    })


def create_rig():
    armature = bpy.data.armatures.new("Biped")
    rig = bpy.data.objects.new("Biped", armature)
    bpy.context.collection.objects.link(rig)
    bpy.context.view_layer.objects.active = rig
    rig.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    for name, (pivot, parent) in SUPPORT.items():
        bone = armature.edit_bones.new(name)
        bone.head = orientation(pivot)
        bone.tail = orientation((pivot[0], pivot[1] + .12, pivot[2]))
        if parent:
            bone.parent = armature.edit_bones[parent]
    bpy.ops.object.mode_set(mode="OBJECT")
    return rig


def actor(role):
    model = Model()
    shirt, lining = role.top, role.inset
    skin, hair = role.skin, role.hair
    pants = role.pants
    shoes, eye, whites = "293f43", "293434", "efe1c7"

    model.orb((0, .998, 0), (.222, .154, .119), pants, 13, 8, bone="pelvis")
    model.box((0, 1.012, .006), (.408, .091, .23), shoes, .045, "Rubber", bone="pelvis")
    model.orb((0, 1.264, .005), (.264, .275, .153), shirt, 16, 10, bone="spine", irregular=.036)
    model.orb((0, 1.397, -.014), (.249, .131, .147), shirt, 12, 8, bone="spine")
    model.orb((0, 1.481, .015), (.096, .101, .093), skin, 12, 8, bone="head")
    for side in [-1, 1]:
        model.box((side * .093, 1.458, .103), (.111, .085, .084), lining, .032, "Paint",
                  yaw=side * -.20, bone="spine")
    model.box((.001, 1.260, .163), (.020, .304, .021), lining, .009, bone="spine")
    model.box((.119, 1.341, .163), (.088, .058, .030), lining, .016, "Paint", bone="spine")
    for i in range(3):
        model.orb((.001, 1.18 + i * .083, .178), (.012, .012, .009), shoes, 8, 5, bone="spine")
    if role.apron:
        model.custom_box((0, 1.19, .142), (.333, .42, .075), role.apron, .037, .022)
        model.parts[-1].bone = "spine"
        model.box((0, 1.083, .186), (.183, .122, .028), role.apron, .014, "Paint", bone="spine")
        model.box((0, 1.128, .205), (.171, .018, .019), lining, .008, bone="spine")
        for side in [-1, 1]:
            model.pipe([(side * .122, 1.357, .182), (side * .115, 1.462, .033),
                        (side * .122, 1.388, -.103)], .021, role.apron, bone="spine", sides=7)
    if role.key == "manager" or role in DIRECTORS:
        for side in [-1, 1]:
            model.pipe([(side * .076, 1.461, .126), (side * .099, 1.368, .173),
                        (side * .056, 1.267, .177)], .027, lining, bone="spine", sides=8)
    if role.reflective:
        for side in [-1, 1]:
            model.box((side * .151, 1.277, .141), (.050, .329, .034), lining, .009,
                      "Paint", yaw=side * .2, bone="spine")

    if role.key in ("customer", "driver"):
        # A rounded day pack with a separate gusset and the straps over the shoulders.
        model.custom_box((-.042, 1.29, -.192), (.325, .362, .168), "546c64" if role.key == "driver" else "ba8150", .125, .047)
        model.parts[-1].bone = "spine"
        model.box((-.045, 1.19, -.282), (.24, .168, .058), "849682" if role.key == "driver" else "d5a564", .061, bone="spine")
        for side in [-1, 1]:
            model.pipe([(side * .155, 1.100, -.099), (side * .195, 1.33, .144),
                        (side * .173, 1.474, .017), (side * .139, 1.426, -.222)],
                       .027, "4a6359", "Rubber", sides=8, bone="spine")
    if role.key in ("mechanic", "attendant", "wash_worker"):
        model.box((.183, 1.042, .173), (.14, .152, .108), "5b655a", .025, "Rubber", bone="pelvis")
        model.box((.183, 1.115, .204), (.125, .047, .049), lining, .014, bone="pelvis")
        model.box((-.13, 1.27, .185), (.13, .108, .065), shirt, .018, bone="spine")
        model.box((-.13, 1.301, .221), (.114, .031, .023), lining, .009, "Paint", bone="spine")

    model.orb((0, 1.689, .023), (.199, .218, .165), skin, 18, 13,
              bone="head", irregular=.028)
    model.orb((0, 1.608, .083), (.139, .095, .102), skin, 13, 8, bone="head")
    model.orb((0, 1.689, .178), (.053, .047, .058), skin, 12, 8, bone="head")
    model.pipe([(-.054, 1.616, .176), (-.026, 1.607, .189), (.023, 1.606, .190), (.058, 1.621, .172)],
               .011, "845047" if role.skin != "7f503b" else "603f31", bone="head", sides=7)
    for side in [-1, 1]:
        model.orb((side * .185, 1.667, .022), (.047, .070, .047), skin, 11, 7, bone="head")
        model.orb((side * .208, 1.666, .053), (.021, .031, .017), "9d6451", 9, 6, bone="head")
        model.orb((side * .081, 1.723, .165), (.049, .032, .025), whites, 11, 7, bone="head")
        model.orb((side * .076, 1.722, .186), (.024, .027, .013), eye, 10, 7, "Paint", bone="head")
        model.orb((side * .074 + .007, 1.732, .197), (.008, .008, .005), whites, 8, 5, bone="head")
        model.pipe([(side * .044, 1.737, .187), (side * .081, 1.751, .187),
                    (side * .120, 1.737, .176)], .007, hair, bone="head", sides=6)
        model.pipe([(side * .039, 1.772, .170), (side * .084, 1.782, .166),
                    (side * .127, 1.768, .146)], .011, hair, bone="head", sides=7)
    model.orb((-.006, 1.736, -.048), (.198, .129 if role.hat else .195, .149), hair,
              17, 11, bone="head", irregular=.045)
    if not role.hat:
        model.orb((0, 1.848, .034), (.179, .100, .130), hair, 16, 9, bone="head", irregular=.07)
        for x, y, width, angle in [(-.078, 1.828, .122, .52), (.068, 1.850, .092, -.34)]:
            model.orb((x, y, .075), (width, .090, .112), hair, 13, 8,
                      bone="head", yaw=angle, irregular=.075)
    if role.key in ("customer", "cashier", "server", "ada", "iga"):
        model.orb((.123, 1.708, -.103), (.117, .149, .129), hair, 13, 9, bone="head", irregular=.12)
        model.orb((.144, 1.580, -.121), (.077, .083, .078), hair, 12, 8, bone="head")
    if role.hat:
        model.orb((0, 1.851, -.011), (.222, .126, .187), role.hat, 17, 10, bone="head")
        if role.key == "wash_worker":
            model.orb((0, 1.952, -.024), (.059, .057, .056), lining, 12, 7, bone="head")
            model.orb((0, 1.825, -.008), (.225, .043, .184), lining, 17, 8, bone="head")
        else:
            model.orb((0, 1.821, .162), (.176, .021, .112), role.hat, 15, 8, bone="head")
            model.box((0, 1.882, .177), (.089, .051, .018), lining, .010, "Paint", bone="head")
    if role.key in ("manager", "ada", "maks", "leon"):
        for side in [-1, 1]:
            x = side * .084
            rim = [(x + dx, 1.729 + dy, .204) for dx, dy in [(-.056, -.026), (.056, -.026),
                    (.064, .013), (.049, .032), (-.049, .032), (-.064, .013), (-.056, -.026)]]
            model.pipe(rim, .009, hair, sides=7, bone="head")
            model.pipe([(x + side * .057, 1.740, .199), (side * .201, 1.748, .056)],
                       .009, hair, sides=7, bone="head")
        model.box((0, 1.728, .195), (.059, .019, .026), hair, .005, "Metal", bone="head")
    if role.key == "mechanic":
        model.orb((0, 1.58, .089), (.134, .066, .101), hair, 13, 8, bone="head")

    for suffix, side in (("l", 1), ("r", -1)):
        arm, elbow, hand = (f"{part}_{suffix}" for part in ("arm", "elbow", "hand"))
        leg, knee, foot = (f"{part}_{suffix}" for part in ("leg", "knee", "foot"))
        model.orb((side * .258, 1.382, .001), (.101, .108, .102), shirt, 12, 8, bone=arm)
        model.pipe([(side * .254, 1.385, 0), (side * .285, 1.285, .013),
                    (side * .309, 1.189, .02)], [.095, .082, .072], shirt, bone=arm, sides=11)
        model.orb((side * .310, 1.180, .015), (.074, .076, .071), shirt, 12, 8, bone=elbow)
        cover = shirt if role.key in ("driver", "mechanic", "wash_worker", "manager") else skin
        model.pipe([(side * .310, 1.181, .017), (side * .319, 1.115, .032),
                    (side * .321, 1.008, .047)], [.070, .062, .049], cover, bone=elbow, sides=11)
        if cover == shirt:
            model.pipe([(side * .320, 1.041, .041), (side * .322, 1.014, .044)],
                       .056, lining, sides=10, bone=elbow)
        hand_color = "405951" if role.key in ("mechanic", "wash_worker") else skin
        model.orb((side * .325, .976, .064), (.060, .080, .052), hand_color, 12, 8, bone=hand)
        model.orb((side * .287, .990, .101), (.031, .043, .026), hand_color, 10, 7, bone=hand)
        model.pipe([(side * .134, .946, 0), (side * .143, .73, .026),
                    (side * .145, .528, .030)], [.111, .089, .073], pants, bone=leg, sides=13)
        model.orb((side * .146, .52, .029), (.076, .093, .074), pants, 12, 8, bone=knee)
        model.pipe([(side * .145, .53, .029), (side * .154, .353, .008),
                    (side * .152, .161, .007)], [.073, .078, .055], pants, bone=knee, sides=12)
        if role.reflective:
            model.pipe([(side * .151, .312, .008), (side * .152, .358, .011)],
                       .079, lining, bone=knee, sides=12)
        model.box((side * .153, .120, .076), (.193, .194, .289), shoes, .075, "Rubber", bone=foot)
        model.box((side * .153, .042, .075), (.202, .075, .302), "c0ae90", .031, "Rubber", bone=foot)
        model.box((side * .153, .146, .186), (.129, .084, .109), shirt, .034, "Paint", bone=foot)
    # Enlarge the face and cap around the existing head pivot, so clips and props remain compatible.
    for part in model.parts:
        if part.bone == "head":
            part.vertices = [(x * 1.14, 1.58 + (y - 1.58) * 1.10, .021 + (z - .021) * 1.10)
                             for x, y, z in part.vertices]
    bake_occlusion(model.mesh("Uniform", create_rig()), .22, .28)


def tools_model():
    nozzle = Model()
    nozzle.box((0, .0, .074), (.111, .161, .194), "367f67", .041, "Paint")
    nozzle.box((.0, -.073, .086), (.078, .093, .121), "29464a", .021, "Rubber")
    nozzle.pipe([(0, .037, .16), (0, .052, .223), (.008, .041, .297)], .024, "9ca49e", "Metal", 9)
    nozzle.pipe([(0, -.034, -.026), (0, -.045, -.094)], .033, "253d3d", "Rubber", 9)
    nozzle.mesh("Nozzle")

    mop = Model()
    mop.pipe([(0, -.83, .04), (0, .22, .04)], .026, "8fa5a0", "Metal")
    mop.box((0, -.79, .05), (.25, .067, .152), "477b77", .026, "Paint")
    mop.box((0, -.836, .049), (.284, .062, .173), "cbd0ae", .019, "Rubber")
    mop.mesh("Mop")

    spanner = Model()
    spanner.box((0, 0, .104), (.099, .053, .265), "99aba8", .021, "Metal")
    spanner.pipe([(-.045, 0, .188), (-.095, 0, .230), (-.080, 0, .286)],
                 .031, "a6b4ad", "Metal", 8)
    spanner.pipe([(.045, 0, .188), (.095, 0, .230), (.080, 0, .286)],
                 .031, "a6b4ad", "Metal", 8)
    spanner.mesh("Spanner")

    tray = Model()
    tray.pipe([(0, .044, .038), (0, .091, .038)], [.22, .24], "6d5444", "Metal", 16)
    tray.pipe([(-.091, .090, .038), (-.091, .245, .038)], [.061, .085], "e9d5ae", sides=13)
    tray.pipe([(-.091, .237, .038), (-.091, .262, .038)], .088, "ca8051", "Paint", 13)
    tray.box((.086, .111, .034), (.13, .051, .17), "e5ac60", .019)
    tray.mesh("Tray")

    board = Model()
    board.box((0, .027, .12), (.195, .047, .30), "ae7450", .030)
    board.box((0, .058, .12), (.157, .016, .252), "eee1c2", .012)
    board.box((0, .075, .219), (.084, .024, .034), "739194", .007, "Metal")
    board.mesh("Clipboard")


def generate(root):
    folder = root / "assets/models/characters"
    for role in ROLES:
        clear_objects()
        actor(role)
        export(folder / f"{role.key}.glb")
    clear_objects()
    tools_model()
    export(folder / "hand_props.glb")

def generate_directors(root):
    folder = root / "assets/models/characters"
    for role in DIRECTORS:
        clear_objects()
        actor(role)
        export(folder / f"{role.key}.glb")
