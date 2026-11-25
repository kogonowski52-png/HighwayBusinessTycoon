extends CanvasLayer

signal serve_requested
signal upgrade_requested
signal language_requested
signal power_requested
signal lighting_requested
signal view_requested
signal page_requested(page: String)
signal quantity_requested(quantity: int)
signal income_requested

const REGULAR = preload("res://assets/fonts/OpenSans-Regular.ttf")
const BOLD = preload("res://assets/fonts/OpenSans-Bold.ttf")
const HEAVY = preload("res://assets/fonts/OpenSans-ExtraBold.ttf")
const PUMP = preload("res://assets/ui/icon_fuel.png")
const ROAD = preload("res://assets/ui/icon_road.png")
const STAFF = preload("res://assets/ui/icon_staff.png")
const CASH = preload("res://assets/ui/icon_cash.png")
const NAV := {"sites": preload("res://assets/ui/icon_sites.png"), "team": STAFF,
	"goals": preload("res://assets/ui/icon_goals.png"), "finance": preload("res://assets/ui/icon_finance.png")}
const IVORY = preload("res://assets/ui/panel_ivory.png")
const ACTION = preload("res://assets/ui/button_mint.png")
const UPGRADE = preload("res://assets/ui/button_honey.png")
const INK := Color("#243a43")
const PANEL := Color("#fff9ed")
const RIM := Color("#d2bea1")
const CREAM := Color("#fff8e8")
const GOLD := Color("#956023")
const FADE := Color("#536760")
const MINT := Color("#2b795f")

var location: Label
var title: Label
var traffic_caption: Label
var people_caption: Label
var people: Label
var cash_caption: Label
var cash: Label
var level: Label
var station: Label
var status: Label
var rate: Label
var serve: Button
var upgrade: Button
var language: Button
var power: Button
var lighting: Button
var view: Button
var progress: ProgressBar
var queued: Label
var wallet_stats: Dictionary = {}
var pages: Dictionary = {}
var quantities: Dictionary = {}
var income: Button
var reserve: Label
var shown_cash: HbtAmount
var next_cash: HbtAmount
var cash_locale := ""
var cash_pattern := ""
var counting: Tween

