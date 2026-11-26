"""Distinct vehicle silhouettes, with suspension-independent wheel meshes."""
from dataclasses import dataclass, replace
import json
from math import cos, pi, sin, sqrt, tau

from kit import Model, bake_occlusion, clear_objects, export

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
    Vehicle("cove", "Cove", "city", 2.94, .68, .76, 1.22, .305, 1.80, .75, -1.06, "e3a159", "68a491", "moon"),
    Vehicle("sable", "Sable", "sedan", 4.03, .79, .74, 1.11, .322, 2.39, .70, -1.37, "725c8c", "bf644e", "duotone"),
    Vehicle("brook", "Brook", "wagon", 4.04, .78, .81, 1.44, .354, 2.48, .86, -1.68, "637f60", "cc9a66", "utility"),
    Vehicle("ridgeback", "Ridgeback", "suv", 4.20, .88, 1.07, 1.78, .433, 2.56, 1.09, -1.55, "c68844", "6c8d9f", "expedition"),
    Vehicle("courier", "Courier", "van", 4.16, .83, .97, 1.94, .349, 2.45, 1.53, -1.82, "5b9b82", "d98861", "reefer"),
    Vehicle("sundown", "Sundown", "van", 5.04, .91, .98, 2.12, .355, 2.97, 1.96, -2.14, "c87a59", "698d9b", "camper"),
    Vehicle("arrow", "Arrow", "sport", 3.96, .89, .59, .93, .297, 2.48, .48, -1.10, "d36147", "75a7a4", "blade"),
    Vehicle("solstice", "Solstice", "ev", 4.12, .78, .73, 1.21, .341, 2.64, 1.35, -1.54, "465e83", "65b4a5", "pixel"),
    Vehicle("switchback", "Switchback", "coach", 5.46, .88, 1.07, 2.15, .382, 3.42, 2.44, -2.39, "ce7a48", "5d91a1", "shuttle"),
    Vehicle("petrel", "Petrel", "trailer", 7.66, .99, 1.07, 2.43, .431, 1.96, 3.48, 2.07, "dc9d54", "509888", "tanker"),
)

FRONTIER = (
    Vehicle("sunray","Sunray","sport",3.88,.83,.61,.97,.299,2.39,.90,-1.31,"e69467","58c0ac","convertible"),
    Vehicle("reefvan","Reefliner","coach",5.72,.91,1.04,2.19,.39,3.47,2.64,-2.58,"499f9e","f1b869","tourcoach"),
    Vehicle("dune_buggy","Dunehopper","suv",3.61,.90,1.02,1.77,.414,2.18,.66,-1.42,"e0ad64","719a63","buggy"),
    Vehicle("oxbow","Oxbow","pickup",4.52,.86,.88,1.53,.375,2.60,1.25,-.38,"a95248","a7b898","tailgate"),
    Vehicle("velvet","Velvet","luxury",5.13,.83,.77,1.21,.342,2.87,1.04,-1.16,"af596a","448d8f","fins"),
    Vehicle("roamer","Roamer","van",5.21,.88,.91,2.15,.355,2.97,1.92,-2.05,"d99d62","77998d","poproof"),
    Vehicle("container","Boxmaster","trailer",7.94,1.0,1.07,2.53,.442,2.18,3.63,2.13,"be7b4f","628789","container"),
    Vehicle("cooler","Coldbox","trailer",8.14,1.0,1.11,2.61,.43,2.23,3.66,2.02,"9cb4b9","5c8793","reefer_truck"),
    Vehicle("forklift","Dock Shunter","tractor",4.34,.89,1.09,2.17,.414,2.61,1.62,-.09,"d4a757","709997","shunter"),
    Vehicle("onyx","Onyx","sport",4.23,.92,.52,.87,.296,2.51,.84,-1.05,"8b5e9c","b65157","superwing"),
    Vehicle("lumen","Lumen","luxury",5.42,.90,.72,1.23,.342,3.31,1.44,-1.79,"69798f","e4d7b9","limousine"),
    Vehicle("sovereign","Sovereign","suv",4.70,.91,1.03,1.76,.399,2.90,1.21,-1.69,"d0ba9e","67758f","panoramic"),
    Vehicle("akari","Akari GT","sport",4.08,.85,.64,1.05,.302,2.46,.93,-1.33,"55aabc","ce7c78","track"),
    Vehicle("bento","Bento","city",2.77,.61,.74,1.39,.278,1.62,.87,-1.12,"edb97b","95b69f","kei"),
    Vehicle("ion","Ion","ev",4.45,.83,.72,1.31,.35,2.82,1.44,-1.56,"8dbbaa","8a77ab","pixel"),
    Vehicle("timber","Timber Haul","trailer",8.22,1.00,1.12,2.58,.446,2.29,3.72,2.07,"7a8858","b48258","logs"),
    Vehicle("boreal","Boreal Scout","suv",4.07,.89,1.08,1.79,.434,2.57,1.10,-1.58,"9b845c","738d92","snowkit"),
    Vehicle("tandem","Tandem Rescue","pickup",4.98,.91,1.03,1.74,.398,2.94,1.44,-.37,"d79f61","7a9a89","rescue"),
)


