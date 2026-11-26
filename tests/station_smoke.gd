extends "res://tests/run_checks.gd"

const Main = preload("res://scenes/world/roadside.tscn")
const Phase = HbtVisit.Phase
const WALL := 1_789_000_000
var game: Node3D
var captures := ""
var save_path: String

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			captures = argument.trim_prefix("--capture-dir=")
	if not captures.is_empty() and DisplayServer.get_name() == "headless":
		expect(false, "capture requires a display")
		result("Station gameplay")
		return
	save_path = "/tmp/hbt-idle-smoke-%d.cfg" % OS.get_process_id()
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.size = Vector2i(720, 1280) if not captures.is_empty() else Vector2i(540, 960)
	root.position = Vector2i.ZERO
	root.borderless = true
	game = mount(WALL)
	await process_frame
	await process_frame
	var economy: HbtEconomy = game.economy
	var dispatch: HbtDispatch = game.traffic.dispatch
	expect(economy.amount("cash").decimal() == "120" and economy.level("fuel") == 1, "new profile budget and location")
	expect(controls_fit(), "phone controls fit")
	expect(not game.hud.serve.disabled and game.hud.upgrade.disabled, "first customer ready with unaffordable upgrade")
	click(game.hud.serve)
	expect(game.hud.serve.disabled and not dispatch.start_manual("fuel"), "click starts a single service")
	step(1.0)
	expect(game.hud.progress.value > 0.12 and game.effects.hose[0].visible and game.driver.cycles == "fuel",
		"actual service drives the model, hose and progress UI")
	await capture("01-tankowanie.png")
	step(2.0)
	expect(economy.amount("cash").decimal() == "155" and economy.customers == 1, "first purchase amount is earned by refueling")
	click(game.hud.upgrade_preview)
	await process_frame
	expect(game.operations.visible and game.operations.page == "upgrades", "building illustration and upgrade sheet opens")
	await capture("08-etapy.png")
	await click_row(game.hud.upgrade.text)
	expect(economy.level("fuel") == 2 and economy.amount("cash").empty(), "upgrade sheet commits the same purchase")
	await close_sheet()

	click(game.hud.pages.goals)
	await process_frame
	expect(game.operations.visible and game.operations.page == "goals", "goals sheet opens from HUD")
	await click_row("Odbierz")
	await click_row("Odbierz")
	expect(economy.claimed.has("first") and economy.claimed.has("upgrade") and economy.amount("diamond").decimal() == "2",
		"claims pay disclosed rewards")
	await close_sheet()
	click(game.hud.pages.team)
	await process_frame
	await click_row(game.t("recruit") % game.money(economy.recruit_cost("fuel")))
	expect(economy.crew.fuel.size() == 1 and game.crew.staff.fuel.size() == 1, "recruitment places a real employee at the station")
	await close_sheet()
	var worked := false
	for t in range(700):
		step(0.05)
		var work := dispatch.first_at("fuel", Phase.WORKING)
		if work != null and work.worker == 0 and game.crew.staff.fuel[0].cycles == "fuel":
			worked = true
			break
	expect(worked, "employee physically walks to the bay and fuels on their own")
	await capture("02-automatyzacja.png")
	step(3.0)
	expect(not economy.holding().empty() and economy.crew.fuel[0].xp >= 1, "automated sale enters the till and grants XP")
	await process_frame
	click(game.hud.income)
	expect(economy.holding().empty(), "cash collection button transfers ledger balance")
	click(game.hud.pages.goals)
	await process_frame
	await click_row("Odbierz")
	expect(economy.cards.has("ada"), "crew mission grants a named manager card")
	await close_sheet()
	click(game.hud.pages.managers)
	await process_frame
	await click_row("Ada Nowak")
	await click_row("Aktywuj")
	expect("ada" in economy.equipped and game.crew.directors.has("ada"), "manager activation appears in the scene")
	await capture("03-zespol.png")
	await close_sheet()

	await earn_for_shop()
	var quote := economy.construction_quote("market")
	expect(quote.ready, "market unlock reached through ordinary sales")
	click(game.hud.pages.sites)
	await process_frame
	await click_row(game.t("unlock") % game.money(quote.cost))
	expect(game.selected == "market" and economy.level("market") == 1, "market opens from the priced directory action")
	await close_sheet()
	click(game.hud.upgrade_preview)
	await process_frame
	await click_row("+10")
	await close_sheet()
	expect(game.quantity == 10 and game.hud.upgrade.disabled, "batch price respects available wallet")

	provision(expansion_targets())
	dispatch.spawning = false
	step(50.0)
	var washer := dispatch.try_admit("local", "wash")
	var truck := dispatch.try_admit("trucker", "truck")
	expect(washer != null and truck != null and dispatch.lanes.car.size() == 1 and dispatch.lanes.truck.size() == 1,
		"passenger and freight entries use separate physical queues")
	game.select_site("wash")
	for turn in range(680):
		step(0.05)
		if washer != null and washer.phase == Phase.WORKING and game.effects.water.emitting:
			break
	expect(washer != null and washer.phase == Phase.WORKING and game.effects.foam.emitting,
		"reserved car activates physical wash effects during service")
	await capture("04-myjnia.png")
	step(12.0)
	expect(truck != null and truck.paid and economy.per_service.truck.count > 0 and dispatch.consistent(),
		"lorry is fuelled at its dedicated bay")
	click(game.hud.lighting)
	click(game.hud.view)
	expect(game.overview and game.lighting.current == game.lighting.Look.GOLDEN, "view and lighting controls remain usable")
	await capture("05-kompleks.png")

	click(game.hud.settings)
	await process_frame
	await click_row("EN")
	await click_row(game.t("battery_off"))
	await close_sheet()
	expect(economy.language == "en" and economy.low_power and Engine.max_fps == 30, "English and energy mode work")
	economy.checkpoint()
	var wallet := economy.amount("cash")
	var after := economy.clock
	game.free()
	game = mount(after + 1800)
	await process_frame
	await process_frame
	economy = game.economy
	expect(economy.amount("cash").compare(wallet) == 0 and economy.cards.has("ada") and economy.level("wash") > 0,
		"profile restores facilities, cash and manager")
	expect(game.operations.visible and game.operations.page == "offline" and not economy.offline_pending.empty(),
		"relaunch presents the offline payout")
	var income := economy.offline_pending
	await capture("06-offline.png")
	await click_row(game.t("claim_offline") % game.money(income))
	expect(economy.amount("cash").compare(wallet.plus(income)) == 0 and economy.offline_pending.empty(),
		"offline collected with real dialog button, once")
	if not captures.is_empty():
		root.size = Vector2i(900, 1200)
		await process_frame
		await process_frame
		expect(controls_fit(), "tablet controls fit")
		await capture("07-tablet.png")
	game.free()
	clean_save(save_path)
	result("Station gameplay")

