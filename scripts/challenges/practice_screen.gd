extends CanvasLayer

const Rules = preload("res://scripts/challenges/service_practice.gd")
const Stage = preload("res://scripts/challenges/practice_art.gd")
const Mat = preload("res://scripts/challenges/practice_board.gd")

var game: Node3D
var hud: CanvasLayer
var session := Rules.new()
var base: Control
var illustration: Stage
var board: Mat
var status: Label
var clock: Label
var caption: Label
var meter: ProgressBar
var action: Button
var start_button: Button
var back: Button
var callback := Callable()
var finger := -1
var mouse := false
var prior := Vector2.ZERO
var rendered := true
var earned := HbtAmount.new()

func open(owner: Node3D, mode: String, id: String, exit: Callable) -> void:
	game = owner
	hud = owner.hud
	callback = exit
	layer = 14
	session.begin(mode, id)
	rendered = DisplayServer.get_name() != "headless"
	base = ColorRect.new()
	(base as ColorRect).color = Color("#142e36e8")
	add_child(base)
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var body := CenterContainer.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.add_child(body)
	var card := PanelContainer.new()
	body.add_child(card)
	card.add_theme_stylebox_override("panel", hud.sculpted(hud.IVORY, 49, 28))
	var stack := VBoxContainer.new()
	card.add_child(stack)
	stack.add_theme_constant_override("separation", 12)
	var hero := PanelContainer.new()
	stack.add_child(hero)
	hero.add_theme_stylebox_override("panel", hud.sculpted(hud.PETROL, 44, 18))
	var hero_stack := VBoxContainer.new()
	hero.add_child(hero_stack)
	var headline := HBoxContainer.new()
	hero_stack.add_child(headline)
	hud.icon(headline, hud.PUMP if mode == "fuel" else hud.NAV.sites, 86)
	var name: Label = hud.caption(headline, 41, hud.CREAM, hud.HEAVY)
	name.text = game.t("practice_" + mode)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	back = button(headline, game.t("close"), dismiss, false, 132)
	caption = hud.caption(hero_stack, 24, Color("#eccea1"), hud.BOLD)
	caption.text = game.t("practice_" + mode + "_rules")
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	clock = hud.caption(stack, 26, hud.INK, hud.HEAVY)
	clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meter = ProgressBar.new()
	stack.add_child(meter)
	meter.show_percentage = false
	meter.max_value = session.last()
	meter.value = session.last()
	meter.add_theme_stylebox_override("background", hud.style(Color("#d6c6a2"), hud.RIM, 9, 0))
	meter.add_theme_stylebox_override("fill", hud.style(Color("#478b81"), Color("#407263"), 9, 0))
	meter.custom_minimum_size.y = 20
	var demo := PanelContainer.new()
	stack.add_child(demo)
	demo.add_theme_stylebox_override("panel", hud.style(Color("#274c52"), Color("#8c8270"), 17, 11))
	if rendered:
		illustration = Stage.new()
		demo.add_child(illustration)
		illustration.build(mode)
	else:
		demo.custom_minimum_size.y = 266
	board = Mat.new()
	board.session = session
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if mode == "wash":
		demo.add_child(board)
	else:
		stack.add_child(board)
		board.custom_minimum_size.y = 430 if mode == "cargo" else 119
	status = hud.caption(stack, 28, hud.INK, hud.HEAVY)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var controls := HBoxContainer.new()
	stack.add_child(controls)
	controls.add_theme_constant_override("separation", 10)
	start_button = button(controls, game.t("practice_start"), begin, true)
	start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if mode in ["fuel", "cargo"]:
		action = button(controls, game.t("practice_stop" if mode == "fuel" else "practice_rotate"), operate, false)
		action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action.hide()
	adapt(card, demo)
	get_viewport().size_changed.connect(adapt.bind(card, demo))
	refresh()

func adapt(card: PanelContainer, demo: PanelContainer) -> void:
	var screen := get_viewport().get_visible_rect().size
	card.custom_minimum_size.x = minf(952, screen.x - 54)
	if illustration != null:
		illustration.custom_minimum_size.y = (415 if session.practice == "wash" else 260) if screen.y > 1470 else 260
	if session.practice == "cargo":
		board.custom_minimum_size.y = minf(430, screen.y * .29)
	demo.update_minimum_size()

