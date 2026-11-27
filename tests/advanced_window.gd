extends "res://tests/station_smoke.gd"
## Drive the production panels and touch controls in a rendered Godot viewport.

const Atlas = preload("res://data/world/atlas.gd")
const FreightData = preload("res://data/logistics/fleet.gd")
const ContractData = preload("res://data/logistics/contracts.gd")
const Practice = preload("res://scripts/challenges/service_practice.gd")
const EstateCatalog = preload("res://data/estate/complex_design.gd")
const AT := 1_804_980_000
var count := 0

func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			captures = argument.get_slice("=", 1)
	if not captures.is_empty():
		DirAccess.make_dir_recursive_absolute(captures)
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.size = Vector2i(576, 1024)
	root.position = Vector2i.ZERO
	root.borderless = true
	save_path = "/tmp/hbt-advanced-window-%d.cfg" % OS.get_process_id()
	game = mount(AT)
	current_scene = game
	game.economy.preferences.auto_day = false
	game.traffic.dispatch.spawning = false
	game.skip_tutorial()
	prepare(game.economy)
	await settle_ui()
	await fleet_scene()
	await show_practice("fuel")
	await show_practice("wash")
	await test_estate()
	for id: String in ["market", "workshop", "wash", "restaurant", "motel"]:
		await room_scene(id)
	if await reach_metro():
		await show_practice("logistics")
		for id: String in ["dealership", "mall", "warehouse", "logistics"]:
			await room_scene(id)
		await show_page("empire")
		await picture("50-imperium-po-modernizacji")
		game.operations.hide_page()
	else:
		expect(false, "the campaign travels to the Metro cargo service")
	root.get_node("RouteAudio").shut_down()
	game.free()
	await create_timer(.18).timeout
	clean_save(save_path)
	result("Advanced Gameplay in Godot")

func prepare(estate: HbtEconomy) -> void:
	estate.credit("cash", HbtAmount.from("1000000000"))
	estate.credit("reputation", HbtAmount.from(200))
	estate.buy_levels("fuel", 25)
	for id: String in estate.facilities:
		if id != "fuel":
			estate.unlock(id)
		if estate.level(id) > 0:
			estate.hire(id)
			estate.buy_levels(id, 10)
	estate.credit("cash", HbtAmount.from(80_000))
	estate.touch()

func fleet_scene() -> void:
	await show_page("finance")
	await click_row(game.t("empire_header"))
	expect(game.operations.page == "empire", "dashboard opens from the finance ribbon")
	await picture("01-centrum-imperium")
	await click_row(game.t("fleet_header"))
	await picture("02-kupno-floty")
	await click_row(game.t("fleet_buy") % game.money(HbtAmount.from(FreightData.TYPES.van.price)))
	expect(game.campaign.freight.vehicles.has("1") and is_instance_valid(game.depot), "real purchase opens the rendered yard")
	await picture("03-parcel-w-garazu")
	await click_row(game.t("fleet_workforce"))
	await click_row(game.t("fleet_hire") % game.money(HbtAmount.from(FreightData.DRIVER_PRICE)))
	await picture("04-miejsce-pracy-kierowcy")
	await click_row(game.t("fleet_garage"))
	await click_row(game.t("fleet_assign") % "Maja Lis")
	expect(game.campaign.freight.vehicles["1"].driver == "2", "dispatch has the staff member from the UI")
	await picture("05-kierowca-przydzielony")
	await click_row(game.t("fleet_open_yard"))
	await create_timer(.62).timeout
	await picture("06-baza-transportowa")
	await show_page("freight")
	await picture("07-tablica-zlecen")
	var sender_cash: HbtAmount = game.economy.amount("cash")
	var quote: Dictionary = game.campaign.freight.quote(game.campaign, "north/0", "1")
	var unit: String = game.operations.logistics.unit_name("1")
	await click_row(game.t("freight_dispatch") % [unit, game.money(HbtAmount.from(quote.cost))])
	expect(game.campaign.freight.jobs.size() == 1 and game.depot.trucks.size() == 1, "first dispatch creates a moving truck in the actual depot")
	await create_timer(.6).timeout
	await picture("08-wyjazd-z-bazy")
	var truck: Node3D = game.depot.trucks.values().front()
	var at := truck.position
	step(4)
	game.depot.animate(.25)
	expect(truck.position.distance_to(at) > .8, "assigned vehicle moves along its shipping lane")
	await picture("09-przejazd-dostawczego")
	await show_page("freight")
	await picture("10-transport-w-toku")
	game.operations.hide_page()
	step(39)
	await settle_ui()
	await show_page("freight")
	await picture("11-zaplacona-dostawa")
	expect(game.campaign.freight.completed == 1 and game.economy.amount("cash").compare(
		sender_cash.minus(HbtAmount.from(quote.cost)).plus(HbtAmount.from(quote.reward))) == 0, "actual trip settles the promised payment")
	await show_page("empire")
	await picture("12-imperium-po-dostawie")
	game.operations.hide_page()

