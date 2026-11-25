extends "res://tests/balance_simulation.gd"
## Run a new free campaign without fixture grants or list-of-business shortcuts.

const Atlas = preload("res://data/world/atlas.gd")
const DesertRoutes = preload("res://data/world/desert_routes.gd")
const RegionalRoutes = preload("res://data/world/regional_routes.gd")
const DistrictOrder := ["north", "desert", "valley", "alpine", "ocean", "metro"]

var campaign: HbtCampaign
var save_path := ""
var openings := {}
var return_cursor := 0
var cash_from_absence: Dictionary
var recovery_counts: Dictionary
var last_sale: Dictionary

func run() -> void:
	for seed in [41, 612, 7283]:
		simulate(seed)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--report="):
			var output := FileAccess.open(argument.trim_prefix("--report="), FileAccess.WRITE)
			expect(output != null, "write evidence")
			if output != null:
				output.store_string(JSON.stringify(table, "\t") + "\n")
				output.close()
	result("Free campaign balance")

func simulate(seed: int) -> void:
	run_seed = seed
	seconds = 0
	first_sale = -1
	first_upgrade = -1
	offline = HbtAmount.new()
	recovered = 0
	departed = 0
	patience_left = 0
	cadence = 0
	return_cursor = 0
	openings = {"north": 0}
	opened_at = {"fuel": 0}
	last_sale = {}
	cash_from_absence = {}
	recovery_counts = {}
	economy = HbtEconomy.new()
	save_path = "/tmp/hbt-campaign-balance-%d-%d.cfg" % [OS.get_process_id(), seed]
	economy.storage.path = save_path
	campaign = HbtCampaign.new(economy)
	campaign.restore(WALL)
	begin_session(true)
	var last_gross := HbtAmount.new()
	for horizon in HORIZONS:
		if horizon <= 7200:
			active_until(horizon)
		else:
			check_in_until(horizon)
		var row := campaign_evidence(horizon)
		table.append(row)
		print("Campaign balance " + JSON.stringify(row))
		var gross := HbtAmount.from(row.gross)
		expect(gross.compare(last_gross) > 0 and traffic.consistent(), "new turnover and valid dispatch at each horizon")
		last_gross = gross
		match horizon:
			300: expect(campaign.districts.has("desert"), "new arrivals can afford the first free expansion in five minutes")
			1800: expect(campaign.districts.size() >= 2 and row.sites >= 7 and row.workers >= 5,
				"steady free expansion and multiple staffed businesses within thirty minutes")
			7200: expect(campaign.districts.size() >= 4 and not campaign.prestige_ready(), "campaign opens additional branches without exhausting the cap")
			86400: expect(not offline.empty() and campaign.current().metric("staff") >= 1, "first day gains include independent offline revenue")
			604800: expect(campaign.districts.size() == 6 and row.sites >= 31, "open all districts with free progression within seven days")
			2592000:
				expect(row.sites == total_businesses() and row.managers >= 7 and row.missions >= 200,
					"month-end visits grow staffed businesses, managers and mission rewards")
				expect(row.levels >= 1850 and row.levels < total_businesses() * 100, "long-term upgrading runway remains after thirty days")
				expect(row.recoveries * 100 <= maxi(1, row.departures) * 3, "traffic recovery remains below 3% in a new campaign")
	expect(first_sale > 0 and first_sale <= 5.0 and first_upgrade > 0 and first_upgrade <= 60.0,
		"first earnings and upgrade retain 0.6.0 timings")
	clean_save(save_path)

func total_businesses() -> int:
	var count := 0
	for id in DistrictOrder:
		var estate: HbtEconomy = campaign.districts.get(id)
		if estate == null:
			estate = HbtEconomy.new(id)
		count += estate.facilities.size()
	return count

