extends "res://tests/expedition_window.gd"
## Real Godot viewport passes through the atlas and through staffed service visits.

const Atlas = preload("res://data/world/atlas.gd")
const Regions = preload("res://data/world/regions.gd")
const RegionalCampus = preload("res://scripts/buildings/regional_campus.gd")
const VISITS := {
	"valley": [["restaurant", "local", "18-orchard-table.jpg"], ["market", "business", "20-greenbank-dostawa.jpg"]],
	"alpine": [["motel", "tourist", "25-snowline-autokar.jpg"], ["restaurant", "family", "26-ember-hearth.jpg"]],
	"ocean": [["vip_park", "vip", "30-marina-vip.jpg"], ["wash", "vip", "32-pearl-bay-myjnia.jpg"]],
	"metro": [["logistics", "trucker", "37-terminal-zaladunek.jpg"], ["warehouse", "trucker", "38-magazyn-operacja.jpg"],
		["dealership", "vip", "39-apex-motors.jpg"], ["mall", "family", "40-crossline-klienci.jpg"],
		["charge", "electric", "41-pulse-plaza.jpg"], ["truck_park", "trucker", "42-freight-exchange.jpg"]],
}

var capture_count := 0
var perf_report := false

func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			captures = argument.trim_prefix("--capture-dir=")
		perf_report = perf_report or argument == "--sample-performance"
	if DisplayServer.get_name() == "headless":
		expect(false, "regional window requires a real renderer")
		result("Six districts in Godot")
		return
	if not captures.is_empty():
		DirAccess.make_dir_recursive_absolute(captures)
	save_path = "/tmp/hbt-regional-window-%d.cfg" % OS.get_process_id()
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.size = Vector2i(640, 1138)
	root.position = Vector2i.ZERO
	root.borderless = true
	game = mount(Calendar.START + Calendar.WEEK * 4 + 420)
	current_scene = game
	game.skip_tutorial()
	# Fixed seed and in-game time make QA views reproducible without writing a player's save.
	game.economy.preferences.auto_day = false
	game.traffic.dispatch.spawning = false
	await settle()
	await capture("01-stacja-polnoc.jpg")
	click(game.hud.serve)
	step(1.50)
	expect(game.effects.hose[0].visible, "old North station still animates a manual refuel")
	await capture("02-polnoc-tankowanie.jpg")
	step(2.8)
	await show_page("atlas")
	await capture("03-atlas-szesciu-lokalizacji.jpg")
	game.operations.expedition.open_district("valley")
	await capture("04-green-valley-warunki.jpg")
	expect(not game.campaign.available("valley"), "later district still locked in visible atlas")
	await show_page("seasons")
	await capture("05-wydarzenie-wakacyjny-kurort.jpg")
	await close_sheet()
	develop(28)
	await phone_and_panorama("06-polnoc-panorama.jpg", true)
	await performance("north")
	for id in Atlas.chapter_routes(false).slice(1):
		var prior: HbtEconomy = game.economy
		var fee := HbtAmount.from(Atlas.DESTINATIONS[id].cost)
		if not await atlas_travel(id):
			expect(false, "real atlas button travels to " + id)
			break
		expect(prior.spent.compare(fee) >= 0 and game.economy.level("fuel") == 1 and controls_fit(),
			id + " opens on its own fuel and phone controls fit")
		if id == "desert":
			await desert()
		else:
			await region(id)
	if game.economy.district == "metro":
		await play_metro()
		game.economy.clock += 3600
		expect(await atlas_travel("valley"), "round trip through Atlas returns to Valley")
		expect(game.economy.level("fuel") >= 60 and game.economy.crew.fuel.size() >= 1
			and not game.economy.offline_pending.empty(), "real atlas return restores workers, improvements and offline summary")
		await capture("50-powrot-zarobki-offline.jpg")
		if game.operations.page == "offline":
			await click_row(game.t("claim_offline") % game.money(game.economy.offline_pending))
			expect(game.economy.offline_pending.empty(), "visible offline button collects only once")
		expect(game.campaign.districts.size() == 6, "all six districts travelled and saved")
	if not captures.is_empty():
		expect(capture_count >= 40, "at least forty original viewport captures")
	root.get_node("RouteAudio").shut_down()
	game.free()
	await create_timer(.18).timeout
	clean_save(save_path)
	result("Six districts in Godot")

func atlas_travel(id: String) -> bool:
	if game.operations.modal_open():
		await close_sheet()
	await show_page("atlas")
	await click_row(game.district_name(id))
	var label: String = game.t("district_travel")
	if not game.campaign.districts.has(id):
		label = game.t("district_open") % game.money(HbtAmount.from(Atlas.DESTINATIONS[id].cost))
	await click_row(label)
	var arrived := await wait_for_district(id)
	if arrived:
		game.traffic.dispatch.spawning = false
		await settle()
	return arrived

