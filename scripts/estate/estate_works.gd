extends RefCounted
## Regional ownership, traffic works and positive-only service ratings.

const Catalog = preload("res://data/estate/complex_design.gd")

var designs := {}
var ownership := {}
var levels := {}
var campaign := {}
var rating := 72
var samples := 0
var bottlenecks := {}
var awards := {}
var revision := 0
var next_spotlight := 0
var spotlight_cursor := 0

func snapshot() -> Dictionary:
	return {"designs": designs, "ownership": ownership, "levels": levels, "campaign": campaign,
		"rating": rating, "samples": samples, "bottlenecks": bottlenecks, "awards": awards,
		"next_spotlight": next_spotlight, "spotlight_cursor": spotlight_cursor}

func has_work() -> bool:
	return not designs.is_empty() or not ownership.is_empty() or not levels.is_empty() or not campaign.is_empty() or not awards.is_empty() or samples > 0 or next_spotlight > 0

func restore(raw: Dictionary) -> void:
	designs = {}
	ownership = {}
	levels = {}
	campaign = {}
	awards = {}
	bottlenecks = {}
	for slot: String in Catalog.STYLES:
		var allowed := dictionary(raw.get("ownership"))
		var style := clampi(int(dictionary(raw.get("designs")).get(slot, 0)), 0, 5)
		if style > 0:
			designs[slot] = style
		for i in range(1, 6):
			var key := "%s/%d" % [slot,i]
			if allowed.get(key) == true:
				ownership[key] = true
	for key: String in Catalog.INFRASTRUCTURE:
		var stage := clampi(int(dictionary(raw.get("levels")).get(key, 0)), 0, 3)
		if stage > 0:
			levels[key] = stage
	for key: String in Catalog.AUDITS:
		if dictionary(raw.get("awards")).get(key) == true:
			awards[key] = true
	var offer := dictionary(raw.get("campaign"))
	if Catalog.CAMPAIGNS.has(offer.get("id", "")):
		campaign = {"id": offer.id, "until": int(offer.get("until", 0))}
	rating = clampi(int(raw.get("rating", 72)), 0, 100)
	samples = maxi(0, int(raw.get("samples", 0)))
	next_spotlight = maxi(0, int(raw.get("next_spotlight", 0)))
	spotlight_cursor = maxi(0, int(raw.get("spotlight_cursor", 0)))
	for key in ["queue", "capacity", "quality"]:
		bottlenecks[key] = maxi(0, int(dictionary(raw.get("bottlenecks")).get(key, 0)))
	revision += 1

func dictionary(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}

func active(now: int) -> Dictionary:
	if not campaign.is_empty() and now < int(campaign.until):
		return Catalog.CAMPAIGNS[campaign.id]
	return {}

func custom_quote(store: RefCounted, key: String, value: int) -> Dictionary:
	if value < 0 or value > 5 or not Catalog.STYLES.has(key):
		return {}
	var owned: bool = ownership.get("%s/%d" % [key, value], false)
	var requirement := 0
	var price := HbtAmount.new()
	match value:
		2: requirement = 24
		3: requirement = 80
		4: requirement = 180
		5: price = store.price("fuel").times(15).plus(HbtAmount.from(300)) if not owned else HbtAmount.new()
	var play: bool = owned or store.customers >= requirement or (value == 4 and not awards.is_empty())
	return {"cost": price, "requirement": requirement, "owned": owned or value <= 1,
		"ready": play and store.can_afford(price) and not store.storage.read_only}

func set_style(store: RefCounted, key: String, value: int) -> bool:
	var offer := custom_quote(store, key, value)
	if offer.is_empty() or not offer.ready or int(designs.get(key, 0)) == value:
		return false
	return pay(store, offer.cost, func() -> void:
		if value == 0:
			designs.erase(key)
		else:
			designs[key] = value
			ownership["%s/%d" % [key, value]] = true)

func stage(key: String) -> int:
	return int(levels.get(key, 0))

func construction_cost(store: RefCounted, key: String) -> HbtAmount:
	var step := stage(key) + 1
	return store.price("fuel").times(9 + step * 7).plus(HbtAmount.from(180 * step * step))

func build(store: RefCounted, key: String) -> bool:
	if not Catalog.INFRASTRUCTURE.has(key) or stage(key) >= 3 or store.level("fuel") < 4 + stage(key) * 4:
		return false
	var next := stage(key) + 1
	return pay(store, construction_cost(store, key), func() -> void: levels[key] = next)

func travel_scale(phase: HbtVisit.Phase) -> float:
	match phase:
		HbtVisit.Phase.ENTERING: return 1.0 + .027 * (stage("roads") + stage("entry") + stage("signals"))
		HbtVisit.Phase.DEPART: return 1.0 + .027 * (stage("roads") + stage("exit") + stage("signals"))
		_: return 1.0 + .025 * (stage("roads") + stage("junction") + stage("roundabout"))

func queue_speed() -> float:
	return 1.0 + .025 * (stage("junction") + stage("roundabout") + stage("signals"))

