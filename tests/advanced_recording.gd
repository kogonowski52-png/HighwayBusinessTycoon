extends "res://tests/advanced_window.gd"

const FPS := 10

func run() -> void:
	var only := "all"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--feature="):
			only = argument.get_slice("=",1)
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.size = Vector2i(344, 612)
	root.position = Vector2i.ZERO
	root.borderless = true
	save_path = "/tmp/hbt-advanced-movie-%d.cfg" % OS.get_process_id()
	game = mount_metro() if only == "cargo" else mount(AT)
	current_scene = game
	game.traffic.dispatch.spawning = false
	game.economy.preferences.auto_day = false
	game.skip_tutorial()
	prepare(game.economy)
	game.set_quality(1)
	await settle_ui()
	if only in ["all","flota"]:
		await record_fleet()
	if only in ["all","fuel"]:
		await record_practice("fuel")
	if only in ["all","wash"]:
		await record_practice("wash")
	if only in ["all","drogi"]:
		await record_works()
	if only == "cargo" or (only == "all" and await reach_metro()):
		await record_practice("logistics")
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
	for _frame in 56:
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
	screen.set_process(false)
	await settle_ui()
	segment(mode, true)
	await create_timer(.34).timeout
	await press_control(screen.start_button)
	match mode:
		"fuel":
			for index in Practice.BANDS.size():
				for frame in 20:
					rules.advance(.20)
					if rules.fuel_ready():
						break
					screen.refresh()
					screen.board.queue_redraw()
					if frame % 3 == 0:
						await process_frame
				while rules.fuel_ready() and absf(rules.needle() - Practice.BANDS[index]) > .043:
					rules.advance(.02)
				screen.refresh()
				screen.board.queue_redraw()
				await process_frame
				if not rules.done:
					await press_control(screen.action)
		"wash":
			for repeat in 2:
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
					for point in range(1,6):
						drag(from.lerp(to, point / 5.0), (to - from) / 5.0)
						rules.advance(.19)
						screen.refresh()
						await process_frame
					touch(to,false)
		"cargo":
			for i in 6:
				await create_timer(.52).timeout
				rules.advance(2.54)
				if i == 1:
					await press_control(screen.action)
				var at: Vector2i = [Vector2i.ZERO,Vector2i(2,0),Vector2i(2,3),Vector2i(0,2),Vector2i(1,5),Vector2i(0,4)][i]
				var grid: Control = screen.board
				var pointer: Vector2 = grid.get_global_rect().position + grid.bed() + (Vector2(at) + Vector2(.5,.5)) * grid.metric()
				touch(pointer,true)
				await process_frame
				touch(pointer,false)
	if not rules.done:
		rules.advance(maxf(0.0, 16.0 - rules.elapsed))
		if not rules.complete():
			rules.advance(rules.last())
		screen.finish()
	expect(rules.done and not screen.earned.empty() and rules.score() > 50, "finished and paid in the actual " + mode + " recording")
	await create_timer(.9).timeout
	segment(mode, false)
	if rules.done:
		await press_control(screen.start_button)
	else:
		screen.dismiss()
	game.operations.hide_page()
