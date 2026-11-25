extends Node3D

const Art = preload("res://scripts/art/visual_library.gd")
const MARQUES := {"valley": "RIVERBEND", "alpine": "SUMMIT", "ocean": "BLUE CURRENT", "metro": "MERIDIAN"}

var routes: RefCounted
var building: Node3D
var pumps: Array[Node3D] = []
var status := OmniLight3D.new()

func _init(course: RefCounted) -> void:
	routes = course

func _ready() -> void:
	position = routes.origin("fuel")
	building = Art.place(self, "regions", routes.district + "_fuel")
	Art.sign(building, Vector3(0, 3.47, 2.175), MARQUES[routes.district], .33, Color("#fff1d6"))
	Art.contact(self, Vector3(0, -.016, -.80), 10.0, 6.0)
	for index in 2:
		var stop: Vector3 = routes.position_of("fuel", index)
		pumps.append(Art.place(self, "desert", "pump", stop - position + Vector3(1.53, 0, -.60)))
	status.position = pumps[0].position + Vector3(.1, 1.52, .24)
	status.light_color = Color("#acefbd")
	status.omni_range = 2.1
	status.light_energy = 0.0
	add_child(status)

func set_bays(count: int) -> void:
	for i in pumps.size():
		pumps[i].visible = i < count

func hose_anchor() -> Vector3:
	return pumps[0].global_position + Vector3(.30, 1.03, .08)

func set_service_progress(progress: float) -> void:
	status.light_energy = .34 + progress * .52 if progress > 0.0 else 0.0

func animate_construction() -> void:
	Art.settle(building)
