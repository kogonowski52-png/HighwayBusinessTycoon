class_name HbtEconomy
extends RefCounted

signal changed
signal offline_prepared

const CONFIG: HbtBalance = preload("res://data/economy/balance.tres")
const LEGACY = preload("res://data/station.tres")
const BOOK = preload("res://data/economy/progression.gd")
const Managers = preload("res://data/economy/managers.gd")
const Journey = preload("res://data/economy/journey.gd")
const Recognition = preload("res://data/economy/recognition.gd")
const RecognitionState = preload("res://scripts/economy/recognition_state.gd")
const Preferences = preload("res://scripts/core/player_preferences.gd")
const Staff = preload("res://scripts/employees/staff_rules.gd")
const SaveManager = preload("res://scripts/core/save_manager.gd")
const DESERT: HbtDistrict = preload("res://data/world/desert.tres")
const DesertBusiness = preload("res://data/world/desert_businesses.gd")
const Regions = preload("res://data/world/regions.gd")
const FrontierGoals = preload("res://data/economy/frontier_goals.gd")
const Commerce = preload("res://scripts/economy/regional_commerce.gd")
const BPS := 10_000
const CURRENCIES := ["cash", "diamond", "reputation", "event"]
const MANAGER_WORKER := -2
const TUTORIAL_DONE := 6

var storage := SaveManager.new()
var facilities: Dictionary = {}
var wallet: Dictionary = {}
var levels: Dictionary = {}
var registers: Dictionary = {}
var crew: Dictionary = {}
var per_service: Dictionary = {}
var cards: Dictionary = {}
var manager_ranks: Dictionary = {}
var equipped: Array[String] = []
var claimed: Dictionary = {}
var missions: Dictionary
var chapters: Dictionary = {}
var player_xp := 0
var paid_player_level := 1
var tutorial_step := 0
var feedback_enabled := true
var preferences := Preferences.new()
var recognition := RecognitionState.new()
var language := "pl"
var low_power := false
var customers := 0
var gross := HbtAmount.new()
var spent := HbtAmount.new()
var offline_pending := HbtAmount.new()
var offline_boosted := HbtAmount.new()
var offline_seconds := 0
var offline_away_seconds := 0
var offline_tier := 0
var high_water := 0
var clock := 0
var boost_until := 0
var global_boost: HbtBoost
var event_day := -1
var event_services := 0
var event_claimed := -1
var save_error := OK
var dirty := false
var _reward_count := -1
var _curve: Dictionary = {}
var _prefix_costs: Dictionary = {}
var _sales: Array[Dictionary] = []
var _sales_total := HbtAmount.new()
var district := "north"
var commerce := Commerce.new()
var milestones: Array = BOOK.MILESTONES
var campaign_data: Dictionary = {}
var save_hook: Callable
var prestige_rank := 0
const EstateWorks = preload("res://scripts/estate/estate_works.gd")
var works := EstateWorks.new()
var supplies: Dictionary = {}
var practice_state: Dictionary = {}
var conditions: Dictionary = {}
var special_guest: Dictionary = {}

func _init(location := "north") -> void:
	district = location
	var definitions: Array[HbtService] = DesertBusiness.profiles() if district == "desert" else CONFIG.services
	if Regions.has_region(district):
		definitions = Regions.profiles(district)
	for profile in definitions:
		facilities[profile.id] = profile
		_curve[profile.id] = build_curve(profile)
		chapters[profile.id] = []
	commerce.configure(facilities, district)
	if district == "desert":
		missions = DesertBusiness.missions(facilities)
		milestones = DesertBusiness.LANDMARKS
	elif Regions.has_region(district):
		missions = FrontierGoals.missions(district, facilities) if Regions.FRONTIERS.has(district) else DesertBusiness.missions(facilities, district)
		milestones = Regions.roster_goals(district)
	else:
		missions = Journey.items(facilities)
	for item in missions.values():
		chapters[item.site].append(item)
	reset()

func reset() -> void:
	wallet.clear()
	commerce.reset()
	var starting_cash := DESERT.opening_cash if district == "desert" else CONFIG.opening_cash
	if Regions.has_region(district):
		starting_cash = Regions.ECONOMICS[district][0]
	for currency in CURRENCIES:
		wallet[currency] = HbtAmount.from(starting_cash if currency == "cash" else 0)
	for id in facilities:
		levels[id] = 1 if id == "fuel" else 0
		registers[id] = HbtAmount.new()
		crew[id] = []
		per_service[id] = {"count": 0, "gross": HbtAmount.new()}
	language = "pl"
	low_power = false
	cards.clear()
	manager_ranks.clear()
	equipped.clear()
	claimed.clear()
	player_xp = 0
	paid_player_level = 1
	tutorial_step = TUTORIAL_DONE if district != "north" else 0
	feedback_enabled = true
	preferences = Preferences.new()
	recognition = RecognitionState.new()
	customers = 0
	gross = HbtAmount.new()
	spent = HbtAmount.new()
	offline_pending = HbtAmount.new()
	offline_boosted = HbtAmount.new()
	offline_seconds = 0
	offline_away_seconds = 0
	offline_tier = 0
	boost_until = 0
	event_day = -1
	event_services = 0
	event_claimed = -1
	high_water = 0
	clock = 0
	_sales.clear()
	_sales_total = HbtAmount.new()
	campaign_data = {}
	prestige_rank = 0
	_reward_count = -1
	dirty = false
	save_error = OK

