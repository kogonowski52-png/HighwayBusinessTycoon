extends "res://tests/mobile_input_window.gd"

const AdSource = preload("res://tests/reward_fixture.gd")

var gallery := ""

func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			gallery = argument.get_slice("=", 1)
	if gallery.is_empty() or DisplayServer.get_name() == "headless":
		quit(2)
		return
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.borderless = true
	root.position = Vector2i.ZERO
	root.size = Vector2i(720, 1280)
	save_path = "/tmp/hbt-play-listing-%d.cfg" % OS.get_process_id()
	game = mount(Revenue.SEASON_EPOCH + 3600)
	current_scene = game
	game.skip_tutorial()
	game.set_look(game.lighting.Look.DAY)
	var economy: HbtEconomy = game.economy
	economy.credit("cash", HbtAmount.from(100_000))
	economy.credit("reputation", HbtAmount.from(400))
	economy.buy_levels("fuel", 23)
	for id in ["market", "wash", "workshop"]:
		if economy.unlock(id):
			economy.buy_levels(id, 6)
			economy.hire(id)
	economy.hire("fuel")
	game.campaign.freight.buy(game.campaign, "van")
	game.campaign.freight.hire(game.campaign)
	game.campaign.freight.assign(game.campaign, "1", "2")
	game.sync_depot()
	var source := AdSource.new()
	game.ads.connect_provider(source)
	await settle()
	game.select_site("fuel")
	await shot("phone", "01-north-station")
	game.select_site("wash")
	await shot("phone", "02-car-wash")
	game.select_site("workshop")
	game.open_page("upgrades")
	await shot("phone", "03-workshop-upgrades")
	game.open_page("team")
	await shot("phone", "04-crew")
	game.open_page("fleet")
	await shot("phone", "05-fleet")
	game.open_page("atlas")
	await shot("phone", "06-world-atlas")
	game.open_page("empire")
	await shot("phone", "07-empire")
	game.open_page("free_rewards")
	await shot("phone", "08-free-rewards")

	root.size = Vector2i(800, 1280)
	game.operations.hide_page()
	game.select_site("fuel")
	await shot("tablet-7-inch", "01-station")
	game.open_page("shop_featured")
	await shot("tablet-7-inch", "02-store")
	root.size = Vector2i(1200, 1920)
	game.open_page("atlas")
	await shot("tablet-10-inch", "01-atlas")
	game.open_page("free_rewards")
	await shot("tablet-10-inch", "02-rewards")
	game.free()
	root.get_node("RouteAudio").shut_down()
	await create_timer(.18).timeout
	clean_save(save_path)
	result("Play listing from rendered game viewports")

func shot(folder: String, name: String) -> void:
	for frame in 7:
		await process_frame
	await RenderingServer.frame_post_draw
	var target := gallery.path_join(folder)
	DirAccess.make_dir_recursive_absolute(target)
	var pixels := root.get_texture().get_image()
	expect(pixels != null and pixels.save_jpg(target.path_join(name + ".jpg"), .92) == OK, "real viewport " + name)
