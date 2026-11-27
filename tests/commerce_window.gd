extends "res://tests/mobile_input_window.gd"
## Exercise real viewport taps and scrolling. Only the Google callbacks are controlled by the test.

const Source = preload("res://tests/reward_fixture.gd")

class PlayBoundary extends RefCounted:
	signal billing_catalog(data: String)
	signal billing_state(source: String, code: int)
	signal billing_purchases(data: String)
	signal identity_result(token: String)

	var has_verifier := false
	var queries := 0
	var restored := 0
	var launch_ids: Array[String] = []

	func billingConfigured() -> bool: return true
	func identityConfigured() -> bool: return has_verifier
	func serviceMode() -> String: return "test"
	func installedFromPlay() -> bool: return false
	func purchaseEndpoint() -> String: return "https://127.0.0.1:1" if has_verifier else ""
	func startBilling(_ids: String) -> void: queries += 1
	func restoreBilling() -> void: restored += 1
	func launchBilling(id: String, _account: String) -> bool:
		launch_ids.append(id)
		return true

var source: Source
var play := PlayBoundary.new()

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			captures = arg.get_slice("=", 1)
		video = video or arg == "--record"
	if not captures.is_empty():
		DirAccess.make_dir_recursive_absolute(captures)
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.size = Vector2i(432, 768) if video else Vector2i(588, 1046)
	root.borderless = true
	root.position = Vector2i.ZERO
	save_path = "/tmp/hbt-commerce-%d.cfg" % OS.get_process_id()
	game = mount(Revenue.SEASON_EPOCH + 3600)
	current_scene = game
	game.skip_tutorial()
	game.set_look(game.lighting.Look.DAY)
	game.traffic.dispatch.spawning = false
	source = Source.new()
	source.auto_complete = false
	game.ads.connect_provider(source)
	await settle()
	if video:
		await record_ad_wait()
	else:
		await ads_on_first_touch()
		await check_shop()
		await test_catalogue_states()
		if DisplayServer.get_name() != "headless":
			await shop_layouts()
	game.free()
	root.get_node("RouteAudio").shut_down()
	await create_timer(.18).timeout
	clean_save(save_path)
	result("Commerce, first-touch ads and native boundaries")

