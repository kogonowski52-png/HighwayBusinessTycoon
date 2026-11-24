extends Resource

@export var opening_cash := 120
@export var upgrade_costs: Array[int] = [155, 280, 470, 750]
@export var sale_prices: Array[int] = [35, 48, 64, 82, 110]
@export var service_seconds: Array[float] = [2.7, 2.35, 2.0, 1.7, 1.35]

func upgrade_cost(level: int) -> int:
	return upgrade_costs[level - 1] if level <= upgrade_costs.size() else 0
