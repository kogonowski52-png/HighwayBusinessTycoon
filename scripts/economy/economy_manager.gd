extends RefCounted

signal changed

const PROFILE = preload("res://data/station.tres")
const SaveManager = preload("res://scripts/core/save_manager.gd")

var storage := SaveManager.new()
var cash := 120
var level := 1
var customers := 0
var language := "pl"
var low_power := false
var save_error := OK

func restore() -> void:
	var file := storage.read_progress()
	cash = maxi(0, int(file.get_value("station", "cash", PROFILE.opening_cash)))
	level = clampi(int(file.get_value("station", "level", 1)), 1, PROFILE.sale_prices.size())
	customers = maxi(0, int(file.get_value("station", "customers", 0)))
	language = "en" if file.get_value("settings", "language", "pl") == "en" else "pl"
	low_power = bool(file.get_value("settings", "low_power", false))

func persist() -> void:
	var file := ConfigFile.new()
	file.set_value("station", "cash", cash)
	file.set_value("station", "level", level)
	file.set_value("station", "customers", customers)
	file.set_value("settings", "language", language)
	file.set_value("settings", "low_power", low_power)
	save_error = storage.write_progress(file)
	changed.emit()

func sell() -> int:
	var payout: int = PROFILE.sale_prices[level - 1]
	cash += payout
	customers += 1
	persist()
	return payout

func upgrade() -> bool:
	var cost: int = PROFILE.upgrade_cost(level)
	if cost == 0 or cash < cost:
		return false
	cash -= cost
	level += 1
	persist()
	return true
