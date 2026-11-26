extends Node3D

const Art = preload("res://scripts/art/visual_library.gd")

var effect := CPUParticles3D.new()
var weather := "clear"
var event_id := ""
var ornaments := Node3D.new()
var wardrobe := Node3D.new()
var lighting: Node3D
var desert := false
var district := "north"
var routes: Object

func setup(world_lighting: Node3D, region: String, course: Object) -> void:
	lighting = world_lighting
	district = region
	routes = course
	desert = region == "desert"
	add_child(ornaments)
	add_child(wardrobe)
	add_child(effect)
	effect.local_coords = false
	effect.emitting = false
	effect.amount = 42
	effect.lifetime = 1.7
	effect.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	effect.emission_box_extents = Vector3(13.0, 1.4, 8.2)
	effect.spread = 9.0
	effect.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func follow(at: Vector3) -> void:
	effect.position = Vector3(at.x, 7.8, at.z)

func apply(site: HbtEconomy, event: Dictionary, quality: int, choice: String) -> void:
	var condition := choice
	if choice == "auto":
		condition = event.weather if event.live else "wind" if desert else "snow" if district == "alpine" else "clear"
		if desert and condition == "haze":
			condition = "wind"
		if district == "alpine" and condition in ["rain", "clear"]:
			condition = "snow"
		if district == "ocean" and condition == "snow":
			condition = "haze"
	var changed := condition != weather or effect.mesh == null
	weather = condition
	var fog: Environment = lighting.environment
	fog.fog_enabled = condition != "clear"
	fog.fog_density = .0085 if condition == "haze" else .0030 if district == "alpine" else .0048
	fog.fog_light_color = Color("#efbf93") if desert else Color("#c7d8e5")
	site.conditions = {}
	match condition:
		"wind": site.conditions = {"showers": 1.27, "cafe": 1.15, "wash": 1.13}
		"rain": site.conditions = {"cafe": 1.19, "restaurant": 1.18, "wash": .79, "motel": 1.12}
		"snow": site.conditions = {"workshop": 1.22, "truck": 1.12, "motel": 1.24, "restaurant": 1.19}
	if changed:
		configure_particles(condition)
	var cap: int = [12, 28, 48, 65][quality]
	if effect.amount != cap:
		effect.amount = cap
	effect.emitting = condition in ["rain", "snow", "wind"]
	var tag: String = event.id if event.live else ""
	if tag != event_id:
		event_id = tag
		replace_event_ornaments(tag)

func configure_particles(condition: String) -> void:
	var body := BoxMesh.new()
	var pigment := StandardMaterial3D.new()
	pigment.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	match condition:
		"rain":
			body.size = Vector3(.025, .47, .025)
			pigment.albedo_color = Color("#a7cede")
			effect.direction = Vector3(.25, -1, .09)
			effect.gravity = Vector3(.32, -8, 0)
			effect.initial_velocity_min = 4.6
			effect.initial_velocity_max = 6.8
		"snow":
			body.size = Vector3(.069, .069, .069)
			pigment.albedo_color = Color("#e7f0e9")
			effect.direction = Vector3(.26, -1.0, .2)
			effect.gravity = Vector3(.2, -1.60, .1)
			effect.initial_velocity_min = 1.3
			effect.initial_velocity_max = 2.2
		_:
			body.size = Vector3(.24, .036, .055)
			pigment.albedo_color = Color("#e8cb9f")
			effect.direction = Vector3(1, -.21, -.25)
			effect.gravity = Vector3(.15, -.19, 0)
			effect.initial_velocity_min = 3.7
			effect.initial_velocity_max = 6.4
	body.material = pigment
	effect.mesh = body

func replace_event_ornaments(tag: String) -> void:
	clear(ornaments)
	if tag.is_empty():
		return
	var positions := [Vector3(-7.1, 0, -.8), Vector3(4.65, 0, -4.9), Vector3(17.2, 0, -5.8)] if desert else 		[Vector3(9.1, 0, 2.24), Vector3(-2.24, 0, -2.45), Vector3(-10.2, 0, -.79)]
	if HbtEconomy.Regions.has_region(district):
		var station: Vector3 = routes.origin("fuel")
		positions = [station + Vector3(4.5, 0, .10), station + Vector3(-4.45, 0, -.45)]
	for at: Vector3 in positions:
		Art.place(ornaments, "desert", "event_" + tag, at)

func display_collection(equipped: Dictionary) -> void:
	clear(wardrobe)
	var paths := {"decor": "event_", "signs": "event_", "facades": "upgrade_"}
	var bank := Vector3(-6.0, 0, -3.3) if desert else Vector3(5.45, 0, -.06)
	if HbtEconomy.Regions.has_region(district):
		bank = routes.origin("fuel") + Vector3(4.32, 0, -1.2)
	var index := 0
	for group in paths:
		if equipped.has(group):
			var item: String = equipped[group]
			var at := bank + Vector3(index * 1.31, 0, 0)
			if item == "copper_arch" and not HbtEconomy.Regions.has_region(district):
				at = Vector3(-.28, 3.73, -.06) if desert else Vector3(1.09, 3.01, .40)
			if item == "gold_gate":
				Art.place(wardrobe, "premium", item, at)
			else:
				Art.place(wardrobe, "desert", paths[group] + item, at)
		index += 1

func clear(node: Node3D) -> void:
	for item in node.get_children():
		node.remove_child(item)
		item.queue_free()
