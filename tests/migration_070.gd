extends "res://tests/run_checks.gd"

const Atlas = preload("res://data/world/atlas.gd")
const Calendar = preload("res://data/world/expedition_calendar.gd")
const AT := Calendar.START + Calendar.WEEK * 4 + 500
const FIXTURE_RECEIPT := "fixture-only-stage7-test"
var path: String
var source_version := "0.7.0"

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--profile="):
			path = arg.get_slice("=", 1)
		elif arg.begins_with("--original="):
			source_version = arg.get_slice("=", 1)
	if not path.begins_with("/tmp/hbt-070-migration-"):
		expect(false, "isolated fixture path is required")
		result("0.7.0 migration")
		return
	var original := saved_at(AT)
	if "--seed" in OS.get_cmdline_user_args():
		write_original(original)
	else:
		reload(original)
	result(source_version + " migration")

func saved_at(time: int) -> HbtCampaign:
	var world := HbtCampaign.new(HbtEconomy.new())
	world.storage.path = path
	world.restore(time)
	return world

func write_original(world: HbtCampaign) -> void:
	expect(ProjectSettings.get_setting("application/config/version") == source_version, "run the seed on the original release")
	if failures > 0:
		return
	for region: String in Atlas.DESTINATIONS:
		if region != "north":
			expect(world.travel(region) == OK, "actually opened " + region)
		var estate := world.current()
		estate.credit("cash", HbtAmount.from("195456792000000075000"))
		estate.credit("reputation", HbtAmount.from(180))
		estate.finish_tutorial()
		estate.buy_levels("fuel", 25)
		estate.hire("fuel")
		estate.train("fuel", 0)
		for side: String in estate.facilities:
			if side != "fuel" and estate.unlock(side):
				estate.buy_levels(side, 25)
				estate.hire(side)
		estate.cards.ada = true
		estate.serve("fuel", HbtAmount.from(10750), 1, 0)
		world.ledger.increment(estate, {"turnover": 10750})
	world.current().preferences.quality = 1
	world.current().preferences.fps = 30
	world.boost.extend_confirmed(AT)
	world.premium.grants[FIXTURE_RECEIPT] = true
	world.premium.entitlements.remove_ads = true
	expect(world.checkpoint() == OK, "original saves all six districts and campaign variables")
	var report := FileAccess.open(path + ".expected", FileAccess.WRITE)
	report.store_string(snapshot(saved_at(AT)))

func reload(world: HbtCampaign) -> void:
	var prior := FileAccess.get_file_as_string(path + ".expected")
	if prior != snapshot(world):
		var actual := FileAccess.open(path + ".actual", FileAccess.WRITE)
		actual.store_string(snapshot(world))
	expect(world.districts.size() == 6 and world.active == "metro" and prior == snapshot(world),
		"six estates, exact balances, crew, local progress, events and receipt state migrated")
	expect(world.boost.remaining(world.current().clock) == 300 and world.premium.entitlements.remove_ads, "BOOST clock and restoration entitlement preserved")
	expect(world.current().preferences.quality == 1 and world.current().preferences.fps == 30 and not world.current().preferences.quality_auto,
		"old manual settings remain manual")
	var serial: int = world.storage.sequence
	expect(world.checkpoint() == OK and world.storage.sequence == serial + 1, "new release publishes an atomic checkpoint")
	for suffix in ["", ".tmp"]:
		var interrupted := FileAccess.open(path + suffix, FileAccess.WRITE)
		interrupted.store_string("{incomplete")
		interrupted.close()
	var recovered := saved_at(AT)
	expect(recovered.storage.sequence == serial and prior == snapshot(recovered), "backup recovers after corrupted primary and interrupted staging")
	expect(recovered.checkpoint() == OK and snapshot(saved_at(AT)) == prior, "recovered profile is safely re-published")

func snapshot(world: HbtCampaign) -> String:
	var districts := {}
	for id: String in world.districts:
		var data: Dictionary = world.districts[id].snapshot()
		data.preferences.erase("quality_auto")
		districts[id] = data
	return JSON.stringify({"districts": districts, "active": world.active, "boost": world.boost.snapshot(),
		"premium": world.premium.snapshot(), "ledger": world.ledger.snapshot()})
