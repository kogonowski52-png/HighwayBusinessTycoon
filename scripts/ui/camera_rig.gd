extends Node

const LIMIT_MIN := Vector2(-45.0, -25.0)
const LIMIT_MAX := Vector2(52.0, 18.0)
const MIN_WIDTH := 11.5
const MAX_WIDTH := 142.0
const TAP_DISTANCE := 17.0

var controller: Node3D
var limits_min := LIMIT_MIN
var limits_max := LIMIT_MAX
var lens: Camera3D
var focus := Vector3.ZERO
var heading := Vector3(15.3, 34.7, 31.5)
var width := 22.6
var target := Vector3.ZERO
var angle := heading
var zoom := width
var momentum := Vector3.ZERO
var pointers: Dictionary = {}
var touch_origin := Vector2.ZERO
var touch_moved := false
var mouse_drag := false
var mouse_origin := Vector2.ZERO
var mouse_moved := false
var mouse_button := MOUSE_BUTTON_LEFT
var drift_age := 1.0
var film: Dictionary = {}
var cut: Tween

func bind_to(game: Node3D, camera: Camera3D) -> void:
	controller = game
	lens = camera
	if game.economy.Regions.FRONTIERS.has(game.economy.district):
		for id: String in game.routes.layout.plots:
			var at: Vector3 = game.routes.origin(id)
			limits_min.x = minf(limits_min.x, at.x - 9.0)
			limits_min.y = minf(limits_min.y, at.z - 9.0)
			limits_max.x = maxf(limits_max.x, at.x + 9.0)
			limits_max.y = maxf(limits_max.y, at.z + 9.0)

func frame(center: Vector3, offset: Vector3, size: float, immediate: bool) -> void:
	cancel_film(false)
	release_gestures()
	target = center
	angle = offset
	zoom = size
	if immediate:
		focus = target
		heading = angle
		width = zoom
		apply()

func apply() -> void:
	lens.position = focus + heading
	lens.look_at(focus)
	lens.size = maxf(0.1, width)

func _process(delta: float) -> void:
	if lens == null:
		return
	drift_age += delta
	if controller.operations.visible:
		release_gestures()
	elif not mouse_drag and pointers.is_empty() and momentum.length_squared() > 0.008:
		target += momentum * delta
		clamp_target()
		momentum *= exp(-7.6 * delta)
	var settle := 1.0 - exp(-12.0 * delta)
	if focus.distance_squared_to(target) < 0.000001 and heading.distance_squared_to(angle) < 0.000001 \
		and absf(width - zoom) < 0.001:
		return
	focus = focus.lerp(target, settle)
	heading = heading.lerp(angle, settle)
	width = lerpf(width, zoom, settle)
	apply()

func start_film(construction: Vector3, finished: Callable) -> void:
	if not controller.motion_enabled():
		finished.call()
		return
	if cut != null and cut.is_running():
		cut.kill()
	if film.is_empty():
		film = {"center": target, "offset": angle, "zoom": zoom}
	release_gestures()
	target = construction + Vector3(-0.35, 0.82, -0.45)
	zoom = clampf(zoom * 0.71, MIN_WIDTH, 24.0)
	cut = create_tween()
	cut.tween_interval(0.43)
	cut.tween_callback(finished)
	cut.tween_interval(0.51)
	cut.tween_callback(func() -> void: cancel_film(true))

func cancel_film(restore: bool) -> void:
	if film.is_empty():
		return
	if cut != null:
		cut.kill()
	if restore:
		target = film.center
		angle = film.offset
		zoom = film.zoom
	film.clear()

func release_gestures() -> void:
	pointers.clear()
	mouse_drag = false
	momentum = Vector3.ZERO

func clamp_target() -> void:
	target.x = clampf(target.x, limits_min.x, limits_max.x)
	target.z = clampf(target.z, limits_min.y, limits_max.y)

