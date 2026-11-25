extends "res://tests/station_smoke.gd"
## Captures are from the game viewport. Test callbacks are visibly labelled.

const Config = preload("res://data/monetization/config.gd")
const Fixture = preload("res://tests/reward_fixture.gd")
var screenshots := 0
var provider: Fixture
var banner: CanvasLayer

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			captures = arg.trim_prefix("--capture-dir=")
	if DisplayServer.get_name() == "headless":
		expect(false, "window renderer required for evidence")
		result("Monetization window")
		return
	if not captures.is_empty():
		DirAccess.make_dir_recursive_absolute(captures)
	save_path = "/tmp/hbt-070-window-%d.cfg" % OS.get_process_id()
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.size = Vector2i(640, 1138)
	root.borderless = true
	root.position = Vector2i.ZERO
	game = mount(Config.SEASON_EPOCH + 100)
	current_scene = game
	game.skip_tutorial()
	await scene_photo("01-trasa17-hud.jpg")
	click(game.hud.boost_button)
	await scene_photo("02-boost-bez-polaczenia.jpg")
	expect(game.operations.page == "boost", "HUD opens boost panel")
	await close_sheet()
	await show("shop", "03-start-sklep.jpg")
	var shop = game.operations.premium
	shop.choose_tab("shop_packs")
	await scene_photo("04-pakiety-diamentow.jpg")
	await reveal("Pakiet rozbudowy")
	await scene_photo("05-pakiet-rozbudowy.jpg")
	shop.choose_tab("shop_free")
	await scene_photo("06-darmowe-bonusy.jpg")
	shop.choose_tab("shop_season")
	await scene_photo("07-sklep-sezon.jpg")
	expect(game.purchases.catalogue.is_empty() and not game.purchases.verified_checkout(), "desktop has no invented prices or checkout")
	await show("pass", "08-przepustka-darmowa.jpg")
	shop.change_track("pass_premium")
	await scene_photo("09-przepustka-premium-zablokowana.jpg")
	await show("atlas", "10-atlas-tras.jpg")
	await show("settings", "11-ustawienia-i-diagnostyka.jpg")
	await show("privacy", "12-prywatnosc.jpg")
	await close_sheet()

	provider = Fixture.new()
	game.ads.connect_provider(provider)
	mark_fixture()
	game.open_page("boost")
	await scene_photo("13-boost-przygotowanie.jpg")
	await click_row(game.t("ad_prepare"))
	await scene_photo("14-boost-film-gotowy.jpg")
	await click_row(game.t("boost_watch"))
	expect(game.ads.busy(), "native contract waits for a callback")
	await scene_photo("15-oczekiwanie-na-zdarzenie.jpg")
	provider.finish(true, true)
	await scene_photo("16-boost-aktywny.jpg")
	expect(game.campaign.boost.remaining(game.economy.clock) == 300, "viewport activation is real and idempotent")
	await close_sheet()
	await scene_photo("17-zloty-licznik-w-swiecie.jpg")
	await show("boost", "18-boost-przedluzenie.jpg")
	for repeat in 5:
		game.ads.prepare("boost")
		expect(game.ads.request("boost"), "full extension requested")
		provider.finish(true)
	await scene_photo("19-limit-trzydziesci-minut.jpg")
	expect(not game.ads.playable("boost"), "ad button gated at cap")
	await close_sheet()

	var estate: HbtEconomy = game.economy
	estate.credit("cash", HbtAmount.from(30_500))
	estate.credit("reputation", HbtAmount.from(40))
	estate.hire("fuel")
	estate.buy_levels("fuel", 10)
	await show("upgrades", "20-oferta-modernizacji.jpg")
	if game.ads.playable("upgrade", {"site": "fuel"}):
		await click_row(game.t("offer_upgrade"))
		await scene_photo("21-szczegoly-modernizacji.jpg")
	await close_sheet()
	game.aim_camera(Vector3(0, .2, 7), Vector3(7.0, 19, 22), 27)
	for row in [["vip", "regency", "22-vip-na-drodze.jpg"], ["cash", "post", "23-furgonetka.jpg"],
			["delivery", "cargo", "24-zlota-ciezarowka.jpg"], ["gift", "helicopter", "25-helikopter.jpg"]]:
		game.world_offers.spawn(row[0], row[1])
		game.world_offers.tick(12.5)
		await scene_photo(row[2])
		expect(is_instance_valid(game.world_offers.actor), "3D event active " + str(row[1]))
	game.world_offers.offer()
	await scene_photo("26-oferta-helikoptera.jpg")
	expect(not game.ads.busy() and game.operations.page == "reward_offer", "touching world reward asks first")
	await close_sheet()
	for trade in 100:
		game.campaign.premium.record_season(estate.clock, {"repairs": 1}, 6)
	game.open_page("pass")
	game.operations.premium.change_track("pass_free")
	await scene_photo("27-przepustka-postep.jpg")
	var season := Config.season_at(estate.clock)
	game.campaign.premium.entitlements[season.sku] = true
	game.operations.premium.change_track("pass_premium")
	await scene_photo("28-przepustka-premium-test.jpg")
	game.claim_pass(0, 5, true)
	expect(game.campaign.premium.progress(season.sku).premium.has("5"), "the entitled track pays a real reward")
	await close_sheet()
	estate.high_water = estate.clock
	estate.capture_absence(estate.clock + 2200)
	await show("offline", "29-zarobki-offline-z-boost.jpg")
	expect(not estate.offline_pending.empty() and not estate.offline_boosted.empty(), "offline screen shows real partial interval income")
	await close_sheet()
	game.set_language("en")
	await show("boost", "30-boost-en.jpg")
	expect(game.t("boost_active") == "BOOST active" and controls_fit(), "controls fit and English localization")
	if not captures.is_empty():
		expect(screenshots >= 25, "at least 25 real viewport screenshots")
	game.free()
	await process_frame
	clean_save(save_path)
	result("Monetization window")

func mark_fixture() -> void:
	banner = CanvasLayer.new()
	banner.layer = 9
	game.add_child(banner)
	var label := Label.new()
	label.text = "PRÓBA SILNIKA · SYGNAŁ SDK Z DANYCH TESTOWYCH"
	label.position = Vector2(22, 254)
	label.add_theme_color_override("font_color", Color("#fff5d7"))
	label.add_theme_color_override("font_outline_color", Color("#20373e"))
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_font_size_override("font_size", 19)
	banner.add_child(label)

func show(page: String, file: String) -> void:
	game.open_page(page)
	await scene_photo(file)

func reveal(title: String) -> void:
	for child in game.operations.rows.find_children("*", "Label", true, false):
		if child.text == title:
			game.operations.scroll.ensure_control_visible(child)
			await process_frame
			return

func scene_photo(file: String) -> void:
	await create_timer(.21).timeout
	await process_frame
	if captures.is_empty():
		return
	await RenderingServer.frame_post_draw
	var pix := root.get_texture().get_image()
	var done := pix.save_jpg(captures.path_join(file), .91) == OK
	expect(done, "rendered screenshot " + file)
	screenshots += int(done)
