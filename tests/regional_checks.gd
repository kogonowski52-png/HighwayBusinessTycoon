extends "res://tests/run_checks.gd"

const Atlas = preload("res://data/world/atlas.gd")
const Regions = preload("res://data/world/regions.gd")
const Roads = preload("res://data/world/regional_routes.gd")
const Calendar = preload("res://data/world/expedition_calendar.gd")
const Ledger = preload("res://scripts/expansion/ledger.gd")
const STAMP := Calendar.START + 949_201

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	await process_frame
	campaign_roundtrip()
	var missions := HbtEconomy.new().missions.size() + HbtEconomy.new("desert").missions.size()
	for district in Atlas.chapter_routes(false).slice(2):
		missions += drive_region(district)
	expect(missions == 590, "590 playable chapter missions across six districts")
	freight_checks()
	result("Regional routes, trades and independent estates")

func campaign_roundtrip() -> void:
	var save := "/tmp/hbt-region-roundtrip-%d.cfg" % OS.get_process_id()
	var north := HbtEconomy.new()
	north.storage.path = save
	var campaign := HbtCampaign.new(north)
	campaign.restore(STAMP)
	var chain := Atlas.chapter_routes(false)
	for id in chain.slice(1):
		var offer: Dictionary = Atlas.DESTINATIONS[id]
		var sponsor := campaign.current()
		expect(sponsor.district == offer["from"] and not campaign.available(id), "%s locked before predecessor requirements" % id)
		sponsor.credit("cash", HbtAmount.from(120_000))
		sponsor.credit("reputation", HbtAmount.from(100))
		sponsor.buy_levels("fuel", 10)
		sponsor.hire("fuel")
		if offer.get("gate") != null:
			for site in sponsor.facilities:
				if site == "fuel":
					continue
				expect(sponsor.unlock(site), "%s real service gate for %s" % [sponsor.district, site])
				sponsor.buy_levels(site, 10)
				if site == offer.gate:
					break
		var paid := sponsor.amount("cash").minus(HbtAmount.from(offer.cost))
		if id == "alpine":
			expect(campaign.travel("north") == OK, "first visit can be started from a previous district")
			var north_cash := north.amount("cash")
			campaign.storage.path = save + "/invalid"
			var before := campaign.ledger.high_water
			expect(campaign.travel(id) != OK and not campaign.districts.has(id) and campaign.ledger.high_water == before,
				"new region and shared ledger roll back on rejected storage")
			campaign.storage.path = save
			expect(campaign.travel(id) == OK and north.amount("cash").compare(north_cash) == 0, "earmarked investment charged to predecessor")
		else:
			expect(campaign.travel(id) == OK, "travel and checkpoint for " + id)
		expect(sponsor.amount("cash").compare(paid) == 0 and campaign.available(id), "one investment charged for " + id)
		expect(campaign.current().level("fuel") == 1 and campaign.current().crew.fuel.is_empty(),
			"separate operations " + id)
		var list: Array = Atlas.STAMPS[id]
		for key: String in list:
			campaign.ledger.spot(id, key)
		expect(campaign.ledger.set_reward(campaign.current(), "routes") and not campaign.ledger.set_reward(campaign.current(), "routes"),
			"independent album reward " + id)
	var active := campaign.current()
	active.hire("fuel")
	active.preferences.weather = "snow"
	active.clock += 17_000
	var quote := north.offline_quote(north.offline_limit())
	expect(campaign.travel("north") == OK and not quote.empty() and north.offline_pending.compare(quote) == 0,
		"inactive district captured at its own cap")
	expect(campaign.travel("metro") == OK and active.offline_pending.empty(), "other active district gets no simultaneous offline credit")
	expect(campaign.travel("north") == OK and north.offline_pending.compare(quote) == 0, "rapid travel does not charge the same seconds twice")
	expect(campaign.checkpoint() == OK, "all six independent profiles in one save")
	var saved := HbtEconomy.new()
	saved.storage.path = save
	var recovered := HbtCampaign.new(saved)
	recovered.restore(active.clock)
	expect(recovered.districts.size() == 6 and recovered.active == "north" and saved.preferences.weather == "snow", "all estates plus shared settings reloaded")
	expect(recovered.districts.metro.crew.fuel.size() == 1 and recovered.districts.desert.level("fuel") > 1
		and recovered.ledger.collected(recovered.districts.ocean, "routes") == 3, "regional hires, original levels and albums persisted")
	expect(saved.redeem_offline().compare(quote) == 0 and saved.redeem_offline().empty(), "offline redeem is one-time after restart")
	clean_save(save)

