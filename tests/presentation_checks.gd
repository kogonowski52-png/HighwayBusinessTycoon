extends "res://tests/run_checks.gd"

const Recognition = preload("res://data/economy/recognition.gd")
const Models = preload("res://data/economy/managers.gd")
const Strings = preload("res://localization/strings.gd")
const WALL := 1_789_084_800

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	calendar_cycle()
	achievements_and_settings()
	result("Presentation data and persistence")

func calendar_cycle() -> void:
	var store := HbtEconomy.new()
	store.restore(WALL)
	store.clock = WALL
	store.cards.nina = true
	var path := "/tmp/hbt-calendar-%d.cfg" % OS.get_process_id()
	store.storage.path = path
	for index in range(Recognition.CALENDAR.size()):
		var clock := store.clock
		var expected: Array = Recognition.CALENDAR[index]
		expect(store.recognition.slot() == index and store.recognition.is_available(store.day_index()) \
			and store.calendar_offer() == expected, "calendar offers disclosed day %d" % (index + 1))
		var actual := store.claim_calendar()
		if expected == ["card", "nina"]:
			expect(actual == ["diamond", Recognition.DUPLICATE_DIAMONDS], "duplicate rewards become six diamonds")
		else:
			expect(actual == expected, "calendar pays day %d" % (index + 1))
		expect(store.checkpoint() == OK and store.claim_calendar().is_empty(), "calendar checks same day %d" % (index + 1))
		store.restore(clock)
		expect(store.claim_calendar().is_empty(), "reopening keeps day %d spent" % (index + 1))
		if index == 8:
			store.clock = clock - 86_400
			expect(store.claim_calendar().is_empty(), "backward clock preserves last claimed date")
		store.clock = clock + (3 if index == 8 else 1) * 86_400
	expect(store.recognition.daily_count == 30 and store.recognition.slot() == 0 \
		and store.cards.has("vera") and store.cards.has("tom"), "30-day reward set repeats after a full cycle")
	var vouchers: int = store.recognition.vouchers
	expect(vouchers > 0 and store.redeem_voucher() and store.boost_until - store.clock == store.CONFIG.boost_seconds
		and store.recognition.vouchers == vouchers - 1 and not store.redeem_voucher(), "vouchers use the real boost and respect its active window")
	clean_save(path)

func achievements_and_settings() -> void:
	var store := HbtEconomy.new()
	store.clock = WALL
	store.add_xp(35_000)
	store.credit("cash", HbtAmount.from("900000000000000000000"))
	store.credit("diamond", HbtAmount.from(500))
	store.credit("reputation", HbtAmount.from(5000))
	for site in store.facilities:
		if site != "fuel":
			store.unlock(site)
		store.buy_levels(site, 0)
		for worker in range(store.capacity(site)):
			if store.hire(site):
				for lesson in range(4):
					store.train(site, worker)
	for key in Models.ROSTER:
		store.grant_reward({"card": key})
		for rank in range(2):
			store.train_manager(key)
	store.assign("nina")
	store.assign("ada")
	store.serve("market", store.price("market"), 2, 0)
	store.serve("fuel", store.price("fuel"), 1, 0)
	expect(store.recognition.mentor_xp.nina == 1 and store.recognition.mentor_xp.ada == 2 \
		and store.manager_rank("nina") == 3, "actual eligible sales grow manager XP independently of trained rank")
	for index in range(2510):
		store.serve("charge", store.price("charge"), 2, 0)
	for day in range(30):
		store.clock += 86_400
		store.claim_calendar()
	var icons := {}
	expect(Recognition.collection.size() == 50, "50 achievement definitions")
	for item in Recognition.collection.values():
		var filename: String = item.icon
		expect(not icons.has(filename) and ResourceLoader.exists(filename), "original icon " + item.id)
		icons[filename] = true
		var before := store.amount("diamond")
		expect(store.claim_achievement(item.id) and not store.claim_achievement(item.id) \
			and store.amount("diamond").compare(before.plus(HbtAmount.from(item.reward))) == 0, "functional achievement " + item.id)
		expect(Strings.phrase("pl", "ach_rule_" + item.group) != Strings.phrase("en", "ach_rule_" + item.group),
			"localized achievement " + item.id)
	var path := "/tmp/hbt-presentation-%d.cfg" % OS.get_process_id()
	store.storage.path = path
	store.preferences.volumes = {"music": .24, "ambient": .45, "effects": 0.0}
	store.preferences.quality = 1
	store.preferences.fps = 30
	store.preferences.haptics = false
	store.language = "en"
	root.get_node("RouteAudio").apply(store.preferences)
	expect(AudioServer.is_bus_mute(AudioServer.get_bus_index("Route Effects")) \
		and not AudioServer.is_bus_mute(AudioServer.get_bus_index("Route Music")) \
		and absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Route Ambience")) - linear_to_db(.45)) < .001,
		"mixer channels have separate volumes")
	expect(store.checkpoint() == OK, "persist presentation preferences")
	var restored := HbtEconomy.new()
	restored.storage.path = path
	restored.restore(store.clock)
	expect(restored.recognition.achievement_claimed == store.recognition.achievement_claimed \
		and restored.recognition.daily_count == 30 and restored.recognition.mentor_xp == store.recognition.mentor_xp \
		and restored.preferences.snapshot() == store.preferences.snapshot() and restored.language == "en",
		"achievements, calendar, experience and all mixer settings survive restart")
	clean_save(path)
