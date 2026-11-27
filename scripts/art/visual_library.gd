extends RefCounted

const FONT = preload("res://assets/fonts/OpenSans-ExtraBold.ttf")
const CONTACT = preload("res://assets/materials/contact.gdshader")
const LIGHT_POOL = preload("res://assets/materials/light_pool.gdshader")

static var scenes: Dictionary = {}
static var meshes: Dictionary = {}
static var decals: Dictionary = {}
static var quad: PlaneMesh
static var fleet_residency: Array[String] = []
const FLEET_SCENES := 24
static var optional_venues: Array[String] = []
const DECOR_SCENES := 16

static func surface_shader(key: String, shader: Shader) -> ShaderMaterial:
	if not decals.has(key):
		var material := ShaderMaterial.new()
		material.shader = shader
		decals[key] = material
	return decals[key]

static func scene(family: String, key: String) -> PackedScene:
	var path := "res://assets/models/%s/%s.glb" % [family, key]
	if family == "vehicles" and not key.begins_with("wheel_"):
		fleet_residency.erase(path)
		fleet_residency.append(path)
		if fleet_residency.size() > FLEET_SCENES:
			scenes.erase(fleet_residency.pop_front())
	if family in ["estates", "transport"]:
		optional_venues.erase(path)
		optional_venues.append(path)
		if optional_venues.size() > DECOR_SCENES:
			scenes.erase(optional_venues.pop_front())
	if not scenes.has(path):
		scenes[path] = load(path)
	return scenes[path]

static func place(parent: Node3D, family: String, key: String, at := Vector3.ZERO, yaw := 0.0) -> Node3D:
	var instance := scene(family, key).instantiate() as Node3D
	instance.position = at
	instance.rotation.y = yaw
	parent.add_child(instance)
	var glass := instance.find_child("Glazing", true, false) as MeshInstance3D
	if glass:
		glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance

static func extract_mesh(family: String, key: String, part := "") -> Mesh:
	var identity := "%s/%s/%s" % [family, key, part]
	if not meshes.has(identity):
		var model := scene(family, key).instantiate()
		var geometry: MeshInstance3D
		if part.is_empty():
			var found := model.find_children("*", "MeshInstance3D", true, false)
			geometry = found[0] as MeshInstance3D
		else:
			geometry = model.find_child(part, true, false) as MeshInstance3D
		meshes[identity] = geometry.mesh
		model.free()
	return meshes[identity]

static func release_region(region: String) -> void:
	var families: Array[String] = ["regions/" + region + "_"]
	if region == "north":
		families = ["architecture/", "landscape/"]
	elif region == "desert":
		families = ["desert/"]
	for family in families:
		var model_path := "res://assets/models/" + family
		for key: String in scenes.keys():
			if key.begins_with(model_path):
				scenes.erase(key)
		for key: String in meshes.keys():
			if key.begins_with(family):
				meshes.erase(key)

static func sign(parent: Node3D, at: Vector3, message: String, height: float, tint: Color) -> Label3D:
	var label := Label3D.new()
	label.position = at
	label.text = message
	label.font = FONT
	label.font_size = 96
	label.pixel_size = height / 96.0
	label.modulate = tint
	label.outline_size = 0
	label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	parent.add_child(label)
	return label

static func contact(parent: Node3D, at: Vector3, width: float, length: float) -> MeshInstance3D:
	if not decals.has("contact"):
		var surface := ShaderMaterial.new()
		surface.shader = CONTACT
		decals["contact"] = surface
	return plane(parent, at, Vector2(width, length), decals["contact"])

static func light_pool(parent: Node3D, at: Vector3, size: Vector2, tint: Color, intensity: float) -> MeshInstance3D:
	var surface := ShaderMaterial.new()
	surface.shader = LIGHT_POOL
	surface.set_shader_parameter("tint", tint)
	surface.set_shader_parameter("intensity", intensity)
	return plane(parent, at, size, surface)

static func plane(parent: Node3D, at: Vector3, size: Vector2, surface: Material) -> MeshInstance3D:
	if quad == null:
		quad = PlaneMesh.new()
		quad.size = Vector2.ONE
	var instance := MeshInstance3D.new()
	instance.mesh = quad
	instance.material_override = surface
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.position = at
	instance.scale = Vector3(size.x, 1.0, size.y)
	parent.add_child(instance)
	return instance

static func settle(module: Node3D) -> void:
	var height := module.position.y
	var scale_y := module.scale.y
	module.position.y += 0.75
	module.scale.y *= 0.82
	var lift := module.create_tween().set_parallel()
	lift.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	lift.tween_property(module, "position:y", height, 0.59)
	lift.tween_property(module, "scale:y", scale_y, 0.67)
