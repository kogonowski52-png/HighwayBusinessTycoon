extends RefCounted
## Test boundary only. This script is excluded from Android exports.

signal reward_availability
signal reward_earned(ticket: String)
signal reward_closed(ticket: String)
signal reward_show_failed(ticket: String)
signal ad_shown(slot: String)
signal break_shown(ticket: String)
signal break_closed(ticket: String)

var enabled := true
var ready := {}
var loads := true
var auto_complete := true
var requests := {}
var reloading := {}
var opened_slot := ""
var reserve_only := false
var ticket := ""
var screens := 0

func adsConfigured() -> bool:
	return enabled

func privacyOptionsRequired() -> bool:
	return false

func rewardReady(slot: String) -> bool:
	return bool(ready.get(slot, false))

func rewardLoading(slot: String) -> bool:
	return requests.has(slot)

func adPlacementState(slot: String) -> String:
	if not ticket.is_empty() and slot == opened_slot:
		return "showing"
	if rewardReady(slot):
		return "ready"
	if rewardLoading(slot):
		return "reloading" if reloading.has(slot) else "loading"
	return "unavailable"

func preloadAds() -> void:
	for slot in ["boost", "offline", "bonus", "interstitial"]:
		prepareReward(slot)

func prepareReward(slot: String) -> void:
	if rewardReady(slot) or rewardLoading(slot):
		return
	requests[slot] = true
	if auto_complete:
		complete(slot, loads)

func complete(slot: String, successful: bool) -> void:
	requests.erase(slot)
	ready[slot] = successful
	reward_availability.emit()

func showRewarded(slot: String, request: String) -> bool:
	if not rewardReady(slot):
		return false
	ready[slot] = false
	ticket = request
	opened_slot = slot
	if not reserve_only:
		screens += 1
		call_deferred("emit_signal", "ad_shown", slot)
	return true

func cancelRewarded(request: String) -> bool:
	if request != ticket or not reserve_only:
		return false
	ready[opened_slot] = true
	ticket = ""
	opened_slot = ""
	return true

func finish(earned: bool, duplicate := false) -> void:
	var prior := ticket
	var slot := opened_slot
	if earned:
		reward_earned.emit(prior)
		if duplicate:
			reward_earned.emit(prior)
	reward_closed.emit(prior)
	ticket = ""
	opened_slot = ""
	if not slot.is_empty():
		reloading[slot] = true
		prepareReward(slot)

func fail_show() -> void:
	reward_show_failed.emit(ticket)
	finish(false)

func breakReady() -> bool:
	return bool(ready.get("interstitial", false))

func prepareBreak() -> void:
	prepareReward("interstitial")

func showBreak(request: String) -> bool:
	if not breakReady():
		return false
	ready["interstitial"] = false
	screens += 1
	ticket = request
	return true
