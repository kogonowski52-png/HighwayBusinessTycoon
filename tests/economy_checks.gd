extends "res://tests/run_checks.gd"

const SaveManager := preload("res://scripts/core/save_manager.gd")
const Staff := preload("res://scripts/employees/staff_rules.gd")
const Ads := preload("res://scripts/monetization/offline_ads.gd")
const WALL := 1_789_000_000

class TestProvider extends RefCounted:
	signal reward_earned(id: String)
	signal reward_closed(id: String)
	signal reward_availability
	var request_id := ""
	func rewardReady() -> bool:
		return true
	func showOffline(token: String) -> bool:
		request_id = token
		return true

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	arithmetic()
	commercial_rules()
	disk_recovery()
	offline_and_ad()
	daily_event()
	result("Economy, save and offline")

func arithmetic() -> void:
	var wide := HbtAmount.from("9".repeat(180))
	expect(wide.plus(HbtAmount.from(1)).decimal() == "1" + "0".repeat(180), "180-digit carry is exact")
	expect(wide.plus(HbtAmount.from(1)).minus(HbtAmount.from(1)).decimal() == wide.decimal(), "long borrow")
	expect(wide.times(999_999_999).divided(999_999_999).decimal() == wide.decimal(), "max factor multiplication and division")
	expect(HbtAmount.from("123456789123456789123456789").divided(7).decimal() == "17636684160493827017636684", "long quotient truncates")
	expect(HbtAmount.from("1234").minus(HbtAmount.from(1235)).empty(), "amount cannot go negative")
	expect(HbtAmount.from("1e9").empty() and HbtAmount.from("-3").empty(), "decline non-decimal inputs")
	expect(HbtAmount.from("1000001").compact("pl") == "1M" and HbtAmount.from("1200901").compact("pl") == "1,2M", "localized compact amount")

func commercial_rules() -> void:
	var store := HbtEconomy.new()
	store.clock = WALL
	expect(not store.unlock("workshop") and store.level("workshop") == 0, "unlock gates are enforced")
	for id in store.facilities:
		var prior := HbtAmount.new()
		var increasing := true
		for tier in range(1, 100):
			var cost := store.cost_at(id, tier)
			increasing = increasing and cost.compare(prior) > 0 and store.price(id, tier + 1).compare(store.price(id, tier)) > 0
			prior = cost
		expect(increasing and store.cost_at(id, 100).empty(), "%s 100-level curve" % id)
	store.serve("fuel", store.payout("fuel", 100, -1), 1, -1)
	expect(store.amount("cash").decimal() == "155", "first completed service can buy level 2")
	expect(store.buy_levels("fuel", 1) == 1 and store.level("fuel") == 2 and store.amount("cash").empty(), "single-level atomically deducts exact cost")
	expect(store.buy_levels("fuel", 10) == 0 and store.level("fuel") == 2, "unaffordable batch purchases are rejected")
	store.credit("cash", HbtAmount.from("100000000000000000000"))
	for count in [10, 25, 0]:
		var quote := store.quote_upgrade("fuel", count)
		var balance := store.amount("cash")
		expect(store.buy_levels("fuel", count) == quote.count and store.amount("cash").compare(balance.minus(quote.cost)) == 0,
			"exact purchase for quantity %d" % count)
	expect(store.level("fuel") == 100 and store.buy_levels("fuel", 1) == 0 and store.capacity("fuel") == 2, "cap and capacity milestones")
	expect(store.hire("fuel") and store.hire("fuel") and not store.hire("fuel"), "staff never exceed physical capacity")
	var base := store.payout("fuel", 100, 0)
	var regular := store.duration("fuel", 0)
	expect(not store.promote("fuel", 0), "experience gate cannot be bypassed")
	for i in range(12):
		store.serve("fuel", base, 1, 0)
	expect(not store.holding().empty() and store.crew.fuel[0].xp == 12, "automated sales earn experience and await collection")
	expect(store.train("fuel", 0) and store.train("fuel", 0) and store.promote("fuel", 0), "training and promotion")
	expect(store.payout("fuel", 100, 0).compare(base) > 0 and store.duration("fuel", 0) < regular,
		"staff bonuses change effective price and time")
	expect(store.claim_reward("crew") and not store.claim_reward("crew") and store.assign("ada"), "transparent manager reward is single claim")
	expect(store.holding().empty(), "collector retrieves held revenue")
	var wallet_before := store.amount("cash")
	store.serve("fuel", base, 2, 0)
	expect(store.amount("cash").compare(wallet_before.plus(base)) == 0, "collector credits new payments")
	store.cards.merge({"iga": true, "maks": true, "mira": true, "leon": true})
	expect(store.assign("iga") and store.assign("maks") and not store.assign("mira"), "three active management roles")
	expect(store.payout("fuel", 100, -1).compare(store.price("fuel")) > 0 and store.duration("fuel", 0) < regular,
		"skills change price and service")
	var period := store.arrival_period()
	store.assign("maks")
	store.assign("mira")
	expect(store.arrival_period() < period, "traffic skill changes cadence")
	var before := store.cost_at("market", 2)
	store.assign("iga")
	store.assign("leon")
	expect(store.cost_at("market", 2).compare(before) < 0, "upgrade discount affects quoted price")
	store.credit("event", HbtAmount.from(30))
	expect(store.exchange(false) and store.amount("diamond").compare(HbtAmount.from(Staff.MAX_RANK)) >= 0, "event catalog trades points for diamonds")
	store.credit("diamond", HbtAmount.from(4))
	expect(store.buy_boost() and not store.buy_boost() and store.payout("fuel", 100, -1).compare(store.price("fuel")) > 0,
		"optional temporary boost uses earned currency")
	store.clock += store.CONFIG.boost_seconds
	expect(store.payout("fuel", 100, -1).compare(store.price("fuel")) == 0, "temporary boost expires")

