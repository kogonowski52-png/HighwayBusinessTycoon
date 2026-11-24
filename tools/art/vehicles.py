"""Distinct vehicle silhouettes, with suspension-independent wheel meshes."""
from dataclasses import dataclass
import json
from math import cos, pi, sin, sqrt, tau

from kit import Model, clear_objects, export

TRIM = "2b4148"
RUBBER = "253035"
CHROME = "becdca"
WINDOW = "335969"
HEAD = "fff0bf"
TAIL = "b33735"
AMBER = "e89b3a"
PAINT = "ffffff"


@dataclass(frozen=True)
class Vehicle:
    key: str
    name: str
    kind: str
    length: float
    half_width: float
    shoulder: float
    roof: float
    tire: float
    wheelbase: float
    cabin_front: float
    cabin_rear: float
    color: str
    alternate: str
    detail: str

    @property
    def axles(self):
        return [-self.wheelbase * 0.5, self.wheelbase * 0.5]


CATALOG = (
    Vehicle("sprint", "Sprint", "city", 3.10, .69, .69, 1.14, .298, 1.83, .81, -1.11, "ecae58", "d0846c", "round"),
    Vehicle("loop", "Loop", "city", 2.78, .65, .74, 1.35, .284, 1.71, .81, -1.03, "64b6a9", "eccf85", "visor"),
    Vehicle("meridian", "Meridian", "sedan", 3.77, .76, .70, 1.16, .312, 2.25, .87, -1.04, "438e9b", "7f7fad", "blade"),
    Vehicle("crest", "Crest", "sedan", 3.61, .77, .68, 1.10, .316, 2.13, .91, -1.21, "987d9e", "d09e57", "fastback"),
    Vehicle("trail", "Trail", "wagon", 3.91, .75, .75, 1.27, .329, 2.32, .92, -1.62, "d8c29a", "9abfc1", "rails"),
    Vehicle("coast", "Coast", "wagon", 3.66, .74, .77, 1.37, .321, 2.27, .99, -1.52, "bf6555", "789b77", "wood"),
    Vehicle("pine", "Pine", "suv", 3.72, .83, .96, 1.58, .373, 2.16, .93, -1.53, "81985b", "c8a569", "rack"),
    Vehicle("summit", "Summit", "suv", 3.46, .82, .99, 1.68, .414, 2.12, .80, -1.46, "ca7256", "64928b", "spare"),
    Vehicle("range", "Range", "pickup", 4.43, .88, .94, 1.63, .365, 2.55, 1.29, -.21, "ac5848", "cfac73", "short"),
    Vehicle("mesa", "Mesa", "pickup", 4.85, .86, .99, 1.67, .382, 2.81, 1.28, -.55, "8ca5a1", "c1aa72", "rack"),
    Vehicle("kestrel", "Kestrel", "sport", 3.62, .86, .61, .99, .291, 2.34, .79, -1.22, "e46142", "dbc45f", "scoop"),
    Vehicle("vela", "Vela", "sport", 3.85, .84, .59, 1.02, .297, 2.36, 1.04, -1.21, "39a494", "bd6a8a", "wing"),
    Vehicle("regency", "Regency", "luxury", 4.36, .82, .78, 1.25, .332, 2.61, 1.14, -1.37, "555e82", "99727a", "chrome"),
    Vehicle("orion", "Orion", "luxury", 4.14, .86, .94, 1.58, .363, 2.39, 1.04, -1.64, "d2d8ce", "82758e", "crown"),
    Vehicle("parcel", "Parcel", "van", 4.36, .88, .91, 1.96, .341, 2.52, 1.65, -1.86, "5594ab", "e4b75c", "delivery"),
    Vehicle("post", "Post", "van", 3.82, .80, .85, 1.75, .334, 2.38, 1.41, -1.61, "ecd7ae", "9caa7f", "shuttle"),
    Vehicle("atlas", "Atlas", "tractor", 4.70, .96, 1.04, 2.47, .432, 2.77, 1.79, .09, "be694d", "4f8992", "tower"),
    Vehicle("cargo", "Cargo", "trailer", 7.62, .99, 1.03, 2.47, .428, 1.96, 3.47, 2.00, "50897d", "a789ae", "liner"),
    Vehicle("horizon", "Horizon", "coach", 6.55, .93, 1.00, 2.22, .401, 4.14, 3.03, -2.92, "5a79a0", "ba835e", "coach"),
    Vehicle("pulse", "Pulse", "ev", 3.55, .77, .72, 1.28, .323, 2.37, 1.12, -1.29, "8ebcb6", "e1c9cc", "pixel"),
)

