extends RefCounted
## Inventory is changed by settled visits. In-flight reservations live with dispatch.

const SITES := ["logistics", "warehouse", "dealership", "mall"]
const SHOWROOM_MODELS := ["vela", "sprint", "coast", "regency"]
const RESTOCK_SECONDS := 12.0
const COUNTERS := ["inbound", "outbound", "sold", "shoppers"]

var state: Dictionary = {}
var reservations: Dictionary = {}
var restock := 0.0

func reset() -> void:
	state.clear()
	reservations.clear()
	restock = 0.0

func record(id: String) -> Dictionary:
	if not state.has(id):
		state[id] = {"stock": 2 if id == "dealership" else 0, "inbound": 0, "outbound": 0, "sold": 0, "shoppers": 0}
	return state[id]

func capacity(id: String, tier: int) -> int:
	return 2 + floori(tier / 25.0) if id == "dealership" else 6 + floori(tier / 5.0)

func begin(ticket: HbtVisit, tier: int) -> void:
	var id := ticket.service
	if id not in SITES:
		return
	var inventory := record(id)
	var reserved: Dictionary = holds(id)
	var stock := int(inventory.stock)
	var available := stock - int(reserved.outgoing)
	match id:
		"logistics", "warehouse":
			var room := stock + int(reserved.incoming) < capacity(id, tier)
			var outbound := available > 0 and (not room or (ticket.number + ticket.bay) % 3 != 0)
			if outbound or room:
				ticket.trade = "outbound" if outbound else "inbound"
				ticket.stock_delta = -1 if outbound else 1
		"dealership":
			ticket.trade = "sale" if available > 0 else "viewing"
			if ticket.trade == "sale":
				ticket.stock_delta = -1
				ticket.sold_model = SHOWROOM_MODELS[(int(inventory.sold) + int(reserved.outgoing)) % SHOWROOM_MODELS.size()]
		"mall":
			ticket.trade = "retail"
	reserved.incoming += maxi(0, ticket.stock_delta)
	reserved.outgoing += maxi(0, -ticket.stock_delta)

func holds(id: String) -> Dictionary:
	if not reservations.has(id):
		reservations[id] = {"incoming": 0, "outgoing": 0}
	return reservations[id]

func settle(ticket: HbtVisit, tier: int) -> void:
	if ticket.trade.is_empty():
		return
	var inventory := record(ticket.service)
	release(ticket)
	inventory.stock = clampi(int(inventory.stock) + ticket.stock_delta, 0, capacity(ticket.service, tier))
	match ticket.trade:
		"inbound", "outbound": inventory[ticket.trade] += 1
		"sale": inventory.sold += 1
		"retail": inventory.shoppers += 1

func release(ticket: HbtVisit) -> void:
	var held := holds(ticket.service)
	held.incoming -= maxi(0, ticket.stock_delta)
	held.outgoing -= maxi(0, -ticket.stock_delta)

func tick(seconds: float, level: int) -> bool:
	if level <= 0:
		return false
	var goods := record("dealership")
	if int(goods.stock) >= capacity("dealership", level):
		restock = 0.0
		return false
	restock += seconds
	if restock < RESTOCK_SECONDS:
		return false
	restock -= RESTOCK_SECONDS
	goods.stock += 1
	return true

func restore(values: Dictionary, levels: Dictionary) -> void:
	for id in SITES:
		if not levels.has(id) or not values.get(id) is Dictionary:
			continue
		var old: Dictionary = values[id]
		var inventory := record(id)
		inventory.stock = clampi(int(old.get("stock", inventory.stock)), 0, capacity(id, levels[id]))
		for key in COUNTERS:
			inventory[key] = clampi(int(old.get(key, 0)), 0, 1_000_000_000)

func statistics(id: String, tier: int) -> Dictionary:
	if id not in SITES:
		return {}
	var result := record(id).duplicate()
	result["capacity"] = capacity(id, tier)
	return result
