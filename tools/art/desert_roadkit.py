"""Foreground islands, market furniture and highway luminaires for Copper Mile."""
from pathlib import Path
from math import sin, cos, tau
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from kit import Model, bake_occlusion, clear_objects, export, output_root


def planter():
    m = Model()
    m.custom_box((0, .15, 0), (3.32, .34, 1.47), "cda481", .50, .09)
    m.custom_box((0, .33, 0), (3.00, .12, 1.25), "a27559", .43, .036)
    m.custom_box((0, .31, 0), (2.77, .14, 1.06), "be956c", .42, .014)
    for i, x in enumerate([-1.08, -.37, .24, .95]):
        for y in range(6):
            theta = tau * y / 6 + x
            dx = .34 * sin(theta)
            dz = .35 * cos(theta)
            m.pipe([(x, .33, 0), (x + dx*.65, .53, dz*.54), (x+dx, .69+.12*(i%3), dz)],
                   [.102, .078, .014], ["668e6b","77995e","508671"][(i+y)%3], sides=6)
        m.orb((x+.24,.40,.26),(.21,.16,.15),"ce9a77",9,5,irregular=.12)
    return m


def lamp():
    m = Model()
    m.box((0, .117, 0), (.62, .27, .61), "ba9a79", .10)
    m.pipe([(0,.19,0),(0,.41,0),(0,3.31,0),(.1,3.89,0),(.47,4.11,0),(.79,4.11,0)],
           [.095,.085,.055,.056,.063,.075], "659082", "Metal", 10)
    m.custom_box((.83,4.12,0),(.72,.24,.36),"577365",.18,.06,"Paint")
    m.custom_box((.90,4.00,0),(.51,.073,.31),"ffe4ad",.13,.021,"Light")
    return m


def stone_fence():
    m = Model()
    for side in [-1,1]:
        m.custom_box((side*1.42, .31, 0),(.46,.64,.56),"b78967",.16,.06)
        m.box((side*1.42,.67,0),(.56,.13,.64),"dbac83",.06)
    m.custom_box((0,.38,0),(2.85,.25,.30),"8b7d6d",.13,.054,"Metal")
    for index in range(7):
        m.box((-1.13+index*.377,.39,.16),(.17,.19,.038),"c3ba9b" if index%2==0 else "eb9560",.024)
    return m


def roof_variant():
    m = Model()
    m.custom_box((0,.28,0),(4.7,.55,1.62),"889e97",.60,.14,"Metal")
    m.custom_box((0,.57,0),(4.42,.28,1.59),"1d6464",.52,.095,"Paint")
    m.custom_box((-1.65,.69,0),(1.50,.21,1.33),"a5403a",.47,.069,"Paint")
    m.box((0,.51,.84),(3.29,.10,.13),"f4ce78",.025,"Light")
    for x in [-1.86,1.86]:
        m.pipe([(x,.035,0),(x,.18,.46),(x,.5,.67)],.093,"b6b6a4","Metal",8)
    return m


def utility_kit():
    m = Model()
    m.custom_box((0,.165,.04),(.82,.265,.52),"91705a",.106,.067,"Paint")
    m.box((0,.272,.04),(.84,.071,.55),"d0a37e",.048)
    for shift in [-.23,.23]:
        m.box((shift,.277,.04),(.09,.105,.56),"b9783e",.028,"Metal")
    m.pipe([(cos(a*tau/14)*.245+.47,.19,sin(a*tau/14)*.245-.22) for a in range(15)],
           .095,"46413d","Rubber",8)
    return m


for name, model in [
        ("median_planter", planter()), ("highway_lamp", lamp()), ("barrier", stone_fence()),
        ("upgrade_copper_arch", roof_variant()), ("truck_kit", utility_kit())]:
    clear_objects()
    mesh = model.mesh(name.title().replace("_", ""))
    bake_occlusion(mesh, radius=.87, strength=.49)
    export(output_root() / "assets/models/desert" / f"{name}.glb")