func develop(tier: int) -> void:
	var district: HbtEconomy = game.economy
	district.credit("cash", HbtAmount.from(1_000_000_000_000))
	district.credit("reputation", HbtAmount.from(180))
	for id in district.facilities:
		if id != "fuel":
			expect(district.unlock(id), "%s unlocks in %s with listed prerequisite" % [id, district.district])
		while district.level(id) < tier:
			var remaining := tier - district.level(id)
			district.buy_levels(id, 25 if remaining >= 25 else 10 if remaining >= 10 else 1)
		district.hire(id)
		district.train(id, 0)
		if district.capacity(id) >= 2:
			district.hire(id)
	district.checkpoint()
	await settle()

func desert() -> void:
	game.choose_weather("clear")
	await capture("07-copper-mile-start.jpg")
	await develop(62)
	await focus_photo("fuel", "08-copper-mile-stacja.jpg")
	await focus_photo("cafe", "09-dust-and-bean.jpg")
	await focus_photo("truck", "10-red-mesa-serwis.jpg", 22)
	await focus_photo("motel", "11-stargazer.jpg", 22)
	game.set_look(game.lighting.Look.NIGHT)
	await focus_photo("drive_through", "12-roadstar-noca.jpg", 25)
	game.set_look(game.lighting.Look.DAY)
	await phone_and_panorama("13-copper-mile-panorama.jpg", true)
	await performance("desert")

func region(id: String) -> void:
	var start := {"valley": "14-riverbend-start.jpg", "alpine": "22-summit-start.jpg",
		"ocean": "27-blue-current-start.jpg", "metro": "33-meridian-start.jpg"}
	if id == "alpine":
		game.choose_weather("snow")
		expect(game.weather.effect.emitting, "Alpine snow particles enabled through weather rules")
	elif id == "ocean" or id == "valley":
		game.choose_weather("clear")
	await capture(start[id])
	await develop(62)
	match id:
		"valley":
			await focus_photo("fuel", "15-riverbend-stacja.jpg", 25)
			await phone_and_panorama("16-green-valley-panorama.jpg", true)
			await flat_photo("17-most-i-rzeka.jpg", Vector3(-29.5, .2, 3.19), 24)
			await focus_photo("workshop", "19-mill-i-motor.jpg", 21)
		"alpine":
			await phone_and_panorama("23-alpine-panorama.jpg", true)
			await flat_photo("24-zasniezona-przelecz.jpg", Vector3(-13, 1.5, -18.1), 41)
		"ocean":
			await phone_and_panorama("28-ocean-coast-panorama.jpg", true)
			await flat_photo("29-plaza-i-molo.jpg", Vector3(-13.3, .2, 19.4), 27)
			await focus_photo("motel", "31-coral-key.jpg", 23)
		"metro":
			game.set_look(game.lighting.Look.NIGHT)
			await phone_and_panorama("34-metro-panorama-noc.jpg", true)
			await flat_photo("35-meridian-autostrada.jpg", Vector3(2.8, .2, 8.1), 33)
			game.set_look(game.lighting.Look.GOLDEN)
			await phone_and_panorama("36-metro-panorama-dzien.jpg", true)
	for job: Array in VISITS[id]:
		await visit_photo(job)
	await performance(id)

func play_metro() -> void:
	var local: HbtEconomy = game.economy
	game.select_site("warehouse")
	await show_page("upgrades")
	await capture("43-panel-magazynu.jpg")
	await close_sheet()
	for id in ["logistics", "warehouse", "dealership", "mall"]:
		var prior := local.level(id)
		expect(is_instance_valid(game.campus.buildings[id]) and game.campus.buildings[id].visible and prior >= 60,
			"open special trade has a unique installed scene " + id)
		for tier in RegionalCampus.THRESHOLDS:
			local.levels[id] = tier
			game.campus.update_sites(local)
			var shown: int = game.campus.upgrades[id].filter(func(part: Node3D) -> bool: return part.visible).size()
			expect(game.campus.roof_counts[id] == RegionalCampus.THRESHOLDS.find(tier) + 1 and shown == game.campus.roof_counts[id] - 1,
				"%s has separate visible geometry by tier %d" % [id, tier])
			if id == "warehouse" and tier in [1, 30, 90]:
				await focus_photo(id, "44-magazyn-prog-%02d.jpg" % tier, 30)
		local.levels[id] = prior
	local.touch()
	await show_page("contracts")
	await capture("45-kontrakt-meridian.jpg")
	await close_sheet()
	await show_page("collections")
	game.operations.expedition.choose_set("routes")
	await capture("46-znaki-podrozy.jpg")
	await close_sheet()
	game.economy.cards.dev = true
	game.assign_manager("dev")
	await show_page("managers")
	await click_row("Dev Griffin")
	expect(game.operations.page == "manager_detail" and game.crew.directors.has("dev"), "original director and portrait both render")
	await capture("47-menedzer-dev.jpg")
	await close_sheet()
	game.set_look(game.lighting.Look.NIGHT)
	await focus_photo("logistics", "48-meridian-doki-noc.jpg", 25)
	game.set_language("en")
	await show_page("upgrades")
	expect(game.operations.visible and game.operations.page == "upgrades", "English operates the same storefront panel")
	await capture("49-panel-angielski.jpg")
	await close_sheet()

