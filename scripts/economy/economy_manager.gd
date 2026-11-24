class_name HbtEconomy
extends RefCounted

signal changed
signal offline_prepared

const CONFIG: HbtBalance = preload("res://data/economy/balance.tres")
const LEGACY = preload("res://data/station.tres")
const BOOK = preload("res://data/economy/progression.gd")
const Staff = preload("res://scripts/employees/staff_rules.gd")
const SaveManager = preload("res://scripts/core/save_manager.gd")
const BPS := 10_000
const CURRENCIES := ["cash", "diamond", "reputation", "event"]

var storage := SaveManager.new()
var facilities: Dictionary = {}
var wallet: Dictionary = {}
var levels: Dictionary = {}
var registers: Dictionary = {}
var crew: Dictionary = {}
var per_service: Dictionary = {}
var cards: Dictionary = {}
var equipped: Array[String] = []
var claimed: Dictionary = {}
var language := "pl"
var low_power := false
var customers := 0
var gross := HbtAmount.new()
var spent := HbtAmount.new()
var offline_pending := HbtAmount.new()
var offline_seconds := 0
var high_water := 0
var clock := 0
var boost_until := 0
var event_day := -1
var event_services := 0
var event_claimed := -1
var save_error := OK
var dirty := false
var _curve: Dictionary = {}
var _sales: Array[Dictionary] = []

func _init() -> void:
	for profile in CONFIG.services:
		facilities[profile.id] = profile
		_curve[profile.id] = build_curve(profile)
	reset()

func reset() -> void:
	wallet.clear()
	for currency in CURRENCIES:
		wallet[currency] = HbtAmount.from(CONFIG.opening_cash if currency == "cash" else 0)
	for id in facilities:
		levels[id] = 1 if id == "fuel" else 0
		registers[id] = HbtAmount.new()
		crew[id] = []
		per_service[id] = {"count": 0, "gross": HbtAmount.new()}
	language = "pl"
	low_power = false
	cards.clear()
	equipped.clear()
	claimed.clear()
	customers = 0
	gross = HbtAmount.new()
	spent = HbtAmount.new()
	offline_pending = HbtAmount.new()
	offline_seconds = 0
	boost_until = 0
	event_day = -1
	event_services = 0
	event_claimed = -1
	high_water = 0
	clock = 0
	_sales.clear()
	dirty = false
	save_error = OK

func build_curve(profile: HbtService) -> Dictionary:
	var prices: Array[HbtAmount] = []
	var costs: Array[HbtAmount] = []
	var sale := HbtAmount.from(profile.base_price)
	var upgrade := HbtAmount.from(profile.first_upgrade)
	for level in range(1, CONFIG.max_level + 1):
		if profile.id == "fuel":
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
	reset()
	var data := storage.restore()
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
	var owned := safe_dict(data.get("cards"))
	for id in BOOK.MANAGERS:
		if owned.get(id) == true:
			cards[id] = true
	var active: Variant = data.get("equipped")
	if active is Array:
		for id in active:
			if cards.has(id) and id not in equipped and equipped.size() < CONFIG.max_active_managers:
				equipped.append(id)
	var rewards := safe_dict(data.get("claimed"))
	for item in BOOK.MILESTONES:
		if rewards.get(item.id) == true:
			claimed[item.id] = true
	language = "en" if data.get("language") == "en" else "pl"
	low_power = data.get("low_power") == true
	customers = counter(data.get("customers", 0))
	event_day = int(data.get("event_day", -1))
	event_services = counter(data.get("event_services", 0))
	event_claimed = int(data.get("event_claimed", -1))
	gross = HbtAmount.from(data.get("gross", "0"))
	spent = HbtAmount.from(data.get("spent", "0"))
	offline_pending = HbtAmount.from(data.get("offline_pending", "0"))
	offline_seconds = clampi(int(data.get("offline_seconds", 0)), 0, CONFIG.offline_cap_seconds)
	high_water = counter(data.get("high_water", 0))
	clock = int(Time.get_unix_time_from_system()) if wall < 0 else wall
	boost_until = clock + clampi(int(data.get("boost_until", 0)) - maxi(clock, high_water), 0, CONFIG.boost_seconds)
	capture_absence(clock)
	if data.get("legacy") == true:
		per_service["fuel"]["count"] = customers
		wallet["reputation"] = HbtAmount.from(customers)
	dirty = true
	if storage.read_only:
		save_error = ERR_UNAVAILABLE

