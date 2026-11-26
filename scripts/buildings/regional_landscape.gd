extends Node3D

const Batch = preload("res://scripts/art/scenery_batch.gd")
const Art = preload("res://scripts/art/visual_library.gd")
const Kit = preload("res://scripts/buildings/model_kit.gd")
const GROUND = preload("res://assets/materials/desert_ground.gdshader")
const FOLIAGE = preload("res://assets/materials/regional_foliage.gdshader")
const WATER = preload("res://assets/materials/regional_water.gdshader")
const SURFACES := {
	"valley": ["#6d8557", "#a1ad70", "#586160", "#7f8271"],
	"alpine": ["#a2b4bd", "#dde6e7", "#545b65", "#7b858a"],
	"ocean": ["#c3a87d", "#edd6a6", "#59696d", "#8d9290"],
	"metro": ["#6f8075", "#a3aa85", "#4c5963", "#747e7f"],
}

var routes: RefCounted
var pavement: ShaderMaterial
var paint: Array[Transform3D] = []
var rng := RandomNumberGenerator.new()

func _init(course: RefCounted) -> void:
	routes = course
	rng.seed = hash(course.district) + 1279

func _ready() -> void:
	var region: String = routes.district
	var pigments: Array = SURFACES[region]
	pavement = surface(pigments[2], pigments[3], .66)
	Art.plane(self, Vector3(0, -.12, 0), Vector2(260, 178), surface(pigments[0], pigments[1]))
	roadway("car", 5.05, true)
	if routes.layout.has("truck"):
		roadway("truck", 7.65, false)
	var ambient: float = routes.layout.ambient
	public_road(ambient, 8.7 if region != "metro" else 13.0, region == "metro")
	for id in routes.layout.plots:
		build_plot(id)
	street_signs(ambient)
	match region:
		"valley": valley()
		"alpine": alpine()
		"ocean": ocean()
		"metro": metro()
	var strip := BoxMesh.new()
	strip.size = Vector3.ONE
	instances(strip, paint, Kit.material(Color("#e9daba")), false)
	Batch.compact(self)


func surface(a: String, b: String, wear := 0.0) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = GROUND
	mat.set_shader_parameter("base", Color(a))
	mat.set_shader_parameter("accent", Color(b))
	mat.set_shader_parameter("trail", wear)
	return mat

func roadway(lane: String, width: float, paint_edges: bool) -> void:
	var center: Array = routes.centerline(lane)
	var from := Vector3(routes.exit_x(lane) - 5.0, 0, center[0].y)
	var asphalt: Array[Vector3] = [from]
	for point: Vector2 in center:
		asphalt.append(Vector3(point.x, 0, point.y))
	asphalt.append(routes.entrance(lane) + Vector3(6, 0, 0))
	var outer := surface("#8a8b78", "#a6a291", .0)
	ribbon(asphalt, width + .84, -.061, outer)
	ribbon(asphalt, width, -.039, pavement)
	for index in range(1, asphalt.size()):
		var a := asphalt[index - 1]
		var b := asphalt[index]
		var forward := a.direction_to(b)
		var edge := forward.cross(Vector3.UP) * (width * .5 - .24)
		if paint_edges:
			for side in [-1, 1]:
				paint.append(stroke(a + side * edge, b + side * edge, .065))
		else:
			for length in range(2, floori(a.distance_to(b)), 5):
				var p := a + forward * length
				paint.append(stroke(p, p + forward * 2.6, .095))

func ribbon(path: Array[Vector3], width: float, elevation: float, mat: Material) -> void:
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	var right: Array[Vector3] = []
	var left: Array[Vector3] = []
	for i in path.size():
		var p := path[i]
		p.y = elevation
		var prior := (path[i] - path[i - 1]).normalized() if i > 0 else path[0].direction_to(path[1])
		var after := (path[i + 1] - path[i]).normalized() if i < path.size() - 1 else prior
		var normal := (prior + after).normalized().cross(Vector3.UP)
		var half_width := .5 * width / maxf(.75, normal.dot(after.cross(Vector3.UP)))
		right.append(p + normal * half_width)
		left.append(p - normal * half_width)
	for i in range(right.size() - 1):
		for point in [right[i], left[i], left[i + 1], right[i], left[i + 1], right[i + 1]]:
			builder.set_normal(Vector3.UP)
			builder.add_vertex(point)
	var road := MeshInstance3D.new()
	road.mesh = builder.commit()
	road.material_override = mat
	road.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(road)

