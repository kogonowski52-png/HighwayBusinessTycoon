extends "res://tests/station_smoke.gd"

const Front = preload("res://scenes/ui/front_gate.tscn")
const Route = preload("res://data/economy/routes.gd")
const Campus = preload("res://scripts/buildings/roadside_campus.gd")

func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			captures = argument.trim_prefix("--capture-dir=")
	if not captures.is_empty() and DisplayServer.get_name() == "headless":
		expect(false, "framebuffer capture requires a graphics display")
		result("Presentation playthrough")
		return
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.borderless = true
	root.position = Vector2i.ZERO
	root.size = Vector2i(720, 1280)
	save_path = "/tmp/hbt-presentation-window-%d.cfg" % OS.get_process_id()
	await launch()
	if game == null:
		result("Presentation playthrough")
		return
	await upgrades_and_career()
	await rewards()
	await settings_and_gestures()
	await world_activity()
	await return_offline()
	game.free()
	await process_frame
	clean_save(save_path)
	result("Presentation playthrough")

func launch() -> void:
	var intro := Front.instantiate()
	intro.profile_path = save_path
	root.add_child(intro)
	current_scene = intro
	await pause_ui()
	expect(intro.play.text == "Graj" and root.get_node("RouteAudio").track == "menu", "native title with logo and menu mix")
	await capture("01-start.png")
	click(intro.play)
	expect(intro.busy and intro.loading.visible, "Play starts a real threaded preload")
	await capture("02-ladowanie.png")
	var elapsed := 0
	while is_instance_valid(intro) and elapsed < 170:
		await process_frame
		elapsed += 1
	expect(current_scene is Node3D and not is_instance_valid(intro), "loading hands over to the actual world scene")
	if current_scene is Node3D:
		game = current_scene
		game.set_physics_process(false)
		await pause_ui()
		expect(root.get_node("RouteAudio").track == "day" and controls_fit(), "game receives its own sound mix and five visible tabs")
		await capture("03-hud.png")

func upgrades_and_career() -> void:
	var store: HbtEconomy = game.economy
	click(game.hud.serve)
	step(0.81)
	expect(game.hud.progress.value > .08 and game.effects.hose[0].visible, "animated progress follows real pumping")
	await capture("04-tankowanie.png")
	step(2.05)
	await pause_ui()
	var previous: float = game.camera_rig.zoom
	click(game.hud.upgrade)
	expect(store.level("fuel") == 2 and store.customers == 1, "economic first upgrade is preserved")
	if game.motion_enabled():
		expect(not game.camera_rig.film.is_empty() and game.camera_rig.zoom < previous, "purchased geometry starts a camera move")
		await create_timer(.49).timeout
		await capture("05-modernizacja.png")
		await create_timer(.66).timeout
		expect(game.camera_rig.film.is_empty() and is_equal_approx(game.camera_rig.zoom, previous), "camera returns to the original frame")
	else:
		await capture("05-modernizacja.png")
	await open_hud("goals")
	await capture("06-misje.png")
	await click_row(game.t("claim"))
	await click_row(game.t("claim"))
	expect(store.claimed.has("first") and store.claimed.has("upgrade"), "old mission awards remain accessible")
	await open_hud("team")
	await capture("07-pracownicy.png")
	await click_row(game.t("recruit") % game.money(store.recruit_cost("fuel")))
	expect(store.crew.fuel.size() == 1 and game.crew.staff.fuel.size() == 1, "recruitment updates world staff")
	await open_hud("goals")
	await click_row(game.t("claim"))
	expect(store.cards.has("ada"), "original quest still reveals Ada")
	await capture("08-nowa-karta.png")
	await open_hud("managers")
	await capture("09-kolekcja.png")
	await click_row("Ada Nowak")
	expect(game.operations.page == "manager_detail", "a unique portrait opens manager details")
	await click_row(game.t("assign"))
	await capture("10-karta-menedzera.png")
	await close_sheet()
	if game.tutorial.visible:
		click(game.tutorial.skip)
	await pause_ui()
	click(game.hud.upgrade_preview)
	await pause_ui()
	expect(game.operations.page == "upgrades", "build sheet remains available")
	await capture("11-modernizacja-panel.png")
	await click_row("+25")
	expect(game.quantity == 25 and not game.operations.upgrade_counts.is_empty(), "bulk quantity is applied by the sheet")
	await click_row("+1")
	await close_sheet()
	await open_hud("sites")
	await capture("12-obiekty.png")
	await close_sheet()
	provision(expansion_targets())
	game.economy.credit("diamond", HbtAmount.from(15))
	game.economy.credit("event", HbtAmount.from(12))

