extends RefCounted

const START := 1795392000 # 2026-11-23 00:00 UTC
const DAY := 86_400
const WEEK := 7 * DAY
const MODELS := {
	"snow": "summit", "holiday": "coast", "sport": "kestrel",
	"truck": "atlas", "summer": "orion", "green": "pulse",
}

# Each week has five playable days and two days for the summary.
const SEASONS := [
	{"id": "snow", "days": 5, "guest": "family", "weather": "snow", "tint": "#9ec3ce",
		"tasks": [["fuel", 5], ["repairs", 4], ["special", 3]], "cash": 480, "diamond": 4},
	{"id": "holiday", "days": 5, "guest": "family", "weather": "snow", "tint": "#d08074",
		"tasks": [["visits", 9], ["food", 5], ["special", 3]], "cash": 540, "diamond": 5},
	{"id": "sport", "days": 5, "guest": "local", "weather": "clear", "tint": "#e09859",
		"tasks": [["sports", 5], ["vip", 3], ["special", 5]], "cash": 690, "diamond": 5},
	{"id": "truck", "days": 5, "guest": "trucker", "weather": "haze", "tint": "#c8ac71",
		"tasks": [["trucks", 6], ["liters", 240], ["special", 4]], "cash": 760, "diamond": 6},
	{"id": "summer", "days": 5, "guest": "vip", "weather": "clear", "tint": "#e5ac6f",
		"tasks": [["stay", 4], ["food", 6], ["special", 4]], "cash": 810, "diamond": 6},
	{"id": "green", "days": 5, "guest": "electric", "weather": "rain", "tint": "#8cbd98",
		"tasks": [["charged", 4], ["clean", 6], ["special", 4]], "cash": 960, "diamond": 7},
]

const CONTRACTS := [
	{"id": "trucks", "goal": 8, "seconds": 1200, "cash": 970, "diamond": 2, "tier": 2},
	{"id": "liters", "goal": 160, "seconds": 600, "cash": 320, "diamond": 1, "tier": 1},
	{"id": "vip", "goal": 5, "seconds": 1500, "cash": 850, "diamond": 2, "tier": 2},
	{"id": "repairs", "goal": 8, "seconds": 1800, "cash": 1350, "diamond": 3, "tier": 3},
	{"id": "deliveries", "goal": 2, "seconds": 1500, "cash": 1000, "diamond": 2, "tier": 2},
	{"id": "turnover", "goal": 2300, "seconds": 2100, "cash": 1550, "diamond": 3, "tier": 3},
	{"id": "building", "goal": 6, "seconds": 900, "cash": 520, "diamond": 1, "tier": 1},
]

const COSMETICS := {"decor": ["snow", "holiday", "summer", "green"], "signs": ["sport", "truck"], "facades": ["beacon", "copper_arch"]}

static func event_at(clock: int) -> Dictionary:
	var shift := maxi(0, clock - START)
	@warning_ignore("integer_division")
	var index := shift / WEEK
	var season: Dictionary = SEASONS[index % SEASONS.size()].duplicate()
	season["index"] = index
	season["begins"] = START + index * WEEK
	season["ends"] = season.begins + season.days * DAY
	season["live"] = clock >= season.begins and clock < season.ends
	season["model"] = MODELS[season.id]
	return season
