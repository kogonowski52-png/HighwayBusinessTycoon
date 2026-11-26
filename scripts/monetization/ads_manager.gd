extends Node

signal availability_changed
signal rewarded(id: String)
signal failed
signal commercial_started

const Config = preload("res://data/monetization/config.gd")
const Native := "HighwayRewarded"
const Staff = preload("res://scripts/employees/staff_rules.gd")

var game: Node3D
var provider: Object
var pending := ""
var offer := ""
var context := {}
var confirmed := false
var reward_receipts := 0
var interstitial := ""
var break_counted := false

func bind(controller: Node3D) -> void:
	game = controller
	if not available() and Engine.has_singleton(Native):
		connect_provider(Engine.get_singleton(Native))

func connect_provider(plugin: Object) -> void:
	provider = plugin
	provider.connect("reward_earned", receive)
	provider.connect("reward_closed", closed)
	if provider.has_signal("ad_shown"):
		provider.connect("ad_shown", on_ad_shown)
	provider.connect("reward_availability", notify)
	provider.connect("break_shown", on_break_shown)
	provider.connect("break_closed", on_break_closed)

func available() -> bool:
	return is_instance_valid(provider) and provider.adsConfigured()

func busy() -> bool:
	return not pending.is_empty() or not interstitial.is_empty()

func region() -> HbtEconomy:
	return game.economy

func slot(id: String) -> String:
	return id if id in ["boost", "offline"] else "bonus"

func loading(id := "offline") -> bool:
	return available() and provider.rewardLoading(slot(id))

func privacy_required() -> bool:
	return available() and provider.privacyOptionsRequired()

func privacy() -> void:
	if privacy_required() and not busy():
		provider.showPrivacy()

func ready(id := "offline") -> bool:
	return available() and not busy() and provider.rewardReady(slot(id))

func prepare(id := "offline") -> void:
	if available() and not busy() and not loading(id):
		provider.prepareReward(slot(id))
		notify()

func playable(id: String, detail: Dictionary = {}) -> bool:
	var world: HbtCampaign = game.campaign
	var e := region()
	if world.storage.read_only:
		return false
	if id == "boost":
		return world.boost.can_extend(e.clock)
	if not Config.OFFERS.has(id) or not world.premium.allowed(id, e.clock):
		return false
	if already_claimed(world, id, detail):
		return false
	var site := str(detail.get("site", ""))
	var index := int(detail.get("index", -1))
	match id:
		"offline": return not e.offline_eligible().empty()
		"upgrade": return e.level(site) > 0 and e.level(site) < e.CONFIG.max_level
		"training":
			var crew: Array = e.crew.get(site, [])
			return index >= 0 and index < crew.size() and int(crew[index].training) < Staff.MAX_TRAINING
		"daily": return e.recognition.last_day == int(detail.get("start_day", e.day_index()))
		"mission": return e.claimed.get(str(detail.get("mission", "")), false) and detail.get("offer_day") == detail.get("start_day", e.day_index())
		"event": return detail.has("event_week") or (world.ledger.season().live and world.ledger.paid_event())
		"delivery":
			return e.level("warehouse") > 0 and int(e.commerce.record("warehouse").stock) + int(e.commerce.holds("warehouse").incoming) 				< e.commerce.capacity("warehouse", e.level("warehouse"))
		"manager": return not e.cards.has(Config.AD_MANAGER)
		"vip": return not world.premium.vip.has(e.district)
	return true

func already_claimed(world: HbtCampaign, id: String, detail: Dictionary) -> bool:
	if id == "event":
		return int(world.premium.offer_claims.get("event_week", -1)) == int(detail.get("event_week", world.ledger.week))
	if id == "mission":
		return world.premium.offer_claims.has(mission_marker(detail))
	return false

func mission_marker(detail: Dictionary) -> String:
	return "mission/%s/%s" % [region().district, detail.get("mission", "")]

