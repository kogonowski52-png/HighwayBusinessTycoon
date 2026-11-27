extends "res://tests/station_smoke.gd"
## Capture localized game state at the native size of each store slot.

const ATLAS = preload("res://data/world/atlas.gd")
const VEHICLES = preload("res://data/visual/vehicle_catalog.gd")
const MANAGERS = preload("res://data/economy/managers.gd")
const PRODUCTS = preload("res://data/monetization/config.gd")
const SHOP_COPY = preload("res://localization/monetization.gd")
const SIZES := {"06_TELEFON": Vector2i(1080, 1920), "07_TABLET_7": Vector2i(1200, 1920),
	"08_TABLET_10": Vector2i(1600, 2560)}
const AT := 1795770000

func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			captures = argument.trim_prefix("--capture-dir=")
	if captures.is_empty():
		expect(false, "choose a destination for publishing evidence")
		result("Publishing listing")
		return
	DirAccess.make_dir_recursive_absolute(captures)
	write_catalog()
	if "--catalog-only" in OS.get_cmdline_user_args():
		result("Publishing catalogue")
		return
	if DisplayServer.get_name() == "headless":
		expect(false, "listing images require a real game viewport")
		result("Publishing listing")
		return
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.borderless = true
	root.position = Vector2i.ZERO
	root.size = SIZES["06_TELEFON"]
	save_path = "/tmp/hbt-publishing-%d.cfg" % OS.get_process_id()
	game = mount(AT)
	current_scene = game
	develop_site(25, ["motel", "charge"])
	step(22.0)
	game.select_site("fuel")
	game.aim_camera(Vector3(1.3, .5, -6), Vector3(18, 35, 31), 50)
	await capture_states("01-empire", 1)
	game.open_page("upgrades")
	game.aim_camera(game.campus.focus("fuel") + Vector3(0, 0, 2), Vector3(11, 24, 22), 26)
	await capture_states("02-fuel-station")
	game.select_site("wash")
	game.open_page("sites")
	await capture_states("03-open-businesses", 2)
	game.operations.hide_page()
	game.select_site("workshop")
	game.open_page("team")
	await capture_states("04-manage-team")
	game.operations.hide_page()
	game.select_site("truck")
	var freight: HbtVisit = game.traffic.dispatch.try_admit("trucker", "truck", "atlas")
	step(5.5)
	if freight == null:
		freight = game.traffic.dispatch.try_admit("trucker", "truck", "atlas")
		step(6.0)
	expect(freight != null, "real truck visit enters the campaign queue")
	game.aim_camera(game.campus.focus("truck"), Vector3(11, 21, 26), 30)
	await capture_states("05-serve-traffic", 3)
	game.open_page("managers")
	await capture_states("07-managers")
	game.operations.hide_page()
	var paid: HbtAmount = game.economy.capture_absence(game.economy.high_water + 78 * 60)
	expect(not paid.empty(), "offline panel derives earnings from staffed businesses")
	game.open_page("offline")
	await capture_states("08-offline-income")
	game.claim_offline()
	game.travel_to("desert")
	if await arrive("desert"):
		develop_site(22)
		step(5.0)
		game.select_site("fuel")
		game.aim_camera(Vector3(-1, .5, -7), Vector3(22, 35, 37), 42)
		await capture_states("06-new-districts")
		game.open_page("atlas")
		await capture_states("04-world-atlas", 4, false)
		await check_privacy()
	else:
		expect(false, "real campaign travel to Desert Highway")
	root.get_node("RouteAudio").shut_down()
	game.free()
	await create_timer(.18).timeout
	clean_save(save_path)
	result("Publishing listing")

