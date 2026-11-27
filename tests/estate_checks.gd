extends "res://tests/run_checks.gd"

const Design = preload("res://data/estate/complex_design.gd")
const Staff = preload("res://scripts/employees/staff_rules.gd")
const Demand = preload("res://scripts/customers/demand.gd")
const Spotlights = preload("res://data/estate/spotlight.gd")
const AT := 1_804_980_000
var path := "/tmp/hbt-estate-%d.cfg" % OS.get_process_id()

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var estate := HbtEconomy.new()
	estate.storage.path = path
	var world := HbtCampaign.new(estate)
	world.restore(AT)
	expect(not estate.works.build(estate, "roads"), "infrastructure requires an open complex")
	estate.credit("cash", HbtAmount.from("3000000"))
	estate.credit("reputation", HbtAmount.from(180))
	estate.buy_levels("fuel", 25)
	estate.finish_tutorial()
	var pieces := 0
	for family: String in Design.STYLES:
		var names: Array = Design.STYLES[family]
		for style in range(1, names.size() + 1):
			pieces += 1
			if family not in ["facade","roof","canopy","plants"]:
				expect(ResourceLoader.exists("res://assets/models/estates/%s_%d.glb" % [family, style]), "authored prop %s/%d" % [family, style])
	expect(pieces == 60, "sixty option records with actual style resources")
	var wallet := estate.amount("cash")
	expect(not estate.works.set_style(estate, "fountain", 4), "progress award is unavailable initially")
	expect(estate.works.set_style(estate, "fountain", 1) and estate.amount("cash").compare(wallet) == 0, "earned customization does not charge cash")
	var offer := estate.works.custom_quote(estate, "fountain", 5)
	expect(estate.works.set_style(estate, "fountain", 5)
		and estate.amount("cash").compare(wallet.minus(offer.cost)) == 0, "the paid style charges exactly its quote")
	var base := estate.duration("fuel", -1)
	for work: String in Design.INFRASTRUCTURE:
		for i in 3:
			expect(estate.works.build(estate, work), "real work reaches level %d at %s" % [i + 1, work])
	var no_works := estate.amount("cash")
	expect(not estate.works.build(estate, "roads") and estate.amount("cash").compare(no_works) == 0, "stage cap prevents repeated payment")
	expect(estate.duration("fuel", -1) < base and estate.works.queue_speed() > 1.1 and estate.works.dispatch_speed() > 1.15,
		"upgrades affect actual service, queues and shipping")
	var control := Demand.new(764)
	var initial := count_visitors(control, estate, "local", 400)
	var cost := estate.works.campaign_price(estate, "fuel")
	wallet = estate.amount("cash")
	expect(estate.works.promote(estate,"fuel") and estate.amount("cash").compare(wallet.minus(cost)) == 0,
		"campaign costs exactly its quote")
	expect(not estate.works.promote(estate, "roadside"), "one paid campaign can run at a time")
	var pushed := count_visitors(Demand.new(764), estate, "local", 400)
	expect(pushed > initial + 25, "the live marketing changes the requested customer mix")
	estate.clock += Design.CAMPAIGNS.fuel.seconds + 1
	expect(estate.works.active(estate.clock).is_empty() and count_visitors(Demand.new(764), estate, "local", 400) == initial,
		"customer mix recovers after the campaign expires")
	estate.hire("fuel")
	estate.crew.fuel[0].xp = 14
	estate.crew.fuel[0].training = 2
	expect(estate.promote("fuel",0), "experience and training can promote a worker")
	var prior := Staff.speed(estate.crew.fuel[0])
	expect(estate.specialize("fuel", 0, "speed") and Staff.speed(estate.crew.fuel[0]) > prior, "specialization changes a real job parameter")
	var traffic := HbtDispatch.new(estate, 605)
	traffic.seed_station()
	var visits := 0
	while visits < 3500:
		traffic.tick(.1)
		visits += 1
	expect(traffic.consistent() and estate.customers > 12 and estate.works.samples > 12,
		"upgraded traffic works with normal visitors and real reviews")
	if estate.works.inspection(estate, "fuel").ready:
		expect(estate.works.claim_inspection(estate, "fuel") and not estate.works.claim_inspection(estate,"fuel"), "inspection certificates claim once")
	else:
		expect(false, "strong services can complete a non-punitive inspection")
	var available := Spotlights.MOMENTS
	for item: Dictionary in available:
		var spec := preload("res://scripts/traffic/vehicle_catalog.gd").definition(item.model)
		expect(spec.id == item.model, "featured visitor uses the specified vehicle " + item.id)
	expect(world.checkpoint() == OK and world.travel("desert") == OK and world.current().works.designs.is_empty(),
		"style and infrastructure remain in their home region")
	var restored := HbtCampaign.new(HbtEconomy.new())
	restored.storage.path = path
	restored.restore(estate.clock)
	expect(restored.districts.north.works.designs.fountain == 5
		and restored.districts.north.works.stage("roads") == 3
		and restored.districts.north.crew.fuel[0].specialty == "speed", "regional developments and specialties survive reload")
	print("CAMPAIGN local visitors before/after: %d → %d of 400 each" % [initial, pushed])
	clean_save(path)
	result("Estate design, infrastructure, marketing and satisfaction")

func count_visitors(demand: RefCounted, estate: HbtEconomy, type: String, units: int) -> int:
	var count := 0
	for i in units:
		if demand.customer(estate).type == type:
			count += 1
	return count
