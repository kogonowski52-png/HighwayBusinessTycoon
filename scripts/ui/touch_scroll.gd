extends ScrollContainer
## Own a finger from the first press to release, including across child controls.

signal interaction_finished

const SLOP := 17.0
const FRICTION := 8.5
const STOP_SPEED := 22.0
const MAX_SPEED := 4200.0

enum Gesture { TAP, SCROLL, SLIDER }

var listening := false
var touch_area: Control
var finger := -1
var gesture := Gesture.TAP
var start := Vector2.ZERO
var previous := Vector2.ZERO
var scroll_position := 0.0
var speed := 0.0
var last_motion := 0
var slider: HSlider
var stop_only := false
var pending_tap := false
var owns_emulated_mouse := false
var dispatching_mouse := false

func _ready() -> void:
	set_process(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		cancel_interaction()
		owns_emulated_mouse = false
		interaction_finished.emit()

func interacting() -> bool:
	return finger != -1 or pending_tap or absf(speed) >= STOP_SPEED

func cancel_interaction() -> void:
	if finger != -1 and gesture == Gesture.SLIDER:
		send_mouse(previous, false)
	finger = -1
	slider = null
	pending_tap = false
	speed = 0.0
	set_process(false)

func within(point: Vector2) -> bool:
	var area := touch_area if is_instance_valid(touch_area) else self
	var local := area.get_global_transform_with_canvas().affine_inverse() * point
	return Rect2(Vector2.ZERO, area.size).has_point(local)

func _input(event: InputEvent) -> void:
	if dispatching_mouse:
		return
	var viewport := get_viewport()
	if event is InputEventMouseButton and event.device == InputEvent.DEVICE_ID_EMULATION and event.button_index == MOUSE_BUTTON_LEFT:
		# Some platforms send the emulated press even before the corresponding ScreenTouch.
		if event.pressed:
			owns_emulated_mouse = listening and within(event.position)
		if owns_emulated_mouse:
			owns_emulated_mouse = event.pressed
			viewport.set_input_as_handled()
		return
	if event is InputEventMouseMotion and event.device == InputEvent.DEVICE_ID_EMULATION and owns_emulated_mouse:
		viewport.set_input_as_handled()
		return
	if not listening or not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		if event.pressed and finger == -1 and within(event.position):
			begin(event)
			viewport.set_input_as_handled()
		elif finger != -1:
			if event.index == finger and not event.pressed:
				end(event)
			viewport.set_input_as_handled()
	elif event is InputEventScreenDrag and finger == event.index:
		update_drag(event)
		viewport.set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and finger == -1 and absf(speed) >= STOP_SPEED and within(event.position):
		stop_scroll()

func begin(event: InputEventScreenTouch) -> void:
	stop_only = absf(speed) >= STOP_SPEED
	speed = 0.0
	set_process(false)
	finger = event.index
	start = event.position
	previous = start
	gesture = Gesture.TAP
	scroll_position = get_v_scroll_bar().value
	last_motion = Time.get_ticks_usec()
	slider = null
	for control: HSlider in find_children("*", "HSlider", true, false):
		if control.is_visible_in_tree() and control.editable and control.get_global_rect().has_point(start):
			slider = control
			break

func update_drag(event: InputEventScreenDrag) -> void:
	var displacement := event.position - start
	var delta_y := previous.y - event.position.y
	if gesture == Gesture.TAP:
		if displacement.length_squared() < SLOP * SLOP:
			return
		if is_instance_valid(slider) and absf(displacement.x) > absf(displacement.y) * 1.25:
			gesture = Gesture.SLIDER
			send_mouse(start, true)
		else:
			gesture = Gesture.SCROLL
			# Remove the small amount it took to recognize this as a drag.
			delta_y = -signf(displacement.y) * maxf(0.0, absf(displacement.y) - SLOP)
	if gesture == Gesture.SLIDER:
		send_motion(event.position)
	else:
		var scale_y := get_global_transform_with_canvas().y.length()
		var traveled := move_scroll(delta_y / maxf(0.1, scale_y))
		var now := Time.get_ticks_usec()
		var elapsed := clampf((now - last_motion) / 1000000.0, .012, .085)
		speed = clampf(lerpf(speed, traveled / elapsed, .65), -MAX_SPEED, MAX_SPEED) if absf(traveled) > .05 else 0.0
		last_motion = now
	previous = event.position

func end(event: InputEventScreenTouch) -> void:
	finger = -1
	if gesture == Gesture.SLIDER:
		send_mouse(event.position, false)
	elif not event.canceled and gesture == Gesture.TAP and not stop_only 			and start.distance_squared_to(event.position) < SLOP * SLOP and within(event.position):
		pending_tap = true
		replay_tap.call_deferred(start)
		return
	elif not event.canceled and gesture == Gesture.SCROLL and Time.get_ticks_usec() - last_motion < 115_000 			and absf(speed) >= STOP_SPEED:
		set_process(true)
		return
	stop_scroll()

func replay_tap(point: Vector2) -> void:
	if not pending_tap:
		return
	pending_tap = false
	if listening:
		send_mouse(point, true)
		send_mouse(point, false)
	interaction_finished.emit()

func send_mouse(point: Vector2, pressed: bool) -> void:
	var mouse := InputEventMouseButton.new()
	mouse.position = point
	mouse.global_position = point
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	mouse.pressed = pressed
	dispatch_mouse(mouse)

func send_motion(point: Vector2) -> void:
	var mouse := InputEventMouseMotion.new()
	mouse.position = point
	mouse.global_position = point
	mouse.relative = point - previous
	mouse.button_mask = MOUSE_BUTTON_MASK_LEFT
	dispatch_mouse(mouse)

func dispatch_mouse(event: InputEventMouse) -> void:
	dispatching_mouse = true
	get_viewport().push_input(event, true)
	dispatching_mouse = false

func move_scroll(delta: float) -> float:
	var rail := get_v_scroll_bar()
	var before := scroll_position
	scroll_position = clampf(before + delta, 0.0, maxf(0.0, rail.max_value - rail.page))
	rail.value = scroll_position
	return scroll_position - before

func _process(delta: float) -> void:
	var decay := exp(-FRICTION * delta)
	var traveled := move_scroll(speed * (1.0 - decay) / FRICTION)
	speed *= decay
	if absf(speed) < STOP_SPEED or absf(traveled) < .01:
		stop_scroll()

func stop_scroll() -> void:
	speed = 0.0
	set_process(false)
	interaction_finished.emit()