PASSENGERS = ["sprint", "loop", "meridian", "crest", "trail", "coast", "pine", "summit",
              "kestrel", "vela", "regency", "orion", "pulse", "post", "cove",
              "sable", "brook", "ridgeback", "courier", "sundown", "arrow", "solstice"]


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
                         (w * .65, top, z), (w * .38, top + .038, z), (0, top + .051, z),
                         (-w * .38, top + .038, z), (-w * .65, top, z), (-w * .87, top - .016, z),
                         (-w * .988, belt, z), (-w, mid, z), (-w * .966, y + .028, z)])
    n = 15
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
    for i in range(8):
        j = (i + 1) % 8
        # A broad sky reflection stays legible on the silhouette in the overhead view.
        horizon = "95bcca" if i in (0, 1, 7) else "709aa4"
        if i == 0:
            glass = []
            for k in range(7):
                t = k / 6
                arc = .064 * sin(t * pi)
                glass.extend([(lower[i][0] * (1-t) + lower[j][0] * t, bottom_y, front + arc),
                              (upper[i][0] * (1-t) + upper[j][0] * t, top_y - .095, upper_front + arc * .80)])
            model.add(glass, [(k, k + 1, k + 3, k + 2) for k in range(0, 12, 2)], WINDOW,
                      "Tint", True, vertex_colors=[WINDOW, horizon] * 7)
            for side in [-1, 1]:
                model.pipe([(side * width * .20, bottom_y + .041, front + .063),
                            (side * width * .38, bottom_y + .111, front - .026)],
                           .012, TRIM, "Rubber", 6)
            if car.kind in ("coach", "tractor", "trailer"):
                model.pipe([(0, bottom_y + .015, front + .069), (0, top_y - .09, upper_front + .052)],
                           .024, PAINT, "CoachPaint", 7)
            continue
        model.add([lower[i], upper[i], upper[j], lower[j]], [(0, 1, 2, 3)],
                  WINDOW, "Tint", True, vertex_colors=[WINDOW, horizon, horizon, WINDOW])
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
        if car.kind in ("sedan", "wagon", "city", "ev", "luxury", "suv"):
            x = side * car.half_width * .978
            model.pipe([(x, bottom_y - .198, rear + .28), (x * 1.016, bottom_y - .165, .0),
                        (x, bottom_y - .159, front - .37)], .015,
                       CHROME if car.kind == "luxury" else TRIM, "Metal", 6)


def wheels_for(car):
    if car.kind == "trailer":
        return [-3.03, -2.26, 1.34, 3.08]
    if car.kind == "tractor":
        return [-1.65, -0.93, 1.55]
    return car.axles