func screen_vector(pixels: Vector2) -> Vector3:
	var factor := zoom / get_viewport().get_visible_rect().size.x
	var across := Vector3(lens.basis.x.x, 0.0, lens.basis.x.z).normalized()
	var after := Vector3(lens.basis.z.x, 0.0, lens.basis.z.z).normalized()
	return (across * pixels.x + after * pixels.y * 1.09) * factor

func drag(delta: Vector2) -> void:
	var movement := -screen_vector(delta)
	target += movement
	clamp_target()
	var recent := clampf(drift_age, .012, .10)
	momentum = (movement / recent).limit_length(48.0)
	drift_age = 0.0

func zoom_at(multiplier: float, position: Vector2) -> void:
	var new_width := clampf(zoom * multiplier, MIN_WIDTH, MAX_WIDTH)
	var offset := position - get_viewport().get_visible_rect().get_center()
	target += screen_vector(offset) * (1.0 - new_width / zoom)
	zoom = new_width
	momentum = Vector3.ZERO
	clamp_target()

# Release over a menu must clear the pointer as well.
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and not event.pressed and pointers.has(event.index):
		var tap: bool = not event.canceled and pointers.size() == 1 and not touch_moved \
			and touch_origin.distance_to(event.position) < TAP_DISTANCE
		pointers.erase(event.index)
		if not pointers.is_empty():
			momentum = Vector3.ZERO
		if tap:
			tap_venue(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION \
			and mouse_drag and not event.pressed and event.button_index == mouse_button:
		mouse_drag = false
		if mouse_button == MOUSE_BUTTON_LEFT and not mouse_moved and mouse_origin.distance_to(event.position) < TAP_DISTANCE:
			tap_venue(event.position)

func tap_venue(point: Vector2) -> void:
	if not controller.operations.visible and not controller.hud.blocks_world(point):
		controller.site_buttons.tap_world(point)

func begin_gesture() -> void:
	if not film.is_empty():
		cancel_film(false)
	momentum = Vector3.ZERO
	drift_age = 0.06

func _unhandled_input(event: InputEvent) -> void:
	if controller == null or controller.operations.visible or not controller.mounted:
		return
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if event is InputEventScreenTouch and event.pressed and not controller.hud.blocks_world(event.position):
		begin_gesture()
		if pointers.is_empty():
			touch_origin = event.position
		touch_moved = not pointers.is_empty()
		pointers[event.index] = event.position
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and pointers.has(event.index):
		if pointers.size() >= 2:
			var other: Vector2
			for index in pointers:
				if index != event.index:
					other = pointers[index]
					break
			var before: Vector2 = pointers[event.index]
			var old_gap := before.distance_to(other)
			var new_gap: float = event.position.distance_to(other)
			if minf(old_gap, new_gap) > 10.0:
				zoom_at(clampf(old_gap / new_gap, 0.81, 1.24), (other + event.position) * 0.5)
		else:
			var delta: Vector2 = event.position - pointers[event.index]
			if not touch_moved:
				delta = event.position - touch_origin
				touch_moved = delta.length() >= TAP_DISTANCE
				if touch_moved:
					delta -= delta.normalized() * TAP_DISTANCE
			if touch_moved:
				drag(delta)
		pointers[event.index] = event.position
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and pointers.is_empty():
		if controller.hud.blocks_world(event.position):
			return
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			begin_gesture()
			zoom_at(0.86 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.16, event.position)
			get_viewport().set_input_as_handled()
		elif event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE]:
			begin_gesture()
			mouse_button = event.button_index
			mouse_origin = event.position
			mouse_moved = false
			mouse_drag = true
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and mouse_drag and pointers.is_empty():
		var delta: Vector2 = event.relative
		if not mouse_moved:
			delta = event.position - mouse_origin
			mouse_moved = delta.length() >= TAP_DISTANCE
			if mouse_moved:
				delta -= delta.normalized() * TAP_DISTANCE
		if mouse_moved:
			drag(delta)
		get_viewport().set_input_as_handled()
