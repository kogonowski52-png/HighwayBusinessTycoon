extends "res://tests/station_smoke.gd"
## Store screenshots and UI checks at real tablet-sized viewport dimensions.

const Front = preload("res://scenes/ui/front_gate.tscn")
const CASES := {"7-inch": Vector2i(1200, 1920), "10-inch": Vector2i(1440, 1920)}

func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			captures = argument.get_slice("=", 1)
	if captures.is_empty() or DisplayServer.get_name() == "headless":
		expect(false, "a canvas and output directory are required")
		result("Tablet viewports")
		return
	DirAccess.make_dir_recursive_absolute(captures)
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.borderless = true
	root.position = Vector2i.ZERO
	save_path = "/tmp/hbt-090-tablet-%d.cfg" % OS.get_process_id()
	game = mount(WALL)
	current_scene = game
	game.skip_tutorial()
	game.economy.credit("cash", HbtAmount.from(90_000))
	game.economy.credit("reputation", HbtAmount.from(28))
	game.set_quality(1)
	game.set_look(game.lighting.Look.GOLDEN)
	game.economy.preferences.auto_day = false
	game.economy.buy_levels("fuel", 25)
	game.economy.hire("fuel")
	for service in ["market", "wash", "workshop"]:
		if game.economy.unlock(service):
			game.economy.buy_levels(service, 10)
			game.economy.hire(service)
	step(8)
	for name: String in CASES:
		root.size = CASES[name]
		game.operations.hide_page()
		game.aim_camera(Vector3(3.0, .43, -7.8), Vector3(14.2, 22.4, 23.5), 27.0)
		await settle_frames()
		expect(root.size == CASES[name] and controls_fit(), "main HUD fits %s" % name)
		await capture(name + "-01-services.jpg")
		var menu := "team" if name == "7-inch" else "atlas"
		game.open_page(menu)
		await settle_frames()
		expect(game.operations.modal_open() and root.get_visible_rect().encloses(game.operations.panel.get_global_rect()),
			"sheet fits %s" % name)
		await capture(name + "-02-" + menu + ".jpg")
		game.operations.hide_page()
		await settle_frames()
	game.free()
	var title := Front.instantiate()
	title.profile_path = save_path
	root.add_child(title)
	current_scene = title
	await settle_frames()
	expect(root.get_visible_rect().encloses(title.play.get_global_rect()), "title fits a tablet")
	root.size = Vector2i(432, 960)
	title.switch_language()
	await settle_frames()
	expect(root.get_visible_rect().encloses(title.play.get_global_rect()) and title.play.text in ["Play", "Continue"],
		"English title fits a tall phone")
	await capture("phone-english-title.png")
	title.free()
	root.get_node("RouteAudio").shut_down()
	await create_timer(.18).timeout
	clean_save(save_path)
	result("Tablet viewports")

func settle_frames() -> void:
	await create_timer(.40).timeout
	for _frame in 4:
		await RenderingServer.frame_post_draw
