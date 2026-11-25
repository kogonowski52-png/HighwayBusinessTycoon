extends RefCounted

const Atlas = preload("res://data/world/atlas.gd")
const Regions = preload("res://data/world/regions.gd")
const Calendar = preload("res://data/world/expedition_calendar.gd")
const Preview = preload("res://scripts/ui/expedition_preview.gd")
const Vehicles = preload("res://data/visual/vehicle_catalog.gd")
const Managers = preload("res://data/economy/managers.gd")

var panel: CanvasLayer
var hud: CanvasLayer
var game: Node3D
var destination := "desert"
var collection := "cars"
var collection_item := ""
var position := 0
var clocks: Array = []

func bind(owner: CanvasLayer) -> void:
	panel = owner
	game = owner.controller
	hud = owner.theme_source

func show(page: String) -> bool:
	clocks.clear()
	match page:
		"atlas": show_atlas()
		"district": show_district()
		"seasons": show_seasons()
		"season_summary": show_summary()
		"contracts": show_contracts()
		"collections": show_collections()
		"prestige", "prestige_confirm": show_prestige(page == "prestige_confirm")
		"climate": show_climate()
		_: return false
	return true

func signature(page: String) -> String:
	var world: HbtCampaign = game.campaign
	var site: HbtEconomy = game.economy
	var local := [page, site.language]
	match page:
		"atlas": local.append_array([world.active, world.districts.size(), Atlas.DESTINATIONS.keys().filter(world.available)])
		"district":
			local.append_array([destination, world.available(destination), world.completion(destination)])
			if world.districts.has(destination):
				local.append_array([world.districts[destination].player_level(), world.projected_income(destination).decimal()])
		"seasons": local.append_array([world.ledger.week, world.ledger.event_totals, world.ledger.season().live])
		"season_summary": local.append_array([world.ledger.week, world.ledger.finished_events, world.ledger.event_totals])
		"contracts":
			local.append_array([site.day_index(), world.ledger.contracts, world.ledger.active_contracts(site.district),
				site.levels, site.metric("reputation") >= 5])
		"collections": local.append_array([collection, collection_item, position, world.ledger.seen_vehicles, world.ledger.sightings,
			site.cards.keys(), world.ledger.cosmetics, world.ledger.chosen, world.ledger.prizes])
		"prestige", "prestige_confirm": local.append_array([site.prestige_rank, world.completion(site.district)])
		"climate": local.append_array([site.preferences.weather, site.preferences.auto_day, game.weather.weather])
		_: return ""
	return str(local)

func text(key: String) -> String:
	return game.t(key)

func balance(value: int) -> String:
	return game.money(HbtAmount.from(value))

func show_atlas() -> void:
	var campaign: HbtCampaign = game.campaign
	panel.feature(hud.ROAD, text("atlas_title"), text("atlas_intro"))
	var board := Preview.atlas(panel.rows)
	var index := 0
	for id in Atlas.DESTINATIONS:
		var point: Vector2 = Atlas.DESTINATIONS[id].position
		var pin: Button = hud.action(board, 103, 84, false)
		hud.button_art(pin, hud.REPUTATION if id == campaign.active else hud.ROAD if campaign.districts.has(id) else hud.NAV.sites, 44)
		var ready := campaign.available(id)
		var tint: Texture2D = hud.UPGRADE if id == campaign.active else hud.ACTION if ready else hud.CREAM_BUTTON
		pin.add_theme_stylebox_override("normal", hud.sculpted(tint, 30, 7))
		pin.set_anchor(SIDE_LEFT, point.x)
		pin.set_anchor(SIDE_RIGHT, point.x)
		pin.set_anchor(SIDE_TOP, point.y)
		pin.set_anchor(SIDE_BOTTOM, point.y)
		pin.offset_left = -51
		pin.offset_right = 52
		pin.offset_top = -45
		pin.offset_bottom = 39
		pin.tooltip_text = game.district_name(id)
		pin.pressed.connect(open_district.bind(id))
		var label: Label = hud.caption(board, 23, Color("#fff2d1"), hud.HEAVY)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for side in [SIDE_LEFT, SIDE_RIGHT]: label.set_anchor(side, point.x)
		for side in [SIDE_TOP, SIDE_BOTTOM]: label.set_anchor(side, point.y)
		label.offset_left = -136
		label.offset_right = 136
		label.offset_top = 41
		label.text = game.district_name(id)
		label.add_theme_color_override("font_outline_color", Color("#1d3536"))
		label.add_theme_constant_override("outline_size", 5)
		if ready and game.motion_enabled():
			var pulse := pin.create_tween().set_loops().set_trans(Tween.TRANS_SINE)
			pulse.tween_interval(index * .17)
			pulse.tween_property(pin, "modulate", Color(1.15, 1.10, 1.02), 1.19)
			pulse.tween_property(pin, "modulate", Color.WHITE, 1.19)
		index += 1
	var quick := HBoxContainer.new()
	panel.rows.add_child(quick)
	quick.add_theme_constant_override("separation", 8)
	for key in ["seasons", "contracts", "collections"]:
		var action: Button = panel.button(quick, text(key + "_header"), panel.show_page.bind(key))
		action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for id in Atlas.DESTINATIONS:
		var estate: Button = panel.button(panel.rows, game.district_name(id), open_district.bind(id), false, id == campaign.active)
		hud.button_art(estate, hud.ROAD, 56)
	var tools: HBoxContainer = HBoxContainer.new()
	panel.rows.add_child(tools)
	for key in ["climate", "prestige"]:
		var action: Button = panel.button(tools, text(key + "_header"), panel.show_page.bind(key))
		action.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func open_district(id: String) -> void:
	destination = id
	panel.show_page("district")