func ads_on_first_touch() -> void:
	expect(source.requests.size() == 5 and source.screens == 0, "all ad placements preloaded without showing")
	game.open_page("boost")
	await settle()
	await tap_row(game.t("boost_watch"))
	expect(game.ads.waiting("boost") and source.screens == 0, "one touch during preload records intent")
	expect(has_label(game.t("ad_loading_wait")), "loading message is visible")
	await photo("10-boost-oczekiwanie")
	await tap_row(game.t("ad_cancel_wait"))
	source.complete("boost", true)
	await settle()
	expect(not game.ads.busy() and source.screens == 0, "cancel prevents presentation after the load callback")
	await tap_row(game.t("boost_watch"))
	expect(source.screens == 1 and game.ads.displaying() and root.get_node("RouteAudio").ad_fullscreen,
		"ready ad opens on first touch and suspends game audio")
	source.finish(false)
	await settle()
	expect(game.ads.placement_status("boost") == "reloading" and not root.get_node("RouteAudio").ad_fullscreen,
		"closing starts a new preload and restores game audio")
	expect(game.campaign.boost.remaining(game.economy.clock) == 0, "discarded ad pays nothing")
	await tap_row(game.t("boost_watch"))
	source.complete("boost", true)
	await settle()
	expect(source.screens == 2 and game.ads.displaying(), "a new load opens automatically from its callback")
	var receipt := source.ticket
	source.finish(true, true)
	await settle()
	expect(game.campaign.boost.remaining(game.economy.clock) == 300 and game.ads.reward_receipts == 1,
		"confirmed duplicate callbacks grant exactly one full 5-minute boost")
	expect(game.operations.modal_open() and game.operations.page == "boost" and not root.get_node("RouteAudio").ad_fullscreen,
		"reward returns to the same panel with game audio")
	game.ads.receive(receipt)
	expect(game.ads.reward_receipts == 1, "late callback from an expired ticket is ignored")
	await photo("11-boost-z-nagroda")
	await tap_row(game.t("boost_extend"))
	source.complete("boost", false)
	await settle()
	expect(game.ads.waiting("boost") and source.screens == 2, "SDK load error does not cause a presentation")
	game.ads.wait_until = Time.get_ticks_msec()
	game.ads.check_waiting()
	expect(not game.ads.busy() and game.ads.last_reward == "unavailable", "network or no-fill timeout unblocks the panel")
	source.complete("boost", true)
	await settle()
	expect(source.screens == 2, "retry after timeout warms the slot without showing")

	game.operations.premium.select_offer("cash", {})
	await settle()
	await tap_row(game.t("offer_watch"))
	await tap(game.operations.back)
	source.complete("bonus", true)
	await settle()
	expect(not game.ads.busy() and source.screens == 2, "closing the offer discards the wait across placements")

	game.operations.premium.select_offer("cash", {})
	await settle()
	source.reserve_only = true
	await tap_row(game.t("offer_watch"))
	expect(game.ads.displaying() and source.screens == 2, "native UI dispatch can still be pending")
	await tap(game.operations.back)
	expect(not game.ads.busy() and source.screens == 2, "a reserved display can be cancelled before the native activity opens")
	source.reserve_only = false

	game.operations.premium.select_offer("cash", {})
	await settle()
	var wallet: HbtAmount = game.economy.amount("cash")
	await tap_row(game.t("offer_watch"))
	source.fail_show()
	await settle()
	expect(game.ads.last_reward == "unavailable" and game.economy.amount("cash").compare(wallet) == 0,
		"native show failure stays ungranted")

	game.open_page("boost")
	await settle()
	source.complete("boost", false)
	await tap_row(game.t("boost_extend"))
	game._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	source.complete("boost", true)
	await settle()
	game._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	expect(source.screens == 3 and not game.ads.busy(), "backgrounding cancels a wait even when the ad subsequently loads")

	game.economy.offline_pending = HbtAmount.from(70)
	game.open_page("offline")
	await settle()
	await tap_row(game.t("claim_bonus") % game.money(HbtAmount.from(140)))
	source.complete("offline", true)
	await settle()
	expect(source.screens == 4 and game.ads.displaying(), "the offline offer uses the same first-touch wait")
	var cash: HbtAmount = game.economy.amount("cash")
	source.finish(true, true)
	await settle()
	expect(game.economy.amount("cash").compare(cash.plus(HbtAmount.from(140))) == 0 and not game.operations.modal_open(),
		"offline award pays once and closes its sheet after playback")