func _ready() -> void:
	var root := Control.new()
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var top := band(root, false)
	var header := VBoxContainer.new()
	top.add_child(header)
	header.add_theme_constant_override("separation", 11)
	var hero := HBoxContainer.new()
	header.add_child(hero)
	hero.add_theme_constant_override("separation", 16)
	var heading := VBoxContainer.new()
	hero.add_child(heading)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	location = caption(heading, 22, GOLD, HEAVY)
	title = caption(heading, 51, INK, HEAVY)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var settings := HBoxContainer.new()
	hero.add_child(settings)
	settings.alignment = BoxContainer.ALIGNMENT_END
	settings.add_theme_constant_override("separation", 10)
	language = action(settings, 84, 68, false)
	power = action(settings, 110, 68, false)
	language.pressed.connect(func() -> void: language_requested.emit())
	power.pressed.connect(func() -> void: power_requested.emit())

	var stats := HBoxContainer.new()
	header.add_child(stats)
	stats.add_theme_constant_override("separation", 12)
	var highway := tile(stats, ROAD, Color("#f2ead9"))
	traffic_caption = caption(highway, 20, FADE)
	queued = caption(highway, 34, INK, HEAVY)
	var visits := tile(stats, STAFF, Color("#f5eadc"))
	people_caption = caption(visits, 20, FADE)
	people = caption(visits, 34, INK, HEAVY)
	var treasury := tile(stats, CASH, Color("#e1efdf"))
	cash_caption = caption(treasury, 20, FADE)
	cash = caption(treasury, 35, MINT, HEAVY)
	var balances := HBoxContainer.new()
	header.add_child(balances)
	balances.add_theme_constant_override("separation", 12)
	for id in ["diamond", "reputation", "event"]:
		var item := caption(balances, 19, FADE)
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		wallet_stats[id] = item

	var framing := VBoxContainer.new()
	root.add_child(framing)
	framing.set_anchor(SIDE_LEFT, 1.0)
	framing.set_anchor(SIDE_RIGHT, 1.0)
	framing.set_anchor(SIDE_TOP, 0.194)
	framing.set_anchor(SIDE_BOTTOM, 0.194)
	framing.offset_left = -213.0
	framing.offset_right = -34.0
	framing.offset_top = 0.0
	framing.offset_bottom = 0.0
	framing.add_theme_constant_override("separation", 10)
	lighting = action(framing, 164, 65, false)
	view = action(framing, 164, 65, false)
	lighting.pressed.connect(func() -> void: lighting_requested.emit())
	view.pressed.connect(func() -> void: view_requested.emit())

	var bottom := band(root, true)
	var card := VBoxContainer.new()
	bottom.add_child(card)
	card.add_theme_constant_override("separation", 10)
	var top_row := HBoxContainer.new()
	card.add_child(top_row)
	top_row.add_theme_constant_override("separation", 20)
	icon(top_row, PUMP, 85)
	var station_info := VBoxContainer.new()
	top_row.add_child(station_info)
	station_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level = caption(station_info, 23, GOLD)
	station = caption(station_info, 39, INK, HEAVY)
	station.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rate = caption(top_row, 24, MINT)
	rate.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status = caption(card, 27, FADE, BOLD)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	progress = ProgressBar.new()
	card.add_child(progress)
	progress.custom_minimum_size.y = 11
	progress.max_value = 1.0
	progress.step = 0.0
	progress.show_percentage = false
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress.add_theme_stylebox_override("background", style(Color("#e7dac4"), RIM, 7, 0))
	progress.add_theme_stylebox_override("fill", style(MINT, MINT, 7, 0))
	reserve = caption(card, 23, GOLD)
	reserve.visible = false
	var purchase := HBoxContainer.new()
	card.add_child(purchase)
	purchase.add_theme_constant_override("separation", 8)
	for count in [1, 10, 25, 0]:
		var option := action(purchase, 0, 55, false)
		option.toggle_mode = true
		option.add_theme_stylebox_override("pressed", style(Color("#d5eadb"), MINT, 18, 10))
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option.text = "MAX" if count == 0 else "+%d" % count
		option.pressed.connect(func() -> void: quantity_requested.emit(count))
		quantities[count] = option
	var actions := HBoxContainer.new()
	card.add_child(actions)
	actions.add_theme_constant_override("separation", 14)
	serve = action(actions, 0, 92, true)
	serve.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrade = action(actions, 305, 92, false)
	upgrade.add_theme_stylebox_override("normal", sculpted(UPGRADE, 24, 10))
	upgrade.add_theme_stylebox_override("hover", style(Color("#ffe5a8"), Color("#b48443"), 18, 10))
	upgrade.add_theme_stylebox_override("pressed", style(Color("#ecb35e"), Color("#b48443"), 18, 10))
	serve.pressed.connect(func() -> void: serve_requested.emit())
	upgrade.pressed.connect(func() -> void: upgrade_requested.emit())
	income = action(card, 0, 66, false)
	income.visible = false
	income.pressed.connect(func() -> void: income_requested.emit())
	var tabs := HBoxContainer.new()
	card.add_child(tabs)
	tabs.add_theme_constant_override("separation", 8)
	for page in ["sites", "team", "goals", "finance"]:
		var tab := action(tabs, 0, 70, false)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.icon = NAV[page]
		tab.add_theme_constant_override("icon_max_width", 48)
		tab.add_theme_constant_override("h_separation", 4)
		tab.pressed.connect(func() -> void: page_requested.emit(page))
		pages[page] = tab