PASSENGERS = ["sprint", "loop", "meridian", "crest", "trail", "coast", "pine", "summit",
              "kestrel", "vela", "regency", "orion", "pulse", "post"]


def body(model, half_width, bottom, shoulder, length, axles, tire, kind, center=0.0):
    end = length * 0.5
    z_stops = {-end, -end * .97, -end * .88, -end * .64, -end * .25,
               end * .25, end * .52, end * .70, end * .88, end * .97, end}
    for axle in axles:
        for i in range(-4, 5):
            sample = axle + tire * i * .278
            if -end < sample < end:
                z_stops.add(sample)
    rings = []
    for z in sorted(z_stops):
        t = z / end
        edge = max(0, (abs(t) - .70) / .30)
        width = half_width * (1 - (.22 if kind == "sport" else .14) * edge ** 2)
        # The bottom side surface rises around each wheel, leaving proper cut-outs.
        lower = bottom
        for axle in axles:
            dx = (z - axle) / (tire * 1.17)
            if abs(dx) < 1:
                lower = max(lower, tire + tire * .84 * sqrt(1 - dx * dx))
        deck = shoulder - edge ** 2 * (.14 if kind in ("sport", "ev") else .085)
        if kind == "pickup" and z < -.36:
            deck -= .052
        lower = min(lower, deck - .089)
        rings.append((z + center, width, lower, deck))
    vertices = []
    for z, w, y, top in rings:
        belt = max(y + .034, top - .15)
        mid = max(y + .017, top - .235)
        vertices.extend([(-w * .79, y, z), (w * .79, y, z), (w * .966, y + .028, z),
                         (w, mid, z), (w * .988, belt, z), (w * .87, top - .016, z),
                         (w * .65, top, z), (-w * .65, top, z), (-w * .87, top - .016, z),
                         (-w * .988, belt, z), (-w, mid, z), (-w * .966, y + .028, z)])
    n = 12
    faces = [tuple(reversed(range(n)))]
    for k in range(len(rings) - 1):
        for i in range(n):
            j = (i + 1) % n
            faces.append((k*n + i, k*n + j, (k+1)*n + j, (k+1)*n + i))
    faces.append(tuple(range(len(vertices) - n, len(vertices))))
    model.add(vertices, faces, PAINT, "CoachPaint", [False] + [True] * (len(faces) - 2) + [False])