func public_road(z: float, width: float, metro: bool) -> void:
	Art.plane(self, Vector3(0, -.083, z), Vector2(217, width + 1.36), surface("#a2a18b", "#b1a995"))
	Art.plane(self, Vector3(0, -.067, z), Vector2(216, width), surface("#4a5458", "#788180", .86))
	for x in range(-100, 110, 5):
		for lane in ([-3.2, 3.2] if metro else [0.0]):
			paint.append(stroke(Vector3(x, -.045, z + lane), Vector3(x + 2.65, -.045, z + lane), .115))
	if metro:
		for line in [-.29, .29]:
			paint.append(stroke(Vector3(-95, -.049, z + line), Vector3(95, -.049, z + line), .115))
	for side in [-1, 1]:
		var rim: float = z + (width * .5 - .28) * side
		paint.append(stroke(Vector3(-105, -.045, rim), Vector3(105, -.045, rim), .10))
	# The far turnoff is shared by the physical queue and the illustrated public road.
	var gate: Vector3 = routes.entrance("car")
	var turn := [Vector3(gate.x - 1.5, 0, gate.z), Vector3(gate.x + 5, 0, gate.z + 2.8),
		Vector3(gate.x + 7.2, 0, z)]
	var link: Array[Vector3] = []
	link.assign(turn)
	ribbon(link, 4.45, -.061, pavement)

func build_plot(id: String) -> void:
	var at: Vector3 = routes.origin(id)
	var lanes: Array = routes.layout.plots[id]
	var heavy: bool = lanes[1] == "truck"
	var maximum := 3 if id in ["logistics", "mall"] or (id == "restaurant" and routes.district == "ocean") 		or (id == "motel" and routes.district in ["alpine", "ocean"]) else 2
	for i in maximum:
		var bay: Vector3 = routes.position_of(id, i)
		var approach: Vector3 = routes.point_at(lanes[1], bay.x)
		var length := approach.z - at.z
		Art.plane(self, Vector3(bay.x, -.029, at.z + length * .48), Vector2(lanes[2] + .63, maxf(4.2, length)), pavement)
		var side := 2.01 if heavy else 1.28
		for edge in [-1, 1]:
			var mark := bay + Vector3(side * edge, -.047, 0)
			var reach := 3.52 if heavy else 1.83
			paint.append(stroke(mark - Vector3(0, 0, reach), mark + Vector3(0, 0, reach), .081 if heavy else .063))
	var paver := surface("#9e9a82", "#c3bda0")
	var foundation := 11.5 if heavy else 8.6
	Art.plane(self, Vector3(at.x, -.059, at.z - .21), Vector2(foundation + float(lanes[2]), 6.2), paver)

func stroke(a: Vector3, b: Vector3, width: float) -> Transform3D:
	var direction := a.direction_to(b)
	var pivot := Basis(Vector3.UP, atan2(-direction.z, direction.x))
	return Transform3D(pivot.scaled_local(Vector3(a.distance_to(b), .009, width)), a.lerp(b, .5))

func instances(mesh: Mesh, locations: Array[Transform3D], material: Material = null, shadows := true) -> void:
	Batch.instances(self, mesh, locations, material, GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)


func plant(at: Vector3, scale: float, angle: float) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, angle).scaled_local(Vector3.ONE * scale), at)

func foliage(points: Array[Vector2]) -> void:
	var placements: Array[Transform3D] = []
	for point in points:
		var q := rng.randf_range(.58, 1.34)
		placements.append(plant(Vector3(point.x, -.064, point.y), q, rng.randf_range(-PI, PI)))
	var leaf := ShaderMaterial.new()
	leaf.shader = FOLIAGE
	instances(Art.extract_mesh("regions", routes.district + "_foliage"), placements, leaf)
	for i in range(0, points.size(), 3):
		Art.contact(self, Vector3(points[i].x, -.052, points[i].y), 3.45, 2.80)

