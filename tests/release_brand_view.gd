extends "res://tests/station_smoke.gd"
## Capture the marketing camera from the production diorama and original vehicle models.

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			captures = arg.get_slice("=", 1)
	if captures.is_empty() or DisplayServer.get_name() == "headless":
		expect(false, "a canvas and output directory are required")
		result("Brand diorama")
		return
	DirAccess.make_dir_recursive_absolute(captures)
	root.borderless = true
	root.position = Vector2i.ZERO
	root.size = Vector2i(768, 768)
	save_path = "/tmp/hbt-090-brand-%d.cfg" % OS.get_process_id()
	game = mount(WALL)
	current_scene = game
	game.skip_tutorial()
	game.choose_weather("clear")
	game.set_look(game.lighting.Look.GOLDEN)
	game.set_quality(2)
	game.economy.credit("cash", HbtAmount.from(44_000))
	game.economy.credit("reputation", HbtAmount.from(14))
	game.economy.buy_levels("fuel", 10)
	game.economy.unlock("market")
	game.economy.hire("fuel")
	game.hud.hide()
	game.operations.hide()
	game.site_buttons.hide()
	game.crew.hide()
	game.driver.hide()
	game.traffic.dispatch.spawning = false
	for car: Node3D in game.traffic.vehicles.values():
		car.hide()
	for car: Node3D in game.traffic.background:
		car.hide()
	var featured: Node3D = game.traffic.background[0]
	featured.build("vela", 0, false, "north")
	featured.position = Vector3(2.45, .014, 2.33)
	featured.rotation.y = -.77
	featured.show()
	await process_frame
	await process_frame
	game.aim_camera(Vector3(.25, .85, -.11), Vector3(8.8, 12.4, 13.8), 12.3)
	await capture("station-icon.png")
	game.aim_camera(Vector3(.41, .62, -.46), Vector3(7.2, 10.6, 12.9), 14.1)
	await capture("station-icon-wide.png")
	root.size = Vector2i(1280, 640)
	await process_frame
	await process_frame
	game.aim_camera(Vector3(-3.4, .63, -.47), Vector3(11.4, 22.2, 22.5), 27.2)
	await capture("station-feature.png")
	root.size = Vector2i(768, 1024)
	await process_frame
	await process_frame
	game.aim_camera(Vector3(-.5, .85, -.64), Vector3(10.6, 16.1, 17.8), 18.4)
	await capture("station-title.png")
	expect(FileAccess.file_exists(captures.path_join("station-icon.png")) and featured.visible, "real game diorama and coupe captured")
	game.free()
	root.get_node("RouteAudio").shut_down()
	await create_timer(.22).timeout
	clean_save(save_path)
	result("Brand diorama")