def cabin(model, car, front, rear, bottom_y, top_y, width, upright=False):
    def polygon(w, y, front, rear):
        return [(w * .79, y, front), (-w * .79, y, front), (-w, y, front - .12),
                (-w, y, rear + .11), (-w * .77, y, rear), (w * .77, y, rear),
                (w, y, rear + .11), (w, y, front - .12)]
    tilt = .23 if upright else .42
    rear_inset = .20 if car.kind in ("van", "wagon", "suv", "coach", "trailer", "tractor", "pickup") else .38
    upper_front = front - tilt
    upper_rear = rear + rear_inset
    lower = polygon(width, bottom_y, front, rear)
    upper = polygon(width * (.91 if upright else .82), top_y - .095, upper_front, upper_rear)
    vertices = lower + upper
    for i in range(8):
        j = (i + 1) % 8
        model.add(vertices, [(i, i + 8, j + 8, j)],
                  "447581" if i in (0, 1, 7) else WINDOW, "Tint", True)
    cap = polygon(width * (.87 if upright else .76), top_y, upper_front - .006, upper_rear + .021)
    cap_points = upper + cap
    cap_color = "d9d9c3" if car.detail in ("visor", "wood", "rack", "shuttle", "crown") else PAINT
    finish = "Paint" if cap_color != PAINT else "CoachPaint"
    model.add(cap_points, [(i, i + 8, (i + 1) % 8 + 8, (i + 1) % 8) for i in range(8)] +
              [tuple(reversed(range(8, 16)))], cap_color, finish, [True] * 8 + [False])
    # A and C pillars, frames, lower trim, roof rails and interior light glints.
    for side in [-1, 1]:
        leg = [width * .91 * side, width * .79 * side]
        model.pipe([(leg[0], bottom_y + .008, front - .081), (upper[0][0] * side, top_y - .094, upper_front)],
                   .025 if car.kind != "coach" else .041, PAINT, "CoachPaint", 7)
        model.pipe([(leg[0], bottom_y + .008, rear + .104), (upper[5][0] * side, top_y - .094, upper_rear)],
                   .029 if car.kind != "coach" else .05, PAINT, "CoachPaint", 7)
        panes = 5 if car.kind == "coach" else 3 if car.detail in ("shuttle", "rails", "wood", "crown") else 2
        for j in range(1, panes):
            t = j / panes
            p = front * (1 - t) + rear * t
            q = upper_front * (1 - t) + upper_rear * t
            model.pipe([(width * side, bottom_y + .015, p), (abs(upper[6][0]) * side, top_y - .09, q)],
                       .026 if car.kind != "coach" else .034, TRIM, "Rubber", 7)
        model.pipe([(side * width * .979, bottom_y + .032, rear + .093),
                    (side * width * 1.002, bottom_y + .033, front - .14)],
                   .019, CHROME if car.kind == "luxury" else TRIM, "Metal", 7)
        model.pipe([(side * width * .88, bottom_y + .144, front - .12),
                    (side * width * .72, top_y - .16, upper_front + .026)],
                   .008, "719ba1", "Tint", 6)
        face = bottom_y + (.24 if upright else .102)
        model.pipe([(side * width * .91, face, front - .10),
                    (side * (width + .118), face, front - .083)], .036, TRIM, "Rubber", 7)
        model.box((side * (width + .132), face + .025, front - .073),
                  (.20, .134, .131), PAINT, .048, "CoachPaint", yaw=side * .18)
        model.box((side * (width + .14), face + .026, front - .150),
                  (.128, .080, .019), "7ba6a9", .007, "Tint")


def wheels_for(car):
    if car.kind == "trailer":
        return [-3.03, -2.26, 1.34, 3.08]
    if car.kind == "tractor":
        return [-1.65, -0.93, 1.55]
    return car.axles


