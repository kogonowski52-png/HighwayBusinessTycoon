extends "res://tests/run_checks.gd"

const Fleet = preload("res://data/logistics/fleet.gd")
const Orders = preload("res://data/logistics/contracts.gd")
const Atlas = preload("res://data/world/atlas.gd")
const START := 1_804_980_000
var save_path := "/tmp/hbt-transport-%d.cfg" % OS.get_process_id()

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var world := campaign(START)
	var freight = world.freight
	expect(not freight.buy(world, "van"), "level four licenses the depot")
	fund(world.current())
	var wallet := world.current().amount("cash")
	expect(freight.buy(world, "van") and world.current().amount("cash").compare(wallet.minus(HbtAmount.from(740))) == 0, "purchase charges exactly the list price")
	expect(freight.hire(world) and freight.assign(world, "1", "2"), "one driver is assigned to van")
	expect(freight.buy(world, "tractor") and not freight.assign(world, "3", "2"), "driver cannot be double booked")
	expect(freight.trailer(world, "3", "deck") and freight.specifications("3").capacity == 21, "flatbed capacity reflects the bought trailer")
	expect(freight.trailer(world, "3", "cold") and freight.specifications("3").cargo.has("food"), "swapping changes cold-chain eligibility")
	wallet = world.current().amount("cash")
	expect(freight.trailer(world, "3", "deck") and world.current().amount("cash").compare(wallet) == 0, "already owned trailer is not charged twice")
	expect(freight.upgrade(world, "1") and freight.specifications("1").speed > Fleet.TYPES.van.speed, "upgrade speeds up transport")
	expect(freight.train(world, "2") and not freight.dispatch(world, "north/0", "1"), "a trainee must finish training before dispatch")
	world.current().clock = START + 61
	expect(freight.advance(world, START + 61) and freight.drivers["2"].rank == 2, "complete training by a real clock")
	expect(not freight.dispatch(world, "north/1", "1"), "van cannot ship to a locked region")
	expect(not freight.dispatch(world, "north/2", "1"), "van cannot haul fuel")
	expect(world.boost.extend_confirmed(START + 61), "ad boost window can overlap a transport contract")
	var quote: Dictionary = freight.quote(world, "north/0", "1")
	wallet = world.current().amount("cash")
	expect(freight.dispatch(world, "north/0", "1") and freight.busy("1") and freight.jobs.size() == 1, "dispatch persists truck and driver's reservation")
	expect(not freight.dispatch(world, "north/0", "1") and not freight.assign(world, "1", "") and not freight.train(world, "2"),
		"reserved equipment and driver remain locked")
	var ticket: Dictionary = freight.jobs.values()[0]
	var arrived := campaign(int(ticket.due))
	var north: HbtEconomy = arrived.current()
	var payout := wallet.minus(HbtAmount.from(quote.cost)).plus(HbtAmount.from(quote.reward))
	expect(north.amount("cash").compare(payout) == 0 and arrived.freight.completed == 1, "restore settles the exact fixed freight quote under BOOST")
	expect(arrived.freight.jobs.is_empty() and arrived.freight.vehicles["1"].condition < 100 and arrived.freight.drivers["2"].xp == 1,
		"settlement updates wear and route experience")
	expect(north.supplies.parts == 2, "arrival unloads two real units")
	expect(north.level("workshop") > 0, "workshop can be built with normal economics")
	var efficient := north.duration("workshop", -1)
	north.serve("workshop", HbtAmount.from(18), 1, -1)
	north.serve("workshop", HbtAmount.from(18), 1, -1)
	expect(north.supplies.is_empty() and north.duration("workshop", -1) > efficient, "supplies accelerate two paid visits then normal service continues")
	var repeat := campaign(int(ticket.due) + 3)
	expect(repeat.freight.completed == 1 and repeat.current().amount("cash").compare(payout) == 0,
		"reopening never repeats freight payment")
	expect(repeat.freight.repair(repeat, "1") and repeat.freight.vehicles["1"].condition == 100, "service restores condition for its quoted price")
	for district: String in Atlas.DESTINATIONS:
		if district != "north":
			expect(repeat.travel(district) == OK, "real campaign opens carrier district " + district)
			fund(repeat.current())
	expect(repeat.travel("north") == OK, "flight returns to the same carrier")
	check_manifests()
	var material_bill := repeat.current().quote_upgrade("fuel", 10)
	repeat.current().deliver_supplies("materials", 2)
	var discounted := repeat.current().quote_upgrade("fuel", 10)
	expect(discounted.cost.compare(material_bill.cost.times(95).divided(100)) == 0
		and repeat.current().buy_levels("fuel", 10) == 10 and repeat.current().supplies.materials == 1,
		"construction cargo reduces the real invoice and spends one shipment unit")
	var dest_cash: HbtAmount = repeat.districts.valley.amount("cash")
	wallet = repeat.current().amount("cash")
	var outbound: Dictionary = repeat.freight.quote(repeat, "north/1", "1")
	expect(repeat.freight.dispatch(repeat, "north/1", "1") and repeat.travel("valley") == OK, "departing from a region keeps the job in the campaign")
	var due: int = repeat.freight.jobs.values().front().due
	repeat.current().clock = due - 4
	expect(repeat.freight.visible_jobs("valley", due - 4).size() == 1 and repeat.freight.visible_jobs("north", due - 4).is_empty(),
		"inbound visual follows only the destination's approach")
	expect(repeat.freight.advance(repeat, due) and repeat.districts.valley.amount("cash").compare(dest_cash) == 0, "recipient receives inventory without taking sender cash")
	expect(repeat.districts.north.amount("cash").compare(wallet.minus(HbtAmount.from(outbound.cost)).plus(HbtAmount.from(outbound.reward))) == 0
		and repeat.current().supplies.goods == 4, "cross-region delivery pays sender and stocks destination")
	expect(repeat.checkpoint() == OK and repeat.travel("metro") == OK, "settlement persists after another trip")
	var metro := repeat.current()
	metro.grant_reward({"card": "dev"})
	expect(metro.assign("dev") and repeat.freight.toggle_automatic(repeat), "an actual logistics manager operates automation")
	var truck := str(repeat.freight.serial)
	expect(repeat.freight.buy(repeat, "van") and repeat.freight.hire(repeat)
		and repeat.freight.assign(repeat, truck, str(int(truck) + 1)), "trained company can equip a local depot")
	repeat.freight.advance(repeat, metro.clock)
	expect(repeat.freight.busy(truck) and repeat.freight.jobs.size() == 1, "manager dispatches profitable available local order")
	clean_save(save_path)
	result("Transport fleet and contracts")

