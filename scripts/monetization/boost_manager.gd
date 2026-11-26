class_name HbtBoost
extends RefCounted
## Half-open UTC intervals shared by all regional saves.

const Policy := preload("res://data/monetization/config.gd")

var clock := 0
var windows: Array[PackedInt64Array] = []
var anchor_ms := -1
var anchor_second := 0
var boot := -1
var boot_tick := -1

var native_seen_ms := -1
var native_base_ms := -1

func observe_device(wall: int, refresh_native := true) -> int:
	var local := Time.get_ticks_msec()
	if not refresh_native and native_seen_ms >= 0 and local - native_seen_ms < 1000:
		return observe_boot(wall, native_base_ms + local - native_seen_ms, boot)
	if Engine.has_singleton("HighwayRewarded"):
		var bridge := Engine.get_singleton("HighwayRewarded")
		var sample := str(bridge.clockSample()).split(":")
		if sample.size() == 2 and sample[0].is_valid_int() and sample[1].is_valid_int():
			var id := sample[0].to_int()
			var ticks := sample[1].to_int()
			if id >= 0 and ticks >= 0:
				native_seen_ms = local
				# A millisecond rounding difference is not a second boot.
				if boot == id:
					ticks = maxi(ticks, boot_tick)
				native_base_ms = ticks
				return observe_boot(wall, ticks, id)
	return advance(wall, local)

func observe_boot(wall: int, ticks: int, id: int) -> int:
	if boot != id or ticks < boot_tick:
		anchor_ms = -1
	elif anchor_ms < 0 and boot_tick >= 0:
		anchor_ms = boot_tick
		anchor_second = clock
	boot = id
	boot_tick = ticks
	return advance(wall, ticks)

func advance(wall: int, ticks := -1) -> int:
	if ticks >= 0 and anchor_ms < 0:
		anchor_ms = ticks
		anchor_second = maxi(clock, wall)
	if anchor_ms >= 0 and ticks >= anchor_ms:
		var elapsed := floori((ticks - anchor_ms) / 1000.0)
		var predicted := anchor_second + elapsed
		if wall > predicted:
			anchor_second = wall
			anchor_ms = ticks
			predicted = wall
		wall = predicted
	clock = maxi(clock, wall)
	return clock

func remaining(now: int) -> int:
	if windows.is_empty() or now < windows.back()[0]:
		return 0
	return maxi(0, windows.back()[1] - now)

func earning(now: int) -> bool:
	return remaining(now) > 0

func can_extend(now: int) -> bool:
	return remaining(maxi(clock, now)) <= Policy.CAP_SECONDS - Policy.STEP_SECONDS

func extend_confirmed(now: int) -> bool:
	now = advance(now)
	if not can_extend(now):
		return false
	var left := remaining(now)
	if left > 0:
		var existing: PackedInt64Array = windows.back()
		existing[1] += Policy.STEP_SECONDS
		windows[-1] = existing
	else:
		windows.append(PackedInt64Array([now, now + Policy.STEP_SECONDS]))
	return true

func segments(start: int, end: int) -> Array[PackedInt64Array]:
	var result: Array[PackedInt64Array] = []
	for period in windows:
		if period[1] <= start:
			continue
		if period[0] >= end:
			break
		result.append(PackedInt64Array([maxi(start, period[0]), mini(end, period[1])]))
	return result

func prune(estate_ranges: Array[PackedInt64Array]) -> void:
	var relevant: Array[PackedInt64Array] = []
	for period in windows:
		if period[1] > clock or estate_ranges.any(func(span: PackedInt64Array) -> bool:
			return period[1] > span[0] and period[0] < span[1]):
			relevant.append(period)
	windows = relevant

func snapshot() -> Dictionary:
	var history: Array = []
	for interval in windows:
		history.append([interval[0], interval[1]])
	return {"clock": clock, "history": history, "boot": boot, "boot_tick": boot_tick}

func restore(data: Dictionary) -> void:
	clock = maxi(0, int(data.get("clock", 0)))
	anchor_ms = -1
	native_seen_ms = -1
	native_base_ms = -1
	boot = int(data.get("boot", -1))
	boot_tick = int(data.get("boot_tick", -1))
	windows.clear()
	var history: Variant = data.get("history")
	if not history is Array:
		return
	for pair in history:
		if not pair is Array or pair.size() != 2:
			continue
		var start := int(pair[0])
		var end := int(pair[1])
		if start <= 0 or start > clock or end <= start or end > clock + Policy.CAP_SECONDS:
			continue
		if not windows.is_empty() and start < windows.back()[1]:
			continue
		windows.append(PackedInt64Array([start, end]))