def create_car_model(car):
    # Visual height only. Wheelbase, road clearance and visit dimensions use the catalog record.
    rise = .21 if car.kind in ("city", "van", "tractor", "trailer") else .13
    car = replace(car, roof=car.roof + rise)
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

    guards = TRIM if car.kind in ("suv", "pickup", "tractor", "trailer") else PAINT
    finish = "Rubber" if guards == TRIM else "CoachPaint"
    for axle in axles:
        for side in [-1, 1]:
            x = w * .952 * side
            points = [(x * (0.95 + 0.092 * sin(j * pi / 12)),
                       car.tire + car.tire * 1.04 * sin(j * pi / 12),
                       axle + car.tire * 1.20 * cos(j * pi / 12)) for j in range(13)]
            base.pipe(points, .036 if not heavy else .059, guards, finish, 8)

    if car.kind in ("tractor", "trailer"):
        # Cab below the windscreen, independent chassis and rear load over the bogie.
        base.box((0, 1.13, car.cabin_front - .51), (w * 1.89, .84, 1.36), PAINT, .22, "CoachPaint")
        base.box((0, 1.35, car.cabin_front - 1.02), (w * 1.80, 1.49, .638), PAINT, .16, "CoachPaint")
        base.box((0, car.roof - .38, car.cabin_front - .91), (w * 1.72, .59, .78), PAINT, .13, "CoachPaint")
        cabin(base, car, car.cabin_front, car.cabin_rear, 1.51, car.roof, w * .88, upright=True)
        visor_z = car.cabin_front - .31
        base.custom_box((0, car.roof - .105, visor_z), (w * 1.81, .114, .491), PAINT, .17, .036, "CoachPaint")
        for x in [-.63, -.31, .31, .63]:
            base.box((x, car.roof - .121, visor_z + .251), (.133, .051, .034), AMBER, .019, "Tint")
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
        if car.detail in ("convertible","buggy"):
            open_cabin(base, car)
        else:
            cabin(base, car, car.cabin_front, car.cabin_rear, car.shoulder - .014, car.roof, w * .836)
        if car.kind == "pickup":
            pickup_bed(base, car)
        if (car.kind in ("suv", "wagon") or car.detail == "rack") and car.detail != "buggy":
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
        if heavy or car.kind == "luxury":
            base.custom_box((0, grille_y - .047, front_z + .015), (grille_width + .095, grille_height + .071, .144),
                            CHROME, .103, .026, "Metal")
        base.box((0, grille_y - .036, front_z + .038), (grille_width, grille_height, .133),
                 TRIM, .054, "Rubber")
        for j in range(5 if square else 3):
            base.box((0, grille_y - grille_height * .40 + j * grille_height / (6 if square else 4),
                      front_z + .110), (grille_width * .84, .021, .028), CHROME, .006, "Metal")
    for side in [-1, 1]:
        light_x = w * .62 * side
        light_width = w * (.29 if car.detail == "round" else .42)
        front = front_z - (.023 if car.detail == "round" else .056)
        if car.detail == "round":
            base.orb((light_x, lights_y + .015, front), (.142, .141, .075), CHROME, 16, 9, "Metal")
            head.orb((light_x, lights_y + .021, front + .048), (.113, .113, .058), HEAD, 16, 9)
        else:
            light_height = .096 if car.detail in ("blade", "fastback", "scoop", "wing", "pixel") else .152
            base.box((light_x, lights_y, front), (light_width + .067, light_height + .055, .135),
                     TRIM, .025, "Rubber", side * .26)
            head.box((light_x, lights_y + .009, front + .064),
                     (light_width, light_height, .071), HEAD, .027, "Ceramic", side * .26)
            if not heavy:
                base.box((light_x, lights_y - light_height * .61, front + .083),
                         (light_width * .88, .026, .035), CHROME, .009, "Metal", side * .26)
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
    vehicle_finish(base, car)
    if any(entry.key == car.key for entry in FRONTIER):
        frontier_trim(base, car)
    bake_occlusion(base.mesh("Chassis"), .37, .30)
    brake.mesh("BrakeLamps")
    left.mesh("IndicatorLeft")
    right.mesh("IndicatorRight")
    head.mesh("Headlamps")


