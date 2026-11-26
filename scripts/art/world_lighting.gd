extends Node3D

const Regions = preload("res://data/world/regions.gd")
const Art = preload("res://scripts/art/visual_library.gd")

enum Look { DAY, GOLDEN, EVENING, NIGHT, DAWN }

const LOOKS := [
	{ "ambient": Color("#d6e6f7"), "ambient_energy": 0.54, "key": Color("#fff1db"), "energy": 0.69,
		"angles": Vector3(-49, -34, 0), "back": Color("#b4c8b2"), "sky": Color("#80b5cf"), "practicals": 0.0 },
	{ "ambient": Color("#d1cce1"), "ambient_energy": 0.51, "key": Color("#ffd098"), "energy": 0.88,
		"angles": Vector3(-29, -53, 0), "back": Color("#cead84"), "sky": Color("#bdbcdd"), "practicals": 0.19 },
	{ "ambient": Color("#9babdb"), "ambient_energy": 0.38, "key": Color("#c3bad7"), "energy": 0.44,
		"angles": Vector3(-35, -41, 0), "back": Color("#747895"), "sky": Color("#465f9a"), "practicals": 0.68 },
	{ "ambient": Color("#8aaee9"), "ambient_energy": 0.24, "key": Color("#91b3ff"), "energy": 0.20,
		"angles": Vector3(-54, 29, 0), "back": Color("#243951"), "sky": Color("#192e5c"), "practicals": 1.0 },
	{ "ambient": Color("#eccfb9"), "ambient_energy": 0.53, "key": Color("#ffe4b9"), "energy": 0.69,
		"angles": Vector3(-21, 36, 0), "back": Color("#e5bb9a"), "sky": Color("#a9c5da"), "practicals": 0.09 },
]

var environment := Environment.new()
var sun := DirectionalLight3D.new()
var reflected_sky := ProceduralSkyMaterial.new()
var supports_glow := false
var practical_lights: Array[OmniLight3D] = []
var floor_glows: Array[MeshInstance3D] = []
var has_practicals := true
var reduced := false
var quality := 2
var current := Look.DAY
var district := "north"