def create_car_model(car):
    base = Model()
    brake, left, right, head = Model(), Model(), Model(), Model()
    z = car.length * .50
    w = car.half_width
    axles = wheels_for(car)
    heavy = car.kind in ("coach", "tractor", "trailer")
    square = heavy or car.kind == "van"
    slab_bottom = car.tire * (.62 if car.kind in ("sport", "sedan", "city", "ev") else .87)
    if car.kind == "trailer":
        body(base, w * .96, slab_bottom, car.shoulder, 3.28, [a - 2.12 for a in axles if a > 0],
             car.tire, "tractor", 2.12)
    else:
        body(base, w, slab_bottom, car.shoulder, car.length, axles, car.tire, car.kind)

    if car.kind in ("tractor", "trailer"):
        # Cab below the windscreen, independent chassis and rear load over the bogie.
        base.box((0, 1.13, car.cabin_front - .51), (w * 1.89, .84, 1.36), PAINT, .22, "CoachPaint")
        base.box((0, 1.35, car.cabin_front - 1.02), (w * 1.80, 1.49, .638), PAINT, .16, "CoachPaint")
        base.box((0, car.roof - .38, car.cabin_front - .91), (w * 1.72, .59, .78), PAINT, .13, "CoachPaint")
        cabin(base, car, car.cabin_front, car.cabin_rear, 1.51, car.roof, w * .88, upright=True)
        for side in [-1, 1]:
            for i in range(2):
                base.box((side * .89, .59 + i * .137, car.cabin_front - .77), (.32, .075, .50), CHROME, .024, "Metal")
            base.pipe([(side * .79, .81, car.cabin_rear - .18),
                       (side * .79, 1.46, car.cabin_rear - .18),
                       (side * .79, 1.69, car.cabin_rear - .32)], .058, CHROME, "Metal", 10)
        if car.kind == "trailer":
            make_trailer(base, car)
        else:
            base.box((0, .68, -.90), (1.18, .23, 2.31), TRIM, .07, "Metal")
            base.pipe([(0, .806, -1.04), (0, .856, -1.04)], .48, TRIM, "Metal", 18)
            for side in [-1, 1]:
                base.box((side * .51, .69, -.75), (.48, .26, 1.68), CHROME, .09, "Metal")
    elif car.kind in ("van", "coach"):
        rear = car.cabin_rear
        front = car.cabin_front
        base.box((0, car.shoulder + .037, (front + rear) / 2),
                 (w * 1.86, .28, front - rear), PAINT, .115, "CoachPaint")
        cabin(base, car, front, rear, car.shoulder + (.21 if car.kind == "coach" else .034), car.roof, w*.94, True)
        if car.detail == "delivery":
            base.box((0, car.shoulder + .49, -.62), (w * 1.85, .91, 2.49), PAINT, .15, "CoachPaint")
            for side in [-1, 1]:
                base.box((side * w * .934, 1.36, -.62), (.041, .378, 1.76), "ddbf86", .02, "Paint")
                base.box((side * w * .957, 1.36, -.58), (.026, .09, 1.48), "f7e0ae", .013, "Light")
        else:
            for side in [-1, 1]:
                base.box((side * w * .965, car.shoulder + .012, -.35),
                         (.052, .155, car.length * .68), "e6b875", .024, "Paint")
            if car.kind == "coach":
                base.custom_box((0, car.roof + .039, -.89), (.91, .149, 1.08), CHROME, .13, .025, "Paint")
    else:
        cabin(base, car, car.cabin_front, car.cabin_rear, car.shoulder - .014, car.roof, w * .836)
        if car.kind == "pickup":
            pickup_bed(base, car)
        if car.kind in ("suv", "wagon") or car.detail == "rack":
            rails(base, car)
        if car.detail == "spare":
            base.pipe([(0, .858, -z + .024), (0, .858, -z - .24)], .342, RUBBER, "Rubber", 20)
            base.pipe([(0, .858, -z - .253), (0, .858, -z - .278)], .223, CHROME, "Metal", 20)
        if car.detail == "wood":
            for side in [-1, 1]:
                base.box((side * w * .982, car.shoulder - .14, -.15), (.06, .146, car.length * .67),
                         "b08052", .022, "Paint")
        if car.kind == "sport":
            for side in [-1, 1]:
                base.box((side * w * .80, .43, z * .832), (.157, .121, .37), RUBBER, .034, "Rubber")
                base.box((side * w * .77, car.shoulder + .013, z * .53), (.083, .026, .46), TRIM, .009, "Metal")
            if car.detail == "wing":
                for side in [-1, 1]:
                    base.box((side * .46, .754, -z * .86), (.09, .327, .15), TRIM, .024, "Metal")
                base.box((0, .903, -z * .865), (w * 1.69, .095, .29), PAINT, .043, "CoachPaint")

    if car.kind == "trailer":
        back_z = -z
        front_z = z - .09
    else:
        back_z = -z - .014
        front_z = z + .013
    bump_y = car.tire * 1.04
    base.custom_box((0, bump_y, front_z - .021), (w * 1.71, .172 if not heavy else .255, .263),
                    TRIM, .11, .048, "Rubber")
    base.custom_box((0, bump_y, back_z + .023), (w * 1.76, .139 if not heavy else .229, .227),
                    TRIM, .10, .043, "Rubber")
    base.box((0, bump_y + .025, back_z - .105), (.322, .092, .029), "eee3b3", .014, "Paint")
    base.box((0, bump_y + .023, front_z + .130), (.291, .081, .024), "dde5d1", .010, "Paint")
    lights_y = car.shoulder - (.156 if not square else .19)
    tail_y = max(.48, lights_y - .016)
    grille_y = lights_y if car.kind not in ("tractor", "trailer") else 1.21
    if car.kind != "ev":
        grille_width = w * (.91 if car.detail not in ("chrome", "tower", "liner") else 1.18)
        grille_height = .17 if not square else .29 if car.kind not in ("tractor", "trailer") else .58
        base.box((0, grille_y - .036, front_z + .006), (grille_width, grille_height, .133),
                 TRIM, .046, "Rubber")
        for j in range(5 if square else 3):
            base.box((0, grille_y - grille_height * .40 + j * grille_height / (6 if square else 4),
                      front_z + .076), (grille_width * .84, .021, .024), CHROME, .005, "Metal")
    for side in [-1, 1]:
        light_x = w * .62 * side
        light_width = w * (.29 if car.detail == "round" else .42)
        front = front_z - (.023 if car.detail == "round" else .056)
        if car.detail == "round":
            base.orb((light_x, lights_y, front), (.106, .107, .052), TRIM, 12, 7, "Rubber")
            head.orb((light_x, lights_y + .004, front + .028), (.088, .089, .043), HEAD, 12, 7)
        else:
            light_height = .096 if car.detail in ("blade", "fastback", "scoop", "wing", "pixel") else .152
            base.box((light_x, lights_y, front), (light_width + .067, light_height + .055, .135),
                     TRIM, .025, "Rubber", side * .26)
            head.box((light_x, lights_y + .009, front + .064),
                     (light_width, light_height, .071), HEAD, .027, "Ceramic", side * .26)
        target = left if side == 1 else right
        target.box((w * .821 * side, lights_y - .090, front + .015), (.094, .054, .097), AMBER, .019,
                   "Ceramic", side * .26)
        target.box((w * .813 * side, tail_y - .073, back_z + .034), (.077, .058, .094), AMBER, .018,
                   "Ceramic", -side * .14)
        base.box((w * .657 * side, tail_y, back_z + .042), (w * .40, .149, .119), TRIM, .033, "Rubber")
        brake.box((w * .657 * side, tail_y + .006, back_z - .012),
                  (w * .344, .093 if car.detail != "spare" else .149, .081), TAIL, .024, "Ceramic")
        for j in range(2 if car.kind not in ("van", "coach", "tractor", "trailer") else 1):
            door_z = car.cabin_front - .45 - j * .59
            base.box((w * .975 * side, car.shoulder - .090, door_z), (.031, .041, .141),
                     CHROME if car.kind == "luxury" else TRIM, .011, "Metal")
    if car.detail == "pixel":
        head.box((0, lights_y + .021, front_z + .030), (w * 1.36, .037, .053),
                 "d2fff1", .012, "Ceramic")
        brake.box((0, tail_y + .008, back_z - .015), (w * 1.33, .028, .027), TAIL, .007)
    base.mesh("Chassis")
    brake.mesh("BrakeLamps")
    left.mesh("IndicatorLeft")
    right.mesh("IndicatorRight")
    head.mesh("Headlamps")


