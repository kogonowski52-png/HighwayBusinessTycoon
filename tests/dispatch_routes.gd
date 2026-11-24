extends "res://tests/run_checks.gd"

const Routes := preload("res://data/economy/routes.gd")
const Phase = HbtVisit.Phase

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	for definition in HbtEconomy.CONFIG.services:
		for index in range(definition.capacity_levels.size()):
			drive(definition.id, index)
	stress_test()
	watchdog()
	result("Traffic and reservations")

func drive(id: String, index: int) -> void:
	var store := HbtEconomy.new()
	store.clock = 1_789_000_000
	store.levels[id] = 100
	var network := HbtDispatch.new(store, 68492 + index)
	network.spawning = false
	# Freeze lower bays with correctly placed occupied vehicles. The test must reach the actual later bay.
	for slot in range(index):
		var holder := network.make_visit(network.demand.customer(store, "trucker" if id == "truck" else "local"), id)
		holder.phase = Phase.WORKING
		holder.invoice = HbtAmount.new()
		holder.timer = 10000.0
		holder.bay = slot
		holder.location = Routes.position_of(id, slot)
		holder.yaw = Routes.stopping_yaw(id)
		network.bays[id][slot] = holder.number
	var ticket := network.try_admit("trucker" if id == "truck" else "local", id)
	var observed := {"queue": false}
	network.state_changed.connect(func() -> void:
		observed.queue = observed.queue or ticket.phase == Phase.QUEUED)
	var saw_bay := false
	var good := true
	for i in range(1900):
		network.tick(0.05)
		good = good and network.consistent()
		if ticket.phase == Phase.READY and not saw_bay:
			saw_bay = ticket.location.distance_to(Routes.position_of(id, index)) < 0.05 and ticket.bay == index
			network.start_manual(id)
		if not network.live.has(ticket.number):
			break
	expect(observed.queue and saw_bay and ticket.paid and not network.live.has(ticket.number)
		and network.guards.is_empty() and good and network.recovered == 0 and store.customers == 1,
		"%s bay %d reaches queue, reserves, serves and exits (%s; %s; %.2fs)" % [id, index + 1, ticket.phase,
			ticket.location, ticket.stalled])

func stress_test() -> void:
	var store := HbtEconomy.new()
	store.credit("cash", HbtAmount.from("10000000"))
	store.credit("reputation", HbtAmount.from(300))
	for id in store.facilities:
		store.levels[id] = 55
		store.hire(id)
		store.hire(id)
	var network := HbtDispatch.new(store, 71)
	network.seed_station()
	var correct := true
	var serviced := {}
	for i in range(9600):
		store.clock = 1_789_000_000 + floori(i * 0.125)
		network.tick(0.125)
		correct = correct and network.consistent()
		for ticket: HbtVisit in network.live.values():
			if ticket.paid:
				serviced[ticket.service] = true
	network.spawning = false
	for i in range(1200):
		network.tick(0.125)
		correct = correct and network.consistent()
	print("Stress: %d served, %d bypassed/expired, %d recovered, peak queue %d, facilities %s" %
		[store.customers, network.abandoned, network.recovered, network.peak_queue, serviced.keys()])
	expect(correct and network.live.is_empty() and network.guards.is_empty(), "congested simulation drains all reservations")
	expect(serviced.size() == 8 and network.peak_queue >= 3, "all service types handle concurrent demand")
	expect(store.customers > 85 and network.recovered <= 3, "throughput floor and infrequent recovery")

func watchdog() -> void:
	var store := HbtEconomy.new()
	var network := HbtDispatch.new(store, 42)
	network.spawning = false
	network.seed_station()
	var blocked := network.try_admit("local", "fuel")
	var guard: HbtVisit = network.live[1]
	guard.location = Vector3(42.80, 0, 8.78)
	guard.phase = Phase.WORKING
	guard.timer = 180.0
	for i in range(150):
		network.tick(0.10)
	expect(network.recovered == 1 and not network.live.has(blocked.number)
		and not network.guards.has("entry_car") and network.consistent(), "watchdog releases obstructed approach and queue slot")
