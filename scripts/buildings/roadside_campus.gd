extends Node3D

const Art = preload("res://scripts/art/visual_library.gd")
const Routes = preload("res://data/economy/routes.gd")
const Strings = preload("res://localization/strings.gd")
const Station = preload("res://scripts/buildings/building_manager.gd")
const Kit = preload("res://scripts/buildings/model_kit.gd")
const CREAM := Color("#fff0ce")

const WASH_AT := Vector3(11.47, 0.0, -7.85)
const KITCHEN_AT := Vector3(-16.02, 0.0, -8.58)
const WORKSHOP_AT := Vector3(8.68, 0.0, -16.47)
const MOTEL_AT := Vector3(-7.81, 0.0, -16.82)
const PARKING_AT := Vector3(-16.54, 0.0, -0.85)
const TRUCK_AT := Vector3(23.90, 0.0, -6.89)
const TIRES_AT := Vector3(-31.85, 0.0, -8.15)
const CHARGE_AT := Vector3(-38.35, 0.0, -1.10)
const TRUCK_PARK_AT := Vector3(45.50, 0.0, -13.42)

const THRESHOLDS := [1, 15, 35, 65, 90]
const ROOF_MODULES := ["service_console", "service_clerestory", "service_solar", "service_mechanical", "service_lantern"]
const ANNEXES := {
	"market": Station.MARKET_AT + Vector3(-4.73, 0, -.30),
	"wash": WASH_AT + Vector3(3.52, 0, -1.46),
	"workshop": WORKSHOP_AT + Vector3(2.54, 0, -3.69),
	"restaurant": KITCHEN_AT + Vector3(-4.57, 0, -.63),
	"motel": MOTEL_AT + Vector3(-4.80, 0, -2.04),
	"parking": PARKING_AT + Vector3(-4.64, 0, -2.57),
	"truck": TRUCK_AT + Vector3(5.60, 0, -3.92),
	"tires": TIRES_AT + Vector3(2.84, 0, -2.54),
	"charge": CHARGE_AT + Vector3(-2.59, 0, -1.96),
	"truck_park": TRUCK_PARK_AT + Vector3(3.90, 0, -3.11),
}
const ROOFS := {
	"market": [Station.MARKET_AT, [Vector3(2.52, 3.07, 1.51), Vector3(-1.52, 3.51, 0.91),
		Vector3(-1.26, 3.51, -0.87), Vector3(2.52, 3.07, -1.92), Vector3(0.58, 3.51, 0.81)]],
	"wash": [WASH_AT, [Vector3(-2.31, 3.23, 1.87), Vector3(1.54, 3.22, 1.61),
		Vector3(1.55, 3.23, 0.31), Vector3(-0.63, 3.39, -0.55), Vector3(-0.65, 3.39, 0.76)]],
	"restaurant": [KITCHEN_AT, [Vector3(-1.93, 3.02, 0.41), Vector3(0.14, 3.02, 0.27),
		Vector3(1.63, 3.02, -1.09), Vector3(-0.53, 3.02, -1.42), Vector3(2.79, 3.02, 0.18)]],
	"workshop": [WORKSHOP_AT, [Vector3(-2.81, 3.08, 0.74), Vector3(-1.42, 3.74, -0.54),
		Vector3(1.10, 3.74, -0.50), Vector3(-1.51, 3.08, -1.98), Vector3(1.93, 3.08, 0.71)]],
	"motel": [MOTEL_AT, [Vector3(-3.69, 4.32, 0.36), Vector3(-1.45, 4.32, 0.76),
		Vector3(1.71, 4.49, -1.10), Vector3(-3.57, 4.32, -1.46), Vector3(2.47, 4.32, 0.70)]],
	"parking": [PARKING_AT, [Vector3(-2.76, 2.36, -2.25), Vector3(-0.44, 2.36, -1.87),
		Vector3(1.86, 2.36, -1.56), Vector3(-2.39, 2.36, -1.12), Vector3(2.93, 2.36, -2.54)]],
	"truck": [TRUCK_AT, [Vector3(-2.77, 5.42, 1.81), Vector3(-2.32, 5.42, -1.63),
		Vector3(2.16, 5.42, -1.78), Vector3(2.45, 5.42, 1.78), Vector3(2.90, 5.42, 4.57)]],
	"tires": [TIRES_AT, [Vector3(-2.61, 3.18, 0.69), Vector3(-1.75, 3.18, -0.67),
		Vector3(0.17, 3.18, -0.66), Vector3(1.63, 3.18, 0.69), Vector3(2.60, 3.18, -1.36)]],
	"charge": [CHARGE_AT, [Vector3(-0.94, 2.34, -0.76), Vector3(-0.80, 2.34, 0.24),
		Vector3(0.42, 2.34, -0.50), Vector3(0.81, 2.34, 0.40), Vector3(1.32, 2.34, -0.64)]],
	"truck_park": [TRUCK_PARK_AT, [Vector3(-0.92, 2.68, 0.72), Vector3(-0.76, 2.68, -0.68),
		Vector3(0.44, 2.68, -0.51), Vector3(0.72, 2.68, 0.61), Vector3(0.94, 2.68, -0.58)]],
}

