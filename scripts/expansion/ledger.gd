extends RefCounted
## All counted actions come from settled visits, paid construction or delivered parcels.

const Atlas = preload("res://data/world/atlas.gd")
const Regions = preload("res://data/world/regions.gd")
const Calendar = preload("res://data/world/expedition_calendar.gd")
const VEHICLES = preload("res://data/visual/vehicle_catalog.gd")
const Managers = preload("res://data/economy/managers.gd")
const LIMIT := 1_000_000_000

var high_water := 0
var week := -1
var event_totals: Dictionary = {}
var finished_events: Array = []
var contracts: Dictionary = {}
var seen_vehicles: Dictionary = {}
var sightings: Dictionary = {}
var cosmetics: Dictionary = {}
var chosen: Dictionary = {}
var prizes: Dictionary = {}
var prestige_points := 0

func restore(data: Dictionary) -> void:
	high_water = HbtEconomy.counter(data.get("high_water", 0))
	week = clampi(int(data.get("week", -1)), -1, 20000000)
	event_totals = HbtEconomy.safe_dict(data.get("event_totals"))
	var history: Variant = data.get("finished_events", [])
	finished_events = history.slice(-8) if history is Array else []
	contracts = HbtEconomy.safe_dict(data.get("contracts"))
	seen_vehicles = HbtEconomy.safe_dict(data.get("seen_vehicles"))
	sightings = HbtEconomy.safe_dict(data.get("sightings"))
	cosmetics = HbtEconomy.safe_dict(data.get("cosmetics"))
	chosen = HbtEconomy.safe_dict(data.get("chosen"))
	prizes = HbtEconomy.safe_dict(data.get("prizes"))
	prestige_points = clampi(int(data.get("prestige_points", 0)), 0, 40)

func snapshot() -> Dictionary:
	return {"high_water": high_water, "week": week, "event_totals": event_totals,
		"finished_events": finished_events, "contracts": contracts, "seen_vehicles": seen_vehicles,
		"sightings": sightings, "cosmetics": cosmetics, "chosen": chosen, "prizes": prizes, "prestige_points": prestige_points}

func advance(clock: int) -> void:
	high_water = maxi(high_water, clock)
	var schedule := Calendar.event_at(high_water)
	if int(schedule.index) != week:
		if week >= 0:
			var previous: Dictionary = Calendar.SEASONS[week % Calendar.SEASONS.size()]
			finished_events.append({"id": previous.id, "week": week, "totals": event_totals})
			if finished_events.size() > 8:
				finished_events.pop_front()
		week = schedule.index
		event_totals = {}
	for key in contracts.keys():
		if int(contracts[key].due) < high_water - Calendar.WEEK and not (contracts[key].done and not contracts[key].paid):
			contracts.erase(key)

func season() -> Dictionary:
	return Calendar.event_at(high_water)

func visit(site: HbtEconomy, ticket: HbtVisit) -> Dictionary:
	if not ticket.paid:
		return {}
	var model: String = ticket.client.model
	var service := ticket.service
	var venue: String = site.facilities[service].venue_kind
	spot(site.district, model)
	var earned := ticket.invoice.decimal()
	var signal_data := {
		"visits": 1, "fuel": int(service == "fuel"),
		"deliveries": int(ticket.trade in ["inbound", "outbound"] or (site.district == "valley" and service == "market" and model in ["parcel", "post"])),
		"liters": 42 if service == "fuel" else 165 if service == "truck" and site.district == "north" else 0,
		"trucks": int(ticket.client.kind == "truck"), "vip": int(ticket.client.type == "vip"),
		"repairs": int(venue == "repair" or service in ["workshop", "tires"] or (site.district == "desert" and service == "truck")),
		"food": int(venue == "food" or service in ["restaurant", "cafe", "drive_through"]),
		"stay": int(venue in ["hotel", "parking"] or service in ["motel", "parking", "vip_park"]),
		"clean": int(venue == "wash" or service in ["wash", "showers", "restrooms"]),
		"charged": int(service == "charge"), "sports": int(model in ["vela", "kestrel", "onyx", "akari", "velvet", "sunray"]),
		"rentals": int(ticket.trade == "lease"),
		"special": int(ticket.client.get("campaign", false)),
		"turnover": LIMIT if earned.length() > 9 else mini(LIMIT, earned.to_int()),
	}
	signal_data["sales_" + service] = 1
	increment(site, signal_data)
	return signal_data

func spot(site: String, model: String) -> bool:
	var fresh := not seen_vehicles.has(model)
	seen_vehicles[model] = true
	var album := HbtEconomy.safe_dict(sightings.get(site))
	if model in Atlas.STAMPS.get(site, []) and not album.has(model):
		album[model] = true
		sightings[site] = album
		return true
	return fresh

func increment(site: HbtEconomy, activity: Dictionary) -> void:
	advance(site.clock)
	var calendar := season()
	if calendar.live:
		for task in calendar.tasks:
			var name: String = task[0]
			if activity.has(name):
				event_totals[name] = mini(int(task[1]), int(event_totals.get(name, 0)) + int(activity[name]))
	for key in contracts:
		var contract: Dictionary = contracts[key]
		if contract.site == site.district and not contract.done and high_water < int(contract.due):
			contract.have = mini(int(contract.goal), int(contract.have) + int(activity.get(contract.metric, 0)))
			contract.done = int(contract.have) >= int(contract.goal)

