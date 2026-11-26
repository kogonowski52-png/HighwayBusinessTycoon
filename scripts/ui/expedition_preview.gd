extends RefCounted
## A small isolated 3D viewport for the atlas and the selected collectible.

const Art = preload("res://scripts/art/visual_library.gd")
const Regions = preload("res://data/world/regions.gd")
const Atlas = preload("res://data/world/atlas.gd")
const Vehicles = preload("res://data/visual/vehicle_catalog.gd")
const CAR = preload("res://scenes/vehicles/compact.tscn")
const Kit = preload("res://scripts/buildings/model_kit.gd")

static func viewport(size: Vector2i) -> SubViewport:
	var view := SubViewport.new()
	view.size = size
	view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ONCE
	var world := WorldEnvironment.new()
	var sky := Environment.new()
	sky.background_mode = Environment.BG_COLOR
	sky.background_color = Color("#294b50")
	sky.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	sky.ambient_light_color = Color("#e1eddb")
	sky.ambient_light_energy = .70
	world.environment = sky
	view.add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-56, -31, 0)
	light.light_color = Color("#ffe7bd")
	light.light_energy = .62
	light.shadow_enabled = false
	view.add_child(light)
	return view

static func atlas(parent: Control, expansion: bool) -> TextureRect:
	var frame := image(parent, Vector2i(792, 522), 514)
	var view: SubViewport = frame.get_child(0)
	var terrain := Node3D.new()
	view.add_child(terrain)
	var camera := Camera3D.new()
	view.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12.0
	camera.position = Vector3(0, 21, 0)
	camera.rotation_degrees.x = -90.0
	camera.current = true
	land(terrain, Vector3(-4.45, -.85, -.15), Vector2(4.60, 5.0), Color("#b4a778"), Color("#779885"), .22)
	land(terrain, Vector3(3.0, -.84, -.14), Vector2(5.94, 5.04), Color("#a3a47e"), Color("#77978b"), .64)
	for key: String in Atlas.chapter_routes(expansion):
		var entry := Atlas.destination(key)
		var coordinate: Vector2 = entry.position
		var pos := Vector3((coordinate.x - .5) * 18.20, -.10, (coordinate.y - .5) * 12.0)
		land(terrain, pos, Vector2(2.43, 1.63), Color(entry.color), Color(entry.color).darkened(.29), coordinate.x * 3.8)
		var object := pos + Vector3(-.63, .14, -.43)
		if expansion:
			if entry.has("scene"):
				var miniature := Art.place(terrain, "regions", key + "_atlas", pos + Vector3(0, .12, -.31))
				miniature.scale = Vector3.ONE * .19
			continue
		match key:
			"north": Art.place(terrain, "architecture", "canopy_rehab", object).scale = Vector3.ONE * .21
			"desert":
				Art.place(terrain, "desert", "buttress", object + Vector3(-.38, 0, -.25)).scale = Vector3.ONE * .34
				Art.place(terrain, "desert", "copper_mile", object + Vector3(.33, 0, .14)).scale = Vector3.ONE * .195
			_:
				Art.place(terrain, "regions", key + "_fuel", object + Vector3(.2, 0, .14)).scale = Vector3.ONE * .20
				if key in ["valley", "alpine"]:
					Art.place(terrain, "regions", key + "_ridge_25", object + Vector3(-.26, 0, -.37)).scale = Vector3.ONE * .17
				elif key == "ocean":
					Art.place(terrain, "regions", "ocean_lighthouse", object + Vector3(-.26, 0, -.37)).scale = Vector3.ONE * .21
				else:
					Art.place(terrain, "regions", "metro_tower_1", object + Vector3(.73, 0, -.28)).scale = Vector3.ONE * .14
	var routes := [
		[Vector3(-3.65, .05, -2.48), Vector3(-2.95, .05, -1.29), Vector3(-2.65, .05, .25), Vector3(-3.10, .05, 2.82)],
		[Vector3(.52, .05, .3), Vector3(.69, .05, -1.54), Vector3(.80, .05, -3.64)],
		[Vector3(.55, .061, .39), Vector3(2.2, .061, 1.32), Vector3(4.84, .061, 2.6)],
		[Vector3(2.2, .058, 1.21), Vector3(3.45, .058, -.38), Vector3(5.39, .058, -1.49)],
	]
	if expansion:
		var trail: Array[Vector3] = []
		for id: String in Atlas.chapter_routes(true):
			var coordinate: Vector2 = Atlas.destination(id).position
			trail.append(Vector3((coordinate.x - .5) * 18.20, .07, (coordinate.y - .5) * 12.0))
		routes = [trail]
	for marks in routes:
		for index in range(1, marks.size()):
			var a: Vector3 = marks[index - 1]
			var b: Vector3 = marks[index]
			var strip := Kit.box(terrain, (a + b) * .5, Vector3(.107, .012, a.distance_to(b)), Color("#f6d592"))
			strip.rotation.y = atan2(b.x - a.x, b.z - a.z)
	return frame

