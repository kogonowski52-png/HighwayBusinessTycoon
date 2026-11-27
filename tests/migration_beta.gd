extends "res://tests/run_checks.gd"

const Atlas = preload("res://data/world/atlas.gd")
const Policy = preload("res://data/monetization/config.gd")
const AT := Policy.SEASON_EPOCH + 43200

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var path := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--profile="):
			path = arg.get_slice("=", 1)
	if not path.begins_with("/tmp/hbt-beta-migration-"):
		expect(false, "isolated fixture path is required")
		result("Beta migration")
		return
	var world := load_profile(path)
	if "--seed" in OS.get_cmdline_user_args():
		seed_file(world, path)
	else:
		var expected := FileAccess.get_file_as_string(path + ".expected")
		expect(world.districts.size() == 12 and profile(world) == expected, "all estates, fleet, entitlement, reward history and settings match the original")
		expect(world.boost.remaining(AT) == 300, "BOOST remains active for the same time")
		expect(world.premium.call("offer_wait", "gift", AT) == 1800 and world.premium.call("day_used", "gift", AT) == 1,
			"the original reward receipt applies to the new cooldown and daily limit")
		expect(world.checkpoint() == OK and profile(load_profile(path)) == expected, "beta checkpoint reopens without changing legacy state")
	result("Beta migration")

func load_profile(path: String) -> HbtCampaign:
	var world := HbtCampaign.new(HbtEconomy.new())
	world.storage.path = path
	world.restore(AT)
	return world

func seed_file(world: HbtCampaign, path: String) -> void:
	expect(ProjectSettings.get_setting("application/config/version") == "0.9.5", "fixture created by the actual 0.9.5 code")
	if failures > 0:
		return
	for district: String in Atlas.DESTINATIONS:
		if district != "north":
			expect(world.travel(district) == OK, "playable region " + district)
		var store := world.current()
		store.credit("cash", HbtAmount.from("100000000075000"))
		store.credit("reputation", HbtAmount.from(180))
		store.buy_levels("fuel", 24)
		for service: String in store.facilities:
			if service != "fuel" and store.unlock(service):
				store.buy_levels(service, 20)
		store.hire("fuel")
		store.train("fuel", 0)
		store.credit("diamond", HbtAmount.from(25))
	expect(world.freight.buy(world, "van") and world.freight.hire(world) and world.freight.assign(world, "1", "2"),
		"original campaign has an assigned vehicle and driver")
	world.current().preferences.quality = 1
	world.current().credit("diamond", HbtAmount.from(5))
	world.premium.remember("gift", AT)
	world.premium.entitlements.remove_ads = true
	world.premium.progress(Policy.SEASONS[0].sku).xp = 70
	world.boost.extend_confirmed(AT)
	expect(world.checkpoint() == OK, "0.9.5 saved the campaign")
	var report := FileAccess.open(path + ".expected", FileAccess.WRITE)
	report.store_string(profile(load_profile(path)))

func profile(world: HbtCampaign) -> String:
	var districts := {}
	for district: String in world.districts:
		districts[district] = world.districts[district].snapshot()
	return JSON.stringify({"active": world.active, "districts": districts, "fleet": world.freight.snapshot(),
		"premium": world.premium.snapshot(), "boost": world.boost.snapshot(), "ledger": world.ledger.snapshot()})
