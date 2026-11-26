extends Node3D

const Batch = preload("res://scripts/art/scenery_batch.gd")
const Art = preload("res://scripts/art/visual_library.gd")
const Kit = preload("res://scripts/buildings/model_kit.gd")
const Routes = preload("res://data/world/desert_routes.gd")
const GROUND = preload("res://assets/materials/desert_ground.gdshader")
const STONE := Color("#bd9373")
const WHITE := Color("#f8e1b9")
const LANE := Color("#e7b76a")

var pavement: ShaderMaterial
var markings := Node3D.new()

func _ready() -> void:
	var sand := finish("#bc865d", "#f2ce96")
	pavement = finish("#4d514d", "#79726a", .45)
	surface(Vector3(4, -.095, -13), Vector2(232, 158), sand)
	surface(Vector3(4, -.055, 11.3), Vector2(156, 10.1), finish("#51524d", "#767166", .83))
	surface(Vector3(4, -.034, 11.3), Vector2(154, .12), finish("#a97949", "#dfaa69"))
	stretch(Vector3(4, -.031, 3.72), Vector2(66, 6.1))
	stretch(Vector3(-28.3, -.032, -3.7), Vector2(5.9, 22.0))
	stretch(Vector3(52.3, -.032, -2.7), Vector2(9.0, 29.0))
	stretch(Vector3(32.4, -.03, -13.15), Vector2(46, 10.4))
	stretch(Vector3(-8.1, -.031, -12.90), Vector2(47, 9.5))
	stretch(Vector3(-30.9, -.034, 6.1), Vector2(8.5, 8.5))
	stretch(Vector3(32.55, -.033, 6.25), Vector2(8.3, 7.0))
	for id in Routes.BAYS:
		var middle: Vector3 = Routes.BAYS[id][0].lerp(Routes.BAYS[id][-1], .5)
		var span: float = absf(Routes.BAYS[id][0].x - Routes.BAYS[id][-1].x)
		stretch(Vector3(middle.x, -.018, middle.z), Vector2(span + 5.4, 7.6 if Routes.is_truck(id) else 5.5))
	add_child(markings)
	paint_road()
	build_geology()
	build_roadside_furniture()
	for at in [Vector3(3.9, 0, 5.0), Vector3(-24.5, 0, 5.6), Vector3(49.2, 0, 3.3)]:
		Art.place(self, "desert", "pylon", at)
		Art.sign(self, at + Vector3(.13, 3.52, .295), "COPPER MILE", .225, WHITE)
		Art.sign(self, at + Vector3(.025, 2.59, .23), "HIGHWAY  66", .186, WHITE)
	Batch.compact(self)


func stretch(at: Vector3, size: Vector2) -> void:
	surface(at, size, pavement)

func surface(at: Vector3, size: Vector2, mat: Material) -> void:
	Art.plane(self, at, size, mat)

func finish(base: String, highlight: String, tracks := 0.0) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = GROUND
	mat.set_shader_parameter("aggregate", preload("res://assets/textures/paving_noise.png"))
	mat.set_shader_parameter("base", Color(base))
	mat.set_shader_parameter("accent", Color(highlight))
	mat.set_shader_parameter("trail", tracks)
	return mat

func paint_road() -> void:
	var strip := BoxMesh.new()
	strip.size = Vector3.ONE
	var paint := MultiMesh.new()
	paint.transform_format = MultiMesh.TRANSFORM_3D
	paint.mesh = strip
	var points: Array[Transform3D] = []
	for x in range(-73, 78, 4):
		for z in [8.05, 14.55]:
			points.append(Transform3D(Basis.from_scale(Vector3(2.35, .012, .081)), Vector3(x, -.001, z)))
	for x in range(-24, 25, 4):
		points.append(Transform3D(Basis.from_scale(Vector3(1.70, .012, .062)), Vector3(x, .001, 3.70)))
	for id in Routes.BAYS:
		for bay: Vector3 in Routes.BAYS[id]:
			var drag := 6.7 if Routes.is_truck(id) else 3.18
			var side := 1.51 if Routes.is_truck(id) else .98
			for direction in [-1, 1]:
				points.append(Transform3D(Basis.from_scale(Vector3(.065, .014, drag)), bay + Vector3(side * direction, -.022, 0)))
	paint.instance_count = points.size()
	for i in points.size():
		paint.set_instance_transform(i, points[i])
	var strokes := MultiMeshInstance3D.new()
	strokes.multimesh = paint
	strokes.material_override = Kit.material(WHITE)
	strokes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	markings.add_child(strokes)
	for z in [6.54, 16.06]:
		Kit.box(self, Vector3(4, -.002, z), Vector3(150, .019, .16), LANE)
	for point in [Vector3(-25, 0, 3.7), Vector3(6.6, 0, 5.28), Vector3(47.3, 0, -9.9)]:
		var arrow := Art.sign(self, point, "«", 0.70, WHITE)
		arrow.rotation.x = -PI * .5