func expansion_targets() -> Array[String]:
	return ["market", "parking", "wash", "truck", "workshop", "restaurant", "motel"]

func provision(targets: Array[String]) -> void:
	# A seeded QA scenario reaches late traffic without editing the player's save or waiting for hours.
	var store: HbtEconomy = game.economy
	store.credit("cash", HbtAmount.from(70_000))
	store.credit("reputation", HbtAmount.from(100))
	store.buy_levels("fuel", 3)
	for id in targets:
		if store.level(id) == 0:
			store.unlock(id)
		if store.level(id) < 3:
			store.buy_levels(id, 3 - store.level(id))
	store.hire("wash")
	store.hire("truck")

func mount(at: int) -> Node3D:
	var instance := Main.instantiate()
	instance.economy.storage.path = save_path
	instance.wall_override = at
	instance.seed_override = 68427
	instance.set_physics_process(false)
	root.add_child(instance)
	instance.set_physics_process(false)
	return instance

func earn_for_shop() -> void:
	var economy: HbtEconomy = game.economy
	for _turn in range(360):
		var quote := economy.construction_quote("market")
		if quote.ready:
			break
		step(.25)
		if not quote.cash_ok and not economy.holding().empty():
			click(game.hud.income)
	await process_frame

func step(seconds: float) -> void:
	for i in range(roundi(seconds / 0.05)):
		game.tick_game(0.05)

func click(button: Button) -> void:
	if not is_instance_valid(button) or not button.is_visible_in_tree():
		return
	var point := button.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = point
		event.global_position = point
		root.push_input(event, true)

func close_sheet() -> void:
	click(game.operations.back)
	for frame in range(22):
		if not game.operations.visible:
			break
		await process_frame

func click_row(label: String) -> void:
	var button := find_button(game.operations.rows, label)
	if button == null:
		expect(false, "missing button: " + label)
		return
	game.operations.scroll.ensure_control_visible(button)
	await process_frame
	click(button)
	await process_frame
	await process_frame

func find_button(parent: Node, label: String) -> Button:
	for option in parent.find_children("*", "Button", true, false):
		if option.text == label and not option.disabled:
			return option
	return null

func controls_fit() -> bool:
	var screen := root.get_visible_rect()
	for button in [game.hud.serve, game.hud.upgrade, game.hud.settings, game.hud.rank, game.hud.lighting, game.hud.view] + game.hud.pages.values():
		if not screen.encloses(button.get_global_rect()):
			return false
	return true

func capture(name: String) -> void:
	if captures.is_empty():
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var pixels := root.get_texture().get_image()
	expect(pixels != null and pixels.save_png(captures.path_join(name)) == OK, "screenshot " + name)