func service_time() -> float:
	return 1.0 - .036 * stage("bays") - .012 * stage("parking")

func dispatch_speed() -> float:
	return 1.0 + .028 * (stage("roads") + stage("entry") + stage("exit"))

func attraction(now: int) -> float:
	var rate := 1.0 + .014 * (stage("roads") + stage("parking") + stage("walkways"))
	if samples >= 7:
		rate += maxf(0, rating - 75) * .003
	var offer := active(now)
	return rate * float(offer.get("traffic", 1.0))

func group_weight(now: int, group: String) -> float:
	var growth := 1.0
	if group == "vip" and samples >= 7:
		growth += maxf(0, rating - 75) * .032
	var offer := active(now)
	return growth * (3.1 if offer.get("group", "") == group else 1.0)

func service_weight(estate: RefCounted, id: String) -> float:
	var offer := active(estate.clock)
	return 2.55 if not offer.is_empty() and matches(estate, id, offer.site) else 1.0

func campaign_price(store: RefCounted, id: String) -> HbtAmount:
	return store.price("fuel").times(Catalog.CAMPAIGNS[id].cost).plus(HbtAmount.from(55))

func promote(store: RefCounted, id: String) -> bool:
	if not Catalog.CAMPAIGNS.has(id) or not active(store.clock).is_empty() or not market_ready(store, id):
		return false
	return pay(store, campaign_price(store, id), func() -> void:
		campaign = {"id": id, "until": store.clock + int(Catalog.CAMPAIGNS[id].seconds)})

func market_ready(store: RefCounted, id: String) -> bool:
	var group: String = Catalog.CAMPAIGNS[id].site
	return store.level("fuel") >= 4 and (group.is_empty() or sites_for(store, group).size() > 0)

func matches(store: RefCounted, site: String, group: String) -> bool:
	if site == group:
		return true
	var families := {"food":["restaurant","cafe","drive_through"], "hotel":["motel","resort"],
		"freight":["truck","truck_park","terminal","logistics","warehouse","coldstore","distribution","truck_service"],
		"vip":["vip_park","dealership","detail","motel"]}
	if site in families.get(group, []):
		return true
	return store.facilities[site].venue_kind == group

func sites_for(store: RefCounted, group: String) -> Array[String]:
	var found: Array[String] = []
	for id: String in store.facilities:
		if store.level(id) > 0 and matches(store, id, group):
			found.append(id)
	return found

func feedback_for(ticket: HbtVisit, estate: RefCounted, served: bool) -> void:
	var waiting := maxf(0.0, float(ticket.client.patience) - ticket.patience)
	var delay := clampf(waiting / maxf(1.0, ticket.client.patience), 0, 1)
	var report := 39.0 if not served else 82.0 - 29.0 * delay 		+ minf(11.0, estate.level(ticket.service) * .28 + designs.size() * .55 + stage("walkways") + stage("lamps") * .33)
	if served and ticket.worker >= 0 and estate.crew[ticket.service].size() > ticket.worker:
		report += minf(8.0, float(estate.crew[ticket.service][ticket.worker].get("level", 1)) * 1.60)
	samples += 1
	rating = clampi(roundi(lerpf(rating, report, .13)), 0, 100)
	var reason := "capacity" if not served and ticket.bounced else "queue" if not served or delay > .54 else "quality"
	bottlenecks[reason] = int(bottlenecks.get(reason, 0)) + 1
	estate.dirty = true

func inspection(store: RefCounted, id: String) -> Dictionary:
	var item: Dictionary = Catalog.AUDITS[id]
	var best := 0
	var visits := 0
	if item.site.is_empty():
		best = store.level("fuel")
		visits = store.customers
	else:
		for site: String in sites_for(store, item.site):
			best = maxi(best, store.level(site))
			visits += int(store.per_service[site].count)
	return {"best": best, "visits": visits, "reward": store.price("fuel").times(12),
		"ready": best >= item.level and visits >= item.sales and rating >= item.rating and not awards.has(id)}

func claim_inspection(store: RefCounted, id: String) -> bool:
	if not Catalog.AUDITS.has(id):
		return false
	var quote := inspection(store, id)
	if not quote.ready:
		return false
	return pay(store, HbtAmount.new(), func() -> void:
		awards[id] = true
		store.credit("cash", quote.reward)
		store.credit("reputation", HbtAmount.from(7))
		store.credit("diamond", HbtAmount.from(2)))

func pay(store: RefCounted, cost: HbtAmount, apply: Callable) -> bool:
	if store.storage.read_only or not store.can_afford(cost):
		return false
	var prior := snapshot().duplicate(true)
	var balances: Dictionary = store.wallet.duplicate()
	var spending: HbtAmount = store.spent
	store.debit(cost)
	apply.call()
	if store.checkpoint() != OK:
		restore(prior)
		store.wallet = balances
		store.spent = spending
		return false
	revision += 1
	store.touch()
	return true