func show_practice(site: String) -> void:
	game.select_site(site)
	await show_page("upgrades")
	var kind := Practice.mode(game.economy, site)
	await click_row(game.t("practice_" + kind))
	if not game.practice_open():
		expect(false, "management sheet opens practice " + site)
		return
	var screen: CanvasLayer = game.practice_screen
	screen.set_process(false)
	await settle_ui()
	await picture("20-" + kind + "-instrukcja")
	await press_control(screen.start_button)
	var lab: RefCounted = screen.session
	expect(lab.started, "touch starts " + kind)
	match kind:
		"fuel":
			for i in Practice.BANDS.size():
				while not lab.fuel_ready() or absf(lab.needle() - Practice.BANDS[i]) > .028:
					lab.advance(.022)
					if lab.elapsed >= lab.last():
						break
				screen.refresh()
				screen.board.queue_redraw()
				if i in [0,2]:
					await picture("21-fuel-pomiar-" + str(i+1))
				await press_control(screen.action)
		"wash":
			await picture("21-wash-zabrudzony")
			var previous: Vector3 = game.camera_rig.target
			var surface: Rect2 = screen.board.get_global_rect()
			for pass_no in 3:
				for column in 7:
					var from: Vector2
					var to: Vector2
					if screen.illustration != null:
						var view: SubViewport = screen.illustration.viewport
						var lens: Camera3D = screen.illustration.camera
						var x := -.78 + column * .26
						from = surface.position + lens.unproject_position(Vector3(x, .48, -1.72)) * surface.size / Vector2(view.size)
						to = surface.position + lens.unproject_position(Vector3(x, .48, 1.72)) * surface.size / Vector2(view.size)
					else:
						var x := .12 + float(column) * .12
						from = surface.position + Vector2(surface.size.x * x, surface.size.y * .14)
						to = surface.position + Vector2(surface.size.x * x, surface.size.y * .86)
					touch(from, true)
					for step_no in range(1, 13):
						var move := from.lerp(to, step_no / 12.0)
						drag(move, (to - from) / 12.0)
					touch(to, false)
				screen.refresh()
				await picture("22-wash-etap-" + str(pass_no + 1))
			lab.advance(lab.last())
			expect(game.camera_rig.target == previous and lab.score() >= 75, "wash drags clean the mesh while blocking world movement")
		"cargo":
			for i in 6:
				if i == 1:
					await press_control(screen.action)
				var at: Vector2i = [Vector2i.ZERO,Vector2i(2,0),Vector2i(2,3),Vector2i(0,2),Vector2i(1,5),Vector2i(0,4)][i]
				var board: Control = screen.board
				var point: Vector2 = board.get_global_rect().position + board.bed() + (Vector2(at) + Vector2(.5,.5)) * board.metric()
				touch(point, true)
				touch(point, false)
				screen.refresh()
				board.queue_redraw()
				if i in [0,2,4]:
					await picture("21-cargo-partia-" + str(i + 1))
			lab.advance(18)
			expect(lab.piece_count() == 6, "touch places six crates in real grid reservations")
	if not lab.done:
		screen.finish()
	expect(lab.done and lab.score() >= 75 and not screen.earned.empty(), "actual mini-game finishes and receives one earned payment " + kind)
	await picture("23-" + kind + "-nagroda")
	await press_control(screen.start_button)
	expect(not game.practice_open(), "result returns to the same business")
	game.operations.hide_page()

