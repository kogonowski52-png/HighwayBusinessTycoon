class_name HbtPremiumState
extends RefCounted

const Config = preload("res://data/monetization/config.gd")

var install_id := ""
var offer_history := {}
var grants := {}
var offer_claims := {}
var entitlements := {}
var account := ""
var play_session := ""
var play_account := ""
var pass_progress := {}
var vip := {}
var active_seconds := 0.0
var ad_breaks: Array[int] = []
var quiet_until := 0
var analytics := false
var activity_log: Array = []

func snapshot() -> Dictionary:
	return {
		"install": install_id, "account": account, "offers": offer_history, "grants": grants,
		"entitlements": entitlements, "offer_claims": offer_claims, "passes": pass_progress, "vip": vip, "active_seconds": active_seconds,
		"breaks": ad_breaks, "quiet_until": quiet_until, "analytics": analytics, "activity": activity_log,
	}

func restore(data: Dictionary) -> void:
	install_id = str(data.get("install", ""))
	if install_id.length() != 32:
		install_id = Crypto.new().generate_random_bytes(16).hex_encode()
	account = str(data.get("account", ""))
	offer_history = HbtEconomy.safe_dict(data.get("offers"))
	grants = HbtEconomy.safe_dict(data.get("grants"))
	offer_claims = HbtEconomy.safe_dict(data.get("offer_claims"))
	entitlements = HbtEconomy.safe_dict(data.get("entitlements"))
	pass_progress = HbtEconomy.safe_dict(data.get("passes"))
	vip = HbtEconomy.safe_dict(data.get("vip"))
	active_seconds = maxf(0, float(data.get("active_seconds", 0)))
	ad_breaks.clear()
	var previous: Variant = data.get("breaks", [])
	if previous is Array:
		for event in previous.slice(-Config.BREAK_LIMIT):
			ad_breaks.append(int(event))
	quiet_until = HbtEconomy.counter(data.get("quiet_until", 0))
	analytics = data.get("analytics", false) == true
	activity_log.clear()
	var log: Variant = data.get("activity")
	if analytics and log is Array:
		activity_log.assign(log.slice(-128))

func record(action: String, clock: int, placement := "") -> void:
	if not analytics:
		return
	activity_log.append({"event": action, "utc": clock, "placement": placement})
	if activity_log.size() > 128:
		activity_log.pop_front()

func quiet(clock: int) -> void:
	quiet_until = maxi(quiet_until, clock + Config.COMMERCIAL_QUIET)

func break_allowed(clock: int, tutorial_done: bool) -> bool:
	if not tutorial_done or active_seconds < Config.PLAY_BEFORE_BREAK or clock < quiet_until or entitlements.has("remove_ads"):
		return false
	while not ad_breaks.is_empty() and ad_breaks.front() <= clock - Config.BREAK_WINDOW:
		ad_breaks.pop_front()
	return ad_breaks.size() < Config.BREAK_LIMIT and (ad_breaks.is_empty() or clock >= ad_breaks.back() + Config.BREAK_INTERVAL)

func allowed(id: String, now: int) -> bool:
	return offer_wait(id, now) == 0

func offer_wait(id: String, now: int) -> int:
	var rule: Array = Config.OFFERS[id]
	var past: Dictionary = offer_history.get(id, {})
	var last := int(past.get("at", -1))
	var remaining := maxi(0, last + int(rule[0]) - now) if last >= 0 else 0
	var exhausted := day_used(id, now) >= int(rule[1])
	return maxi(remaining, Config.DAY - posmod(now, Config.DAY)) if exhausted else remaining

func day_used(id: String, now: int) -> int:
	var past: Dictionary = offer_history.get(id, {})
	var day := floori(now / float(Config.DAY))
	return int(past.get("count", 0)) if day == int(past.get("day", -1)) else 0

func remember(id: String, now: int) -> void:
	if id == "boost":
		return
	var day := floori(now / float(Config.DAY))
	var old: Dictionary = offer_history.get(id, {})
	var count := 1 + int(old.get("count", 0)) if day == int(old.get("day", -1)) else 1
	offer_history[id] = {"at": now, "day": day, "count": count}

func progress(sku: String) -> Dictionary:
	if not pass_progress.has(sku):
		pass_progress[sku] = {"xp": 0, "tasks": 0, "awarded": false, "free": {}, "premium": {}}
	return pass_progress[sku]

func record_season(clock: int, flags: Dictionary, points: int) -> void:
	var season := Config.season_at(clock)
	if season.is_empty():
		return
	var record := progress(season.sku)
	record.xp = mini(Config.SEASON_TIERS * Config.XP_PER_TIER, int(record.xp) + points)
	record.tasks = mini(season.goal, int(record.tasks) + int(flags.get(season.task, 0)))
	if record.tasks >= season.goal and not record.awarded:
		record.awarded = true
		record.xp = mini(Config.SEASON_TIERS * Config.XP_PER_TIER, int(record.xp) + 210)

func grant_items(world: HbtCampaign, estate: HbtEconomy, items: Dictionary) -> void:
	for type in items:
		match type:
			"card":
				estate.cards[items.card] = true
			"decor":
				world.ledger.cosmetics[items.decor] = true
			"voucher":
				estate.recognition.vouchers = mini(1000, estate.recognition.vouchers + int(items.voucher))
			"cash", "diamond", "reputation", "event":
				estate.credit(type, HbtAmount.from(items[type]))

# Receipts and their effects share the save envelope. A disk failure restores the in-memory state.
func apply(world: HbtCampaign, operation: Callable) -> bool:
	if world.storage.read_only:
		return false
	var estate := world.current()
	var before := snapshot().duplicate(true)
	var wallet := estate.wallet.duplicate()
	var levels := estate.levels.duplicate()
	var crew := estate.crew.duplicate(true)
	var cards := estate.cards.duplicate()
	var equipped := estate.equipped.duplicate()
	var vouchers := estate.recognition.vouchers
	var xp := estate.player_xp
	var gross := estate.gross
	var offline := [estate.offline_pending, estate.offline_boosted, estate.offline_seconds, estate.offline_away_seconds]
	var trades := estate.commerce.state.duplicate(true)
	var supplies := estate.supplies.duplicate()
	var practice := estate.practice_state.duplicate(true)
	var works := estate.works.snapshot().duplicate(true)
	var transport: Dictionary = world.freight.snapshot().duplicate(true)
	var old_ledger: Dictionary = world.ledger.snapshot().duplicate(true)
	var windows := world.boost.windows.duplicate()
	var blocked := estate.is_blocking_signals()
	estate.set_block_signals(true)
	var committed: bool = operation.call() == true and world.checkpoint() == OK
	estate.set_block_signals(blocked)
	if not committed:
		restore(before)
		estate.wallet = wallet
		estate.levels = levels
		estate.crew = crew
		estate.cards = cards
		estate.equipped.assign(equipped)
		estate.recognition.vouchers = vouchers
		estate.player_xp = xp
		estate.gross = gross
		estate.offline_pending = offline[0]
		estate.offline_boosted = offline[1]
		estate.offline_seconds = offline[2]
		estate.offline_away_seconds = offline[3]
		estate.commerce.state = trades
		estate.supplies = supplies
		estate.practice_state = practice
		estate.works.restore(works)
		world.freight.restore(transport)
		world.ledger.restore(old_ledger)
		world.boost.windows.assign(windows)
		world.share_identity(estate)
	estate.touch()
	return committed
