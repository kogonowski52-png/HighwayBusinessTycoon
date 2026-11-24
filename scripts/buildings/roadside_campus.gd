extends Node3D

const Art = preload("res://scripts/art/visual_library.gd")
const Actor = preload("res://scripts/customers/customer_manager.gd")
const Vehicle = preload("res://scenes/vehicles/compact.tscn")
const CREAM := Color("#fff0ce")

const WASH_AT := Vector3(11.47, 0.0, -7.85)
const KITCHEN_AT := Vector3(-16.02, 0.0, -8.58)
const WORKSHOP_AT := Vector3(8.68, 0.0, -16.47)
const MOTEL_AT := Vector3(-7.81, 0.0, -16.82)
const PARKING_AT := Vector3(-16.54, 0.0, -0.85)

func _ready() -> void:
	var wash := Art.place(self, "architecture", "wash", WASH_AT)
	Art.sign(wash, Vector3(0, 2.82, 2.926), "CURRENT WASH", 0.281, CREAM)
	var kitchen := Art.place(self, "architecture", "restaurant", KITCHEN_AT)
	Art.sign(kitchen, Vector3(0, 2.706, 1.767), "JUNIPER", 0.343, CREAM)
	var workshop := Art.place(self, "architecture", "workshop", WORKSHOP_AT)
	Art.sign(workshop, Vector3(0, 2.622, 2.497), "MILE 17 GARAGE", 0.244, CREAM)
	var motel := Art.place(self, "architecture", "motel", MOTEL_AT)
	Art.sign(motel, Vector3(4.14, 3.394, 2.320), "MOTEL", 0.224, CREAM)
	var parking := Art.place(self, "architecture", "parking", PARKING_AT)
	Art.sign(parking, Vector3(-3.9, 1.958, 1.973), "P", 0.538, CREAM)
	for at in [WASH_AT, KITCHEN_AT, WORKSHOP_AT, MOTEL_AT, PARKING_AT]:
		Art.contact(self, at + Vector3(0, 0.013, 0.10), 8.7, 7.0)
	park("coast", PARKING_AT + Vector3(-1.80, 0.18, 0.02), PI, 0)
	park("pulse", PARKING_AT + Vector3(1.86, 0.18, -0.03), PI, 1)
	park("kestrel", WORKSHOP_AT + Vector3(1.64, 0.24, 0.80), 0.0, 0)
	park("loop", WASH_AT + Vector3(-0.07, 0.255, 0.39), 0.0, 1)
	actor("cashier", Vector3(-3.95, 0.28, -5.16), 0.28, "cash")
	actor("attendant", Vector3(4.58, 0.00, -0.87), -0.47, "service")
	actor("mechanic", WORKSHOP_AT + Vector3(1.60, 0.241, 2.46), PI, "repair")
	actor("wash_worker", WASH_AT + Vector3(-2.39, 0.258, 3.10), 0.29, "clean")
	actor("manager", MOTEL_AT + Vector3(3.30, 0.305, 1.66), -0.31, "service")

	var server := actor("server", KITCHEN_AT + Vector3(0, 0.32, 2.42), 0.35, "carry")
	server.configure_walk([
		KITCHEN_AT + Vector3(-1.47, 0.32, 2.53), KITCHEN_AT + Vector3(1.42, 0.32, 2.53),
		KITCHEN_AT + Vector3(1.42, 0.32, 1.82), KITCHEN_AT + Vector3(-1.47, 0.32, 1.82)], "carry", 0.91)
	var customer := actor("customer", Vector3(-9.30, 0.028, -1.08), 0.87, "walk")
	customer.configure_walk([
		Vector3(-9.43, 0.03, -1.07), Vector3(-6.35, 0.03, -1.08),
		Vector3(-5.78, 0.03, -1.70), Vector3(-6.81, 0.03, -1.74), Vector3(-9.45, 0.03, -1.63)])

func park(id: String, at: Vector3, yaw: float, paint: int) -> void:
	var car := Vehicle.instantiate() as Node3D
	car.position = at
	car.rotation.y = yaw
	add_child(car)
	car.build(id, paint)

func actor(role: String, at: Vector3, yaw: float, clip: String) -> Actor:
	var resident := Actor.new()
	resident.role = role
	resident.position = at
	resident.rotation.y = yaw
	add_child(resident)
	resident.play(clip)
	return resident
