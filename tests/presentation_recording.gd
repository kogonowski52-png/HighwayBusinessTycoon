extends SceneTree
## Run with Godot Movie Maker for a short real gameplay recording.

const Front = preload("res://scenes/ui/front_gate.tscn")
var save_path: String

func _initialize() -> void:
	demo.call_deferred()

func demo() -> void:
	var boot_only := "--boot-check" in OS.get_cmdline_user_args()
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.size = Vector2i(486, 864)
	root.borderless = true
	root.position = Vector2i.ZERO
	var title := Front.instantiate()
	save_path = "/tmp/hbt-demo-%d.cfg" % OS.get_process_id()
	title.profile_path = save_path
	root.add_child(title)
	current_scene = title
	if boot_only:
		await process_frame
	else:
		await create_timer(1.09).timeout
	press(title.play)
	for frame in range(240):
		if current_scene != title:
			break
		await process_frame
	if not current_scene is Node3D:
		quit(1)
		return
	var game := current_scene
	if boot_only:
		var ready: bool = game.mounted and game.economy.storage.path == save_path
		print("Cold title launch: ", "passed" if ready else "failed")
		await close_demo(game)
		quit(0 if ready else 1)
		return
	await create_timer(0.82).timeout
	press(game.hud.serve)
	await create_timer(2.95).timeout
	press(game.hud.upgrade)
	await create_timer(1.51).timeout
	press(game.hud.pages.goals)
	await create_timer(0.62).timeout
	await choose(game, game.t("claim"))
	await choose(game, game.t("claim"))
	press(game.operations.back)
	await create_timer(0.34).timeout
	press(game.hud.pages.team)
	await create_timer(0.57).timeout
	await choose(game, game.t("recruit") % game.money(game.economy.recruit_cost("fuel")))
	press(game.operations.back)
	await create_timer(0.40).timeout
	press(game.hud.pages.calendar)
	await create_timer(1.28).timeout
	await choose(game, game.t("calendar_claim") % 1)
	await create_timer(1.45).timeout
	press(game.operations.back)
	await create_timer(0.40).timeout
	press(game.hud.view)
	await create_timer(1.40).timeout
	print("Demo verified: fuel level %d, workers %d, calendar %d, shot %.2f" % [game.economy.level("fuel"),
		game.economy.crew.fuel.size(), game.economy.recognition.daily_count, game.camera.size])
	var complete: bool = game.economy.level("fuel") == 2 and game.economy.crew.fuel.size() == 1 \
		and game.economy.recognition.daily_count == 1 and game.overview
	await close_demo(game)
	quit(0 if complete else 1)

func close_demo(game: Node3D) -> void:
	game.queue_free()
	await game.tree_exited
	for frame in range(4):
		await process_frame
	for suffix in ["", ".backup", ".tmp", ".backup.tmp"]:
		if FileAccess.file_exists(save_path + suffix):
			DirAccess.remove_absolute(save_path + suffix)

func choose(game: Node3D, text: String) -> void:
	for item: Button in game.operations.rows.find_children("*", "Button", true, false):
		if item.text == text and not item.disabled:
			game.operations.scroll.ensure_control_visible(item)
			await process_frame
			press(item)
			await create_timer(0.52).timeout
			return

func press(button: Button) -> void:
	if not is_instance_valid(button) or not button.is_visible_in_tree():
		return
	var at := button.get_global_rect().get_center()
	for value in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = at
		event.global_position = at
		event.pressed = value
		root.push_input(event, true)
