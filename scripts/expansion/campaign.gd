class_name HbtCampaign
extends RefCounted
## One atomic file stores North at the original root and the other districts under world.

const Atlas = preload("res://data/world/atlas.gd")
const Calendar = preload("res://data/world/expedition_calendar.gd")
const Fleet = preload("res://scripts/logistics/transport_manager.gd")
const Ledger = preload("res://scripts/expansion/ledger.gd")

var storage: RefCounted
var districts: Dictionary = {}
var active := "north"
var ledger := Ledger.new()
var boost := HbtBoost.new()
var premium := HbtPremiumState.new()
var freight := Fleet.new()

func _init(north: HbtEconomy) -> void:
	storage = north.storage
	districts.north = north
	north.global_boost = boost

func restore(wall := -1) -> void:
	var root: Dictionary = storage.restore()
	var north: HbtEconomy = districts.north
	var world := HbtEconomy.safe_dict(root.get("world"))
	boost.restore(HbtEconomy.safe_dict(world.get("boost")))
	premium.restore(HbtEconomy.safe_dict(world.get("premium")))
	var observed := int(Time.get_unix_time_from_system()) if wall < 0 else wall
	var now := boost.observe_device(observed) if wall < 0 else boost.advance(observed)
	north.restore_profile(root, now, false)
	north.capture_absence(now)
	ledger.restore(HbtEconomy.safe_dict(world.get("ledger")))
	freight.restore(HbtEconomy.safe_dict(world.get("transport")))
	var saved := HbtEconomy.safe_dict(world.get("estates"))
	for id in Atlas.DESTINATIONS:
		if id == "north" or not saved.get(id) is Dictionary or not Atlas.DESTINATIONS[id].has("scene"):
			continue
		var estate := HbtEconomy.new(id)
		estate.storage = storage
		estate.global_boost = boost
		estate.restore_profile(saved[id], north.clock, false)
		districts[id] = estate
	share_identity(north)
	for id in districts:
		if id != "north":
			districts[id].capture_absence(north.clock)
	var last: Variant = world.get("active", "north")
	active = last if last is String and districts.has(last) else "north"
	ledger.advance(north.clock)
	north.campaign_data = {}
	if freight.advance(self, north.clock, false):
		checkpoint()
	theme()

func current() -> HbtEconomy:
	return districts[active]

func share_identity(source: HbtEconomy) -> void:
	for estate: HbtEconomy in districts.values():
		if estate == source:
			continue
		estate.language = source.language
		estate.low_power = source.low_power
		estate.feedback_enabled = source.feedback_enabled
		estate.preferences = source.preferences
		estate.recognition = source.recognition
		estate.cards = source.cards
		estate.manager_ranks = source.manager_ranks

func theme() -> void:
	var event := ledger.season()
	var local := current()
	local.special_guest = {"type": event.guest, "model": event.model} if event.live else {}

func checkpoint() -> Error:
	var estate := current()
	boost.advance(estate.clock)
	share_identity(estate)
	estate.high_water = maxi(estate.clock, estate.high_water)
	ledger.advance(estate.clock)
	var root: Dictionary = districts.north.snapshot()
	var others := {}
	for id in districts:
		if id != "north":
			others[id] = districts[id].snapshot()
	root["world"] = {"active": active, "estates": others, "ledger": ledger.snapshot(), "boost": boost.snapshot(), "premium": premium.snapshot(), "transport": freight.snapshot()}
	var error: Error = storage.store(root)
	estate.save_error = error
	estate.dirty = error != OK
	if error == OK:
		var regions: Array[PackedInt64Array] = []
		for region: HbtEconomy in districts.values():
			regions.append(PackedInt64Array([region.high_water, region.high_water + region.offline_limit()]))
		boost.prune(regions)
	return error

func available(id: String) -> bool:
	var offer: Dictionary = Atlas.DESTINATIONS.get(id, {})
	if storage.read_only or not offer.has("scene"):
		return false
	if districts.has(id):
		return true
	var sponsor: HbtEconomy = districts.get(offer.get("from", "north"))
	if sponsor == null:
		return false
	return sponsor.level("fuel") >= int(offer.fuel) and sponsor.metric("reputation") >= int(offer.rep) \
		and sponsor.level(offer.get("gate", "")) >= int(offer.get("tier", 0)) and sponsor.can_afford(HbtAmount.from(offer.cost))

