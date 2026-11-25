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
}

static func value(id: String, rank: int) -> int:
	var card: Dictionary = ROSTER[id]
	if card.skill == "collect":
		return card.value
	return floori(card.value * (1.0 + 0.2 * (rank - 1)))
