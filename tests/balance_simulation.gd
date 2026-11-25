extends "res://tests/run_checks.gd"

const WALL := 1_789_000_000
const HORIZONS := [300, 1800, 7200, 86400, 604800, 2592000]
const STEP := 0.25

var economy: HbtEconomy
var traffic: HbtDispatch
var seconds := 0.0
var first_sale := -1.0
var first_upgrade := -1.0
var had_manager := false
var offline := HbtAmount.new()
var recovered := 0
var departed := 0
var patience_left := 0
var table: Array[Dictionary] = []
var cadence := 0
var run_seed := 0
var opened_at: Dictionary

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	for seed in [41, 612, 7283]:
		simulate(seed)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--report="):
			var destination := FileAccess.open(argument.trim_prefix("--report="), FileAccess.WRITE)
			expect(destination != null, "open balance report")
			if destination != null:
				destination.store_string(JSON.stringify(table, "\t") + "\n")
				destination.close()
	result("Balance regression")

func simulate(seed: int) -> void:
	run_seed = seed
	economy = HbtEconomy.new()
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
	var prior_gross := HbtAmount.new()
	var previous_open := 1
	for limit in HORIZONS:
		if limit <= 7200:
			active_until(limit)
		else:
			return_until(limit)
		var row := evidence(limit)
		table.append(row)
		print("Balance %s" % JSON.stringify(row))
		expect(economy.gross.compare(prior_gross) > 0 and row.sites >= previous_open and traffic.consistent(),
			"seed %d, %ds: positive growth and consistent reservations" % [seed, limit])
		prior_gross = economy.gross
		previous_open = row.sites
		if limit == 300:
			expect(row.sites >= 3 and row.workers >= 2, "seed %d: 5 min unlocks and starts automation" % seed)
		elif limit == 1800:
			expect(row.sites >= 6 and had_manager, "seed %d: 30 min expands and acquires a manager" % seed)
		elif limit == 7200:
			expect(row.sites == economy.facilities.size() and row.best_level >= 20, "seed %d: 2 h opens all services" % seed)
		elif limit == 86400:
			expect(row.best_level >= 40 and row.best_level < 100 and not offline.empty(), "seed %d: day-one progress includes offline earnings and stays below cap" % seed)
		elif limit == 604800:
			expect(row.best_level >= 75 and row.workers >= 16 and row.min_level < 100, "seed %d: first week develops capacity and leaves room to grow" % seed)
		elif limit == 2592000:
			expect(row.best_level == 100 and row.min_level >= 95, "seed %d: all free branches approach the cap" % seed)
	expect(first_sale >= 0.0 and first_sale <= 5.0, "seed %d first income by 5s" % seed)
	expect(first_upgrade >= 0.0 and first_upgrade <= 60.0, "seed %d first upgrade by one minute" % seed)
	expect(recovered * 100 <= maxi(1, departed) * 3, "seed %d recovery rate <= 3%%" % seed)

func begin_session(first := false) -> void:
	cadence += 1
	traffic = HbtDispatch.new(economy, run_seed + cadence * 67)
	if first:
		traffic.seed_station()

func active_until(limit: int) -> void:
	while seconds < limit:
		seconds += STEP
		economy.clock = WALL + int(seconds)
		for id in economy.facilities:
			if economy.crew[id].is_empty() and economy.skill("automation", id) == 0:
				traffic.start_manual(id)
		traffic.tick(STEP)
		if first_sale < 0.0 and economy.customers > 0:
			first_sale = seconds
		if roundi(seconds / STEP) % 8 == 1:
			invest()
			if first_upgrade < 0.0 and economy.level("fuel") >= 2:
				first_upgrade = seconds

