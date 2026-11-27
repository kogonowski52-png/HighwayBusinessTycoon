extends RefCounted

const Data = preload("res://data/economy/recognition.gd")
const Managers = preload("res://data/economy/managers.gd")
const Book = preload("res://data/economy/progression.gd")
const Budget = preload("res://scripts/core/render_budget.gd")
const Prefs = preload("res://scripts/core/player_preferences.gd")
const Store = preload("res://data/economy/store_offers.gd")

var panel: CanvasLayer
var game: Node3D
var hud: CanvasLayer
var page_medal := 0
var manager_id := ""
var knob: GradientTexture2D

func bind_to(owner: CanvasLayer) -> void:
	panel = owner
	game = panel.controller
	hud = panel.theme_source

func show(name: String) -> void:
	match name:
		"settings": settings()
		"diagnostics": diagnostics()
		"calendar": calendar()
		"achievements": achievements()
		"managers": managers()
		"manager_detail": manager_detail()
		"shop": shop()
		"rank": rank()
		"help": help()
		"licenses": licenses()
		"privacy": privacy()

func settings() -> void:
	var store: HbtEconomy = game.economy
	var preferences = store.preferences
	var info: VBoxContainer = panel.feature(hud.SETTINGS, game.t("settings_header"),
		game.t("about_version") % ProjectSettings.get_setting("application/config/version"))
	var about := HBoxContainer.new()
	info.add_child(about)
	panel.button(panel.rows, game.t("analytics_on" if game.campaign.premium.analytics else "analytics_off"),
		game.set_local_analytics)
	for name in ["help", "licenses", "privacy"]:
		var link: Button = panel.button(about, game.t(name), panel.show_page.bind(name))
		link.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var system: VBoxContainer = panel.box(game.t("preferences_display"))
	panel.section_row(system, ["PL", "EN"], store.language.to_upper(), game.set_language)
	var graphic_labels: Array[String] = []
	for name in Budget.LABELS:
		graphic_labels.append(game.t(name))
	panel.section_row(system, graphic_labels, graphic_labels[preferences.quality] if not preferences.quality_auto else "",
		game.set_quality, true)
	panel.button(system, game.t("quality_auto_on") % graphic_labels[game.render_quality] if preferences.quality_auto else game.t("quality_auto_off"),
		game.set_quality_auto, false, preferences.quality_auto)
	panel.section_row(system, ["30 FPS", "60 FPS"], "%d FPS" % preferences.fps, game.set_fps, true)
	panel.button(system, game.t("battery_on" if store.low_power else "battery_off"), game.toggle_power, false, store.low_power)
	if store.low_power:
		var note: Label = hud.caption(system, 24, hud.FADE)
		note.text = game.t("battery_effect")
	if is_instance_valid(game.diagnostics):
		panel.button(system, game.t("diagnostics_header"), game.open_page.bind("diagnostics"))
	var mixing: VBoxContainer = panel.box(game.t("preferences_audio"))
	for group in Prefs.CHANNELS:
		var row := HBoxContainer.new()
		mixing.add_child(row)
		var tag: Label = hud.caption(row, 27, hud.INK, hud.HEAVY)
		tag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tag.text = game.t("volume_" + group)
		var number: Label = hud.caption(row, 26, hud.MINT, hud.HEAVY)
		number.text = "%d%%" % roundi(preferences.volumes[group] * 100.0)
		var slider := HSlider.new()
		slider.name = group
		mixing.add_child(slider)
		slider.custom_minimum_size.y = 65
		slider.max_value = 1.0
		slider.step = 0.01
		slider.value = preferences.volumes[group]
		var trough: StyleBoxFlat = hud.style(Color("#dfcfb2"), Color("#a68972"), 9, 0)
		trough.content_margin_top = 8
		trough.content_margin_bottom = 8
		slider.add_theme_stylebox_override("slider", trough)
		slider.add_theme_stylebox_override("grabber_area", hud.style(Color("#559882"), Color("#3b6f65"), 9, 1))
		slider.add_theme_stylebox_override("grabber_area_highlight", hud.style(Color("#73b4a0"), Color("#3b6f65"), 9, 1))
		slider.add_theme_icon_override("grabber", handle())
		slider.add_theme_icon_override("grabber_highlight", handle())
		slider.value_changed.connect(func(value: float) -> void:
			number.text = "%d%%" % roundi(value * 100.0)
			game.set_volume(group, value))
	panel.button(mixing, game.t("vibration_on" if preferences.haptics else "vibration_off"),
		game.toggle_haptics, false, preferences.haptics)
	if game.ads.privacy_required():
		panel.button(mixing, game.t("ad_privacy"), game.ads.privacy)