func request(id := "offline", detail: Dictionary = {}) -> bool:
	game.sync_commercial_clock()
	var condition := detail.duplicate()
	condition.erase("event_week")
	condition.erase("start_day")
	if not playable(id, condition) or not ready(id):
		return false
	var e := region()
	pending = Crypto.new().generate_random_bytes(16).hex_encode()
	offer = id
	context = condition
	context["district"] = e.district
	context["start_day"] = e.day_index()
	if id == "event":
		context["event_week"] = game.campaign.ledger.week
	if id == "offline":
		context["eligible"] = e.offline_eligible()
	confirmed = false
	if not provider.showRewarded(slot(id), pending):
		reset_request()
		return false
	game.campaign.premium.quiet(e.clock)
	track("ad_requested", id)
	commercial_started.emit()
	notify()
	return true

func on_ad_shown(placement: String) -> void:
	track("ad_shown", placement)

func track(name: String, key: String) -> void:
	game.campaign.premium.record(name, region().clock, key)

func receive(token: String) -> void:
	if pending.is_empty() or pending != token or confirmed or context.district != region().district:
		return
	confirmed = true
	reward_receipts += 1
	game.sync_commercial_clock()
	var e := region()
	var world: HbtCampaign = game.campaign
	var id := offer
	var was_running := world.boost.earning(e.clock)
	var earned := world.premium.apply(world, func() -> bool:
		if not playable(id, context):
			return false
		if not grant(world, e, id):
			return false
		world.premium.remember(id, e.clock)
		if id == "mission":
			world.premium.offer_claims[mission_marker(context)] = true
		elif id == "event":
			world.premium.offer_claims["event_week"] = context.event_week
		world.premium.quiet(e.clock)
		track("ad_reward", id)
		if id == "boost":
			track("boost_extended" if was_running else "boost_activated", "boost")
		return true)
	if earned:
		rewarded.emit(id)
	else:
		failed.emit()
	notify()

func grant(world: HbtCampaign, e: HbtEconomy, id: String) -> bool:
	if id == "boost":
		return world.boost.extend_confirmed(e.clock)
	var amount: int = Config.OFFERS[id][2]
	match id:
		"offline":
			return not e.redeem_offline(true, context.eligible).empty()
		"cash", "mission":
			e.credit("cash", HbtAmount.from(amount))
		"daily", "event", "gift":
			e.credit("diamond", HbtAmount.from(amount))
		"upgrade":
			e.levels[context.site] += amount
			e.add_xp(3)
		"training":
			e.crew[context.site][context.index].training += amount
			e.add_xp(4)
		"delivery":
			var load := e.commerce.record("warehouse")
			load.stock += amount
			load.inbound += amount
			world.ledger.increment(e, {"deliveries": amount})
		"manager":
			e.cards[Config.AD_MANAGER] = true
		"vip":
			world.premium.vip[e.district] = true
	return true

func closed(token: String) -> void:
	if token != pending or pending.is_empty():
		return
	game.campaign.premium.quiet(region().clock)
	game.campaign.checkpoint()
	reset_request()
	notify()

func reset_request() -> void:
	pending = ""
	offer = ""
	context = {}
	confirmed = false

func notify() -> void:
	availability_changed.emit()

func natural_break() -> void:
	if not available() or busy() or not game.mounted or game.traveling or game.operations.modal_open() 			or not game.camera_rig.film.is_empty() or game.purchases.busy():
		return
	var e := region()
	var state: HbtPremiumState = game.campaign.premium
	if not state.break_allowed(e.clock, e.tutorial_step == e.TUTORIAL_DONE):
		return
	if not provider.breakReady():
		provider.prepareBreak()
		return
	var token := Crypto.new().generate_random_bytes(16).hex_encode()
	if provider.showBreak(token):
		interstitial = token
		break_counted = false

func on_break_shown(token: String) -> void:
	if interstitial.is_empty() or token != interstitial or break_counted:
		return
	var e := region()
	var state: HbtPremiumState = game.campaign.premium
	break_counted = true
	state.ad_breaks.append(e.clock)
	state.quiet(e.clock)
	track("ad_shown", "interstitial")
	game.campaign.checkpoint()

func on_break_closed(token: String) -> void:
	if token == interstitial:
		interstitial = ""
		notify()
