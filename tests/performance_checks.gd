extends "res://tests/station_smoke.gd"

const Atlas = preload("res://data/world/atlas.gd")
const Budget = preload("res://scripts/core/render_budget.gd")
const Prefs = preload("res://scripts/core/player_preferences.gd")

func run() -> void:
	save_path = "/tmp/hbt-stage7-checks-%d.cfg" % OS.get_process_id()
	game = mount(WALL)
	quality_checks()
	commerce_checks()
	lifecycle_checks()
	for count in [20, 50, 100, 200]:
		await traffic_load(count)
	game.free()
	await process_frame
	clean_save(save_path)
	result("Stage 7 rendering, lifecycle, arithmetic and stressed traffic")

func quality_checks() -> void:
	var prefs := Prefs.new()
	prefs.restore({"quality": 1, "fps": 60})
	expect(prefs.quality == 1 and not prefs.quality_auto, "saved manual quality survives from the previous release")
	for tier in range(Budget.LABELS.size()):
		game.set_quality(tier)
		expect(game.render_quality == tier and is_equal_approx(root.scaling_3d_scale, Budget.SCALES[tier]) \
			and is_equal_approx(root.mesh_lod_threshold, Budget.LOD_PIXELS[tier]) and root.msaa_3d == Budget.SAMPLES[tier],
			"profile %d applies rendering scale, LOD and sampling" % tier)
	game.set_quality_auto()
	var chosen: int = game.economy.preferences.quality
	var reported: bool = false
	for _step in 128:
		reported = game.render_budget.sample(.050, 60) or reported
	expect(reported and game.render_budget.active < game.render_budget.ceiling and game.economy.preferences.quality == chosen,
		"sustained slow frames lower automatic quality and keep the manual Ultra choice")
	game.set_quality_auto()
	expect(game.render_quality == 3, "turning off Automatic restores the manual value")
	game.toggle_power()
	expect(game.render_quality == 0 and Engine.max_fps == 30 and game.effects.reduced, "battery mode applies 30 FPS and least expensive effects")
	game.toggle_power()
	game.set_quality(1)
	expect(is_instance_valid(game.diagnostics) and not game.diagnostics.board.visible, "test diagnostics start hidden")
	game.diagnostics.toggle()
	expect(game.diagnostics.board.visible and "BOOST" in game.diagnostics.sdk_summary(), "optional counters and commerce status are connected")
	game.diagnostics.toggle()

func commerce_checks() -> void:
	var services := 0
	for region: String in Atlas.DESTINATIONS:
		var estate := HbtEconomy.new(region)
		estate.restore_profile({}, WALL, false)
		estate.credit("cash", HbtAmount.from("9055000000000000000000000000000000"))
		for id: String in estate.facilities:
			services += 1
			estate.levels[id] = 5
			for quantity in [1, 10, 25, 0]:
				var count: int = 95 if quantity == 0 else quantity
				var exact := HbtAmount.new()
				for tier in range(5, 5 + count):
					exact = exact.plus(estate.cost_at(id, tier))
				var quote := estate.quote_upgrade(id, quantity)
				expect(quote.count == count and quote.cost.compare(exact) == 0 and quote.affordable, "exact bulk quote %s/%s/%d" % [region, id, quantity])
			var limit := estate.quote_upgrade(id, 10)
			var saved: HbtAmount = estate.wallet.cash
			estate.wallet.cash = limit.cost
			expect(estate.quote_upgrade(id, 0).count == 10, "maximum affordable levels with exact cash " + id)
			estate.wallet.cash = saved
		var before := HbtAmount.from("7100000000000000000000000000000000")
		estate.serve("fuel", before, 1, -1)
		estate.clock += 1
		estate.serve("fuel", HbtAmount.from(41), 1, -1)
		expect(estate.income_per_minute().compare(before.plus(HbtAmount.from(41))) == 0, "rolling minute sums values above int64")
		estate.clock += 59
		expect(estate.income_per_minute().decimal() == "41", "one-second boundary expires the exact first payment")
	expect(services == 41, "all 41 businesses covered")

func lifecycle_checks() -> void:
	var now: int = game.economy.clock
	game.skip_tutorial()
	game.economy.hire("fuel")
	game.campaign.boost.extend_confirmed(now)
	game.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	var sequence: int = game.campaign.storage.sequence
	expect(game.suspended_at >= 0 and game.campaign.storage.read_candidate(save_path).sequence == sequence,
		"suspend forces an atomic checkpoint")
	game._physics_process(140.0)
	game.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	expect(game.campaign.storage.sequence == sequence and game.economy.clock == now, "duplicate suspend pauses live jobs without writing again")
	game.wall_override = now + 140
	game.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	var deposit: HbtAmount = game.economy.offline_pending
	expect(game.suspended_at < 0 and game.campaign.boost.remaining(game.economy.clock) == 160 and not deposit.empty(),
		"resume appends covered offline income and keeps only remaining BOOST time")
	game.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	expect(game.economy.offline_pending.compare(deposit) == 0, "duplicate resume cannot pay twice")
	var backup := HbtCampaign.new(HbtEconomy.new())
	backup.storage.path = save_path
	backup.restore(now + 300)
	expect(not backup.boost.earning(now + 300) and backup.current().offline_pending.compare(deposit) > 0,
		"relaunch after expiry accounts for remaining absence without extending BOOST")

func traffic_load(count: int) -> void:
	var fleet: HbtDispatch = game.traffic.dispatch
	fleet.spawning = false
	for visit: HbtVisit in fleet.live.values():
		fleet.dispose(visit)
	# Independent lanes beyond the visible campus stress the actual route, collision and vehicle code.
	for i in count:
		var client := fleet.demand.customer(game.economy, "local")
		client.model = "pine"
		client.paint = 0
		var visit := fleet.make_visit(client, "fuel")
		visit.location = Vector3(70.0 + (i % 20) * 19.0, 0, 125.0 + floori(i / 20.0) * 14.0)
		visit.yaw = PI * .5
		fleet.route(visit, [visit.location + Vector3(420, 0, 0)], Phase.DEPART)
		fleet.added.emit(visit)
	var initial: int = game.traffic.vehicles.size()
	var began := Time.get_ticks_usec()
	for _frame in 240:
		game.traffic.physics_step(1.0 / 60.0)
	var reached: bool = fleet.live.values().all(func(visit: HbtVisit) -> bool: return visit.distance > .01)
	var milliseconds := (Time.get_ticks_usec() - began) / 1000.0
	expect(initial == count and fleet.live.size() == count and fleet.consistent() and reached, "real movement of %d active routing agents" % count)
	for visit: HbtVisit in fleet.live.values():
		fleet.dispose(visit)
	await process_frame
	expect(game.traffic.vehicles.is_empty() and game.traffic.pooled <= game.traffic.POOL_LIMIT, "bounded pool after releasing %d vehicles" % count)
	print("FLEET %d active · 240 ticks %.2f ms · %d reuse events · %d available" % [count, milliseconds, game.traffic.reused, game.traffic.pooled])