func rewards() -> void:
	var store: HbtEconomy = game.economy
	await open_hud("calendar")
	await capture("13-kalendarz.png")
	var old := store.recognition.daily_count
	await click_row(game.t("calendar_claim") % (store.recognition.slot() + 1))
	expect(store.recognition.daily_count == old + 1 and store.claim_calendar().is_empty(), "calendar page pays once")
	await capture("14-nagroda.png")
	await open_hud("goals")
	await click_row(game.t("chapters"))
	await capture("15-rozdzialy.png")
	await click_row(game.t("achievements_header"))
	await capture("16-osiagniecia.png")
	await click_row(game.t("next"))
	expect(game.operations.extra.page_medal == 1, "achievement tracks can be browsed in the game")
	await open_hud("rank")
	await capture("17-awans.png")
	var bonus := store.player_reward()
	await click_row(game.t("career_reward") % [game.money(HbtAmount.from(bonus.cash)), bonus.diamond])
	expect(store.paid_player_level == store.player_level(), "player reward uses the previous level ledger")
	await open_hud("shop")
	await capture("18-sklep.png")
	var previous := store.amount("diamond")
	await click_row(game.t("shop_price_diamond") % store.CONFIG.boost_cost)
	expect(store.boost_until > store.clock and store.amount("diamond").compare(previous.minus(HbtAmount.from(store.CONFIG.boost_cost))) == 0,
		"shop buys the real earned-currency boost")
	await open_hud("finance")
	await capture("19-statystyki.png")
	expect(game.operations.page == "finance", "finance remains reachable in one tap")

func settings_and_gestures() -> void:
	var store: HbtEconomy = game.economy
	await open_hud("settings")
	await capture("20-ustawienia.png")
	var lens_before: Vector3 = game.camera_rig.target
	touch_event(0, Vector2(448, 990), true)
	move_touch(0, Vector2(791, 1090), Vector2(343, 100))
	touch_event(0, Vector2(791, 1090), false)
	expect(game.camera_rig.target == lens_before, "menu gestures cannot move the map")
	await click_row(game.t("quality_mid"))
	expect(store.preferences.quality == 1 and game.lighting.quality == 1 and is_equal_approx(root.scaling_3d_scale, .88),
		"medium quality applies a distinct render scale")
	await click_row("30 FPS")
	expect(Engine.max_fps == 30 and game.lighting.quality == 1, "FPS cap and quality are independent")
	await click_row(game.t("battery_off"))
	expect(store.low_power and game.lighting.quality == 0 and Engine.max_fps == 30, "battery saving applies lower effects")
	await click_row(game.t("battery_on"))
	await click_row("60 FPS")
	await click_row(game.t("quality_high"))
	var music: HSlider = game.operations.rows.find_child("music", true, false)
	var ambient: HSlider = game.operations.rows.find_child("ambient", true, false)
	var fx: HSlider = game.operations.rows.find_child("effects", true, false)
	music.value = .38
	ambient.value = .27
	fx.value = .64
	await click_row(game.t("vibration_on"))
	expect(not store.preferences.haptics and store.preferences.volumes.music == .38 and store.preferences.volumes.ambient == .27 \
		and store.preferences.volumes.effects == .64, "mixer sliders and vibration update through actual controls")
	for spec in [["help", "21-pomoc.png"], ["licenses", "22-licencje.png"], ["privacy", "23-prywatnosc.png"]]:
		await click_row(game.t(spec[0]))
		expect(game.operations.page == spec[0], "disclosure or help page " + spec[0])
		await capture(spec[1])
		await click_row(game.t("settings_header"))
	await close_sheet()
	var point := Vector2(410, 785)
	var focus: Vector3 = game.camera_rig.target
	touch_event(0, point, true)
	move_touch(0, point + Vector2(85, 45), Vector2(85, 45))
	touch_event(0, point + Vector2(85, 45), false)
	expect(game.camera_rig.target.distance_to(focus) > 0.4 and game.camera_rig.momentum.length() > 0.5, "touch moves the map with release momentum")
	var previous: float = game.camera_rig.zoom
	touch_event(0, point, true)
	touch_event(1, point + Vector2(220, 0), true)
	move_touch(1, point + Vector2(330, 0), Vector2(110, 0))
	touch_event(0, point, false)
	touch_event(1, point + Vector2(330, 0), false)
	expect(game.camera_rig.zoom < previous, "two-finger spread actually zooms")
	game.camera_rig.drag(Vector2(15000, 0))
	expect(game.camera_rig.target.x >= game.camera_rig.LIMIT_MIN.x and game.camera_rig.target.z <= game.camera_rig.LIMIT_MAX.y,
		"map drag is bounded")
	game.select_site("fuel")

