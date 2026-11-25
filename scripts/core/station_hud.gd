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
const NUMERALS = preload("res://assets/fonts/Route17Counter.ttf")
const DIAMOND = preload("res://assets/ui/icon_diamond.png")
const REPUTATION = preload("res://assets/ui/icon_reputation.png")
const EVENT = preload("res://assets/ui/icon_event.png")
const UPGRADE_ART = preload("res://assets/ui/icon_upgrade.png")
const STAGE_ART := [preload("res://assets/ui/icon_stage_1.png"), preload("res://assets/ui/icon_stage_2.png"),
	preload("res://assets/ui/icon_stage_3.png"), preload("res://assets/ui/icon_stage_4.png"), preload("res://assets/ui/icon_stage_5.png")]
const NAV := {"sites": preload("res://assets/ui/icon_sites.png"), "team": STAFF,
	"goals": preload("res://assets/ui/icon_goals.png"), "finance": preload("res://assets/ui/icon_finance.png")}
const IVORY = preload("res://assets/ui/panel_ivory.png")
const ACTION = preload("res://assets/ui/button_mint.png")
const UPGRADE = preload("res://assets/ui/button_honey.png")
const PETROL = preload("res://assets/ui/panel_petrol.png")
const CREAM_BUTTON = preload("res://assets/ui/button_cream.png")
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
var upgrade_preview: Button
var language: Button
var power: Button
var lighting: Button
var view: Button
var progress: ProgressBar
var queued: Label
var wallet_stats: Dictionary = {}
var wallet_names: Dictionary = {}
var pages: Dictionary = {}
var quantities: Dictionary = {}
var income: Button
var reserve: Label
var shown_cash: HbtAmount
var next_cash: HbtAmount
var cash_locale := ""
var cash_pattern := ""
var counting: Tween
var overlay := Control.new()
var active_rewards := 0
var notice: PanelContainer