func show_district() -> void:
	var campaign: HbtCampaign = game.campaign
	var region: Dictionary = Atlas.DESTINATIONS[destination]
	panel.feature(hud.ROAD, game.district_name(destination), text("region_" + destination))
	if region.has("scene"):
		Preview.detail(panel.rows, destination, "")
		var title: String = text("district_metrics") % [campaign.completion(destination), game.money(campaign.projected_income(destination))]
		var card: VBoxContainer = panel.box(title)
		if campaign.districts.has(destination):
			var site: HbtEconomy = campaign.districts[destination]
			var names: Label = hud.caption(card, 25, hud.INK)
			names.text = text("district_rank") % [site.player_level(), site.metric("locations"), site.facilities.size(), site.prestige_rank]
			names.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			if destination != campaign.active:
				panel.button(card, text("district_travel"), game.travel_to.bind(destination), false, true)
			else:
				panel.button(card, text("district_stay"), panel.hide_page, false, true)
		else:
			var opened: Label = hud.caption(card, 26, hud.INK)
			opened.text = text("district_gate") % [game.district_name(region["from"]), region.fuel, region.rep, balance(region.cost)]
			if region.has("gate"):
				var sponsor: HbtEconomy = campaign.districts.get(region["from"])
				if sponsor == null:
					sponsor = HbtEconomy.new(region["from"])
				var service: HbtService = sponsor.facilities[region.gate]
				var title_text := service.name_en if game.economy.language == "en" else service.name_pl
				opened.text += "\n" + text("district_service_gate") % [title_text, region.tier]
			opened.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			panel.button(card, text("district_open") % balance(region.cost), game.travel_to.bind(destination),
				not campaign.available(destination), true)
	else:
		panel.box(text("district_future"), text("district_future_copy"))
	panel.button(panel.rows, text("atlas_return"), panel.show_page.bind("atlas"))

func show_seasons() -> void:
	var campaign: HbtCampaign = game.campaign
	var current: Dictionary = campaign.ledger.season()
	var played: bool = current.live
	var shell: VBoxContainer = panel.feature(hud.GIFT, text("season_" + current.id), text("season_" + current.id + "_body"))
	var tint := Color(current.tint)
	var status: Label = hud.caption(shell, 27, tint.lightened(.34), hud.HEAVY)
	if played:
		clocks.append({"label": status, "when": current.ends, "prefix": "season_time"})
	else:
		status.text = text("season_closed")
	Preview.detail(panel.rows, "decor", current.id)
	for task in current.tasks:
		var count: int = campaign.ledger.event_totals.get(task[0], 0)
		var card: VBoxContainer = panel.box(text("metric_" + task[0]), "%d / %d" % [count, task[1]])
		panel.mission_bar(card, count, task[1])
	var payout: VBoxContainer = panel.box(text("season_payout"), text("pair_reward") % [balance(current.cash), current.diamond])
	panel.button(payout, text("season_claimed") if campaign.ledger.paid_event() else text("claim"),
		game.claim_season, not campaign.ledger.ready_event(), true)
	panel.button(panel.rows, text("season_summary_header"), panel.show_page.bind("season_summary"))
	panel.box(text("local_schedule"), text("local_schedule_body"))
	panel.button(panel.rows, text("atlas_return"), panel.show_page.bind("atlas"))
	update_clock()

