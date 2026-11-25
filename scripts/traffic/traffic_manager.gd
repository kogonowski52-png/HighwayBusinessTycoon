extends Node3D

signal sighting(model: String)

const Vehicle = preload("res://scenes/vehicles/compact.tscn")
const Routes = preload("res://data/economy/routes.gd")
const Catalog = preload("res://scripts/traffic/vehicle_catalog.gd")
const Regions = preload("res://data/world/regions.gd")
const DESERT_STREET := ["range", "mesa", "vela", "atlas", "kestrel", "cargo", "parcel", "regency"]
const STREET := ["regency", "cargo", "trail", "horizon", "pulse", "mesa", "parcel", "vela", "atlas",
	"crest", "summit", "coast", "loop", "range", "orion", "post", "sprint", "pine", "meridian", "kestrel"]

var dispatch: HbtDispatch
var district := "north"
var vehicles: Dictionary = {}
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
	var total := 6 if district == "metro" else 4
	for i in total:
		var car := Vehicle.instantiate()
		car.position = Vector3(-27.0 + i * 19.0, 0, 12.17)
		car.rotation.y = PI / 2.0
		if not ambient_lanes.is_empty():
			var lane := i % ambient_lanes.size()
			car.position.z = ambient_lanes[lane]
			var left := floori(ambient_lanes.size() / 2.0)
			car.rotation.y *= 1.0 if lane < left else -1.0
		add_child(car)
		car.build(street_model(i), 0, district == "desert", district)
		background.append(car)
	passing = background.size()

func start(economy: HbtEconomy, seed: int, routes: Object = Routes) -> void:
	dispatch = HbtDispatch.new(economy, seed, routes)
	dispatch.added.connect(add_vehicle)
	dispatch.removed.connect(remove_vehicle)
	dispatch.completed.connect(show_sale)
	dispatch.seed_station()

func physics_step(delta: float) -> void:
	dispatch.tick(delta)
	for ticket: HbtVisit in dispatch.live.values():
		var car: Node3D = vehicles[ticket.number]
		car.position = ticket.location
		car.rotation.y = ticket.yaw
		car.suspension(ticket.signed_distance, ticket.steer if ticket.distance > 0.02 else 0, delta)
		car.update_signals(ticket.distance < 0.01, ticket.steer if ticket.distance > 0.02 else 0, delta)
	for car in background:
		var distance := 7.35 * delta
		var direction := signf(car.rotation.y)
		var border := 43.0 if layout.is_empty() else 72.0
		car.position.x += distance * direction
		if car.position.x * direction >= border:
			car.position.x -= (80.0 if layout.is_empty() else border * 2.0) * direction
			car.build(street_model(passing), floori(float(passing) / STREET.size()), district == "desert", district)
			sighting.emit(street_model(passing))
			car.set_night(night)
			passing += 1
		car.spin(distance)

func add_vehicle(visit: HbtVisit) -> void:
	var car := Vehicle.instantiate()
	car.position = visit.location
	car.rotation.y = visit.yaw
	add_child(car)
	car.build(visit.client.model, visit.client.paint, district == "desert", district)
	car.set_night(night)
	vehicles[visit.number] = car

func show_sale(visit: HbtVisit) -> void:
	if visit.sold_model.is_empty():
		return
	var car: Node3D = vehicles[visit.number]
	car.build(visit.sold_model, visit.client.paint, false, district)
	car.set_night(night)
	sighting.emit(visit.sold_model)

func remove_vehicle(visit: HbtVisit) -> void:
	var car: Node3D = vehicles[visit.number]
	car.hide()
	car.queue_free()
	vehicles.erase(visit.number)

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