func diagnostics() -> void:
	if not is_instance_valid(game.diagnostics):
		return
	var monitor: CanvasLayer = game.diagnostics
	panel.box(game.t("diagnostics_header"), monitor.sdk_summary())
	panel.button(panel.rows, game.t("diagnostic_fps_on" if monitor.board.visible else "diagnostic_fps_off"), toggle_monitor)
	if game.ads.available():
		panel.button(panel.rows, game.t("diagnostic_load_ad"), game.ads.prepare.bind("boost"), game.ads.busy() or game.ads.loading("boost"))
	if game.purchases.configured():
		panel.button(panel.rows, game.t("diagnostic_check_store"), game.purchases.open.bind(true))
	if game.purchases.verified_checkout():
		panel.button(panel.rows, game.t("diagnostic_check_https"), game.purchases.check_verifier.bind(true))

func toggle_monitor() -> void:
	game.diagnostics.toggle()
	panel.refresh()

func handle() -> GradientTexture2D:
	if knob == null:
		knob = GradientTexture2D.new()
		knob.width = 52
		knob.height = 52
		knob.fill = GradientTexture2D.FILL_RADIAL
		knob.fill_from = Vector2(0.43, 0.39)
		knob.fill_to = Vector2(0.95, 0.52)
		var ramp := Gradient.new()
		ramp.offsets = PackedFloat32Array([0.0, 0.57, 0.84, 1.0])
		ramp.colors = PackedColorArray([Color("#fff6d4"), Color("#f2c879"), Color("#a06845"), Color.TRANSPARENT])
		knob.gradient = ramp
	return knob

func calendar() -> void:
	var store: HbtEconomy = game.economy
	var state = store.recognition
	if game.ads.available() and game.ads.playable("daily"):
		panel.button(panel.rows, game.t("offer_daily"), panel.premium.select_offer.bind("daily", {}))
	var available: bool = state.is_available(store.day_index()) and not store.storage.read_only
	var slot: int = state.slot()
	var filled := 30 if slot == 0 and state.daily_count > 0 and not available else slot
	var offer := store.calendar_offer()
	var feature: VBoxContainer = panel.feature(hud.CALENDAR, game.t("calendar_header"),
		game.t("calendar_next_prize") % reward_name(offer) if available else game.t("calendar_next_day"))
	if available:
		var claim: Button = panel.button(feature, game.t("calendar_claim") % (slot + 1), game.claim_calendar, false, true)
		hud.button_art(claim, reward_icon(offer), 62)
	var layout := GridContainer.new()
	layout.columns = 5
	layout.add_theme_constant_override("h_separation", 7)
	layout.add_theme_constant_override("v_separation", 8)
	panel.rows.add_child(layout)
	for index in range(Data.CALENDAR.size()):
		var reward: Array = Data.CALENDAR[index]
		var tile := PanelContainer.new()
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		layout.add_child(tile)
		var earned := index < filled
		var next := available and index == slot
		var color := Color("#ddedda") if earned else Color("#fff0be") if next else Color("#fff5dd")
		tile.add_theme_stylebox_override("panel", hud.style(color, Color("#946634") if next else hud.RIM, 19, 8))
		var cell := VBoxContainer.new()
		tile.add_child(cell)
		cell.add_theme_constant_override("separation", 4)
		var day: Label = hud.caption(cell, 22, hud.MINT if earned else hud.GOLD, hud.HEAVY)
		day.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		day.text = game.t("calendar_day") % (index + 1)
		var icon: TextureRect = hud.icon(cell, reward_icon(reward), 71)
		icon.modulate.a = 0.65 if earned else 1.0
		var amount: Label = hud.caption(cell, 19, hud.INK)
		amount.text = reward_short(reward)
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		amount.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var note: Label = hud.caption(panel.rows, 23, hud.FADE)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.text = game.t("calendar_rules") % Data.DUPLICATE_DIAMONDS

