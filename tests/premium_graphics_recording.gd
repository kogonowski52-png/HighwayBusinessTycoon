extends "res://tests/expedition_recording.gd"
## Records a paid fuel service followed by a real canopy upgrade in the portrait game.

const Station = preload("res://scenes/world/roadside.tscn")

func run() -> void:
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.size = Vector2i(486, 864)
	root.borderless = true
	root.position = Vector2i.ZERO
	path = "/tmp/hbt-graphics-film-%d.cfg" % OS.get_process_id()
	var site := Station.instantiate()
	site.economy.storage.path = path
	site.seed_override = 41
	site.wall_override = 1_789_000_000
	root.add_child(site)
	current_scene = site
	site.skip_tutorial()
	site.economy.preferences.auto_day = false
	site.choose_weather("clear")
	site.set_quality(2)
	site.economy.credit("cash", HbtAmount.from(7_500))
	site.economy.credit("reputation", HbtAmount.from(25))
	site.economy.buy_levels("fuel", 3)
	site.economy.unlock("market")
	site.frame_camera()
	await create_timer(.65).timeout
	press(site.hud.serve)
	await create_timer(2.95).timeout
	press(site.hud.upgrade)
	await create_timer(2.30).timeout
	press(site.hud.lighting)
	await create_timer(.58).timeout
	press(site.hud.lighting)
	await create_timer(.58).timeout
	press(site.hud.lighting)
	await create_timer(1.05).timeout
	var passed: bool = site.economy.customers > 0 and site.economy.level("fuel") == 5 \
		and site.station.canopy.scene_file_path.ends_with("canopy_ridge.glb")
	print("Graphics gameplay: %s, customers=%d, stage=%d" % [passed, site.economy.customers, site.economy.level("fuel")])
	root.get_node("RouteAudio").shut_down()
	site.queue_free()
	await site.tree_exited
	await create_timer(.12).timeout
	finish(passed)