func street_signs(z: float) -> void:
	var exits: Dictionary = {"valley": ["RIVERBEND", "FARM DISTRICT"], "alpine": ["SNOWLINE", "ALPINE PASS"],
		"ocean": ["CORAL KEY", "OCEAN DRIVE"], "metro": ["MERIDIAN", "JUNCTION 09"]}
	var labels: Array = exits[routes.district]
	for x in [-18.0, 12.5]:
		var pos := Vector3(x, -.03, z - (6.95 if routes.district == "metro" else 5.06))
		Art.place(self, "desert", "highway_lamp", pos, PI * .5)
	var pylon := Art.place(self, "desert", "pylon", Vector3(10.25, 0, z - 5.57))
	Art.sign(pylon, Vector3(.05, 3.44, .29), labels[0], .23, Color("#f7e8bf"))
	Art.sign(pylon, Vector3(.01, 2.58, .25), labels[1], .145, Color("#f7e8bf"))

func water_material(ocean_water: bool) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = WATER
	mat.set_shader_parameter("sea", ocean_water)
	if not ocean_water:
		mat.set_shader_parameter("shallows", Color("#7fab93"))
		mat.set_shader_parameter("channel", Color("#3e89a1"))
	return mat

func valley() -> void:
	var trees: Array[Vector2] = [Vector2(-11, 8.8), Vector2(3.5, 8.6), Vector2(16, -9),
		Vector2(-8, -12.8), Vector2(-13, -13), Vector2(-21.3, -9.9), Vector2(-34, -4.3), Vector2(-44, 2.5)]
	for i in 31:
		trees.append(Vector2(-48.0 + i * 3.8, rng.randf_range(-37.8, -20.0)))
	for i in 12:
		trees.append(Vector2(-26.0 + i * 5.0, rng.randf_range(22.0, 32.5)))
	foliage(trees)
	var streams: Array[Vector3] = [Vector3(-44, 0, -70), Vector3(-32.4, 0, -31), Vector3(-29.6, 0, -12),
		Vector3(-30, 0, -.9), Vector3(-30, 0, 17.4), Vector3(-32.6, 0, 24), Vector3(-28.7, 0, 32),
		Vector3(-18.3, 0, 61)]
	ribbon(streams, 8.9, -.090, surface("#a5a27c", "#b1ad84"))
	ribbon(streams, 6.95, -.082, water_material(false))
	var access: Vector3 = routes.point_at("car", -30)
	Art.place(self, "regions", "valley_bridge", Vector3(-30, -.02, access.z))
	var public_bridge := Art.place(self, "regions", "valley_bridge", Vector3(-30, -.051, routes.layout.ambient))
	public_bridge.scale.z = 1.59
	for i in 9:
		var entry := Art.place(self, "regions", "valley_ridge_25" if i % 2 == 0 else "valley_ridge_74",
			Vector3(-56 + i * 12.9, -.10, -29.0 - 2.2 * cos(i)), .12 * i)
		entry.scale = Vector3(1.46, .48 + .19 * sin(i), 1.68)
	var reeds: Array[Transform3D] = []
	for i in 27:
		var signed_bank := -33.38 if i % 2 == 0 else -26.62
		var depth := -32.0 + i * 2.69
		if absf(depth - access.z) < 4 or absf(depth - float(routes.layout.ambient)) < 6:
			continue
		reeds.append(plant(Vector3(signed_bank, -.10, depth), rng.randf_range(.74, 1.36), rng.randf_range(0, TAU)))
	instances(Art.extract_mesh("landscape", "reeds"), reeds)
	Art.place(self, "landscape", "water_tower", Vector3(26.0, 0, -18.5))
	for i in 10:
		Art.plane(self, Vector3(i * .86 + 2.6, -.094, -20.73), Vector2(.55, 10.3),
			Kit.material(Color("#96a15c") if i % 2 == 0 else Color("#9ea362")))
	for i in 5:
		Art.place(self, "landscape", "rail", Vector3(4.0 + i * 2.58, 0, -14.88))
	var crop: Array[Transform3D] = []
	for i in 64:
		var column := i % 8
		var row := floori(i / 8.0)
		var at := Vector3(2.6 + column * .86, -.058, -17.10 - row * 1.01)
		crop.append(plant(at, rng.randf_range(.39, .63), rng.randf_range(-PI, PI)))
	instances(Art.extract_mesh("landscape", "meadow"), crop, null, false)
	roadside_details([Vector3(-23.2, 0, 7.4), Vector3(-14.6, 0, 9.3), Vector3(4.8, 0, 8.6), Vector3(17.1, 0, 5.3)], "meadow")
	for at in [Vector3(-22.40, -.06, 6.75), Vector3(-10.04, -.06, 9.26), Vector3(14.4, -.06, 5.75)]:
		Art.place(self, "landscape", "pole", at)
	air_line(Vector3(-22.4, 2.75, 6.75), Vector3(-10.04, 2.75, 9.26), Color("#5d6054"), .018)
	air_line(Vector3(-10.04, 2.75, 9.26), Vector3(14.4, 2.75, 5.75), Color("#5d6054"), .018)

