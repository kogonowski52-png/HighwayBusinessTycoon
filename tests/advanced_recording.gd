extends "res://tests/advanced_window.gd"

const FPS := 15

func run() -> void:
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.size = Vector2i(444, 790)
	root.position = Vector2i.ZERO
	root.borderless = true
	save_path = "/tmp/hbt-advanced-movie-%d.cfg" % OS.get_process_id()
	game = mount(AT)
	current_scene = game
	game.traffic.dispatch.spawning = false
	game.economy.preferences.auto_day = false
	game.skip_tutorial()
	prepare(game.economy)
	await settle_ui()
	await record_fleet()
	await record_practice("fuel")
	await record_practice("wash")
	await record_works()
	if await reach_metro():
		await record_practice("logistics")
	else:
		expect(false, "cargo loading scene ready in Metro")
	root.get_node("RouteAudio").shut_down()
	game.free()
	await create_timer(.18).timeout
	clean_save(save_path)
	result("Advanced Gameplay authentic recordings")

func segment(id: String, start: bool) -> void:
	print("CLIP ", id, " ", "start" if start else "end", " ", Engine.get_process_frames())

func record_fleet() -> void:
	var freight = game.campaign.freight
	expect(freight.buy(game.campaign,"van") and freight.hire(game.campaign)
		and freight.assign(game.campaign,"1","2"), "equip a real vehicle for the clip")
	var quote: Dictionary = freight.quote(game.campaign, "north/0", "1")
	await show_page("freight")
	var line: String = game.t("freight_dispatch") % [game.operations.logistics.unit_name("1"), game.money(HbtAmount.from(quote.cost))]
	var button := find_button(game.operations.rows, line)
	game.operations.scroll.ensure_control_visible(button)
	await settle_ui()
	segment("flota", true)
	await create_timer(.8).timeout
	await click_row(line)
	for _frame in 129:
		game.tick_game(1.0 / FPS)
		await process_frame
	step(float(quote.duration))
	await show_page("freight")
	await create_timer(.85).timeout
	expect(freight.completed == 1, "recording's courier settled")
	segment("flota", false)
	game.operations.hide_page()

func record_works() -> void:
	var estate: HbtEconomy = game.economy
	var charge: HbtAmount = estate.works.construction_cost(estate, "roads")
	await show_page("infrastructure")
	var line: String = game.t("infrastructure_build") % game.money(charge)
	var row := find_button(game.operations.rows, line)
	game.operations.scroll.ensure_control_visible(row)
	await settle_ui()
	segment("drogi", true)
	await create_timer(.75).timeout
	await click_row(line)
	await create_timer(1.5).timeout
	expect(estate.works.stage("roads") == 1 and game.estate_view.upgrades.get_child_count() == 1,
		"recorded real road works")
	segment("drogi", false)

func record_practice(site: String) -> void:
	game.select_site(site)
	game.start_practice(site)
	if not game.practice_open():
		expect(false, "camera starts practice " + site)
		return
	var screen: CanvasLayer = game.practice_screen
	var rules: RefCounted = screen.session
	var mode: String = rules.practice
	await settle_ui()
	segment(mode, true)
	await create_timer(.55).timeout
	await press_control(screen.start_button)
	match mode:
		"fuel":
			for index in Practice.BANDS.size():
				while not rules.done and (not rules.fuel_ready() or absf(rules.needle() - Practice.BANDS[index]) > .052):
					await process_frame
				if not rules.done:
					await press_control(screen.action)
		"wash":
			for repeat in 3:
				var surface: Rect2 = screen.board.get_global_rect()
				for column in 6:
					var x := -.73 + column * .29
					var lens: Camera3D = screen.illustration.camera
					var view: SubViewport = screen.illustration.viewport
					var low := surface.position + lens.unproject_position(Vector3(x,.49,-1.70)) * surface.size / Vector2(view.size)
					var high := surface.position + lens.unproject_position(Vector3(x,.49,1.70)) * surface.size / Vector2(view.size)
					var from := low if column % 2 == 0 else high
					var to := high if column % 2 == 0 else low
					touch(from, true)
					for point in range(1,10):
						drag(from.lerp(to, point / 9.0), (to - from) / 9.0)
						await process_frame
					touch(to,false)
		"cargo":
			for i in 6:
				await create_timer(2.45).timeout
				if i == 1:
					await press_control(screen.action)
				var at: Vector2i = [Vector2i.ZERO,Vector2i(2,0),Vector2i(2,3),Vector2i(0,2),Vector2i(1,5),Vector2i(0,4)][i]
				var grid: Control = screen.board
				var pointer: Vector2 = grid.get_global_rect().position + grid.bed() + (Vector2(at) + Vector2(.5,.5)) * grid.metric()
				touch(pointer,true)
				await process_frame
				touch(pointer,false)
	for _frame in 600:
		if rules.done:
			break
		await process_frame
	expect(rules.done and not screen.earned.empty() and rules.score() > 50, "finished and paid in the actual " + mode + " recording")
	await create_timer(.9).timeout
	segment(mode, false)
	if rules.done:
		await press_control(screen.start_button)
	else:
		screen.dismiss()
	game.operations.hide_page()