func return_until(limit: int) -> void:
	while seconds < limit:
		recovered += traffic.recovered
		departed += traffic.departed
		patience_left += traffic.abandoned
		economy.high_water = economy.clock
		# Three six-minute check-ins per day, with a final check-in at each reporting horizon.
		seconds = float(mini(limit, int(seconds) + 28_440))
		offline = offline.plus(economy.capture_absence(WALL + int(seconds)))
		economy.redeem_offline()
		begin_session()
		for i in range(36):
			invest()
		active_until(mini(limit, int(seconds) + 360))

func invest() -> void:
	economy.collect()
	if economy.level("fuel") == 1:
		if economy.buy_levels("fuel", 1) == 0:
			return
	for milestone in economy.milestones:
		economy.claim_reward(milestone.id)
	economy.claim_player_reward()
	for mission in economy.missions:
		if not economy.claimed.has(mission):
			economy.claim_reward(mission)
	economy.claim_daily()
	if economy.cards.has("ada") and not "ada" in economy.equipped:
		had_manager = economy.assign("ada")
	for id in ["iga", "leon"]:
		if economy.cards.has(id) and not id in economy.equipped:
			economy.assign(id)
	if not economy.cards.has("mira"):
		economy.exchange(true)
	for id in economy.facilities:
		var facility: HbtService = economy.facilities[id]
		if economy.gate_open(id) and economy.unlock(id):
			opened_at[id] = seconds
			economy.hire(id)
			return
		if economy.level(id) > 0 and economy.crew[id].size() < economy.capacity(id):
			if economy.hire(id):
				return
		if economy.level(id) == 0 and economy.metric("reputation") >= facility.reputation_gate \
			and economy.level(facility.prerequisite) > 0 and economy.level(facility.prerequisite) < facility.prerequisite_level:
			if economy.buy_levels(facility.prerequisite, 1) > 0:
				return
	if economy.metric("locations") >= 6 and economy.buy_offline_limit():
		return
	if economy.cards.has("ada") and economy.manager_rank("ada") < 3:
		economy.train_manager("ada")
	if economy.metric("locations") >= 4:
		for id in economy.facilities:
			for index in range(economy.crew[id].size()):
				var staff: Dictionary = economy.crew[id][index]
				if staff.xp >= 13 and staff.training < 2 and economy.train(id, index):
					return
				if economy.promote(id, index):
					return
	var lowest_id := ""
	var lowest := 101
	for id in economy.facilities:
		var level := economy.level(id)
		if level > 0 and level < 100 and level < lowest and economy.quote_upgrade(id, 1).affordable:
			lowest = level
			lowest_id = id
	if not lowest_id.is_empty():
		var amount := 10 if lowest >= 35 and economy.metric("locations") == economy.facilities.size() \
			and economy.quote_upgrade(lowest_id, 10).affordable else 1
		economy.buy_levels(lowest_id, amount)

func evidence(horizon: int) -> Dictionary:
	var minimum := 100
	for id in economy.facilities:
		minimum = mini(minimum, economy.level(id))
	return {
		"seed": run_seed, "seconds": horizon, "first_sale_s": first_sale, "first_upgrade_s": first_upgrade,
		"sites": economy.metric("locations"), "workers": economy.metric("staff"),
		"best_level": economy.metric("best_level"), "min_level": minimum,
		"fuel_level": economy.level("fuel"), "customers": economy.customers,
		"reputation": economy.amount("reputation").decimal(), "cash": economy.amount("cash").decimal(),
		"gross": economy.gross.decimal(), "offline_earned": offline.decimal(),
		"invested": economy.spent.decimal(), "minute_income": economy.income_per_minute().decimal(),
		"opening_times_s": opened_at.duplicate(), "player_level": economy.player_level(),
		"missions_claimed": economy.claimed.size(), "manager_cards": economy.cards.size(), "offline_limit_h": economy.CONFIG.offline_hours[economy.offline_tier],
		"patience_exits": patience_left + traffic.abandoned, "recoveries": recovered + traffic.recovered,
		"manager": had_manager,
	}