func build_curve(profile: HbtService) -> Dictionary:
	var prices: Array[HbtAmount] = []
	var costs: Array[HbtAmount] = []
	var sale := HbtAmount.from(profile.base_price)
	var upgrade := HbtAmount.from(profile.first_upgrade)
	for level in range(1, CONFIG.max_level + 1):
		if profile.id == "fuel" and district == "north":
			if level <= LEGACY.sale_prices.size():
				sale = HbtAmount.from(LEGACY.sale_prices[level - 1])
			if level <= LEGACY.upgrade_costs.size():
				upgrade = HbtAmount.from(LEGACY.upgrade_costs[level - 1])
			elif level == 5:
				upgrade = HbtAmount.from(925)
		prices.append(sale)
		costs.append(upgrade)
		sale = sale.times(profile.price_growth).divided(100)
		var premium := 0
		for checkpoint in CONFIG.cost_growth_checkpoints:
			if level >= checkpoint.x:
				premium = checkpoint.y
		upgrade = upgrade.times(profile.upgrade_growth + premium).divided(100)
	return {"price": prices, "cost": costs}

func restore(wall := -1) -> void:
	restore_profile(storage.restore(), wall)

func restore_profile(data: Dictionary, wall: int, accrue := true) -> void:
	reset()
	campaign_data = safe_dict(data.get("world"))
	prestige_rank = clampi(int(data.get("prestige_rank", 0)), 0, 20)
	var balances := safe_dict(data.get("wallet"))
	for currency in CURRENCIES:
		if balances.has(currency):
			wallet[currency] = HbtAmount.from(balances[currency])
	var unlocked := safe_dict(data.get("levels"))
	var tills := safe_dict(data.get("registers"))
	var staff := safe_dict(data.get("crew"))
	var sales := safe_dict(data.get("per_service"))
	for id in facilities:
		levels[id] = clampi(int(unlocked.get(id, levels[id])), 1 if id == "fuel" else 0, CONFIG.max_level)
		registers[id] = HbtAmount.from(tills.get(id, "0"))
		var employees: Variant = staff.get(id)
		if employees is Array:
			for index in range(mini(employees.size(), capacity(id))):
				crew[id].append(Staff.sanitize(safe_dict(employees[index])))
		var record := safe_dict(sales.get(id))
		per_service[id] = {"count": counter(record.get("count", 0)), "gross": HbtAmount.from(record.get("gross", "0"))}
	commerce.restore(safe_dict(data.get("commerce")), levels)
	works.restore(safe_dict(data.get("works")))
	practice_state = {}
	for kind in ["fuel", "wash", "cargo"]:
		var note := safe_dict(safe_dict(data.get("practice")).get(kind))
		if not note.is_empty():
			practice_state[kind] = {"ready": counter(note.get("ready")), "best": clampi(int(note.get("best", 0)), 0, 100),
				"count": counter(note.get("count")), "last": HbtAmount.from(note.get("last", "0")).decimal(),
				"claimed_bonus": note.get("claimed_bonus") == true}
	supplies = {}
	for cargo: String in safe_dict(data.get("supplies")):
		var quantity := mini(64, counter(data.supplies[cargo]))
		if quantity > 0:
			supplies[cargo] = quantity
	var owned := safe_dict(data.get("cards"))
	var ranks := safe_dict(data.get("manager_ranks"))
	for id in BOOK.MANAGERS:
		if owned.get(id) == true:
			cards[id] = true
			manager_ranks[id] = clampi(int(ranks.get(id, 1)), 1, Managers.MAX_RANK)
	var active: Variant = data.get("equipped")
	if active is Array:
		for id in active:
			if cards.has(id) and Managers.ROSTER[id].get("district", district) == district and id not in equipped and equipped.size() < CONFIG.max_active_managers:
				equipped.append(id)
	var rewards := safe_dict(data.get("claimed"))
	for item in milestones:
		if rewards.get(item.id) == true:
			claimed[item.id] = true
	for id in missions:
		if rewards.get(id) == true:
			claimed[id] = true
	language = "en" if data.get("language") == "en" else "pl"
	low_power = data.get("low_power") == true
	customers = counter(data.get("customers", 0))
	player_xp = mini(Journey.LEVEL_XP.back(), counter(data.get("player_xp", previous_xp())))
	paid_player_level = clampi(int(data.get("paid_player_level", 1)), 1, player_level())
	tutorial_step = clampi(int(data.get("tutorial_step", tutorial_step if data.is_empty() else TUTORIAL_DONE)), 0, TUTORIAL_DONE)
	if tutorial_step == 5 and level("market") > 0:
		tutorial_step = TUTORIAL_DONE
	feedback_enabled = data.get("feedback_enabled", true) == true
	preferences.restore(safe_dict(data.get("preferences")), feedback_enabled)
	recognition.restore(safe_dict(data.get("recognition")))
	event_day = int(data.get("event_day", -1))
	event_services = counter(data.get("event_services", 0))
	event_claimed = int(data.get("event_claimed", -1))
	gross = HbtAmount.from(data.get("gross", "0"))
	spent = HbtAmount.from(data.get("spent", "0"))
	offline_pending = HbtAmount.from(data.get("offline_pending", "0"))
	offline_boosted = HbtAmount.from(data.get("offline_boosted", "0"))
	if offline_boosted.compare(offline_pending) > 0:
		offline_boosted = offline_pending
	# Existing clock-based profiles retain the eight-hour benefit they already had.
	var existing_tier := CONFIG.offline_hours.find(8) if int(data.get("_schema", 0)) in [2, 3] else 0
	offline_tier = clampi(int(data.get("offline_tier", existing_tier)), 0, CONFIG.offline_hours.size() - 1)
	offline_seconds = clampi(int(data.get("offline_seconds", 0)), 0, offline_limit())
	offline_away_seconds = maxi(offline_seconds, counter(data.get("offline_away_seconds", 0)))
	high_water = counter(data.get("high_water", 0))
	clock = int(Time.get_unix_time_from_system()) if wall < 0 else wall
	boost_until = clock + clampi(int(data.get("boost_until", 0)) - maxi(clock, high_water), 0, CONFIG.boost_seconds)
	if accrue:
		capture_absence(clock)
	if data.get("legacy") == true:
		per_service["fuel"]["count"] = customers
		wallet["reputation"] = HbtAmount.from(customers)
	dirty = true
	if storage.read_only:
		save_error = ERR_UNAVAILABLE

