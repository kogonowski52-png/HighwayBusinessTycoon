extends Node3D

signal state_changed
signal completed

enum State { ARRIVING, WAITING, SERVING, LEAVING, GAP }

const Vehicle = preload("res://scenes/vehicles/compact.tscn")
const Catalog = preload("res://scripts/traffic/vehicle_catalog.gd")
const STREET := ["regency", "cargo", "trail", "horizon", "pulse", "mesa", "parcel", "vela", "atlas",
	"crest", "summit", "coast", "loop", "range", "orion", "post", "sprint", "pine", "meridian", "kestrel"]
const ENTRY := [Vector3(27, 0, 8.8), Vector3(10, 0, 8.8), Vector3(8.4, 0, 8.35),
	Vector3(7.15, 0, 7.5), Vector3(5.84, 0, 4.22), Vector3(4.9, 0, 3.22),
	Vector3(3.48, 0, 2.63), Vector3(0.8, 0, 2.55)]
const EXIT := [Vector3(-4.4, 0, 2.55), Vector3(-6.98, 0, 2.97), Vector3(-8.43, 0, 4.23),
	Vector3(-9.50, 0, 7.3), Vector3(-10.77, 0, 8.45), Vector3(-12.3, 0, 8.8), Vector3(-27, 0, 8.8)]

var state := State.GAP
var active: Node3D
var background: Array[Node3D] = []
var route: Array[Vector3] = []
var waypoint := 0
var time_left := 0.0
var duration := 1.0
var visits := 0
var passing := 0
var night := false

func _ready() -> void:
	for i in range(4):
		var car := Vehicle.instantiate()
		add_child(car)
		car.build(STREET[passing])
		passing += 1
		car.position = Vector3(-23.0 + i * 14.0, 0, 12.17)
		car.rotation.y = PI / 2
		background.append(car)
	# A driver at the pump makes the first interaction immediately available.
	new_customer()
	active.position = ENTRY.back()
	active.update_signals(true, 0, 0)
	transition(State.WAITING)

func transition(next: State) -> void:
	state = next
	state_changed.emit()

func new_customer() -> void:
	active = Vehicle.instantiate()
	add_child(active)
	var customers := Catalog.customers()
	active.build(customers[visits % customers.size()], visits / customers.size())
	active.set_night(night)
	visits += 1
	active.position = ENTRY[0]
	active.rotation.y = -PI / 2
	route.assign(ENTRY.slice(1))
	waypoint = 0
	transition(State.ARRIVING)

func set_night(enabled: bool) -> void:
	night = enabled
	for car in background:
		car.set_night(enabled)
	if is_instance_valid(active):
		active.set_night(enabled)

func start_service(seconds: float) -> bool:
	if state != State.WAITING:
		return false
	duration = seconds
	time_left = seconds
	transition(State.SERVING)
	return true

func progress() -> float:
	return 1.0 - time_left / duration if state == State.SERVING else 0.0

func crosses_forecourt() -> bool:
	return is_instance_valid(active) and (state == State.ARRIVING or state == State.LEAVING) 		and active.position.z < 6.5

func _process(delta: float) -> void:
	for car in background:
		var distance := 7.35 * delta
		car.position.x += distance
		if car.position.x >= 34.0:
			car.position.x -= 68.0
			car.build(STREET[passing % STREET.size()], passing / STREET.size())
			car.set_night(night)
			passing += 1
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
	var near_pump: bool = state == State.ARRIVING and waypoint >= route.size() - 2
	var speed := 7.8 if absf(active.position.x) > 10.0 else 4.75
	if near_pump:
		speed = 3.75
	var step := delta * speed
	if direction.length_squared() > 0.000001:
		active.rotation.y = lerp_angle(active.rotation.y, atan2(direction.x, direction.z), minf(1.0, delta * 8.0))
		active.position = active.position.move_toward(target, step)
		active.spin(minf(step, direction.length()))
	var turn := 0
	if state == State.ARRIVING and waypoint >= 1 and not near_pump:
		turn = 1
	elif state == State.LEAVING and waypoint > 0 and waypoint < 4:
		turn = -1
	active.update_signals(near_pump, turn, delta)
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
