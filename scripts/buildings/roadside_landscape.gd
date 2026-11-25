extends Node3D

const Art = preload("res://scripts/art/visual_library.gd")
const Kit = preload("res://scripts/buildings/model_kit.gd")
const GROUND = preload("res://assets/materials/ground.gdshader")
const CONTACT = preload("res://assets/materials/contact.gdshader")
const PAVING_NOISE = preload("res://assets/textures/paving_noise.png")
const WATER = preload("res://assets/materials/retention_water.gdshader")
const WIND = preload("res://assets/materials/foliage_wind.gdshader")
const POND_AT := Vector3(3.5, -0.007, -26.55)
const POND_SCALE := Vector3(12.2, 1.0, 4.50)
const CREAM := Color("#ece4ba")
const WHITE := Color("#e4e5d3")
const GOLD := Color("#e7bb69")
const CURB := Color("#b9b9a5")

var rng := RandomNumberGenerator.new()
var stamps: Dictionary = {}
var breeze := ShaderMaterial.new()
var terrain_finish: Material

func _ready() -> void:
	rng.seed = 174126
	breeze.shader = WIND
	var plain := ground(Vector3(0, -0.35, -2), Vector3(162, 0.61, 132),
		Color("#8e9d5e"), Color("#bea67e"), 0.20)
	terrain_finish = plain.material_override
	pavement()
	road_marking()
	furniture()
	scenic_edge()
	planting()
	for tint in stamps:
		var shape := BoxMesh.new()
		shape.size = Vector3.ONE
		batch(shape, stamps[tint], Kit.material(tint), false)

func pavement() -> void:
	var blacktop := Color("#56626d")
	var worn := Color("#737a78")
	var concrete := Color("#a5a291")
	var paving := Color("#b8a487")
	ground(Vector3(23.15, -0.023, 5.53), Vector3(25.85, 0.049, 3.38), blacktop, worn, 0.11)
	ground(Vector3(32.13, -0.028, -4.01), Vector3(30.78, 0.048, 15.17), concrete, worn, 0.11)
	ground(Vector3(46.11, -0.015, 3.16), Vector3(4.24, 0.030, 11.82), blacktop, worn, 0.10)
	ground(Vector3(36.86, -0.017, 3.07), Vector3(3.44, 0.035, 11.51), blacktop, worn, 0.10)
	ground(Vector3(0, -0.035, 10.50), Vector3(127.0, 0.053, 8.64), concrete, paving, 0.11)
	ground(Vector3(0, -0.016, 10.50), Vector3(127.0, 0.036, 7.34), blacktop, worn, 0.21, 0.65, Vector2.ZERO, true)
	ground(Vector3(-0.4, -0.041, -1.70), Vector3(21.27, 0.075, 14.08), concrete, paving, 0.12, 0.87)
	ground(Vector3(0.08, -0.01, 2.21), Vector3(17.58, 0.029, 6.67),
		Color("#929d97"), Color("#b3a78e"), 0.19, 0.59)
	for x in [-8.96, 7.37]:
		ground(Vector3(x, -0.010, 5.73), Vector3(4.10, 0.036, 2.51),
			Color("#929d97"), Color("#b3a78e"), 0.19, 0.59)
	ground(Vector3(-6.12, -0.004, -1.15), Vector3(7.96, 0.047, 1.36),
		Color("#bdab92"), Color("#cfba98"), 0.081, 0.43, Vector2(0.62, 0.41))
	ground(Vector3(-12.08, -0.014, -3.51), Vector3(2.92, 0.035, 20.78), blacktop, worn, 0.11, 0.67)
	ground(Vector3(-1.40, -0.013, -11.79), Vector3(27.30, 0.037, 2.75), blacktop, worn, 0.10, 0.62)
	ground(Vector3(12.01, -0.013, -2.59), Vector3(3.13, 0.037, 18.97), blacktop, worn, 0.1, 0.62)
	for pos in [Vector3(-15.65, -0.019, -4.78), Vector3(-7.89, -0.012, -13.50),
		Vector3(8.48, -0.012, -13.62), Vector3(11.46, -0.012, -5.19)]:
		ground(pos, Vector3(6.4, 0.034, 2.42),
			Color("#aaa08a"), Color("#c4ae8e"), 0.104, 0.63, Vector2(0.68, 0.451))
	ground(Vector3(-19.44, -0.018, -4.66), Vector3(14.34, 0.036, 4.90), concrete, paving, 0.11)
	for edge in [-25.83, -22.97, -20.11]:
		stamp(Vector3(edge, 0.015, -5.75), Vector3(0.074, 0.016, 3.32), WHITE)
	ground(Vector3(-7.10, -0.007, -8.95), Vector3(7.88, 0.039, 4.11), concrete, paving, 0.11)
	for edge in [-10.87, -8.46, -5.88, -3.24]:
		stamp(Vector3(edge, 0.016, -8.60), Vector3(0.074, 0.016, 2.84), WHITE)
	for pair in [[-7.13, 3.92], [-1.08, 4.52], [4.83, 3.4]]:
		ground(Vector3(pair[0], -0.003, -8.17), Vector3(pair[1], 0.051, 1.19),
			Color("#acac91"), Color("#bea98b"), 0.1, 0.64, Vector2(0.53, 0.36))

