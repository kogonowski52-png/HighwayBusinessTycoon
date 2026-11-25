extends "res://tests/run_checks.gd"
## Copy this test into a real v0.6.0 checkout for --seed, then read the same file in 0.6.1.

const Calendar = preload("res://data/world/expedition_calendar.gd")
const EXPECTED_WALL := Calendar.START + Calendar.WEEK + 3750
const SaveManager = preload("res://scripts/core/save_manager.gd")

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var path := ""
	var seed := false
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--profile="):
			path = argument.trim_prefix("--profile=")
		seed = seed or argument == "--seed"
	if not path.begins_with("/tmp/hbt-migration-"):
		expect(false, "use isolated /tmp/hbt-migration-* profile")
		result("Real 0.6.0 migration")
		return
	var estate := HbtEconomy.new()
	estate.storage.path = path
	var saved := HbtCampaign.new(estate)
	saved.restore(EXPECTED_WALL if seed else EXPECTED_WALL + 720)
	if seed:
		write_previous(saved, path)
	else:
		read_previous(saved, path)
	result("Real 0.6.0 migration")

func write_previous(world: HbtCampaign, path: String) -> void:
	expect(SaveManager.SCHEMA == 6 and world.districts.size() == 1, "fixture made by previous release")
	if failures > 0:
		return
	var north := world.current()
	north.finish_tutorial()
	north.credit("cash", HbtAmount.from(59_300))
	north.credit("reputation", HbtAmount.from(21))
	north.buy_levels("fuel", 10)
	north.hire("fuel")
	north.train("fuel", 0)
	north.language = "en"
	north.preferences.volumes.music = .31
	north.preferences.weather = "rain"
	north.preferences.auto_day = true
	north.cards.ada = true
	north.cards.iga = true
	north.assign("ada")
	north.claim_calendar()
	expect(world.travel("desert") == OK, "actual 0.6.0 world opens Desert Highway")
	var desert := world.current()
	desert.credit("cash", HbtAmount.from(19_750))
	desert.credit("reputation", HbtAmount.from(37))
	desert.buy_levels("fuel", 10)
	desert.hire("fuel")
	desert.train("fuel", 0)
	desert.unlock("cafe")
	desert.hire("cafe")
	desert.assign("iga")
	desert.serve("fuel", desert.price("fuel"), 1, 0)
	desert.claim_reward("desert_start")
	world.ledger.accept(desert, "turnover")
	world.ledger.increment(desert, {"turnover": 850})
	world.ledger.seen_vehicles["kestrel"] = true
	world.ledger.cosmetics["beacon"] = true
	world.ledger.chosen["desert"] = {"facades": "beacon"}
	desert.clock += 720
	expect(world.travel("north") == OK and not north.offline_pending.empty(), "previous North has payable absence")
	expect(world.travel("desert") == OK and world.checkpoint() == OK, "previous release writes an active two-estate save")
	var expected := FileAccess.open(path + ".expected.json", FileAccess.WRITE)
	expect(expected != null, "write comparison data")
	if expected != null:
		expected.store_string(canonical_profile(world))
		expected.close()

func read_previous(world: HbtCampaign, path: String) -> void:
	var original: Dictionary = world.storage.read_candidate(path)
	expect(original.get("schema") == 6 and world.active == "desert", "actual previous schema and district detected")
	var expected := FileAccess.get_file_as_string(path + ".expected.json")
	if canonical_profile(world) != expected:
		var comparison := FileAccess.open(path + ".actual.json", FileAccess.WRITE)
		if comparison != null:
			comparison.store_string(canonical_profile(world))
			comparison.close()
	expect(world.districts.size() == 2 and canonical_profile(world) == expected, "original balances, halls, staff, cards, calendar, missions, settings and contracts preserved")
	expect(world.checkpoint() == OK and world.storage.read_candidate(path).schema == SaveManager.SCHEMA,
		"upgrades envelope atomically while preserving old data")
	var reopened := HbtCampaign.new(HbtEconomy.new())
	reopened.storage.path = path
	reopened.restore(EXPECTED_WALL + 720)
	expect(canonical_profile(reopened) == expected and reopened.active == "desert", "snapshot migration survives same-clock reload")
	expect(reopened.travel("north") == OK, "migrated game returns to original district")
	var north := reopened.current()
	var pending := north.offline_pending
	expect(not pending.empty() and north.redeem_offline().compare(pending) == 0 and north.redeem_offline().empty(),
		"pre-existing offline payment remains redeemable exactly once")

func canonical_profile(world: HbtCampaign) -> String:
	var details := {"active": world.active, "contracts": world.ledger.contracts,
		"calendar": world.ledger.event_totals, "seen": world.ledger.seen_vehicles, "chosen": world.ledger.chosen,
		"cosmetics": world.ledger.cosmetics}
	for id in ["north", "desert"]:
		if not world.districts.has(id):
			continue
		var estate: HbtEconomy = world.districts[id]
		var slot := estate.snapshot()
		slot.manager_ranks = slot.manager_ranks.duplicate()
		for id_card in estate.cards:
			slot.manager_ranks[id_card] = estate.manager_rank(id_card)
		if int(slot.boost_until) <= estate.clock:
			slot.boost_until = 0
		for excluded in ["world", "commerce"]:
			slot.erase(excluded)
		var structural: Variant = JSON.parse_string(JSON.stringify(slot))
		details[id] = structural
	return JSON.stringify(JSON.parse_string(JSON.stringify(details)), "\t")
