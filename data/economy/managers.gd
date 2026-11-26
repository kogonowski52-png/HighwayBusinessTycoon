extends RefCounted

const MAX_RANK := 5
const RANK_PRICES := [2, 4, 7, 11]
const RANK_LEVELS := [3, 5, 8, 11]

const ROSTER := {
	"ada": {"name": "Ada Nowak", "skill": "collect", "value": 1, "rarity": "common", "site": ""},
	"iga": {"name": "Iga Brooks", "skill": "revenue", "value": 1800, "rarity": "rare", "site": ""},
	"maks": {"name": "Maks Chen", "skill": "speed", "value": 2000, "rarity": "rare", "site": ""},
	"mira": {"name": "Mira Rossi", "skill": "traffic", "value": 2500, "rarity": "epic", "site": ""},
	"leon": {"name": "Leon Silva", "skill": "discount", "value": 1200, "rarity": "epic", "site": ""},
	"nina": {"name": "Nina Zielińska", "skill": "revenue", "value": 2200, "rarity": "common", "site": "market"},
	"tom": {"name": "Tom Sato", "skill": "speed", "value": 1900, "rarity": "common", "site": "parking"},
	"zofia": {"name": "Zofia Krawiec", "skill": "speed", "value": 2900, "rarity": "rare", "site": "wash"},
	"arun": {"name": "Arun Patel", "skill": "revenue", "value": 2700, "rarity": "rare", "site": "truck"},
	"lena": {"name": "Lena Martín", "skill": "collect", "value": 1, "rarity": "epic", "site": "restaurant"},
	"ben": {"name": "Ben Keller", "skill": "discount", "value": 2000, "rarity": "rare", "site": "workshop"},
	"olu": {"name": "Olu Adeyemi", "skill": "automation", "value": 1750, "rarity": "epic", "site": "tires"},
	"alina": {"name": "Alina Ko", "skill": "offline", "value": 3300, "rarity": "epic", "site": "truck_park"},
	"vera": {"name": "Vera Petrescu", "skill": "offline", "value": 2700, "rarity": "legendary", "site": ""},
	"jo": {"name": "Jo Haddad", "skill": "automation", "value": 2650, "rarity": "legendary", "site": "charge"},
	"tess": {"name": "Tess Wójcik", "skill": "revenue", "value": 2500, "rarity": "rare", "site": "restaurant", "district": "valley"},
	"roan": {"name": "Roan Aebi", "skill": "speed", "value": 2900, "rarity": "epic", "site": "motel", "district": "alpine"},
	"ines": {"name": "Inés Duarte", "skill": "collect", "value": 1, "rarity": "rare", "site": "vip_park", "district": "ocean"},
	"dev": {"name": "Dev Griffin", "skill": "automation", "value": 2400, "rarity": "legendary", "site": "logistics", "district": "metro"},
	"mila": {"name": "Mila Sokol", "skill": "offline", "value": 3200, "rarity": "epic", "site": "warehouse", "district": "metro"},
	"ren": {"name": "Ren Okafor", "skill": "revenue", "value": 2900, "rarity": "epic", "site": "mall", "district": "metro"},
	"ellis": {"name": "Ellis Park", "skill": "discount", "value": 2000, "rarity": "rare", "site": "dealership", "district": "metro"},
	"noa": {"name": "Noa da Costa", "skill": "traffic", "value": 2450, "rarity": "epic", "site": "resort", "district": "tropical"},
	"talia": {"name": "Talia Baptiste", "skill": "collect", "value": 1, "rarity": "rare", "site": "rent", "district": "tropical"},
	"mona": {"name": "Mona Reyes", "skill": "discount", "value": 2050, "rarity": "rare", "site": "restoration", "district": "route66"},
	"iman": {"name": "Iman Nasser", "skill": "automation", "value": 2840, "rarity": "epic", "site": "terminal", "district": "harbor"},
	"hugo": {"name": "Hugo Mercer", "skill": "offline", "value": 3200, "rarity": "rare", "site": "coldstore", "district": "harbor"},
	"selene": {"name": "Selene Moreau", "skill": "revenue", "value": 3450, "rarity": "legendary", "site": "tuning", "district": "luxury"},
	"akio": {"name": "Akio Mori", "skill": "speed", "value": 2700, "rarity": "epic", "site": "tuning", "district": "japan"},
	"soren": {"name": "Søren Vik", "skill": "offline", "value": 3650, "rarity": "epic", "site": "logging", "district": "wilderness"},
	"sana": {"name": "Sana Ito", "skill": "revenue", "value": 2000, "rarity": "epic", "site": "", "source": "store"},
	"reese": {"name": "Reese Morgan", "skill": "speed", "value": 2000, "rarity": "rare", "site": "", "source": "store"},
	"rhea": {"name": "Rhea Foster", "skill": "offline", "value": 2200, "rarity": "legendary", "site": "", "source": "pass"},
}

static func value(id: String, rank: int) -> int:
	var card: Dictionary = ROSTER[id]
	if card.skill == "collect":
		return card.value
	return floori(card.value * (1.0 + 0.2 * (rank - 1)))

static func catalog(district: String, optional := true) -> Array:
	return ROSTER.keys().filter(func(id: String) -> bool:
		return (optional or not ROSTER[id].has("source")) and (not ROSTER[id].has("district") or ROSTER[id].district == district))
