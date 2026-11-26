extends "res://tests/expedition_window.gd"
## Open each selected district through the real atlas. Dispatch clients through every service.

const Atlas = preload("res://data/world/atlas.gd")
const Regions = preload("res://data/world/regions.gd")

var target := "tropical"
var rendered := false

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--district="):
			target = arg.trim_prefix("--district=")
		if arg.begins_with("--capture-dir="):
			captures = arg.trim_prefix("--capture-dir=")
	rendered = DisplayServer.get_name() != "headless"
	expect(Regions.FRONTIERS.has(target), "enabled expansion district")
	if failures > 0:
		result("World Expansion")
		return
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.size = Vector2i(640, 1138)
	root.position = Vector2i.ZERO
	root.borderless = true
	save_path = "/tmp/hbt-frontier-%d.cfg" % OS.get_process_id()
	var world := HbtCampaign.new(HbtEconomy.new())
	world.storage.path = save_path
	world.restore(CAMPAIGN_TIME)
	var order := Atlas.DESTINATIONS.keys()
	for id: String in order.slice(0, order.find(target)):
		if id != "north":
			expect(world.travel(id) == OK, "foundation unlocks " + id)
		fund(world.current())
		world.current().hire("fuel")
		world.current().grant_reward({"card": "ada"})
	var source_id := world.active
	var sponsor := world.current()
	expect(world.available(target), "the sponsor reached the local campaign gate")
	if failures > 0:
		clean_save(save_path)
		result("World Expansion " + target)
		return
	game = load(Atlas.DESTINATIONS[source_id].scene).instantiate()
	game.campaign = world
	game.wall_override = CAMPAIGN_TIME
	game.seed_override = 113530
	root.add_child(game)
	current_scene = game
	game.set_physics_process(false)
	game.traffic.dispatch.spawning = false
	await settle()
	await show_page("atlas")
	game.operations.expedition.show_chapter(true)
	await settle()
	await take("00-atlas")
	await click_row(game.district_name(target))
	expect(game.operations.page == "district", "actual atlas row opens the destination card")
	await take("01-informacje")
	var price := HbtAmount.from(Atlas.DESTINATIONS[target].cost)
	var spent_before := sponsor.spent
	await click_row(game.t("district_open") % game.money(price))
	if not await wait_for_district(target):
		expect(false, "actual open button traveled")
		clean_save(save_path)
		result("World Expansion " + target)
		return
	expect(sponsor.spent.minus(spent_before).compare(price) == 0, "the sponsor paid exactly once")
	game.traffic.dispatch.spawning = false
	var estate: HbtEconomy = game.economy
	expect(estate.level("fuel") == 1 and estate.customers == 0 and game.station.building.scene_file_path.ends_with(target + "_fuel.glb"),
		"arrival starts an independent site with its district model")
	await take("02-pierwszy-dzien")
	click(game.hud.serve)
	var first: HbtVisit = game.traffic.dispatch.visit_at("fuel", 0)
	step(4.4)
	expect(first.paid and estate.customers == 1, "first fuel visit pays through the actual HUD")
	fund(estate)
	expect(world.boost.extend_confirmed(estate.clock), "global BOOST is available to the same campaign in the new district")
	for id: String in estate.facilities:
		expect(estate.hire(id), "assigns staff to " + id)
		await play_service(id)
		var models: Array = game.campus.upgrades[id]
		expect(models[0].get_child_count() == 1, "structural upgrades materialized for " + id)
	await take_wide("20-panorama")
	game.set_look(game.lighting.Look.NIGHT)
	await take_wide("21-noc")
	expect(estate.claimed.is_empty(), "new district kept its own quest state")
	var expected_sales := estate.customers
	game.operations.hide_page()
	await show_page("atlas")
	game.operations.expedition.show_chapter(Atlas.EXPANSION_CHAPTER.has(source_id))
	await click_row(game.district_name(source_id))
	await click_row(game.t("district_travel"))
	expect(await wait_for_district(source_id), "return through atlas keeps an independent estate")
	expect(sponsor.level("fuel") >= 20 and world.districts[target].customers == expected_sales, "return keeps both developments")
	var recovered := HbtCampaign.new(HbtEconomy.new())
	recovered.storage.path = save_path
	recovered.restore(game.economy.clock)
	expect(recovered.districts.has(target) and recovered.districts[target].customers == expected_sales,
		"saved visits survive a real scene transition and restore")
	for id: String in estate.facilities:
		expect(recovered.districts[target].level(id) == estate.level(id) and recovered.districts[target].crew[id].size() == 1,
			"persisted staff and level for " + id)
	root.get_node("RouteAudio").shut_down()
	game.free()
	await process_frame
	clean_save(save_path)
	result("World Expansion " + target)

