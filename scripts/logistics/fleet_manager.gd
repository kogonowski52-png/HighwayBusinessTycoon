extends RefCounted
## Owns the campaign's fleet. Orders and payroll share the normal atomic save.

const Catalog = preload("res://data/logistics/fleet.gd")
const Atlas = preload("res://data/world/atlas.gd")

var vehicles: Dictionary = {}
var drivers: Dictionary = {}
var serial := 1
var revision := 0

func snapshot() -> Dictionary:
	return {"vehicles": vehicles, "drivers": drivers, "serial": serial}

func restore(source: Dictionary) -> void:
	vehicles = {}
	drivers = {}
	serial = maxi(1, HbtEconomy.counter(source.get("serial", 1)))
	var saved_drivers := HbtEconomy.safe_dict(source.get("drivers"))
	for id: String in saved_drivers:
		if drivers.size() >= Catalog.MAX_TRUCKS or not id.is_valid_int():
			continue
		var data := HbtEconomy.safe_dict(saved_drivers[id])
		if not Atlas.DESTINATIONS.has(data.get("home", "")):
			continue
		drivers[id] = {
			"home": data.home, "rank": clampi(int(data.get("rank", 1)), 1, Catalog.MAX_DRIVER_RANK),
			"training": HbtEconomy.counter(data.get("training")), "xp": HbtEconomy.counter(data.get("xp")), "rushed": data.get("rushed") == true,
		}
		serial = maxi(serial, int(id) + 1)
	var assigned := {}
	var saved_vehicles := HbtEconomy.safe_dict(source.get("vehicles"))
	for id: String in saved_vehicles:
		if vehicles.size() >= Catalog.MAX_TRUCKS or not id.is_valid_int():
			continue
		var data := HbtEconomy.safe_dict(saved_vehicles[id])
		var kind: String = str(data.get("kind", ""))
		var home: String = str(data.get("home", ""))
		if not Catalog.TYPES.has(kind) or not Atlas.DESTINATIONS.has(home):
			continue
		var driver: String = str(data.get("driver", ""))
		if not drivers.has(driver) or assigned.has(driver) or drivers[driver].home != home:
			driver = ""
		if not driver.is_empty():
			assigned[driver] = true
		var trailer := str(data.get("trailer", ""))
		vehicles[id] = {
			"kind": kind, "home": home, "driver": driver, "level": clampi(int(data.get("level", 1)), 1, 12),
			"condition": clampi(int(data.get("condition", 100)), 0, 100),
			"trailer": trailer if kind == "tractor" and Catalog.TRAILERS.has(trailer) else "",
			"garage": sanitize_trailers(data.get("garage", {})),
		}
		if not vehicles[id].trailer.is_empty():
			vehicles[id].garage[vehicles[id].trailer] = true
		serial = maxi(serial, int(id) + 1)
	revision += 1

func sanitize_trailers(value: Variant) -> Dictionary:
	var flags := HbtEconomy.safe_dict(value)
	var valid := {}
	for id: String in Catalog.TRAILERS:
		if flags.get(id) == true:
			valid[id] = true
	return valid

func enabled(estate: HbtEconomy) -> bool:
	return estate.level("fuel") >= Catalog.DEPOT_LEVEL and not estate.storage.read_only

func busy(_vehicle: String) -> bool:
	return false # Overridden by the dispatch ledger.

func buy(world: RefCounted, kind: String) -> bool:
	var estate: HbtEconomy = world.current()
	if not enabled(estate) or not Catalog.TYPES.has(kind) or vehicles.size() >= Catalog.MAX_TRUCKS:
		return false
	var id := str(serial)
	return transact(world, int(Catalog.TYPES[kind].price), func() -> void:
		serial += 1
		vehicles[id] = {"kind": kind, "home": estate.district, "driver": "", "level": 1,
			"condition": 100, "trailer": "", "garage": {}})

func hire(world: RefCounted) -> bool:
	var estate: HbtEconomy = world.current()
	if not enabled(estate) or drivers.size() >= Catalog.MAX_TRUCKS:
		return false
	var id := str(serial)
	return transact(world, Catalog.DRIVER_PRICE, func() -> void:
		serial += 1
		drivers[id] = {"home": estate.district, "rank": 1, "training": 0, "xp": 0})

func owner_can_edit(world: RefCounted, vehicle: String) -> bool:
	return vehicles.has(vehicle) and world.active == vehicles[vehicle].home and not busy(vehicle)

