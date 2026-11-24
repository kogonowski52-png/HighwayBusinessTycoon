extends RefCounted
## Adapter for the optional Android rewarded-video plugin. The normal game has no provider.

signal availability_changed
signal earned(base: HbtAmount)

const SINGLETON := "HighwayRewarded"
var provider: Object
var pending := ""
var snapshot: HbtAmount
var _sequence := 0

func attach() -> void:
	if Engine.has_singleton(SINGLETON):
		connect_provider(Engine.get_singleton(SINGLETON))

func connect_provider(plugin: Object) -> void:
	provider = plugin
	provider.connect("reward_earned", confirm)
	provider.connect("reward_closed", dismissed)
	provider.connect("reward_availability", notify)

func available() -> bool:
	return is_instance_valid(provider)

func busy() -> bool:
	return not pending.is_empty()

func loading() -> bool:
	return available() and provider.rewardLoading()

func prepare() -> void:
	if available() and not loading():
		provider.prepare()
		notify()

func privacy_required() -> bool:
	return available() and provider.privacyOptionsRequired()

func privacy() -> void:
	if privacy_required() and not busy():
		provider.showPrivacy()
		notify()

func ready() -> bool:
	return available() and not busy() and provider.rewardReady()

func request(amount: HbtAmount) -> bool:
	if amount.empty() or not ready():
		return false
	_sequence += 1
	pending = "%d-%d" % [Time.get_ticks_usec(), _sequence]
	snapshot = amount
	if not provider.showOffline(pending):
		clear()
		return false
	notify()
	return true

func confirm(token: String) -> void:
	if token != pending or not busy():
		return
	var base := snapshot
	clear()
	earned.emit(base)
	notify()

func dismissed(token: String) -> void:
	if token == pending and busy():
		clear()
		notify()

func clear() -> void:
	pending = ""
	snapshot = null

func notify() -> void:
	availability_changed.emit()
