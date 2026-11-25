extends SceneTree
## Godot Movie Maker demo using the visible title, atlas and actual payment controls.

const Front = preload("res://scenes/ui/front_gate.tscn")
var path: String

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.size = Vector2i(486, 864)
	root.borderless = true
	root.position = Vector2i.ZERO
	path = "/tmp/hbt-copper-film-%d.cfg" % OS.get_process_id()
	var source := HbtEconomy.new()
	source.storage.path = path
	source.restore()
	source.finish_tutorial()
	source.credit("cash", HbtAmount.from(3800))
	source.credit("reputation", HbtAmount.from(12))
	source.buy_levels("fuel", 3)
	source.hire("fuel")
	source.preferences.weather = "clear"
	source.checkpoint()
	var title := Front.instantiate()
	title.profile_path = path
	root.add_child(title)
	current_scene = title
	await create_timer(.9).timeout
	press(title.play)
	var north := await district("north")
	if north == null:
		finish(false)
		return
	await create_timer(.55).timeout
	press(north.hud.pages.atlas)
	await create_timer(1.6).timeout
	await select_button(north, "Desert Highway")
	await create_timer(1.52).timeout
	await select_button(north, north.t("district_open") % north.money(HbtAmount.from(670)))
	var desert := await district("desert")
	if desert == null:
		finish(false)
		return
	await create_timer(.94).timeout
	press(desert.hud.serve)
	await create_timer(3.78).timeout
	press(desert.hud.upgrade)
	await create_timer(.72).timeout
	press(desert.hud.pages.atlas)
	await create_timer(.56).timeout
	await select_button(desert, desert.t("seasons_header"))
	await create_timer(1.42).timeout
	press(desert.operations.back)
	await create_timer(.39).timeout
	press(desert.hud.view)
	await create_timer(1.23).timeout
	var succeeded: bool = desert.economy.customers > 0 and desert.economy.level("fuel") == 2 and desert.overview 		and desert.campaign.districts.north.level("fuel") == 4
	print("Journey recorded: district=%s, customers=%d, fuel level=%d" %
		[desert.economy.district, desert.economy.customers, desert.economy.level("fuel")])
	var audio := root.get_node("RouteAudio")
	audio.set_process(false)
	for player in audio.get_children():
		if player is AudioStreamPlayer:
			player.stop()
	desert.queue_free()
	await desert.tree_exited
	for frame in range(5):
		await process_frame
	finish(succeeded)

func district(id: String) -> Node3D:
	for frame in 230:
		await process_frame
		var node := current_scene
		if node is Node3D and node.mounted and node.economy.district == id:
			return node
	return null

func select_button(game: Node3D, label: String) -> void:
	for control in game.operations.rows.find_children("*", "Button", true, false):
		var item := control as Button
		if item.text == label and not item.disabled:
			game.operations.scroll.ensure_control_visible(item)
			await process_frame
			press(item)
			return

func press(item: Button) -> void:
	if not is_instance_valid(item) or item.disabled or not item.is_visible_in_tree():
		return
	var point := item.get_global_rect().get_center()
	for released in [false, true]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.global_position = point
		event.pressed = not released
		root.push_input(event, true)

func finish(passed: bool) -> void:
	for suffix in ["", ".backup", ".tmp", ".backup.tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	quit(0 if passed else 1)
