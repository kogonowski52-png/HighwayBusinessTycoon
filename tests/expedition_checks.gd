extends "res://tests/run_checks.gd"

const Calendar = preload("res://data/world/expedition_calendar.gd")
const Routes = preload("res://data/world/desert_routes.gd")
const Ledger = preload("res://scripts/expansion/ledger.gd")
const WALL := Calendar.START + 2 * Calendar.DAY

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	await process_frame
	exercise_campaign()
	exercise_weathered_routes()
	exercise_programs()
	result("World expansion, accounting and special programs")

func exercise_campaign() -> void:
	var north := HbtEconomy.new()
	var path := "/tmp/hbt-campaign-%d.cfg" % OS.get_process_id()
	north.storage.path = path
	var world := HbtCampaign.new(north)
	world.restore(WALL)
	expect(not world.available("desert") and not world.available("alpine"), "desert gate and unavailable districts")
	north.credit("cash", HbtAmount.from(6000))
	north.credit("reputation", HbtAmount.from(14))
	north.buy_levels("fuel", 4)
	north.hire("fuel")
	north.language = "en"
	north.preferences.volumes.music = .38
	north.cards.ada = true
	north.assign("ada")
	var saved_wallet := north.amount("cash").minus(HbtAmount.from(670))
	var quote := north.offline_quote(1800)
	expect(world.travel("desert") == OK and world.active == "desert" and north.amount("cash").compare(saved_wallet) == 0,
		"one disclosed travel investment opens the second ledger")
	var desert := world.current()
	expect(not desert.equipped.has("ada") and desert.cards.has("ada") and desert.preferences == north.preferences
		and desert.amount("cash").decimal() == "190" and desert.level("fuel") == 1, "location autonomy and shared collection/settings")
	expect(north.missions.size() + desert.missions.size() == 270, "270 functional chapter missions")
	desert.hire("fuel")
	desert.clock += 1800
	expect(world.travel("north") == OK and not quote.empty() and north.offline_pending.compare(quote) == 0
		and desert.offline_pending.empty(), "only inactive estate earns while the other is active")
	expect(world.travel("desert") == OK and world.travel("north") == OK
		and north.offline_pending.compare(quote) == 0 and desert.offline_pending.empty(), "consecutive travel does not repeat credit")
	expect(world.checkpoint() == OK, "atomic two-estate save")
	var copy := HbtEconomy.new()
	copy.storage.path = path
	var reopened := HbtCampaign.new(copy)
	reopened.restore(WALL + 1800)
	expect(copy.storage.read_candidate(path).schema == HbtEconomy.SaveManager.SCHEMA and reopened.active == "north"
		and reopened.districts.desert.crew.fuel.size() == 1 and reopened.districts.desert.level("fuel") == 1
		and copy.language == "en" and copy.preferences.volumes.music == .38 and copy.offline_pending.compare(quote) == 0,
		"restart restores both estates, settings, active district and exact offline reward")
	expect(copy.redeem_offline().compare(quote) == 0 and copy.redeem_offline().empty(), "offline reward remains single-use")
	var before_failure := copy.amount("cash")
	reopened.storage.path = path + "/missing"
	expect(reopened.travel("desert") != OK and reopened.active == "north" and copy.amount("cash").compare(before_failure) == 0,
		"failed write rolls back district selection and fees")
	reopened.storage.path = path
	expect(not reopened.prestige_ready() and reopened.prestige(true) != OK, "prestige requires max development")
	for id in copy.facilities:
		copy.levels[id] = 100
	expect(reopened.prestige_ready() and reopened.prestige(false) != OK and copy.level("fuel") == 100,
		"prestige preserves existing business without explicit confirmation")
	expect(reopened.prestige(true) == OK, "confirmed prestige persists atomically")
	var reopened_north := reopened.current()
	var fresh := HbtEconomy.new()
	expect(reopened_north.level("fuel") == 1 and reopened_north.crew.fuel.is_empty() and reopened_north.cards.has("ada")
		and reopened.ledger.prestige_points == 1 and reopened.ledger.cosmetics.has("beacon")
		and reopened.districts.desert.crew.fuel.size() == 1
		and reopened_north.payout("fuel", 100, -1).compare(fresh.payout("fuel", 100, -1)) > 0, "prestige reset, preserved collection and actual payout bonus")
	clean_save(path)