def open_cabin(m, car):
    w=car.half_width
    z=car.cabin_front
    seat=car.shoulder
    m.custom_box((0,seat+.017,-.24),(1.50*w,.10,1.36),TRIM,.14,.033)
    for side in (-1,1):
        x=side*w*.42
        m.custom_box((x,seat+.133,-.24),(.35,.162,.54),"cbb997",.11,.048)
        m.custom_box((x,seat+.267,-.42),(.35,.40,.23),"cbb997",.099,.046,yaw=side*.05)
        m.pipe([(side*w*.70,seat,z-.04),(side*w*.61,seat+.40,z-.33)],.035,CHROME,"Metal",8)
        m.box((side*w*.87,seat+.09,z-.14),(.17,.086,.12),PAINT,.039,"CoachPaint")
    m.add([(-w*.70,seat+.05,z),(-w*.61,seat+.41,z-.31),(w*.61,seat+.41,z-.31),
           (w*.70,seat+.05,z)],[(0,1,2,3)],"6e9fa2","Tint",True)
    if car.detail=="buggy":
        for side in (-1,1):
            x=side*w*.78
            m.pipe([(x,seat,z-.51),(x,seat+.63,-.32),(x,seat+.65,-.87),
                    (x,seat,-1.47)],.056,DARK_TRIM,"Metal",9)
        m.pipe([(-w*.77,seat+.64,-.53),(w*.77,seat+.64,-.53)],.053,CHROME,"Metal",9)


def frontier_trailer(m,car):
    w=car.half_width
    rear=-car.length*.49
    if car.detail=="logs":
        for side in (-1,1):
            for z in (-3.54,-2.52,-1.31,-.41):
                m.pipe([(side*w*.78,.82,z),(side*w*.82,2.10,z)],.073,CHROME,"Metal",8)
        for x,y,r in [(-.52,1.06,.27),(.01,1.06,.27),(.54,1.08,.28),
                      (-.31,1.57,.26),(.28,1.61,.29),(.0,2.04,.25)]:
            m.pipe([(x,y,rear+.15),(x+.06,y+.06,.56)],r,"a78558",sides=13)
            m.pipe([(x,y,rear+.122),(x,y,rear+.15)],r*.83,"cfb182",sides=13)
        return
    cold=car.detail=="reefer_truck"
    pane="bacac6" if cold else "b96955"
    m.custom_box((0,1.66,-1.50),(w*1.88,1.76,4.80),pane,.23,.081,"Paint")
    for side in [-1,1]:
        for col in range(9 if cold else 15):
            m.box((side*w*.94,1.66,.57-col*(.50 if cold else .30)),(.057,1.43,.061),
                  "94adb3" if cold else "d08862",.015,"Metal")
        m.box((side*.46,1.64,rear+.15),(.82,1.48,.08),pane,.056,"Paint")
        m.pipe([(side*.55,.95,rear+.083),(side*.55,2.35,rear+.083)],.029,CHROME,"Metal",7)
    if cold:
        m.custom_box((0,2.51,-.42),(1.42,.30,1.86),DARK_TRIM,.20,.054,"Metal")
        for row in range(5):
            m.box((0,2.65,-.99+row*.28),(1.24,.033,.061),CHROME,.009,"Metal")


DARK_TRIM="40525c"