func paid_event() -> bool:
	return event_totals.get("paid", false) == true

func ready_event() -> bool:
	var current := season()
	if paid_event():
		return false
	return current.tasks.all(func(task: Array) -> bool: return int(event_totals.get(task[0], 0)) >= int(task[1]))

func claim_event(site: HbtEconomy) -> bool:
	advance(site.clock)
	if not ready_event():
		return false
	var event := season()
	event_totals["paid"] = true
	cosmetics[event.id] = true
	site.grant_reward({"cash": event.cash, "diamond": event.diamond, "event": 4})
	site.touch()
	return true

func id_for(site: String, metric: String) -> String:
	@warning_ignore("integer_division")
	var day := high_water / Calendar.DAY
	return "%s/%s/%s" % [site, day, metric]

func suitable(site: HbtEconomy, metric: String) -> bool:
	var profile: Dictionary = Regions.LOCAL_CONTRACTS.get(site.district, {})
	if metric == "local_" + site.district and profile.has("site"):
		return site.level(profile.site) > 0
	match metric:
		"trucks":
			return site.facilities.values().any(func(service: HbtService) -> bool:
				return site.level(service.id) > 0 and service.vehicle_kind == "truck")
		"vip": return site.metric("reputation") >= 5
		"repairs":
			return open_kind(site, ["repair"]) or site.level("workshop") > 0 or site.level("tires") > 0 or (site.district == "desert" and site.level("truck") > 0)
		"deliveries", "local_metro":
			return open_kind(site, ["freight", "cold"]) or site.level("market") > 0 or site.level("logistics") > 0 or site.level("warehouse") > 0
		"local_valley": return site.level("market") > 0
		"local_alpine": return site.level("motel") > 0
		"local_ocean": return site.level("vip_park") > 0
		_: return true

func open_kind(site: HbtEconomy, kinds: Array) -> bool:
	return site.facilities.values().any(func(service: HbtService) -> bool:
		return site.level(service.id) > 0 and service.venue_kind in kinds)

func accept(site: HbtEconomy, metric: String) -> bool:
	advance(site.clock)
	var key := id_for(site.district, metric)
	if contracts.has(key) or active_contracts(site.district) >= 3 or not suitable(site, metric):
		return false
	for rule in offers(site.district):
		if rule.id == metric:
			contracts[key] = {"metric": rule.get("counter", metric), "offer": metric, "site": site.district, "due": high_water + rule.seconds,
				"goal": rule.goal, "have": 0, "done": false, "paid": false, "cash": rule.cash, "diamond": rule.diamond}
			site.dirty = true
			return true
	return false

func offers(district: String) -> Array:
	var list := Calendar.CONTRACTS.duplicate()
	if Regions.LOCAL_CONTRACTS.has(district):
		var profile: Dictionary = Regions.LOCAL_CONTRACTS[district]
		list.push_front({"id": "local_" + district, "counter": profile.field, "tier": 3, "goal": profile.count,
			"seconds": profile.time, "cash": profile.cash, "diamond": 4})
	return list

func active_contracts(district: String) -> int:
	var count := 0
	for entry: Dictionary in contracts.values():
		if entry.site == district and not entry.done and int(entry.due) > high_water:
			count += 1
	return count

func claim_contract(site: HbtEconomy, key: String) -> bool:
	var contract: Dictionary = contracts.get(key, {})
	if contract.is_empty() or contract.site != site.district or not contract.done or contract.paid:
		return false
	contract.paid = true
	site.grant_reward({"cash": contract.cash, "diamond": contract.diamond})
	site.touch()
	return true

func items(group: String, district := "north") -> Array:
	match group:
		"cars": return VEHICLES.VEHICLES.keys().filter(func(id: String) -> bool: return id not in ["atlas", "cargo"])
		"trucks": return ["atlas", "cargo"]
		"routes": return Atlas.STAMPS.get(district, [])
		"managers": return Managers.catalog(district, false)
		_: return Calendar.COSMETICS.get(group, [])

func owned(site: HbtEconomy, group: String, item: String) -> bool:
	match group:
		"cars", "trucks": return seen_vehicles.get(item, false)
		"managers": return site.cards.has(item)
		"routes": return HbtEconomy.safe_dict(sightings.get(site.district)).get(item, false)
		_: return cosmetics.get(item, false)

func collected(site: HbtEconomy, group: String) -> int:
	return items(group, site.district).filter(func(item: String) -> bool: return owned(site, group, item)).size()

func set_reward(site: HbtEconomy, group: String) -> bool:
	var list := items(group, site.district)
	var token := prize_key(site, group)
	if prizes.has(token) or list.is_empty() or collected(site, group) != list.size():
		return false
	prizes[token] = true
	site.grant_reward({"diamond": 6, "cash": 500})
	site.touch()
	return true

func prize_key(site: HbtEconomy, group: String) -> String:
	return "%s/%s" % [group, site.district] if group == "routes" else group

func select_cosmetic(site: HbtEconomy, group: String, item: String) -> bool:
	if not Calendar.COSMETICS.has(group) or (item not in items(group) and item != "gold_gate") or not owned(site, group, item):
		return false
	var set: Dictionary = chosen.get(site.district, {})
	if set.get(group) == item:
		set.erase(group)
	else:
		set[group] = item
	chosen[site.district] = set
	site.dirty = true
	return true
