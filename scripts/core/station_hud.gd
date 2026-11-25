extends CanvasLayer

signal serve_requested
signal upgrade_requested
signal lighting_requested
signal view_requested
signal page_requested(page: String)
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
const SETTINGS = preload("res://assets/ui/icon_settings.png")
const CARDS = preload("res://assets/ui/icon_cards.png")
const GIFT = preload("res://assets/ui/icon_gift.png")
const CALENDAR = preload("res://assets/ui/icon_calendar.png")
const HELP = preload("res://assets/ui/icon_help.png")
const NAV := {"sites": UPGRADE_ART, "team": STAFF, "managers": CARDS, "goals": preload("res://assets/ui/icon_goals.png"),
	"shop": GIFT, "finance": preload("res://assets/ui/icon_finance.png"), "settings": SETTINGS, "calendar": CALENDAR,
	"rank": REPUTATION, "achievements": REPUTATION, "help": HELP, "licenses": HELP, "privacy": HELP}
const Touch = preload("res://scripts/ui/touch_button.gd")
const IVORY = preload("res://assets/ui/presentation/shell.png")
const ACTION = preload("res://assets/ui/presentation/jade.png")
const UPGRADE = preload("res://assets/ui/presentation/honey.png")
const PETROL = preload("res://assets/ui/presentation/dock.png")
const CREAM_BUTTON = preload("res://assets/ui/presentation/paper.png")
const LAVENDER = preload("res://assets/ui/presentation/lavender.png")
const INK := Color("#243a43")
const PANEL := Color("#fff9ed")
const RIM := Color("#d2bea1")
const CREAM := Color("#fff8e8")
const GOLD := Color("#956023")
const FADE := Color("#536760")
const MINT := Color("#2b795f")

var location: Label
var title: Label
var cash_caption: Label
var cash: Label
var level: Label
var station: Label
var status: Label
var rate: Label
var serve: Button
var upgrade: Button
var upgrade_preview: Button
var rank: Button
var settings: Button
var badges: Dictionary = {}
var lighting: Button
var view: Button
var progress: ProgressBar
var wallet_stats: Dictionary = {}
var wallet_names: Dictionary = {}
var pages: Dictionary = {}
var income: Button
var shown_cash: HbtAmount
var next_cash: HbtAmount
var cash_locale := ""
var cash_pattern := ""
var counting: Tween
var overlay := Control.new()
var active_rewards := 0
var notice: PanelContainer
var top: PanelContainer
var bottom: PanelContainer
var framing: VBoxContainer
var dock: PanelContainer
var inset := Vector4.ZERO
var reward_layer := CanvasLayer.new()
var upgrade_pulse: Tween
var ready_glow := false
var wallet_motion: Dictionary = {}
var wallet_previous: Dictionary = {}
var wallet_targets: Dictionary = {}
var wallet_languages: Dictionary = {}
var detail_icon: TextureRect