def frontier_trim(m,car):
    z,w=car.length*.50,car.half_width
    if car.detail in ("fins","tailgate"):
        for side in (-1,1):
            x=side*w*.82
            m.pipe([(x,car.shoulder,-z*.38),(x*.98,car.shoulder+.1,-z*.68),
                    (x*.84,car.shoulder+.22,-z*.94)],.067,PAINT,"CoachPaint",10)
            m.pipe([(x*.90,car.shoulder-.034,-z*.50),(x*.96,car.shoulder-.022,-z*.955)],
                   .028,CHROME,"Metal",9)
        m.box((0,.45,-z-.031),(w*1.80,.09,.12),CHROME,.034,"Metal")
    elif car.detail in ("superwing","track"):
        h=.77 if car.detail=="superwing" else .96
        for side in (-1,1):
            m.pipe([(side*.43,h-.29,-z*.90),(side*.50,h,-z*.87)],.049,DARK_TRIM,"Metal",8)
        m.custom_box((0,h,-z*.87),(w*1.84,.10,.33),DARK_TRIM,.12,.038,"Metal")
        for side in (-1,1):
            m.custom_box((side*w*.84,.54,-z*.55),(.26,.16,.49),TRIM,.11,.033,"Rubber")
    elif car.detail in ("poproof","tourcoach","panoramic","limousine","kei"):
        width=w*(1.41 if car.detail!="poproof" else 1.65)
        height=.28 if car.detail=="poproof" else .061
        m.custom_box((0,car.roof+height*.53,-.48),(width,height,1.61),
                     "c4b994" if car.detail=="poproof" else "628e9a",.20,.036,"Tint")
        if car.detail in ("tourcoach","limousine"):
            for side in (-1,1):
                m.box((side*w*.965,car.shoulder+.14,-.89),(.028,.074,1.38),
                      "e8be83",.014,"Paint")
    elif car.detail in ("rescue","snowkit","shunter"):
        m.custom_box((0,car.roof+.077,-.24),(w*1.52,.17,.34),DARK_TRIM,.14,.048,"Paint")
        for side in (-1,1):
            m.orb((side*w*.51,car.roof+.163,-.24),(.146,.078,.14),"efab58",10,6,"Light")
        if car.detail=="rescue":
            m.box((0,car.shoulder+.32,-1.26),(1.32,.51,1.02),"b9b2a0",.104,"Metal")
        elif car.detail=="snowkit":
            m.pipe([(-w*.74,.49,z+.13),(0,.45,z+.22),(w*.74,.49,z+.13)],.098,CHROME,"Metal",8)
        else:
            m.box((0,.65,-.98),(1.51,.61,1.14),"d38c43",.17,"Paint")


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
    if car.detail == "tanker":
        tank_finish(model)
        return
    if car.detail in ("logs","container","reefer_truck"):
        frontier_trailer(model, car)
        return
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
        for y in [1.08, 1.55, 2.08]:
            model.box((side * .79, y, -3.797), (.18, .085, .067), CHROME, .018, "Metal")
        for z in [-3.59, -2.16, -.72]:
            model.box((side * w * .976, .837, z), (.046, .087, .159), AMBER, .018, "Tint")
    model.custom_box((0, 2.514, -1.48), (.79, .091, 3.18), "bac7b2", .19, .035, "Paint")
    model.box((0, 0.83, -1.36), (w * 1.79, .105, .40), CHROME, .03, "Metal")


def tank_finish(model):
    profile = [(-3.65,.37),(-3.48,.67),(-3.21,.82),(.15,.82),(.48,.65),(.65,.35)]
    model.pipe([(0,1.58,z) for z,_ in profile], [r for _,r in profile], "bcc8c0", "Metal", 16)
    for z in [-3.19,-1.91,-.64,.35]:
        model.pipe([(0,1.58,z-.039),(0,1.58,z+.039)], .831 if z<.20 else .758, TRIM, "Metal", 16)
    for z in [-2.66,-.63]:
        model.pipe([(0,2.32,z),(0,2.50,z)],.219,CHROME,"Metal",12)
        model.pipe([(0,2.49,z),(0,2.55,z)],.134,"d9ae60","Metal",10)
    for side in [-1,1]:
        model.box((side*.819,1.52,-1.38),(.062,.23,3.80),PAINT,.028,"CoachPaint")
        model.pipe([(side*.56,2.28,-3.25),(side*.56,2.45,-3.17),(side*.56,2.45,.16),
                    (side*.56,2.31,.26)],.026,CHROME,"Metal",7)
    for row in range(7):
        model.box((.44,1.05+row*.194,-3.53),(.46,.047,.11),CHROME,.015,"Metal")