func checkpoint() -> Error:
	if save_hook.is_valid():
		return save_hook.call()
	high_water = maxi(high_water, clock)
	save_error = storage.store(snapshot())
	dirty = save_error != OK
	return save_error

func snapshot() -> Dictionary:
	var balances := {}
	for currency in CURRENCIES:
		balances[currency] = amount(currency).decimal()
	var tills := {}
	var sales := {}
	for id in facilities:
		tills[id] = registers[id].decimal()
		sales[id] = {"count": int(per_service[id].count), "gross": per_service[id].gross.decimal()}
	var result := {
		"wallet": balances, "levels": levels, "registers": tills, "crew": crew, "per_service": sales,
		"cards": cards, "manager_ranks": manager_ranks, "equipped": equipped, "claimed": claimed,
		"player_xp": player_xp, "paid_player_level": paid_player_level, "tutorial_step": tutorial_step,
		"language": language, "low_power": low_power, "feedback_enabled": feedback_enabled,
		"preferences": preferences.snapshot(), "recognition": recognition.snapshot(),
		"customers": customers, "gross": gross.decimal(), "spent": spent.decimal(),
		"offline_pending": offline_pending.decimal(), "offline_seconds": offline_seconds,
		"offline_tier": offline_tier, "offline_away_seconds": offline_away_seconds,
		"high_water": high_water, "boost_until": boost_until,
		"event_day": event_day, "event_services": event_services, "event_claimed": event_claimed,
	}
	if not offline_boosted.empty():
		result["offline_boosted"] = offline_boosted.decimal()
	if works.has_work():
		result["works"] = works.snapshot()
	if not practice_state.is_empty():
		result["practice"] = practice_state
	if not supplies.is_empty():
		result["supplies"] = supplies
	if not commerce.state.is_empty():
		result["commerce"] = commerce.state
	if prestige_rank > 0:
		result["prestige_rank"] = prestige_rank
	if not campaign_data.is_empty():
		result["world"] = campaign_data
	return result

static func safe_dict(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}

static func counter(value: Variant) -> int:
	return clampi(int(value), 0, 9_000_000_000_000_000) if typeof(value) in [TYPE_INT, TYPE_FLOAT] else 0

func touch() -> void:
	dirty = true
	_reward_count = -1
	advance_tutorial()
	changed.emit()

func amount(currency: String) -> HbtAmount:
	return wallet[currency]

func credit(currency: String, value: HbtAmount) -> void:
	wallet[currency] = amount(currency).plus(value)

func can_afford(value: HbtAmount, currency := "cash") -> bool:
	return amount(currency).compare(value) >= 0

func debit(value: HbtAmount, currency := "cash") -> bool:
	if not can_afford(value, currency):
		return false
	wallet[currency] = amount(currency).minus(value)
	if currency == "cash":
		spent = spent.plus(value)
	return true

func level(id: String) -> int:
	return levels.get(id, 0)

func capacity(id: String) -> int:
	var profile: HbtService = facilities.get(id)
	if profile == null:
		return 0
	var size := 0
	for threshold in profile.capacity_levels:
		size += int(level(id) >= threshold)
	return size

