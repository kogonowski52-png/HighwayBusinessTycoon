extends RefCounted

# The spending limit is a percentage of that customer's strongest available offer.
# Higher levels increase nominal budgets with the local price index.
const PROFILES := {
	"local": {"weight": 29, "budget": Vector2i(93, 138), "patience": 42.0, "tip": 100,
		"rep": 1, "car": "sprint", "services": {"fuel": 65, "market": 36, "wash": 23, "parking": 10, "workshop": 12, "tires": 25}},
	"traveler": {"weight": 22, "budget": Vector2i(97, 153), "patience": 33.0, "tip": 105,
		"rep": 1, "car": "trail", "services": {"fuel": 54, "market": 22, "parking": 20, "restaurant": 28, "motel": 16, "tires": 17}},
	"trucker": {"weight": 14, "budget": Vector2i(125, 161), "patience": 64.0, "tip": 108,
		"rep": 2, "car": "cargo", "services": {"truck": 73, "truck_park": 62}},
	"tourist": {"weight": 13, "budget": Vector2i(86, 148), "patience": 48.0, "tip": 110,
		"rep": 2, "car": "coast", "services": {"parking": 48, "market": 21, "restaurant": 31, "motel": 37, "fuel": 21}},
	"family": {"weight": 13, "budget": Vector2i(120, 158), "patience": 55.0, "tip": 106,
		"rep": 2, "car": "pine", "services": {"market": 37, "parking": 27, "fuel": 30, "restaurant": 38, "motel": 23, "wash": 13}},
	"business": {"weight": 8, "budget": Vector2i(135, 174), "patience": 28.0, "tip": 121,
		"rep": 2, "car": "meridian", "services": {"fuel": 38, "wash": 34, "restaurant": 21, "motel": 23, "workshop": 18, "tires": 21}},
	"vip": {"weight": 5, "budget": Vector2i(160, 218), "patience": 23.0, "tip": 145,
		"rep": 3, "car": "orion", "minimum_rep": 5,
		"services": {"wash": 47, "restaurant": 42, "motel": 37, "workshop": 26, "fuel": 13}},
	"electric": {"weight": 16, "budget": Vector2i(134, 184), "patience": 56.0, "tip": 114,
		"rep": 2, "car": "pulse", "minimum_rep": 38,
		"services": {"charge": 95, "market": 21, "restaurant": 17, "parking": 19, "wash": 13}},
}
