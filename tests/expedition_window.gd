extends "res://tests/station_smoke.gd"

const Calendar = preload("res://data/world/expedition_calendar.gd")
const Routes = preload("res://data/world/desert_routes.gd")
const CAMPAIGN_TIME := Calendar.START + 2 * Calendar.DAY

func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			captures = argument.trim_prefix("--capture-dir=")
	if not captures.is_empty() and DisplayServer.get_name() == "headless":
		expect(false, "gallery requires a rendered window")
		result("Expansion window")
		return
	save_path = "/tmp/hbt-expedition-view-%d.cfg" % OS.get_process_id()
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.size = Vector2i(640, 1138)
	root.position = Vector2i.ZERO
	root.borderless = true
	game = mount(CAMPAIGN_TIME)
	current_scene = game
	game.skip_tutorial()
	await settle()
	scene_cost("Stacja Polnoc")
	if not await travel_out():
		game.free()
		clean_save(save_path)
		result("Expansion window")
		return
	await play_businesses()
	await play_programs()
	await travel_back()
	game.free()
	await process_frame
	clean_save(save_path)
	result("Expansion window")

func settle() -> void:
	await process_frame
	await process_frame
	await process_frame

func show_page(name: String) -> void:
	game.open_page(name)
	await settle()

func travel_out() -> bool:
	await capture("01-stacja-polnoc.png")
	click(game.hud.pages.atlas)
	await settle()
	expect(game.operations.page == "atlas", "HUD opens interactive atlas")
	await capture("02-atlas.png")
	await click_row("Desert Highway")
	expect(game.operations.page == "district" and not game.campaign.available("desert"), "map preview discloses locked gate")
	await capture("03-desert-warunki.png")
	game.operations.expedition.open_district("valley")
	await settle()
	await capture("04-green-valley-plan.png")
	var north: HbtEconomy = game.economy
	north.credit("cash", HbtAmount.from(6000))
	north.credit("reputation", HbtAmount.from(18))
	north.buy_levels("fuel", 4)
	north.hire("fuel")
	await show_page("atlas")
	await click_row("Desert Highway")
	await click_row(game.t("district_open") % game.money(HbtAmount.from(670)))
	await capture("05-podroz.png")
	var switched := await wait_for_district("desert")
	expect(switched and game.economy.level("fuel") == 1 and game.economy.amount("cash").decimal() == "190",
		"real travel button opens Desert Highway once")
	if switched:
		game.choose_weather("clear")
		await settle()
		await capture("06-copper-mile-start.png")
	return switched

func play_businesses() -> void:
	var local: HbtEconomy = game.economy
	game.traffic.dispatch.spawning = false
	click(game.hud.serve)
	step(1.62)
	expect(game.effects.hose[0].visible and game.driver.cycles == "fuel", "fuel animation works in the desert scene")
	await capture("07-pierwsze-tankowanie.png")
	step(2.55)
	expect(local.customers == 1, "first desert sale is paid")
	local.credit("cash", HbtAmount.from(10_000_000_000_000_000))
	local.credit("reputation", HbtAmount.from(105))
	for id in local.facilities:
		if id != "fuel":
			expect(local.unlock(id), "authored unlock gate for " + id)
		local.buy_levels(id, 25)
		local.hire(id)
		local.hire(id)
	local.buy_levels("fuel", 25)
	local.buy_levels("fuel", 25)
	local.buy_levels("fuel", 25)
	expect(game.campus.roof_counts.fuel == 5 and game.station.pumps[1].visible, "five physical stages and two real pumps")
	await show_page("upgrades")
	await capture("08-etapy-copper-mile.png")
	await close_sheet()
	var names := {"cafe": "09-kawiarnia.png", "restrooms": "10-toalety.png", "vip_park": "11-parking-vip.png",
		"truck": "12-serwis-tir.png", "showers": "13-prysznice.png", "motel": "14-motel.png", "truck_park": "15-parking-tir.png",
		"drive_through": "16-drive-through.png", "charge": "17-ladowarki.png"}
	for id: String in names:
		await service_photo(id, names[id])
	game.overview = true
	game.frame_camera()
	game.aim_camera(Vector3(5, 0, -11), Vector3(15, 33, 28), 87.0)
	await capture("18-caly-kompleks.png")
	root.size = Vector2i(1180, 812)
	await settle()
	game.aim_camera(Vector3(7, .30, -12), Vector3(15, 31, 29), 100.0)
	await capture("39-panorama.png")
	scene_cost("Desert - wide")
	root.size = Vector2i(640, 1138)
	await settle()
	game.select_site("fuel")
	game.aim_camera(Vector3(-1, .44, -.70), Vector3(11, 16, 17), 23.0)
	game.set_look(game.lighting.Look.DAWN)
	await capture("19-poranek.png")
	game.set_look(game.lighting.Look.GOLDEN)
	await capture("20-zachod.png")
	game.set_look(game.lighting.Look.NIGHT)
	await capture("21-neony-noca.png")
	game.set_look(game.lighting.Look.DAY)
	await show_page("climate")
	await click_row(game.t("weather_wind"))
	expect(game.weather.weather == "wind" and game.weather.effect.emitting, "weather control enables actual dust particles")
	await capture("22-pogoda.png")
	await close_sheet()
	await capture("23-pustynny-wiatr.png")
	game.choose_weather("rain")
	await capture("24-deszcz.png")
	game.choose_weather("clear")
	scene_cost("Desert - phone")

