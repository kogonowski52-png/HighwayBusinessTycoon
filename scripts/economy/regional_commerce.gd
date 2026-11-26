extends RefCounted
## Reservations are held only while a visit is active. Paid leases return on the district clock.

const SITES := {"logistics": "freight", "warehouse": "freight", "dealership": "motor", "mall": "retail"}
const SHOWROOM_MODELS := ["vela", "sprint", "coast", "regency"]
const RESTOCK_SECONDS := 12.0
const LEASE_SECONDS := 108
const COUNTERS := ["inbound", "outbound", "sold", "shoppers"]

var state: Dictionary = {}
var reservations: Dictionary = {}
var operations: Dictionary = {}
var timed_sites: Array[String] = []
var restock: Dictionary = {}
var showroom: Array = SHOWROOM_MODELS

func configure(facilities: Dictionary, district: String) -> void:
	if district == "luxury":
		showroom = ["onyx", "lumen", "sovereign", "regency"]
	for id: String in facilities:
		var kind: String = facilities[id].venue_kind
		if kind.is_empty():
			kind = SITES.get(id, "")
		if kind in ["freight", "cold", "motor", "retail", "rent", "scooter"]:
			operations[id] = kind
			if kind in ["motor", "rent", "scooter"]:
				timed_sites.append(id)

func reset() -> void:
	state.clear()
	reservations.clear()
	restock.clear()

func record(id: String) -> Dictionary:
	if not state.has(id):
		var kind: String = operations.get(id, "")
		var stock := 2 if kind == "motor" else 3 if kind in ["rent", "scooter"] else 0
		state[id] = {"stock": stock, "inbound": 0, "outbound": 0, "sold": 0, "shoppers": 0}
		if kind in ["rent", "scooter"]:
			state[id]["returns"] = []
	return state[id]

func capacity(id: String, tier: int) -> int:
	match operations.get(id, ""):
		"motor": return 2 + floori(tier / 25.0)
		"rent", "scooter": return 3 + floori(tier / 18.0)
		_: return 6 + floori(tier / 5.0)

func begin(ticket: HbtVisit, tier: int) -> void:
	var id := ticket.service
	if not operations.has(id):
		return
	var inventory := record(id)
	var reserved: Dictionary = holds(id)
	var stock := int(inventory.stock)
	var available := stock - int(reserved.outgoing)
	match operations[id]:
		"freight", "cold":
			var room := stock + int(reserved.incoming) < capacity(id, tier)
			var outbound := available > 0 and (not room or (ticket.number + ticket.bay) % 3 != 0)
			if outbound or room:
				ticket.trade = "outbound" if outbound else "inbound"
				ticket.stock_delta = -1 if outbound else 1
		"motor":
			ticket.trade = "sale" if available > 0 else "viewing"
			if ticket.trade == "sale":
				ticket.stock_delta = -1
				ticket.sold_model = showroom[(int(inventory.sold) + int(reserved.outgoing)) % showroom.size()]
		"rent", "scooter":
			ticket.trade = "lease" if available > 0 else "viewing"
			ticket.stock_delta = -1 if available > 0 else 0
		"retail":
			ticket.trade = "retail"
	reserved.incoming += maxi(0, ticket.stock_delta)
	reserved.outgoing += maxi(0, -ticket.stock_delta)

func holds(id: String) -> Dictionary:
	if not reservations.has(id):
		reservations[id] = {"incoming": 0, "outgoing": 0}
	return reservations[id]

func settle(ticket: HbtVisit, tier: int, clock := 0) -> void:
	if ticket.trade.is_empty():
		return
	var inventory := record(ticket.service)
	release(ticket)
	inventory.stock = clampi(int(inventory.stock) + ticket.stock_delta, 0, capacity(ticket.service, tier))
	match ticket.trade:
		"inbound", "outbound": inventory[ticket.trade] += 1
		"sale": inventory.sold += 1
		"retail": inventory.shoppers += 1
		"lease":
			inventory.outbound += 1
			inventory.returns.append(clock + LEASE_SECONDS)

func release(ticket: HbtVisit) -> void:
	var held := holds(ticket.service)
	held.incoming -= maxi(0, ticket.stock_delta)
	held.outgoing -= maxi(0, -ticket.stock_delta)

func tick(seconds: float, levels: Dictionary, clock: int) -> bool:
	var changed := false
	for id in timed_sites:
		var tier := int(levels.get(id, 0))
		if tier <= 0:
			continue
		var goods := record(id)
		var limit := capacity(id, tier)
		if operations[id] != "motor":
			var due: Array = goods.returns
			if not due.is_empty() and due[0] <= clock:
				due.pop_front()
				goods.stock = mini(limit, int(goods.stock) + 1)
				goods.inbound += 1
				changed = true
			continue
		if int(goods.stock) >= limit:
			restock[id] = 0.0
			continue
		restock[id] = float(restock.get(id, 0.0)) + seconds
		if float(restock[id]) >= RESTOCK_SECONDS:
			restock[id] = float(restock[id]) - RESTOCK_SECONDS
			goods.stock += 1
			changed = true
	return changed

func restore(values: Dictionary, levels: Dictionary) -> void:
	for id: String in operations:
		if not levels.has(id) or not values.get(id) is Dictionary:
			continue
		var old: Dictionary = values[id]
		var inventory := record(id)
		inventory.stock = clampi(int(old.get("stock", inventory.stock)), 0, capacity(id, levels[id]))
		for key in COUNTERS:
			inventory[key] = clampi(int(old.get(key, 0)), 0, 1_000_000_000)
		if inventory.has("returns") and old.get("returns") is Array:
			for observed: Variant in old.returns.slice(0, capacity(id, levels[id])):
				if observed is int and observed >= 0:
					inventory.returns.append(observed)
			inventory.returns.sort()

func statistics(id: String, tier: int) -> Dictionary:
	if not operations.has(id):
		return {}
	var result := record(id).duplicate()
	result["capacity"] = capacity(id, tier)
	return result