func price(id: String, at_level := -1) -> HbtAmount:
	var tier := level(id) if at_level < 0 else at_level
	return _curve[id].price[clampi(tier, 1, CONFIG.max_level) - 1]

func cost_at(id: String, tier: int) -> HbtAmount:
	if tier >= CONFIG.max_level or tier < 1:
		return HbtAmount.new()
	return _curve[id].cost[tier - 1].times(BPS - skill("discount", id)).divided(BPS)

func cost_prefix(id: String) -> Array[HbtAmount]:
	var discount := skill("discount", id)
	var cached: Dictionary = _prefix_costs.get(id, {})
	if cached.get("discount", -1) == discount:
		return cached.totals
	var totals: Array[HbtAmount] = [HbtAmount.new()]
	for tier in range(1, CONFIG.max_level):
		var cost: HbtAmount = _curve[id].cost[tier - 1].times(BPS - discount).divided(BPS)
		totals.append(totals[-1].plus(cost))
	_prefix_costs[id] = {"discount": discount, "totals": totals}
	return totals

func quote_upgrade(id: String, quantity: int) -> Dictionary:
	var tier := level(id)
	if tier == 0 or tier >= CONFIG.max_level or quantity < 0:
		return {"count": 0, "cost": HbtAmount.new(), "affordable": false}
	if quantity == 1:
		var cost := building_input_cost(cost_at(id, tier))
		return {"count": 1, "cost": cost, "affordable": can_afford(cost)}
	var totals := cost_prefix(id)
	var start := tier - 1
	var count := mini(quantity, CONFIG.max_level - tier)
	if quantity == 0:
		var high := CONFIG.max_level - tier
		while count < high:
			var middle := (count + high + 1) >> 1
			if can_afford(building_input_cost(totals[start + middle].minus(totals[start]))):
				count = middle
			else:
				high = middle - 1
	var total := building_input_cost(totals[start + count].minus(totals[start]))
	return {"count": count, "cost": total, "affordable": count > 0 and can_afford(total)}

func buy_levels(id: String, quantity: int) -> int:
	var quote := quote_upgrade(id, quantity)
	if not quote.affordable or not debit(quote.cost):
		return 0
	levels[id] += quote.count
	consume_cargo("materials")
	add_xp(quote.count * 3)
	touch()
	return quote.count

func gate_open(id: String) -> bool:
	var facility: HbtService = facilities[id]
	return level(id) == 0 and level(facility.prerequisite) >= facility.prerequisite_level \
		and amount("reputation").compare(HbtAmount.from(facility.reputation_gate)) >= 0

func construction_quote(id: String) -> Dictionary:
	var service: HbtService = facilities[id]
	var cost := building_input_cost(HbtAmount.from(service.unlock_cost))
	var grade := level(service.prerequisite)
	var reputation := metric("reputation")
	var level_ok := grade >= service.prerequisite_level
	var reputation_ok := reputation >= service.reputation_gate
	var cash_ok := can_afford(cost)
	return {"cost": cost, "level": grade, "reputation": reputation, "level_ok": level_ok,
		"reputation_ok": reputation_ok, "cash_ok": cash_ok,
		"ready": level(id) == 0 and level_ok and reputation_ok and cash_ok and not storage.read_only}

func estimated_bay_income(id: String) -> HbtAmount:
	var tier := maxi(1, level(id))
	return price(id, tier).times(6000).divided(ceili(duration(id, -1, tier) * 100.0))

func unlock(id: String) -> bool:
	var facility: HbtService = facilities[id]
	if not gate_open(id) or not debit(building_input_cost(HbtAmount.from(facility.unlock_cost))):
		return false
	levels[id] = 1
	consume_cargo("materials")
	if id == "market" and tutorial_step == 5:
		tutorial_step = TUTORIAL_DONE
	add_xp(12)
	touch()
	return true

func recruit_cost(id: String) -> HbtAmount:
	return Staff.recruit_cost(facilities[id], crew[id].size(), level(id))

func hire(id: String) -> bool:
	if crew[id].size() >= capacity(id) or not debit(recruit_cost(id)):
		return false
	crew[id].append({"xp": 0, "training": 0, "rank": 1})
	add_xp(7)
	touch()
	return true

func train(id: String, index: int) -> bool:
	var employee: Dictionary = crew[id][index]
	if employee.training >= Staff.MAX_TRAINING or not debit(Staff.training_cost(facilities[id], employee)):
		return false
	employee.training += 1
	add_xp(4)
	touch()
	return true

func promote(id: String, index: int) -> bool:
	var employee: Dictionary = crew[id][index]
	if not Staff.promotion_ready(employee) or not debit(Staff.promotion_cost(facilities[id], employee)):
		return false
	employee.rank += 1
	add_xp(12)
	touch()
	return true

func specialize(id: String, index: int, focus: String) -> bool:
	var people: Array = crew.get(id, [])
	if index not in range(people.size()) or focus not in Staff.SPECIALTIES:
		return false
	var employee: Dictionary = people[index]
	if int(employee.rank) < 2 or focus == employee.get("specialty", "") or storage.read_only:
		return false
	employee["specialty"] = focus
	touch()
	return true

