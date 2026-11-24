extends Node3D

const Kit = preload("res://scripts/buildings/model_kit.gd")
const INK := Color("#203c42")
const TEAL := Color("#246c62")
const GOLD := Color("#f2b767")
const WHITE := Color("#f3deb3")
const GLASS := Color("#478481")

var structure: Node3D
var meter: MeshInstance3D

func setup(level: int) -> void:
	if is_instance_valid(structure):
		remove_child(structure)
		structure.queue_free()
	structure = Node3D.new()
	add_child(structure)
	shop()
	canopy(level)
	pump(level)
	pylon(level)

func shop() -> void:
	Kit.box(structure, Vector3(-5.2, 0.16, -4.8), Vector3(7.4, 0.32, 5.1), WHITE)
	Kit.box(structure, Vector3(-5.2, 1.42, -4.8), Vector3(7, 2.55, 4.5), Color("#d6ac81"))
	var roof := Node3D.new()
	roof.position = Vector3(-5.2, 0, -4.8)
	structure.add_child(roof)
	Kit.loft(roof, [Vector4(2.58, 3.8, 2.55, 0), Vector4(3.32, 3.58, 0.56, -0.38)], INK)
	Kit.box(structure, Vector3(-5.2, 2.58, -4.8), Vector3(7.65, 0.15, 5.15), TEAL)
	for x in [-7.35, -5.92, -3.02]:
		Kit.box(structure, Vector3(x, 1.34, -2.51), Vector3(1.28, 1.31, 0.14), INK)
		Kit.box(structure, Vector3(x, 1.36, -2.42), Vector3(1.14, 1.17, 0.07), GLASS)
		Kit.box(structure, Vector3(x, 1.51, -2.37), Vector3(1.14, 0.057, 0.02), WHITE)
		Kit.box(structure, Vector3(x, 0.65, -2.35), Vector3(1.35, 0.095, 0.43), WHITE)
	Kit.box(structure, Vector3(-4.52, 1.26, -2.5), Vector3(1.18, 2.05, 0.16), INK)
	Kit.box(structure, Vector3(-4.52, 1.44, -2.4), Vector3(0.92, 1.25, 0.07), GLASS)
	Kit.box(structure, Vector3(-4.86, 1.03, -2.34), Vector3(0.055, 0.34, 0.06), GOLD)
	Kit.box(structure, Vector3(-5.2, 2.26, -2.35), Vector3(5.4, 0.49, 0.23), INK)
	Kit.sign_text(structure, Vector3(-5.2, 2.26, -2.22), "NORTHPOINT", 0.49, WHITE)
	for i in range(20):
		Kit.box(structure, Vector3(-8.68, 0.48, -6.92 + i * 0.22), Vector3(0.035, 0.57, 0.105), Color("#9d7058"))

func canopy(level: int) -> void:
	var width := 8.5 + float(level - 1) * 0.62
	var depth := 4.25 + float(level - 1) * 0.24
	for x in [-2.65, 4.75]:
		Kit.box(structure, Vector3(x, 0.24, 0.52), Vector3(0.64, 0.48, 0.64), INK)
		Kit.box(structure, Vector3(x, 1.78, 0.52), Vector3(0.28, 3.28, 0.38), WHITE)
	var frame := Node3D.new()
	structure.add_child(frame)
	frame.position = Vector3(1.05, 0, 0.68)
	Kit.loft(frame, [Vector4(3.28, width / 2 - 0.12, depth / 2 - 0.12, 0),
		Vector4(3.42, width / 2, depth / 2, 0), Vector4(3.69, width / 2, depth / 2, 0),
		Vector4(3.83, width / 2 - 0.24, depth / 2 - 0.23, 0)], TEAL)
	Kit.box(frame, Vector3(0, 3.48, depth / 2 + 0.02), Vector3(width - 0.1, 0.13, 0.07), GOLD)
	Kit.box(frame, Vector3(0, 3.71, -0.35), Vector3(width - 0.6, 0.2, depth - 1.26), INK)
	for i in range(level):
		var x := float(i) * 0.73 - float(level - 1) * 0.365
		Kit.box(frame, Vector3(x, 3.83, -0.38), Vector3(0.66, 0.16, 1.5), Color("#5da099"))
		for j in range(4):
			Kit.box(frame, Vector3(x, 3.916, -0.91 + j * 0.35), Vector3(0.62, 0.01, 0.025), INK)

func pump(level: int) -> void:
	Kit.box(structure, Vector3(1.05, 0.11, 0.53), Vector3(3.6, 0.22, 1.16), WHITE)
	Kit.box(structure, Vector3(1.05, 0.62, 0.53), Vector3(0.85, 1.02, 0.53), TEAL)
	Kit.box(structure, Vector3(1.05, 1.24, 0.53), Vector3(0.95, 0.49, 0.58), GOLD)
	Kit.box(structure, Vector3(1.05, 1.28, 0.83), Vector3(0.67, 0.27, 0.04), INK)
	meter = Kit.box(structure, Vector3(1.05, 1.29, 0.86), Vector3(0.4, 0.085, 0.02), GOLD)
	Kit.beam(structure, Vector3(1.5, 1.15, 0.55), Vector3(1.75, 0.41, 0.55), 0.045, INK)
	Kit.beam(structure, Vector3(1.75, 0.41, 0.55), Vector3(1.76, 0.91, 0.8), 0.045, INK)
	for x in [-0.45, 2.55]:
		Kit.cylinder(structure, Vector3(x, 0.36, 0.89), 0.095, 0.095, 0.54, GOLD)
	if level >= 3:
		Kit.box(structure, Vector3(0.37, 0.68, 0.55), Vector3(0.23, 0.85, 0.29), INK)

func set_service_progress(progress: float) -> void:
	meter.scale.x = maxf(progress, 0.06)

func pylon(level: int) -> void:
	Kit.box(structure, Vector3(7.85, 1.78, 3.1), Vector3(0.32, 3.52, 0.35), INK)
	Kit.box(structure, Vector3(7.85, 3.22, 3.1), Vector3(1.53, 1.16, 0.31), TEAL)
	Kit.box(structure, Vector3(7.85, 3.79, 3.1), Vector3(1.53, 0.12, 0.34), GOLD)
	Kit.sign_text(structure, Vector3(7.85, 3.36, 3.27), "FUEL", 0.49, WHITE)
	Kit.sign_text(structure, Vector3(7.85, 2.98, 3.27), "RTE 17", 0.29, GOLD)
	if level >= 4:
		Kit.box(structure, Vector3(7.85, 2.38, 3.1), Vector3(1.31, 0.48, 0.29), INK)
		Kit.sign_text(structure, Vector3(7.85, 2.38, 3.26), "24 / 7", 0.3, WHITE)