func _ready() -> void:
	var root := Control.new()
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var top := band(root, false)
	var header := VBoxContainer.new()
	top.add_child(header)
	header.add_theme_constant_override("separation", 7)
	var hero := HBoxContainer.new()
	header.add_child(hero)
	hero.add_theme_constant_override("separation", 16)
	var heading := VBoxContainer.new()
	hero.add_child(heading)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title = caption(heading, 42, CREAM, HEAVY)
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var roadside := HBoxContainer.new()
	heading.add_child(roadside)
	roadside.add_theme_constant_override("separation", 11)
	location = caption(roadside, 20, Color("#f2c17e"), HEAVY)
	traffic_caption = caption(roadside, 19, Color("#e0dec8"))
	queued = caption(roadside, 21, Color("#fff0cc"), HEAVY)
	people_caption = caption(roadside, 19, Color("#e0dec8"))
	people = caption(roadside, 21, Color("#fff0cc"), HEAVY)
	var settings := HBoxContainer.new()
	hero.add_child(settings)
	settings.alignment = BoxContainer.ALIGNMENT_END
	settings.add_theme_constant_override("separation", 10)
	language = action(settings, 72, 64, false)
	power = action(settings, 100, 64, false)
	language.pressed.connect(func() -> void: language_requested.emit())
	power.pressed.connect(func() -> void: power_requested.emit())

	var counter := FontVariation.new()
	counter.base_font = NUMERALS
	counter.fallbacks = [HEAVY]
	var balances := HBoxContainer.new()
	header.add_child(balances)
	balances.add_theme_constant_override("separation", 8)
	var treasury := tile(balances, CASH, Color("#d7ead8"))
	cash_caption = caption(treasury, 17, FADE, HEAVY)
	cash = caption(treasury, 34, MINT, counter)
	for data in [["diamond", DIAMOND, Color("#eee1f6"), Color("#684285")],
		["reputation", REPUTATION, Color("#f4e5b9"), Color("#86541d")],
		["event", EVENT, Color("#f4dfd3"), Color("#8b4b37")]]:
		var purse := tile(balances, data[1], data[2])
		wallet_names[data[0]] = caption(purse, 16, FADE, HEAVY)
		wallet_stats[data[0]] = caption(purse, 33, data[3], counter)

	var framing := VBoxContainer.new()
	root.add_child(framing)
	framing.set_anchor(SIDE_LEFT, 1.0)
	framing.set_anchor(SIDE_RIGHT, 1.0)
	framing.set_anchor(SIDE_TOP, 0.155)
	framing.set_anchor(SIDE_BOTTOM, 0.155)
	framing.offset_left = -200.0
	framing.offset_right = -34.0
	framing.offset_top = 0.0
	framing.offset_bottom = 0.0
	framing.add_theme_constant_override("separation", 10)
	lighting = action(framing, 152, 60, false)
	view = action(framing, 152, 60, false)
	button_art(view, ROAD, 46)
	lighting.pressed.connect(func() -> void: lighting_requested.emit())
	view.pressed.connect(func() -> void: view_requested.emit())

	var bottom := band(root, true)
	var card := VBoxContainer.new()
	bottom.add_child(card)
	card.add_theme_constant_override("separation", 8)
	var top_row := HBoxContainer.new()
	card.add_child(top_row)
	top_row.add_theme_constant_override("separation", 14)
	icon(top_row, PUMP, 82)
	var station_info := VBoxContainer.new()
	top_row.add_child(station_info)
	station_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level = caption(station_info, 21, GOLD, HEAVY)
	station = caption(station_info, 36, INK, HEAVY)
	station.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	upgrade_preview = action(top_row, 160, 68, false)
	upgrade_preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button_art(upgrade_preview, UPGRADE_ART, 49)
	upgrade_preview.pressed.connect(func() -> void: page_requested.emit("upgrades"))
	status = caption(card, 24, FADE, BOLD)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	progress = ProgressBar.new()
	card.add_child(progress)
	progress.custom_minimum_size.y = 15
	progress.max_value = 1.0
	progress.step = 0.0
	progress.show_percentage = false
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress.add_theme_stylebox_override("background", style(Color("#b9ac90"), Color("#a69573"), 7, 0))
	progress.add_theme_stylebox_override("fill", style(Color("#4d9b76"), Color("#277152"), 7, 0))
	var service_stats := HBoxContainer.new()
	card.add_child(service_stats)
	reserve = caption(service_stats, 20, GOLD)
	reserve.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reserve.visible = false
	rate = caption(service_stats, 22, MINT, counter)
	rate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rate.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var purchase := HBoxContainer.new()
	card.add_child(purchase)
	purchase.add_theme_constant_override("separation", 8)
	for count in [1, 10, 25, 0]:
		var option := action(purchase, 0, 49, false)
		option.toggle_mode = true
		option.add_theme_stylebox_override("pressed", style(Color("#d5eadb"), MINT, 18, 10))
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option.text = "MAX" if count == 0 else "+%d" % count
		option.pressed.connect(func() -> void: quantity_requested.emit(count))
		quantities[count] = option
	var actions := HBoxContainer.new()
	card.add_child(actions)
	actions.add_theme_constant_override("separation", 14)
	serve = action(actions, 0, 88, true)
	serve.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_art(serve, PUMP, 66)
	upgrade = action(actions, 339, 88, false)
	button_art(upgrade, UPGRADE_ART, 63)
	upgrade.add_theme_stylebox_override("normal", sculpted(UPGRADE, 24, 10))
	upgrade.add_theme_stylebox_override("hover", style(Color("#ffe5a8"), Color("#b48443"), 18, 10))
	upgrade.add_theme_stylebox_override("pressed", style(Color("#ecb35e"), Color("#b48443"), 18, 10))
	serve.pressed.connect(func() -> void: serve_requested.emit())
	upgrade.pressed.connect(func() -> void: upgrade_requested.emit())
	income = action(card, 0, 66, false)
	button_art(income, CASH, 57)
	income.visible = false
	income.pressed.connect(func() -> void: income_requested.emit())
	var tabs := HBoxContainer.new()
	card.add_child(tabs)
	tabs.add_theme_constant_override("separation", 8)
	for page in ["sites", "team", "goals", "finance"]:
		var tab := action(tabs, 0, 71, false)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.add_theme_stylebox_override("normal", sculpted(CREAM_BUTTON, 24, 8))
		button_art(tab, NAV[page], 52)
		tab.pressed.connect(func() -> void: page_requested.emit(page))
		pages[page] = tab
	root.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