func campaign(time: int) -> HbtCampaign:
	var world := HbtCampaign.new(HbtEconomy.new())
	world.storage.path = save_path
	world.restore(time)
	return world

func fund(estate: HbtEconomy) -> void:
	estate.credit("cash", HbtAmount.from("1400000000051000"))
	estate.credit("reputation", HbtAmount.from(220))
	estate.finish_tutorial()
	estate.buy_levels("fuel", 25)
	for id: String in estate.facilities:
		if estate.level(id) == 0:
			estate.unlock(id)
		if estate.level(id) in [1, 2]:
			estate.buy_levels(id, 10)

func check_manifests() -> void:
	var distinct := {}
	var classes := {}
	for district: String in Atlas.DESTINATIONS:
		for id: String in Orders.ids(district):
			var entry := Orders.contract(id)
			var possible := false
			for body in Fleet.TYPES.values() + Fleet.TRAILERS.values():
				if entry.cargo in body.cargo and entry.load <= body.capacity:
					possible = true
			expect(possible and entry.seconds >= 30 and Atlas.DESTINATIONS.has(entry.to) and not distinct.has(entry.name),
				"reachable and distinct contract " + id)
			distinct[entry.name] = true
			classes[entry.cargo] = true
	expect(distinct.size() == 60 and classes.size() == Orders.GOODS.size(), "twelve five-order boards and all cargo types")
