extends SceneTree

const Main = preload("res://scenes/world/roadside.tscn")
const SAVE_PREFIX := "/tmp/highway-tycoon-smoke-"
var failures := 0
var checks := 0
var game: Node3D
var save_path: String
var captures := ""

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	save_path = SAVE_PREFIX + str(OS.get_process_id()) + ".cfg"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			captures = argument.trim_prefix("--capture-dir=")
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.size = Vector2i(675, 1200) if not captures.is_empty() else Vector2i(540, 960)
	root.position = Vector2i.ZERO
	game = mount()
	await process_frame
	check(game.economy.cash == 120 and game.economy.level == 1, "fresh station budget")
	check(not game.hud.serve.disabled and game.hud.upgrade.disabled, "opening actions")
	check(game.hud.status.text == "Klient gotowy do obsługi", "Polish startup")
	check(controls_fit(), "phone controls stay inside the viewport")
	await capture("01-stacja.png")
	click(game.hud.serve)
	check(game.hud.serve.disabled and game.traffic.state == game.traffic.State.SERVING, "serve action starts visible service")
	check(not game.traffic.start_service(3.0), "duplicate service rejected")
	await advance(1.0)
	check(game.hud.progress.value > 0.0 and game.hud.progress.value < 1.0, "animated refueling progress")
	check(game.driver.visible and game.driver.cycles == "fuel" and game.effects.hose[0].visible, "driver animates beside the car")
	await capture("02-tankowanie.png")
	await advance(2.0)
	check(game.economy.cash == 155 and game.economy.customers == 1, "exactly one payout after service")
	check(game.traffic.state == game.traffic.State.LEAVING and not game.hud.upgrade.disabled, "customer leaves and upgrade unlocks")
	var old_structure: Node3D = game.station.structure
	click(game.hud.upgrade)
	check(game.economy.cash == 0 and game.economy.level == 2, "actual upgrade purchase")
	check(game.station.structure != old_structure, "upgrade rebuilds visual geometry")
	var departed_position: Vector3 = game.traffic.active.position
	await advance(1.0)
	check(game.traffic.active.position.distance_to(departed_position) > 1.0, "customer drives away")
	await advance(14.0)
	check(game.traffic.state == game.traffic.State.WAITING and game.traffic.visits == 2, "next customer drives to the dispenser")
	click(game.hud.language)
	click(game.hud.power)
	check(game.hud.title.text == "Northpoint Station" and Engine.max_fps == 30, "live language and FPS controls")
	await capture("03-upgrade-en.png")
	game.free()
	game = mount()
	await process_frame
	check(game.economy.cash == 0 and game.economy.level == 2 and game.economy.customers == 1, "progress survives new scene")
	check(game.economy.language == "en" and game.economy.low_power, "settings survive new scene")
	check(game.economy.sell() == 48, "new tier pays configured rate")
	for tier in range(2, 5):
		var cost: int = game.economy.PROFILE.upgrade_cost(tier)
		game.economy.cash = cost
		game.hud.upgrade.pressed.emit()
		check(game.economy.level == tier + 1 and game.economy.cash == 0, "tier %d purchase" % (tier + 1))
	check(not game.economy.upgrade() and game.hud.upgrade.disabled, "level cap enforced")
	if not captures.is_empty():
		root.size = Vector2i(810, 1080)
		await process_frame
		check(controls_fit(), "tablet controls stay inside the viewport")
		await capture("04-tablet.png")
	var backup_cash: int = game.economy.cash
	game.economy.sell()
	check(game.economy.save_error == OK, "save succeeds")
	var corrupt := FileAccess.open(save_path, FileAccess.WRITE)
	corrupt.store_string("[incomplete")
	corrupt.close()
	game.economy.restore()
	check(game.economy.cash == backup_cash and game.economy.level == 5, "corrupt primary falls back to backup")
	for suffix in ["", ".backup", ".tmp"]:
		if FileAccess.file_exists(save_path + suffix):
			DirAccess.remove_absolute(save_path + suffix)
	print("Station smoke: %d/%d passed" % [checks - failures, checks])
	quit(1 if failures else 0)

func mount() -> Node3D:
	var instance := Main.instantiate()
	instance.economy.storage.path = save_path
	root.add_child(instance)
	return instance

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", description)

func controls_fit() -> bool:
	var viewport := root.get_visible_rect()
	for button in [game.hud.serve, game.hud.upgrade, game.hud.language, game.hud.power, game.hud.lighting, game.hud.view]:
		if not viewport.encloses(button.get_global_rect()):
			return false
	return true

func click(button: Button) -> void:
	var point := button.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = point
		event.global_position = point
		root.push_input(event, true)

func advance(seconds: float) -> void:
	# Run through fixed-size steps while the normal frame loop is paused.
	game.traffic.set_process(false)
	game.set_process(false)
	for step in range(roundi(seconds * 30.0)):
		game.traffic._process(1.0 / 30.0)
		game._process(1.0 / 30.0)
	await process_frame

func capture(filename: String) -> void:
	if captures.is_empty():
		return
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := captures.path_join(filename)
	check(image != null and image.save_png(path) == OK, "screenshot " + filename)
