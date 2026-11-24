extends SceneTree

const Main = preload("res://scenes/world/roadside.tscn")
const Vehicle = preload("res://scenes/vehicles/compact.tscn")
const Actor = preload("res://scripts/customers/customer_manager.gd")
const Catalog = preload("res://scripts/traffic/vehicle_catalog.gd")
const Campus = preload("res://scripts/buildings/roadside_campus.gd")
const Lighting = preload("res://scripts/art/world_lighting.gd")
const Art = preload("res://scripts/art/visual_library.gd")
const Kit = preload("res://scripts/buildings/model_kit.gd")
const PAPER := Color("#d7c6a6")
const INK := Color("#22474b")
const CREAM := Color("#f8e6bd")
const ROLE_STUDIES := [
	["customer", "Klientka", "walk"], ["driver", "Kierowca", "fuel"],
	["cashier", "Kasjerka", "cash"], ["mechanic", "Mechanik", "repair"],
	["attendant", "Obsługa stacji", "service"], ["wash_worker", "Obsługa myjni", "clean"],
	["server", "Kelnerka", "carry"], ["manager", "Menedżer", "idle"],
]
const BUILDING_STUDIES := [
	["market", "Sklep"], ["wash", "Myjnia"], ["restaurant", "Restauracja"],
	["workshop", "Warsztat"], ["motel", "Motel"], ["parking", "Parking"],
]

var captures := ""
var suite := ""
var failures := 0
var checks := 0
var game: Node3D
var art_set: Node3D
var camera: Camera3D
var save_path: String

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			captures = argument.trim_prefix("--capture-dir=")
		if argument.begins_with("--suite="):
			suite = argument.trim_prefix("--suite=")
	if not captures.is_empty() and DisplayServer.get_name() == "headless":
		printerr("Open a window to capture the rendered gallery.")
		quit(2)
		return
	save_path = "/tmp/hbt-art-gallery-%d.cfg" % OS.get_process_id()
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.position = Vector2i.ZERO
	root.borderless = true
	if suite != "studio":
		await play_scene()
	if suite != "game":
		await vehicle_studies()
		await character_studies()
		await building_studies()
	for suffix in ["", ".backup", ".tmp"]:
		if FileAccess.file_exists(save_path + suffix):
			DirAccess.remove_absolute(save_path + suffix)
	print("Visual QA: %d/%d passed" % [checks - failures, checks])
	quit(1 if failures else 0)