func visit_photo(configuration: Array) -> void:
	var id: String = configuration[0]
	var visit: HbtVisit = game.traffic.dispatch.try_admit(configuration[1], id)
	expect(visit != null, "real entrance for " + id)
	if visit == null:
		return
	for frame in 720:
		step(.10)
		if visit.phase == Phase.WORKING and visit.progress() >= .37:
			break
	var body: Node3D = game.traffic.vehicles.get(visit.number)
	var worker: Node3D = game.crew.performer(visit)
	expect(visit.phase == Phase.WORKING and is_instance_valid(body) and is_instance_valid(worker),
		"visible vehicle and worker handling paid service " + id)
	if id in ["logistics", "warehouse"]:
		expect(game.campus.cargo[id][0].visible and visit.trade in ["inbound", "outbound"], "moving freight appears during a real load")
	if id == "wash":
		expect(game.effects.water.emitting and game.effects.foam.emitting, "live wash effect")
	await focus_photo(id, configuration[2], 25 if id in ["logistics", "warehouse", "truck_park"] else 20)
	for frame in 860:
		step(.10)
		if not game.traffic.dispatch.live.has(visit.number):
			break
	expect(visit.paid and not game.traffic.dispatch.live.has(visit.number), "payment, correct exit and release after " + id)
	game.economy.collect()

func flat_photo(name: String, point: Vector3, width: float) -> void:
	game.aim_camera(point, Vector3(9.2, 16.0, 17.1), width)
	await capture(name)

func focus_photo(id: String, name: String, width := 23.0) -> void:
	game.select_site(id)
	var at: Vector3 = game.campus.focus(id)
	await flat_photo(name, at + Vector3(-.28, .64, .10), width)

func phone_and_panorama(filename: String, wide: bool) -> void:
	if wide:
		root.size = Vector2i(1152, 782)
		await settle()
	var region_id: String = game.economy.district
	var subjects := {"north": Vector3(4.2, -.1, -4.5), "desert": Vector3(7, 0, -11),
		"valley": Vector3(-13.0, .0, -.50), "alpine": Vector3(-11.0, .2, -12),
		"ocean": Vector3(-11.3, .2, 2.5), "metro": Vector3(0, .4, -20.0)}
	var width := 94.0 if region_id == "metro" else 76.0 if region_id in ["desert", "north"] else 67.0
	game.aim_camera(subjects[region_id], Vector3(13, 33, 30), width)
	await capture(filename)
	if wide:
		root.size = Vector2i(640, 1138)
		await settle()

func capture(name: String) -> void:
	if captures.is_empty():
		return
	await settle()
	await RenderingServer.frame_post_draw
	var pixels := root.get_texture().get_image()
	var status := pixels.save_jpg(captures.path_join(name), .91)
	expect(status == OK, "real screenshot " + name)
	capture_count += int(status == OK)

func performance(district: String) -> void:
	if not perf_report:
		return
	game.select_site("fuel")
	game.aim_camera(game.campus.focus("fuel"), Vector3(16, 36, 31), 39.0)
	game.traffic.dispatch.spawning = true
	game.set_physics_process(true)
	await create_timer(.55).timeout
	for quality in [0, 1, 2]:
		game.set_quality(quality)
		await settle()
		var moments: Array[float] = []
		var draws := 0
		var triangles := 0
		for i in 38:
			var begin := Time.get_ticks_usec()
			await RenderingServer.frame_post_draw
			moments.append(float(Time.get_ticks_usec() - begin) / 1000.0)
			draws = maxi(draws, root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME))
			triangles = maxi(triangles, root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME))
		moments.sort()
		print("PERF %s q%d 640x1138 median_ms=%.2f p95_ms=%.2f peak_draws=%d peak_triangles=%d engine_mib=%d" %
			[district, quality, moments[19], moments[35], draws, triangles, OS.get_static_memory_usage() / 1048576])
	game.set_physics_process(false)
	game.traffic.dispatch.spawning = false