func begin_session(first := false) -> void:
	cadence += 1
	var routes: Object
	match economy.district:
		"north": routes = HbtDispatch.Routes
		"desert": routes = DesertRoutes
		_: routes = RegionalRoutes.new(economy.district)
	traffic = HbtDispatch.new(economy, run_seed + cadence * 67, routes)
	traffic.completed.connect(func(ticket: HbtVisit) -> void:
		campaign.ledger.visit(economy, ticket)
		last_sale[economy.district] = seconds)
	if first:
		traffic.seed_station()

func release_session() -> void:
	departed += traffic.departed
	recovered += traffic.recovered
	recovery_counts[economy.district] = int(recovery_counts.get(economy.district, 0)) + traffic.recovered
	# The real world scene discards its in-flight reservations on departure.
	economy.commerce.reservations.clear()

func checked_travel(id: String, stage: bool) -> void:
	if not campaign.available(id) or campaign.travel(id) != OK:
		return
	release_session()
	economy = campaign.current()
	if stage:
		openings[id] = seconds
		opened_at = {"fuel": seconds}
	cash_out()
	begin_session(stage)

func invest() -> void:
	var next_index := campaign.districts.size()
	if next_index < DistrictOrder.size() and campaign.available(DistrictOrder[next_index]):
		checked_travel(DistrictOrder[next_index], true)
		return
	# The stock simulation uses the same purchase rules and selects regional directors
	# only after their actual mission has delivered the cards.
	for id in economy.milestones:
		economy.claim_reward(id.id)
	if economy.Regions.has_region(economy.district):
		var manager: String = economy.Regions.ECONOMICS[economy.district][6]
		if economy.cards.has(manager) and manager not in economy.equipped:
			economy.assign(manager)
	super.invest()

func cash_out() -> void:
	var amount := economy.redeem_offline()
	var prior: HbtAmount = cash_from_absence.get(economy.district, HbtAmount.new())
	cash_from_absence[economy.district] = prior.plus(amount)
	offline = offline.plus(amount)

func check_in_until(horizon: int) -> void:
	while seconds < horizon:
		release_session()
		economy.high_water = economy.clock
		seconds = float(mini(horizon, int(seconds) + 28_440))
		economy.capture_absence(WALL + int(seconds))
		cash_out()
		begin_session()
		if campaign.districts.size() == DistrictOrder.size():
			var target: String = DistrictOrder[return_cursor % DistrictOrder.size()]
			return_cursor += 1
			if target != economy.district:
				checked_travel(target, false)
		for i in 28:
			invest()
		active_until(mini(horizon, int(seconds) + 360))

func campaign_evidence(horizon: int) -> Dictionary:
	var sites := 0
	var levels := 0
	var customers := 0
	var workers := 0
	var tasks := 0
	var gross := HbtAmount.new()
	var overview := {}
	for id in DistrictOrder:
		if not campaign.districts.has(id):
			continue
		var estate: HbtEconomy = campaign.districts[id]
		sites += estate.metric("locations")
		workers += estate.metric("staff")
		customers += estate.customers
		tasks += estate.claimed.size()
		gross = gross.plus(estate.gross)
		for tier in estate.levels.values():
			levels += int(tier)
		var earned: HbtAmount = cash_from_absence.get(id, HbtAmount.new())
		overview[id] = {"open_s": openings[id], "sites": estate.metric("locations"), "fuel": estate.level("fuel"),
			"reputation": estate.metric("reputation"), "workers": estate.metric("staff"), "visits": estate.customers,
			"best_level": estate.metric("best_level"), "offline": earned.decimal(), "recoveries": recovery_counts.get(id, 0),
			"cash": estate.amount("cash").decimal(), "earned": estate.gross.decimal(), "last_served_s": last_sale.get(id, 0)}
	return {"seed": run_seed, "horizon_s": horizon, "districts": campaign.districts.size(), "sites": sites, "levels": levels,
		"visits": customers, "workers": workers, "missions": tasks, "managers": economy.cards.size(), "gross": gross.decimal(),
		"offline_total": offline.decimal(), "recoveries": recovered + traffic.recovered, "departures": departed + traffic.departed,
		"first_sale_s": first_sale, "first_upgrade_s": first_upgrade, "progress": overview}
