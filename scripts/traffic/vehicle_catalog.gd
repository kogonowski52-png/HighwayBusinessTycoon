extends RefCounted

const DATA := preload("res://data/visual/vehicle_catalog.gd")

static func definition(id: String) -> Dictionary:
	return DATA.VEHICLES[id]

static func roster() -> Array:
	return DATA.VEHICLES.keys()

static func customers() -> Array:
	return DATA.CUSTOMERS
