extends RefCounted

# id, Polish and English names, invoice, first upgrade, duration, investment,
# preceding business and level, reputation, wage, bays, lane, role, animation.
const SERVICES := [
	["fuel", "Paliwa Copper Mile", "Copper Mile Fuel", 48, 210, 3.0, 0, "", 0, 0, 105, [1, 15], "car", "attendant", "fuel"],
	["cafe", "Kawiarnia Dust & Bean", "Dust & Bean Café", 72, 224, 3.7, 720, "fuel", 3, 7, 164, [1, 18], "car", "server", "carry"],
	["restrooms", "Toalety podróżnych", "Roadside Restrooms", 58, 198, 3.2, 1100, "fuel", 4, 12, 142, [1, 20], "car", "cleaner", "clean"],
	["vip_park", "Parking VIP Sunset", "Sunset VIP Parking", 135, 370, 4.9, 2200, "cafe", 4, 19, 240, [1, 18, 42], "car", "attendant", "service"],
	["truck", "Serwis ciężarowy Red Mesa", "Red Mesa Truck Service", 190, 490, 5.9, 2100, "restrooms", 2, 22, 308, [1, 20], "truck", "mechanic", "repair"],
	["showers", "Prysznice kierowców", "Truckers' Showers", 156, 430, 4.7, 4900, "truck", 3, 33, 277, [1, 18], "truck", "cleaner", "clean"],
	["motel", "Motel Stargazer", "Stargazer Motor Lodge", 240, 560, 5.7, 6600, "cafe", 6, 39, 320, [1, 20, 42], "car", "manager", "service"],
	["truck_park", "Parking TIR Red Mesa", "Red Mesa Truck Parking", 227, 580, 5.7, 7900, "truck", 5, 44, 368, [1, 20], "truck", "attendant", "service"],
	["drive_through", "Grill Roadstar Drive‑Through", "Roadstar Drive‑Through Grill", 266, 695, 5.1, 9800, "motel", 5, 53, 414, [1, 22], "car", "server", "carry"],
	["charge", "Szybkie ładowarki Sunvolt", "Sunvolt Fast Charging", 322, 780, 5.4, 14500, "drive_through", 5, 66, 520, [1, 24], "electric", "attendant", "service"],
]

const LANDMARKS := [
	{"id": "desert_start", "group": "mission", "counter": "customers", "goal": 1, "reward": {"cash": 125}},
	{"id": "desert_crew", "group": "mission", "counter": "staff", "goal": 1, "reward": {"cash": 200, "diamond": 1}},
	{"id": "desert_open", "group": "achievement", "counter": "locations", "goal": 5, "reward": {"cash": 1500, "diamond": 3}},
	{"id": "desert_full", "group": "achievement", "counter": "locations", "goal": 10, "reward": {"cash": 9500, "diamond": 8}},
]

const DAILIES := [
	{"goal": 12, "reward": 7, "services": ["fuel", "truck", "truck_park"], "name_pl": "Zjazd na Copper Mile", "name_en": "Copper Mile turnoff"},
	{"goal": 10, "reward": 8, "services": ["cafe", "drive_through", "motel"], "name_pl": "Przerwa podróżnych", "name_en": "Travellers' break"},
	{"goal": 12, "reward": 8, "services": ["fuel", "restrooms", "showers"], "name_pl": "Przystanek przy drodze", "name_en": "Roadside rest"},
]

static func profiles() -> Array[HbtService]:
	var definitions: Array[HbtService] = []
	for row in SERVICES:
		var service := HbtService.new()
		service.id = row[0]
		service.name_pl = row[1]
		service.name_en = row[2]
		service.base_price = row[3]
		service.first_upgrade = row[4]
		service.upgrade_growth = 111
		service.price_growth = 110
		service.seconds = row[5]
		service.minimum_seconds = service.seconds * 0.53
		service.unlock_cost = row[6]
		service.prerequisite = row[7]
		service.prerequisite_level = row[8]
		service.reputation_gate = row[9]
		service.wage = row[10]
		service.capacity_levels.assign(row[11])
		service.vehicle_kind = row[12]
		service.role = row[13]
		service.task = row[14]
		definitions.append(service)
	return definitions

static func missions(definitions: Dictionary) -> Dictionary:
	var result := {}
	var chapter := 0
	for id in definitions:
		var service: HbtService = definitions[id]
		var rank := mini(10, 1 + chapter)
		var rules := [
			["open", "site_level", 1, service.base_price, 0], ["visits", "site_sales", 4, service.base_price * 2, 0],
			["crew", "site_staff", 1, service.wage, 0], ["turnover", "site_revenue", service.base_price * 8, service.base_price * 3, 0],
			["refit", "site_level", 7, service.base_price * 6, 1], ["training", "site_training", 2, service.wage * 3, 1],
			["visits", "site_sales", 16, service.base_price * 9, 1], ["turnover", "site_revenue", service.base_price * 36, service.base_price * 10, 1],
			["expansion", "site_level", 20, 0, 2], ["training", "site_training", 4, service.wage * 6, 2],
			["visits", "site_sales", 36, 0, 2], ["turnover", "site_revenue", service.base_price * 190, service.base_price * 28, 2],
			["refit", "site_level", 40, 0, 3], ["visits", "site_sales", 80, 0, 3],
			["expansion", "site_level", 65, 0, 3], ["landmark", "site_level", 100, 0, 3],
		]
		for index in range(rules.size()):
			var rule: Array = rules[index]
			var key := "district_%s_%02d" % [id, index]
			var reward := {"cash": rule[3]} if rule[3] > 0 else {"diamond": 3 + rule[4], "event": 2 + rule[4]}
			result[key] = {"id": key, "site": id, "rank": rank, "counter": rule[1], "goal": rule[2],
				"reward": reward, "wave": rule[4], "label": rule[0]}
		chapter += 1
	return result

static func interests(customer: String) -> Dictionary:
	match customer:
		"trucker": return {"truck": 55, "showers": 27, "truck_park": 22}
		"vip": return {"vip_park": 54, "drive_through": 22, "fuel": 10, "motel": 18}
		"electric": return {"charge": 54, "cafe": 18, "drive_through": 17, "vip_park": 9}
		"tourist": return {"motel": 36, "cafe": 31, "restrooms": 19, "fuel": 16, "drive_through": 17}
		"family": return {"restrooms": 33, "drive_through": 27, "cafe": 17, "fuel": 18, "motel": 16}
		"business": return {"cafe": 33, "vip_park": 25, "drive_through": 22, "fuel": 23}
		"traveler": return {"fuel": 45, "restrooms": 22, "motel": 19, "cafe": 24, "drive_through": 18}
	return {"fuel": 44, "cafe": 31, "restrooms": 16, "drive_through": 22}