var markers: Dictionary = {}
var roof_counts: Dictionary = {}
var roof_batches: Array[MultiMesh] = []
var roof_slots: Array[Dictionary] = []
var annexes: Dictionary = {}
var annex_stages: Dictionary = {}
var extra_islands: Dictionary = {}
var workshop_shutters: Node3D
var new_bays: Dictionary = {"charge": [], "truck_park": [], "tires": []}
var charge_shelters: Array[Node3D] = []
var charge_screens: Array[Label3D] = []
var charge_links: Array[Node3D] = []

func _ready() -> void:
	var wash := Art.place(self, "architecture", "wash", WASH_AT)
	Art.sign(wash, Vector3(0, 2.82, 2.926), "CURRENT WASH", 0.281, CREAM)
	var kitchen := Art.place(self, "architecture", "restaurant", KITCHEN_AT)
	Art.sign(kitchen, Vector3(0, 2.706, 1.767), "JUNIPER", 0.343, CREAM)
	var workshop := Art.place(self, "architecture", "workshop", WORKSHOP_AT)
	Art.sign(workshop, Vector3(0, 2.622, 2.497), "MILE 17 GARAGE", 0.244, CREAM)
	workshop_shutters = Art.place(self, "architecture", "workshop_shutter", WORKSHOP_AT)
	var motel := Art.place(self, "architecture", "motel", MOTEL_AT)
	Art.sign(motel, Vector3(4.14, 3.394, 2.320), "MOTEL", 0.224, CREAM)
	var parking := Art.place(self, "architecture", "parking", PARKING_AT)
	Art.sign(parking, Vector3(-3.9, 1.958, 1.973), "P", 0.538, CREAM)
	for at in [WASH_AT, KITCHEN_AT, WORKSHOP_AT, MOTEL_AT, PARKING_AT]:
		Art.contact(self, at + Vector3(0, 0.013, 0.10), 8.7, 7.0)
	var heavy := Art.place(self, "architecture", "truck_canopy", TRUCK_AT)
	Art.sign(heavy, Vector3(0, 5.15, 5.557), "NORTHPOINT FREIGHT", 0.41, CREAM)
	build_extensions()
	for id in ["fuel", "truck"]:
		var islands: Array[Node3D] = []
		var first := int(id == "fuel")
		for index in range(first, 2 if id == "fuel" else 3):
			var at := Routes.position_of(id, index)
			var island := Art.place(self, "architecture", "island", at + Vector3(0, 0, -1.55))
			island.scale = Vector3(0.70, 0.75, 0.75)
			islands.append(island)
		extra_islands[id] = islands
	for definition in HbtEconomy.CONFIG.services:
		var id := definition.id
		var at := Routes.position_of(id, 0) + Vector3(0.0, 2.23, 0.0)
		var label := Art.sign(self, at, "", 0.30, CREAM)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.outline_size = 13
		label.outline_modulate = Color("#173a3c")
		markers[id] = label
		roof_counts[id] = 0
	for module in ROOF_MODULES:
		var batch := MultiMesh.new()
		batch.transform_format = MultiMesh.TRANSFORM_3D
		batch.mesh = Art.extract_mesh("architecture", module)
		var group := MultiMeshInstance3D.new()
		group.multimesh = batch
		add_child(group)
		roof_batches.append(batch)
		roof_slots.append({})

func build_extensions() -> void:
	var tires := Art.place(self, "architecture", "tire_shop", TIRES_AT)
	Art.sign(tires, Vector3(-0.13, 2.64, 2.151), "REDLINE TYRES", 0.28, CREAM)
	Art.contact(self, TIRES_AT + Vector3(0, 0.013, 0.22), 8.7, 6.8)
	var lounge := Art.place(self, "architecture", "ev_lounge", CHARGE_AT)
	Art.sign(lounge, Vector3(0, 1.94, 1.614), "NORTHPOINT EV", 0.165, CREAM)
	Art.contact(self, CHARGE_AT + Vector3(0, 0.013, 0.22), 4.5, 4.1)
	var layover := Art.place(self, "architecture", "freight_office", TRUCK_PARK_AT)
	Art.sign(layover, Vector3(-0.17, 2.19, 1.754), "LAYOVER 17", 0.175, CREAM)
	Art.contact(self, TRUCK_PARK_AT + Vector3(0, 0.013, 0.18), 4.0, 4.2)
	for index in range(2):
		var marker := Art.place(self, "architecture", "freight_sign", Routes.position_of("truck_park", index) + Vector3(-4.21, 0, -1.37))
		Art.sign(marker, Vector3(0, 1.41, 0.132), "P %d" % (index + 1), 0.19, CREAM)
		new_bays.truck_park.append(marker)
		var tire_marker := Art.place(self, "architecture", "freight_sign", Routes.position_of("tires", index) + Vector3(1.45, 0, 1.82))
		tire_marker.scale = Vector3.ONE * 0.78
		Art.sign(tire_marker, Vector3(0, 1.41, 0.132), str(index + 1), 0.22, CREAM)
		new_bays.tires.append(tire_marker)
	for index in range(3):
		var at := Routes.position_of("charge", index)
		var socket := Art.place(self, "architecture", "ev_column", at + Vector3(1.16, 0, -1.67))
		new_bays.charge.append(socket)
		charge_screens.append(Art.sign(socket, Vector3(0, 1.232, 0.260), "EV", 0.077, CREAM))
		charge_shelters.append(Art.place(self, "architecture", "ev_solar", at + Vector3(0, 0, -0.63)))
		var link := Node3D.new()
		link.position = at
		add_child(link)
		var points := [Vector3(0.90, 0.98, -1.57), Vector3(1.07, 0.64, -1.27),
			Vector3(1.02, 0.30, -0.92), Vector3(0.90, 0.34, -0.49), Vector3(0.72, 0.60, -0.30)]
		for segment in range(1, points.size()):
			var span: Vector3 = points[segment] - points[segment - 1]
			var piece := Kit.cylinder(link, (points[segment] + points[segment - 1]) * 0.5, 0.032, 0.032,
				span.length() + 0.022, Color("#294747"), 8)
			piece.quaternion = Quaternion(Vector3.UP, span.normalized())
			piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		link.hide()
		charge_links.append(link)