func road_marking() -> void:
	for i in range(-18, 19):
		stamp(Vector3(i * 3.33, 0.008, 10.5), Vector3(1.55, 0.013, 0.084), CREAM)
	for x in [15.8, 20.75, 25.70, 30.65]:
		stamp(Vector3(x + 2.25, 0.014, 5.41), Vector3(0.10, 0.015, 1.78), WHITE)
	for z in [-2.15, -5.21, -8.54, -11.55]:
		stamp(Vector3(25.6, 0.011, z), Vector3(11.80, 0.015, 0.083), GOLD)
	for z in [7.10, 13.90]:
		stamp(Vector3(0, 0.011, z), Vector3(87.4, 0.013, 0.083), WHITE)
		stamp(Vector3(0, -0.001, z + signf(z - 10.5) * 0.34), Vector3(89, 0.015, 0.07), Color("#777d6d"))
	for x in [-6.15, -3.06, 0.0, 3.04, 9.93]:
		stamp(Vector3(x, 0.048, 5.68), Vector3(2.85 if x < 9.0 else 0.52, 0.101, 0.22), CURB)
	for i in range(33):
		var x := -8.6 + i * 0.44
		if x < -5.96 or x > -4.95:
			stamp(Vector3(x, 0.053, -0.47), Vector3(0.428, 0.105, 0.165), CURB)
	for i in range(7):
		stamp(Vector3(-9.63 + i * 1.18, 0.019, 0.54), Vector3(0.071, 0.014, 1.80), WHITE)
	for i in range(5):
		stamp(Vector3(-6.51 + i * 0.21, 0.017, 1.68), Vector3(0.093, 0.012, 1.81), CREAM)
		stamp(Vector3(-12.84 + i * 0.375, 0.012, -4.8), Vector3(0.19, 0.013, 1.28), WHITE)
	for x in [-8.98, 7.46]:
		stamp(Vector3(x, 0.026, 4.5), Vector3(0.09, 0.016, 0.96), WHITE)
		stamp(Vector3(x - 0.17, 0.026, 4.85), Vector3(0.09, 0.016, 0.46), WHITE, -0.75)
		stamp(Vector3(x + 0.17, 0.026, 4.85), Vector3(0.09, 0.016, 0.46), WHITE, 0.75)
	for x in [-9.80, -1.41, 5.70, 9.78]:
		for j in range(3):
			stamp(Vector3(x + (j - 1) * 0.22, 0.016, -10.57),
				Vector3(0.088, 0.014, 0.41), WHITE)
	for x in [-13.83, 13.88]:
		for i in range(5):
			stamp(Vector3(x, 0.014, 2.43 - i * 2.78), Vector3(0.1, 0.012, 1.1), GOLD)