func checkpoint() -> Error:
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
	return {
		"wallet": balances, "levels": levels, "registers": tills, "crew": crew, "per_service": sales,
		"cards": cards, "equipped": equipped, "claimed": claimed, "language": language, "low_power": low_power,
		"customers": customers, "gross": gross.decimal(), "spent": spent.decimal(),
		"offline_pending": offline_pending.decimal(), "offline_seconds": offline_seconds,
		"high_water": high_water, "boost_until": boost_until,
		"event_day": event_day, "event_services": event_services, "event_claimed": event_claimed,
	}

static func safe_dict(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}

static func counter(value: Variant) -> int:
	return clampi(int(value), 0, 9_000_000_000_000_000) if typeof(value) in [TYPE_INT, TYPE_FLOAT] else 0

func touch() -> void:
	dirty = true
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
	var size := 0
	for threshold in facilities[id].capacity_levels:
		size += int(level(id) >= threshold)
	return size

func price(id: String, at_level := -1) -> HbtAmount:
	var tier := level(id) if at_level < 0 else at_level
	return _curve[id].price[clampi(tier, 1, CONFIG.max_level) - 1]

func cost_at(id: String, tier: int) -> HbtAmount:
	if tier >= CONFIG.max_level or tier < 1:
		return HbtAmount.new()
	return _curve[id].cost[tier - 1].times(BPS - skill("discount")).divided(BPS)

func quote_upgrade(id: String, quantity: int) -> Dictionary:
	var tier := level(id)
	var total := HbtAmount.new()
	if tier == 0:
		return {"count": 0, "cost": total, "affordable": false}
	var limit := CONFIG.max_level - tier if quantity == 0 else mini(quantity, CONFIG.max_level - tier)
	var count := 0
	while count < limit:
		var next := total.plus(cost_at(id, tier + count))
		if quantity == 0 and not can_afford(next):
			break
		total = next
		count += 1
	return {"count": count, "cost": total, "affordable": count > 0 and can_afford(total)}

func buy_levels(id: String, quantity: int) -> int:
	var quote := quote_upgrade(id, quantity)
	if not quote.affordable or not debit(quote.cost):
		return 0
	levels[id] += quote.count
	touch()
	return quote.count

func gate_open(id: String) -> bool:
	var facility: HbtService = facilities[id]
	return level(id) == 0 and level(facility.prerequisite) >= facility.prerequisite_level \
		and amount("reputation").compare(HbtAmount.from(facility.reputation_gate)) >= 0

func unlock(id: String) -> bool:
	var facility: HbtService = facilities[id]
	if not gate_open(id) or not debit(HbtAmount.from(facility.unlock_cost)):
		return false
	levels[id] = 1
	touch()
	return true

func recruit_cost(id: String) -> HbtAmount:
	return Staff.recruit_cost(facilities[id], crew[id].size(), level(id))

func hire(id: String) -> bool:
	if crew[id].size() >= capacity(id) or not debit(recruit_cost(id)):
		return false
	crew[id].append({"xp": 0, "training": 0, "rank": 1})
	touch()
	return true

func train(id: String, index: int) -> bool:
	var employee: Dictionary = crew[id][index]
	if employee.training >= Staff.MAX_TRAINING or not debit(Staff.training_cost(facilities[id], employee)):
		return false
	employee.training += 1
	touch()
	return true

func promote(id: String, index: int) -> bool:
	var employee: Dictionary = crew[id][index]
	if not Staff.promotion_ready(employee) or not debit(Staff.promotion_cost(facilities[id], employee)):
		return false
	employee.rank += 1
	touch()
	return true

func duration(id: String, worker: int) -> float:
	var facility: HbtService = facilities[id]
	var tier := level(id)
	var time := maxf(facility.minimum_seconds, facility.seconds * pow(0.972, tier - 1))
	if id == "fuel" and tier >= 1 and tier <= LEGACY.service_seconds.size():
		time = LEGACY.service_seconds[tier - 1]
	if worker >= 0:
		time *= float(BPS) / Staff.speed(crew[id][worker])
	return maxf(0.65, time * float(BPS) / (BPS + skill("speed")))

func payout(id: String, tip: int, worker: int, include_boost := true) -> HbtAmount:
	var value := price(id).times(tip).divided(100)
	value = value.times(BPS + skill("revenue")).divided(BPS)
	if worker >= 0:
		value = value.times(Staff.efficiency(crew[id][worker])).divided(BPS)
	if include_boost and boost_until > clock:
		value = value.times(CONFIG.boost_multiplier).divided(BPS)
	return value