func check_shop() -> void:
	var premium: RefCounted = game.operations.premium
	await photo("00-map-quick-access")
	await tap(game.hud.wallet_links.shop_cash)
	expect(premium.shop_tab == "shop_cash" and game.operations.page == "shop", "cash plus opens the cash section")
	await tap(game.operations.back)
	await tap(game.hud.wallet_links.shop_gems)
	expect(premium.shop_tab == "shop_gems" and game.operations.page == "shop", "diamonds plus opens the gem section")
	await tap(game.operations.back)
	await tap(game.hud.pages.shop_special)
	expect(premium.shop_tab == "shop_special", "HUD promotions opens special offers")
	await tap(game.operations.back)
	await tap(game.hud.pages.free_rewards)
	expect(game.operations.page == "free_rewards" and has_label(game.t("offer_gift")) and has_label(game.t("offer_training")),
		"HUD opens a separate rewards center with disclosed prizes")
	await photo("00-free-reward-center")
	await tap(game.operations.back)
	await tap(game.hud.pages.shop)
	await settle()
	var expected := ["shop_feature_title", "free_rewards_header", "product_gems_100", "product_starter_pack", "offer_cash", "product_manager_pack",
		"product_builder_pack", "boost_offer_title", "pass_header", "product_remove_ads"]
	var i := 0
	for id: String in premium.SHOP_TABS:
		await choose_shop(id)
		expect(premium.shop_tab == id and has_label(game.t(expected[i])), "shop section opens via touch: " + id)
		if id == "shop_boost":
			expect(premium.boost_bar.value == 300 and has_label(game.t("boost_active") + "  ·  05:00"),
				"BOOST store tab shows the same countdown and progress")
		await photo("%02d-%s" % [i + 1, id])
		i += 1
	await tap(premium.tabs.shop_gems)
	var area: Rect2 = game.operations.scroll.get_global_rect()
	var start := area.position + Vector2(area.size.x * .66, 310)
	var camera: Vector3 = game.camera_rig.target
	touch(start, true)
	for index in range(1, 6):
		drag(start - Vector2(0, index * 34), Vector2(0, -34))
	touch(start - Vector2(0, 170), false, true)
	expect(game.operations.scroll.scroll_vertical > 100 and game.camera_rig.target == camera, "store drag leaves camera untouched")
	await tap(premium.tabs.shop_free)
	expect(game.operations.scroll.scroll_vertical == 0, "fixed tabs reset the scroll position")
	if source.rewardReady("gems"):
		source.complete("gems", false)
	await tap_row(game.t("offer_watch"))
	expect(game.ads.waiting("gift"), "free shop gift queues the first selection")
	await tap(premium.tabs.shop_gems)
	source.complete("gems", true)
	await settle()
	expect(source.screens == 4 and not game.ads.busy(), "changing the store tab cancels the previous gift")
	await choose_shop("shop_season")
	await tap_row(game.t("pass_view"))
	expect(game.operations.page == "pass" and premium.selected_pass().sku == Revenue.SEASONS[0].sku,
		"season tab opens the active pass")
	expect(has_label(game.t("pass_reward_tier") % Revenue.SEASON_TIERS), "season pass still renders 30 reward tiers")
	await tap(game.operations.back)

func choose_shop(id: String) -> void:
	var premium: RefCounted = game.operations.premium
	if premium.tabs.has(id):
		await tap(premium.tabs[id])
	else:
		await tap(premium.tabs.shop_featured)
		await tap_row(game.t(id))

func test_catalogue_states() -> void:
	game.purchases.connect_provider(play)
	game.open_page("shop")
	await settle()
	await choose_shop("shop_special")
	var store: Node = game.purchases
	expect(play.queries == 1 and store.catalog_status == "store_connect", "opening requests a real bridge catalogue once")
	play.billing_state.emit("catalog", 12)
	await settle()
	expect(store.catalogue.is_empty() and store.catalog_status == "store_catalog_network", "catalogue network error is distinct from no configured SKUs")
	await tap_row(game.t("store_retry"))
	expect(play.queries == 2, "Retry reconnects and queries again")
	play.billing_catalog.emit("{}")
	await settle()
	expect(store.catalog_status == "store_no_catalog" and has_label_part(game.t("store_sideload")),
		"empty Google result displays accurate sideload guidance")
	await tap_row(game.t("store_retry"))
	play.billing_catalog.emit('{"starter_pack":{"price":"9,99 zł"},"unknown":{"price":"0 zł"},"gems_550":{"price":""}}')
	await settle()
	expect(store.catalogue.size() == 1 and not store.purchasable("starter_pack") and has_label(game.t("store_price_no_checkout") % "9,99 zł"),
		"an actual localized price alone never enables checkout without verification")
	await photo("12-katalog-bez-weryfikacji")
	play.has_verifier = true
	store.on_verifier_checked(HTTPRequest.RESULT_SUCCESS, 200, [], '{"status":"ready","mode":"production"}'.to_utf8_buffer())
	expect(not store.purchasable("starter_pack"), "mismatched verifier environment fails closed")
	store.on_verifier_checked(HTTPRequest.RESULT_SUCCESS, 200, [], '{"status":"ready","mode":"sandbox"}'.to_utf8_buffer())
	expect(store.purchasable("starter_pack"), "only matching ready HTTPS status unlocks catalogued SKUs")
	play.billing_purchases.emit('{"owned":[{"product":"starter_pack","token":"fixture","state":2}]}')
	expect(store.pending_products.has("starter_pack") and not store.purchasable("starter_pack"),
		"a pending purchase cannot be bought a second time")
	play.billing_purchases.emit('{"owned":[]}')
	expect(not store.pending_products.has("starter_pack") and store.purchasable("starter_pack"),
		"successful Google snapshot clears a stale pending item")
	var account := "a".repeat(64)
	game.campaign.premium.play_account = account
	game.campaign.premium.play_session = "b".repeat(43)
	var payload := JSON.stringify({"account": account, "entitlements": [], "grants": []}).to_utf8_buffer()
	store.selected_product = "starter_pack"
	store.request_kind = "sync"
	store.response(HTTPRequest.RESULT_SUCCESS, 200, [], payload)
	expect(play.launch_ids == ["starter_pack"], "verified sign-in continues the original purchase selection")
	play.billing_state.emit("purchase", 1)
	expect(not store.busy() and store.status == "store_cancel", "Google cancellation releases checkout")
	store.selected_product = "starter_pack"
	await tap(game.operations.back)
	store.request_kind = "sync"
	store.response(HTTPRequest.RESULT_SUCCESS, 200, [], payload)
	expect(play.launch_ids.size() == 1, "leaving the store cancels checkout continuation after sign-in")