func reward_icon(offer: Array) -> Texture2D:
	match offer[0]:
		"cash": return hud.CASH
		"diamond": return hud.DIAMOND
		"reputation": return hud.REPUTATION
		"card": return portrait(offer[1])
	return hud.GIFT

func reward_short(offer: Array) -> String:
	match offer[0]:
		"cash": return game.money(HbtAmount.from(offer[1]))
		"card": return Managers.ROSTER[offer[1]].name.split(" ")[0]
	return "×%d" % offer[1]

func reward_name(offer: Array) -> String:
	if offer[0] == "card":
		return Managers.ROSTER[offer[1]].name
	if offer[0] == "cash":
		return game.money(HbtAmount.from(offer[1]))
	return "%d %s" % [offer[1], game.t("reward_" + offer[0])]

func achievements() -> void:
	var store: HbtEconomy = game.economy
	var finished := store.recognition.achievement_claimed.size()
	panel.feature(hud.REPUTATION, game.t("achievements_header"), game.t("ach_total") % [finished, Data.collection.size()])
	var count_tracks := Data.track_count(store.district)
	page_medal = mini(page_medal, count_tracks - 1)
	var id: String = Data.GROUPS[page_medal][0] if page_medal < Data.GROUPS.size() else "frontier_medals"
	var selected: VBoxContainer = panel.box(game.t("ach_" + id), game.t("collection_page") % [page_medal + 1, count_tracks])
	var navigation := HBoxContainer.new()
	selected.add_child(navigation)
	for turn in [-1, 1]:
		var flip: Button = panel.button(navigation, game.t("previous") if turn < 0 else game.t("next"),
			browse_medal.bind(turn), page_medal + turn < 0 or page_medal + turn >= count_tracks)
		flip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for item in Data.collection.values():
		if item.group != id or item.get("district", store.district) != store.district:
			continue
		var amount := store.achievement_progress(item)
		var regional: bool = item.has("district")
		var title: String = item[store.language] if regional else game.t("ach_" + id) + " " + Data.ROMAN[item.tier]
		var row: VBoxContainer = panel.box(title)
		var contents := HBoxContainer.new()
		row.add_child(contents)
		hud.icon(contents, load(item.icon) as Texture2D, 107)
		var words := VBoxContainer.new()
		contents.add_child(words)
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var description: Label = hud.caption(words, 25, hud.INK)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var goal: String = game.money(HbtAmount.from(item.goal)) if id == "gross" else str(item.goal)
		if regional:
			if item.site.is_empty():
				description.text = game.t("ach_rule_" + item.counter) % goal
			else:
				description.text = game.t("ach_site_" + item.counter) % [game.site_name(item.site), int(item.goal)]
		else:
			description.text = game.t("ach_rule_" + id) % goal
		var count: Label = hud.caption(words, 22, hud.MINT, hud.HEAVY)
		count.text = "%s · %s" % [game.t("progress_pair") % [HbtAmount.from(amount).compact(store.language),
			HbtAmount.from(item.goal).compact(store.language)], game.t("ach_prize") % item.reward]
		panel.mission_bar(words, amount, item.goal)
		var won: bool = store.recognition.achievement_claimed.has(item.id)
		if won:
			var mark: Label = hud.caption(words, 21, hud.MINT, hud.HEAVY)
			mark.text = game.t("claimed")
		elif amount >= int(item.goal):
			var claim: Button = panel.button(row, game.t("claim"), game.claim_achievement.bind(item.id), false, true)
			hud.button_art(claim, hud.DIAMOND, 53)

func browse_medal(delta: int) -> void:
	page_medal = clampi(page_medal + delta, 0, Data.track_count(game.economy.district) - 1)
	panel.scroll.scroll_vertical = 0
	panel.refresh()

