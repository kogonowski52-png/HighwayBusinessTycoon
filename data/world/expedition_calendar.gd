extends RefCounted

const START := 1795392000 # 2026-11-23 00:00 UTC
const DAY := 86_400
const WEEK := 7 * DAY
const MODELS := {
	"snow": "summit", "holiday": "coast", "sport": "kestrel",
	"truck": "atlas", "summer": "orion", "green": "pulse",
	"supercar_run": "onyx", "island_week": "sunray", "logistics_week": "container",
	"akari_matsuri": "akari", "classic_rally": "velvet", "timber_convoy": "timber",
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
	{"id": "supercar_run", "days": 5, "guest": "vip", "weather": "clear", "tint": "#ab789e",
		"tasks": [["sports", 9], ["vip", 11], ["special", 5]], "cash": 12800, "diamond": 9},
	{"id": "island_week", "days": 5, "guest": "tourist", "weather": "clear", "tint": "#74bda5",
		"tasks": [["rentals", 7], ["stay", 8], ["special", 5]], "cash": 11200, "diamond": 8},
	{"id": "logistics_week", "days": 5, "guest": "trucker", "weather": "cloud", "tint": "#7db6bf",
		"tasks": [["deliveries", 18], ["trucks", 12], ["special", 6]], "cash": 16700, "diamond": 10},
	{"id": "akari_matsuri", "days": 5, "guest": "local", "weather": "clear", "tint": "#c18eae",
		"tasks": [["tuning", 8], ["charged", 6], ["special", 5]], "cash": 17200, "diamond": 10},
	{"id": "classic_rally", "days": 5, "guest": "traveler", "weather": "wind", "tint": "#dfa16b",
		"tasks": [["restorations", 7], ["food", 9], ["special", 5]], "cash": 14100, "diamond": 9},
	{"id": "timber_convoy", "days": 5, "guest": "trucker", "weather": "snow", "tint": "#a0bec4",
		"tasks": [["logging", 11], ["trucks", 16], ["special", 6]], "cash": 22500, "diamond": 11},
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

const ORIGINAL_SEASONS := 6
const COSMETICS := {"decor": ["snow", "holiday", "summer", "green", "island_week", "akari_matsuri", "logistics_week", "timber_convoy"],
	"signs": ["sport", "truck", "supercar_run", "classic_rally"], "facades": ["beacon", "copper_arch"]}

static func event_at(clock: int, retained := "") -> Dictionary:
	var shift := maxi(0, clock - START)
	@warning_ignore("integer_division")
	var index := shift / WEEK
	var season := rotation(index, retained).duplicate()
	season["index"] = index
	season["begins"] = START + index * WEEK
	season["ends"] = season.begins + season.days * DAY
	season["live"] = clock >= season.begins and clock < season.ends
	season["model"] = MODELS[season.id]
	return season

static func rotation(index: int, retained := "") -> Dictionary:
	if not retained.is_empty():
		for slot: Dictionary in SEASONS:
			if slot.id == retained:
				return slot
	return SEASONS[index % SEASONS.size()]
