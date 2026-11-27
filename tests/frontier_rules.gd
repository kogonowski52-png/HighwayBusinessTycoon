extends "res://tests/run_checks.gd"

const Atlas = preload("res://data/world/atlas.gd")
const Regions = preload("res://data/world/regions.gd")
const Roads = preload("res://data/world/regional_routes.gd")
const Calendar = preload("res://data/world/expedition_calendar.gd")
const Ledger = preload("res://scripts/expansion/ledger.gd")
const Recognition = preload("res://data/economy/recognition.gd")
const Managers = preload("res://data/economy/managers.gd")
const Catalog = preload("res://data/visual/vehicle_catalog.gd")
const Demand = preload("res://scripts/customers/demand.gd")
const AT := Calendar.START + Calendar.DAY

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	expect(Atlas.DESTINATIONS.size() == 12 and Atlas.chapter_routes(false).size() == 6 and Atlas.chapter_routes(true).size() == 6,
		"two atlas chapters include 12 independently testable regions")
	expect(Recognition.collection.size() == 104 and Catalog.VEHICLES.size() == 48 and Managers.ROSTER.size() == 33,
		"real inventory size")
	rentals()
	events()
	for id: String in Regions.FRONTIERS:
		draw_region(id)
	result("World Expansion accounting, events and sustained traffic")

func rentals() -> void:
	var path := "/tmp/hbt-world-leases-%d.cfg" % OS.get_process_id()
	var resort := HbtEconomy.new("tropical")
	resort.restore_profile({}, AT, false)
	resort.storage.path = path
	resort.levels.rent = 18
	var ticket := HbtVisit.new()
	ticket.service = "rent"
	resort.commerce.begin(ticket, 18)
	expect(ticket.trade == "lease" and ticket.stock_delta == -1 and resort.commerce.holds("rent").outgoing == 1,
		"arrival reserves a rental from the finite fleet")
	resort.commerce.settle(ticket, 18, AT)
	expect(resort.metric("rentals", "rent") == 1 and resort.commerce.record("rent").stock == 2, "paid lease removes one vehicle")
	expect(resort.checkpoint() == OK, "writes a real rental save")
	var restored := HbtEconomy.new("tropical")
	restored.storage.path = path
	restored.restore_profile(restored.storage.restore(), AT + 45, false)
	expect(restored.commerce.record("rent").returns == [AT + resort.commerce.LEASE_SECONDS],
		"absolute checkout timestamp survives the JSON save")
	expect(not restored.commerce.tick(0.0, restored.levels, AT + 40), "an outstanding lease cannot return early")
	expect(restored.commerce.tick(0.0, restored.levels, AT + 150) and not restored.commerce.tick(0.0, restored.levels, AT + 150)
		and restored.commerce.record("rent").stock == 3 and restored.metric("returns", "rent") == 1,
		"restart restores each expired lease once")
	clean_save(path)

func events() -> void:
	var names := {}
	for index in range(Calendar.SEASONS.size()):
		var then := AT + index * Calendar.WEEK
		var event := Calendar.event_at(then)
		expect(event.live and not names.has(event.id) and ResourceLoader.exists("res://assets/models/desert/event_" + event.id + ".glb"),
			"authored scene and distinct active schedule " + event.id)
		names[event.id] = true
		if index < Calendar.ORIGINAL_SEASONS:
			continue
		var estate := HbtEconomy.new("wilderness" if event.id == "timber_convoy" else "harbor" if event.id == "logistics_week"
			else "tropical" if event.id == "island_week" else "japan" if event.id == "akari_matsuri" else "route66" if event.id == "classic_rally" else "luxury")
		estate.clock = then
		estate.credit("reputation", HbtAmount.from(120))
		for id: String in estate.levels:
			estate.levels[id] = 35
		estate.special_guest = {"type": event.guest, "model": event.model}
		var demand := Demand.new(232 + index)
		var special := 0
		for _try in 125:
			var client := demand.customer(estate)
			if client.model == event.model and client.get("campaign"):
				special += 1
		expect(special > 5, "new guests physically enter the customer pool for " + event.id)
		var ledger := Ledger.new()
		for goal: Array in event.tasks:
			ledger.increment(estate, {goal[0]: goal[1]})
		expect(ledger.ready_event() and ledger.claim_event(estate) and not ledger.claim_event(estate),
			"each event has distinct goals and an idempotent prize " + event.id)
		expect(ledger.cosmetics.has(event.id), "claimed event awards its original exhibit")
	var historical := Ledger.new()
	historical.restore({"week": 7, "high_water": AT + Calendar.WEEK * 7, "event_totals": {"paid": true}})
	expect(historical.season().id == "holiday" and historical.paid_event(), "0.9.3 paid event preserved until its existing week ends")
	historical.advance(AT + Calendar.WEEK * 8)
	expect(historical.season().id == "logistics_week" and not historical.paid_event(),
		"next week changes to the new season only once")

func draw_region(district: String) -> void:
	var site := HbtEconomy.new(district)
	site.clock = AT
	site.credit("cash", HbtAmount.from(100_000_000))
	site.credit("reputation", HbtAmount.from(160))
	var traffic := HbtDispatch.new(site, 502, Roads.new(district))
	var ledger := Ledger.new()
	for id: String in site.facilities:
		site.levels[id] = 62
		site.hire(id)
		site.train(id, 0)
	var contract := "local_" + district
	expect(ledger.accept(site, contract), "real local contract services in " + district)
	traffic.completed.connect(func(ticket: HbtVisit) -> void: ledger.visit(site, ticket))
	var first_wallet := site.amount("cash")
	for frame in 15_000:
		site.clock = AT + floori(frame * .10)
		traffic.tick(.1)
	print("%s 25 minute demand: %d paid, %d departures, %d recoveries, peak %d" %
		[district, site.customers, traffic.departed, traffic.recovered, traffic.peak_queue])
	expect(traffic.consistent() and traffic.departed > 40 and traffic.recovered <= maxi(2, traffic.departed / 50),
		"mixed real road demand and bounded recovery in " + district)
	expect(site.amount("cash").compare(first_wallet) >= 0 and not site.offline_quote(1_800).empty(),
		"wages funded, staff/inactive economies remain productive in " + district)
	var key := ledger.id_for(district, contract)
	var due := int(Regions.LOCAL_CONTRACTS[district].time)
	for frame in range(15_000, due * 10):
		if ledger.contracts[key].done:
			break
		site.clock = AT + floori(frame * .10)
		traffic.tick(.1)
	print("Contract ", district, " ", ledger.contracts[key].have, "/", ledger.contracts[key].goal)
	expect(ledger.claim_contract(site, key) and not ledger.claim_contract(site, key),
		"dispatch and ledger can complete the local contract during its real window in " + district)
	var tests := 0
	for item: Dictionary in Recognition.collection.values():
		if item.get("district") == district:
			tests += 1
			var available := site.achievement_progress(item)
			expect(ResourceLoader.exists(item.icon) and available >= 0 and available <= item.goal, "bounded real achievement " + item.id)
			if available == int(item.goal):
				expect(site.claim_achievement(item.id) and not site.claim_achievement(item.id), "one prize for " + item.id)
	expect(tests == 9, "nine real measures configured for " + district)
	var manager: String = Regions.ECONOMICS[district][6]
	var skill: String = Managers.ROSTER[manager].skill
	var business: String = Regions.ECONOMICS[district][5]
	site.per_service[business].count = maxi(6, int(site.per_service[business].count))
	expect(site.claim_reward(district + "_director") and site.assign(manager) and site.skill(skill, business) > 0,
		"real prize and district skill " + manager)