def rails(model, car):
    for side in [-1, 1]:
        x = side * car.half_width * .61
        z1 = car.cabin_rear + .36
        z2 = car.cabin_front - .51
        model.pipe([(x, car.roof - .006, z1), (x, car.roof + .095, z1 + .05),
                    (x, car.roof + .095, z2 - .05), (x, car.roof - .006, z2)],
                   .027, CHROME if car.kind == "wagon" else TRIM, "Metal", 8)
    if car.detail == "rack" and car.kind != "pickup":
        for z in [-.81, -.49, -.17, .15]:
            model.box((0, car.roof + .105, z), (1.12, .057, .071), TRIM, .015, "Metal")


def pickup_bed(model, car):
    z0 = -car.length / 2 + .15
    z1 = car.cabin_rear - .10
    mid = (z0 + z1) / 2
    length = z1 - z0
    for side in [-1, 1]:
        model.box((side * car.half_width * .90, car.shoulder + .093, mid),
                  (.146, .19, length), PAINT, .063, "CoachPaint")
        model.box((side * car.half_width * .78, car.shoulder + .069, mid),
                  (.039, .11, length * .94), TRIM, .015, "Rubber")
    model.box((0, car.shoulder + .093, z0 + .04), (car.half_width * 1.71, .19, .155),
              PAINT, .056, "CoachPaint")
    model.box((0, car.shoulder + .013, mid), (car.half_width * 1.56, .051, length * .91),
              TRIM, .025, "Rubber")
    for i in range(7):
        model.box(((i - 3) * .17, car.shoulder + .041, mid),
                  (.025, .023, length * .86), "556465", .007, "Metal")


