extends Node3D

const Kit = preload("res://scripts/buildings/model_kit.gd")
const GROUND = preload("res://assets/materials/ground.gdshader")
const GRAVEL := Color("#d4ba93")
const ROAD := Color("#425258")
const PAINT := Color("#dfd39e")

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 174126
	ground(Vector3(0, -0.28, 0), Vector3(160, 0.46, 140), Color("#728250"), 0.38)
	Kit.box(self, Vector3(0, -0.065, 10.5), Vector3(150, 0.1, 8.6), GRAVEL)
	ground(Vector3(0, -0.035, 10.5), Vector3(150, 0.068, 7.35), ROAD, 0.3)
	Kit.box(self, Vector3(0, -0.081, -0.34), Vector3(21, 0.155, 13.7), GRAVEL)
	ground(Vector3(0.2, -0.025, 2.4), Vector3(17.7, 0.045, 6.45), Color("#a39783"), 0.4)
	for x in [-8.0, 7.4]:
		ground(Vector3(x, -0.022, 5.8), Vector3(4.2, 0.04, 3.1), Color("#a39783"), 0.4)
	for x in range(-36, 38, 3):
		Kit.box(self, Vector3(x, 0.003, 10.5), Vector3(1.53, 0.006, 0.1), PAINT)
	for z in [7.14, 13.86]:
		Kit.box(self, Vector3(0, 0.004, z), Vector3(100, 0.007, 0.075), PAINT)
	for i in range(6):
		var x := -8.25 + i * 1.17
		Kit.box(self, Vector3(x, 0.003, -0.66), Vector3(0.045, 0.008, 1.81), PAINT)
	for x in [-8.8, -4.8, -0.8, 3.2, 7.2]:
		Kit.box(self, Vector3(x, 0.05, -7.21), Vector3(3.88, 0.12, 0.34), Color("#b3a687"))
		fence(Vector3(x, 0, -7.3))
	for pos in [Vector3(-10.1, 0, -5.5), Vector3(9.6, 0, -3.1), Vector3(8.8, 0, 5.4)]:
		lamp(pos)
	for i in range(92):
		var x := rng.randf_range(-35, 35)
		var z := rng.randf_range(-30, 20)
		if z > 5.85 and z < 15.35:
			continue
		if absf(x) < 11.0 and z > -8.1 and z < 6.1:
			continue
		if i % 4 == 0:
			tree(Vector3(x, 0, z), rng.randf_range(0.79, 1.4))
		else:
			var radius := rng.randf_range(0.22, 0.91)
			rock(Vector3(x, 0.1, z), radius, Color("#71875f") if i % 2 == 0 else Color("#a3a783"))
	for pos in [Vector3(-11.8, 0, -5.7), Vector3(-10.7, 0, -9.1), Vector3(7.7, 0, -8.8),
		Vector3(11.7, 0, -5.8), Vector3(13.1, 0, 0.8), Vector3(-13, 0, 1.3),
		Vector3(9.1, 0, 17.5), Vector3(-7.6, 0, 17.3)]:
		tree(pos, rng.randf_range(0.86, 1.15))

	for i in range(32):
		var x := rng.randf_range(-13.5, 13.5)
		var z := rng.randf_range(-13.0, -8.3) if i % 3 else rng.randf_range(15.2, 19.0)
		rock(Vector3(x, -0.02, z), rng.randf_range(0.15, 0.42), Color("#547557"))
	for x in [-8.8, -4.5, 5.2, 9.0]:
		Kit.box(self, Vector3(x, 0.018, 6.32), Vector3(1.6, 0.02, 0.14), PAINT)

func ground(pos: Vector3, size: Vector3, tint: Color, contrast: float) -> void:
	var part := Kit.box(self, pos, size, tint)
	var surface := ShaderMaterial.new()
	surface.shader = GROUND
	surface.set_shader_parameter("tint", tint)
	surface.set_shader_parameter("contrast", contrast)
	part.material_override = surface

func lamp(pos: Vector3) -> void:
	var metal := Color("#536264")
	Kit.cylinder(self, pos + Vector3(0, 1.34, 0), 0.065, 0.055, 2.68, metal)
	Kit.beam(self, pos + Vector3(0, 2.62, 0), pos + Vector3(0, 2.76, 0.65), 0.05, metal)
	Kit.box(self, pos + Vector3(0, 2.74, 0.67), Vector3(0.32, 0.13, 0.49), metal)
	Kit.box(self, pos + Vector3(0, 2.659, 0.67), Vector3(0.23, 0.045, 0.36), Color("#ffe9a3"))

func fence(pos: Vector3) -> void:
	var wood := Color("#a47b5c")
	for x in [-1.86, 1.86]:
		Kit.box(self, pos + Vector3(x, 0.38, 0), Vector3(0.15, 0.76, 0.17), wood)
	for y in [0.29, 0.55]:
		Kit.box(self, pos + Vector3(0, y, 0), Vector3(3.84, 0.11, 0.11), wood)

func rock(pos: Vector3, radius: float, tint: Color) -> void:
	var stone := SphereMesh.new()
	stone.radius = radius
	stone.height = radius * 1.1
	stone.radial_segments = 7
	stone.rings = 3
	Kit.mesh(self, stone, pos, tint).rotation.y = pos.x

func tree(pos: Vector3, size: float) -> void:
	Kit.cylinder(self, pos + Vector3(0, 0.72 * size, 0), size * 0.175, size * 0.08, 1.44 * size, Color("#79634f"), 7)
	for i in range(3):
		var radius := size * (1.02 - i * 0.23)
		var height := size * (1.3 - i * 0.16)
		var leaf := Kit.cylinder(self, pos + Vector3(0, size * (1.45 + i * 0.54), 0),
			radius, radius * 0.17, height, [Color("#416953"), Color("#527d5d"), Color("#65916a")][i], 8)
		leaf.rotation.y = pos.x + float(i) * 0.3
