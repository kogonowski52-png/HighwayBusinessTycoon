extends Node3D

const Art = preload("res://scripts/art/visual_library.gd")
const CREAM := Color("#fff0c7")
const GOLD := Color("#ffd081")
const MINT := Color("#c1f6dd")

const MARKET_AT := Vector3(-6.13, 0.0, -4.73)
const CANOPY_AT := Vector3(1.05, 0.0, 0.48)
const ISLAND_AT := Vector3(1.05, 0.0, 0.49)
const PRICE_AT := Vector3(8.17, 0.0, 3.70)
const HOSE_SOCKET := Vector3(0.60, 1.09, 0.145)
const SHELTERS := ["canopy_worn", "canopy_rehab", "canopy_service", "canopy_cantilever", "canopy_ridge"]
const STUDIES := ["canopy_arc", "canopy_ridge", "canopy_terrace"]
const SIGNAGE := {
	"canopy_worn": [Vector3(-0.30, 2.85, 1.079), "RTE 17", 0.254],
	"canopy_rehab": [Vector3(0.19, 3.18, 1.347), "NORTHPOINT", 0.265],
	"canopy_service": [Vector3(-0.54, 3.575, 1.823), "NORTHPOINT", 0.269],
	"canopy_cantilever": [Vector3(0.14, 3.81, 2.107), "NORTHPOINT", 0.303],
	"canopy_arc": [Vector3(0.20, 4.28, 2.239), "NORTHPOINT", 0.34],
	"canopy_ridge": [Vector3(-0.10, 4.018, 2.269), "NORTHPOINT", 0.341],
	"canopy_terrace": [Vector3(0.16, 4.10, 2.253), "NORTHPOINT", 0.332],
}

var structure: Node3D
var meter: MeshInstance3D
var newest_module: Node3D
var canopy: Node3D
var pump: Node3D
var market: Node3D
var market_open := false

func setup(level: int, study := "") -> void:
	if is_instance_valid(structure):
		remove_child(structure)
		structure.queue_free()
	structure = Node3D.new()
	structure.name = "StationArchitecture"
	add_child(structure)
	market = null
	build_market()
	var shelter: String = study if study in STUDIES else SHELTERS[clampi(level, 1, SHELTERS.size()) - 1]
	canopy = Art.place(structure, "architecture", shelter, CANOPY_AT)
	var sign_spec: Array = SIGNAGE[shelter]
	Art.sign(canopy, sign_spec[0], sign_spec[1], sign_spec[2], CREAM)
	pump = Art.place(structure, "architecture", "pump_vintage" if level == 1 else "island", ISLAND_AT)
	var price := Art.place(structure, "architecture", "price_sign", PRICE_AT)
	Art.sign(price, Vector3(0.16, 3.246, 0.246), "RTE 17", 0.234, CREAM)
	Art.sign(price, Vector3(0, 2.685, 0.298), "95  5.89", 0.226, MINT)
	Art.sign(price, Vector3(0, 2.291, 0.298), "98  6.39", 0.219, GOLD)
	Art.contact(structure, Vector3(-6.18, 0.018, -4.65), 8.8, 6.35)
	Art.contact(structure, Vector3(1.05, 0.020, 0.53), 4.2 if level == 1 else 8.4, 2.08)
	Art.contact(structure, Vector3(8.17, 0.018, 3.7), 2.04, 1.88)

	var screen := BoxMesh.new()
	screen.size = Vector3(0.434, 0.058, 0.007)
	var finish := StandardMaterial3D.new()
	finish.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	finish.albedo_color = MINT
	meter = MeshInstance3D.new()
	meter.mesh = screen
	meter.material_override = finish
	meter.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	meter.position = ISLAND_AT + (Vector3(-0.042, 1.363, 0.421) if level == 1 else Vector3(-0.042, 1.35, 0.382))
	structure.add_child(meter)
	newest_module = null
	for tier in range(2, level + 1):
		newest_module = Art.place(structure, "architecture", "stage_%d" % tier)
	if level >= 2:
		var seat := structure.find_child("stage_2", false, false) as Node3D
		if seat:
			Art.sign(seat, Vector3(5.31, 2.86, -0.762), "PIT STOP", 0.205, CREAM)

func set_market_open(opened: bool) -> void:
	if market_open == opened:
		return
	market_open = opened
	if is_instance_valid(structure):
		build_market()

func build_market() -> void:
	if is_instance_valid(market):
		structure.remove_child(market)
		market.queue_free()
	market = Art.place(structure, "architecture", "market" if market_open else "market_shuttered", MARKET_AT)
	if market_open:
		Art.sign(market, Vector3(0.1, 2.662, 2.728), "NORTHPOINT MARKET", 0.255, CREAM)
	else:
		Art.sign(market, Vector3(-0.57, 2.145, 1.775), "NORTHPOINT", 0.225, CREAM)

func hose_anchor() -> Vector3:
	return pump.to_global(HOSE_SOCKET)

func set_service_progress(progress: float) -> void:
	meter.scale.x = maxf(progress, 0.055)
	meter.position.x = ISLAND_AT.x - 0.26 + 0.217 * meter.scale.x

func animate_construction() -> void:
	if is_instance_valid(newest_module):
		Art.settle(canopy)
		Art.settle(newest_module)
