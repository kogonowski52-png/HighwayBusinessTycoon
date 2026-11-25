extends Node3D

signal sighting(model: String)

const Vehicle = preload("res://scenes/vehicles/compact.tscn")
const Routes = preload("res://data/economy/routes.gd")
const Catalog = preload("res://scripts/traffic/vehicle_catalog.gd")
const DESERT_STREET := ["range", "mesa", "vela", "atlas", "kestrel", "cargo", "parcel", "regency"]
const STREET := ["regency", "cargo", "trail", "horizon", "pulse", "mesa", "parcel", "vela", "atlas",
	"crest", "summit", "coast", "loop", "range", "orion", "post", "sprint", "pine", "meridian", "kestrel"]

var dispatch: HbtDispatch
var district := "north"
var vehicles: Dictionary = {}
var background: Array[Node3D] = []
var passing := 0
var night := false

func _ready() -> void:
	for i in range(4):
		var car := Vehicle.instantiate()
		car.position = Vector3(-27.0 + i * 19.0, 0, 12.17)
		car.rotation.y = PI / 2.0
		add_child(car)
		car.build(street_model(i), 0, district == "desert")
		background.append(car)
	passing = background.size()

func start(economy: HbtEconomy, seed: int, routes: Script = Routes) -> void:
	dispatch = HbtDispatch.new(economy, seed, routes)
	dispatch.added.connect(add_vehicle)
	dispatch.removed.connect(remove_vehicle)
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
		car.position.x += distance
		if car.position.x >= 43.0:
			car.position.x -= 80.0
			car.build(street_model(passing), floori(float(passing) / STREET.size()), district == "desert")
			sighting.emit(street_model(passing))
			car.set_night(night)
			passing += 1
		car.spin(distance)

func add_vehicle(visit: HbtVisit) -> void:
	var car := Vehicle.instantiate()
	car.position = visit.location
	car.rotation.y = visit.yaw
	add_child(car)
	car.build(visit.client.model, visit.client.paint, district == "desert")
	car.set_night(night)
	vehicles[visit.number] = car

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
	return fleet[index % fleet.size()]
