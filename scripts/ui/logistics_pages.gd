extends RefCounted

const Catalog = preload("res://data/logistics/fleet.gd")
const Orders = preload("res://data/logistics/contracts.gd")
const DEPOT = preload("res://assets/ui/business/metro_logistics.png")
const VAN = preload("res://assets/ui/business/valley_market.png")
const WAREHOUSE = preload("res://assets/ui/business/metro_warehouse.png")
const ATLAS = preload("res://data/world/atlas.gd")
const VehicleNames = preload("res://data/visual/vehicle_catalog.gd")
const PAGES := ["empire", "fleet", "freight"]

var panel: CanvasLayer
var game: Node3D
var hud: CanvasLayer
var workforce := false
var clocks: Dictionary = {}
var revision := 0

func bind(owner: CanvasLayer) -> void:
	panel = owner
	game = owner.controller
	hud = owner.theme_source

func t(key: String) -> String:
	return game.t(key)

func price(value: int) -> String:
	return game.money(HbtAmount.from(value))

func localized(list: Array) -> String:
	return list[int(game.economy.language == "en")]

func freight() -> RefCounted:
	return game.campaign.freight

func signature(page: String) -> String:
	if not page in PAGES:
		return ""
	var store: HbtEconomy = game.economy
	return str([page, store.language, freight().revision, revision, store.level("fuel"),
		store.amount("cash").decimal(), store.equipped, store.clock / 30 if page == "freight" else 0])

func show(page: String) -> bool:
	clocks.clear()
	match page:
		"empire": show_empire()
		"fleet": show_fleet()
		"freight": show_freight()
		_: return false
	return true

func nav(container: Control, page: String) -> void:
	var choice := HBoxContainer.new()
	choice.add_theme_constant_override("separation", 8)
	container.add_child(choice)
	for tab in PAGES:
		if tab == page:
			continue
		panel.button(choice, t(tab + "_header"), panel.show_page.bind(tab)).size_flags_horizontal = Control.SIZE_EXPAND_FILL

func focus_workforce(value: bool) -> void:
	workforce = value
	revision += 1
	panel.refresh()

func perform(call: Callable) -> void:
	if call.call():
		game.feedback.play("click")
		game.sync_depot()
	else:
		game.show_message(t("fleet_failure"))
	panel.refresh()

func driver_name(id: String) -> String:
	var index := posmod(int(id) - 2, Catalog.DRIVER_NAMES.size())
	return Catalog.DRIVER_NAMES[index]

func unit_name(vehicle: String) -> String:
	var item: Dictionary = freight().vehicles[vehicle]
	return localized(Catalog.TYPES[item.kind].name) + " · #" + vehicle

func own_trucks() -> Array:
	return freight().vehicles.keys().filter(func(id: String) -> bool: return freight().vehicles[id].home == game.economy.district)

func show_fleet() -> void:
	var manager := freight()
	var estate: HbtEconomy = game.economy
	var hero: VBoxContainer = panel.feature(DEPOT, t("fleet_header"), t("fleet_intro"))
	nav(hero, "fleet")
	if not manager.enabled(estate):
		panel.box(t("fleet_gate"))
		return
	if not own_trucks().is_empty():
		panel.button(panel.rows, t("fleet_open_yard"), game.view_depot)
	var toggles := HBoxContainer.new()
	panel.rows.add_child(toggles)
	for choice in [false, true]:
		var key := "fleet_workforce" if choice else "fleet_garage"
		panel.button(toggles, t(key), focus_workforce.bind(choice), false, choice == workforce).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if workforce:
		show_drivers()
		return
	for id: String in own_trucks():
		show_truck(manager, id)
	var store: VBoxContainer = panel.feature(VAN, t("fleet_browse"))
	for type: String in Catalog.TYPES:
		var offer: Dictionary = Catalog.TYPES[type]
		var row: VBoxContainer = panel.box(localized(offer.name), t("fleet_loading") % [offer.capacity, roundi(offer.speed * 100), price(offer.running)] if offer.capacity > 0 else t("fleet_no_trailer"))
		panel.button(row, t("fleet_buy") % price(offer.price), perform.bind(manager.buy.bind(game.campaign, type)),
			not estate.can_afford(HbtAmount.from(offer.price)) or manager.vehicles.size() >= Catalog.MAX_TRUCKS,
			offer.capacity > 0 and manager.vehicles.is_empty())
	store.tooltip_text = t("fleet_intro")

