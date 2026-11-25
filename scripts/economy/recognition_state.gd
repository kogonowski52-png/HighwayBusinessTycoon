extends RefCounted

const Data = preload("res://data/economy/recognition.gd")
const Managers = preload("res://data/economy/managers.gd")

var last_day := -1
var daily_count := 0
var vouchers := 0
var achievement_claimed: Dictionary = {}
var mentor_xp: Dictionary = {}

func restore(data: Dictionary) -> void:
	last_day = clampi(int(data.get("last_day", -1)), -1, 500000000)
	daily_count = clampi(int(data.get("daily_count", 0)), 0, 1000000)
	vouchers = clampi(int(data.get("vouchers", 0)), 0, 1000000)
	var milestones: Variant = data.get("achievement_claimed", {})
	if milestones is Dictionary:
		for id in milestones:
			if Data.collection.has(id) and milestones[id] == true:
				achievement_claimed[id] = true
	var coaches: Variant = data.get("mentor_xp", {})
	if coaches is Dictionary:
		for id in Managers.ROSTER:
			if coaches.has(id):
				mentor_xp[id] = clampi(int(coaches[id]), 0, 100000)

func snapshot() -> Dictionary:
	return {"last_day": last_day, "daily_count": daily_count, "vouchers": vouchers,
		"achievement_claimed": achievement_claimed, "mentor_xp": mentor_xp}

func slot() -> int:
	return daily_count % Data.CALENDAR.size()

func is_available(day: int) -> bool:
	return day >= 0 and day > last_day

func record_visit(site: String, equipped: Array[String]) -> void:
	for id in equipped:
		var target: String = Managers.ROSTER[id].site
		if target.is_empty() or target == site:
			mentor_xp[id] = mini(100000, mentor_xp.get(id, 0) + 1)
