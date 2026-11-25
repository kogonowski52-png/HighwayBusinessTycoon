extends RefCounted

const DATA = preload("res://data/economy/customers.gd")
const Catalog = preload("res://scripts/traffic/vehicle_catalog.gd")

var random := RandomNumberGenerator.new()

func _init(seed: int) -> void:
	random.seed = seed

func customer(economy: HbtEconomy, forced := "") -> Dictionary:
	var weights := {}
	for key in DATA.PROFILES:
		var row: Dictionary = DATA.PROFILES[key]
		if economy.metric("reputation") >= int(row.get("minimum_rep", 0)) \
			and (key != "trucker" or economy.level("truck") > 0) \
			and (key != "electric" or economy.level("charge") > 0):
			weights[key] = row.weight
	var id := weighted(weights) if forced.is_empty() else forced
	var profile: Dictionary = DATA.PROFILES[id]
	var strength := HbtAmount.new()
	for facility in profile.services:
		if economy.level(facility) > 0 and economy.price(facility).compare(strength) > 0:
			strength = economy.price(facility)
	var budget := strength.times(random.randi_range(profile.budget.x, profile.budget.y)).divided(100)
	var model: String = profile.car
	if id == "trucker" and random.randf() < 0.45:
		model = "atlas"
	var vehicle := Catalog.definition(model)
	return {"type": id, "budget": budget, "patience": profile.patience, "tip": profile.tip,
		"reputation": profile.rep, "model": model, "length": vehicle.length, "width": vehicle.width,
		"paint": random.randi_range(0, 1), "kind": "truck" if id == "trucker" else "car"}

func pick(economy: HbtEconomy, visitor: Dictionary, queues: Dictionary, free_only: Dictionary = {}) -> String:
	var weights := {}
	var profile: Dictionary = DATA.PROFILES[visitor.type]
	for id in profile.services:
		if economy.level(id) == 0 or (not free_only.is_empty() and not free_only.get(id, false)):
			continue
		if economy.price(id).compare(visitor.budget) > 0 or not accepts(economy.facilities[id], visitor):
			continue
		# An occupied building remains a choice, but the customer prefers the shorter wait.
		weights[id] = maxi(1, floori(float(profile.services[id]) * economy.attraction(id) / (1.0 + queues.get(id, 0) * 0.63)))
	return weighted(weights)

static func accepts(facility: HbtService, visitor: Dictionary) -> bool:
	var electric: bool = visitor.model == "pulse"
	if facility.vehicle_kind == "electric":
		return electric
	return facility.vehicle_kind == visitor.kind and not (facility.id == "fuel" and electric)

func weighted(weights: Dictionary) -> String:
	var sum := 0
	for weight in weights.values():
		sum += int(weight)
	if sum <= 0:
		return ""
	var point := random.randi_range(1, sum)
	for key in weights:
		point -= int(weights[key])
		if point <= 0:
			return key
	return ""
