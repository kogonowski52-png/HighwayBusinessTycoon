extends RefCounted

const FILTERS := ["sites_all", "sites_available", "sites_built", "sites_locked"]

var panel: CanvasLayer
var game: Node3D
var hud: CanvasLayer
var tabs: HBoxContainer
var buttons: Dictionary = {}
var filter := "sites_all"

func setup(owner: CanvasLayer, parent: Control) -> void:
	panel = owner
	game = owner.controller
	hud = owner.theme_source
	tabs = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 7)
	parent.add_child(tabs)
	for key: String in FILTERS:
		var tab: Button = hud.action(tabs, 0, 84, false)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.toggle_mode = true
		tab.pressed.connect(select_filter.bind(key))
		buttons[key] = tab
	tabs.hide()

func select_filter(key: String) -> void:
	if not panel.modal_open():
		return
	filter = key
	panel.scroll.cancel_interaction()
	panel.scroll.scroll_vertical = 0
	panel.refresh()

func draw() -> void:
	for key: String in FILTERS:
		var tab: Button = buttons[key]
		tab.text = game.t(key)
		tab.set_pressed_no_signal(key == filter)
		tab.add_theme_stylebox_override("normal", hud.sculpted(hud.ACTION if key == filter else hud.CREAM_BUTTON, 34, 8))
		tab.add_theme_stylebox_override("pressed", hud.sculpted(hud.ACTION, 34, 8))
		tab.add_theme_color_override("font_color", hud.CREAM if key == filter else hud.INK)
		tab.add_theme_color_override("font_pressed_color", hud.CREAM)
	var groups := {"sites_available": [], "sites_built": [], "sites_locked": []}
	var economy: HbtEconomy = game.economy
	for id: String in economy.facilities:
		var tier := economy.level(id)
		var quote := economy.construction_quote(id)
		var group := "sites_built" if tier > 0 else "sites_available" if quote.ready else "sites_locked"
		groups[group].append({"id": id, "tier": tier, "quote": quote})
	var sections: Array = groups.keys() if filter == "sites_all" else [filter]
	for section: String in sections:
		for site: Dictionary in groups[section]:
			card(site.id, site.tier, site.quote)
	if panel.rows.get_child_count() == 0:
		panel.box(game.t("sites_empty"))

func card(id: String, tier: int, quote: Dictionary) -> void:
	var economy: HbtEconomy = game.economy
	var service: HbtService = economy.facilities[id]
	var ready: bool = tier == 0 and quote.ready
	var shell := PanelContainer.new()
	shell.name = "Business_" + id
	shell.custom_minimum_size.y = 178
	panel.rows.add_child(shell)
	var tint := Color("#e7efd9") if ready else Color("#f7ecd7") if tier == 0 else Color("#f9f2e1")
	shell.add_theme_stylebox_override("panel", hud.style(tint, Color("#8cb89a") if ready else hud.RIM, 20, 10))
	var row := HBoxContainer.new()
	shell.add_child(row)
	row.add_theme_constant_override("separation", 12)
	var image: Texture2D = load("res://assets/ui/business/%s_%s.png" % [economy.district, id]) as Texture2D
	hud.icon(row, image, 137)
	var details := VBoxContainer.new()
	row.add_child(details)
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.alignment = BoxContainer.ALIGNMENT_CENTER
	details.add_theme_constant_override("separation", 2)
	line(details, game.site_name(id), 29, hud.INK, hud.HEAVY)
	var cost: HbtAmount = quote.cost
	var level_text: String = game.t("site_card_level") % [tier, economy.CONFIG.max_level]
	if not ready:
		level_text += " · " + game.t("site_card_cost") % game.money(cost)
	line(details, level_text, 22, hud.FADE, hud.BOLD)
	line(details, game.t("site_projection") % game.money(economy.estimated_bay_income(id)), 22, hud.MINT, hud.BOLD)
	if service.prerequisite_level > 0:
		requirements(details, service, quote)
	var actions := VBoxContainer.new()
	actions.custom_minimum_size.x = 238
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 4)
	row.add_child(actions)
	var status := availability(id, tier, quote)
	var badge := line(actions, game.t(status), 21,
		hud.MINT if ready or status in ["site_built", "site_can_upgrade"] else Color("#835b30"), hud.HEAVY)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var label: String = game.t("unlock") % game.money(cost) if ready else game.t("site_manage" if tier > 0 else "site_details")
	var callback: Callable = game.build_site.bind(id) if ready else game.manage_site.bind(id)
	var button: Button = hud.action(actions, 0, 96, ready)
	button.text = label
	button.tooltip_text = game.site_name(id)
	button.pressed.connect(callback)
	if id == "market":
		panel.tutorial_targets["first_business"] = button

func requirements(parent: Control, service: HbtService, quote: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 11)
	parent.add_child(row)
	var level := line(row, "%s %s" % ["✓" if quote.level_ok else "○",
		game.t("site_needs_level") % [game.site_name(service.prerequisite), quote.level, service.prerequisite_level]], 20,
		hud.MINT if quote.level_ok else Color("#835b30"), hud.BOLD)
	level.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var reputation := line(row, "%s %s" % ["✓" if quote.reputation_ok else "○",
		game.t("site_needs_rep") % [quote.reputation, service.reputation_gate]], 20,
		hud.MINT if quote.reputation_ok else Color("#835b30"), hud.BOLD)
	reputation.autowrap_mode = TextServer.AUTOWRAP_OFF

func availability(id: String, tier: int, quote: Dictionary) -> String:
	if tier > 0:
		return "site_can_upgrade" if game.economy.quote_upgrade(id, 1).affordable else "site_built"
	if quote.ready:
		return "site_ready"
	if not quote.level_ok:
		return "site_no_level"
	if not quote.reputation_ok:
		return "site_no_rep"
	if not quote.cash_ok:
		return "site_no_cash"
	return "site_unavailable"

func line(parent: Control, value: String, size: int, tint: Color, font: Font) -> Label:
	var label: Label = hud.caption(parent, size, tint, font)
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label
