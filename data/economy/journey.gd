extends RefCounted

const LEVEL_XP := [0, 10, 28, 56, 100, 175, 270, 405, 590, 815, 1100, 1475, 1950, 2550, 3300, 4300,
	5600, 7350, 9500, 12200]

# Chapters follow the original complex and its three extensions. Values are
# facility, player level, first sales target, and the disclosed specialist card.
const CHAPTERS := [
	["fuel", 1, 8, ""], ["market", 2, 5, "nina"], ["parking", 3, 5, "tom"],
	["wash", 4, 6, "zofia"], ["truck", 4, 5, "arun"], ["workshop", 5, 5, "ben"],
	["restaurant", 5, 5, "lena"], ["tires", 6, 5, "olu"], ["truck_park", 6, 5, "alina"],
	["motel", 7, 5, "vera"], ["charge", 8, 5, "jo"],
]

static var catalog: Dictionary

static func items(profiles: Dictionary) -> Dictionary:
	if not catalog.is_empty():
		return catalog
	var index := 0
	for chapter in CHAPTERS:
		var site: String = chapter[0]
		var service: HbtService = profiles[site]
		var small: int = chapter[2]
		var card := {"diamond": 2} if chapter[3].is_empty() else {"card": chapter[3]}
		var rules := [
			["open", "site_level", 1, {"cash": service.base_price}, 0],
			["visits", "site_sales", small, {"cash": service.base_price * 2}, 0],
			["crew", "site_staff", 1, {"diamond": 1}, 0],
			["specialist", "site_sales", small * (3 if index < 5 else 2), card, 1],
			["turnover", "site_revenue", service.base_price * 27, {"cash": service.base_price * 6}, 1],
			["refit", "site_level", 8, {"diamond": 2}, 1],
			["training", "site_training", 2, {"cash": service.wage * 2}, 2],
			["expansion", "site_level", 35, {"diamond": 3}, 2],
			["network", "reputation" if index % 2 == 0 else "manager_ranks",
				42 + index * 17 if index % 2 == 0 else 2 + index / 2, {"diamond": 3, "event": 4}, 2],
			["landmark", "site_level", 90, {"diamond": 6, "event": 10}, 3],
		]
		for rule in rules:
			var id := "route_%s_%s" % [site, rule[0]]
			catalog[id] = {"id": id, "site": site, "rank": chapter[1], "counter": rule[1],
				"goal": int(rule[2]), "reward": rule[3], "wave": rule[4]}
		index += 1
	return catalog

static func level_for(xp: int) -> int:
	for index in range(LEVEL_XP.size() - 1, 0, -1):
		if xp >= LEVEL_XP[index]:
			return index + 1
	return 1
