extends "res://tests/run_checks.gd"

const Book = preload("res://data/economy/progression.gd")
const Managers = preload("res://data/economy/managers.gd")
const Routes = preload("res://data/economy/routes.gd")
const WALL := 1_789_000_000

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	chapters_and_cards()
	managed_visit()
	save_previous_release()
	result("Career, specialists and migration")

func chapters_and_cards() -> void:
	var store := HbtEconomy.new()
	store.clock = WALL
	store.high_water = WALL
	expect(store.missions.size() == 110 and store.chapters.size() == 11, "110 executable missions across 11 chapters")
	expect(not store.claim_reward("route_fuel_specialist") and not store.claim_reward("route_charge_open"),
		"mission series and player-level prerequisites are enforced")
	expect(store.claim_reward("route_fuel_open") and not store.claim_reward("route_fuel_open"), "a chapter reward is single-use")
	expect(not store.buy_offline_limit() and store.offline_limit() == 7_200, "fresh offline plan is two hours")
	store.credit("cash", HbtAmount.from("1000000000000000000000000"))
	store.credit("reputation", HbtAmount.from(150))
	for id in store.facilities:
		if id != "fuel":
			expect(store.unlock(id), id + " opens with earned currency and prerequisites")
		store.buy_levels(id, 0)
		store.hire(id)
		store.train(id, 0)
		store.train(id, 0)
		for service in range(31):
			store.serve(id, store.payout(id, 100, 0), 1, 0)
		expect(store.promote(id, 0), id + " employee gains a real promotion from training and experience")
	for item in Book.MILESTONES:
		expect(store.claim_reward(item.id), "original objective remains claimable: " + item.id)
	expect(store.exchange(true), "event exchange retains Mira")
	var reward := store.player_reward()
	var diamonds := store.amount("diamond")
	expect(store.claim_player_reward() and not store.claim_player_reward()
		and store.amount("diamond").compare(diamonds.plus(HbtAmount.from(reward.diamond))) == 0, "earned player-level payouts")
	for wave in range(2):
		for item in store.missions.values():
			if item.wave == wave and item.id != "route_fuel_open":
				expect(store.claim_reward(item.id), "claim " + item.id)
	expect(store.cards.size() == 15, "all 15 cards are obtainable through objectives and events")
	for id in Book.MANAGERS:
		expect(ResourceLoader.exists("res://assets/ui/managers/%s.png" % id)
			and ResourceLoader.exists("res://assets/models/characters/%s.glb" % id), "portrait and world rig exist for " + id)
	var early := store.payout("market", 100, -1)
	expect(store.assign("nina") and store.payout("market", 100, -1).compare(early) > 0
		and store.payout("parking", 100, -1).compare(store.price("parking")) == 0, "the specialist changes only the designated venue")
	for id in ["ada", "nina"]:
		for rank in range(2, 6):
			var before := store.amount("diamond")
			var quote := store.manager_training(id)
			expect(store.train_manager(id) and store.manager_rank(id) == rank
				and store.amount("diamond").compare(before.minus(HbtAmount.from(quote.cost))) == 0, "paid manager training %s/%d" % [id, rank])
		expect(not store.train_manager(id), "highest rank cannot be bought twice")
	expect(store.payout("market", 100, -1).compare(early.times(12).divided(10)) > 0, "manager development strengthens skill")
	for wave in [2, 3]:
		for item in store.missions.values():
			if item.wave == wave:
				expect(store.claim_reward(item.id), "claim advanced mission " + item.id)
	expect(store.claimed.size() == 120, "all 110 chapter missions and 10 original objectives can be completed")
	for hours in [4, 6, 8, 10, 12]:
		expect(store.buy_offline_limit() and store.offline_limit() == hours * 3600, "offline tier reaches %d hours" % hours)
	expect(not store.buy_offline_limit(), "12 hours is the highest tier")
	var planned := store.offline_quote(3600)
	expect(store.assign("vera") and store.offline_quote(3600).compare(planned) > 0, "Vera enhances actual offline payments")
	store.capture_absence(WALL + 80000)
	var path := "/tmp/hbt-career-%d.cfg" % OS.get_process_id()
	store.storage.path = path
	expect(store.checkpoint() == OK and store.offline_seconds == 43_200, "extended plan is bounded at 12 hours")
	var reopened := HbtEconomy.new()
	reopened.storage.path = path
	reopened.restore(store.clock)
	expect(reopened.levels == store.levels and reopened.crew == store.crew and reopened.claimed == store.claimed
		and reopened.cards == store.cards and reopened.equipped == store.equipped and reopened.player_level() == store.player_level()
		and reopened.paid_player_level == store.paid_player_level and reopened.offline_limit() == 43_200 and reopened.manager_rank("ada") == 5
		and reopened.offline_pending.compare(store.offline_pending) == 0, "full save restores staff, manager ranks, missions, venues and pending payout")
	expect(not reopened.redeem_offline().empty() and reopened.checkpoint() == OK, "offline redemption checkpoint writes")
	reopened.restore(store.clock)
	expect(reopened.redeem_offline().empty(), "collected offline payout cannot repeat across launch")
	clean_save(path)