func _ready() -> void:
	var world := WorldEnvironment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	var sky := Sky.new()
	sky.radiance_size = Sky.RADIANCE_SIZE_64
	sky.sky_material = reflected_sky
	reflected_sky.sun_angle_max = 0.0
	environment.sky = sky
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	supports_glow = RenderingServer.get_current_rendering_method() != "gl_compatibility"
	environment.glow_intensity = 0.29
	environment.glow_hdr_threshold = 1.08
	world.environment = environment
	add_child(world)

	sun.shadow_enabled = true
	sun.shadow_blur = 1.60
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
	if Regions.has_region(district):
		var plan: Dictionary = Regions.LAYOUTS[district]
		for id in plan.plots:
			var plot: Vector2 = plan.plots[id][0]
			var warm := Color("#ffc583") if id != "charge" else Color("#86eee5")
			var heavy: bool = plan.plots[id][1] == "truck"
			practical(Vector3(plot.x, 3.88 if heavy else 2.56, plot.y + 3.12), 8.0 if heavy else 5.7, warm)
			floor_glows.append(Art.light_pool(self, Vector3(plot.x, -.009, plot.y + 4.33),
				Vector2(14.0, 8.1) if heavy else Vector2(7.75, 5.8), warm, .79))
		if district == "metro":
			for x in [-24.0, 0.0, 24.0]:
				practical(Vector3(x, 3.60, 6.33), 7.60, Color("#c9ecff"))
		return
	if district == "desert":
		for point in [Vector3(-1, 3.11, .32), Vector3(-12.8, 2.03, -4.31), Vector3(28.1, 4.31, -21.33),
			Vector3(-13.4, 2.32, -21.54), Vector3(12.75, 2.74, -20.08), Vector3(32.0, 2.54, -4.88)]:
			practical(point, 5.8, Color("#ffd396"))
		for point in [Vector3(-1.0, .022, .80), Vector3(7.28, .021, 6.48), Vector3(19.1, .021, 6.63),
			Vector3(-22.7, .022, 6.51), Vector3(-12.75, .021, -4.35), Vector3(28.12, .022, -21.12)]:
			floor_glows.append(Art.light_pool(self, point, Vector2(7.0, 5.3), Color("#ffce83"), .72))
		return
	practical(Vector3(0.75, 2.89, 1.15), 6.7, Color("#ffdda2"))
	practical(Vector3(-5.84, 1.90, -3.15), 5.4, Color("#ffcd9e"))
	practical(Vector3(9.92, 2.78, 3.72), 4.6, Color("#ffd395"))
	practical(Vector3(11.34, 2.32, -5.2), 5.5, Color("#86eee1"))
	practical(Vector3(-15.3, 2.25, -6.95), 5.8, Color("#ffba87"))
	practical(Vector3(-7.65, 2.90, -13.4), 5.6, Color("#ffc29a"))
	practical(Vector3(8.56, 2.5, -13.75), 5.5, Color("#b6dbc9"))
	practical(Vector3(23.9, 4.45, -6.89), 7.8, Color("#ffdda3"))
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
	reflected_sky.sky_top_color = preset.sky
	reflected_sky.sky_horizon_color = preset.ambient
	reflected_sky.ground_horizon_color = preset.back
	reflected_sky.ground_bottom_color = Color("#4b5148") if current < Look.EVENING else Color("#151e35")
	sun.rotation_degrees = preset.angles
	sun.light_color = preset.key
	sun.light_energy = preset.energy
	if district == "desert" and look in [Look.DAY, Look.GOLDEN]:
		environment.background_color = Color("#d7a779")
		environment.ambient_light_color = Color("#d9dcef")
		sun.light_color = Color("#ffdfae")
		sun.light_energy = .83 if look == Look.DAY else .92
	var intensity: float = preset.practicals
	RenderingServer.global_shader_parameter_set(&"hbt_practical_level", lerpf(0.16, 1.64, intensity))
	if look in [Look.DAY, Look.GOLDEN]:
		match district:
			"valley":
				sun.light_color = Color("#fff1d2")
				sun.light_energy *= 1.10
			"alpine":
				environment.ambient_light_color = Color("#b8cde3")
				environment.ambient_light_energy = .47
				sun.light_color = Color("#ffe7c6")
				sun.light_energy *= .88
				sun.rotation_degrees = Vector3(-43, -48, 0)
			"ocean":
				environment.ambient_light_color = Color("#cae7df")
				sun.light_color = Color("#fff0cb")
				sun.light_energy *= 1.22
	if district == "metro" and look == Look.NIGHT:
		environment.ambient_light_energy = .33
		sun.light_energy = .28
	RenderingServer.global_shader_parameter_set(&"hbt_ambient_motion", 0.0 if reduced else 1.0)
	environment.glow_enabled = supports_glow and not reduced and look in [Look.EVENING, Look.NIGHT]
	for index in range(practical_lights.size()):
		var lamp := practical_lights[index]
		lamp.visible = intensity > 0.0 and index < [3, 5, practical_lights.size(), practical_lights.size()][quality]
		lamp.light_energy = intensity * (1.32 if index < 2 else 0.96)
	for decal in floor_glows:
		decal.visible = intensity > 0.0
		(decal.material_override as ShaderMaterial).set_shader_parameter("intensity", 0.58 * intensity)

func set_reduced(enabled: bool) -> void:
	set_quality(0 if enabled else 2)

func set_quality(tier: int) -> void:
	if quality != tier:
		quality = tier
		reduced = quality == 0
		sun.directional_shadow_max_distance = [34.0, 57.0, 74.0, 88.0][quality]
		sun.shadow_blur = [1.0, 1.28, 1.6, 1.75][quality]
		sun.directional_shadow_mode = [DirectionalLight3D.SHADOW_ORTHOGONAL, DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS,
			DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS, DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS][quality]
		set_look(current)