func show_summary() -> void:
	var ledger: RefCounted = game.campaign.ledger
	var current: Dictionary = ledger.season()
	panel.feature(hud.GIFT, text("season_summary_header"))
	if not current.live:
		season_record(current, ledger.event_totals)
	for index in range(ledger.finished_events.size() - 1, -1, -1):
		var record: Dictionary = ledger.finished_events[index]
		season_record(Calendar.SEASONS[int(record.week) % Calendar.SEASONS.size()], record.totals)
	if current.live and ledger.finished_events.is_empty():
		panel.box(text("season_summary_empty"), text("season_summary_empty_body"))
	panel.button(panel.rows, text("seasons_header"), panel.show_page.bind("seasons"))

func season_record(profile: Dictionary, totals: Dictionary) -> void:
	var cleared := 0
	for task in profile.tasks:
		cleared += int(int(totals.get(task[0], 0)) >= int(task[1]))
	var card: VBoxContainer = panel.box(text("season_" + profile.id),
		text("season_tasks_done") % [cleared, profile.tasks.size()] + " · " +
		text("season_claimed" if totals.get("paid", false) else "season_closed"))
	panel.mission_bar(card, cleared, profile.tasks.size())

func show_contracts() -> void:
	var ledger: RefCounted = game.campaign.ledger
	var site: HbtEconomy = game.economy
	panel.feature(hud.SETTINGS, text("contracts_header"), text("contracts_intro"))
	for key in ledger.contracts:
		var current: Dictionary = ledger.contracts[key]
		if current.site != site.district or current.paid:
			continue
		var card: VBoxContainer = panel.box(contract_label(current.get("offer", current.metric)), "%d / %d" % [current.have, current.goal])
		panel.mission_bar(card, current.have, current.goal)
		if current.done:
			panel.button(card, text("claim"), game.claim_contract.bind(key), false, true)
		else:
			var due: Label = hud.caption(card, 24, hud.GOLD)
			clocks.append({"label": due, "when": current.due, "prefix": "season_time"})
	for rule in ledger.offers(site.district):
		var key: String = ledger.id_for(site.district, rule.id)
		if ledger.contracts.has(key):
			continue
		var card: VBoxContainer = panel.box(contract_label(rule.id), text("contract_details") % [
			rule.tier, rule.goal, game.clock_text(rule.seconds), balance(rule.cash), rule.diamond])
		var eligible: bool = ledger.suitable(site, rule.id)
		panel.button(card, text("contract_accept" if eligible else "contract_need_service"),
			game.start_contract.bind(rule.id), not eligible or ledger.active_contracts(site.district) >= 3, eligible)
	panel.button(panel.rows, text("atlas_return"), panel.show_page.bind("atlas"))
	update_clock()

func contract_label(id: String) -> String:
	if id.begins_with("local_") and Regions.LOCAL_CONTRACTS.has(id.trim_prefix("local_")):
		var language: String = game.economy.language
		return Regions.LOCAL_CONTRACTS[id.trim_prefix("local_")][language]
	return text("metric_" + id)

func update_clock() -> void:
	if panel == null or not panel.modal_open():
		return
	for entry in clocks:
		var label: Label = entry.label
		if is_instance_valid(label):
			var left: int = int(entry.when) - game.campaign.ledger.high_water
			label.text = text(entry.prefix) % remaining(left) if left > 0 else text("contract_expired")

func remaining(seconds: int) -> String:
	var days := floori(seconds / 86400.0)
	if days > 0:
		return text("season_days") % [days, floori(posmod(seconds, 86400) / 3600.0)]
	return game.clock_text(seconds)