func portrait(id: String) -> Texture2D:
	return load("res://assets/ui/managers/%s.png" % id) as Texture2D

func managers() -> void:
	var store: HbtEconomy = game.economy
	var list := Managers.catalog(store.district)
	var owned_count := list.filter(func(id: String) -> bool: return store.cards.has(id)).size()
	panel.feature(hud.CARDS, game.t("manager_collection") % [owned_count, list.size()],
		game.t("manager_capacity") % [store.equipped.size(), store.CONFIG.max_active_managers])
	var shelf := GridContainer.new()
	shelf.columns = 3
	shelf.add_theme_constant_override("h_separation", 8)
	shelf.add_theme_constant_override("v_separation", 12)
	panel.rows.add_child(shelf)
	for key in list:
		var profile: Dictionary = Managers.ROSTER[key]
		var owned := store.cards.has(key)
		var card: Button = panel.button(shelf, profile.name, open_manager.bind(key))
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size.y = 244
		var base: Color = panel.RARITY[profile.rarity]
		card.add_theme_stylebox_override("normal", hud.style(base, base.darkened(.29), 27, 11))
		card.add_theme_stylebox_override("hover", hud.style(base.lightened(.10), base.darkened(.26), 27, 11))
		card.add_theme_stylebox_override("pressed", hud.style(base.darkened(.08), base.darkened(.30), 27, 11))
		card.add_theme_constant_override("icon_max_width", 163)
		card.add_theme_font_size_override("font_size", 24)
		card.icon = portrait(key)
		card.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		card.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		card.tooltip_text = game.t("cards_locked") if not owned else game.t("manager_rank") % [store.manager_rank(key), Managers.MAX_RANK]
		if key in store.equipped:
			var badge: Label = hud.caption(card, 18, hud.MINT, hud.HEAVY)
			badge.position = Vector2(10, 8)
			badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			badge.text = game.t("manager_active")

func open_manager(id: String) -> void:
	manager_id = id
	panel.show_page("manager_detail")

func manager_detail() -> void:
	if manager_id.is_empty():
		return
	var store: HbtEconomy = game.economy
	var card: Dictionary = Managers.ROSTER[manager_id]
	var rarity: String = game.t("rarity_" + card.rarity)
	var area: String = game.t("manager_all") if card.site.is_empty() else game.site_name(card.site)
	var level := store.manager_rank(manager_id)
	var hero: VBoxContainer = panel.feature(portrait(manager_id), card.name, rarity + " · " + area)
	var image: TextureRect = hero.get_child(0).get_child(0)
	image.custom_minimum_size = Vector2(219, 219)
	if level > 0:
		var xp: int = store.recognition.mentor_xp.get(manager_id, 0)
		var band := Data.xp_band(xp)
		var summary: VBoxContainer = panel.box(game.t("manager_rank") % [level, Managers.MAX_RANK],
			game.t("manager_xp") % [band.index, xp] if not band.maxed else game.t("manager_xp_max") % xp)
		panel.mission_bar(summary, band.have, band.goal)
	var effect := manager_description(manager_id, maxi(1, level))
	panel.box(game.t("current_effect") if level > 0 else game.t("preview_effect"), effect)
	if level in range(1, Managers.MAX_RANK):
		panel.box(game.t("next_effect") % (level + 1), manager_description(manager_id, level + 1))
	if level == 0:
		if card.has("source"):
			panel.button(panel.rows, game.t("shop_header" if card.source == "store" else "pass_header"),
				game.open_page.bind("shop" if card.source == "store" else "pass"), false, true)
		else:
			var source: Dictionary = panel.card_source(store, manager_id)
			panel.button(panel.rows, game.t("manager_source") % source.label, panel.open_card_source.bind(source), false, true)
	else:
		var assigned: bool = manager_id in store.equipped
		panel.button(panel.rows, game.t("remove" if assigned else "assign"), game.assign_manager.bind(manager_id),
			not assigned and store.equipped.size() >= store.CONFIG.max_active_managers, true)
		var price := store.manager_training(manager_id)
		if not price.is_empty():
			var train: Button = panel.button(panel.rows, game.t("manager_train") % price.cost,
				game.train_manager.bind(manager_id), not price.ready)
			hud.button_art(train, hud.DIAMOND, 59)
			if store.player_level() < price.level:
				panel.box(game.t("manager_gate") % price.level)
	panel.button(panel.rows, game.t("back_collection"), panel.show_page.bind("managers"))

