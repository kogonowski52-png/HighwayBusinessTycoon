extends RefCounted
## Test boundary only. This script is excluded from Android exports.

signal reward_availability
signal reward_earned(ticket: String)
signal reward_closed(ticket: String)
signal ad_shown(slot: String)
signal break_shown(ticket: String)
signal break_closed(ticket: String)

var enabled := true
var ready := {}
var loads := true
var ticket := ""
var screens := 0

func adsConfigured() -> bool:
	return enabled

func privacyOptionsRequired() -> bool:
	return false

func rewardReady(slot: String) -> bool:
	return bool(ready.get(slot, false))

func rewardLoading(_slot: String) -> bool:
	return false

func prepareReward(slot: String) -> void:
	ready[slot] = loads
	reward_availability.emit()

func showRewarded(slot: String, request: String) -> bool:
	if not rewardReady(slot):
		return false
	ready[slot] = false
	ticket = request
	screens += 1
	call_deferred("emit_signal", "ad_shown", slot)
	return true

func finish(earned: bool, duplicate := false) -> void:
	var prior := ticket
	if earned:
		reward_earned.emit(prior)
		if duplicate:
			reward_earned.emit(prior)
	reward_closed.emit(prior)
	ticket = ""

func breakReady() -> bool:
	return bool(ready.get("interstitial", false))

func prepareBreak() -> void:
	ready["interstitial"] = loads

func showBreak(request: String) -> bool:
	if not breakReady():
		return false
	ready["interstitial"] = false
	screens += 1
	ticket = request
	return true
