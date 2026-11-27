extends SubViewportContainer

const Car = preload("res://scenes/vehicles/compact.tscn")
const Art = preload("res://scripts/art/visual_library.gd")
const Kit = preload("res://scripts/buildings/model_kit.gd")
const GRIME = preload("res://assets/materials/practice_grime.gdshader")
const GRAIN = preload("res://assets/textures/paving_noise.png")

var viewport: SubViewport
var camera: Camera3D
var mud: ShaderMaterial

func build(mode: String) -> void:
	stretch = true
	stretch_shrink = 2
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.y = 455 if mode == "wash" else 278
	viewport = SubViewport.new()
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	var room := Node3D.new()
	viewport.add_child(room)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("#315b60")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("#d1e3df")
	environment.environment.ambient_light_energy = .56
	room.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-65, 26, 0)
	light.light_color = Color("#ffecd0")
	light.light_energy = 1.03
	light.shadow_enabled = true
	room.add_child(light)
	Kit.box(room, Vector3(0,-.17,0), Vector3(22,.24,22), Color("#4e7776"))
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.6 if mode == "wash" else 5.45
	room.add_child(camera)
	camera.position = Vector3(0,7.0,0.0) if mode == "wash" else Vector3(4.8,4.9,6.2)
	camera.look_at(Vector3(0,.33,0), Vector3.RIGHT if mode == "wash" else Vector3.UP)
	camera.current = true
	for side in [-1.0, 1.0]:
		Kit.box(room, Vector3(side * 1.81, .012, 0), Vector3(.065,.025,9.6), Color("#ecd59c"))
		for i in 6:
			var stripe := Kit.box(room, Vector3(side * 2.10,.009,-3.1+i*1.21),Vector3(.36,.021,.075),Color("#d5b36e"))
			stripe.rotation.y = .38
	var unit := Car.instantiate()
	room.add_child(unit)
	unit.build("kestrel" if mode == "wash" else "atlas" if mode == "cargo" else "orion", 0)
	if mode == "wash":
		mud = ShaderMaterial.new()
		mud.shader = GRIME
		mud.set_shader_parameter("grain", GRAIN)
		mud.set_shader_parameter("paint", Color("#17af9b"))
		var chassis := unit.chassis_art.find_child("Chassis", true, false) as MeshInstance3D
		for surface in chassis.mesh.get_surface_count():
			var paint := chassis.mesh.surface_get_material(surface)
			if paint.resource_name == "CoachPaint":
				chassis.set_surface_override_material(surface, mud)
	elif mode == "fuel":
		Art.place(room, "transport", "depot", Vector3(-3.10, -.05, -4.65)).scale = Vector3.ONE * .65
		camera.position += Vector3(-.85,.22, .35)
		camera.look_at(Vector3(-.38, .61, .1))
	else:
		Art.place(unit, "transport", "freight")
		camera.position += Vector3(0.6,1.12,-.57)
		camera.look_at(Vector3(0,.82,-1.38))

func stain_coords(global: Vector2) -> Vector2:
	var rect := get_global_rect()
	var pixel := (global - rect.position) / rect.size * Vector2(viewport.size)
	var contact := camera.project_ray_origin(pixel)
	return Vector2(contact.x / 1.72 + .5, contact.z / 3.62 + .5)

func apply_dirty(values: PackedFloat32Array) -> void:
	if mud == null:
		return
	for row in 3:
		var index := row * 4
		mud.set_shader_parameter(["dirt_a","dirt_b","dirt_c"][row],
			Vector4(values[index], values[index+1], values[index+2], values[index+3]))
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