func drive_region(id: String) -> int:
	var economy := HbtEconomy.new(id)
	economy.clock = STAMP
	economy.credit("reputation", HbtAmount.from(120))
	var routes := Roads.new(id)
	for service in economy.facilities:
		economy.levels[service] = 100
		economy.crew[service] = []
		for i in economy.capacity(service):
			economy.crew[service].append({"training": 2, "rank": 1, "xp": 3})
	var ledger := Ledger.new()
	var local := "local_" + id
	expect(ledger.accept(economy, local), "regional contract available " + id)
	var order := ledger.id_for(id, local)
	for service in economy.facilities:
		var dispatch := HbtDispatch.new(economy, 511, routes)
		dispatch.completed.connect(func(ticket: HbtVisit) -> void: ledger.visit(economy, ticket))
		dispatch.spawning = false
		var preferred := "trucker" if routes.lane_of(service) == "truck" else "electric" if service == "charge" else "tourist"
		if id == "ocean":
			preferred = "vip"
		var trip := dispatch.try_admit(preferred, service)
		var animated := false
		for i in 1200:
			dispatch.tick(.10)
			animated = animated or (trip != null and trip.phase == HbtVisit.Phase.WORKING and trip.worker >= 0)
			if dispatch.live.is_empty():
				break
		expect(trip != null and trip.paid and animated and dispatch.consistent() and dispatch.live.is_empty()
			and dispatch.recovered == 0, "%s/%s settles a staffed drive, reservation and exit" % [id, service])
	var mixed := HbtDispatch.new(economy, 341, routes)
	mixed.completed.connect(func(ticket: HbtVisit) -> void: ledger.visit(economy, ticket))
	for frame in 15000:
		economy.clock = STAMP + floori(frame * .10)
		mixed.tick(.10)
	print("%s 25-min stress: paid=%d departures=%d recovered=%d queue_peak=%d dropped_full=%d" %
		[id, economy.customers, mixed.departed, mixed.recovered, mixed.peak_queue, mixed.capacity_rejected])
	expect(mixed.consistent() and mixed.departed > 40 and mixed.recovered == 0, "mixed traffic without deadlocks in " + id)
	expect(ledger.claim_contract(economy, order) and not ledger.claim_contract(economy, order),
		"regional contract completes through actual service " + id)
	var funded := economy.offline_quote(3600)
	expect(not funded.empty(), "staffed independent offline economy " + id)
	var manager: String = Regions.ECONOMICS[id][6]
	var skill: String = preload("res://data/economy/managers.gd").ROSTER[manager].skill
	var business: String = Regions.ECONOMICS[id][5]
	for key in economy.facilities:
		economy.per_service[key] = {"count": 150, "gross": HbtAmount.from(10_000_000)}
		for worker in economy.crew[key]:
			worker.training = 5
	economy.player_xp = 12_200
	var claimed := 0
	for key in economy.missions:
		if economy.claim_reward(key) and not economy.claim_reward(key):
			claimed += 1
	expect(claimed == economy.missions.size(), "all local mission waves payable exactly once " + id)
	expect(economy.claim_reward(id + "_director") and economy.assign(manager) and economy.skill(skill, business) > 0,
		"local manager card awarded and mechanically effective " + id)
	return claimed

func freight_checks() -> void:
	var e := HbtEconomy.new("metro")
	e.clock = STAMP
	var r := Roads.new("metro")
	var ledger := Ledger.new()
	for id in e.facilities:
		e.levels[id] = 100
		for i in e.capacity(id):
			e.crew[id].append({"training": 3, "rank": 2, "xp": 3})
	e.credit("reputation", HbtAmount.from(130))
	var d := HbtDispatch.new(e, 31, r)
	d.completed.connect(func(ticket: HbtVisit) -> void: ledger.visit(e, ticket))
	expect(ledger.accept(e, "local_metro"), "freight contract starts when docks operate")
	var contract := ledger.id_for("metro", "local_metro")
	for i in 16000:
		e.clock = STAMP + floori(i * .10)
		d.tick(.10)
	for id in ["logistics", "warehouse"]:
		var tally := e.commerce.statistics(id, e.level(id))
		expect(tally.inbound > 2 and tally.outbound > 2 and tally.stock == tally.inbound - tally.outbound
			and tally.stock <= tally.capacity, "bounded real inbound, outbound and inventory " + id)
	expect(ledger.claim_contract(e, contract) and not ledger.claim_contract(e, contract), "freight visits complete local contract once")
	var sold := e.commerce.statistics("dealership", e.level("dealership"))
	var retail := e.commerce.statistics("mall", e.level("mall"))
	expect(sold.sold > 1 and retail.shoppers > 1 and d.consistent() and d.recovered == 0,
		"showroom sales and multiple mall shoppers are authoritative")
	var restored := HbtEconomy.new("metro")
	restored.restore_profile(e.snapshot(), e.clock, false)
	expect(restored.commerce.statistics("dealership", 100) == sold
		and restored.commerce.statistics("mall", 100) == retail, "commercial accounting survives reloading a profile")