func assign(world: RefCounted, vehicle: String, driver: String) -> bool:
	if not owner_can_edit(world, vehicle) or vehicles[vehicle].driver == driver:
		return false
	if not driver.is_empty():
		if not drivers.has(driver) or drivers[driver].home != world.active or driver_busy(driver):
			return false
	return transact(world, 0, func() -> void: vehicles[vehicle].driver = driver)

func driver_busy(driver: String) -> bool:
	for data: Dictionary in vehicles.values():
		if data.driver == driver:
			return true
	return false

func driver_working(driver: String) -> bool:
	for vehicle: String in vehicles:
		if vehicles[vehicle].driver == driver and busy(vehicle):
			return true
	return false

func train(world: RefCounted, driver: String) -> bool:
	if not drivers.has(driver) or driver_working(driver):
		return false
	var data: Dictionary = drivers[driver]
	var rank: int = data.rank
	if data.home != world.active or data.training > 0 or rank >= Catalog.MAX_DRIVER_RANK:
		return false
	var estate: HbtEconomy = world.current()
	return transact(world, training_price(rank), func() -> void:
		data.training = estate.clock + 30 + rank * 30
		data.rushed = false)

func training_price(rank: int) -> int:
	return 110 + 135 * rank

func complete_training(now: int) -> bool:
	var changed := false
	for data: Dictionary in drivers.values():
		if data.training > 0 and data.training <= now:
			data.rank = mini(data.rank + 1, Catalog.MAX_DRIVER_RANK)
			data.training = 0
			changed = true
	if changed:
		revision += 1
	return changed

func trailer(world: RefCounted, vehicle: String, kind: String) -> bool:
	if not owner_can_edit(world, vehicle) or not Catalog.TRAILERS.has(kind):
		return false
	var data: Dictionary = vehicles[vehicle]
	if data.kind != "tractor" or data.trailer == kind:
		return false
	var price := 0 if data.garage.has(kind) else int(Catalog.TRAILERS[kind].price)
	return transact(world, price, func() -> void:
		data.garage[kind] = true
		data.trailer = kind)

func upgrade_price(vehicle: String) -> int:
	var data: Dictionary = vehicles[vehicle]
	return maxi(200, int(Catalog.TYPES[data.kind].price * (.18 + float(data.level) * .085)))

func repair_price(vehicle: String) -> int:
	return (100 - int(vehicles[vehicle].condition)) * (3 if vehicles[vehicle].kind == "van" else 8)

func upgrade(world: RefCounted, vehicle: String) -> bool:
	if not owner_can_edit(world, vehicle) or vehicles[vehicle].level >= 12:
		return false
	return transact(world, upgrade_price(vehicle), func() -> void: vehicles[vehicle].level += 1)

func repair(world: RefCounted, vehicle: String) -> bool:
	if not owner_can_edit(world, vehicle) or vehicles[vehicle].condition >= 100:
		return false
	return transact(world, repair_price(vehicle), func() -> void: vehicles[vehicle].condition = 100)

func specifications(vehicle: String) -> Dictionary:
	var data: Dictionary = vehicles[vehicle]
	var unit: Dictionary = Catalog.TYPES[data.kind]
	var carrier: Dictionary = Catalog.TRAILERS.get(data.trailer, unit)
	var driver: Dictionary = drivers.get(data.driver, {})
	var rank := int(driver.get("rank", 1))
	var xp := int(driver.get("xp", 0))
	var extras := int(data.level - 1)
	return {"capacity": int(carrier.capacity) + mini(5, extras / 2) if carrier.capacity > 0 else 0,
		"speed": float(unit.speed) * (1.0 + .045 * extras + .055 * (rank - 1) + minf(.14, xp * .003)),
		"running": maxi(9, roundi(float(unit.running) * (1.0 - extras * .025 - (rank - 1) * .04))),
		"cargo": carrier.cargo, "model": carrier.model}

func transact(world: RefCounted, price: int, operation: Callable) -> bool:
	var estate: HbtEconomy = world.current()
	if estate.storage.read_only:
		return false
	var cash := estate.amount("cash")
	var spending := estate.spent
	var previous := snapshot().duplicate(true)
	if not estate.debit(HbtAmount.from(price)):
		return false
	operation.call()
	if world.checkpoint() != OK:
		restore(previous)
		estate.wallet.cash = cash
		estate.spent = spending
		return false
	revision += 1
	estate.touch()
	return true
