extends RefCounted

const MANAGERS := preload("res://data/economy/managers.gd").ROSTER

const MILESTONES := [
	{"id": "first", "group": "mission", "counter": "customers", "goal": 1, "reward": {"cash": 40}},
	{"id": "upgrade", "group": "mission", "counter": "fuel_level", "goal": 2, "reward": {"cash": 65, "diamond": 2}},
	{"id": "crew", "group": "mission", "counter": "staff", "goal": 1, "reward": {"card": "ada", "cash": 45}},
	{"id": "expansion", "group": "mission", "counter": "locations", "goal": 3, "reward": {"card": "iga", "diamond": 2}},
	{"id": "apprentice", "group": "mission", "counter": "trained", "goal": 1, "reward": {"cash": 320, "diamond": 3}},
	{"id": "promotion", "group": "mission", "counter": "promoted", "goal": 1, "reward": {"cash": 1250, "diamond": 4}},
	{"id": "reputation", "group": "achievement", "counter": "reputation", "goal": 45, "reward": {"card": "maks", "cash": 400}},
	{"id": "hundred", "group": "achievement", "counter": "customers", "goal": 100, "reward": {"card": "leon", "cash": 900}},
	{"id": "network", "group": "achievement", "counter": "locations", "goal": 8, "reward": {"diamond": 12, "event": 10}},
	{"id": "hundred_levels", "group": "achievement", "counter": "best_level", "goal": 100, "reward": {"diamond": 30, "event": 25}},
]

const EVENTS := [
	{"goal": 16, "reward": 7, "services": ["fuel", "truck", "parking"], "name_pl": "Ruch na trasie", "name_en": "Highway rush"},
	{"goal": 12, "reward": 8, "services": ["market", "restaurant", "motel"], "name_pl": "Postój w podróży", "name_en": "Travel stop"},
	{"goal": 14, "reward": 8, "services": ["wash", "workshop", "fuel"], "name_pl": "Czysta trasa", "name_en": "Clean highway"},
]

const EVENT_CARD_COST := 12
const EVENT_DIAMOND_COST := 6
const EVENT_DIAMONDS := 3