func band(root: Control, bottom: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	root.add_child(panel)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", sculpted(IVORY if bottom else PETROL, 35, 20))
	var anchor := float(bottom)
	panel.anchor_right = 1.0
	panel.anchor_top = anchor
	panel.anchor_bottom = anchor
	panel.offset_left = 29
	panel.offset_right = -29
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN if bottom else Control.GROW_DIRECTION_END
	if bottom:
		panel.offset_top = -29
		panel.offset_bottom = -29
	else:
		panel.offset_top = 31
	return panel

func tile(parent: Control, texture: Texture2D, tint: Color) -> VBoxContainer:
	var shell := PanelContainer.new()
	parent.add_child(shell)
	shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.add_theme_stylebox_override("panel", style(tint, tint.darkened(0.19), 19, 7))
	var row := HBoxContainer.new()
	shell.add_child(row)
	row.add_theme_constant_override("separation", 4)
	icon(row, texture, 63)
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

func icon(parent: Control, texture: Texture2D, side: int) -> TextureRect:
	var image := TextureRect.new()
	parent.add_child(image)
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size = Vector2(side, side)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image

func button_art(button: Button, picture: Texture2D, width: int) -> void:
	button.icon = picture
	button.add_theme_constant_override("icon_max_width", width)
	button.add_theme_constant_override("h_separation", 6)

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

func animate_reward(origin: Vector2, direct: bool) -> void:
	if not visible or active_rewards >= 3 or not get_viewport().get_visible_rect().has_point(origin):
		return
	active_rewards += 1
	var reward := icon(overlay, CASH, 79)
	reward.size = Vector2(79, 79)
	reward.position = origin - reward.size * 0.5
	reward.pivot_offset = reward.size * 0.5
	var destination: Control = cash if direct or not income.is_visible_in_tree() else income
	var target := destination.get_global_rect().get_center() - reward.size * 0.5
	var flight := create_tween()
	flight.tween_property(reward, "position:y", reward.position.y - 73, 0.20).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	flight.tween_property(reward, "position", target, 0.46).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	flight.parallel().tween_property(reward, "scale", Vector2(0.54, 0.54), 0.46)
	flight.parallel().tween_property(reward, "modulate:a", 0.1, 0.44)
	flight.tween_callback(func() -> void:
		active_rewards -= 1
		reward.queue_free())

func announce(message: String, picture: Texture2D, animate: bool) -> void:
	if is_instance_valid(notice):
		notice.queue_free()
	notice = PanelContainer.new()
	overlay.add_child(notice)
	var banner := notice
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	banner.offset_left = -305
	banner.offset_right = 305
	banner.offset_top = 225
	banner.add_theme_stylebox_override("panel", sculpted(PETROL, 35, 14))
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 13)
	banner.add_child(row)
	icon(row, picture, 70)
	var label := caption(row, 30, CREAM, HEAVY)
	label.text = message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var reveal := banner.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if animate:
		banner.modulate.a = 0.0
		reveal.tween_property(banner, "modulate:a", 1.0, 0.25)
	reveal.tween_interval(2.10)
	reveal.tween_property(banner, "modulate:a", 0.0, 0.30)
	reveal.tween_callback(banner.queue_free)