func _ready() -> void:
	var root := Control.new()
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top = band(root, false, PETROL)
	var header := VBoxContainer.new()
	top.add_child(header)
	header.add_theme_constant_override("separation", 6)
	var hero := HBoxContainer.new()
	header.add_child(hero)
	hero.add_theme_constant_override("separation", 10)
	var heading := VBoxContainer.new()
	hero.add_child(heading)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	location = caption(heading, 18, Color("#f0be79"), HEAVY)
	title = caption(heading, 38, CREAM, HEAVY)
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var stats := action(hero, 110, 88, false)
	button_art(stats, NAV.finance, 61)
	stats.pressed.connect(func() -> void: page_requested.emit("finance"))
	pages.finance = stats
	var daily := action(hero, 110, 88, false)
	button_art(daily, CALENDAR, 64)
	daily.pressed.connect(func() -> void: page_requested.emit("calendar"))
	pages.calendar = daily
	add_badge(daily, "calendar")
	settings = action(hero, 110, 88, false)
	button_art(settings, SETTINGS, 66)
	settings.pressed.connect(func() -> void: page_requested.emit("settings"))
	pages.settings = settings

	var counter := FontVariation.new()
	counter.base_font = NUMERALS
	counter.fallbacks = [HEAVY]
	var balances := HBoxContainer.new()
	header.add_child(balances)
	balances.add_theme_constant_override("separation", 7)
	var treasury := tile(balances, CASH, Color("#d6e9d5"))
	cash_caption = caption(treasury, 17, FADE, HEAVY)
	cash = caption(treasury, 32, MINT, counter)
	cash.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	for data in [["diamond", DIAMOND, Color("#e9dff9"), Color("#643c86")],
		["reputation", REPUTATION, Color("#f5e7bf"), Color("#815021")]]:
		var purse := tile(balances, data[1], data[2])
		wallet_names[data[0]] = caption(purse, 16, FADE, HEAVY)
		wallet_stats[data[0]] = caption(purse, 30, data[3], counter)
		wallet_stats[data[0]].text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	rank = action(balances, 176, 86, false)
	rank.add_theme_stylebox_override("normal", sculpted(UPGRADE, 35, 12))
	button_art(rank, REPUTATION, 45)
	rank.pressed.connect(func() -> void: page_requested.emit("rank"))
	pages.rank = rank
	add_badge(rank, "rank")

	framing = VBoxContainer.new()
	root.add_child(framing)
	framing.set_anchor(SIDE_LEFT, 1.0)
	framing.set_anchor(SIDE_RIGHT, 1.0)
	framing.add_theme_constant_override("separation", 6)
	lighting = action(framing, 146, 70, false)
	view = action(framing, 146, 70, false)
	button_art(view, ROAD, 42)
	lighting.pressed.connect(func() -> void: lighting_requested.emit())
	view.pressed.connect(func() -> void: view_requested.emit())

	dock = band(root, true, PETROL)
	var tabs := HBoxContainer.new()
	dock.add_child(tabs)
	tabs.add_theme_constant_override("separation", 5)
	for page in ["sites", "team", "managers", "goals", "shop"]:
		var tab := action(tabs, 0, 130, false)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.add_theme_font_size_override("font_size", 25)
		tab.add_theme_stylebox_override("normal", sculpted(LAVENDER if page == "shop" else CREAM_BUTTON, 38, 11))
		button_art(tab, NAV[page], 69)
		tab.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		tab.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tab.pressed.connect(func() -> void: page_requested.emit(page))
		pages[page] = tab
	add_badge(pages.goals, "goals")

	bottom = band(root, true, IVORY)
	var card := VBoxContainer.new()
	bottom.add_child(card)
	card.add_theme_constant_override("separation", 6)
	var top_row := HBoxContainer.new()
	card.add_child(top_row)
	top_row.add_theme_constant_override("separation", 11)
	detail_icon = icon(top_row, PUMP, 75)
	var detail := VBoxContainer.new()
	top_row.add_child(detail)
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level = caption(detail, 19, GOLD, HEAVY)
	station = caption(detail, 38, INK, HEAVY)
	station.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	upgrade_preview = action(top_row, 172, 92, false)
	upgrade_preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button_art(upgrade_preview, UPGRADE_ART, 51)
	upgrade_preview.pressed.connect(func() -> void: page_requested.emit("upgrades"))

	var details := HBoxContainer.new()
	details.add_theme_constant_override("separation", 9)
	card.add_child(details)
	status = caption(details, 25, FADE, BOLD)
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	rate = caption(details, 23, MINT, counter)
	rate.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	progress = ProgressBar.new()
	card.add_child(progress)
	progress.custom_minimum_size.y = 14
	progress.max_value = 1.0
	progress.step = 0.0
	progress.show_percentage = false
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress.add_theme_stylebox_override("background", style(Color("#cfc0a4"), Color("#af9879"), 8, 0))
	progress.add_theme_stylebox_override("fill", style(Color("#5cad8a"), Color("#2e745a"), 8, 0))
	var actions := HBoxContainer.new()
	card.add_child(actions)
	actions.add_theme_constant_override("separation", 9)
	serve = action(actions, 0, 112, true)
	serve.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_art(serve, PUMP, 65)
	upgrade = action(actions, 0, 112, false)
	upgrade.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_art(upgrade, UPGRADE_ART, 65)
	upgrade.add_theme_stylebox_override("normal", sculpted(UPGRADE, 42, 14))
	upgrade.add_theme_stylebox_override("hover", style(Color("#ffe5a8"), Color("#b48443"), 26, 10))
	upgrade.add_theme_stylebox_override("pressed", style(Color("#ecb35e"), Color("#b48443"), 26, 10))
	serve.pressed.connect(func() -> void: serve_requested.emit())
	upgrade.pressed.connect(func() -> void: upgrade_requested.emit())
	income = action(card, 0, 81, false)
	button_art(income, CASH, 54)
	income.visible = false
	income.pressed.connect(func() -> void: income_requested.emit())
	add_child(reward_layer)
	reward_layer.layer = 7
	reward_layer.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visibility_changed.connect(func() -> void: reward_layer.visible = visible)
	get_viewport().size_changed.connect(layout_safe)
	call_deferred("layout_safe")

func band(root: Control, at_bottom: bool, art: Texture2D) -> PanelContainer:
	var panel := PanelContainer.new()
	root.add_child(panel)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", sculpted(art, 45, 18))
	panel.anchor_right = 1.0
	panel.anchor_top = float(at_bottom)
	panel.anchor_bottom = float(at_bottom)
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN if at_bottom else Control.GROW_DIRECTION_END
	return panel

static func safe_insets(area: Rect2, screen: Vector2, canvas: Vector2) -> Vector4:
	if not area.has_area() or screen.x <= 0 or screen.y <= 0:
		return Vector4.ZERO
	var ratio := canvas / screen
	return Vector4(maxf(0.0, area.position.x) * ratio.x, maxf(0.0, area.position.y) * ratio.y,
		maxf(0.0, screen.x - area.end.x) * ratio.x, maxf(0.0, screen.y - area.end.y) * ratio.y)