func world_activity() -> void:
	var store: HbtEconomy = game.economy
	var dispatch: HbtDispatch = game.traffic.dispatch
	dispatch.spawning = false
	step(45.0)
	var mechanic := dispatch.try_admit("local", "workshop")
	var shopper := dispatch.try_admit("local", "market")
	if shopper == null:
		for index in range(240):
			step(.05)
			shopper = dispatch.try_admit("local", "market")
			if shopper != null:
				break
	var saw_door := false
	var saw_exit := false
	for i in range(1360):
		step(.05)
		if shopper != null and dispatch.live.has(shopper.number):
			if game.crew.visitors.has(shopper.number):
				saw_exit = saw_exit or game.crew.visitors[shopper.number].cycles == "exit_car"
			dispatch.start_manual("market")
		if mechanic != null and mechanic.phase == HbtVisit.Phase.READY:
			dispatch.start_manual("workshop")
		if mechanic != null and mechanic.phase == HbtVisit.Phase.WORKING and game.venue_activity.door_progress > .94:
			saw_door = true
			game.select_site("workshop")
			game.aim_camera(Campus.WORKSHOP_AT + Vector3(.45, 1.59, 1.18), Vector3(.48, .63, 3.25), 10.0)
			await capture("24-brama-warsztatu.png")
			break
	expect(saw_door, "the door opens for the reserved workshop vehicle")
	var delivery_seen := false
	for i in range(1600):
		step(.05)
		if shopper != null:
			if game.crew.visitors.has(shopper.number):
				saw_exit = saw_exit or game.crew.visitors[shopper.number].cycles == "exit_car"
			dispatch.start_manual("market")
		if is_instance_valid(game.venue_activity.courier) and game.venue_activity.courier.cycles == "carry":
			delivery_seen = true
			break
	expect(shopper != null and shopper.paid and saw_exit and delivery_seen, "shop customer steps out and a completed sale starts a parcel restock")
	game.select_site("market")
	game.set_look(game.lighting.Look.GOLDEN)
	game.aim_camera(Vector3(-4.13, .80, -6.56), Vector3(6.6, 5.5, -10.0), 13.0)
	await capture("25-dostawa.png")
	step(7.0)
	expect(store.per_service.market.count > 0 and is_instance_valid(game.venue_activity.stack), "delivery leaves physical stock")
	print_view("business", Vector2i(720, 1280))

func return_offline() -> void:
	var store: HbtEconomy = game.economy
	var before := store.clock
	expect(store.checkpoint() == OK, "settings and rewards checkpoint together")
	game.free()
	game = mount(before + 15_200)
	await pause_ui()
	store = game.economy
	expect(game.operations.page == "offline" and not store.offline_pending.empty(), "previous offline mechanism opens the updated payout screen")
	expect(store.preferences.volumes.music == .38 and not store.preferences.haptics and store.recognition.daily_count == 1,
		"new display state and calendar persist")
	await capture("26-offline.png")
	var income := store.offline_pending
	await click_row(game.t("claim_offline") % game.money(income))
	await close_sheet()
	for spec in [[Vector2i(585, 1280), "27-telefon.png"], [Vector2i(900, 1200), "28-tablet.png"],
		[Vector2i(1440, 960), "29-tablet-szeroki.png"]]:
		root.size = spec[0]
		await pause_ui()
		expect(controls_fit(), "controls fit " + str(spec[0]))
		if spec[1] == "29-tablet-szeroki.png":
			game.toggle_view()
			await pause_ui()
		await capture(spec[1])
		print_view(spec[1], spec[0])
	root.size = Vector2i(640, 1280)
	await pause_ui()
	var margins: Vector4 = game.hud.safe_insets(Rect2(0, 42, 640, 1206), Vector2(640, 1280), root.get_visible_rect().size)
	game.hud.apply_safe(margins)
	await process_frame
	expect(game.hud.top.position.y >= margins.y and game.hud.dock.get_global_rect().end.y <= root.get_visible_rect().end.y - margins.w,
		"simulated notch and system bar fit inside the safe area")
	await capture("30-wyciecie.png")

func print_view(label: String, size: Vector2i) -> void:
	if not captures.is_empty():
		print("%s %s draws=%d primitives=%d" % [label, size,
			root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
			root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)])

func open_hud(name: String) -> void:
	await close_sheet()
	click(game.hud.pages[name])
	await pause_ui()
	expect(game.operations.modal_open() and game.operations.page == name, "navigation opens " + name)

func pause_ui() -> void:
	await process_frame
	await process_frame
	if not captures.is_empty():
		await create_timer(.23).timeout

func touch_event(index: int, point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = pressed
	root.push_input(event, true)

func move_touch(index: int, point: Vector2, delta: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = point
	event.relative = delta
	root.push_input(event, true)