func managed_visit() -> void:
	var store := HbtEconomy.new()
	store.clock = WALL
	store.levels.charge = 1
	store.cards.jo = true
	expect(store.assign("jo") and not store.offline_quote(7200).empty(), "automation manager can generate offline income without staff")
	var flow := HbtDispatch.new(store, 9147)
	flow.spawning = false
	expect(flow.try_admit("local", "charge") == null and flow.try_admit("electric", "fuel") == null,
		"the EV service accepts only compatible vehicles and EVs cannot refuel")
	var visit := flow.try_admit("electric", "charge")
	var arrived := false
	var walking_back := false
	var stopped_for_guest := true
	for frame in range(1350):
		flow.tick(0.05)
		if visit.phase == HbtVisit.Phase.WORKING:
			arrived = arrived or visit.walked >= visit.foot_length
		if visit.phase == HbtVisit.Phase.EXIT_WAIT and visit.walked > 0.01:
			walking_back = true
			stopped_for_guest = stopped_for_guest and visit.location.is_equal_approx(Routes.position_of("charge", 0))
		if not flow.live.has(visit.number):
			break
	expect(visit.worker == store.MANAGER_WORKER and visit.director == "jo" and visit.paid and store.crew.charge.is_empty()
		and not store.registers.charge.empty(), "equipped specialist runs an actual unstaffed charging visit")
	expect(arrived and walking_back and stopped_for_guest and flow.live.is_empty() and flow.consistent(),
		"driver walks to the charger and returns before the vehicle is released")

func save_previous_release() -> void:
	var path := "/tmp/hbt-schema3-%d.cfg" % OS.get_process_id()
	var old := {"wallet": {"cash": "358202", "diamond": "11", "reputation": "87", "event": "4"},
		"levels": {"fuel": 15, "market": 2, "workshop": 1}, "registers": {"market": "440"}, "customers": 51,
		"crew": {"fuel": [{"xp": 29, "training": 3, "rank": 2}]}, "cards": {"ada": true}, "equipped": ["ada"],
		"claimed": {"crew": true}, "offline_pending": "1450", "offline_seconds": 1800, "high_water": WALL,
		"language": "en", "low_power": true}
	var payload := JSON.stringify(old)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema": 3, "sequence": 5, "sha256": payload.sha256_text(), "payload": payload}))
	file.close()
	var store := HbtEconomy.new()
	store.storage.path = path
	store.restore(WALL)
	expect(store.amount("cash").decimal() == "358202" and store.amount("diamond").decimal() == "11"
		and store.level("fuel") == 15 and store.level("charge") == 0 and store.crew.fuel[0].rank == 2
		and store.registers.market.decimal() == "440" and store.cards.has("ada") and store.manager_rank("ada") == 1
		and store.claimed.has("crew") and store.player_level() > 1 and store.tutorial_step == store.TUTORIAL_DONE
		and store.offline_limit() == 28_800 and store.offline_pending.decimal() == "1450",
		"0.3.2 profile keeps balances, prior eight-hour cap, inventory, settings and uncollected payment")
	expect(store.checkpoint() == OK and store.storage.read_candidate(path).schema == 4, "previous schema migrates atomically")
	clean_save(path)
