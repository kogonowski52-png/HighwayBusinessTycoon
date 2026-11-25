extends Node3D

const Art = preload("res://scripts/art/visual_library.gd")
const Routes = preload("res://data/economy/routes.gd")
const Strings = preload("res://localization/strings.gd")
const Station = preload("res://scripts/buildings/building_manager.gd")
const CREAM := Color("#fff0ce")

const WASH_AT := Vector3(11.47, 0.0, -7.85)
const KITCHEN_AT := Vector3(-16.02, 0.0, -8.58)
const WORKSHOP_AT := Vector3(8.68, 0.0, -16.47)
const MOTEL_AT := Vector3(-7.81, 0.0, -16.82)
const PARKING_AT := Vector3(-16.54, 0.0, -0.85)
const TRUCK_AT := Vector3(23.90, 0.0, -6.89)

const THRESHOLDS := [1, 15, 35, 65, 90]
const ROOF_MODULES := ["service_console", "service_clerestory", "service_solar", "service_mechanical", "service_lantern"]
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
}

var markers: Dictionary = {}
var roof_counts: Dictionary = {}
var roof_batches: Array[MultiMesh] = []
var roof_slots: Array[Dictionary] = []
var extra_islands: Dictionary = {}

func _ready() -> void:
	var wash := Art.place(self, "architecture", "wash", WASH_AT)
	Art.sign(wash, Vector3(0, 2.82, 2.926), "CURRENT WASH", 0.281, CREAM)
	var kitchen := Art.place(self, "architecture", "restaurant", KITCHEN_AT)
	Art.sign(kitchen, Vector3(0, 2.706, 1.767), "JUNIPER", 0.343, CREAM)
	var workshop := Art.place(self, "architecture", "workshop", WORKSHOP_AT)
	Art.sign(workshop, Vector3(0, 2.622, 2.497), "MILE 17 GARAGE", 0.244, CREAM)
	var motel := Art.place(self, "architecture", "motel", MOTEL_AT)
	Art.sign(motel, Vector3(4.14, 3.394, 2.320), "MOTEL", 0.224, CREAM)
	var parking := Art.place(self, "architecture", "parking", PARKING_AT)
	Art.sign(parking, Vector3(-3.9, 1.958, 1.973), "P", 0.538, CREAM)
	for at in [WASH_AT, KITCHEN_AT, WORKSHOP_AT, MOTEL_AT, PARKING_AT]:
		Art.contact(self, at + Vector3(0, 0.013, 0.10), 8.7, 7.0)
	var heavy := Art.place(self, "architecture", "truck_canopy", TRUCK_AT)
	Art.sign(heavy, Vector3(0, 5.15, 5.557), "NORTHPOINT FREIGHT", 0.41, CREAM)
	for id in ["fuel", "truck"]:
		var islands: Array[Node3D] = []
		var first := int(id == "fuel")
		for index in range(first, 2 if id == "fuel" else 3):
			var at := Routes.position_of(id, index)
			var island := Art.place(self, "architecture", "island", at + Vector3(0, 0, -1.55))
			island.scale = Vector3(0.70, 0.75, 0.75)
			islands.append(island)
		extra_islands[id] = islands
	for id in ["fuel", "market", "wash", "parking", "workshop", "restaurant", "motel", "truck"]:
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

func update_sites(economy: HbtEconomy) -> void:
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

func roof_anchor(id: String, stage: int) -> Vector3:
	var roof: Array = ROOFS[id]
	return roof[0] + roof[1][stage]

func update_roofs() -> void:
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
