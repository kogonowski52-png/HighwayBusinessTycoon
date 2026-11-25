extends "res://tests/station_smoke.gd"

const Routes = preload("res://data/economy/routes.gd")
const Campus = preload("res://scripts/buildings/roadside_campus.gd")

func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			captures = argument.trim_prefix("--capture-dir=")
	if not captures.is_empty() and DisplayServer.get_name() == "headless":
		expect(false, "capture needs a window")
		result("Career playthrough")
		return
	save_path = "/tmp/hbt-career-window-%d.cfg" % OS.get_process_id()
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.position = Vector2i.ZERO
	root.borderless = true
	root.size = Vector2i(720, 1280)
	game = mount(WALL)
	await process_frame
	await process_frame
	await first_shift()
	await late_complex()
	game.free()
	clean_save(save_path)
	result("Career playthrough")

func first_shift() -> void:
	var store: HbtEconomy = game.economy
	expect(game.tutorial.visible and store.tutorial_step == 0 and game.tutorial.glow.visible, "new player sees the live fuel control highlighted")
	await capture("01-pierwsza-zmiana.png")
	click(game.hud.serve)
	step(0.95)
	expect(game.hud.progress.value > 0.20 and game.effects.hose[0].visible, "guided press begins real refueling")
	await capture("02-tankowanie.png")
	step(2.0)
	await process_frame
	expect(store.tutorial_step == 1 and store.amount("cash").decimal() == "155", "first sale guides to the exactly affordable upgrade")
	await capture("03-pierwszy-zarobek.png")
	click(game.hud.upgrade)
	await process_frame
	expect(store.level("fuel") == 2 and store.tutorial_step == 2, "upgrade advances tutorial")
	click(game.hud.pages.goals)
	await process_frame
	await capture("04-kariera-i-pierwsze-cele.png")
	await click_row(game.t("claim"))
	await click_row(game.t("claim"))
	expect(store.tutorial_step == 3 and store.claimed.has("first") and store.claimed.has("upgrade"), "the real goals pay for the attendant")
	click(game.operations.back)
	click(game.hud.pages.team)
	await process_frame
	await capture("05-zatrudnienie.png")
	await click_row(game.t("recruit") % game.money(store.recruit_cost("fuel")))
	click(game.operations.back)
	expect(store.tutorial_step == 4 and store.crew.fuel.size() == 1, "hiring creates an employee for this save")
	for tick in range(1400):
		step(0.05)
		if game.crew.staff.fuel[0].cycles == "fuel":
			break
	expect(game.crew.staff.fuel[0].cycles == "fuel", "employee walks up to the next vehicle and refuels")
	await capture("06-pracownik-na-stanowisku.png")
	for tick in range(600):
		step(0.05)
		if not store.holding().empty():
			break
	await process_frame
	await process_frame
	await capture("07-odbiory-z-kasy.png")
	click(game.hud.income)
	await process_frame
	expect(store.holding().empty() and store.tutorial_step == 5, "collection advances the first shift")
	click(game.hud.pages.sites)
	await process_frame
	expect(store.tutorial_step == store.TUTORIAL_DONE and not game.tutorial.visible, "tutorial finishes after opening the business directory")
	await capture("08-uslugi-trasy17.png")
	click(game.operations.back)