func furniture() -> void:
	var lamp_positions: Array[Transform3D] = []
	for pos in [Vector3(-11.15, 0, 4.78), Vector3(10.22, 0, 2.81),
		Vector3(16.40, 0, 3.1), Vector3(-19.5, 0, 7.08),
		Vector3(12.92, 0, -9.78), Vector3(-12.72, 0, -12.79),
		Vector3(5.5, 0, -11.25), Vector3(-3.09, 0, 14.8), Vector3(11.28, 0, 14.8)]:
		lamp_positions.append(transform_at(pos, PI if pos.z > 14.0 else 0.0, 1.0))
	batch(Art.extract_mesh("landscape", "lamp"), lamp_positions)
	var rail_transforms: Array[Transform3D] = []
	for z in [6.48, 14.91]:
		for x in ([-24.1, -20.12, -16.14] if z < 8.0 else [-24.1, -20.12, -16.14, 17.8, 21.78, 25.76]):
			rail_transforms.append(transform_at(Vector3(x, 0.0, z), 0.0, 1.0))
	for x in [19.06, 23.04, 27.02, 31.0, 34.98, 38.96, 42.94]:
		rail_transforms.append(transform_at(Vector3(x, 0.0, -12.51), 0.0, 1.0))
	batch(Art.extract_mesh("landscape", "rail"), rail_transforms)
	var freight_stores: Array[Transform3D] = [transform_at(Vector3(18.18, 0, -11.47), 0.18, 1.16),
		transform_at(Vector3(28.38, 0, -12.12), 0.05, 1.08), transform_at(Vector3(12.68, 0, -15.71), -PI * 0.5, 0.79)]
	batch(Art.extract_mesh("landscape", "service_yard"), freight_stores)
	var sign_board := Art.place(self, "landscape", "billboard", Vector3(16.89, 0, 0.92), -0.17)
	Art.sign(sign_board, Vector3(0, 2.93, 0.178), "NORTHPOINT", 0.43, CREAM)
	Art.sign(sign_board, Vector3(0, 2.592, 0.179), "ROUTE 17   /   500 m", 0.175, GOLD)
	var route := Art.place(self, "landscape", "route_sign", Vector3(-10.52, 0.01, 5.22), 0.11)
	Art.sign(route, Vector3(0.0, 1.758, 0.127), "R17  ↑", 0.28, CREAM)
	Art.sign(route, Vector3(0.0, 1.128, 0.113), "←  P", 0.25, Color("#213c3f"))
	var wires: Array[Transform3D] = []
	var wire_point := Vector3(-22.0, 0.0, -10.62)
	for i in range(4):
		var next := Vector3(-22.0 + i * 13.65, 0.0, -10.62)
		Art.place(self, "landscape", "pole", next)
		if i > 0:
			for dz in [-0.54, 0.43]:
				var start := wire_point + Vector3(0, 4.24, dz)
				for j in range(1, 6):
					var t := j / 5.0
					var end := wire_point.lerp(next, t) + Vector3(0, 4.24 - sin(t * PI) * 0.63, dz)
					var span := end - start
					var frame := Basis(Quaternion(Vector3.UP, span.normalized()))
					wires.append(Transform3D(frame.scaled_local(Vector3(1, span.length(), 1)), (start + end) * 0.5))
					start = end
		wire_point = next
	var cable := CylinderMesh.new()
	cable.height = 1.0
	cable.top_radius = 0.019
	cable.bottom_radius = 0.019
	cable.radial_segments = 6
	cable.rings = 0
	batch(cable, wires, Kit.material(Color("#465a4f")), false)