func play_scene() -> void:
	root.size = Vector2i(756, 1344)
	game = Main.instantiate()
	game.economy.storage.path = save_path
	root.add_child(game)
	await process_frame
	check(game.economy.level == 1 and game.traffic.active.model_id == "sprint", "main scene starts with first tier and Sprint")
	check(game.hud.lighting.text == "Dzień" and game.hud.view.text == "Mapa", "localized lighting and camera controls")
	game.traffic.set_process(false)
	await capture("01-stacja-w-grze.png")
	game.hud.view.pressed.emit()
	check(game.overview and game.camera.size >= 46.0, "camera control expands the world view")
	game.hud.visible = false
	set_window(Vector2i(1440, 960))
	await process_frame
	await process_frame
	var map_target := Vector3(-1.35, 0.0, -3.18)
	var map_view := Vector3(8.2, 32.0, 27.0)
	game.aim_camera(map_target, map_view, 52.0)
	await capture("02-mapa-dzien.png")

	game.serve_customer()
	game._process(0.0)
	game.driver.pose_at("fuel", 0.68)
	check(game.effects.hose[0].visible and game.driver.prop.visible, "live nozzle and hose")
	game.aim_camera(Vector3(-0.42, 1.12, -0.17), Vector3(5.8, 7.5, 14.6), 18.75)
	await capture("03-stacja-detal.png")

	game.hud.lighting.pressed.emit()
	check(game.lighting.current == Lighting.Look.GOLDEN and not game.traffic.active.head_pool.visible, "golden hour preserves daylight lamps")
	game.aim_camera(map_target, map_view, 52.0)
	await capture("04-mapa-zlota-godzina.png")
	game.hud.lighting.pressed.emit()
	check(game.lighting.current == Lighting.Look.EVENING and game.traffic.active.head_pool.visible, "evening turns on headlights")
	await capture("05-mapa-wieczor.png")
	game.hud.lighting.pressed.emit()
	check(game.lighting.current == Lighting.Look.NIGHT and game.lighting.practical_lights[0].visible, "night lights the forecourt")
	game.aim_camera(Vector3(0, 0.62, 0.73), Vector3(9.1, 12, 15.9), 29.4)
	await capture("06-stacja-noc.png")

	game.set_look(Lighting.Look.DAY)
	game.effects.cycle = 2.5
	game.effects._process(0.0)
	check(game.effects.water.emitting and game.effects.foam.emitting and game.effects.smoke.emitting,
		"wash water, foam and workshop smoke start")
	if not captures.is_empty():
		game.aim_camera(Campus.WASH_AT + Vector3(0, 1.12, 1.70), Vector3(-2.7, 3.4, 7.6), 10.5)
		await create_timer(0.37).timeout
		await capture("15-myjnia-woda.png")
		game.aim_camera(Vector3(0, 0.62, 0.73), Vector3(9.1, 12, 15.9), 29.4)
	game.traffic._process(3.0)
	check(game.traffic.state == game.traffic.State.LEAVING and game.economy.customers == 1, "payment settles through gameplay")
	await capture("07-monety-sprzedaz.png", false)
	for tier in range(2, 6):
		game.economy.cash = game.economy.PROFILE.upgrade_cost(tier - 1)
		game.upgrade_station()
		check(game.economy.level == tier and is_instance_valid(game.station.newest_module),
			"level %d unlocks dedicated architecture" % tier)
	if not captures.is_empty():
		await create_timer(0.26).timeout
		await capture("08-rozbudowa-efekt.png", false)
		await create_timer(0.95).timeout
	else:
		game.station.newest_module.position.y = 0.0
		game.station.newest_module.scale.y = 1.0
	game.aim_camera(Vector3(-0.3, 0.7, -1.52), Vector3(9.4, 14.7, 22.8), 24.9)
	await capture("09-stacja-poziom-5.png")
	game.hud.visible = true
	game.hud.view.pressed.emit()
	set_window(Vector2i(756, 1344))
	await capture("10-poziom-5-w-grze.png")
	game.free()

func vehicle_studies() -> void:
	studio(Vector2i(1440, 810), Vector3(0, 0.47, 0.25), Vector3(0, 9.1, 15.0), 18.85)
	var hero := car("meridian", Vector3(-5.52, 0.115, 0.91), -0.65, 0)
	car("kestrel", Vector3(-0.33, 0.115, 0.83), 2.31, 0).update_signals(true, -1, 0.16)
	car("cargo", Vector3(5.14, 0.115, -0.03), -0.83, 0)
	label_at(Vector3(-5.53, 0.117, 3.16), "MERIDIAN", 0.40)
	label_at(Vector3(-0.33, 0.117, 3.14), "KESTREL", 0.40)
	label_at(Vector3(5.14, 0.117, 3.62), "CARGO", 0.40)
	var wheel: Node3D = hero.wheels[0]
	var before := wheel.rotation
	hero.spin(0.32)
	check(wheel.rotation != before, "wheel rotates by travelled distance")
	hero.update_signals(true, 1, 0.08)
	check(hero.brake_lamps.material_override != null and hero.right_lamps.material_override != null,
		"brake and turn lamps emit")
	hero.update_signals(false, 1, 0.50)
	check(hero.brake_lamps.material_override == null and hero.right_lamps.material_override == null,
		"indicator has an off-phase")
	await capture("11-samochody-detal.png")

	studio(Vector2i(1280, 1280), Vector3(0, 0.23, 0.28), Vector3(0, 22, 10.3), 28.25)
	var roster := Catalog.roster()
	check(roster.size() == 20, "20 authored vehicle geometries")
	for index in range(roster.size()):
		var x := (index % 4 - 1.5) * 6.03
		var z := (floori(index / 4.0) - 2.0) * 5.35
		var id: String = roster[index]
		var model := car(id, Vector3(x, 0.095, z), -0.58 if index % 2 == 0 else 0.64, 0)
		model.scale *= minf(1.0, 4.35 / float(model.record.length))
		label_at(Vector3(x, 0.103, z + 2.38), str(model.record.name).to_upper(), 0.53)
		check(model.wheels.size() == model.record.axles.size() * 2 and model.headlamps != null
			and model.brake_lamps != null and model.left_lamps != null and model.right_lamps != null,
			"axles and lamp set for " + id)
	await capture("12-flota-20-modeli.png")
	art_set.free()
	art_set = null