func show_collections() -> void:
	var ledger: RefCounted = game.campaign.ledger
	var site: HbtEconomy = game.economy
	var entries: Array = ledger.items(collection, site.district)
	if collection_item not in entries:
		collection_item = entries.front()
	var owned: int = ledger.collected(site, collection)
	panel.feature(hud.NAV.managers, text("collections_header"), text("collection_sources"))
	for row in [["cars", "trucks", "managers"], ["decor", "signs", "facades"], ["routes"]]:
		var choices := HBoxContainer.new()
		panel.rows.add_child(choices)
		for key in row:
			var tab: Button = panel.button(choices, text("set_" + key), choose_set.bind(key), false, key == collection)
			tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var acquired: VBoxContainer = panel.box(text("collection_total") % [owned, entries.size()])
	panel.mission_bar(acquired, owned, entries.size())
	var batch := HBoxContainer.new()
	panel.rows.add_child(batch)
	panel.button(batch, "‹", browse.bind(-1), position <= 0)
	var headline: Label = hud.caption(batch, 29, hud.INK, hud.HEAVY)
	headline.text = item_name(collection_item)
	headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	headline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.button(batch, "›", browse.bind(1), position >= entries.size() - 1)
	if collection == "managers":
		var face: TextureRect = hud.icon(panel.rows, panel.extra.portrait(collection_item), 184)
		face.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	else:
		Preview.detail(panel.rows, collection, collection_item)
	var available: bool = ledger.owned(site, collection, collection_item)
	panel.box(text("collection_won" if available else "collection_locked"), item_name(collection_item))
	if available and collection in Calendar.COSMETICS:
		var selected: bool = ledger.chosen.get(site.district, {}).get(collection, "") == collection_item
		panel.button(panel.rows, text("collection_remove" if selected else "collection_equip"),
			game.equip_collection.bind(collection, collection_item), false, true)
	if not ledger.prizes.has(ledger.prize_key(site, collection)):
		panel.button(panel.rows, text("collection_claim"), game.redeem_collection.bind(collection), owned != entries.size(), true)
	panel.button(panel.rows, text("atlas_return"), panel.show_page.bind("atlas"))

func choose_set(key: String) -> void:
	collection = key
	position = 0
	collection_item = ""
	panel.refresh()

func browse(step: int) -> void:
	var list: Array = game.campaign.ledger.items(collection, game.economy.district)
	position = clampi(position + step, 0, list.size() - 1)
	collection_item = list[position]
	panel.refresh()

func item_name(item: String) -> String:
	if Vehicles.VEHICLES.has(item):
		return Vehicles.VEHICLES[item].name
	if Managers.ROSTER.has(item):
		return Managers.ROSTER[item].name
	if item in Calendar.COSMETICS.facades:
		return text("collectible_" + item)
	return text("season_" + item)

func show_prestige(confirm: bool) -> void:
	var campaign: HbtCampaign = game.campaign
	var local: HbtEconomy = game.economy
	panel.feature(hud.REPUTATION, text("prestige_header"), text("prestige_rank") % [local.prestige_rank,
		local.prestige_rank * 5, campaign.ledger.prestige_points])
	var degree := campaign.completion(campaign.active)
	panel.mission_bar(panel.box(text("prestige_progress") % degree), degree, 100)
	panel.box(text("prestige_rewards"), text("prestige_rewards_body"))
	panel.box(text("prestige_keep"), text("prestige_keep_body"))
	panel.box(text("prestige_reset"), text("prestige_reset_body"))
	if confirm:
		panel.button(panel.rows, text("prestige_commit"), game.confirm_prestige, not campaign.prestige_ready(), true)
		panel.button(panel.rows, text("prestige_cancel"), panel.show_page.bind("prestige"))
	else:
		panel.button(panel.rows, text("prestige_review"), panel.show_page.bind("prestige_confirm"), not campaign.prestige_ready(), true)
		panel.button(panel.rows, text("atlas_return"), panel.show_page.bind("atlas"))

func show_climate() -> void:
	var active: String = game.weather.weather
	panel.feature(hud.ROAD, text("climate_header"), text("climate_current") % text("weather_" + active))
	var site: HbtEconomy = game.economy
	for preset in (["auto", "clear", "haze", "rain", "wind"] if game.is_desert() else ["auto", "clear", "haze", "rain", "snow"]):
		panel.button(panel.rows, text("weather_" + preset), game.choose_weather.bind(preset), false, preset == site.preferences.weather)
	panel.button(panel.rows, text("auto_day_on" if site.preferences.auto_day else "auto_day_off"),
		game.toggle_auto_day, false, site.preferences.auto_day)
	panel.button(panel.rows, text("atlas_return"), panel.show_page.bind("atlas"))