func build_geology() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 361105
	var rocks: Array[Transform3D] = []
	for i in 31:
		var x := -55.0 + i * 3.99 + random.randf_range(-.91, .91)
		var y := 1.3 + .79 * sin(i * .44) + random.randf_range(.35, 1.05)
		var z := -39.0 - (6.0 * cos(i * .44))
		var scale := Vector3(.94 + y * .64, y, 1.6 + .37 * y)
		rocks.append(placed(Vector3(x, -.26, z), scale, random.randf_range(-PI, PI)))
	for i in 18:
		var x := -38.4 - random.randf_range(0, 12) if i % 2 == 0 else 53.5 + random.randf_range(0, 11)
		var z := random.randf_range(-32, 5)
		var q := random.randf_range(.42, 1.63)
		rocks.append(placed(Vector3(x, -.095, z), Vector3(q, q * .76, q), random.randf_range(-PI, PI)))
	instances("buttress", rocks)
	var cacti: Array[Transform3D] = []
	var agaves: Array[Transform3D] = []
	for i in 124:
		var x := random.randf_range(-57, 63)
		var z := random.randf_range(-41, 22)
		var roadside := z > 17.8 or z < -28.7 or x < -35 or x > 55.5
		if not roadside or (z > 6.1 and z < 17.8):
			continue
		var q := random.randf_range(.30, 1.13)
		var entry := placed(Vector3(x, -.08, z), Vector3(q, q, q), random.randf_range(-PI, PI))
		if i % 3 == 0:
			cacti.append(entry)
		else:
			agaves.append(entry)
	for point in [Vector3(-8.1, 0, -5.83), Vector3(-6.70, 0, -6.15), Vector3(6.5, 0, -5.55),
		Vector3(15.70, 0, -6.75), Vector3(-26.8, 0, -4.33), Vector3(19, 0, -21.0)]:
		agaves.append(placed(point, Vector3.ONE, 0.2))
	instances("saguaro", cacti)
	instances("agave", agaves)

func placed(at: Vector3, scale: Vector3, angle: float) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, angle).scaled(scale), at)

func build_roadside_furniture() -> void:
	for point in [Vector3(-7.9, 0, -1.18), Vector3(6.2, 0, -2.48), Vector3(1.5, 0, -5.57),
		Vector3(-18.2, 0, -6.0), Vector3(17.1, 0, -3.5), Vector3(-25, 0, -.8), Vector3(20.4, 0, -22.1),
		Vector3(20.2, 0, -5.4), Vector3(-5.6, 0, -25.7), Vector3(8.2, 0, -22.6)]:
		Art.place(self, "desert", "median_planter", point, .12 * sin(point.x))
		Art.contact(self, point + Vector3(0, -.019, 0), 3.60, 1.95)
	for x in [-23.5, -15.7, -7.6, 9.1, 17.0, 24.0]:
		var point := Vector3(x, 0, 6.35)
		Art.place(self, "desert", "barrier", point)
	for point in [Vector3(-22.7, 0, 5.86), Vector3(7.28, 0, 5.74), Vector3(19.1, 0, 5.92),
		Vector3(-26.7, 0, -7.85), Vector3(51.35, 0, -18.7)]:
		Art.place(self, "desert", "highway_lamp", point, -PI * .5)

func instances(id: String, entries: Array[Transform3D]) -> void:
	Batch.instances(self, Art.extract_mesh("desert", id), entries)


func set_forecourt_tier(tier: int) -> void:
	pavement.set_shader_parameter("trail", clampf(1.10 - float(tier) * .18, .14, .92))
