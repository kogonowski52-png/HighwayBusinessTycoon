extends "res://tests/balance_simulation.gd"
## Same active/return cadence as the published North simulation, starting from a new desert estate.

const DesertRoutes = preload("res://data/world/desert_routes.gd")

func run() -> void:
	for seed in [52, 481, 1227]:
		simulate(seed)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--report="):
			var output := FileAccess.open(argument.trim_prefix("--report="), FileAccess.WRITE)
			expect(output != null, "record desert balance")
			if output != null:
				output.store_string(JSON.stringify(table, "\t") + "\n")
				output.close()
	result("Desert balance")

func simulate(seed: int) -> void:
	run_seed = seed
	economy = HbtEconomy.new("desert")
	economy.clock = WALL
	economy.high_water = WALL
	seconds = 0.0
	first_sale = -1.0
	first_upgrade = -1.0
	had_manager = false
	offline = HbtAmount.new()
	recovered = 0
	departed = 0
	patience_left = 0
	cadence = 0
	opened_at = {"fuel": 0.0}
	begin_session(true)
	var prior := HbtAmount.new()
	for limit in HORIZONS:
		if limit <= 7200:
			active_until(limit)
		else:
			return_until(limit)
		var row := evidence(limit)
		table.append(row)
		print("Desert balance " + JSON.stringify(row))
		expect(economy.gross.compare(prior) > 0 and traffic.consistent(), "progress and valid traffic at %d seconds, seed %d" % [limit, seed])
		prior = economy.gross
		if limit == 300:
			expect(row.sites >= 2 and row.workers >= 1, "first staffed expansion in five minutes")
		elif limit == 1800:
			expect(row.sites >= 5 and row.missions_claimed >= 20, "meaningful specialization in thirty minutes")
		elif limit == 7200:
			expect(row.sites >= 9 and row.best_level >= 20, "most regional services reachable in two hours")
		elif limit == 86400:
			expect(not offline.empty() and row.best_level < 100, "day one gains and upgrade runway")
		elif limit == 604800:
			expect(row.sites == economy.facilities.size() and row.min_level < 100, "all services and room to build in week one")
		elif limit == 2592000:
			expect(row.best_level == 100 and row.min_level >= 90, "month-end progression reaches the endgame")
	expect(first_sale >= 0.0 and first_sale <= 6.0, "first local sale within six seconds")
	expect(first_upgrade >= 0.0 and first_upgrade <= 60.0, "first local upgrade within one minute")
	expect(recovered * 100 <= maxi(1, departed) * 3, "monthly recovery rate at most 3 percent")

func begin_session(first := false) -> void:
	cadence += 1
	traffic = HbtDispatch.new(economy, run_seed + cadence * 67, DesertRoutes)
	if first:
		traffic.seed_station()
