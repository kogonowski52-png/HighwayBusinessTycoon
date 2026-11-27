extends "res://tests/expedition_recording.gd"
## Movie Maker records live rentals, paid freight and the valid atlas transition between them.

const Atlas = preload("res://data/world/atlas.gd")
const Calendar = preload("res://data/world/expedition_calendar.gd")
const AT := Calendar.START + Calendar.WEEK * 8 + 60
const Phase = HbtVisit.Phase

func run() -> void:
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.size = Vector2i(444, 790)
	root.borderless = true
	root.position = Vector2i.ZERO
	path = "/tmp/hbt-world-film-%d.cfg" % OS.get_process_id()
	var world := HbtCampaign.new(HbtEconomy.new())
	world.storage.path = path
	world.restore(AT)
	for id: String in Atlas.DESTINATIONS:
		if id != "north" and world.travel(id) != OK:
			finish(false)
			return
		var store := world.current()
		store.credit("cash", HbtAmount.from(2_000_000_000))
		store.credit("reputation", HbtAmount.from(185))
		store.finish_tutorial()
		for site: String in store.facilities:
			if site != "fuel":
				store.unlock(site)
			store.buy_levels(site, 25)
			store.buy_levels(site, 10)
			store.hire(site)
		if id == "harbor":
			break
	if world.travel("tropical") != OK:
		finish(false)
		return
	var island := load(Atlas.DESTINATIONS.tropical.scene).instantiate() as Node3D
	island.campaign = world
	island.wall_override = AT
	island.seed_override = 1602
	root.add_child(island)
	current_scene = island
	island.set_quality(1)
	island.choose_weather("clear")
	island.traffic.dispatch.spawning = false
	island.aim_camera(Vector3(-7, .0, -1), Vector3(13, 29, 31), 60)
	await create_timer(1.45).timeout
	var rental := await play(island, "rent", "tourist")
	var island_wallet: HbtEconomy = island.economy
	var leased: bool = rental != null and rental.paid and island_wallet.commerce.record("rent").outbound == 1
	press(island.hud.pages.atlas)
	await create_timer(.36).timeout
	island.operations.expedition.show_chapter(true)
	await create_timer(.24).timeout
	island.operations.expedition.open_district("harbor")
	await create_timer(.43).timeout
	await select_button(island, island.t("district_travel"))
	var port := await district("harbor")
	if port == null:
		finish(false)
		return
	port.set_quality(1)
	port.choose_weather("cloud")
	port.traffic.dispatch.spawning = false
	var freight := await play(port, "terminal", "trucker")
	var cargo: bool = freight != null and freight.paid and freight.trade in ["inbound", "outbound"]
	await create_timer(.65).timeout
	print("World film · paid rental %s · cargo settled %s" % [leased, cargo])
	root.get_node("RouteAudio").shut_down()
	port.queue_free()
	await port.tree_exited
	await create_timer(.12).timeout
	finish(leased and cargo)

func play(world: Node3D, id: String, customer: String) -> HbtVisit:
	world.select_site(id)
	world.aim_camera(world.campus.focus(id) + Vector3(.25, .55, -.75), Vector3(7.8, 15, 18.4), 21.2)
	var visit: HbtVisit = world.traffic.dispatch.try_admit(customer, id)
	if visit == null:
		return null
	for _frame in 620:
		if visit.phase == HbtVisit.Phase.WORKING and visit.progress() >= .12:
			break
		world.tick_game(.07)
	await create_timer(2.4).timeout
	for _frame in 210:
		if visit.paid:
			break
		world.tick_game(.045)
	await create_timer(.55).timeout
	return visit
