extends "res://tests/expedition_recording.gd"

const Main = preload("res://scenes/world/roadside.tscn")
const Fixture = preload("res://tests/reward_fixture.gd")
const Config = preload("res://data/monetization/config.gd")

func run() -> void:
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.size = Vector2i(486, 864)
	root.borderless = true
	root.position = Vector2i.ZERO
	path = "/tmp/hbt-070-movie-%d.cfg" % OS.get_process_id()
	var site := Main.instantiate()
	site.wall_override = Config.SEASON_EPOCH + 700
	site.economy.storage.path = path
	site.seed_override = 27
	root.add_child(site)
	current_scene = site
	site.skip_tutorial()
	site.traffic.dispatch.spawning = false
	var test_source := Fixture.new()
	site.ads.connect_provider(test_source)
	var layer := CanvasLayer.new()
	layer.layer = 15
	site.add_child(layer)
	var context := Label.new()
	layer.add_child(context)
	context.text = "TEST SILNIKA · KONTROLOWANE ZDARZENIE SDK"
	context.position = Vector2(31, 237)
	context.add_theme_font_size_override("font_size", 22)
	context.add_theme_color_override("font_color", Color("#fff1ce"))
	context.add_theme_color_override("font_outline_color", Color("#23363a"))
	context.add_theme_constant_override("outline_size", 6)
	await create_timer(.7).timeout
	press(site.hud.boost_button)
	await create_timer(1.15).timeout
	await select_button(site, site.t("ad_prepare"))
	await create_timer(1.10).timeout
	await select_button(site, site.t("boost_watch"))
	await create_timer(.78).timeout
	var requested: bool = site.ads.busy()
	test_source.finish(true, true)
	await create_timer(2.0).timeout
	press(site.operations.back)
	await create_timer(.55).timeout
	var estimate: HbtAmount = site.traffic.dispatch.visit_at("fuel", 0).invoice
	if estimate.empty():
		estimate = site.economy.price("fuel")
	var cash: HbtAmount = site.economy.amount("cash")
	press(site.hud.serve)
	await create_timer(4.08).timeout
	var real_income: HbtAmount = site.economy.amount("cash").minus(cash)
	press(site.hud.boost_button)
	await create_timer(2.15).timeout
	var left: int = site.campaign.boost.remaining(site.economy.clock)
	if site.campaign.boost.windows.is_empty():
		finish(false)
		return
	var window: PackedInt64Array = site.campaign.boost.windows[0]
	print("BOOST film %s, started=%s, duration=%d, actual earning=%s, base=%s" %
		[requested and not real_income.empty(), requested, window[1] - window[0], real_income.decimal(), estimate.decimal()])
	var audio := root.get_node("RouteAudio")
	audio.set_process(false)
	for player in audio.get_children():
		if player is AudioStreamPlayer:
			player.stop()
	site.queue_free()
	await site.tree_exited
	for frame in 5:
		await process_frame
	finish(requested and left in range(280, 300) and real_income.compare(estimate.times(2)) >= 0)