func character_studies() -> void:
	studio(Vector2i(1440, 960), Vector3(0, 0.70, 0.23), Vector3(0, 7.2, 10.2), 11.40)
	for index in range(ROLE_STUDIES.size()):
		var study: Array = ROLE_STUDIES[index]
		var row := floori(index / 4.0)
		var x := (index % 4 - 1.5) * 2.65
		var z := -2.84 if row == 0 else 1.81
		var actor := Actor.new()
		actor.role = study[0]
		actor.position = Vector3(x, 0.12, z)
		actor.rotation.y = -0.37 if index % 2 == 0 else 0.35
		art_set.add_child(actor)
		actor.pose_at(study[2], 0.27 + (index % 3) * 0.12)
		actor.animation.pause()
		var rig := actor.skeleton
		check(rig.get_bone_count() >= 15 and actor.animation.get_animation_list().size() == 9,
			"rig and nine clips for " + actor.role)
		if index == 0:
			var bone := rig.find_bone("leg_l")
			actor.pose_at("run", 0.11)
			var early := rig.get_bone_pose_rotation(bone)
			actor.pose_at("run", 0.48)
			check(absf(early.dot(rig.get_bone_pose_rotation(bone))) < 0.995, "the running clip actually moves the leg")
			actor.pose_at("walk", 0.21)
			actor.animation.pause()
		label_at(Vector3(x, 0.12, z + 1.26), study[1], 0.31)
	await capture("13-postacie.png")
	art_set.free()
	art_set = null

func building_studies() -> void:
	studio(Vector2i(1440, 960), Vector3(0, 0.42, 0.34), Vector3(0, 19.0, 21.0), 33.40)
	for index in range(BUILDING_STUDIES.size()):
		var study: Array = BUILDING_STUDIES[index]
		var x := (index % 3 - 1) * 10.45
		var z := -7.02 if index < 3 else 6.43
		var model := Art.place(art_set, "architecture", study[0], Vector3(x, 0.1, z), -0.27)
		check(model.find_children("*", "MeshInstance3D", true, false).size() > 0, "architecture " + study[0])
		label_at(Vector3(x, 0.18, z + 4.0), study[1], 0.66)
	await capture("14-architektura.png")
	art_set.free()

func studio(resolution: Vector2i, subject: Vector3, offset: Vector3, width: float) -> void:
	if is_instance_valid(art_set):
		art_set.free()
	set_window(resolution)
	art_set = Node3D.new()
	root.add_child(art_set)
	var floor_mesh := Kit.box(art_set, Vector3(0, -0.22, 0), Vector3(140, 0.44, 140), PAPER)
	floor_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var rig := Lighting.new()
	rig.has_practicals = false
	art_set.add_child(rig)
	camera = Camera3D.new()
	art_set.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.size = width
	camera.position = subject + offset
	camera.look_at(subject)
	camera.current = true

func car(id: String, at: Vector3, yaw: float, paint: int) -> Node3D:
	var model := Vehicle.instantiate() as Node3D
	model.position = at
	model.rotation.y = yaw
	art_set.add_child(model)
	model.build(id, paint)
	return model

func label_at(at: Vector3, title: String, size: float) -> void:
	var label := Art.sign(art_set, at, title, size, INK)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true

func set_window(size: Vector2i) -> void:
	if not captures.is_empty():
		root.size = size

func capture(filename: String, settle := true) -> void:
	if captures.is_empty():
		return
	if settle:
		await process_frame
	await RenderingServer.frame_post_draw
	var pixels := root.get_texture().get_image()
	check(pixels != null and pixels.save_png(captures.path_join(filename)) == OK, "captured " + filename)
	if filename in ["01-stacja-w-grze.png", "02-mapa-dzien.png", "06-stacja-noc.png"]:
		var draw_calls := root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
		var triangles := root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)
		print("%s viewport: %d draws, %d primitives" % [filename, draw_calls, triangles])

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)