func exercise_weathered_routes() -> void:
	var desert := HbtEconomy.new("desert")
	desert.clock = WALL
	for id in desert.facilities:
		desert.levels[id] = 100
		desert.crew[id] = [{"xp": 3, "training": 2, "rank": 1}, {"xp": 3, "training": 2, "rank": 1}]
		var traffic := HbtDispatch.new(desert, 809 + desert.facilities.keys().find(id), Routes)
		traffic.spawning = false
		var visitor := "trucker" if Routes.is_truck(id) else "electric" if id == "charge" else "vip" if id == "vip_park" else "local"
		var ticket := traffic.try_admit(visitor, id)
		var working := false
		for frame in 1050:
			traffic.tick(.10)
			working = working or (ticket != null and ticket.phase == HbtVisit.Phase.WORKING and ticket.worker >= 0)
			if traffic.live.is_empty():
				break
		expect(ticket != null and ticket.paid and working and traffic.consistent() and traffic.live.is_empty()
			and traffic.departed == 1 and traffic.recovered == 0, "complete staffed route and exit for " + id)
		desert.per_service[id] = {"count": 100, "gross": HbtAmount.from(100_000)}
	desert.player_xp = 12200
	var missions := 0
	for id in desert.missions:
		if desert.claim_reward(id) and not desert.claim_reward(id):
			missions += 1
	expect(missions == 160, "all local missions can advance, pay and stay paid")
	var mixed := HbtDispatch.new(desert, 157, Routes)
	for frame in 9000:
		desert.clock = WALL + int(frame * .15)
		mixed.tick(.15)
	expect(mixed.consistent() and mixed.departed > 35 and mixed.recovered <= maxi(1, mixed.departed / 20),
		"mixed desert traffic stress, independent lanes and recovery bound")
	print("Desert traffic: %d departed, %d recovered, queue peak %d" % [mixed.departed, mixed.recovered, mixed.peak_queue])

func exercise_programs() -> void:
	var store := HbtEconomy.new()
	store.clock = Calendar.START
	for id in store.facilities:
		store.levels[id] = 10
	store.credit("reputation", HbtAmount.from(105))
	var ledger := Ledger.new()
	for index in Calendar.SEASONS.size():
		store.clock = Calendar.START + index * Calendar.WEEK + 150
		ledger.advance(store.clock)
		var event := ledger.season()
		expect(event.live and event.index == index and event.id == Calendar.SEASONS[index].id, "configured event " + event.id)
		var activities := {}
		for rule in event.tasks:
			activities[rule[0]] = rule[1]
		ledger.increment(store, activities)
		expect(ledger.claim_event(store) and not ledger.claim_event(store) and ledger.cosmetics.has(event.id), "unique points and themed prize " + event.id)
		ledger.advance(store.clock - Calendar.WEEK)
		expect(ledger.season().index == index and ledger.paid_event(), "clock rollback never repeats a prize")
	expect(ledger.finished_events.size() == mini(8, Calendar.SEASONS.size() - 1), "event archive keeps previous summaries")
	store.clock += Calendar.WEEK
	ledger.advance(store.clock)
	for rule in Calendar.CONTRACTS:
		expect(ledger.accept(store, rule.id) and not ledger.accept(store, rule.id), "unique contract acceptance " + rule.id)
		ledger.increment(store, {rule.id: rule.goal})
		var key := ledger.id_for("north", rule.id)
		expect(ledger.claim_contract(store, key) and not ledger.claim_contract(store, key), "contract pays once " + rule.id)
	store.clock += Calendar.DAY
	ledger.advance(store.clock)
	expect(ledger.accept(store, "liters"), "new UTC day offers another fuel contract")
	var expired := ledger.id_for("north", "liters")
	store.clock += 601
	ledger.increment(store, {"liters": 1000})
	expect(not ledger.contracts[expired].done and not ledger.claim_contract(store, expired), "no progress after expiry")
	var spot := HbtVisit.new()
	spot.paid = true
	spot.service = "truck"
	spot.invoice = HbtAmount.from(347)
	spot.client = {"model": "atlas", "kind": "truck", "type": "trucker"}
	ledger.visit(store, spot)
	spot.client.model = "cargo"
	ledger.visit(store, spot)
	expect(ledger.collected(store, "trucks") == 2 and ledger.set_reward(store, "trucks") and not ledger.set_reward(store, "trucks"), "actual vehicles complete a rewarded set")
	expect(ledger.select_cosmetic(store, "signs", "sport") and ledger.chosen.north.signs == "sport", "owned collectible is equipable")
	var past := Ledger.new()
	past.restore(ledger.snapshot().duplicate(true))
	expect(past.owned(store, "trucks", "atlas") and past.prizes.trucks and past.chosen.north.signs == "sport",
		"event, contract and collection ledger survives serialization")
