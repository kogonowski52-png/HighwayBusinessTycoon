extends Node3D

signal state_changed
signal completed

enum State { ARRIVING, WAITING, SERVING, LEAVING, GAP }

const Vehicle = preload("res://scenes/vehicles/compact.tscn")
const COLORS := [Color("#e39c54"), Color("#4c8f96"), Color("#b95542"), Color("#e3cd9b")]
const ENTRY := [Vector3(27, 0, 8.8), Vector3(10, 0, 8.8), Vector3(7, 0, 7.6),
	Vector3(5.8, 0, 4.1), Vector3(3.8, 0, 2.55), Vector3(0.8, 0, 2.55)]
const EXIT := [Vector3(-4.4, 0, 2.55), Vector3(-7.8, 0, 3.8),
	Vector3(-9.5, 0, 7.3), Vector3(-12, 0, 8.8), Vector3(-27, 0, 8.8)]

var state := State.GAP
var active: Node3D
var background: Array[Node3D] = []
var route: Array[Vector3] = []
var waypoint := 0
var time_left := 0.0
var duration := 1.0
var visits := 0

func _ready() -> void:
	for i in range(4):
		var car := Vehicle.instantiate()
		add_child(car)
		car.build(COLORS[(i + 2) % COLORS.size()], i % 2 == 0)
		car.position = Vector3(-23.0 + i * 13.0, 0, 12.2)
		car.rotation.y = PI / 2
		background.append(car)
	# The first customer starts at the pump so a new player can act immediately.
	new_customer()
	active.position = ENTRY.back()
	transition(State.WAITING)

func transition(next: State) -> void:
	state = next
	state_changed.emit()

func new_customer() -> void:
	active = Vehicle.instantiate()
	add_child(active)
	active.build(COLORS[visits % COLORS.size()], visits % 2 == 1)
	visits += 1
	active.position = ENTRY[0]
	active.rotation.y = -PI / 2
	route.assign(ENTRY.slice(1))
	waypoint = 0
	transition(State.ARRIVING)

func start_service(seconds: float) -> bool:
	if state != State.WAITING:
		return false
	duration = seconds
	time_left = seconds
	transition(State.SERVING)
	return true

func progress() -> float:
	return 1.0 - time_left / duration if state == State.SERVING else 0.0

func _process(delta: float) -> void:
	for i in range(background.size()):
		var car := background[i]
		var distance := (6.4 + i * 0.27) * delta
		car.position.x = wrapf(car.position.x + distance, -28.0, 28.0)
		car.spin(distance)
	match state:
		State.ARRIVING, State.LEAVING:
			travel(delta)
		State.SERVING:
			time_left -= delta
			if time_left <= 0.0:
				route.assign(EXIT)
				waypoint = 0
				transition(State.LEAVING)
				completed.emit()
		State.GAP:
			time_left -= delta
			if time_left <= 0.0:
				new_customer()

func travel(delta: float) -> void:
	var target := route[waypoint]
	var direction := target - active.position
	var step := delta * (7.8 if absf(active.position.x) > 10.0 else 4.8)
	if direction.length() > 0.001:
		active.rotation.y = lerp_angle(active.rotation.y, atan2(direction.x, direction.z), minf(1.0, delta * 9.0))
	active.position = active.position.move_toward(target, step)
	active.spin(minf(step, direction.length()))
	if active.position.distance_squared_to(target) > 0.0001:
		return
	waypoint += 1
	if waypoint < route.size():
		return
	if state == State.ARRIVING:
		active.rotation.y = -PI / 2.0
		transition(State.WAITING)
	else:
		active.queue_free()
		time_left = 0.35
		transition(State.GAP)