func layout_safe() -> void:
	inset = Vector4.ZERO
	var viewport := get_viewport().get_visible_rect().size
	if OS.has_feature("mobile"):
		inset = safe_insets(Rect2(DisplayServer.get_display_safe_area()), Vector2(get_window().size), viewport)
	apply_safe(inset)

func apply_safe(safe: Vector4) -> void:
	inset = safe
	var width := get_viewport().get_visible_rect().size.x
	var gutter := maxf(22.0, (width - 1150.0) * 0.5)
	for frame in [top, bottom, dock]:
		frame.offset_left = gutter + inset.x
		frame.offset_right = -gutter - inset.z
	top.offset_top = 15.0 + inset.y
	dock.offset_bottom = -12.0 - inset.w
	bottom.offset_bottom = -174.0 - inset.w
	framing.offset_left = -171.0 - inset.z
	framing.offset_right = -19.0 - inset.z
	framing.offset_top = 239.0 + inset.y
	framing.offset_bottom = 239.0 + inset.y

func add_badge(button: Button, key: String) -> void:
	var pin := Panel.new()
	button.add_child(pin)
	pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pin.add_theme_stylebox_override("panel", style(Color("#f6bf69"), Color("#723729"), 18, 0))
	pin.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	pin.offset_left = -31
	pin.offset_right = -9
	pin.offset_top = 9
	pin.offset_bottom = 31
	pin.hide()
	badges[key] = pin

func set_upgrade_ready(enabled: bool, motion: bool) -> void:
	var glow := enabled and motion
	if ready_glow == glow:
		return
	ready_glow = glow
	if upgrade_pulse != null:
		upgrade_pulse.kill()
	upgrade.modulate = Color.WHITE
	if glow:
		upgrade_pulse = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
		upgrade_pulse.tween_property(upgrade, "modulate", Color(1.15, 1.10, 0.99), 0.67)
		upgrade_pulse.tween_property(upgrade, "modulate", Color.WHITE, 0.67)

func tile(parent: Control, texture: Texture2D, tint: Color) -> VBoxContainer:
	var shell := PanelContainer.new()
	parent.add_child(shell)
	shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.add_theme_stylebox_override("panel", style(tint, tint.darkened(0.19), 19, 7))
	var row := HBoxContainer.new()
	shell.add_child(row)
	row.add_theme_constant_override("separation", 4)
	icon(row, texture, 64)
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
	var button := Touch.new()
	parent.add_child(button)
	button.custom_minimum_size = Vector2(width, height)
	button.add_theme_font_override("font", HEAVY)
	button.add_theme_font_size_override("font_size", 28 if height > 82 else 24)
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
		button.add_theme_stylebox_override("normal", sculpted(ACTION, 42, 13))
	else:
		button.add_theme_stylebox_override("normal", sculpted(CREAM_BUTTON, 42, 13))
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
	if fill.a >= 0.96 and radius >= 17:
		box.shadow_size = 4
		box.shadow_offset = Vector2(0, 3)
		box.shadow_color = Color(0.12, 0.18, 0.21, 0.16)
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

func update_balance(key: String, value: HbtAmount, locale: String, motion: bool) -> void:
	var label: Label = wallet_stats[key]
	var before: HbtAmount = wallet_previous.get(key)
	var target: HbtAmount = wallet_targets.get(key)
	var language_changed: bool = wallet_languages.get(key, "") != locale
	if target != null and target.compare(value) == 0 and not language_changed and motion:
		return
	if wallet_motion.has(key):
		wallet_motion[key].kill()
	wallet_targets[key] = value
	wallet_languages[key] = locale
	if before == null or not motion or language_changed or before.compare(value) == 0:
		wallet_previous[key] = value
		label.text = value.compact(locale)
		return
	var upward := value.compare(before) > 0
	var distance := value.minus(before) if upward else before.minus(value)
	var count := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	wallet_motion[key] = count
	count.tween_method(func(tick: int) -> void:
		var moved := distance.times(tick).divided(100)
		var shown := before.plus(moved) if upward else before.minus(moved)
		wallet_previous[key] = shown
		label.text = shown.compact(locale), 0, 100, 0.27)

func animate_reward(origin: Vector2, direct: bool, currency := "cash") -> void:
	if not visible or active_rewards >= 3 or not get_viewport().get_visible_rect().has_point(origin):
		return
	active_rewards += 1
	var reward := icon(overlay, DIAMOND if currency == "diamond" else CASH, 79)
	reward.size = Vector2(79, 79)
	reward.position = origin - reward.size * 0.5
	reward.pivot_offset = reward.size * 0.5
	var destination: Control = wallet_stats.diamond if currency == "diamond" else cash if direct or not income.is_visible_in_tree() else income
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
	banner.offset_top = 236 + inset.y
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

func blocks_world(point: Vector2) -> bool:
	if not visible:
		return false
	for frame in [top, bottom, dock, framing]:
		if frame.get_global_rect().has_point(point):
			return true
	return false

func overlaps_world(bounds: Rect2) -> bool:
	if not visible:
		return false
	for frame in [top, bottom, dock, framing]:
		if frame.get_global_rect().intersects(bounds):
			return true
	return false