def vehicle_finish(model, car):
    w,z=car.half_width,car.length*.5
    tall = car.kind in ("van","coach","tractor","trailer")
    for side in [-1,1]:
        # A shaped sill and a subtle hand-applied bright line lift the silhouette at phone size.
        x=side*w
        y=car.shoulder-.145
        model.pipe([(x*.86,y-.045,-z*.84),(x*.987,y,-z*.56),(x*1.001,y,z*.30),
                    (x*.97,y+.028,z*.60),(x*.82,y+.015,z*.85)], .021 if not tall else .035,
                   "c2ba92" if car.kind in ("luxury","coach","wagon") else "48606a","Metal",7)
        for k in range(2 if not tall else 3):
            model.box((x*.994,car.tire*.94,-.24+k*.14),(.029,.024,.094),"a8b5a6",.006,"Metal")

    if car.detail in ("moon","duotone") or car.key=="solstice":
        roof_length=max(.62, car.cabin_front-car.cabin_rear-.87)
        middle=(car.cabin_front+car.cabin_rear)*.5-.053
        model.custom_box((0,car.roof+.024,middle),(w*1.07,.054,roof_length),
                         "466c7c" if car.key=="solstice" else "e1c78b",.19,.019,"Tint")
    if car.detail in ("utility","expedition"):
        for side in [-1,1]:
            x=side*w*.82
            model.pipe([(x,.42,-z*.52),(x*1.16,.46,-z*.36),(x*1.16,.46,z*.36),
                        (x,.42,z*.53)],.058,TRIM,"Metal",8)
        model.custom_box((0,car.roof+.165,-.36),(w*1.33,.20,1.22),
                         "d0ad68" if car.detail=="expedition" else "8a9b73",.17,.061,"Paint")
        if car.detail=="expedition":
            model.pipe([(-w*.53,.51,z+.13),(-w*.48,.68,z+.19),(w*.48,.68,z+.19),(w*.53,.51,z+.13)], .048,CHROME,"Metal",10)
    if car.detail in ("camper","reefer","shuttle"):
        mid=-.70 if car.kind == "van" else -.46
        model.custom_box((0,car.roof+.135,mid),(w*1.58,.28,2.08 if car.detail=="camper" else 1.08),
                         "dbc8a9",.26,.087,"Paint")
        for i in range(4):
            model.box(((i-1.5)*.18,car.roof+.283,mid),(.046,.035,.48),"718f92",.012,"Metal")
        for side in [-1,1]:
            x=side*w*.975
            model.box((x,car.shoulder+.17,-.36),(.049,.081,car.length*.63),"e2a763",.021,"Paint")
            if car.detail=="camper":
                model.pipe([(x,car.roof-.31,-z+.29),(x,car.roof-.31,.02)],.071,CREAM_ROOF,"Paint",10)
    if car.key == "arrow":
        model.custom_box((0,car.shoulder+.065,-1.47),(w*1.61,.11,.57),"335465",.12,.039,"Tint")
        for side in [-1,1]:
            model.box((side*w*.855,.455,-.86),(.153,.122,.38),TRIM,.037,"Rubber",side*.13)
            model.pipe([(side*w*.76,.52,-1.39),(side*w*.89,.64,-1.57),(side*w*.80,.69,-1.76)],
                       .045,PAINT,"CoachPaint",8)
        model.custom_box((0,.705,-1.71),(w*1.87,.10,.34),TRIM,.11,.030,"Metal")


CREAM_ROOF = "e8cf9c"


def wheel(style):
    model = Model()
    spokes = {"street": 6, "utility": 5, "heavy": 8}[style]
    width = {"street": .35, "utility": .43, "heavy": .45}[style]
    side_positions = [-width, -width * .93, -width * .76, -width * .53,
                      width * .53, width * .76, width * .93, width]
    radii = [.71, .88, .977, 1, 1, .977, .88, .71]
    model.pipe([(x, 0, 0) for x in side_positions], radii, RUBBER, "Rubber", 20)
    for side in [-1, 1]:
        face = width * side
        model.pipe([(face * .93, 0, 0), (face * 1.08, 0, 0)], [.707, .667], CHROME, "Metal", 18)
        model.pipe([(face * 1.077, 0, 0), (face * 1.107, 0, 0)], .574, TRIM, "Metal", 18)
        model.pipe([(face * 1.11, 0, 0), (face * 1.24, 0, 0)], [.23, .195], CHROME, "Metal", 12)
        for i in range(spokes):
            angle = i * tau / spokes
            model.pipe([(face * 1.126, cos(angle) * .23, sin(angle) * .23),
                        (face * 1.103, cos(angle + .12) * .58, sin(angle + .12) * .58)],
                       .063 if style == "heavy" else .069, CHROME, "Metal", 6)
            at = (cos(angle)*.145, sin(angle)*.145)
            model.pipe([(face*1.225,*at),(face*1.267,*at)],.030,"8ba3a1","Metal",6)
    model.mesh("Wheel")


def generate(root, selection=None):
    folder = root / "assets/models/vehicles"
    records = []
    for car in CATALOG + FRONTIER:
        if selection is None or car.key in selection:
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
    if selection is None:
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