func duration(id: String, worker: int, at_level := -1) -> float:
	var facility: HbtService = facilities[id]
	var tier := level(id) if at_level < 0 else at_level
	var time := maxf(facility.minimum_seconds, facility.seconds * pow(0.972, tier - 1))
	if id == "fuel" and tier >= 1 and tier <= LEGACY.service_seconds.size():
		time = LEGACY.service_seconds[tier - 1]
	if worker >= 0:
		time *= float(BPS) / Staff.speed(crew[id][worker])
	elif worker == MANAGER_WORKER:
		time *= float(BPS) / (BPS + skill("automation", id))
	if has_supplies(id):
		time *= .86
	if not works.levels.is_empty():
		time *= works.service_time()
	return maxf(0.65, time * float(BPS) / (BPS + skill("speed", id)))

func payout(id: String, tip: int, worker: int, include_boost := true, include_global := true) -> HbtAmount:
	var value := price(id).times(tip).divided(100)
	value = value.times(BPS + skill("revenue", id) + collector_bonus(id)).divided(BPS)
	if worker >= 0:
		value = value.times(Staff.efficiency(crew[id][worker])).divided(BPS)
	var double_active := include_boost and include_global and global_boost != null and global_boost.earning(clock)
	if include_boost and not double_active and boost_until > clock:
		value = value.times(CONFIG.boost_multiplier).divided(BPS)
	if prestige_rank > 0:
		value = value.times(BPS + prestige_rank * 500).divided(BPS)
	return value.times(HbtBoost.Policy.INCOME_MULTIPLIER) if double_active else value

func serve(id: String, value: HbtAmount, reputation: int, worker: int) -> void:
	if worker >= 0:
		crew[id][worker].xp = mini(1_000_000, crew[id][worker].xp + 1)
	consume_supplies(id)
	customers += 1
	recognition.record_visit(id, equipped)
	add_xp(2 + reputation)
	per_service[id].count += 1
	per_service[id].gross = per_service[id].gross.plus(value)
	gross = gross.plus(value)
	_sales.append({"time": clock, "value": value})
	_sales_total = _sales_total.plus(value)
	credit("reputation", HbtAmount.from(reputation))
	if id in current_event().services:
		if event_day != day_index():
			event_day = day_index()
			event_services = 0
		event_services += 1
		credit("event", HbtAmount.from(1))
	if worker == -1 or skill("collect", id) > 0:
		credit("cash", value)
	else:
		registers[id] = registers[id].plus(value)
	touch()

func building_input_cost(cost: HbtAmount) -> HbtAmount:
	return cost.times(95).divided(100) if int(supplies.get("materials", 0)) > 0 else cost

func deliver_supplies(cargo: String, units: int) -> void:
	supplies[cargo] = mini(64, int(supplies.get(cargo, 0)) + units)
	dirty = true

func supply_for(id: String) -> String:
	var facility: HbtService = facilities.get(id)
	if facility == null:
		return ""
	if id in ["logging", "haulage"]:
		return "timber"
	match facility.venue_kind:
		"refuel": return "fuel"
		"shop": return "goods"
		"food": return "food"
		"repair": return "parts"
		"cold", "freight": return "containers"
		"showroom": return "cars"
		"hotel", "rent", "scooter", "parking", "vip": return "vip"
	if id in ["fuel", "truck"]:
		return "fuel"
	if id in ["market", "mall", "parts"]:
		return "goods"
	if id in ["restaurant", "cafe", "drive_through"]:
		return "food"
	if id in ["workshop", "tires", "tuning", "restoration"]:
		return "parts"
	if id in ["logistics", "warehouse", "terminal"]:
		return "containers"
	if id in ["motel", "vip_park", "resort"]:
		return "vip"
	return ""

func has_supplies(id: String) -> bool:
	return not supplies.is_empty() and int(supplies.get(supply_for(id), 0)) > 0

func consume_supplies(id: String) -> void:
	if supplies.is_empty():
		return
	consume_cargo(supply_for(id))

func consume_cargo(cargo: String) -> void:
	var left := int(supplies.get(cargo, 0))
	if left > 1:
		supplies[cargo] = left - 1
	elif left == 1:
		supplies.erase(cargo)

func holding() -> HbtAmount:
	var total := HbtAmount.new()
	for id in facilities:
		total = total.plus(registers[id])
	return total

func collect() -> HbtAmount:
	var total := holding()
	if total.empty():
		return total
	for id in facilities:
		registers[id] = HbtAmount.new()
	credit("cash", total)
	if tutorial_step == 4:
		tutorial_step = TUTORIAL_DONE if level("market") > 0 else 5
	touch()
	return total

func income_per_minute() -> HbtAmount:
	while not _sales.is_empty() and int(_sales.front().time) <= clock - 60:
		_sales_total = _sales_total.minus(_sales.pop_front().value)
	return _sales_total