func show_drivers() -> void:
	var manager := freight()
	var estate: HbtEconomy = game.economy
	for id: String in manager.drivers:
		var driver: Dictionary = manager.drivers[id]
		if driver.home != estate.district:
			continue
		var card: VBoxContainer = panel.box(driver_name(id), t("fleet_driver_rank") % [driver.rank, driver.xp])
		if driver.training > 0:
			var label: Label = hud.caption(card, 23, hud.MINT, hud.BOLD)
			clocks["d/" + id] = label
			label.text = t("fleet_in_training") % game.clock_text(maxi(0, int(driver.training) - estate.clock))
		elif manager.driver_working(id):
			hud.caption(card, 23, hud.FADE).text = t("fleet_traveling")
		elif driver.rank < Catalog.MAX_DRIVER_RANK:
			var fee: int = manager.training_price(driver.rank)
			panel.button(card, t("fleet_train") % price(fee), perform.bind(manager.train.bind(game.campaign, id)),
				not estate.can_afford(HbtAmount.from(fee)))
	panel.button(panel.rows, t("fleet_hire") % price(Catalog.DRIVER_PRICE), perform.bind(manager.hire.bind(game.campaign)),
		not estate.can_afford(HbtAmount.from(Catalog.DRIVER_PRICE)) or manager.drivers.size() >= Catalog.MAX_TRUCKS, true)

func show_truck(manager: RefCounted, id: String) -> void:
	var data: Dictionary = manager.vehicles[id]
	var info: Dictionary = manager.specifications(id)
	var estate: HbtEconomy = game.economy
	var card: VBoxContainer = panel.box(unit_name(id), t("fleet_level") % [data.level, data.condition])
	add_bar(card, int(data.condition), 100, Color("#4a9f91"))
	hud.caption(card, 22, hud.FADE).text = t("fleet_loading") % [info.capacity, roundi(info.speed * 100.0), price(info.running)]
	if manager.busy(id):
		hud.caption(card, 24, hud.MINT, hud.BOLD).text = t("fleet_traveling")
		return
	if not data.driver.is_empty() and manager.drivers.has(data.driver):
		hud.caption(card, 25, hud.INK, hud.HEAVY).text = t("fleet_operator") % driver_name(data.driver)
		panel.button(card, t("fleet_release"), perform.bind(manager.assign.bind(game.campaign, id, "")))
	else:
		hud.caption(card, 25, hud.INK, hud.HEAVY).text = t("fleet_unassigned")
		var any_driver := false
		for driver: String in manager.drivers:
			if manager.drivers[driver].home == estate.district and not manager.driver_busy(driver):
				panel.button(card, t("fleet_assign") % driver_name(driver),
					perform.bind(manager.assign.bind(game.campaign, id, driver)), false, true)
				any_driver = true
		if not any_driver:
			panel.button(card, t("fleet_workforce"), focus_workforce.bind(true))
	if data.level < 12:
		var upgrade: int = manager.upgrade_price(id)
		panel.button(card, t("fleet_upgrade") % price(upgrade), perform.bind(manager.upgrade.bind(game.campaign, id)),
			not estate.can_afford(HbtAmount.from(upgrade)))
	if data.condition < 100:
		var repair: int = manager.repair_price(id)
		panel.button(card, t("fleet_repair") % price(repair), perform.bind(manager.repair.bind(game.campaign, id)),
			not estate.can_afford(HbtAmount.from(repair)))
	if data.kind == "tractor":
		for trailer: String in Catalog.TRAILERS:
			var option: Dictionary = Catalog.TRAILERS[trailer]
			var owned: bool = data.garage.has(trailer)
			var cost: int = 0 if owned else option.price
			var title := localized(option.name)
			if trailer != data.trailer:
				panel.button(card, t("fleet_change_trailer") % title + (" · " + price(cost) if cost > 0 else ""),
					perform.bind(manager.trailer.bind(game.campaign, id, trailer)), not estate.can_afford(HbtAmount.from(cost)))
			else:
				hud.caption(card, 24, hud.MINT, hud.BOLD).text = title

