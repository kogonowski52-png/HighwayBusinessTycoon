extends RefCounted
## Each row is a service plot with its model origin, route lane and bay spacing.

const LAYOUTS := {
	"valley": {
		"family": "valley", "center": Vector3(-8, 0, -2), "width": 34.0, "ambient": 15.5,
		"car": [Vector2(-55, 1), Vector2(-36, -1), Vector2(-24, -1), Vector2(-12, 4), Vector2(1, 4), Vector2(13, 0), Vector2(56, 0)],
		"queue": 28.0, "plots": {
			"fuel": [Vector2(-4, -6), "car", 4.1, 6.7],
			"restaurant": [Vector2(9, -9), "car", 4.1, 4.0],
			"workshop": [Vector2(-16, -8), "car", 4.1, 5.2],
			"market": [Vector2(-37, -11), "car", 4.3, 4.0],
		},
		"fleet": ["pine", "post", "loop", "range", "parcel", "crest", "summit", "trail", "brook", "courier", "cove"],
		"guests": {"local": "pine", "business": "post", "family": "parcel", "traveler": "range", "tourist": "crest", "vip": "meridian"},
		"weights": {"local": 1.8, "business": 1.5, "traveler": .75},
	},
	"alpine": {
		"family": "alpine", "center": Vector3(-7, 0, -2), "width": 35.0, "ambient": 14.5,
		"car": [Vector2(-54, -1), Vector2(-39, -1), Vector2(-27, 7), Vector2(-17, 5), Vector2(-9, -2), Vector2(4, -2), Vector2(14, 5), Vector2(26, 5), Vector2(35, 2), Vector2(57, 2)],
		"queue": 35.0, "plots": {
			"fuel": [Vector2(-4, -14), "car", 5.0, 6.5],
			"restaurant": [Vector2(16, -8), "car", 5.4, 7.0],
			"motel": [Vector2(-27, -6), "car", 6.2, 7.1],
			"parking": [Vector2(-42, -12), "car", 5.8, 4.0],
		},
		"fleet": ["horizon", "trail", "summit", "post", "pine", "kestrel", "range", "ridgeback", "sundown", "switchback"],
		"guests": {"tourist": "horizon", "family": "summit", "local": "trail", "traveler": "kestrel", "business": "post"},
		"weights": {"tourist": 2.5, "family": 1.4, "local": .72},
	},
	"ocean": {
		"family": "ocean", "center": Vector3(-3, 0, 1), "width": 36.0, "ambient": 15.25,
		"car": [Vector2(-53, 0), Vector2(-37, 2), Vector2(-27, 5), Vector2(-8, 5), Vector2(3, 1), Vector2(16, -1), Vector2(54, -1)],
		"queue": 30.0, "plots": {
			"fuel": [Vector2(1, -10), "car", 4.7, 6.2],
			"restaurant": [Vector2(-12, -8), "car", 4.4, 4.2],
			"motel": [Vector2(-26, -12), "car", 4.6, 4.3],
			"vip_park": [Vector2(16, -11), "car", 4.6, 4.0],
			"wash": [Vector2(-39, -10), "car", 4.3, 5.0],
		},
		"fleet": ["vela", "coast", "sprint", "regency", "meridian", "orion", "pulse", "arrow", "sable", "solstice"],
		"guests": {"vip": "vela", "tourist": "coast", "traveler": "sprint", "business": "regency", "family": "orion"},
		"weights": {"vip": 3.2, "tourist": 2.4, "local": .65},
	},
	"metro": {
		"family": "metro", "center": Vector3(0, 0, -12), "width": 42.0, "ambient": 12.8,
		"car": [Vector2(-58, 2), Vector2(-39, 2), Vector2(-28, 0), Vector2(20, 0), Vector2(33, 2), Vector2(62, 2)],
		"truck": [Vector2(-62, -27), Vector2(-39, -27), Vector2(-31, -24), Vector2(32, -24), Vector2(44, -27), Vector2(73, -27)],
		"queue": 36.0, "truck_queue": 46.0, "plots": {
			"fuel": [Vector2(0, -8.8), "car", 4.4, 6.0],
			"dealership": [Vector2(-27, -11), "car", 4.5, 4.3],
			"mall": [Vector2(15, -12), "car", 5.1, 4.4],
			"charge": [Vector2(-13, -10.5), "car", 4.2, 4.8],
			"logistics": [Vector2(-16, -40), "truck", 9.1, 6.4],
			"warehouse": [Vector2(11, -40), "truck", 9.8, 6.4],
			"truck_park": [Vector2(33, -40), "truck", 8.6, 5.9],
		},
		"fleet": ["cargo", "atlas", "pulse", "parcel", "regency", "orion", "sprint", "post", "vela", "meridian",
			"petrel", "courier", "solstice", "switchback"],
		"guests": {"business": "post", "vip": "regency", "family": "orion", "local": "meridian", "tourist": "sprint"},
		"weights": {"trucker": 2.9, "electric": 1.9, "business": 1.8},
	},
}