func disk_recovery() -> void:
	var path := "/tmp/hbt-save-check-%d.cfg" % OS.get_process_id()
	var legacy := ConfigFile.new()
	legacy.set_value("station", "cash", 98765)
	legacy.set_value("station", "level", 5)
	legacy.set_value("station", "customers", 37)
	legacy.set_value("settings", "language", "en")
	legacy.set_value("settings", "low_power", true)
	expect(legacy.save(path) == OK, "legacy fixture written")
	var store := HbtEconomy.new()
	store.storage.path = path
	store.restore(WALL)
	expect(store.amount("cash").decimal() == "98765" and store.level("fuel") == 5 and store.customers == 37
		and store.language == "en" and store.low_power, "migration from actual five-level ConfigFile format")
	expect(store.checkpoint() == OK, "migration checkpoint")
	var huge := HbtAmount.from("9".repeat(200))
	store.credit("cash", huge)
	var expected := store.amount("cash").decimal()
	expect(store.checkpoint() == OK, "serialized huge amount with checksum")
	expect(DirAccess.copy_absolute(path, path + ".tmp") == OK, "crash fixture preserves new temporary copy")
	write(path, "{torn")
	var retry := HbtEconomy.new()
	retry.storage.path = path
	retry.restore(WALL)
	expect(retry.amount("cash").decimal() == expected, "highest valid temporary snapshot recovers after interrupted rename")
	retry.credit("cash", HbtAmount.from(7))
	expect(retry.checkpoint() == OK, "safe next checkpoint after recovery")
	write(path, "{\"schema\":3,\"sequence\":99,\"payload\":\"{}\",\"sha256\":\"bad\"}")
	retry.restore(WALL)
	expect(retry.amount("cash").decimal() == expected, "valid backup preserved when current primary is bad")
	var payload := JSON.stringify(retry.snapshot())
	write(path, JSON.stringify({"schema": SaveManager.SCHEMA + 1, "sequence": 100, "sha256": payload.sha256_text(), "payload": payload}))
	retry.restore(WALL)
	expect(retry.storage.read_only and retry.checkpoint() == ERR_UNAVAILABLE, "unknown newer schema remains untouched")
	clean_save(path)

func offline_and_ad() -> void:
	var store := HbtEconomy.new()
	store.clock = WALL
	store.high_water = WALL
	expect(store.offline_quote(3600).empty(), "unstaffed site does not earn offline")
	expect(store.hire("fuel"), "staffed test site")
	var expected := store.offline_quote(28_800)
	expect(store.capture_absence(WALL + 100_000).compare(expected) == 0 and store.offline_seconds == 28_800, "eight-hour cap")
	expect(store.capture_absence(WALL + 100_000).empty(), "same timestamp cannot earn twice")
	expect(store.capture_absence(WALL + 99_980).empty(), "small rollback is harmless")
	expect(not store.capture_absence(WALL + 100_290).empty(), "earnings continue after a small correction")
	var clock := store.high_water
	expect(store.capture_absence(clock + 100_000, 300).compare(store.offline_quote(300)) == 0
		and store.high_water == clock + 300, "resume bounds forward clock jumps with monotonic time")
	var plugin := TestProvider.new()
	var bridge := Ads.new()
	expect(not bridge.available(), "offline export exposes no ad button")
	bridge.connect_provider(plugin)
	var awarded: Array[HbtAmount] = []
	bridge.earned.connect(func(base: HbtAmount) -> void: awarded.append(store.redeem_offline(true, base)))
	var pending := store.offline_pending
	expect(bridge.request(pending) and not bridge.request(pending), "one pending rewarded offer")
	plugin.reward_earned.emit("incorrect-token")
	expect(awarded.is_empty() and bridge.busy(), "only the outstanding token can grant reward")
	plugin.reward_closed.emit(plugin.request_id)
	expect(awarded.is_empty() and not bridge.busy() and store.offline_pending.compare(pending) == 0,
		"dismissal preserves normal offline claim")
	bridge.request(pending)
	plugin.reward_earned.emit(plugin.request_id)
	plugin.reward_earned.emit(plugin.request_id)
	expect(awarded.size() == 1 and awarded[0].compare(pending.times(2)) == 0, "reward callback doubles only once")
	expect(store.redeem_offline().empty() and store.offline_pending.empty(), "offline entitlement is spent")

func write(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(content)
	file.close()

func daily_event() -> void:
	var store := HbtEconomy.new()
	store.clock = WALL
	var event := store.current_event()
	expect(not store.claim_daily(), "daily challenge requires real services")
	for index in range(int(event.goal)):
		store.serve(event.services[0], HbtAmount.from(25), 1, -1)
	expect(store.claim_daily() and not store.claim_daily() and store.amount("diamond").decimal() == "1",
		"daily challenge grants a transparent one-time bonus")
	store.clock += 86_400
	expect(store.daily_progress() == 0 and not store.claim_daily(), "new day opens the next challenge at zero")