func manager_description(id: String, rank: int) -> String:
	var skill: String = Managers.ROSTER[id].skill
	var label: String = game.t("skill_" + skill)
	if skill == "collect":
		return label + (" " + game.t("skill_collect_bonus") % (3 * (rank - 1)) if rank > 1 else "")
	return label % floori(Managers.value(id, rank) / 100.0)

func shop() -> void:
	var store: HbtEconomy = game.economy
	panel.box(game.t("shop_earned"))
	var clock := store.boost_until - store.clock
	if clock > 0:
		panel.box(game.t("boost_running") % game.clock_text(clock))
	for offer in Store.OFFERS:
		var icon: Texture2D
		var cost: int
		var callback := Callable(game, offer.action)
		var detail := ""
		var ready := true
		match offer.key:
			"voucher":
				if store.recognition.vouchers <= 0:
					continue
				icon = hud.GIFT
				cost = 1
				detail = game.t("voucher_count") % store.recognition.vouchers
				ready = clock <= 0
			"boost":
				cost = store.CONFIG.boost_cost
				icon = hud.DIAMOND
				ready = clock <= 0
			"event_diamond":
				cost = Book.EVENT_DIAMOND_COST
				icon = hud.DIAMOND
				callback = callback.bind(false)
				detail = game.t("shop_diamonds") % Book.EVENT_DIAMONDS
			"event_card":
				if store.cards.has("mira"):
					continue
				cost = Book.EVENT_CARD_COST
				icon = portrait("mira")
				callback = callback.bind(true)
				detail = Managers.ROSTER.mira.name
		var row: VBoxContainer = panel.feature(icon, game.t(offer.title), detail)
		var label: String = game.t("shop_price_" + offer.currency) % cost
		panel.button(row, label, callback, not ready or (offer.currency != "voucher"
			and not store.can_afford(HbtAmount.from(cost), offer.currency)), true)
	panel.button(panel.rows, game.t("calendar_header"), panel.show_page.bind("calendar"))

func rank() -> void:
	var store: HbtEconomy = game.economy
	panel.feature(hud.REPUTATION, game.t("rank_header"), game.t("rank_description") % store.player_level())
	panel.show_player_rank(store)

func help() -> void:
	panel.feature(hud.HELP, game.t("help_header"))
	for key in ["camera", "cash", "crew", "offline", "daily"]:
		panel.box(game.t("help_" + key), game.t("help_" + key + "_body"))
	panel.button(panel.rows, game.t("settings_header"), panel.show_page.bind("settings"))

func privacy() -> void:
	panel.feature(hud.HELP, game.t("privacy_header"))
	panel.box(game.t("privacy_save"), game.t("privacy_save_body"))
	panel.box(game.t("privacy_services"), game.t("store_privacy"))
	var policy: String = game.purchases.privacy_url()
	if not policy.is_empty():
		panel.button(panel.rows, game.t("privacy_read_online"), func() -> void: OS.shell_open(policy))
	panel.button(panel.rows, game.t("settings_header"), panel.show_page.bind("settings"))

func licenses() -> void:
	panel.feature(hud.HELP, game.t("licenses_header"))
	panel.box(game.t("licenses_original"), game.t("licenses_original_body"))
	var notice := FileAccess.get_file_as_string("res://assets/fonts/LICENSE-Open-Sans.txt")
	var license := FileAccess.get_file_as_string("res://assets/fonts/Apache-2.0.txt")
	panel.box("Open Sans · Apache 2.0", notice + "\n\n" + license)
	panel.button(panel.rows, game.t("settings_header"), panel.show_page.bind("settings"))