# id, names, base invoice, first improvement, duration, unlock, preceding
# service and tier, reputation, wage, bay thresholds, fleet, role and task.
const SERVICES := {
	"valley": [
		["fuel", "Paliwa Riverbend", "Riverbend Fuel", 78, 345, 3.4, 0, "", 0, 0, 158, [1, 15], "car", "attendant", "fuel"],
		["restaurant", "Jadalnia Orchard Table", "Orchard Table Diner", 125, 510, 4.3, 1100, "fuel", 3, 7, 250, [1, 18], "car", "server", "carry"],
		["workshop", "Warsztat Mill & Motor", "Mill & Motor Garage", 168, 650, 5.2, 2700, "restaurant", 3, 17, 345, [1, 20], "car", "mechanic", "repair"],
		["market", "Targ Greenbank", "Greenbank Market", 205, 780, 4.7, 5900, "workshop", 4, 27, 395, [1, 20], "car", "cashier", "cash"],
	],
	"alpine": [
		["fuel", "Paliwa Summit", "Summit Fuel", 119, 515, 3.7, 0, "", 0, 0, 220, [1, 16], "car", "attendant", "fuel"],
		["restaurant", "Schronisko Ember Hearth", "Ember Hearth Restaurant", 181, 728, 5.0, 1950, "fuel", 3, 9, 350, [1, 19], "car", "server", "carry"],
		["motel", "Hotel Snowline", "Snowline Lodge", 285, 1040, 6.4, 5400, "restaurant", 4, 19, 540, [1, 21, 45], "car", "manager", "service"],
		["parking", "Parking Glacier View", "Glacier View Parking", 220, 870, 4.6, 8300, "motel", 3, 29, 437, [1, 18], "car", "attendant", "service"],
	],
	"ocean": [
		["fuel", "Paliwa Blue Current", "Blue Current Fuel", 155, 700, 3.4, 0, "", 0, 0, 310, [1, 16], "car", "attendant", "fuel"],
		["restaurant", "Restauracja Tidal Room", "Tidal Room Dining", 261, 990, 5.3, 3100, "fuel", 3, 10, 500, [1, 18, 44], "car", "server", "carry"],
		["motel", "Motel Coral Key", "Coral Key Resort", 352, 1290, 6.5, 7300, "restaurant", 4, 21, 680, [1, 19, 45], "car", "manager", "service"],
		["vip_park", "Parking VIP Marina", "Marina VIP Parking", 280, 1000, 4.8, 11200, "motel", 3, 31, 620, [1, 18], "car", "attendant", "service"],
		["wash", "Myjnia Pearl Bay", "Pearl Bay Car Wash", 380, 1410, 5.7, 16200, "vip_park", 4, 42, 790, [1, 23], "car", "cleaner", "clean"],
	],
	"metro": [
		["fuel", "Paliwa Meridian", "Meridian Fuel", 220, 890, 3.7, 0, "", 0, 0, 445, [1, 16], "car", "attendant", "fuel"],
		["logistics", "Centrum logistyczne Meridian", "Meridian Freight Hub", 460, 1510, 6.5, 4200, "fuel", 3, 11, 810, [1, 18, 45], "truck", "attendant", "carry"],
		["warehouse", "Magazyn Junction", "Junction Warehouse", 570, 1870, 6.7, 9500, "logistics", 4, 22, 1030, [1, 20], "truck", "attendant", "carry"],
		["dealership", "Salon Apex Motors", "Apex Motors Showroom", 820, 2330, 7.1, 15600, "fuel", 7, 29, 1190, [1, 18], "car", "cashier", "cash"],
		["mall", "Centrum handlowe Crossline", "Crossline Shopping Centre", 940, 2820, 7.0, 23500, "dealership", 3, 40, 1460, [1, 20, 46], "car", "server", "service"],
		["charge", "Ładowarki Pulse Plaza", "Pulse Plaza Charging", 615, 1940, 5.1, 15400, "warehouse", 4, 35, 1030, [1, 18], "electric", "attendant", "service"],
		["truck_park", "Parking TIR Freight Exchange", "Freight Exchange Truck Park", 685, 2090, 5.9, 22500, "logistics", 6, 48, 1230, [1, 19], "truck", "attendant", "service"],
	],
}

const ECONOMICS := {
	"valley": [1450, 3.65, 1.65, 109, 109, "restaurant", "tess"],
	"alpine": [2250, 4.0, 1.7, 110, 110, "motel", "roan"],
	"ocean": [3050, 3.7, 1.55, 110, 110, "vip_park", "ines"],
	"metro": [4300, 2.85, 1.25, 111, 111, "logistics", "dev"],
}