func band(root: Control, bottom: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	root.add_child(panel)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", sculpted(IVORY, 35, 26))
	var anchor := float(bottom)
	panel.anchor_right = 1.0
	panel.anchor_top = anchor
	panel.anchor_bottom = anchor
	panel.offset_left = 29
	panel.offset_right = -29
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN if bottom else Control.GROW_DIRECTION_END
	if bottom:
		panel.offset_top = -34
		panel.offset_bottom = -34
	else:
		panel.offset_top = 33
	return panel

func tile(parent: Control, texture: Texture2D, tint: Color) -> VBoxContainer:
	var shell := PanelContainer.new()
	parent.add_child(shell)
	shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.add_theme_stylebox_override("panel", style(tint, RIM, 19, 9))
	var row := HBoxContainer.new()
	shell.add_child(row)
	row.add_theme_constant_override("separation", 8)
	icon(row, texture, 56)
	var body := VBoxContainer.new()
	row.add_child(body)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return body

func caption(parent: Control, font_size: int, color: Color, font: Font = BOLD) -> Label:
	var label := Label.new()
	parent.add_child(label)
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func icon(parent: Control, texture: Texture2D, side: int) -> void:
	var image := TextureRect.new()
	parent.add_child(image)
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size = Vector2(side, side)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE

func action(parent: Control, width: int, height: int, primary: bool) -> Button:
	var button := Button.new()
	parent.add_child(button)
	button.custom_minimum_size = Vector2(width, height)
	button.add_theme_font_override("font", HEAVY)
	button.add_theme_font_size_override("font_size", 30 if height > 80 else 23)
	var normal := Color("#32846e") if primary else PANEL
	var text := CREAM if primary else INK
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var fill := normal
		match state:
			"hover": fill = normal.lightened(0.12)
			"pressed": fill = normal.darkened(0.12)
			"focus": fill = Color.TRANSPARENT
			"disabled": fill = Color("#e7decc")
		button.add_theme_stylebox_override(state, style(fill, GOLD if state == "focus" else RIM, 18, 10))
	if primary:
		button.add_theme_stylebox_override("normal", sculpted(ACTION, 24, 10))
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(key, text)
	button.add_theme_color_override("font_disabled_color", Color("#68756a"))
	return button

func style(fill: Color, border: Color, radius: int, padding: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(2)
	box.border_width_bottom = 3
	box.set_corner_radius_all(radius)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		box.set_content_margin(side, padding)
	return box

func sculpted(texture: Texture2D, corner: int, padding: int) -> StyleBoxTexture:
	var style_box := StyleBoxTexture.new()
	style_box.texture = texture
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style_box.set_texture_margin(side, corner)
		style_box.set_content_margin(side, padding)
	return style_box

func update_cash(value: HbtAmount, locale: String, pattern: String, animate: bool) -> void:
	var locale_changed := cash_locale != locale
	var in_motion := counting != null and counting.is_running()
	if next_cash != null and next_cash.compare(value) == 0 and not locale_changed and (animate or not in_motion):
		return
	if in_motion:
		counting.kill()
	cash.modulate = Color.WHITE
	next_cash = value
	cash_locale = locale
	cash_pattern = pattern
	if shown_cash == null or not animate or locale_changed or shown_cash.compare(value) == 0:
		display_cash(value)
		return
	var origin := shown_cash
	var growing := value.compare(origin) > 0
	var distance := value.minus(origin) if growing else origin.minus(value)
	counting = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	counting.tween_method(func(step: int) -> void:
		var moved := distance.times(step).divided(1000)
		display_cash(origin.plus(moved) if growing else origin.minus(moved)), 0, 1000, 0.38)
	if growing:
		cash.modulate = Color(1.30, 1.16, 1.04)
		counting.parallel().tween_property(cash, "modulate", Color.WHITE, 0.34)

func display_cash(value: HbtAmount) -> void:
	shown_cash = value
	cash.text = cash_pattern % value.compact(cash_locale)
