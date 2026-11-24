extends Node3D

const Art = preload("res://scripts/art/visual_library.gd")

enum Look { DAY, GOLDEN, EVENING, NIGHT }

const LOOKS := [
	{ "ambient": Color("#c4dfed"), "ambient_energy": 0.55, "key": Color("#fff0d1"), "energy": 0.75,
		"angles": Vector3(-54, -38, 0), "back": Color("#b4c7ae"), "practicals": 0.0 },
	{ "ambient": Color("#c7c3dd"), "ambient_energy": 0.48, "key": Color("#ffd09a"), "energy": 0.92,
		"angles": Vector3(-31, -55, 0), "back": Color("#b0a789"), "practicals": 0.18 },
	{ "ambient": Color("#a6b9e8"), "ambient_energy": 0.40, "key": Color("#a4bbf0"), "energy": 0.47,
		"angles": Vector3(-38, -45, 0), "back": Color("#667b97"), "practicals": 0.68 },
	{ "ambient": Color("#a5bce8"), "ambient_energy": 0.36, "key": Color("#91a8e5"), "energy": 0.28,
		"angles": Vector3(-53, 31, 0), "back": Color("#354c6d"), "practicals": 1.0 },
]

var environment := Environment.new()
var sun := DirectionalLight3D.new()
var practical_lights: Array[OmniLight3D] = []
var floor_glows: Array[MeshInstance3D] = []
var has_practicals := true
var reduced := false
var current := Look.DAY

func _ready() -> void:
	var world := WorldEnvironment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment = environment
	add_child(world)

	sun.shadow_enabled = true
	sun.shadow_blur = 1.45
	sun.shadow_bias = 0.24
	sun.shadow_normal_bias = 1.22
	sun.shadow_reverse_cull_face = true
	sun.directional_shadow_max_distance = 74.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	add_child(sun)
	if has_practicals:
		setup_practicals()
	set_look(current)

func setup_practicals() -> void:
	practical(Vector3(0.75, 2.89, 1.15), 6.7, Color("#ffdda2"))
	practical(Vector3(-5.84, 1.90, -3.15), 5.4, Color("#ffcd9e"))
	practical(Vector3(9.92, 2.78, 3.72), 4.6, Color("#ffd395"))
	practical(Vector3(11.34, 2.32, -5.2), 5.5, Color("#86eee1"))
	practical(Vector3(-15.3, 2.25, -6.95), 5.8, Color("#ffba87"))
	practical(Vector3(-7.65, 2.90, -13.4), 5.6, Color("#ffc29a"))
	practical(Vector3(8.56, 2.5, -13.75), 5.5, Color("#b6dbc9"))
	for at in [Vector3(1.0, 0.016, 1.45), Vector3(-6.0, 0.025, -2.06),
		Vector3(9.63, 0.024, 4.01), Vector3(-11.6, 0.026, 4.95), Vector3(13.1, 0.027, 10.65)]:
		floor_glows.append(Art.light_pool(self, at, Vector2(6.2, 5.4), Color("#ffc977"), 0.64))

func practical(at: Vector3, radius: float, tint: Color) -> void:
	var lamp := OmniLight3D.new()
	lamp.position = at
	lamp.light_color = tint
	lamp.omni_range = radius
	lamp.omni_attenuation = 1.35
	lamp.shadow_enabled = false
	add_child(lamp)
	practical_lights.append(lamp)

func set_look(look: Look) -> void:
	current = look
	var preset: Dictionary = LOOKS[look]
	environment.background_color = preset.back
	environment.ambient_light_color = preset.ambient
	environment.ambient_light_energy = preset.ambient_energy
	sun.rotation_degrees = preset.angles
	sun.light_color = preset.key
	sun.light_energy = preset.energy
	var intensity: float = preset.practicals
	for index in range(practical_lights.size()):
		var lamp := practical_lights[index]
		lamp.visible = intensity > 0.0 and (not reduced or index < 3)
		lamp.light_energy = intensity * (1.1 if index < 2 else 0.79)
	for decal in floor_glows:
		decal.visible = intensity > 0.0
		(decal.material_override as ShaderMaterial).set_shader_parameter("intensity", 0.48 * intensity)

func set_reduced(enabled: bool) -> void:
	if reduced != enabled:
		reduced = enabled
		set_look(current)