func manager_for(key: String, site := "") -> String:
	var best := ""
	for id in equipped:
		var card: Dictionary = BOOK.MANAGERS[id]
		if card.get("district", district) != district:
			continue
		if card.skill == key and (card.site.is_empty() or card.site == site):
			if best.is_empty() or manager_effect(id) > manager_effect(best) \
				or (key == "collect" and manager_rank(id) > manager_rank(best)):
				best = id
	return best

func skill(key: String, site := "") -> int:
	var id := manager_for(key, site)
	return 0 if id.is_empty() else manager_effect(id)

func collector_bonus(site: String) -> int:
	var id := manager_for("collect", site)
	return 0 if id.is_empty() else (manager_rank(id) - 1) * 300

func manager_rank(id: String) -> int:
	return manager_ranks.get(id, 1) if cards.has(id) else 0

func manager_effect(id: String) -> int:
	return Managers.value(id, maxi(1, manager_rank(id)))

func manager_training(id: String) -> Dictionary:
	var rank := manager_rank(id)
	if rank == 0 or rank >= Managers.MAX_RANK:
		return {}
	var price: int = Managers.RANK_PRICES[rank - 1] + int(BOOK.MANAGERS[id].rarity in ["epic", "legendary"])
	var required: int = Managers.RANK_LEVELS[rank - 1]
	return {"cost": price, "level": required,
		"ready": player_level() >= required and can_afford(HbtAmount.from(price), "diamond")}

func train_manager(id: String) -> bool:
	var quote := manager_training(id)
	if quote.is_empty() or not quote.ready or not debit(HbtAmount.from(quote.cost), "diamond"):
		return false
	manager_ranks[id] = manager_rank(id) + 1
	add_xp(10)
	touch()
	return true

func assign(id: String) -> bool:
	if BOOK.MANAGERS.get(id, {}).get("district", district) != district:
		return false
	if not cards.has(id):
		return false
	if id in equipped:
		equipped.erase(id)
	elif equipped.size() < CONFIG.max_active_managers:
		equipped.append(id)
	else:
		return false
	for site in facilities:
		if skill("collect", site) > 0 and not registers[site].empty():
			credit("cash", registers[site])
			registers[site] = HbtAmount.new()
	touch()
	return true

func metric(key: String, site := "") -> int:
	match key:
		"customers": return customers
		"fuel_level": return level("fuel")
		"site_level": return level(site)
		"site_sales": return int(per_service[site].count)
		"rentals": return int(commerce.record(site).outbound)
		"returns", "inbound", "outbound", "sold", "shoppers":
			var field := "inbound" if key == "returns" else key
			return int(commerce.record(site).get(field, 0))
		"site_staff": return crew[site].size()
		"site_training":
			var training := 0
			for employee in crew[site]:
				training += int(employee.training)
			return training
		"manager_ranks":
			var ranks := 0
			for id in cards:
				ranks += manager_rank(id) - 1
			return ranks
		"best_level": return levels.values().max()
		"reputation": return mini(1_000_000_000, amount("reputation").decimal().left(10).to_int())
		"locations":
			var count := 0
			for id in levels:
				count += int(level(id) > 0)
			return count
		"staff", "trained", "promoted":
			var count := 0
			for entries in crew.values():
				for employee in entries:
					count += int(key == "staff" or (key == "trained" and employee.training > 0) \
						or (key == "promoted" and employee.rank > 1))
			return count
	return 0

func player_level() -> int:
	return Journey.level_for(player_xp)

func add_xp(value: int) -> void:
	player_xp = mini(Journey.LEVEL_XP.back(), player_xp + value)

func previous_xp() -> int:
	var total := customers * 3
	for id in facilities:
		total += maxi(0, level(id) - 1) * 3 + int(id != "fuel" and level(id) > 0) * 12
		for employee in crew[id]:
			total += 7 + int(employee.training) * 4 + (int(employee.rank) - 1) * 12
	return total

func player_reward() -> Dictionary:
	var cash := 0
	var diamonds := 0
	for rank in range(paid_player_level + 1, player_level() + 1):
		cash += rank * 45
		diamonds += 1 + floori(rank / 4.0)
	return {"cash": cash, "diamond": diamonds}

func claim_player_reward() -> bool:
	if paid_player_level >= player_level():
		return false
	var reward := player_reward()
	paid_player_level = player_level()
	grant_reward(reward)
	touch()
	return true

func mission_progress(item: Dictionary) -> int:
	if item.counter == "site_revenue":
		var cash: HbtAmount = per_service[item.site].gross
		return int(item.goal) if cash.compare(HbtAmount.from(item.goal)) >= 0 else cash.decimal().to_int()
	return mini(int(item.goal), metric(item.counter, item.get("site", "")))

func mission_available(item: Dictionary) -> bool:
	if player_level() < int(item.rank) or (level(item.site) == 0 and int(item.wave) > 0):
		return false
	if item.wave == 0:
		return true
	var completed := 0
	for prerequisite in chapters[item.site]:
		if prerequisite.wave == item.wave - 1 and claimed.has(prerequisite.id):
			completed += 1
	return completed >= 2

