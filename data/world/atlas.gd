extends RefCounted

const DESTINATIONS := {
	"north": {"pl": "Stacja Północ", "en": "North Station", "area": "Trasa 17", "position": Vector2(.30, .29),
		"color": "#7ea17a", "scene": "res://scenes/world/roadside.tscn", "cost": 0, "fuel": 0, "rep": 0},
	"desert": {"pl": "Desert Highway", "en": "Desert Highway", "area": "Copper Mile", "position": Vector2(.33, .74),
		"color": "#d79058", "scene": "res://scenes/world/desert_highway.tscn", "cost": 670, "fuel": 3, "rep": 6},
	"valley": {"pl": "Green Valley", "en": "Green Valley", "position": Vector2(.53, .53), "color": "#78a675"},
	"alpine": {"pl": "Alpine Pass", "en": "Alpine Pass", "position": Vector2(.54, .19), "color": "#a9cacc"},
	"ocean": {"pl": "Ocean Coast", "en": "Ocean Coast", "position": Vector2(.77, .73), "color": "#5d9da4"},
	"metro": {"pl": "Metro City", "en": "Metro City", "position": Vector2(.80, .38), "color": "#b99b8b"},
}

static func location_name(id: String, language: String) -> String:
	var item: Dictionary = DESTINATIONS[id]
	return item.en if language == "en" else item.pl