func scene_cost(name: String) -> void:
	if captures.is_empty():
		return
	print("%s %s: draws=%d primitives=%d objects=%d resources=%d" % [name, root.size,
		root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
		root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME),
		Performance.get_monitor(Performance.OBJECT_COUNT), Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)])

func service_photo(id: String, filename: String) -> void:
	var dispatch: HbtDispatch = game.traffic.dispatch
	for ticket: HbtVisit in dispatch.live.values():
		dispatch.dispose(ticket)
	game.select_site(id)
	var request := "trucker" if Routes.is_truck(id) else "electric" if id == "charge" else "vip" if id == "vip_park" else "local"
	var expected := dispatch.try_admit(request, id)
	var action := false
	for frame in 1230:
		step(.05)
		if expected != null and expected.phase == Phase.WORKING:
			action = true
			break
	var front: Vector3 = Routes.FRONTS[id]
	var at := Routes.position_of(id, 0).lerp(front, .48)
	var offset := Vector3(8, 15, -15) if id == "showers" else Vector3(11, 15, 16)
	game.aim_camera(at + Vector3(0, .58, 0), offset, 23.50 if Routes.is_truck(id) else 18.75)
	expect(action and expected.worker >= 0, "paid-ready customer and real staff for " + id)
	await capture(filename)
	for frame in 1050:
		step(.05)
		if expected != null and expected.paid and dispatch.live.is_empty():
			break
	expect(expected != null and expected.paid and dispatch.consistent(), "settled invoice and reserved bay for " + id)

func play_programs() -> void:
	await show_page("contracts")
	await click_row(game.t("contract_accept"))
	expect(game.campaign.ledger.active_contracts("desert") == 1, "contract accepted through the sheet")
	await capture("25-kontrakty.png")
	await show_page("collections")
	await capture("26-kolekcja-pojazdow.png")
	await click_row(game.t("set_trucks"))
	await capture("27-kolekcja-ciezarowek.png")
	for index in Calendar.SEASONS.size():
		game.simulation_clock = float(Calendar.START + index * Calendar.WEEK + 3 * Calendar.DAY)
		step(.05)
		await show_page("seasons")
		var current: Dictionary = game.campaign.ledger.season()
		expect(current.id == Calendar.SEASONS[index].id and current.live and game.weather.event_id == current.id,
			"real timed panel and ornament " + current.id)
		await capture("%02d-wydarzenie-%s.png" % [28 + index, current.id])
	await show_page("season_summary")
	await capture("34-podsumowanie-wydarzen.png")
	await show_page("finance")
	await capture("35-finanse-desert.png")
	await show_page("prestige")
	await capture("36-prestiz-warunki.png")
	for id in game.economy.facilities:
		game.economy.levels[id] = 100
	game.economy.touch()
	await settle()
	await click_row(game.t("prestige_review"))
	expect(game.operations.page == "prestige_confirm", "prestige has a distinct confirmation page")
	await capture("37-potwierdzenie-prestizu.png")
	await click_row(game.t("prestige_cancel"))
	expect(game.economy.level("fuel") == 100 and game.economy.prestige_rank == 0, "cancel preserves progress")
	await close_sheet()

func travel_back() -> void:
	game.economy.checkpoint()
	await show_page("atlas")
	await click_row(game.district_name("north"))
	await click_row(game.t("district_travel"))
	var switched := await wait_for_district("north")
	expect(switched and game.economy.level("fuel") == 5 and game.economy.crew.fuel.size() == 1
		and game.campaign.districts.desert.level("fuel") == 100, "return keeps both districts")
	if switched:
		expect(game.operations.page == "offline" and not game.economy.offline_pending.empty(), "inactive district pays on return")
		await capture("38-powrot-i-offline.png")

func wait_for_district(id: String) -> bool:
	for frame in 130:
		await process_frame
		var node := current_scene
		if node != game and node is Node3D and node.mounted and node.economy.district == id:
			game = node
			game.set_physics_process(false)
			if game.motion_enabled():
				await create_timer(.54).timeout
			return true
	return false
