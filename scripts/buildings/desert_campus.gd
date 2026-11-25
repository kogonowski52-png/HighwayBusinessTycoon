extends Node3D

const Art = preload("res://scripts/art/visual_library.gd")
const Kit = preload("res://scripts/buildings/model_kit.gd")
const Routes = preload("res://data/world/desert_routes.gd")
const THRESHOLDS := [1, 12, 30, 60, 90]
const UPGRADES := ["storage", "porch", "solar", "beacon"]
const SIGNS := {
	"cafe": ["DUST  &  BEAN", 2.18, 2.76], "restrooms": ["RESTROOMS", 2.44, 1.84],
	"vip_park": ["SUNSET   VIP", 2.91, .51], "truck": ["RED MESA   SERVICE", 4.50, 2.56],
	"showers": ["TRUCKERS'  SHOWERS", 2.43, 1.78], "motel": ["STARGAZER", 4.13, 1.38],
	"truck_park": ["RED MESA   TRUCK PARK", 4.35, .51], "drive_through": ["ROADSTAR  GRILL", 2.28, 1.80],
	"charge": ["SUNVOLT   FAST CHARGE", 2.93, .51],
}
const ROOFLINE := {"fuel": 3.80, "cafe": 2.59, "restrooms": 2.71, "vip_park": 3.04, "truck": 4.96,
	"showers": 2.71, "motel": 4.31, "truck_park": 4.46, "drive_through": 2.66, "charge": 3.22}

var buildings := {}
var plots := {}
var upgrades := {}
var roof_counts := {}
var chargers: Array[Node3D] = []
var lamps: Array[OmniLight3D] = []
var shutter: Node3D

func _ready() -> void:
	for id in Routes.FRONTS:
		var at: Vector3 = Routes.FRONTS[id]
		roof_counts[id] = 0
		var parts := Node3D.new()
		add_child(parts)
		upgrades[id] = []
		for index in UPGRADES.size():
			var part_at := at + upgrade_offset(id, index)
			var part := Art.place(parts, "desert", "upgrade_" + UPGRADES[index], part_at)
			part.hide()
			upgrades[id].append(part)
		if id == "fuel":
			continue
		var building := Art.place(self, "desert", id, at)
		Art.contact(self, at + Vector3(0, -.010, 0), 9.0 if Routes.is_truck(id) else 6.1, 4.20)
		var placard: Array = SIGNS[id]
		Art.sign(building, Vector3(0, placard[1], placard[2]), placard[0], .25, Color("#fff0c0"))
		buildings[id] = building
		var pad := Node3D.new()
		pad.position = at
		add_child(pad)
		Art.place(pad, "desert", "upgrade_storage", Vector3(.10, 0, .63))
		var marker := Kit.box(pad, Vector3(-.83, .52, 1.07), Vector3(.51, .19, .12), Color("#e9b667"))
		marker.rotation.z = 0.12
		Kit.box(pad, Vector3(-.83, .22, 1.07), Vector3(.06, .45, .05), Color("#69564c"))
		plots[id] = pad
	for bay: Vector3 in Routes.BAYS.charge:
		var item := Art.place(buildings.charge, "desert", "charger", bay - Routes.FRONTS.charge + Vector3(-1.17, 0, -.66))
		chargers.append(item)
		var light := OmniLight3D.new()
		light.position = Vector3(0, 1.25, .31)
		light.light_color = Color("#6df2ba")
		light.omni_range = 1.86
		item.add_child(light)
		lamps.append(light)
	shutter = Kit.box(buildings.truck, Vector3(0, 3.39, 2.31), Vector3(4.7, 1.20, .12), Color("#779386"))

func upgrade_offset(id: String, index: int) -> Vector3:
	var width := 6.75 if Routes.is_truck(id) else 3.77
	match index:
		0: return Vector3(-width, 0, -.54)
		1: return Vector3(width * .94, 0, .88)
		2: return Vector3(-1.02, ROOFLINE[id], -.70)
		_: return Vector3(1.88, ROOFLINE[id] - .08, .17)

func focus(id: String) -> Vector3:
	return Routes.FRONTS[id] + Vector3(0, 0, 1.73)

func update_sites(economy: HbtEconomy) -> void:
	for id in Routes.FRONTS:
		var level := economy.level(id)
		if id != "fuel":
			buildings[id].visible = level > 0
			plots[id].visible = level == 0
		var stage := THRESHOLDS.filter(func(tier: int) -> bool: return level >= tier).size()
		roof_counts[id] = stage
		for index in UPGRADES.size():
			upgrades[id][index].visible = index + 1 < stage
	for index in chargers.size():
		chargers[index].visible = index < economy.capacity("charge")

func animate_install(id: String, previous: int) -> void:
	if previous == 0 and id in buildings:
		Art.settle(buildings[id])
	for index in range(maxi(0, previous - 1), maxi(0, roof_counts[id] - 1)):
		Art.settle(upgrades[id][index])

func hose_anchor(visit: HbtVisit) -> Vector3:
	return Routes.position_of(visit.service, visit.bay) + Vector3(1.43, 1.10, -.6)

func update_chargers(dispatch: HbtDispatch) -> void:
	for index in lamps.size():
		var ticket := dispatch.visit_at("charge", index)
		lamps[index].light_energy = .61 if ticket != null and ticket.phase == HbtVisit.Phase.WORKING else 0.0
	var carrier := dispatch.visit_at("truck", 0)
	var height := 4.02 if carrier != null else 3.39
	shutter.position.y = lerpf(shutter.position.y, height, .12)
