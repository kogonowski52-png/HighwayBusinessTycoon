extends Node

signal availability_changed
signal rewarded(id: String)
signal failed
signal unconfirmed
signal commercial_started
signal commercial_finished

const Config = preload("res://data/monetization/config.gd")
const Native := "HighwayRewarded"
const Staff = preload("res://scripts/employees/staff_rules.gd")

var game: Node3D
var provider: Object
var pending := ""
var offer := ""
var context := {}
var confirmed := false
var paid := false
var show_failed := false
var wait_offer := ""
var wait_context := {}
var wait_until := 0
var next_attempt := 0
var last_reward := "idle"
var reward_receipts := 0
var interstitial := ""
var break_counted := false

func bind(controller: Node3D) -> void:
	game = controller
	set_process(false)
	if not available() and Engine.has_singleton(Native):
		connect_provider(Engine.get_singleton(Native))

func connect_provider(plugin: Object) -> void:
	provider = plugin
	provider.connect("reward_earned", receive)
	provider.connect("reward_closed", closed)
	if provider.has_signal("reward_show_failed"):
		provider.connect("reward_show_failed", on_show_failed)
	if provider.has_signal("ad_shown"):
		provider.connect("ad_shown", on_ad_shown)
	provider.connect("reward_availability", on_availability)
	provider.connect("break_shown", on_break_shown)
	provider.connect("break_closed", on_break_closed)
	if available() and provider.has_method("preloadAds"):
		provider.preloadAds()

func available() -> bool:
	return is_instance_valid(provider) and provider.adsConfigured()

func busy() -> bool:
	return waiting() or displaying()

func displaying() -> bool:
	return not pending.is_empty() or not interstitial.is_empty()

func waiting(id := "") -> bool:
	return not wait_offer.is_empty() and (id.is_empty() or id == wait_offer)

func region() -> HbtEconomy:
	return game.economy

func slot(id: String) -> String:
	return id if id in ["boost", "offline"] else "bonus"

func loading(id := "offline") -> bool:
	return available() and provider.rewardLoading(slot(id))

func placement_status(id: String) -> String:
	if not available():
		return "unavailable"
	if provider.has_method("adPlacementState"):
		return provider.adPlacementState(slot(id))
	if provider.rewardReady(slot(id)):
		return "ready"
	return "loading" if loading(id) else "unavailable"

func privacy_required() -> bool:
	return available() and provider.privacyOptionsRequired()

func privacy() -> void:
	if privacy_required() and not busy():
		provider.showPrivacy()

func ready(id := "offline") -> bool:
	return available() and not busy() and provider.rewardReady(slot(id))

func prepare(id := "offline") -> void:
	if available() and not displaying() and not loading(id):
		provider.prepareReward(slot(id))

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
	if not available() or busy() or game.purchases.busy() or game.suspended_at >= 0:
		return false
	game.sync_commercial_clock()
	var condition := detail.duplicate()
	condition.erase("event_week")
	condition.erase("start_day")
	if not playable(id, condition):
		return false
	var e := region()
	wait_offer = id
	wait_context = condition
	wait_context["district"] = e.district
	wait_context["start_day"] = e.day_index()
	if id == "event":
		wait_context["event_week"] = game.campaign.ledger.week
	if id == "offline":
		wait_context["eligible"] = e.offline_eligible()
	wait_until = Time.get_ticks_msec() + Config.AD_WAIT_MSEC
	next_attempt = 0
	last_reward = "waiting"
	set_process(true)
	if not provider.rewardReady(slot(id)):
		prepare(id)
	check_waiting()
	notify()
	return true

func _process(_delta: float) -> void:
	if Time.get_ticks_msec() >= next_attempt:
		check_waiting()

func on_availability() -> void:
	# The plugin can emit a state change while reserving a slot. Finish that call first.
	if waiting() and available() and provider.rewardReady(slot(wait_offer)):
		check_waiting.call_deferred()
	notify()

func check_waiting() -> void:
	if not waiting():
		return
	var now := Time.get_ticks_msec()
	next_attempt = now + 250
	if game.suspended_at >= 0 or wait_context.district != region().district:
		cancel_wait()
		return
	if now >= wait_until or not available() or not playable(wait_offer, wait_context):
		clear_wait()
		last_reward = "unavailable"
		failed.emit()
		notify()
		return
	if game.purchases.busy():
		cancel_wait()
		return
	var unit := slot(wait_offer)
	if not provider.rewardReady(unit):
		return
	var token := Crypto.new().generate_random_bytes(16).hex_encode()
	if not provider.showRewarded(unit, token):
		return
	pending = token
	offer = wait_offer
	context = wait_context
	clear_wait()
	confirmed = false
	paid = false
	last_reward = "showing"
	game.campaign.premium.quiet(region().clock)
	track("ad_requested", offer)
	commercial_started.emit()
	notify()

func cancel_wait() -> void:
	if waiting():
		clear_wait()
	elif not pending.is_empty() and provider.has_method("cancelRewarded") and provider.cancelRewarded(pending):
		reset_request()
		commercial_finished.emit()
	else:
		return
	last_reward = "cancelled"
	notify()

func clear_wait() -> void:
	wait_offer = ""
	wait_context = {}
	set_process(false)

func on_ad_shown(placement: String) -> void:
	track("ad_shown", placement)

func track(name: String, key: String) -> void:
	game.campaign.premium.record(name, region().clock, key)

func receive(token: String) -> void:
	if pending.is_empty() or pending != token or confirmed or show_failed or context.district != region().district:
		return
	confirmed = true
	reward_receipts += 1
	game.sync_commercial_clock()
	var e := region()
	var world: HbtCampaign = game.campaign
	var id := offer
	var was_running := world.boost.earning(e.clock)
	paid = world.premium.apply(world, func() -> bool:
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
	last_reward = "granted" if paid else "rejected"
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

func on_show_failed(token: String) -> void:
	if not pending.is_empty() and token == pending and not confirmed:
		show_failed = true

func closed(token: String) -> void:
	if token != pending or pending.is_empty():
		return
	game.campaign.premium.quiet(region().clock)
	game.campaign.checkpoint()
	var no_reward := not confirmed
	var earned := paid
	var did_fail := show_failed
	var id := offer
	reset_request()
	commercial_finished.emit()
	if did_fail:
		last_reward = "unavailable"
		failed.emit()
	elif no_reward:
		last_reward = "cancelled"
		unconfirmed.emit()
	elif earned:
		rewarded.emit(id)
	else:
		failed.emit()
	notify()

func reset_request() -> void:
	pending = ""
	offer = ""
	context = {}
	confirmed = false
	paid = false
	show_failed = false

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
		commercial_started.emit()
		notify()

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
		commercial_finished.emit()
		notify()