func fund(store: HbtEconomy) -> void:
	store.credit("cash", HbtAmount.from("500000000000"))
	store.credit("reputation", HbtAmount.from(180))
	store.finish_tutorial()
	for id: String in store.facilities:
		if id != "fuel" and not store.unlock(id):
			expect(false, "reachable business gate " + store.district + "/" + id)
		store.buy_levels(id, 25)
		store.buy_levels(id, 10)

func play_service(id: String) -> void:
	var estate: HbtEconomy = game.economy
	var dispatch: HbtDispatch = game.traffic.dispatch
	var facility: HbtService = estate.facilities[id]
	var customer := "trucker" if facility.vehicle_kind == "truck" else "electric" if facility.vehicle_kind == "electric" else "vip" if target == "luxury" else "tourist" if target == "tropical" else "local"
	var ticket := dispatch.try_admit(customer, id)
	expect(ticket != null, "the queue admitted a fitting " + customer + " for " + id)
	if ticket == null:
		return
	var at: Vector3 = game.routes.focus(id) if game.routes.has_method("focus") else game.campus.focus(id)
	game.select_site(id)
	game.aim_camera(at + Vector3(0, .9, -1.3), Vector3(6.8, 12.0, 16.9), 22.2 if facility.vehicle_kind == "truck" else 17.3)
	for i in range(1250):
		game.tick_game(.045)
		if ticket.phase == Phase.WORKING and ticket.progress() > .34:
			break
	expect(ticket.phase == Phase.WORKING and ticket.worker >= 0, "the assigned worker started the service at " + id)
	if id != "fuel":
		expect(game.campus.buildings[id].is_visible_in_tree() and game.campus.built_venues.has(id),
			"the corresponding model is mounted and visible for " + id)
	await take("10-" + id)
	var earned := int(estate.per_service[id].count)
	for i in range(1400):
		game.tick_game(.045)
		if not dispatch.live.has(ticket.number):
			break
	expect(ticket.paid and int(estate.per_service[id].count) == earned + 1,
		"worker's finished service pays once and is saved in " + id)
	expect(not dispatch.live.has(ticket.number), "the vehicle leaves without blocking the road at " + id)
	if estate.global_boost.earning(estate.clock):
		expect(ticket.invoice.compare(ticket.base_invoice.times(2)) == 0, "global BOOST applies once at " + id)
	if facility.venue_kind in ["freight", "cold"]:
		var goods := estate.commerce.record(id)
		expect(int(goods.inbound) + int(goods.outbound) == 1, "the shipment changes inventory once at " + id)
	if facility.venue_kind in ["rent", "scooter"]:
		var goods := estate.commerce.record(id)
		expect(int(goods.outbound) == 1 and goods.returns.size() == 1, "a real lease reserves local stock at " + id)

func take_wide(name: String) -> void:
	if not rendered or captures.is_empty():
		return
	root.size = Vector2i(1180, 782)
	game.aim_camera(Regions.LAYOUTS[target].center, Vector3(12.8, 30.0, 35.0), 81.0)
	await settle()
	await take(name)
	root.size = Vector2i(640, 1138)
	await settle()

func take(name: String) -> void:
	if not rendered or captures.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(captures)
	await settle()
	await RenderingServer.frame_post_draw
	expect(root.get_texture().get_image().save_jpg(captures.path_join(target + "-" + name + ".jpg"), .91) == OK,
		"real viewport screenshot " + name)
