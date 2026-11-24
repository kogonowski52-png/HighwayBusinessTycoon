extends CanvasLayer

signal serve_requested
signal upgrade_requested
signal language_requested
signal power_requested
signal lighting_requested
signal view_requested

const REGULAR = preload("res://assets/fonts/OpenSans-Regular.ttf")
const BOLD = preload("res://assets/fonts/OpenSans-Bold.ttf")
const HEAVY = preload("res://assets/fonts/OpenSans-ExtraBold.ttf")
const PUMP = preload("res://assets/icons/pump.svg")
const ROAD = preload("res://assets/icons/road.svg")
const BARS = preload("res://assets/icons/bars.svg")
const INK := Color("#152d33")
const PANEL := Color("#1c373c")
const RIM := Color("#48605a")
const CREAM := Color("#fff1cf")
const GOLD := Color("#ffd894")
const FADE := Color("#b9cec0")
const MINT := Color("#a7d0ac")

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

func _ready() -> void:
	var root := Control.new()
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var top := band(root, false)
	var header := VBoxContainer.new()
	top.add_child(header)
	header.add_theme_constant_override("separation", 20)
	var hero := HBoxContainer.new()
	header.add_child(hero)
	hero.add_theme_constant_override("separation", 16)
	var heading := VBoxContainer.new()
	hero.add_child(heading)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	location = caption(heading, 25, GOLD)
	title = caption(heading, 57, CREAM, HEAVY)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var settings := HBoxContainer.new()
	hero.add_child(settings)
	settings.alignment = BoxContainer.ALIGNMENT_END
	settings.add_theme_constant_override("separation", 10)
	language = action(settings, 90, 76, false)
	power = action(settings, 112, 76, false)
	language.pressed.connect(func() -> void: language_requested.emit())
	power.pressed.connect(func() -> void: power_requested.emit())

	var stats := HBoxContainer.new()
	header.add_child(stats)
	stats.add_theme_constant_override("separation", 12)
	var highway := tile(stats, ROAD)
	traffic_caption = caption(highway, 20, FADE)
	caption(highway, 35, GOLD, HEAVY).text = "R17"
	var visits := tile(stats, BARS)
	people_caption = caption(visits, 20, FADE)
	people = caption(visits, 35, CREAM, HEAVY)
	var treasury := tile(stats, null)
	cash_caption = caption(treasury, 20, FADE)
	cash = caption(treasury, 35, CREAM, HEAVY)

	var framing := VBoxContainer.new()
	root.add_child(framing)
	framing.set_anchor(SIDE_LEFT, 1.0)
	framing.set_anchor(SIDE_RIGHT, 1.0)
	framing.set_anchor(SIDE_TOP, 0.214)
	framing.set_anchor(SIDE_BOTTOM, 0.214)
	framing.offset_left = -215.0
	framing.offset_right = -38.0
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
	card.add_theme_constant_override("separation", 16)
	var top_row := HBoxContainer.new()
	card.add_child(top_row)
	top_row.add_theme_constant_override("separation", 20)
	icon(top_row, PUMP, 78)
	var station_info := VBoxContainer.new()
	top_row.add_child(station_info)
	station_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level = caption(station_info, 23, GOLD)
	station = caption(station_info, 39, CREAM, HEAVY)
	station.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rate = caption(top_row, 24, MINT)
	rate.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status = caption(card, 29, FADE, REGULAR)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	progress = ProgressBar.new()
	card.add_child(progress)
	progress.custom_minimum_size.y = 11
	progress.max_value = 1.0
	progress.step = 0.0
	progress.show_percentage = false
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress.add_theme_stylebox_override("background", style(PANEL, RIM, 7, 0))
	progress.add_theme_stylebox_override("fill", style(MINT, MINT, 7, 0))
	var actions := HBoxContainer.new()
	card.add_child(actions)
	actions.add_theme_constant_override("separation", 14)
	serve = action(actions, 0, 102, true)
	serve.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrade = action(actions, 292, 102, false)
	serve.pressed.connect(func() -> void: serve_requested.emit())
	upgrade.pressed.connect(func() -> void: upgrade_requested.emit())

func band(root: Control, bottom: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	root.add_child(panel)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var surface := style(INK, RIM, 31, 26)
	surface.shadow_size = 13
	surface.shadow_offset = Vector2(0, 5)
	surface.shadow_color = Color("#1e30296c")
	panel.add_theme_stylebox_override("panel", surface)
	var anchor := float(bottom)
	panel.anchor_right = 1.0
	panel.anchor_top = anchor
	panel.anchor_bottom = anchor
	panel.offset_left = 38
	panel.offset_right = -38
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN if bottom else Control.GROW_DIRECTION_END
	if bottom:
		panel.offset_top = -48
		panel.offset_bottom = -48
	else:
		panel.offset_top = 48
	return panel

func tile(parent: Control, texture: Texture2D) -> VBoxContainer:
	var shell := PanelContainer.new()
	parent.add_child(shell)
	shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.add_theme_stylebox_override("panel", style(PANEL, RIM, 19, 13))
	var row := HBoxContainer.new()
	shell.add_child(row)
	row.add_theme_constant_override("separation", 8)
	if texture:
		icon(row, texture, 47)
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
	var normal := GOLD if primary else PANEL
	var text := INK if primary else CREAM
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var fill := normal
		match state:
			"hover": fill = normal.lightened(0.12)
			"pressed": fill = normal.darkened(0.12)
			"focus": fill = Color.TRANSPARENT
			"disabled": fill = Color("#294348")
		button.add_theme_stylebox_override(state, style(fill, GOLD if state == "focus" else RIM, 18, 10))
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(key, text)
	button.add_theme_color_override("font_disabled_color", Color("#a1b5ad"))
	return button

func style(fill: Color, border: Color, radius: int, padding: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(radius)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		box.set_content_margin(side, padding)
	return box
