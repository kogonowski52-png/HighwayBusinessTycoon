extends "res://tests/station_smoke.gd"
## Separate product photography of the shipped models and an in-engine business panorama.

const Art = preload("res://scripts/art/visual_library.gd")
const Kit = preload("res://scripts/buildings/model_kit.gd")
const Vehicle = preload("res://scenes/vehicles/compact.tscn")

func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			captures = argument.trim_prefix("--capture-dir=")
	if captures.is_empty() or DisplayServer.get_name() == "headless":
		expect(false, "publishing photography needs a real viewport and destination")
		result("Publishing brand")
		return
	DirAccess.make_dir_recursive_absolute(captures)
	root.borderless = true
	root.position = Vector2i.ZERO
	root.size = Vector2i(1024, 1024)
	root.transparent_bg = true
	var studio := Node3D.new()
	root.add_child(studio)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("#174746")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("#c5e1f0")
	environment.environment.ambient_light_energy = 0.66
	studio.add_child(environment)
	var main := DirectionalLight3D.new()
	studio.add_child(main)
	main.rotation_degrees = Vector3(-49, -32, 0)
	main.light_color = Color("#fff0ca")
	main.light_energy = 1.12
	main.shadow_enabled = true
	main.directional_shadow_max_distance = 35
	main.shadow_blur = 1.4
	var rim := DirectionalLight3D.new()
	studio.add_child(rim)
	rim.rotation_degrees = Vector3(-29, 139, 0)
	rim.light_color = Color("#87dbf4")
	rim.light_energy = 0.42
	var camera := Camera3D.new()
	studio.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.current = true
	var looks := [
		["copper", "canopy_arc", "vela", 0, Vector3(10.0, 12.3, 14.0), Color("#fff0ca")],
		["jade", "canopy_cantilever", "kestrel", 0, Vector3(12.2, 12.7, 13.4), Color("#f5f5dc")],
		["blue-hour", "canopy_ridge", "regency", 2, Vector3(-9.2, 12.2, 14.7), Color("#ffca93")],
	]
	for look: Array in looks:
		var display := Node3D.new()
		studio.add_child(display)
		Kit.box(display, Vector3(0, -.31, 0), Vector3(11.9, .42, 9.1), Color("#314956"))
		Kit.box(display, Vector3(0, -.13, -.02), Vector3(11.72, .19, 8.92), Color("#485863"))
		Kit.box(display, Vector3(0, -.019, 3.84), Vector3(11.64, .055, .15), Color("#edd195"))
		Art.place(display, "architecture", "island", Vector3(-1.65, .03, -1.3)).scale = Vector3.ONE * .88
		var canopy := Art.place(display, "architecture", look[1], Vector3(-.5, 0, -1.15))
		canopy.scale = Vector3.ONE * .91
		Art.place(display, "architecture", "pump_vintage", Vector3(-2.3, .03, -1.23)).scale = Vector3.ONE * 1.18
		Art.place(display, "architecture", "pump_vintage", Vector3(.15, .03, -1.23)).scale = Vector3.ONE * 1.12
		var car := put_car(display, look[2], look[3], Vector3(1.3, .03, 2.36), -.87)
		car.scale = Vector3.ONE * 1.57
		camera.position = look[4]
		camera.look_at(Vector3(0, .9, .0))
		camera.size = 16.7
		main.light_color = look[5]
		for frame in 4:
			await process_frame
		await capture("icon-" + str(look[0]) + ".png")
		display.free()
	studio.free()
	root.transparent_bg = false
	await panorama()
	root.get_node("RouteAudio").shut_down()
	game.free()
	await create_timer(.20).timeout
	clean_save(save_path)
	result("Publishing brand")

func put_car(parent: Node3D, model: String, variant: int, position: Vector3, yaw: float) -> Node3D:
	var car := Vehicle.instantiate()
	parent.add_child(car)
	car.build(model, variant)
	car.position = position
	car.rotation.y = yaw
	return car

func panorama() -> void:
	root.size = Vector2i(1536, 750)
	save_path = "/tmp/hbt-play-brand-%d.cfg" % OS.get_process_id()
	game = mount(WALL)
	current_scene = game
	game.skip_tutorial()
	game.choose_weather("clear")
	game.economy.preferences.auto_day = false
	game.set_look(game.lighting.Look.GOLDEN)
	game.set_quality(2)
	game.economy.credit("cash", HbtAmount.from(100_000_000))
	game.economy.credit("reputation", HbtAmount.from(440))
	game.economy.buy_levels("fuel", 43)
	for id: String in game.economy.facilities:
		if id != "fuel" and game.economy.unlock(id):
			game.economy.buy_levels(id, 39)
		if game.economy.level(id) > 0:
			game.economy.hire(id)
	step(.5)
	game.hud.hide()
	game.operations.hide()
	game.site_buttons.hide()
	game.traffic.dispatch.spawning = false
	for car: Node3D in game.traffic.background:
		car.hide()
	put_car(game, "atlas", 1, Vector3(13.28, .03, 5.2), -PI * .5)
	put_car(game, "cargo", 0, Vector3(-6.2, .03, 4.4), PI * .5)
	put_car(game, "vela", 0, Vector3(4.4, .03, 4.7), -PI * .5)
	put_car(game, "post", 1, Vector3(-8.5, .03, -.25), -.3)
	put_car(game, "kestrel", 1, Vector3(12.05, .03, -4.6), PI)
	game.aim_camera(Vector3(-1.8, .9, -5.3), Vector3(13.5, 37, 34), 40.0)
	for frame in 5:
		await process_frame
	await capture("business-panorama.png")