func ready_rewards() -> int:
	if _reward_count >= 0:
		return _reward_count
	_reward_count = int(player_level() > paid_player_level)
	for item in milestones:
		_reward_count += int(not claimed.has(item.id) and mission_progress(item) >= item.goal)
	for item in missions.values():
		_reward_count += int(not claimed.has(item.id) and mission_available(item) and mission_progress(item) >= item.goal)
	return _reward_count

func accept_reward(item: Dictionary) -> bool:
	if claimed.has(item.id) or mission_progress(item) < item.goal:
		return false
	claimed[item.id] = true
	grant_reward(item.reward)
	touch()
	return true

func grant_reward(reward: Dictionary) -> void:
	for key in reward:
		if key == "card":
			cards[reward.card] = true
		else:
			credit(key, HbtAmount.from(reward[key]))

func claim_reward(id: String) -> bool:
	if missions.has(id):
		var item: Dictionary = missions[id]
		return mission_available(item) and accept_reward(item)
	for item in milestones:
		if item.id == id:
			return accept_reward(item)
	return false

func advance_tutorial() -> void:
	while tutorial_step < 5:
		var ready := false
		match tutorial_step:
			0: ready = customers > 0
			1: ready = level("fuel") >= 2
			2: ready = claimed.has("first") and claimed.has("upgrade")
			3: ready = not crew.fuel.is_empty()
			4: ready = skill("collect", "fuel") > 0
		if not ready:
			return
		tutorial_step += 1

func finish_tutorial() -> void:
	if tutorial_step < TUTORIAL_DONE:
		tutorial_step = TUTORIAL_DONE
		touch()

@warning_ignore("integer_division")
func day_index() -> int:
	return maxi(high_water, clock) / 86_400

func calendar_offer() -> Array:
	return Recognition.CALENDAR[recognition.slot()]

func claim_calendar() -> Array:
	var day := day_index()
	if storage.read_only or not recognition.is_available(day):
		return []
	var offer := calendar_offer()
	recognition.last_day = day
	recognition.daily_count += 1
	match offer[0]:
		"voucher": recognition.vouchers += int(offer[1])
		"card":
			if cards.has(offer[1]):
				offer = ["diamond", Recognition.DUPLICATE_DIAMONDS]
				credit("diamond", HbtAmount.from(offer[1]))
			else:
				cards[offer[1]] = true
		_:
			credit(offer[0], HbtAmount.from(offer[1]))
	touch()
	return offer

func redeem_voucher() -> bool:
	if recognition.vouchers <= 0 or boost_until > clock:
		return false
	recognition.vouchers -= 1
	boost_until = clock + CONFIG.boost_seconds
	touch()
	return true

func achievement_progress(item: Dictionary) -> int:
	var goal: int = item.goal
	if item.has("district"):
		if item.district != district:
			return 0
		return mini(goal, metric(item.counter, item.site))
	match item.group:
		"gross":
			return goal if gross.compare(HbtAmount.from(goal)) >= 0 else gross.decimal().to_int()
		"upgrades":
			var count := 0
			for tier in levels.values():
				count += maxi(0, int(tier) - 1)
			return mini(goal, count)
		"training":
			var count := 0
			for site in facilities:
				count += metric("site_training", site)
			return mini(goal, count)
		"cards": return mini(goal, cards.size())
		"calendar": return mini(goal, recognition.daily_count)
	return mini(goal, metric(item.group))

func claim_achievement(id: String) -> bool:
	if storage.read_only or not Recognition.collection.has(id) or recognition.achievement_claimed.has(id):
		return false
	var item: Dictionary = Recognition.collection[id]
	if achievement_progress(item) < int(item.goal):
		return false
	recognition.achievement_claimed[id] = true
	credit("diamond", HbtAmount.from(item.reward))
	touch()
	return true

func current_event() -> Dictionary:
	if district == "desert":
		return DesertBusiness.DAILIES[posmod(day_index(), DesertBusiness.DAILIES.size())]
	if Regions.has_region(district):
		return Regions.daily(district, day_index())
	return BOOK.EVENTS[posmod(day_index(), BOOK.EVENTS.size())]

func daily_progress() -> int:
	return event_services if event_day == day_index() else 0

func claim_daily() -> bool:
	var event := current_event()
	if event_claimed == day_index() or daily_progress() < int(event.goal):
		return false
	event_claimed = day_index()
	credit("event", HbtAmount.from(event.reward))
	credit("diamond", HbtAmount.from(1))
	touch()
	return true

func exchange(card: bool) -> bool:
	if card and cards.has("mira"):
		return false
	var cost: int = BOOK.EVENT_CARD_COST if card else BOOK.EVENT_DIAMOND_COST
	if not debit(HbtAmount.from(cost), "event"):
		return false
	if card:
		cards["mira"] = true
	else:
		credit("diamond", HbtAmount.from(BOOK.EVENT_DIAMONDS))
	touch()
	return true

