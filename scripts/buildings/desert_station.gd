extends Node3D

const Art = preload("res://scripts/art/visual_library.gd")
const Routes = preload("res://data/world/desert_routes.gd")

var canopy: Node3D
var pumps: Array[Node3D] = []
var status_light: OmniLight3D

func _ready() -> void:
	position = Routes.FRONTS.fuel
	canopy = Art.place(self, "desert", "copper_mile")
	Art.contact(self, Vector3(0, -.021, -.87), 10.6, 5.6)
	Art.sign(self, Vector3(.24, 3.46, 3.150), "COPPER  MILE", .33, Color("#fff0ce"))
	Art.sign(self, Vector3(-.23, 2.15, -1.38), "FUEL  &  SUPPLIES", .155, Color("#48746a"))
	for index in 2:
		var bay := Routes.position_of("fuel", index) - position
		pumps.append(Art.place(self, "desert", "pump", bay + Vector3(1.41, 0.0, -.58)))
	status_light = OmniLight3D.new()
	status_light.position = pumps[0].position + Vector3(0, 1.47, .32)
	status_light.light_color = Color("#67efb9")
	status_light.omni_range = 1.14
	status_light.light_energy = 0.0
	add_child(status_light)

func set_bays(count: int) -> void:
	for index in pumps.size():
		pumps[index].visible = index < count

func hose_anchor() -> Vector3:
	return pumps[0].global_position + Vector3(.30, 1.03, .08)

func set_service_progress(progress: float) -> void:
	status_light.light_energy = 0.24 + progress * .54 if progress > 0.0 else 0.0

func animate_construction() -> void:
	Art.settle(canopy)
