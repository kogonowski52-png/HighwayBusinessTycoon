extends Node3D

const Art = preload("res://scripts/art/visual_library.gd")
const CREAM := Color("#fff0c7")
const GOLD := Color("#ffd081")
const MINT := Color("#c1f6dd")

const MARKET_AT := Vector3(-6.13, 0.0, -4.73)
const CANOPY_AT := Vector3(1.05, 0.0, 0.48)
const ISLAND_AT := Vector3(1.05, 0.0, 0.49)
const PRICE_AT := Vector3(8.17, 0.0, 3.70)

var structure: Node3D
var meter: MeshInstance3D
var newest_module: Node3D

func setup(level: int) -> void:
	if is_instance_valid(structure):
		remove_child(structure)
		structure.queue_free()
	structure = Node3D.new()
	structure.name = "StationArchitecture"
	add_child(structure)
	var market := Art.place(structure, "architecture", "market", MARKET_AT)
	Art.sign(market, Vector3(0.1, 2.662, 2.728), "NORTHPOINT MARKET", 0.255, CREAM)
	var canopy := Art.place(structure, "architecture", "canopy", CANOPY_AT)
	Art.sign(canopy, Vector3(0.08, 3.768, 2.015), "NORTHPOINT", 0.269, CREAM)
	Art.place(structure, "architecture", "island", ISLAND_AT)
	var price := Art.place(structure, "architecture", "price_sign", PRICE_AT)
	Art.sign(price, Vector3(0.16, 3.246, 0.246), "RTE 17", 0.234, CREAM)
	Art.sign(price, Vector3(0, 2.685, 0.298), "95  5.89", 0.226, MINT)
	Art.sign(price, Vector3(0, 2.291, 0.298), "98  6.39", 0.219, GOLD)
	Art.contact(structure, Vector3(-6.18, 0.018, -4.65), 8.8, 6.35)
	Art.contact(structure, Vector3(1.05, 0.020, 0.53), 8.4, 2.08)
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
	meter.position = ISLAND_AT + Vector3(-0.042, 1.35, 0.382)
	structure.add_child(meter)
	newest_module = null
	for tier in range(2, level + 1):
		newest_module = Art.place(structure, "architecture", "stage_%d" % tier)
	if level >= 2:
		var seat := structure.find_child("stage_2", false, false) as Node3D
		if seat:
			Art.sign(seat, Vector3(5.31, 2.86, -0.762), "PIT STOP", 0.205, CREAM)

func set_service_progress(progress: float) -> void:
	meter.scale.x = maxf(progress, 0.055)
	meter.position.x = ISLAND_AT.x - 0.26 + 0.217 * meter.scale.x

func animate_construction() -> void:
	if is_instance_valid(newest_module):
		Art.settle(newest_module)