static func land(parent: Node3D, at: Vector3, size: Vector2, top: Color, edge: Color, seed: float) -> void:
	var stamp := SurfaceTool.new()
	stamp.begin(Mesh.PRIMITIVE_TRIANGLES)
	var perimeter: Array[Vector3] = []
	for index in 20:
		var phi := TAU * index / 20.0
		var scale := 1.0 + .115 * sin(phi * 4 + seed) + .09 * cos(phi * 3 - seed)
		perimeter.append(Vector3(cos(phi) * size.x * scale, sin(2 * phi) * .07, sin(phi) * size.y * scale))
	for index in perimeter.size():
		var low := Vector3(0, -.42, 0)
		var a := perimeter[index]
		var b := perimeter[(index + 1) % perimeter.size()]
		for point in [Vector3.ZERO, b, a]:
			stamp.set_color(top)
			stamp.add_vertex(point)
		for point in [a, b, b + low, a, b + low, a + low]:
			stamp.set_color(edge)
			stamp.add_vertex(point)
	stamp.generate_normals()
	var instance := MeshInstance3D.new()
	instance.mesh = stamp.commit()
	var surface := StandardMaterial3D.new()
	surface.vertex_color_use_as_albedo = true
	surface.cull_mode = BaseMaterial3D.CULL_DISABLED
	instance.material_override = surface
	instance.position = at
	parent.add_child(instance)

static func detail(parent: Control, group: String, item: String) -> void:
	var frame := image(parent, Vector2i(560, 260), 302)
	var view: SubViewport = frame.get_child(0)
	var presentation := Node3D.new()
	view.add_child(presentation)
	var subject: Node3D
	var width := 4.0
	var focus_y := 0.6
	if group == "desert":
		subject = Art.place(presentation, "desert", "copper_mile")
		width = 12.7
		focus_y = 1.18
	elif group == "north":
		subject = Art.place(presentation, "architecture", "canopy_ridge")
		width = 11.9
		focus_y = 1.12
	elif Atlas.EXPANSION_CHAPTER.has(group):
		subject = Art.place(presentation, "regions", group + "_atlas")
		width = 12.9
		focus_y = .93
	elif Regions.has_region(group):
		subject = Art.place(presentation, "regions", group + "_fuel")
		match group:
			"valley":
				Art.place(presentation, "regions", "valley_bridge", Vector3(-5.7, -.14, 2.8)).scale = Vector3.ONE * .52
				Art.place(presentation, "regions", "valley_foliage", Vector3(4.1, 0, -1.6))
			"alpine":
				Art.place(presentation, "regions", "alpine_ridge_25", Vector3(-4.1, -.12, -2.7)).scale = Vector3.ONE * .61
				Art.place(presentation, "regions", "alpine_foliage", Vector3(4.2, 0, .6))
			"ocean":
				Art.place(presentation, "regions", "ocean_lighthouse", Vector3(-4.3, 0, -2.1)).scale = Vector3.ONE * .74
				Art.place(presentation, "regions", "ocean_foliage", Vector3(3.3, 0, 1.5))
			"metro":
				Art.place(presentation, "regions", "metro_tower_1", Vector3(-3.65, 0, -3.9)).scale = Vector3.ONE * .39
				Art.place(presentation, "regions", "metro_tower_2", Vector3(3.9, 0, -3.1)).scale = Vector3.ONE * .53
		width = 14.2
		focus_y = 1.43
	elif item == "gold_gate":
		subject = Art.place(presentation, "premium", "gold_gate")
		width = 4.8
		focus_y = .79
	elif group in ["cars", "trucks", "routes"]:
		subject = CAR.instantiate()
		presentation.add_child(subject)
		subject.build(item, 1)
		width = float(Vehicles.VEHICLES[item].length) * 1.62
		focus_y = width * .095
	else:
		var asset := "upgrade_" + item if group == "facades" else "event_" + item
		subject = Art.place(presentation, "desert", asset)
		width = 6.2 if item == "copper_arch" else 5.8 if item in ["summer", "holiday"] else 4.8
		focus_y = .95 if item in ["summer", "holiday"] else .69
	subject.rotation.y = .25
	Kit.cylinder(presentation, Vector3(0, -.26, 0), width * .41, width * .43, .40, Color("#a89672"), 32)
	Art.contact(presentation, Vector3(0, -.032, 0), width * .76, width * .42)
	var camera := Camera3D.new()
	presentation.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.size = width
	camera.position = Vector3(5.3, 5.4, 8.7)
	camera.look_at(Vector3(0, focus_y, 0))
	camera.current = true

static func image(parent: Control, size: Vector2i, height: int) -> TextureRect:
	var frame := TextureRect.new()
	frame.custom_minimum_size.y = height
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(frame)
	var view := viewport(size)
	frame.add_child(view)
	frame.texture = view.get_texture()
	return frame