const LOCAL_CONTRACTS := {
	"valley": {"field": "deliveries", "count": 6, "time": 1200, "cash": 2250, "pl": "Dostawy z doliny", "en": "Valley deliveries"},
	"alpine": {"field": "sales_motel", "count": 11, "time": 1500, "cash": 4000, "pl": "Goście Snowline", "en": "Snowline guests"},
	"ocean": {"field": "sales_vip_park", "count": 8, "time": 1500, "cash": 6900, "pl": "Weekend w marinie", "en": "Marina weekend"},
	"metro": {"field": "deliveries", "count": 24, "time": 1800, "cash": 10200, "pl": "Łańcuch dostaw", "en": "Supply chain"},
}

static func has_region(id: String) -> bool:
	return LAYOUTS.has(id)

static func profiles(id: String) -> Array[HbtService]:
	var definitions: Array[HbtService] = []
	var rates: Array = ECONOMICS[id]
	for row in SERVICES[id]:
		var service := HbtService.new()
		service.id = row[0]
		service.name_pl = row[1]
		service.name_en = row[2]
		service.base_price = row[3]
		service.first_upgrade = row[4]
		service.seconds = row[5]
		service.minimum_seconds = service.seconds * .57
		service.unlock_cost = row[6]
		service.prerequisite = row[7]
		service.prerequisite_level = row[8]
		service.reputation_gate = row[9]
		service.wage = row[10]
		service.capacity_levels.assign(row[11])
		service.vehicle_kind = row[12]
		service.role = row[13]
		service.task = row[14]
		service.upgrade_growth = rates[3]
		service.price_growth = rates[4]
		definitions.append(service)
	return definitions

static func roster_goals(id: String) -> Array:
	var region: Array = ECONOMICS[id]
	var result := [
		{"id": id + "_welcome", "group": "mission", "counter": "customers", "goal": 2, "reward": {"cash": int(region[0]) / 4}},
		{"id": id + "_director", "group": "mission", "counter": "site_sales", "site": region[5], "goal": 6, "reward": {"card": region[6], "diamond": 2}},
		{"id": id + "_team", "group": "achievement", "counter": "staff", "goal": 5, "reward": {"cash": region[0], "diamond": 3}},
		{"id": id + "_district", "group": "achievement", "counter": "locations", "goal": SERVICES[id].size(), "reward": {"cash": int(region[0]) * 3, "diamond": 6}},
	]
	if id == "metro":
		result.append({"id": "metro_stock", "group": "mission", "counter": "site_sales", "site": "warehouse", "goal": 12, "reward": {"card": "mila", "cash": 4200}})
		result.append({"id": "metro_retail", "group": "mission", "counter": "site_sales", "site": "mall", "goal": 12, "reward": {"card": "ren", "cash": 6400}})
		result.append({"id": "metro_motors", "group": "mission", "counter": "site_sales", "site": "dealership", "goal": 12, "reward": {"card": "ellis", "diamond": 3}})
	return result

static func daily(id: String, day: int) -> Dictionary:
	var rows: Array = SERVICES[id]
	var offset := posmod(day, rows.size() - 1) + 1
	return {"goal": 12, "reward": 8, "services": ["fuel", rows[offset][0]],
		"name_pl": "Ruch w okolicy · " + rows[offset][1], "name_en": "Around the district · " + rows[offset][2]}

static func interests(id: String, customer: String) -> Dictionary:
	var normal := {
		"local": {"fuel": 39, "market": 45, "workshop": 27, "mall": 31, "restaurant": 17},
		"business": {"fuel": 19, "market": 41, "restaurant": 28, "dealership": 49, "mall": 28, "vip_park": 22},
		"family": {"fuel": 27, "market": 29, "restaurant": 32, "mall": 51, "motel": 27, "wash": 16, "parking": 18},
		"traveler": {"fuel": 47, "workshop": 23, "restaurant": 21, "motel": 30, "wash": 22, "parking": 23, "mall": 13},
		"tourist": {"fuel": 21, "restaurant": 42, "motel": 55, "parking": 33, "vip_park": 27, "mall": 27},
		"vip": {"fuel": 12, "restaurant": 44, "vip_park": 56, "dealership": 64, "motel": 32, "mall": 39, "wash": 23},
		"electric": {"charge": 55, "restaurant": 19, "mall": 23, "dealership": 20},
		"trucker": {"logistics": 55, "warehouse": 44, "truck_park": 24},
	}
	var weights: Dictionary = normal[customer]
	var plots: Dictionary = LAYOUTS[id].plots
	for site in plots:
		if not weights.has(site) and plots[site][1] == "car" and customer not in ["trucker", "electric"]:
			weights[site] = 11
	return weights