func alpine() -> void:
	var trees: Array[Vector2] = [Vector2(4, -.65), Vector2(7.1, -16.7), Vector2(-10.7, -11.6),
		Vector2(18.2, -16.35), Vector2(-18.3, -7.5), Vector2(-15.7, -21.9), Vector2(-35, .55)]
	for index in 45:
		var q := -50.0 + index * 2.6
		trees.append(Vector2(q, rng.randf_range(-37.0, -23.0)))
		if index % 3 == 0:
			trees.append(Vector2(q + 1.0, rng.randf_range(21.8, 35.3)))
	foliage(trees)
	for i in 11:
		var ridge := Art.place(self, "regions", "alpine_ridge_25" if i % 2 == 0 else "alpine_ridge_74",
			Vector3(-65 + i * 11.9, -.13, -35.0 - cos(i * .78) * 5), .39 * sin(i))
		ridge.scale = Vector3(1.33 + .22 * sin(i), 1.82 + .75 * sin(i * .72), 1.89)
	for i in 12:
		var drift := Art.place(self, "regions", "alpine_ridge_74",
			Vector3(-46 + i * 8.0, -.104, 27.0 + cos(i) * 2.3), .69 * i)
		drift.scale = Vector3(.50, .093, .45)
	for at in [Vector3(-16.2, 0, 10.35), Vector3(-13.8, 0, 8.15), Vector3(12.6, 0, 8.55), Vector3(19.5, 0, 8.60)]:
		Art.place(self, "desert", "barrier", at)
	Art.place(self, "regions", "alpine_gondola", Vector3(-12.0, 0, -28.2))
	air_line(Vector3(-12.0, 5.6, -28.2), Vector3(16.0, 11.1, -44.3), Color("#526574"), .043)
	roadside_details([Vector3(-30.2, 0, 10.73), Vector3(-20.4, 0, -16.0),
		Vector3(1.3, 0, -10.3), Vector3(9.5, 0, 7.38), Vector3(23.4, 0, 1.2)], "stone")