func shop_layouts() -> void:
	game.set_language("en")
	game.open_page("shop")
	var premium: RefCounted = game.operations.premium
	for viewport in [Vector2i(390, 844), Vector2i(450, 900), Vector2i(768, 1024)]:
		root.size = viewport
		await settle()
		var frame: Rect2 = game.operations.panel.get_global_rect()
		var screen := root.get_visible_rect()
		var fits := screen.grow(1.0).encloses(frame)
		for tab: Button in premium.tabs.values():
			var font := tab.get_theme_font("font")
			var text_width := font.get_string_size(tab.text, HORIZONTAL_ALIGNMENT_LEFT, -1, tab.get_theme_font_size("font_size")).x
			fits = fits and frame.has_point(tab.get_global_rect().get_center()) and text_width + 72 <= tab.size.x
		expect(fits, "store and translated labels fit viewport " + str(viewport))

func tap_row(copy: String) -> void:
	var control := find_button(game.operations.rows, copy)
	if control == null:
		expect(false, "missing action " + copy)
		return
	game.operations.scroll.ensure_control_visible(control)
	await settle()
	await tap(control)

func has_label(copy: String) -> bool:
	for child in game.operations.rows.find_children("*", "Label", true, false):
		if child.text == copy:
			return true
	return false

func has_label_part(copy: String) -> bool:
	for child in game.operations.rows.find_children("*", "Label", true, false):
		if copy in child.text:
			return true
	return false

func photo(name: String) -> void:
	if captures.is_empty():
		return
	await RenderingServer.frame_post_draw
	var pixels := root.get_texture().get_image()
	expect(pixels != null and pixels.save_jpg(captures.path_join(name + ".jpg"), .91) == OK,
		"rendered capture " + name)

func record_ad_wait() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 15
	game.add_child(layer)
	var banner := Label.new()
	layer.add_child(banner)
	banner.text = "GODOT / LINUX · KONTROLOWANE CALLBACKI SDK"
	banner.position = Vector2(30, 237)
	banner.add_theme_font_size_override("font_size", 21)
	banner.add_theme_color_override("font_color", Color("#fff1ce"))
	banner.add_theme_color_override("font_outline_color", Color("#23363a"))
	banner.add_theme_constant_override("outline_size", 6)
	game.open_page("boost")
	await create_timer(.65).timeout
	await tap_row(game.t("boost_watch"))
	expect(source.screens == 0 and game.ads.waiting("boost"), "recorded first tap queues the ad")
	for frame in 5:
		if game.ads.wait_until - Time.get_ticks_msec() < 3_000:
			break
		await process_frame
	source.complete("boost", true)
	await create_timer(.65).timeout
	expect(source.screens == 1 and game.ads.displaying(), "recorded ready callback starts playback")
	source.finish(true, true)
	await create_timer(1.8).timeout
	expect(game.campaign.boost.remaining(game.economy.clock) == 300 and game.ads.reward_receipts == 1, "recorded SDK callback grants BOOST once")