func buy_boost() -> bool:
	if boost_until > clock or not debit(HbtAmount.from(CONFIG.boost_cost), "diamond"):
		return false
	boost_until = clock + CONFIG.boost_seconds
	touch()
	return true

func arrival_period() -> float:
	var reputation := float(metric("reputation"))
	var interval := DESERT.arrival_seconds if district == "desert" else CONFIG.arrival_seconds
	var floor_seconds := DESERT.minimum_arrival_seconds if district == "desert" else CONFIG.minimum_arrival_seconds
	if Regions.has_region(district):
		interval = Regions.ECONOMICS[district][1]
		floor_seconds = Regions.ECONOMICS[district][2]
	var shortened := interval / (1.0 + minf(reputation / 350.0, 0.64))
	return maxf(floor_seconds, shortened * float(BPS) / (BPS + skill("traffic")))

func attraction(id: String) -> float:
	return (1.0 + minf(level(id) * 0.006, 0.55) + maxf(0.0, capacity(id) - 1) * 0.10) * float(conditions.get(id, 1.0))

func offline_limit() -> int:
	return CONFIG.offline_hours[offline_tier] * 3600

func offline_upgrade() -> Dictionary:
	if offline_tier >= CONFIG.offline_costs.size():
		return {}
	var price := HbtAmount.from(CONFIG.offline_costs[offline_tier])
	var required: int = CONFIG.offline_levels[offline_tier]
	return {"hours": CONFIG.offline_hours[offline_tier + 1], "cost": price, "level": required,
		"ready": player_level() >= required and metric("staff") > 0 and can_afford(price)}

func buy_offline_limit() -> bool:
	var offer := offline_upgrade()
	if offer.is_empty() or not offer.ready or not debit(offer.cost):
		return false
	offline_tier += 1
	touch()
	return true

func offline_quote(seconds: int) -> HbtAmount:
	var total := HbtAmount.new()
	var staffed := metric("staff")
	for id in facilities:
		if level(id) > 0 and crew[id].is_empty() and skill("automation", id) > 0:
			staffed += 1
	if staffed == 0:
		return total
	for id in facilities:
		var workers: int = crew[id].size()
		var automated := workers == 0 and level(id) > 0 and skill("automation", id) > 0
		for slot in range(workers + int(automated)):
			var worker := MANAGER_WORKER if automated else slot
			# Conservative allocation based on staffing, cadence and distance to the bay.
			var seconds_per_job := maxf(duration(id, worker) + 11.0 + staffed * 1.1, arrival_period() * staffed)
			var jobs := floori(seconds * CONFIG.offline_efficiency / (100.0 * seconds_per_job))
			var income := payout(id, 100, worker, false).times(jobs).times(BPS + skill("offline", id)).divided(BPS)
			total = total.plus(income)
	return total

func offline_window(start: int, elapsed: int) -> HbtAmount:
	var total := offline_quote(elapsed)
	if global_boost == null or elapsed <= 0:
		return total
	for segment in global_boost.segments(start, start + elapsed):
		var boosted := offline_quote(segment[1] - start).minus(offline_quote(segment[0] - start))
		total = total.plus(boosted.times(HbtBoost.Policy.INCOME_MULTIPLIER - 1))
	return total

func capture_absence(wall: int, monotonic_elapsed := -1) -> HbtAmount:
	var trusted_wall := wall
	var delta := wall - high_water
	if high_water == 0:
		delta = 0
	elif monotonic_elapsed >= 0 and absi(delta - monotonic_elapsed) > CONFIG.clock_tolerance_seconds:
		delta = monotonic_elapsed
		trusted_wall = high_water + monotonic_elapsed
	var elapsed := clampi(delta, 0, maxi(0, offline_limit() - offline_seconds))
	var base := offline_quote(elapsed)
	var grant := offline_window(high_water, elapsed)
	offline_boosted = offline_boosted.plus(grant.minus(base).times(HbtBoost.Policy.INCOME_MULTIPLIER)
		.divided(HbtBoost.Policy.INCOME_MULTIPLIER - 1))
	high_water = maxi(high_water, trusted_wall)
	clock = high_water
	if not grant.empty():
		offline_pending = offline_pending.plus(grant)
		offline_seconds += elapsed
	if not offline_pending.empty():
		offline_away_seconds += maxi(0, delta)
	if not grant.empty():
		offline_prepared.emit()
	dirty = true
	return grant

func offline_eligible() -> HbtAmount:
	return offline_pending.minus(offline_boosted)

func redeem_offline(bonus := false, endorsed_base: HbtAmount = null) -> HbtAmount:
	if offline_pending.empty():
		return HbtAmount.new()
	var value := offline_pending
	if bonus and endorsed_base != null:
		var unboosted := offline_eligible()
		var eligible := endorsed_base if endorsed_base.compare(unboosted) <= 0 else unboosted
		value = value.plus(eligible)
	offline_pending = HbtAmount.new()
	offline_boosted = HbtAmount.new()
	offline_seconds = 0
	offline_away_seconds = 0
	credit("cash", value)
	gross = gross.plus(value)
	touch()
	return value
