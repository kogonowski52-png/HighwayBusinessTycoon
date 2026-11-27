extends SceneTree
## Same scripted viewport, camera, save and workload can run on both sides of a comparison.

const Atlas = preload("res://data/world/atlas.gd")
const FRONT := "res://scenes/ui/front_gate.tscn"
const SIZE := Vector2i(486, 864)

var game: Node3D
var capture_dir := ""
var report_file := ""
var district_limit := 6
var first_quality := 0
var quality_limit := 3
var panoramas := true
var roundtrips := 0
var revisits: Array[Dictionary] = []
var frames := 32
var rows: Array[Dictionary] = []
var startup: Dictionary = {}
var travel: Dictionary = {}
var profile_path := "/tmp/hbt-perf-window-%d.cfg" % OS.get_process_id()

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	for option in OS.get_cmdline_user_args():
		if option.begins_with("--capture-dir="):
			capture_dir = option.get_slice("=", 1)
		elif option.begins_with("--report="):
			report_file = option.get_slice("=", 1)
		elif option.begins_with("--districts="):
			district_limit = clampi(int(option.get_slice("=", 1)), 1, Atlas.DESTINATIONS.size())
		elif option.begins_with("--first-quality="):
			first_quality = clampi(int(option.get_slice("=", 1)), 0, 3)
		elif option.begins_with("--roundtrips="):
			roundtrips = clampi(int(option.get_slice("=", 1)), 0, 5)
		elif option == "--no-panorama":
			panoramas = false
		elif option.begins_with("--qualities="):
			quality_limit = clampi(int(option.get_slice("=", 1)), 1, 4)
		elif option.begins_with("--frames="):
			frames = maxi(12, int(option.get_slice("=", 1)))
	if DisplayServer.get_name() == "headless":
		fail("A real renderer is required")
		return
	if not capture_dir.is_empty():
		DirAccess.make_dir_recursive_absolute(capture_dir)
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.size = SIZE
	root.position = Vector2i.ZERO
	root.borderless = true
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var title_start := Time.get_ticks_usec()
	var gate: Control = load(FRONT).instantiate()
	gate.profile_path = profile_path
	root.add_child(gate)
	current_scene = gate
	await RenderingServer.frame_post_draw
	startup.first_title_ms = elapsed_ms(title_start)
	var play_start := Time.get_ticks_usec()
	gate.begin_loading()
	if not await arrived("north"):
		fail("Title did not load North")
		return
	startup.title_to_world_ms = elapsed_ms(play_start)
	for id: String in Atlas.DESTINATIONS.keys().slice(0, district_limit):
		if id != "north":
			var begins := Time.get_ticks_usec()
			game.travel_to(id)
			if not await arrived(id):
				fail("Could not travel to " + id)
				return
			travel[id] = elapsed_ms(begins)
		develop()
		game.camera_rig.cancel_film(true)
		game.operations.hide_page()
		game.aim_camera(game.campus.focus("fuel"), Vector3(16, 36, 31), 39.0)
		game.economy.preferences.auto_day = false
		game.set_look(game.lighting.Look.DAY)
		if id == "alpine":
			game.choose_weather("snow")
		for quality in range(first_quality, quality_limit):
			await sample(id, quality)
		if panoramas and not capture_dir.is_empty():
			game.set_quality(2)
			game.toggle_view()
			game.frame_camera()
			await wait_frames(14)
			shot(id + "-panorama")
			game.toggle_view()
	if roundtrips > 0 and not await loop_maps():
		fail("Repeated travel failed")
		return
	var output := {"renderer": RenderingServer.get_current_rendering_method(), "driver": RenderingServer.get_video_adapter_name(),
		"size": [SIZE.x, SIZE.y], "frames": frames, "startup": startup, "travel_ms": travel, "viewports": rows, "return_passes": revisits}
	if not report_file.is_empty():
		var file := FileAccess.open(report_file, FileAccess.WRITE)
		file.store_string(JSON.stringify(output, "\t") + "\n")
	print("Rendered benchmark: %d samples, %s" % [rows.size(), JSON.stringify(startup)])
	game.free()
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(profile_path + suffix)
	quit()

