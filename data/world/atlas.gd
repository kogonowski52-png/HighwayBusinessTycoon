extends RefCounted

const Tropical = preload("res://data/world/frontier/tropical.gd")

const RouteSixtySix = preload("res://data/world/frontier/route66.gd")

const Harbor = preload("res://data/world/frontier/harbor.gd")

const Luxury = preload("res://data/world/frontier/luxury.gd")

const Japan = preload("res://data/world/frontier/japan.gd")

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
	"tropical": Tropical.ATLAS,
	"route66": RouteSixtySix.ATLAS,
	"harbor": Harbor.ATLAS,
	"luxury": Luxury.ATLAS,
	"japan": Japan.ATLAS,
}

const EXPANSION_CHAPTER := {
	"tropical": {"pl": "Tropical Island", "en": "Tropical Island", "area": "Palmwater", "position": Vector2(.20, .68), "color": "#5cae95"},
	"route66": {"pl": "Route 66", "en": "Route 66", "area": "Copper Spur", "position": Vector2(.20, .25), "color": "#c17d55"},
	"harbor": {"pl": "Industrial Harbor", "en": "Industrial Harbor", "area": "Breakwater", "position": Vector2(.51, .69), "color": "#72969f"},
	"luxury": {"pl": "Luxury City", "en": "Luxury City", "area": "Gilded Mile", "position": Vector2(.51, .26), "color": "#b9938f"},
	"japan": {"pl": "Japan Highway", "en": "Japan Highway", "area": "Akari Junction", "position": Vector2(.81, .68), "color": "#a692b6"},
	"wilderness": {"pl": "Northern Wilderness", "en": "Northern Wilderness", "area": "Timberline", "position": Vector2(.81, .24), "color": "#92ab9b"},
}

const STAMPS := {
	"north": ["trail", "meridian", "cargo"],
	"desert": ["mesa", "atlas", "kestrel"],
	"valley": ["pine", "post", "parcel"],
	"alpine": ["horizon", "trail", "summit"],
	"ocean": ["vela", "coast", "regency"],
	"metro": ["atlas", "pulse", "orion"],
	"tropical": Tropical.STAMPS,
	"route66": RouteSixtySix.STAMPS,
	"harbor": Harbor.STAMPS,
	"luxury": Luxury.STAMPS,
	"japan": Japan.STAMPS,
}

static func location_name(id: String, language: String) -> String:
	var item := destination(id)
	return item.en if language == "en" else item.pl

static func destination(id: String) -> Dictionary:
	return DESTINATIONS.get(id, EXPANSION_CHAPTER.get(id, {}))

static func chapter_routes(expansion: bool) -> Array:
	return EXPANSION_CHAPTER.keys() if expansion else DESTINATIONS.keys().filter(
		func(id: String) -> bool: return not EXPANSION_CHAPTER.has(id))