func ocean() -> void:
	var trees: Array[Vector2] = [Vector2(-4, 6.8), Vector2(-7.6, 7.7), Vector2(7, -8.8),
		Vector2(1.0, -13.9), Vector2(-11.2, -13.9), Vector2(-17.6, -10.3),
		Vector2(-29.9, -7.5), Vector2(-22, -17.0), Vector2(21, -12.5), Vector2(11.85, -14.5)]
	for i in 15:
		trees.append(Vector2(-46 + i * 6.33, rng.randf_range(20.2, 22.5)))
	for i in 20:
		trees.append(Vector2(-45 + i * 4.4, rng.randf_range(-25.2, -19.1)))
	foliage(trees)
	Art.plane(self, Vector3(0, -.081, 57.15), Vector2(221, 68), water_material(true))
	Art.plane(self, Vector3(0, -.075, 21.2), Vector2(200, 3.04), surface("#e0bf8d", "#f1daaa"))
	Art.plane(self, Vector3(0, -.057, 20.09), Vector2(120, .60), surface("#a79e83", "#d0c4a5"))
	for x in [-22.0, 18.0]:
		Art.place(self, "regions", "ocean_pier", Vector3(x, -.046, 22.38), -.10)
	Art.place(self, "regions", "ocean_lighthouse", Vector3(-40.8, -.08, 22.0))
	for point in [Vector3(-13, -.06, 8.40), Vector3(15.8, -.06, 4.75), Vector3(-36, -.06, 8.0)]:
		Art.place(self, "desert", "median_planter", point)
	for i in 9:
		var coast_rock := Art.place(self, "landscape", "stone", Vector3(-41.8 + i * .85, -.05, 22.2 + sin(i) * 1.35), .32 * i)
		coast_rock.scale = Vector3.ONE * (.88 + .20 * sin(i))
	for i in 12:
		var at := Vector3(-38.4 + i * 6.42, 0, 21.6 + sin(i * 1.73) * .54)
		Art.place(self, "desert", "barrier", at)
	roadside_details([Vector3(-28.1, 0, 20.06), Vector3(-7.5, 0, -13.9), Vector3(7.2, 0, 5.9)], "hedge")

func metro() -> void:
	var trees: Array[Vector2] = [Vector2(-8, 5.9), Vector2(4.9, 5.75), Vector2(20.1, 5.65),
		Vector2(-19.0, 4.45), Vector2(-24.0, -4.9), Vector2(9.1, -9.85), Vector2(-1.2, -17.0)]
	for i in 23:
		trees.append(Vector2(-49 + i * 4.61, rng.randf_range(21.4, 22.85)))
	for i in 14:
		trees.append(Vector2(-45 + i * 6.45, -19.9 + sin(i) * .55))
	foliage(trees)
	for i in 13:
		var at := Vector3(-53.3 + i * 8.68, -.1, -52.1 - rng.randf_range(.0, 6.1))
		var tower := Art.place(self, "regions", "metro_tower_%d" % (i % 3), at, .09 * sin(i))
		tower.scale.y = rng.randf_range(.79, 1.23)
	for i in 7:
		var at := Vector3(-36.0 + i * 12.0, -.015, 5.23)
		Art.place(self, "desert", "highway_lamp", at, PI * .5)
		Art.place(self, "desert", "barrier", at + Vector3(2.1, 0, .55))
	var divider := surface("#77847a", "#9da399")
	Art.plane(self, Vector3(0, -.051, -19.9), Vector2(105.0, 1.63), divider)
	Art.plane(self, Vector3(0, -.046, 6.15), Vector2(112.0, .81), divider)
	for x in [-20.0, 3.0, 26.0]:
		var object := Art.place(self, "desert", "pylon", Vector3(x, -.03, -18.55))
		Art.sign(object, Vector3(0, 3.48, .31), "FREIGHT", .19, Color("#ffe5ac"))

func roadside_details(points: Array, key: String) -> void:
	var patches: Array[Transform3D] = []
	for anchor: Vector3 in points:
		for i in 10:
			var at := anchor + Vector3(rng.randf_range(-1.19, 1.19), -.049, rng.randf_range(-.67, .67))
			patches.append(plant(at, rng.randf_range(.24, .61), rng.randf_range(-PI, PI)))
	instances(Art.extract_mesh("landscape", key), patches, null, false)

func air_line(a: Vector3, b: Vector3, tint: Color, thickness: float) -> void:
	var line := Kit.cylinder(self, a.lerp(b, .5), thickness, thickness, a.distance_to(b), tint, 6)
	var axis := a.direction_to(b)
	line.basis = Basis(Quaternion(Vector3.UP, axis))

func set_forecourt_tier(tier: int) -> void:
	pavement.set_shader_parameter("trail", clampf(.84 - float(tier) * .14, .17, .70))