func test_estate() -> void:
	await show_page("empire")
	await click_row(game.t("design_header"))
	expect(game.operations.page == "design", "Empire links the customization catalog")
	await picture("30-katalog-personalizacji")
	var modules: RefCounted = game.economy.works
	for slot: String in ["facade", "roof", "canopy", "fence", "paving", "plants", "planter", "bench", "fountain", "lights", "billboard", "sign"]:
		var state: RefCounted = game.operations.development
		state.choose(slot)
		state.select_style(1)
		await settle_ui()
		game.operations.scroll.scroll_vertical = 590
		await process_frame
		await picture("31-podglad-" + slot)
		expect(not modules.designs.has(slot), "preview never commits " + slot)
		await click_row(game.t("design_apply"))
		expect(modules.designs.get(slot, 0) == 1, "actual apply equips " + slot)
		game.operations.scroll.scroll_vertical = 0
		await process_frame
	game.view_estate(false)
	await create_timer(.70).timeout
	await picture("32-wlasny-taras")
	var transit: Vector3 = game.camera_rig.target
	await show_page("infrastructure")
	await picture("33-zestaw-infrastruktury")
	var before: float = game.economy.works.travel_scale(Phase.ENTERING)
	var bill: HbtAmount = modules.construction_cost(game.economy, "roads")
	await click_row(game.t("infrastructure_build") % game.money(bill))
	expect(modules.stage("roads") == 1 and modules.travel_scale(Phase.ENTERING) > before,
		"purchased internal roads improve actual movement")
	await create_timer(.70).timeout
	await picture("34-modernizacja-drogi")
	for id: String in EstateCatalog.INFRASTRUCTURE:
		if id != "roads":
			expect(modules.build(game.economy, id), "actual regional investment " + id)
	game.view_estate(true)
	await create_timer(.70).timeout
	await picture("35-ukonczona-infrastruktura")
	expect(game.estate_view.upgrades.get_child_count() == 10, "all ten templates appear in the mounted complex")
	await show_page("marketing")
	var price: HbtAmount = modules.campaign_price(game.economy, "roadside")
	await click_row(game.t("marketing_launch") % game.money(price))
	expect(modules.active(game.economy.clock).group == "traveler", "the campaign button purchases real targeting")
	await picture("36-aktywna-kampania")
	await show_page("inspections")
	await picture("37-ocena-obslugi")
	game.operations.hide_page()

func room_scene(id: String) -> void:
	if game.economy.level(id) == 0:
		expect(false, "the test builds the advertised interior " + id)
		return
	game.traffic.dispatch.spawning = false
	var traffic: HbtDispatch = game.traffic.dispatch
	var family: String = game.economy.facilities[id].vehicle_kind
	var visitor := "trucker" if family == "truck" else "vip" if id in ["motel", "dealership"] else "family"
	var ticket: HbtVisit
	for _attempt in 7:
		ticket = traffic.try_admit(visitor, id)
		if ticket != null:
			break
		step(1.0)
	if ticket != null:
		for _attempt in 1450:
			game.tick_game(.035)
			if ticket.phase == Phase.WORKING and ticket.progress() > .27:
				break
	expect(ticket != null and ticket.phase == Phase.WORKING, "real staffed customer visits " + id)
	game.select_site(id)
	await show_page("upgrades")
	await click_row(game.t("interior_action"))
	var room: Control = game.operations.interior
	if room == null:
		expect(false, "interior action mounts " + id)
		return
	for _frame in 180:
		if room.loaded or room.failed:
			break
		await process_frame
	expect(room.loaded and room.apartment != "" and room.attendant != null, "dedicated streamed room with staff " + id)
	await picture("40-otwarcie-" + id)
	await create_timer(.76).timeout
	await picture("41-wnetrze-" + id)
	if room.loaded:
		expect(not room.failed and not room.roof.visible and "%" in room.progress.text,
			"cut-away roof and real visit progress " + id)
	await click_row(game.t("interior_return"))
	await process_frame
	expect(not is_instance_valid(room), "previous interior releases its viewport")
	game.operations.hide_page()
	step(11.0)

func press_control(button: Button) -> void:
	var at := button.get_global_rect().get_center()
	touch(at, true)
	touch(at, false)
	await process_frame
	await process_frame

func touch(at: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.position = at
	event.pressed = pressed
	root.push_input(event, true)

func drag(at: Vector2, distance: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.position = at
	event.relative = distance
	root.push_input(event, true)

func show_page(page: String) -> void:
	game.open_page(page)
	await settle_ui()

func settle_ui() -> void:
	await create_timer(.24).timeout
	await process_frame

func picture(name: String) -> void:
	if captures.is_empty() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	expect(frame.save_jpg(captures.path_join(name + ".jpg"), .92) == OK, "write engine frame " + name)
	count += 1

func reach_metro() -> bool:
	for id: String in ["desert", "valley", "alpine", "ocean", "metro"]:
		if not game.campaign.available(id):
			printerr("Travel gate ", id, " from ", game.economy.district, " levels ", game.economy.levels, " cash ", game.economy.amount("cash").decimal(), " rep ", game.economy.metric("reputation"))
			return false
		game.travel_to(id)
		var arrived := false
		for _frame in 420:
			await process_frame
			if is_instance_valid(current_scene) and current_scene.has_method("tick_game") and current_scene.economy.district == id:
				game = current_scene
				game.set_physics_process(false)
				game.traffic.dispatch.spawning = false
				prepare(game.economy)
				arrived = true
				break
		if not arrived:
			printerr("Travel did not complete ", id, " current ", game.economy.district, " loading ", game.traveling, " save ", game.economy.save_error)
			return false
	return true