func scenic_edge() -> void:
	for profile in [[Vector3(-23.07, 0.0, -24.1), Vector3(10.2, 2.14, 5.2), -0.16],
		[Vector3(25.46, 0.0, -24.16), Vector3(9.7, 2.40, 6.2), 0.32],
		[Vector3(14.61, -0.02, 19.60), Vector3(7.0, 0.32, 2.72), 0.07]]:
		var hill := Art.place(self, "landscape", "bank", profile[0], profile[2])
		hill.scale = profile[1]
		(hill.find_child("Bank", true, false) as MeshInstance3D).material_override = terrain_finish
		var trees: Array[Transform3D] = [transform_at(profile[0] + Vector3(-1.56, profile[1].y * 0.77, 0.19), -0.8, 0.71),
			transform_at(profile[0] + Vector3(1.63, profile[1].y * 0.77, -0.32), 1.40, 0.88)]
		if profile[1].y > 1.0:
			batch(Art.extract_mesh("landscape", "pine"), trees)
	var pond := Art.place(self, "landscape", "wetland", POND_AT)
	pond.scale = POND_SCALE
	var surface := ShaderMaterial.new()
	surface.shader = WATER
	var water := pond.find_child("Water", true, false) as MeshInstance3D
	water.material_override = surface
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var marsh: Array[Transform3D] = []
	for degrees in [11, 18, 36, 55, 65, 73, 126, 138, 148, 169, 210, 222, 258, 273, 308, 326]:
		var angle := deg_to_rad(degrees)
		var ripple := 0.948 * (1.0 + 0.081 * sin(3.0 * angle + 0.5) + 0.062 * cos(5.0 * angle))
		var at := POND_AT + Vector3(cos(angle) * POND_SCALE.x * ripple, 0.042, sin(angle) * POND_SCALE.z * ripple)
		marsh.append(transform_at(at, angle, rng.randf_range(0.66, 1.04)))
	batch(Art.extract_mesh("landscape", "reeds"), marsh, breeze, false)
	Art.place(self, "landscape", "overlook", Vector3(-3.68, -0.034, 18.67), -0.11)
	ground(Vector3(-3.68, -0.043, 16.56), Vector3(8.75, 0.031, 1.54),
		Color("#bfb198"), Color("#cfbd92"), 0.22, 0.50, Vector2(0.68, 0.46))
	var cacti: Array[Transform3D] = []
	for at in [Vector3(-7.33, -0.04, 17.9), Vector3(-6.89, -0.04, 19.1), Vector3(2.93, -0.04, 16.21),
		Vector3(3.51, -0.04, 16.96), Vector3(12.34, -0.04, 15.96), Vector3(16.7, -0.04, 18.01),
		Vector3(-25.7, -0.04, -10.94), Vector3(-23.28, -0.04, -10.61), Vector3(14.17, -0.04, -16.84)]:
		cacti.append(transform_at(at, rng.randf_range(-PI, PI), rng.randf_range(0.69, 1.22)))
	batch(Art.extract_mesh("landscape", "cactus"), cacti)