func serve(id: String, value: HbtAmount, reputation: int, worker: int) -> void:
	if worker >= 0:
		crew[id][worker].xp = mini(1_000_000, crew[id][worker].xp + 1)
	customers += 1
	per_service[id].count += 1
	per_service[id].gross = per_service[id].gross.plus(value)
	gross = gross.plus(value)
	_sales.append({"time": clock, "value": value})
	credit("reputation", HbtAmount.from(reputation))
	if id in current_event().services:
		if event_day != day_index():
			event_day = day_index()
			event_services = 0
		event_services += 1
		credit("event", HbtAmount.from(1))
	if worker < 0 or skill("collect") > 0:
		credit("cash", value)
	else:
		registers[id] = registers[id].plus(value)
	touch()

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
	touch()
	return total

func income_per_minute() -> HbtAmount:
	while not _sales.is_empty() and int(_sales.front().time) <= clock - 60:
		_sales.pop_front()
	var total := HbtAmount.new()
	for record in _sales:
		total = total.plus(record.value)
	return total

func skill(key: String) -> int:
	for id in equipped:
		if BOOK.MANAGERS[id].skill == key:
			return BOOK.MANAGERS[id].value
	return 0

func assign(id: String) -> bool:
	if not cards.has(id):
		return false
	if id in equipped:
		equipped.erase(id)
	elif equipped.size() < CONFIG.max_active_managers:
		equipped.append(id)
	else:
		return false
	if skill("collect") > 0:
		collect()
	touch()
	return true

func metric(key: String) -> int:
	match key:
		"customers": return customers
		"fuel_level": return level("fuel")
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

func claim_reward(id: String) -> bool:
	for item in BOOK.MILESTONES:
		if item.id != id:
			continue
		if claimed.has(id) or metric(item.counter) < item.goal:
			return false
		claimed[id] = true
		for key in item.reward:
			if key == "card":
				cards[item.reward.card] = true
			else:
				credit(key, HbtAmount.from(item.reward[key]))
		touch()
		return true
	return false

@warning_ignore("integer_division")
func day_index() -> int:
	return maxi(high_water, clock) / 86_400

func current_event() -> Dictionary:
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
	var shortened := CONFIG.arrival_seconds / (1.0 + minf(reputation / 350.0, 0.64))
	return maxf(CONFIG.minimum_arrival_seconds, shortened * float(BPS) / (BPS + skill("traffic")))

func offline_quote(seconds: int) -> HbtAmount:
	var total := HbtAmount.new()
	var staffed := metric("staff")
	if staffed == 0:
		return total
	for id in facilities:
		for worker in range(crew[id].size()):
			# Conservative allocation based on staffing, cadence and distance to the bay.
			var seconds_per_job := maxf(duration(id, worker) + 11.0 + staffed * 1.1, arrival_period() * staffed)
			var jobs := floori(seconds * CONFIG.offline_efficiency / (100.0 * seconds_per_job))
			total = total.plus(payout(id, 100, worker, false).times(jobs))
	return total

func capture_absence(wall: int, monotonic_elapsed := -1) -> HbtAmount:
	var trusted_wall := wall
	var delta := wall - high_water
	if high_water == 0:
		delta = 0
	elif monotonic_elapsed >= 0 and absi(delta - monotonic_elapsed) > CONFIG.clock_tolerance_seconds:
		delta = monotonic_elapsed
		trusted_wall = high_water + monotonic_elapsed
	var elapsed := clampi(delta, 0, CONFIG.offline_cap_seconds)
	var grant := offline_quote(elapsed)
	high_water = maxi(high_water, trusted_wall)
	clock = trusted_wall
	if not grant.empty():
		offline_pending = offline_pending.plus(grant)
		offline_seconds = mini(CONFIG.offline_cap_seconds, offline_seconds + elapsed)
		offline_prepared.emit()
	dirty = true
	return grant

func redeem_offline(bonus := false, endorsed_base: HbtAmount = null) -> HbtAmount:
	if offline_pending.empty():
		return HbtAmount.new()
	var value := offline_pending
	if bonus and endorsed_base != null:
		var eligible := endorsed_base if endorsed_base.compare(offline_pending) <= 0 else offline_pending
		value = value.plus(eligible)
	offline_pending = HbtAmount.new()
	offline_seconds = 0
	credit("cash", value)
	gross = gross.plus(value)
	touch()
	return value