func show_freight() -> void:
	var manager := freight()
	var hero: VBoxContainer = panel.feature(WAREHOUSE, t("freight_header"), t("freight_intro"))
	nav(hero, "freight")
	var now: int = game.economy.clock
	var here: String = game.economy.district
	if not manager.enabled(game.economy):
		panel.box(t("fleet_gate"))
		return
	for job_id: String in manager.jobs:
		var job: Dictionary = manager.jobs[job_id]
		var order := Orders.contract(job.order)
		if here not in [order.from, order.to]:
			continue
		var card: VBoxContainer = panel.box(order.name, t("freight_inbound") % game.district_name(order.to))
		var row: Label = hud.caption(card, 24, hud.MINT, hud.HEAVY)
		clocks[job_id] = row
		row.text = t("freight_active") + " · " + game.clock_text(maxi(0, int(job.due) - now))
		add_bar(card, maxi(0, now - int(job.start)), maxi(1, int(job.due - job.start)), Color("#559586"))
	var supplies: Dictionary = game.economy.supplies
	if not supplies.is_empty():
		var stock: Array[String] = []
		for good: String in Orders.GOODS:
			if supplies.has(good):
				stock.append("%s × %d" % [localized(Orders.GOODS[good]), supplies[good]])
		panel.box(t("freight_stock"), "  ·  ".join(stock))
	var receipt: Dictionary = manager.receipts.get(here, {})
	if not receipt.is_empty():
		panel.box(t("freight_delivered") % game.money(HbtAmount.from(receipt.cash)), Orders.contract(receipt.order).get("name", ""))
	var automatic: VBoxContainer = panel.box(t("freight_dispatcher"))
	if manager.has_dispatcher(game.economy):
		var on: bool = manager.automatic.get(here, false)
		panel.button(automatic, t("freight_auto_on" if on else "freight_auto_off"), perform.bind(manager.toggle_automatic.bind(game.campaign)), false, on)
	else:
		hud.caption(automatic, 22, hud.FADE).text = t("freight_auto_gate")
	panel.feature(DEPOT, t("freight_available"))
	for id: String in Orders.ids(here):
		show_order(manager, id)

func show_order(manager: RefCounted, id: String) -> void:
	var order := Orders.contract(id)
	var card: VBoxContainer = panel.box(order.name, t("freight_manifest") % [game.district_name(order.from), game.district_name(order.to)])
	hud.caption(card, 23, hud.FADE).text = t("freight_quote") % [
		order.load, localized(Orders.GOODS[order.cargo]), order.difficulty + 1, game.clock_text(order.seconds)]
	var fleet_here := own_trucks()
	if fleet_here.is_empty():
		panel.button(card, t("freight_depot"), panel.show_page.bind("fleet"))
		return
	for vehicle: String in fleet_here:
		var quote: Dictionary = manager.quote(game.campaign, id, vehicle)
		if quote.is_empty():
			continue
		if quote.vehicle:
			hud.caption(card, 22, hud.INK).text = t("freight_pay") % [price(quote.reward), price(quote.cost), game.clock_text(quote.duration)]
			hud.caption(card, 22, hud.FADE).text = status(quote)
			panel.button(card, t("freight_dispatch") % [unit_name(vehicle), price(quote.cost)], send_order.bind(id, vehicle),
				not manager.ready(quote), manager.ready(quote))
	if not fleet_here.any(func(vehicle: String) -> bool: return manager.quote(game.campaign, id, vehicle).get("vehicle", false)):
		var allowed: Array[String] = []
		for type: String in Catalog.TYPES:
			if order.cargo in Catalog.TYPES[type].cargo:
				allowed.append(localized(Catalog.TYPES[type].name))
		for type: String in Catalog.TRAILERS:
			if order.cargo in Catalog.TRAILERS[type].cargo:
				allowed.append(localized(Catalog.TRAILERS[type].name))
		var note: Label = hud.caption(card, 21, hud.FADE)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.text = " · ".join(allowed)

func status(quote: Dictionary) -> String:
	var names := {"destination":"freight_destination", "available":"freight_busy", "driver":"freight_driver",
		"condition":"freight_condition", "cash":"freight_cash"}
	for key: String in names:
		if not quote[key]:
			return t(names[key])
	return ""

func send_order(id: String, vehicle: String) -> void:
	var manager := freight()
	if manager.dispatch(game.campaign, id, vehicle):
		game.feedback.play("build", true)
		game.view_depot()
	else:
		game.show_message(t("fleet_failure"))
		panel.refresh()