func late_complex() -> void:
	var store: HbtEconomy = game.economy
	var dispatch: HbtDispatch = game.traffic.dispatch
	dispatch.spawning = false
	step(55.0)
	# Seed purchasing power only so the test can reach the late complex immediately.
	store.credit("cash", HbtAmount.from("180000000"))
	store.credit("reputation", HbtAmount.from(180))
	for id in store.facilities:
		if id != "fuel":
			expect(store.unlock(id), "actual expansion purchase " + id)
		store.buy_levels(id, 38 - store.level(id))
		if store.crew[id].is_empty():
			store.hire(id)
	expect(store.metric("locations") == 11 and store.capacity("tires") == 2 and store.capacity("truck_park") == 2
		and store.capacity("charge") == 2 and game.campus.charge_shelters[0].visible,
		"advanced upgrades install distinct operations, capacity and EV solar roof")
	if not captures.is_empty():
		await create_timer(2.8).timeout
	for spec in [
		["tires", "local", Campus.TIRES_AT + Vector3(0.18, 1.20, 0.84), Vector3(-3.65, 3.8, 5.1), 10.6, "09-wulkanizacja.png"],
		["charge", "electric", Vector3(-33.72, 0.66, -0.86), Vector3(2.9, 5.9, 12.8), 15.7, "10-ladowanie-ev.png"],
		["truck_park", "trucker", Vector3(40.7, 0.66, -9.19), Vector3(5.7, 7.6, 12.7), 16.8, "11-parking-tir.png"],
		["restaurant", "traveler", Vector3(-19.17, 0.86, -6.44), Vector3(3.95, 5.7, 12.9), 15.7, "12-klient-restauracji.png"],
	]:
		await service_view(dispatch, spec)
	click(game.hud.pages.goals)
	await process_frame
	await click_row(game.t("chapters"))
	await click_row(game.t("claim"))
	expect(store.claimed.has("route_fuel_open"), "chapter mission can be claimed from its actual screen")
	await capture("13-rozdzialy.png")
	await click_row(game.t("career"))
	var bonus := store.player_reward()
	await capture("14-nagrody-poziomu.png")
	await click_row(game.t("career_reward") % [game.money(HbtAmount.from(bonus.cash)), bonus.diamond])
	expect(store.paid_player_level == store.player_level(), "player level rewards are paid by the UI")
	await click_row(game.t("claim"))
	await click_row(game.t("claim"))
	await click_row(game.t("claim"))
	expect(store.cards.has("ada"), "earned employee goal yields Ada")
	click(game.operations.back)
	click(game.hud.pages.team)
	await process_frame
	await click_row(game.t("team_cards"))
	await click_row(game.t("assign"))
	expect(store.equipped.has("ada") and game.crew.directors.has("ada"), "card activation reaches the main scene")
	var training := store.manager_training("ada")
	await click_row(game.t("manager_train") % training.cost)
	expect(store.manager_rank("ada") == 2, "manager training charges disclosed earned diamonds")
	await capture("15-menedzerowie.png")
	click(game.operations.back)
	click(game.hud.pages.finance)
	await process_frame
	var offer := store.offline_upgrade()
	await click_row(game.t("offline_upgrade") % [offer.hours, game.money(offer.cost)])
	expect(store.offline_limit() == 14_400, "Finance button expands offline to four hours")
	await capture("16-limit-offline.png")
	click(game.operations.back)
	game.select_site("fuel")
	click(game.hud.view)
	root.size = Vector2i(1600, 1080)
	await process_frame
	await capture("17-pelny-kompleks.png")
	print("Career map viewport: %d draws, %d primitives" % [
		root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
		root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)])
	root.size = Vector2i(720, 1280)
	await process_frame
	var saved_at := store.clock
	var balance := store.amount("cash")
	expect(store.checkpoint() == OK, "0.4.0 gameplay checkpoint")
	game.free()
	game = mount(saved_at + 19800)
	await process_frame
	await process_frame
	store = game.economy
	expect(store.amount("cash").compare(balance) == 0 and store.level("charge") == 38 and store.cards.has("ada")
		and store.manager_rank("ada") == 2 and store.claimed.has("route_fuel_open") and store.tutorial_step == store.TUTORIAL_DONE,
		"relaunch preserves experience, venue, manager rank and chapter reward")
	expect(game.operations.page == "offline" and store.offline_seconds == 14_400 and store.offline_away_seconds == 19_800,
		"offline summary distinguishes actual time from credited time")
	await capture("18-podsumowanie-offline.png")
	var expected := store.offline_pending
	await click_row(game.t("claim_offline") % game.money(expected))
	expect(store.amount("cash").compare(balance.plus(expected)) == 0 and store.offline_pending.empty(),
		"offline claim pays exactly once")
	root.size = Vector2i(900, 1200)
	click(game.hud.language)
	await process_frame
	await process_frame
	expect(store.language == "en" and controls_fit(), "English tablet layout fits")
	await capture("19-tablet-en.png")

func service_view(dispatch: HbtDispatch, spec: Array) -> void:
	var id: String = spec[0]
	game.select_site(id)
	game.aim_camera(spec[2], spec[3], spec[4])
	var visit := dispatch.try_admit(spec[1], id)
	expect(visit != null, "appropriate client enters for " + id)
	if visit == null:
		return
	var moving_client := false
	for tick in range(1550):
		step(0.05)
		moving_client = moving_client or game.crew.visitors.has(visit.number)
		if visit.phase == Phase.WORKING and visit.walked >= visit.foot_length and is_instance_valid(game.crew.performer(visit)):
			break
	var active := visit.phase == Phase.WORKING
	var actor: Node3D = game.crew.performer(visit)
	expect(active and moving_client and actor != null and visit.worker >= 0
		and actor.cycles == game.economy.facilities[id].task, "client and hired worker physically run " + id)
	if id == "charge":
		expect(game.campus.charge_links[visit.bay].visible, "working charger shows a real connected cable")
	await capture(spec[5])
	for tick in range(1700):
		step(0.05)
		if not dispatch.live.has(visit.number):
			break
	expect(visit.paid and not dispatch.live.has(visit.number) and dispatch.consistent()
		and not game.economy.per_service[id].gross.empty(), "payment, departure and bay release for " + id)