func loop_maps() -> bool:
	game.set_quality(1)
	for pass_index in range(roundtrips + 1):
		var order := ["north"] if pass_index == 0 else Atlas.DESTINATIONS.keys().slice(1) + ["north"]
		for id: String in order:
			game.travel_to(id)
			if not await arrived(id):
				return false
			if root.get_children().filter(func(node: Node) -> bool: return node.has_method("tick_game")).size() != 1:
				return false
		await wait_frames(25)
		var entry := {"pass": pass_index, "nodes": get_node_count(), "rss_kib": process_rss(),
			"heap_bytes": OS.get_static_memory_usage(), "vram_bytes": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
			"viewport": "north", "objects": Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)}
		revisits.append(entry)
		print("RETURN ", JSON.stringify(entry))
	return true

func arrived(id: String) -> bool:
	for _frame in 240:
		await process_frame
		if is_instance_valid(current_scene) and current_scene.has_method("tick_game") and current_scene.economy.district == id:
			game = current_scene
			game.set_physics_process(false)
			game.wall_override = game.economy.clock
			game.seed_override = 68427
			game.traffic.dispatch.demand.random.seed = 68427
			await RenderingServer.frame_post_draw
			return true
	return false

func develop() -> void:
	var estate: HbtEconomy = game.economy
	game.skip_tutorial()
	estate.credit("cash", HbtAmount.from("1000000000000000000000"))
	estate.credit("reputation", HbtAmount.from(1000))
	for id: String in estate.facilities:
		if id != "fuel":
			estate.unlock(id)
		if estate.level(id) > 0:
			estate.levels[id] = 62
			estate.hire(id)
			if estate.capacity(id) > 1:
				estate.hire(id)
	estate.touch()
	for _frame in 720:
		game.tick_game(1.0 / 60.0)
	await wait_frames(5)

func sample(id: String, quality: int) -> void:
	game.set_quality(quality)
	await wait_frames(7)
	var timings: Array[float] = []
	var draws: Array[int] = []
	var primitives: Array[int] = []
	var objects: Array[int] = []
	for _frame in frames:
		var start := Time.get_ticks_usec()
		game.tick_game(1.0 / 60.0)
		await RenderingServer.frame_post_draw
		timings.append(elapsed_ms(start))
		objects.append(root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_OBJECTS_IN_FRAME))
		draws.append(root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME))
		primitives.append(root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME))
	var mean: float = timings.reduce(func(acc: float, next: float) -> float: return acc + next, 0.0) / frames
	timings.sort()
	draws.sort()
	primitives.sort()
	objects.sort()
	var row := {"district": id, "quality": quality, "fps": 1000.0 / mean, "median_ms": timings[frames / 2],
		"p95_ms": timings[ceili(frames * 0.95) - 1], "draws": draws[frames / 2], "primitives": primitives[frames / 2],
		"objects": objects[frames / 2], "nodes": get_node_count(), "rss_kib": process_rss(),
		"heap_bytes": OS.get_static_memory_usage(), "vram_bytes": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
		"scale": root.scaling_3d_scale, "msaa": root.msaa_3d}
	rows.append(row)
	print("PERF ", JSON.stringify(row))
	shot("%s-q%d" % [id, quality])

func wait_frames(count: int) -> void:
	for _frame in count:
		await RenderingServer.frame_post_draw

func shot(name: String) -> void:
	if not capture_dir.is_empty():
		var image := root.get_texture().get_image()
		if image.save_jpg(capture_dir.path_join(name + ".jpg"), .92) != OK:
			push_error("Could not save " + name)

func process_rss() -> int:
	var file := FileAccess.open("/proc/%d/status" % OS.get_process_id(), FileAccess.READ)
	if file != null:
		while not file.eof_reached():
			var line := file.get_line()
			if line.begins_with("VmRSS:"):
				return int(line.trim_prefix("VmRSS:").strip_edges().split(" ")[0])
	return 0

func elapsed_ms(start: int) -> float:
	return (Time.get_ticks_usec() - start) / 1000.0

func fail(message: String) -> void:
	printerr(message)
	quit(1)