func update_clocks(now: int) -> void:
	for id: String in clocks:
		if not is_instance_valid(clocks[id]):
			continue
		var label: Label = clocks[id]
		if id.begins_with("d/"):
			var driver: Dictionary = freight().drivers.get(id.substr(2), {})
			label.text = t("fleet_in_training") % game.clock_text(maxi(0, int(driver.get("training", 0)) - now))
		else:
			var job: Dictionary = freight().jobs.get(id, {})
			if not job.is_empty():
				label.text = t("freight_active") + " · " + game.clock_text(maxi(0, int(job.due) - now))

func add_bar(parent: Control, value: int, maximum: int, tint: Color) -> void:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.custom_minimum_size.y = 23
	bar.max_value = maximum
	bar.value = value
	bar.add_theme_stylebox_override("background", hud.style(Color("#eadcc1"), hud.RIM, 9, 0))
	bar.add_theme_stylebox_override("fill", hud.style(tint, tint.darkened(.13), 9, 0))
	parent.add_child(bar)

func show_empire() -> void:
	var campaign: HbtCampaign = game.campaign
	var manager := freight()
	var aggregate := HbtAmount.new()
	var customers := 0
	var staff := 0
	var highest := HbtAmount.new()
	var best := HbtAmount.new()
	var title := ""
	var totals := {}
	for id: String in campaign.districts:
		var estate: HbtEconomy = campaign.districts[id]
		var total := estate.gross.plus(HbtAmount.from(manager.region_totals.get(id, "0")))
		aggregate = aggregate.plus(total)
		customers += estate.customers
		staff += estate.metric("staff")
		totals[id] = total
		if total.compare(highest) > 0:
			highest = total
		for service: String in estate.per_service:
			var gross: HbtAmount = estate.per_service[service].gross
			if gross.compare(best) > 0:
				best = gross
				title = estate.facilities[service].name_en if game.economy.language == "en" else estate.facilities[service].name_pl
	var summary: VBoxContainer = panel.feature(DEPOT, t("empire_header"), t("empire_intro"))
	nav(summary, "empire")
	var overview: VBoxContainer = panel.box(t("empire_turnover"), game.money(aggregate, true))
	hud.caption(overview, 25, hud.INK, hud.BOLD).text = t("empire_totals") % [totals.size(), staff, customers]
	hud.caption(overview, 25, hud.INK).text = t("empire_jobs") % [manager.jobs.size(), manager.completed, manager.vehicles.size()]
	var duration := campaign.boost.remaining(game.economy.clock)
	if duration > 0:
		hud.caption(overview, 25, Color("#9c641e"), hud.HEAVY).text = t("empire_boost") % game.boost_time(duration)
	if not title.is_empty():
		panel.box(t("empire_best") % [title, game.money(best)])
	var chart: VBoxContainer = panel.box(t("empire_regional"))
	for id: String in ATLAS.DESTINATIONS:
		if not totals.has(id):
			continue
		var total: HbtAmount = totals[id]
		var row: Label = hud.caption(chart, 23, hud.INK, hud.BOLD)
		row.text = game.district_name(id) + "   " + game.money(total)
		var pace := t("empire_projection") % [game.money(campaign.projected_income(id)), campaign.completion(id)]
		hud.caption(chart, 20, hud.FADE).text = pace
		add_bar(chart, ratio(total, highest), 100, Color(ATLAS.DESTINATIONS[id].color))
	for service: String in game.economy.facilities:
		if game.economy.construction_quote(service).ready:
			panel.button(panel.rows, t("empire_next") % game.site_name(service), panel.show_page.bind("sites"), false, true)
			break
	for id: String in ATLAS.DESTINATIONS:
		if not campaign.districts.has(id):
			panel.button(panel.rows, t("empire_next_route") % game.district_name(id), panel.expedition.open_district.bind(id))
			break
	panel.button(panel.rows, t("empire_browse"), panel.show_page.bind("atlas"))
	panel.button(panel.rows, t("empire_local"), panel.show_page.bind("finance"))

func ratio(value: HbtAmount, maximum: HbtAmount) -> int:
	if value.empty():
		return 0
	var low := 1
	var high := 100
	var scaled := value.times(100)
	while low < high:
		var probe := (low + high + 1) >> 1
		if maximum.times(probe).compare(scaled) <= 0:
			low = probe
		else:
			high = probe - 1
	return low
