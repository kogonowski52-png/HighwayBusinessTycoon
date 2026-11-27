extends "res://scripts/logistics/fleet_manager.gd"
## Every paid run has one reserved truck/driver and one persisted settlement time.

const Orders = preload("res://data/logistics/contracts.gd")
const AUTO_MANAGERS := ["dev", "iman", "soren"]
const SHOW_SECONDS := 13

var jobs: Dictionary = {}
var receipts: Dictionary = {}
var cooldowns: Dictionary = {}
var automatic := {}
var completed := 0
var freight_total := HbtAmount.new()
var region_totals := {}

func snapshot() -> Dictionary:
	var source: Dictionary = super.snapshot()
	source.merge({"jobs": jobs, "receipts": receipts, "cooldowns": cooldowns, "automatic": automatic,
		"completed": completed, "freight_total": freight_total.decimal(), "region_totals": region_totals})
	return source

func restore(source: Dictionary) -> void:
	super.restore(source)
	jobs = {}
	cooldowns = {}
	receipts = {}
	automatic = {}
	region_totals = {}
	completed = HbtEconomy.counter(source.get("completed"))
	freight_total = HbtAmount.from(source.get("freight_total", "0"))
	for key: String in HbtEconomy.safe_dict(source.get("cooldowns")):
		if not Orders.contract(key).is_empty():
			cooldowns[key] = HbtEconomy.counter(source.cooldowns[key])
	for key: String in HbtEconomy.safe_dict(source.get("receipts")):
		if Atlas.DESTINATIONS.has(key):
			receipts[key] = HbtEconomy.safe_dict(source.receipts[key])
	for key: String in HbtEconomy.safe_dict(source.get("region_totals")):
		if Atlas.DESTINATIONS.has(key):
			region_totals[key] = HbtAmount.from(source.region_totals[key]).decimal()
	for key: String in HbtEconomy.safe_dict(source.get("automatic")):
		if Atlas.DESTINATIONS.has(key) and source.automatic[key] == true:
			automatic[key] = true
	for id: String in HbtEconomy.safe_dict(source.get("jobs")):
		var data := HbtEconomy.safe_dict(source.jobs[id])
		var order := Orders.contract(str(data.get("order", "")))
		var truck: Dictionary = vehicles.get(str(data.get("truck", "")), {})
		var start := HbtEconomy.counter(data.get("start"))
		var due := HbtEconomy.counter(data.get("due"))
		if not id.is_valid_int() or order.is_empty() or truck.is_empty():
			continue
		if truck.home != order.from or not drivers.has(truck.driver) or start >= due or due - start > 1200:
			continue
		if busy(str(data.truck)) or job_for_order(str(data.order)):
			continue
		jobs[id] = {"order": data.order, "truck": data.truck, "start": start, "due": due,
			"reward": HbtAmount.from(data.get("reward", "0")).decimal(), "cost": clampi(int(data.get("cost", 0)), 0, 20_000),
			"rushed": data.get("rushed") == true}
		serial = maxi(serial, int(id) + 1)

func busy(vehicle: String) -> bool:
	return jobs.values().any(func(job: Dictionary) -> bool: return job.truck == vehicle)

func job_for_order(order: String) -> bool:
	return jobs.values().any(func(job: Dictionary) -> bool: return job.order == order)

func quote(world: RefCounted, id: String, vehicle: String) -> Dictionary:
	var order := Orders.contract(id)
	if order.is_empty() or not vehicles.has(vehicle) or not world.districts.has(order.from):
		return {}
	var estate: HbtEconomy = world.districts[order.from]
	var truck: Dictionary = vehicles[vehicle]
	var spec := specifications(vehicle)
	var driver: Dictionary = drivers.get(truck.driver, {})
	var difficulty: int = order.difficulty
	var load_size: int = order.load
	var fee := int(spec.running) * (difficulty + 1) + load_size * (6 + difficulty * 4)
	var reward := (125 + load_size * (19 + difficulty * 20) + difficulty * 160) * (100 + mini(120, estate.level("fuel"))) / 100
	var duration := maxi(24, ceili(float(order.seconds) / (spec.speed * estate.works.dispatch_speed())))
	var now: int = world.current().clock
	return {"reward": reward, "cost": fee, "duration": duration, "parts": load_size,
		"vehicle": order.cargo in spec.cargo and spec.capacity >= load_size,
		"driver": not driver.is_empty() and int(driver.get("training", 0)) == 0 and int(driver.get("rank", 0)) >= maxi(1, difficulty),
		"condition": truck.condition >= Catalog.MIN_CONDITION,
		"origin": truck.home == order.from and world.active == order.from,
		"destination": world.districts.has(order.to),
		"available": not busy(vehicle) and not job_for_order(id) and now >= int(cooldowns.get(id, 0)),
		"cash": estate.can_afford(HbtAmount.from(fee)) and enabled(estate)}