func update_sites(economy: HbtEconomy) -> void:
	workshop_shutters.visible = economy.level("workshop") == 0
	var roofs_changed := false
	for id in markers:
		var level := economy.level(id)
		var marker: Label3D = markers[id]
		marker.text = Strings.phrase(economy.language, "site_closed") if level == 0 else ""
		marker.visible = level == 0
		if id in ROOFS:
			var count := 0
			for threshold in THRESHOLDS:
				count += int(level >= threshold)
			roofs_changed = roofs_changed or count != roof_counts[id]
			roof_counts[id] = count
	if roofs_changed:
		update_roofs()
	for id in extra_islands:
		var group: Array = extra_islands[id]
		var capacity := economy.capacity(id) - int(id == "fuel")
		for index in range(group.size()):
			group[index].visible = index < capacity
	for id in new_bays:
		for index in range(new_bays[id].size()):
			new_bays[id][index].visible = index < economy.capacity(id)
	for index in range(charge_shelters.size()):
		charge_shelters[index].visible = index < economy.capacity("charge") and economy.level("charge") >= 35

func update_chargers(dispatch: HbtDispatch) -> void:
	for index in range(charge_screens.size()):
		var visit := dispatch.visit_at("charge", index)
		var charging := visit != null and visit.phase == HbtVisit.Phase.WORKING and visit.walked >= visit.foot_length
		charge_links[index].visible = charging
		var display := "%d%%" % roundi(visit.progress() * 100.0) if charging else "EV"
		if charge_screens[index].text != display:
			charge_screens[index].text = display

func roof_anchor(id: String, stage: int) -> Vector3:
	var roof: Array = ROOFS[id]
	return roof[0] + roof[1][stage]

func update_roofs() -> void:
	for id: String in ANNEXES:
		var stage: int = roof_counts[id]
		if int(annex_stages.get(id, 0)) == stage:
			continue
		annex_stages[id] = stage
		if annexes.has(id):
			var previous: Node3D = annexes[id]
			remove_child(previous)
			previous.queue_free()
			annexes.erase(id)
		if stage >= 2:
			annexes[id] = Art.place(self, "architecture", "annex_%s_%d" % [id, stage], ANNEXES[id], .12 if id == "restaurant" else 0.0)
	for stage in range(roof_batches.size()):
		var slots := roof_slots[stage]
		slots.clear()
		for id in ROOFS:
			if roof_counts[id] > stage:
				slots[id] = slots.size()
		var group := roof_batches[stage]
		group.instance_count = slots.size()
		for id in slots:
			group.set_instance_transform(slots[id], Transform3D(Basis.IDENTITY, roof_anchor(id, stage)))

func animate_install(id: String, previous_count: int) -> void:
	if annexes.has(id) and roof_counts[id] > previous_count:
		Art.settle(annexes[id])
	for stage in range(previous_count, roof_counts[id]):
		var lift := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		var place_module := func(weight: float) -> void:
			var slot: int = roof_slots[stage].get(id, -1)
			if slot >= 0:
				var at := roof_anchor(id, stage) + Vector3.UP * (0.75 * weight)
				var frame := Basis.from_scale(Vector3(1.0, 1.0 - weight * 0.18, 1.0))
				roof_batches[stage].set_instance_transform(slot, Transform3D(frame, at))
		place_module.call(1.0)
		lift.tween_method(place_module, 1.0, 0.0, 0.65)

func focus(id: String) -> Vector3:
	if id == "fuel":
		return Vector3(-0.2, 0.0, 1.45)
	return Routes.position_of(id, 0)

func hose_anchor(visit: HbtVisit) -> Vector3:
	var island: Node3D = extra_islands[visit.service][visit.bay - int(visit.service == "fuel")]
	return island.to_global(Station.HOSE_SOCKET)
