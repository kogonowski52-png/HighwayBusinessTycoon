extends RefCounted

const World = preload("res://data/economy/frontier_goals.gd")

# Each entry is visible before it is earned. Missed dates leave the calendar at
# the same slot, and the next cycle starts on the following UTC day.
const CALENDAR := [
	["cash", 70], ["diamond", 2], ["reputation", 4], ["voucher", 1], ["cash", 150],
	["diamond", 3], ["card", "nina"], ["cash", 240], ["reputation", 8], ["diamond", 4],
	["voucher", 1], ["cash", 350], ["reputation", 12], ["card", "tom"], ["cash", 500],
	["diamond", 5], ["voucher", 1], ["reputation", 16], ["cash", 700], ["diamond", 6],
	["card", "zofia"], ["cash", 950], ["reputation", 22], ["voucher", 2], ["diamond", 8],
	["cash", 1400], ["reputation", 30], ["diamond", 10], ["voucher", 2], ["card", "vera"],
]

const GROUPS := [
	["customers", [10, 50, 200, 800, 2500]],
	["gross", [500, 5000, 50000, 1000000, 1000000000]],
	["upgrades", [5, 25, 100, 350, 800]],
	["locations", [2, 4, 6, 9, 11]],
	["staff", [1, 4, 8, 16, 26]],
	["training", [1, 5, 16, 45, 100]],
	["reputation", [25, 100, 500, 1600, 4000]],
	["cards", [1, 3, 6, 10, 15]],
	["manager_ranks", [1, 3, 6, 12, 22]],
	["calendar", [1, 5, 10, 20, 30]],
]
const ROMAN := ["I", "II", "III", "IV", "V"]
const MANAGER_XP := [0, 15, 45, 120, 300, 650]
const DUPLICATE_DIAMONDS := 6

static var collection: Dictionary = build_collection()

static func build_collection() -> Dictionary:
	var result := {}
	for index in range(GROUPS.size()):
		var group: Array = GROUPS[index]
		for tier in range(group[1].size()):
			var id := "%s_%d" % [group[0], tier + 1]
			result[id] = {"id": id, "group": group[0], "tier": tier, "goal": group[1][tier],
				"reward": 2 + tier * 2, "icon": "res://assets/ui/presentation/medals/%s.png" % id}
	for district: String in World.AWARDS:
		for item: Array in World.AWARDS[district]:
			result[item[0]] = {"id": item[0], "group": "frontier_medals", "district": district,
				"pl": item[1], "en": item[2], "site": item[3], "counter": item[4], "tier": 0, "goal": item[5],
				"reward": item[6], "icon": "res://assets/ui/presentation/medals/%s_3.png" % item[7]}
	return result

static func track_count(district: String) -> int:
	return GROUPS.size() + int(World.AWARDS.has(district))

static func xp_band(total: int) -> Dictionary:
	for index in range(1, MANAGER_XP.size()):
		var goal: int = MANAGER_XP[index]
		if total < goal:
			var previous: int = MANAGER_XP[index - 1]
			return {"index": index, "have": total - previous, "goal": goal - previous, "maxed": false}
	return {"index": MANAGER_XP.size(), "have": 1, "goal": 1, "maxed": true}
