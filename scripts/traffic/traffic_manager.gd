extends Node3D

signal sighting(model: String)

const Vehicle = preload("res://scenes/vehicles/compact.tscn")
const Routes = preload("res://data/economy/routes.gd")
const ViewVolume = preload("res://scripts/art/view_volume.gd")
const POOL_LIMIT := 24
const Regions = preload("res://data/world/regions.gd")
const DESERT_STREET := ["range", "mesa", "vela", "atlas", "kestrel", "cargo", "parcel", "regency"]
const STREET := ["regency", "cargo", "trail", "horizon", "pulse", "mesa", "parcel", "vela", "atlas",
	"crest", "summit", "coast", "loop", "range", "orion", "post", "sprint", "pine", "meridian", "kestrel"]

var dispatch: HbtDispatch
var district := "north"
var vehicles: Dictionary = {}
var visual_area := ViewVolume.new()
var pool: Dictionary = {}
var pooled := 0
var built := 0
var reused := 0
var background: Array[Node3D] = []
var passing := 0
var night := false
var layout: Dictionary
var ambient_lanes: Array[float] = []

func _ready() -> void:
	layout = Regions.LAYOUTS.get(district, {})
	if not layout.is_empty():
		var middle: float = layout.ambient
		if district == "metro":
			ambient_lanes.assign([middle - 4.84, middle - 1.62, middle + 1.62, middle + 4.84])
		else:
			ambient_lanes.assign([middle - 1.88, middle + 1.89])
	for i in 6 if district == "metro" else 4:
		add_ambient(i)
	passing = background.size()

func add_ambient(index: int) -> void:
	var car := Vehicle.instantiate()
	car.position = Vector3(-27.0 + index * 19.0, 0, 12.17)
	car.rotation.y = PI / 2.0
	if not ambient_lanes.is_empty():
		var lane := index % ambient_lanes.size()
		car.position.z = ambient_lanes[lane]
		var left := floori(ambient_lanes.size() / 2.0)
		car.rotation.y *= 1.0 if lane < left else -1.0
	add_child(car)
	car.build(street_model(index), 0, district == "desert", district)
	background.append(car)

func start(economy: HbtEconomy, seed: int, routes: Object = Routes) -> void:
	dispatch = HbtDispatch.new(economy, seed, routes)
	dispatch.added.connect(add_vehicle)
	dispatch.removed.connect(remove_vehicle)
	dispatch.completed.connect(show_sale)
	dispatch.seed_station()

func physics_step(delta: float) -> void:
	dispatch.tick(delta)
	visual_area.update(get_viewport().get_camera_3d())
	for ticket: HbtVisit in dispatch.live.values():
		var car: Node3D = vehicles[ticket.number]
		var in_frame := visual_area.sees(ticket.location, 8.0)
		car.visible = in_frame
		if not in_frame:
			continue
		if car.position != ticket.location:
			car.position = ticket.location
			car.rotation.y = ticket.yaw
		var steering: int = ticket.steer if ticket.distance > .02 else 0
		car.suspension(ticket.signed_distance, steering, delta)
		car.update_signals(ticket.distance < .01, steering, delta)
	for car in background:
		var distance := 7.35 * delta
		var direction := signf(car.rotation.y)
		var border := 43.0 if layout.is_empty() else 72.0
		car.position.x += distance * direction
		if car.position.x * direction >= border:
			car.position.x -= (80.0 if layout.is_empty() else border * 2.0) * direction
			var model := street_model(passing)
			car.build(model, floori(float(passing) / STREET.size()), district == "desert", district)
			sighting.emit(model)
			car.set_night(night)
			passing += 1
		car.visible = visual_area.sees(car.position, 8.0)
		if car.visible:
			car.spin(distance)

func add_vehicle(visit: HbtVisit) -> void:
	var key := pool_key(visit.client.model, visit.client.paint)
	var car: Node3D
	if pool.has(key):
		car = pool[key].pop_back()
		if pool[key].is_empty():
			pool.erase(key)
		pooled -= 1
		reused += 1
	else:
		car = Vehicle.instantiate()
		add_child(car)
		car.build(visit.client.model, visit.client.paint, district == "desert", district)
		built += 1
	car.set_meta(&"pool_key", key)
	car.reset_drive()
	car.position = visit.location
	car.rotation.y = visit.yaw
	car.visible = visual_area.sees(visit.location, 8.0)
	car.set_night(night)
	vehicles[visit.number] = car

func pool_key(model: String, paint: int) -> String:
	return "%s/%d" % [model, paint]

func show_sale(visit: HbtVisit) -> void:
	if visit.sold_model.is_empty():
		return
	var car: Node3D = vehicles[visit.number]
	car.build(visit.sold_model, visit.client.paint, district == "desert", district)
	car.set_meta(&"pool_key", pool_key(visit.sold_model, visit.client.paint))
	car.set_night(night)
	sighting.emit(visit.sold_model)

func remove_vehicle(visit: HbtVisit) -> void:
	var car: Node3D = vehicles[visit.number]
	car.hide()
	vehicles.erase(visit.number)
	var key: String = car.get_meta(&"pool_key")
	if pooled >= POOL_LIMIT or pool.get(key, []).size() >= 2:
		car.queue_free()
		return
	if not pool.has(key):
		pool[key] = []
	pool[key].append(car)
	pooled += 1

func set_night(enabled: bool) -> void:
	night = enabled
	for car: Node3D in vehicles.values():
		car.set_night(enabled)
	for car in background:
		car.set_night(enabled)

func street_model(index: int) -> String:
	var fleet := DESERT_STREET if district == "desert" else STREET
	if not layout.is_empty():
		fleet = layout.fleet
	return fleet[index % fleet.size()]