def make_trailer(model, car):
    w = car.half_width
    model.box((0, .61, -1.36), (w * 1.77, .231, 4.58), TRIM, .064, "Metal")
    model.custom_box((0, 1.57, -1.45), (w * 1.90, 1.65, 4.57),
                     "c2cfbb", .20, .087, "Paint")
    model.custom_box((0, 2.41, -1.45), (w * 1.85, .139, 4.52),
                     "dee0c2", .19, .047, "Paint")
    for side in [-1, 1]:
        model.box((side * w * .940, 1.63, -1.48), (.061, .322, 4.19), PAINT, .029, "CoachPaint")
        model.box((side * w * .972, 1.616, -1.48), (.041, .086, 4.10), "dab776", .016, "Paint")
        for j in range(7):
            model.box((side * w * .964, 1.665, -.13 - .47 * j), (.045, 1.31, .040), CHROME, .012, "Metal")
        model.box((side * .40, 1.57, -3.75), (.72, 1.48, .065), "a3b4a6", .042, "Paint")
        model.pipe([(side * .49, 1.00, -3.795), (side * .49, 2.19, -3.795)], .022, TRIM, "Metal", 8)
    model.box((0, 0.83, -1.36), (w * 1.79, .105, .40), CHROME, .03, "Metal")


def wheel(style):
    model = Model()
    spokes = {"street": 6, "utility": 5, "heavy": 8}[style]
    width = {"street": .35, "utility": .43, "heavy": .45}[style]
    side_positions = [-width, -width * .93, -width * .76, -width * .53,
                      width * .53, width * .76, width * .93, width]
    radii = [.71, .88, .977, 1, 1, .977, .88, .71]
    model.pipe([(x, 0, 0) for x in side_positions], radii, RUBBER, "Rubber", 24)
    for side in [-1, 1]:
        face = width * side
        model.pipe([(face * .93, 0, 0), (face * 1.08, 0, 0)], [.707, .667], CHROME, "Metal", 22)
        model.pipe([(face * 1.077, 0, 0), (face * 1.107, 0, 0)], .574, TRIM, "Metal", 22)
        model.pipe([(face * 1.11, 0, 0), (face * 1.24, 0, 0)], [.23, .195], CHROME, "Metal", 12)
        for i in range(spokes):
            angle = i * tau / spokes
            model.pipe([(face * 1.126, cos(angle) * .23, sin(angle) * .23),
                        (face * 1.103, cos(angle + .12) * .58, sin(angle + .12) * .58)],
                       .069 if style == "heavy" else .078, CHROME, "Metal", 7)
    model.mesh("Wheel")


def generate(root):
    folder = root / "assets/models/vehicles"
    records = []
    for car in CATALOG:
        clear_objects()
        create_car_model(car)
        export(folder / (car.key + ".glb"))
        heavy = car.kind in ("trailer", "tractor", "coach")
        tire = "heavy" if heavy else "utility" if car.kind in ("suv", "pickup", "van") else "street"
        records.append({
            "id": car.key, "name": car.name, "category": car.kind, "length": car.length,
            "width": round(car.half_width * 2, 3), "radius": car.tire, "wheel": tire,
            "wheel_x": round(car.half_width * (.82 if heavy else .87), 3),
            "axles": [round(axle, 3) for axle in wheels_for(car)],
            "paint": [car.color, car.alternate], "head_z": round(car.length * .50, 3),
        })
    for style in ("street", "utility", "heavy"):
        clear_objects()
        wheel(style)
        export(folder / ("wheel_" + style + ".glb"))
    catalog = root / "data/visual/vehicle_catalog.gd"
    with catalog.open("w", encoding="utf-8") as destination:
        destination.write('extends RefCounted\n\n# Generated by tools/art/vehicles.py. Geometry and axle dimensions share one source.\nconst VEHICLES := {\n')
        for record in records:
            destination.write(f'\t"{record["id"]}": {json.dumps(record, ensure_ascii=False)},\n')
        destination.write('}\n\nconst CUSTOMERS := ' + json.dumps(PASSENGERS) + '\n')
