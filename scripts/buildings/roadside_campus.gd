extends Node3D

const Art = preload("res://scripts/art/visual_library.gd")
const Routes = preload("res://data/economy/routes.gd")
const Kit = preload("res://scripts/buildings/model_kit.gd")
const Strings = preload("res://localization/strings.gd")
const CREAM := Color("#fff0ce")

const WASH_AT := Vector3(11.47, 0.0, -7.85)
const KITCHEN_AT := Vector3(-16.02, 0.0, -8.58)
const WORKSHOP_AT := Vector3(8.68, 0.0, -16.47)
const MOTEL_AT := Vector3(-7.81, 0.0, -16.82)
const PARKING_AT := Vector3(-16.54, 0.0, -0.85)
const TRUCK_AT := Vector3(23.90, 0.0, -5.22)

var markers: Dictionary = {}
var additions: Dictionary = {}

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
	var heavy := Art.place(self, "architecture", "canopy", TRUCK_AT)
	Art.sign(heavy, Vector3(0, 3.76, 2.04), "NORTHPOINT  /  TRUCK", 0.32, CREAM)
	for id in ["fuel", "market", "wash", "parking", "workshop", "restaurant", "motel", "truck"]:
		var at := Routes.position_of(id, 0) + Vector3(0.0, 2.23, 0.0)
		var label := Art.sign(self, at, "", 0.30, CREAM)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.outline_size = 7
		label.outline_modulate = Color("#173a3c")
		markers[id] = label
		additions[id] = []

func update_sites(economy: HbtEconomy) -> void:
	for id in markers:
		var level := economy.level(id)
		var marker: Label3D = markers[id]
		marker.text = Strings.phrase(economy.language, "site_closed") if level == 0 else ""
		marker.visible = level == 0
		var installed: Array = additions[id]
		var count := int(level > 0) + int(level >= 15) + int(level >= 35) + int(level >= 65) + int(level >= 90)
		for stage in range(installed.size(), count):
			installed.append(install(id, stage))

func install(id: String, stage: int) -> Node3D:
	var fixture := Node3D.new()
	add_child(fixture)
	if stage == 0 and id == "fuel":
		return fixture
	var last := mini(stage, 2)
	var capacity_by_id := {"fuel": 2, "market": 2, "wash": 2, "parking": 3, "workshop": 2,
		"restaurant": 2, "motel": 3, "truck": 3}
	var bay := Routes.position_of(id, mini(last, capacity_by_id[id] - 1))
	if id in ["fuel", "truck"] and (stage == 0 or stage == 1):
		var island := Art.place(fixture, "architecture", "island", bay + Vector3(0, 0, -1.46))
		island.scale = Vector3(0.70, 0.75, 0.75)
	if stage == 0:
		Kit.box(fixture, bay + Vector3(0, 0.02, 1.42), Vector3(1.33, 0.02, 0.09), Color("#f5bd6e"))
	else:
		var facing := Routes.stopping_yaw(id)
		var shift := Vector3(0.93 + float(stage - 1) * 0.16, 0.0, 0.30).rotated(Vector3.UP, facing)
		var lamp := Art.place(fixture, "landscape", "lamp", bay + shift, facing)
		lamp.scale = Vector3.ONE * (0.52 + 0.04 * stage)
		var tint := Color("#eac479") if stage < 3 else Color("#88d4b9")
		Kit.box(fixture, bay + shift + Vector3(0, 0.087, 0), Vector3(0.43, 0.187, 0.41), tint)
	return fixture

func focus(id: String) -> Vector3:
	if id == "fuel":
		return Vector3(-0.2, 0.0, 1.45)
	return Routes.position_of(id, 0)
