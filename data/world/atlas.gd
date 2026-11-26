extends RefCounted

const DESTINATIONS := {
	"north": {"pl": "Stacja Północ", "en": "Northpoint Station", "area": "Trasa 17", "position": Vector2(.30, .29),
		"color": "#7ea17a", "scene": "res://scenes/world/roadside.tscn", "cost": 0, "fuel": 0, "rep": 0},
	"desert": {"pl": "Desert Highway", "en": "Desert Highway", "area": "Copper Mile", "position": Vector2(.33, .74),
		"color": "#d79058", "scene": "res://scenes/world/desert_highway.tscn", "from": "north", "cost": 670, "fuel": 3, "rep": 6},
	"valley": {"pl": "Green Valley", "en": "Green Valley", "position": Vector2(.53, .53), "color": "#78a675", "area": "Riverbend",
		"scene": "res://scenes/world/valley.tscn", "from": "desert", "cost": 4250, "fuel": 6, "rep": 25, "gate": "cafe", "tier": 3},
	"alpine": {"pl": "Alpine Pass", "en": "Alpine Pass", "position": Vector2(.54, .19), "color": "#a9cacc", "area": "Snowline",
		"scene": "res://scenes/world/alpine.tscn", "from": "valley", "cost": 10700, "fuel": 7, "rep": 35, "gate": "workshop", "tier": 3},
	"ocean": {"pl": "Ocean Coast", "en": "Ocean Coast", "position": Vector2(.77, .73), "color": "#5d9da4", "area": "Coral Key",
		"scene": "res://scenes/world/ocean.tscn", "from": "alpine", "cost": 17900, "fuel": 8, "rep": 45, "gate": "motel", "tier": 3},
	"metro": {"pl": "Metro City", "en": "Metro City", "position": Vector2(.80, .38), "color": "#b99b8b", "area": "Meridian Junction",
		"scene": "res://scenes/world/metro.tscn", "from": "ocean", "cost": 27500, "fuel": 9, "rep": 65, "gate": "vip_park", "tier": 3},
}

const STAMPS := {
	"north": ["trail", "meridian", "cargo"],
	"desert": ["mesa", "atlas", "kestrel"],
	"valley": ["pine", "post", "parcel"],
	"alpine": ["horizon", "trail", "summit"],
	"ocean": ["vela", "coast", "regency"],
	"metro": ["atlas", "pulse", "orion"],
}

static func location_name(id: String, language: String) -> String:
	var item: Dictionary = DESTINATIONS[id]
	return item.en if language == "en" else item.pl