func ready(quote_data: Dictionary) -> bool:
	if quote_data.is_empty():
		return false
	for key in ["vehicle", "driver", "condition", "origin", "destination", "available", "cash"]:
		if not quote_data[key]:
			return false
	return true

func dispatch(world: RefCounted, id: String, vehicle: String) -> bool:
	var offer := quote(world, id, vehicle)
	if not ready(offer):
		return false
	var now: int = world.current().clock
	return transact(world, offer.cost, func() -> void:
		var key := str(serial)
		serial += 1
		jobs[key] = {"order": id, "truck": vehicle, "start": now, "due": now + int(offer.duration),
			"reward": HbtAmount.from(offer.reward).decimal(), "cost": offer.cost})

func advance(world: RefCounted, now: int, can_automate := true) -> bool:
	var changed := complete_training(now)
	if world.storage.read_only:
		return changed
	for id: String in jobs.keys():
		var job: Dictionary = jobs[id]
		if int(job.due) <= now:
			finish(world, job, now)
			jobs.erase(id)
			changed = true
	if changed:
		revision += 1
		world.current().dirty = true
	if can_automate and automatic.get(world.active, false) and has_dispatcher(world.current()):
		offer_short_run(world)
	return changed

func finish(world: RefCounted, job: Dictionary, now: int) -> void:
	var order := Orders.contract(job.order)
	if not world.districts.has(order.from) or not world.districts.has(order.to):
		return
	var depot: HbtEconomy = world.districts[order.from]
	var destination: HbtEconomy = world.districts[order.to]
	var truck: Dictionary = vehicles[job.truck]
	var driver: Dictionary = drivers[truck.driver]
	var payment := HbtAmount.from(job.reward)
	depot.credit("cash", payment)
	depot.credit("reputation", HbtAmount.from(int(order.difficulty) + 1))
	destination.deliver_supplies(order.cargo, order.load)
	truck.condition = maxi(0, int(truck.condition) - maxi(3, 7 + int(order.difficulty) * 3 - int(truck.level) / 2))
	driver.xp += 1
	completed += 1
	freight_total = freight_total.plus(payment)
	region_totals[order.from] = HbtAmount.from(region_totals.get(order.from, "0")).plus(payment).decimal()
	receipts[order.from] = {"order": order.id, "cash": payment.decimal(), "at": now}
	cooldowns[order.id] = now + 30 + int(order.difficulty) * 30
	depot.touch()

func has_dispatcher(estate: HbtEconomy) -> bool:
	return estate.equipped.any(func(id: String) -> bool:
		var site: String = estate.BOOK.MANAGERS[id].get("site", "")
		return id in AUTO_MANAGERS or site in ["logistics", "transfer", "terminal", "distribution", "transport", "logging"])

func toggle_automatic(world: RefCounted) -> bool:
	if not has_dispatcher(world.current()):
		return false
	return transact(world, 0, func() -> void: automatic[world.active] = not automatic.get(world.active, false))

func offer_short_run(world: RefCounted) -> void:
	# An assigned dispatcher runs a local route. Remote depots can finish jobs but cannot spend while absent.
	var id := "%s/0" % world.active
	for truck: String in vehicles:
		if ready(quote(world, id, truck)):
			dispatch(world, id, truck)
			return

func visible_jobs(region: String, now: int) -> Dictionary:
	var result := {}
	for id: String in jobs:
		var job: Dictionary = jobs[id]
		var order := Orders.contract(job.order)
		if order.from == region and now - int(job.start) < SHOW_SECONDS:
			result[id] = {"arrival": false, "job": job}
		elif order.to == region and int(job.due) - now <= SHOW_SECONDS:
			result[id] = {"arrival": true, "job": job}
	return result