func button(parent: Control, label: String, call: Callable, main: bool, width := 0) -> Button:
	var control: Button = hud.action(parent, width, 93, main)
	control.text = label
	control.pressed.connect(call)
	return control

func begin() -> void:
	if session.done:
		dismiss()
		return
	session.started = true
	start_button.hide()
	if action != null:
		action.show()
	game.feedback.play("click")
	refresh()

func operate() -> void:
	if session.practice == "fuel":
		if session.mark_pressure():
			game.feedback.play("sale", true)
			board.queue_redraw()
	elif session.started and not session.done:
		session.rotation = (session.rotation + 1) % 4
		game.feedback.play("click")
		board.queue_redraw()
	if session.complete():
		finish()
	refresh()

func _process(delta: float) -> void:
	if game.suspended_at >= 0 or not session.started or session.done:
		return
	session.advance(delta)
	board.wave = maxf(0.0, board.wave - delta * 3.85)
	if session.complete():
		finish()
	refresh()
	board.queue_redraw()

func refresh() -> void:
	if session.done:
		status.text = game.t("practice_result") % [session.score(), game.money(earned)]
		clock.text = game.t("practice_complete")
		return
	var current := session.elapsed
	clock.text = game.t("practice_clock") % [ceili(session.last() - current), session.score()]
	meter.value = session.last() - current
	match session.practice:
		"fuel": status.text = game.t("practice_round") % [mini(4, session.attempts.size() + 1), 4]
		"wash": status.text = game.t("practice_clean") % session.score()
		"cargo": status.text = game.t("practice_load") % [session.piece_count(), session.LOAD.size()]
	if action != null:
		action.disabled = not session.fuel_ready() if session.practice == "fuel" else session.piece().is_empty()

func finish() -> void:
	if session.done:
		return
	earned = session.award(game.economy)
	if action != null:
		action.hide()
	start_button.text = game.t("practice_collect")
	start_button.show()
	if not earned.empty():
		game.reward_feedback("reward")
	refresh()

func dismiss() -> void:
	var saved := callback
	hide()
	queue_free()
	if saved.is_valid():
		saved.call()

func _input(event: InputEvent) -> void:
	if not session.started or session.done or session.practice == "fuel":
		return
	var active := board.get_global_rect()
	if event is InputEventScreenTouch:
		pointer_change(event.index, event.pressed, event.position, event.canceled, active)
	elif event is InputEventScreenDrag and event.index == finger:
		pointer_move(event.position, active)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION:
		mouse = event.pressed
		pointer_change(99, event.pressed, event.position, false, active)
	elif event is InputEventMouseMotion and mouse and finger == 99:
		pointer_move(event.position, active)

func pointer_change(index: int, down: bool, at: Vector2, canceled: bool, area: Rect2) -> void:
	if down:
		if finger != -1 or not area.has_point(at):
			return
		finger = index
		prior = at
		pointer_move(at, area)
	elif index == finger:
		finger = -1
		if not canceled and area.has_point(at) and session.practice == "cargo" and session.pack(board.slot(at - area.position)):
			game.feedback.play("build")
		get_viewport().set_input_as_handled()

func pointer_move(at: Vector2, area: Rect2) -> void:
	get_viewport().set_input_as_handled()
	if session.practice == "cargo":
		board.preview = board.slot(at - area.position)
		board.queue_redraw()
		return
	if not area.has_point(at):
		prior = at
		return
	var length := at.distance_to(prior)
	var passes := clampi(ceili(length / 27.0), 1, 14)
	for part in range(1, passes + 1):
		var point := prior.lerp(at, float(part) / passes)
		var unit := illustration.stain_coords(point) if illustration != null else (point - area.position) / area.size
		session.scrub(unit, .49 if length > 1.0 else .07)
	prior = at
	if illustration != null:
		illustration.apply_dirty(session.dirty)
	board.splash = at - area.position
	board.wave = 1.0
	board.queue_redraw()