func travel(id: String) -> Error:
	if not available(id) or id == active:
		return ERR_UNAVAILABLE
	var old_id := active
	var source := current()
	var existed := districts.has(id)
	var offer: Dictionary = Atlas.DESTINATIONS[id]
	var sponsor: HbtEconomy = districts.get(offer.get("from", "north"), source)
	var before_wallet := sponsor.amount("cash")
	var before_spent := sponsor.spent
	if not existed:
		if not sponsor.debit(HbtAmount.from(offer.cost)):
			return ERR_UNAVAILABLE
		var opened := HbtEconomy.new(id)
		opened.storage = storage
		opened.global_boost = boost
		opened.clock = source.clock
		opened.high_water = source.clock
		districts[id] = opened
	var arrival: HbtEconomy = districts[id]
	var prior_ledger := ledger.snapshot().duplicate(true)
	var source_water := source.high_water
	var old_offline := [arrival.clock, arrival.high_water, arrival.offline_pending, arrival.offline_seconds, arrival.offline_away_seconds, arrival.offline_boosted]
	share_identity(source)
	source.high_water = maxi(source.high_water, source.clock)
	arrival.capture_absence(source.clock)
	active = id
	var error := checkpoint()
	if error != OK:
		active = old_id
		ledger.restore(prior_ledger)
		source.high_water = source_water
		sponsor.wallet.cash = before_wallet
		sponsor.spent = before_spent
		if existed:
			arrival.clock = old_offline[0]
			arrival.high_water = old_offline[1]
			arrival.offline_pending = old_offline[2]
			arrival.offline_seconds = old_offline[3]
			arrival.offline_away_seconds = old_offline[4]
			arrival.offline_boosted = old_offline[5]
		else:
			districts.erase(id)
		source.save_error = error
		source.dirty = true
	theme()
	return error

func completion(id: String) -> int:
	if not districts.has(id):
		return 0
	var estate: HbtEconomy = districts[id]
	var sum := 0
	for level: int in estate.levels.values():
		sum += level
	return floori(float(sum) / estate.facilities.size())

func projected_income(id: String) -> HbtAmount:
	if not districts.has(id):
		return HbtAmount.new()
	var estate: HbtEconomy = districts[id]
	return estate.offline_quote(3600)

func prestige_ready() -> bool:
	var estate := current()
	return not storage.read_only and estate.prestige_rank < 20 		and estate.levels.values().all(func(tier: int) -> bool: return tier >= HbtEconomy.CONFIG.max_level)

func prestige(confirmed: bool) -> Error:
	if not confirmed or not prestige_ready():
		return ERR_UNAVAILABLE
	var previous := current()
	var next := HbtEconomy.new(active)
	next.storage = storage
	next.global_boost = boost
	next.clock = previous.clock
	next.high_water = previous.high_water
	next.prestige_rank = previous.prestige_rank + 1
	next.works.restore(previous.works.snapshot())
	next.practice_state = previous.practice_state.duplicate(true)
	next.supplies = previous.supplies.duplicate()
	next.tutorial_step = HbtEconomy.TUTORIAL_DONE
	next.equipped.assign(previous.equipped)
	next.player_xp = previous.player_xp
	next.paid_player_level = previous.paid_player_level
	next.offline_tier = previous.offline_tier
	next.offline_pending = previous.offline_pending
	next.offline_boosted = previous.offline_boosted
	next.offline_seconds = previous.offline_seconds
	next.offline_away_seconds = previous.offline_away_seconds
	for currency in ["reputation", "diamond", "event"]:
		next.wallet[currency] = previous.amount(currency)
	share_identity(previous)
	next.language = previous.language
	next.low_power = previous.low_power
	next.feedback_enabled = previous.feedback_enabled
	next.preferences = previous.preferences
	next.recognition = previous.recognition
	next.cards = previous.cards
	next.manager_ranks = previous.manager_ranks
	districts[active] = next
	var owned_beacon := ledger.cosmetics.has("beacon")
	var owned_canopy := ledger.cosmetics.has("copper_arch")
	ledger.cosmetics["beacon"] = true
	ledger.prestige_points += 1
	if ledger.prestige_points >= 2:
		ledger.cosmetics["copper_arch"] = true
	var error := checkpoint()
	if error != OK:
		districts[active] = previous
		ledger.prestige_points -= 1
		if not owned_beacon:
			ledger.cosmetics.erase("beacon")
		if not owned_canopy:
			ledger.cosmetics.erase("copper_arch")
	theme()
	return error