func planting() -> void:
	var plots := {
		"broadleaf": [Vector3(-11.0, 0, -7.7), Vector3(5.52, 0, -8.52),
			Vector3(-22, 0, -13.7), Vector3(16.0, 0, -14.8), Vector3(-9.9, 0, 16.56),
			Vector3(14.2, 0, 16.8), Vector3(17.70, 0.0, -1.1), Vector3(-4.2, 0.0, -19.6)],
		"golden_tree": [Vector3(-10.54, 0, -3.87), Vector3(15.94, 0, -8.09),
			Vector3(-22.4, 0, -8.9), Vector3(8.68, 0, 16.42), Vector3(-0.3, 0, -15.55),
			Vector3(20.72, 0, -12.58), Vector3(-17.52, 0, -16.10), Vector3(15.51, 0, -17.66)],
		"pine": [Vector3(-3.43, 0, -8.37), Vector3(7.04, 0, -7.40),
			Vector3(-9.42, 0, -14.44), Vector3(-18.16, 0, 3.32), Vector3(17.32, 0, 2.3),
			Vector3(1.14, 0, 17.10), Vector3(3.71, 0, 18.8), Vector3(1.04, 0, -15.10)],
		"hedge": [Vector3(-9.53, 0, -6.93), Vector3(-9.44, 0, -2.23),
			Vector3(8.25, 0, -1.64), Vector3(9.77, 0, 1.5), Vector3(9.93, 0, 4.83),
			Vector3(7.84, 0, 4.12), Vector3(-10.19, 0, -6.41), Vector3(0.03, 0, -8.52),
			Vector3(-19.31, 0, -4.1), Vector3(-2.11, 0, -14.27),
			Vector3(15.95, 0, -7.51), Vector3(8.41, 0, 15.82), Vector3(17.3, 0, -1.3),
			Vector3(-15.23, -0.03, -23.19), Vector3(20.60, 0.29, -21.91),
			Vector3(18.66, 0.05, 18.11), Vector3(-7.07, -0.025, 18.83)],
	}
	var contact_transforms: Array[Transform3D] = []
	for species in plots:
		var transforms: Array[Transform3D] = []
		for at in plots[species]:
			var factor := rng.randf_range(0.73, 1.08)
			transforms.append(transform_at(at, rng.randf_range(-PI, PI), factor))
			var size := factor * (2.2 if species == "hedge" else 5.0)
			contact_transforms.append(Transform3D(Basis.from_scale(Vector3(size, 1.0, size * 0.77)), at + Vector3(0, 0.016, 0)))
		batch(Art.extract_mesh("landscape", species), transforms)

	var grass: Array[Transform3D] = []
	var stones: Array[Transform3D] = []
	var distant_pines: Array[Transform3D] = []
	for i in range(236):
		var x := rng.randf_range(-32.0, 33.0)
		var z := rng.randf_range(-22.0, 22.0)
		if (z < 15.25 and z > 5.0) or (x > -27.6 and z > -19.85 and z <= 5.0):
			continue
		if x > -8.3 and x < 0.6 and z > 15.55 and z < 20.5:
			continue
		var at := Vector3(x, -0.032, z)
		if i % 9 == 0:
			stones.append(transform_at(at, rng.randf_range(-PI, PI), rng.randf_range(0.39, 1.05)))
		elif i % 7 == 0 and (absf(x) > 21.1 or z < -19.2):
			distant_pines.append(transform_at(at, rng.randf_range(-PI, PI), rng.randf_range(0.69, 1.07)))
		else:
			grass.append(transform_at(at, rng.randf_range(-PI, PI), rng.randf_range(0.55, 1.18)))
	for at in [Vector3(1.21, -0.03, 16.8), Vector3(-9.31, -0.03, 16.23),
		Vector3(7.58, -0.02, -8.92), Vector3(6.87, -0.025, 15.96)]:
		stones.append(transform_at(at, rng.randf_range(-PI, PI), 0.86))
	batch(Art.extract_mesh("landscape", "meadow"), grass, breeze, false)
	batch(Art.extract_mesh("landscape", "stone"), stones)
	batch(Art.extract_mesh("landscape", "pine"), distant_pines)
	var blur := PlaneMesh.new()
	blur.size = Vector2.ONE
	var shadow := ShaderMaterial.new()
	shadow.shader = CONTACT
	shadow.set_shader_parameter("opacity", 0.37)
	batch(blur, contact_transforms, shadow, false)

func ground(at: Vector3, size: Vector3, tint: Color, accent: Color, grain: float, field := 1.0,
		tile := Vector2.ZERO, highway := false) -> MeshInstance3D:
	var piece := BoxMesh.new()
	piece.size = size
	var surface := ShaderMaterial.new()
	surface.shader = GROUND
	surface.set_shader_parameter("tint", tint)
	surface.set_shader_parameter("accent", accent)
	surface.set_shader_parameter("grain", grain)
	surface.set_shader_parameter("field", field)
	surface.set_shader_parameter("tile", tile)
	surface.set_shader_parameter("paving_noise", PAVING_NOISE)
	surface.set_shader_parameter("highway", highway)
	var instance := MeshInstance3D.new()
	instance.mesh = piece
	instance.material_override = surface
	instance.position = at
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	return instance

func stamp(at: Vector3, size: Vector3, tint: Color, yaw := 0.0) -> void:
	if not stamps.has(tint):
		var placements: Array[Transform3D] = []
		stamps[tint] = placements
	stamps[tint].append(Transform3D(Basis(Vector3.UP, yaw).scaled_local(size), at))

func transform_at(at: Vector3, yaw: float, scale: float) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scale), at)

func batch(mesh: Mesh, transforms: Array[Transform3D], surface: Material = null, shadows := true) -> void:
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = mesh
	instances.instance_count = transforms.size()
	for index in range(transforms.size()):
		instances.set_instance_transform(index, transforms[index])
	var group := MultiMeshInstance3D.new()
	group.multimesh = instances
	group.material_override = surface
	if not shadows:
		group.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(group)