func develop_site(tier: int, future_sites: Array[String] = []) -> void:
	game.operations.hide_page()
	game.skip_tutorial()
	game.choose_weather("clear")
	game.economy.preferences.auto_day = false
	game.set_quality(1)
	game.set_look(game.lighting.Look.DAY)
	var estate: HbtEconomy = game.economy
	estate.credit("cash", HbtAmount.from(290_000))
	estate.credit("reputation", HbtAmount.from(170))
	estate.buy_levels("fuel", tier)
	for id: String in estate.facilities:
		if id != "fuel" and id not in future_sites and estate.unlock(id):
			estate.buy_levels(id, tier)
		if estate.level(id) > 0:
			estate.hire(id)
			estate.train(id, 0)
	for director in ["sana", "reese", "mira"]:
		estate.grant_reward({"card": director})
	estate.checkpoint()
	if is_instance_valid(game.hud.notice):
		game.hud.notice.queue_free()
	game.refresh()

func check_privacy() -> void:
	root.size = SIZES["06_TELEFON"]
	for locale in ["pl", "en"]:
		game.set_language(locale)
		game.open_page("settings")
		await create_timer(.22).timeout
		await click_row(game.t("privacy"))
		expect(game.operations.page == "privacy" and game.operations.header.text == game.t("privacy_header"),
			"settings opens the localized privacy page in " + locale)
		var copy: Array[Node] = game.operations.rows.find_children("*", "Label", true, false)
		expect(copy.any(func(label: Label) -> bool: return label.text == game.t("privacy_purchases_disabled")),
			"the offline privacy page describes disabled purchases in " + locale)
		expect(find_button(game.operations.rows, "kogonowski52@gmail.com") != null
			and find_button(game.operations.rows, game.t("privacy_read_online")) == null,
			"the privacy page shows contact and omits an unverified web link in " + locale)

func arrive(id: String) -> bool:
	for frame in 300:
		await process_frame
		var scene := current_scene
		if scene is Node3D and scene.get("mounted") == true and scene.economy.district == id:
			game = scene
			game.set_physics_process(false)
			return true
	return false

func capture_states(stem: String, tablet := 0, phone := true) -> void:
	for locale in ["pl", "en"]:
		game.set_language(locale)
		if is_instance_valid(game.hud.notice):
			game.hud.notice.hide()
		if phone:
			await photo("06_TELEFON", locale, stem)
		if tablet > 0:
			for folder in ["07_TABLET_7", "08_TABLET_10"]:
				await photo(folder, locale, "%02d-%s" % [tablet, stem.substr(3)])

func photo(folder: String, locale: String, stem: String) -> void:
	var screen: Vector2i = SIZES[folder]
	root.size = screen
	for frame in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var target := captures.path_join(folder).path_join(locale.to_upper())
	DirAccess.make_dir_recursive_absolute(target)
	var pixels := root.get_texture().get_image()
	expect(pixels != null and pixels.get_size() == screen and pixels.save_jpg(target.path_join(stem + ".jpg"), .93) == OK,
		"native %s · %s · %s" % [str(screen), locale, stem])

func write_catalog() -> void:
	var services := {}
	for id: String in ATLAS.DESTINATIONS:
		services[id] = HbtEconomy.new(id).facilities.keys()
	var products := {}
	for id: String in PRODUCTS.PRODUCTS:
		products[id] = PRODUCTS.product(id).duplicate(true)
		products[id].label = SHOP_COPY.COPY["product_" + id]
	for index in PRODUCTS.SEASONS.size():
		var season: Dictionary = PRODUCTS.season_profile(index)
		products[season.sku] = PRODUCTS.product(season.sku)
		products[season.sku].label = SHOP_COPY.COPY["product_" + season.sku]
		products[season.sku].start = season.start
		products[season.sku].end = season.end
	var info := {"version": ProjectSettings.get_setting("application/config/version"),
		"services": services, "vehicles": VEHICLES.VEHICLES.keys(), "managers": MANAGERS.ROSTER.keys(), "products": products}
	var report := FileAccess.open(captures.path_join("catalog.json"), FileAccess.WRITE)
	expect(report != null, "write inventory from shipped Godot resources")
	if report != null:
		report.store_string(JSON.stringify(info, "\t") + "\n")
