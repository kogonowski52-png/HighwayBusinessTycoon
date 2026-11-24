extends Node3D

const Art = preload("res://scripts/art/visual_library.gd")
const Catalog = preload("res://scripts/traffic/vehicle_catalog.gd")

static var brake_lit: StandardMaterial3D
static var indicator_lit: StandardMaterial3D
static var head_lit: StandardMaterial3D
static var paints: Dictionary = {}

var wheels: Array[Node3D] = []
var wheel_instances: MultiMesh
var brake_lamps: MeshInstance3D
var left_lamps: MeshInstance3D
var right_lamps: MeshInstance3D
var headlamps: MeshInstance3D
var head_pool: MeshInstance3D
var decoration: Node3D
var record: Dictionary
var model_id := ""
var radius := 0.30
var blink_elapsed := 0.0
var lit_at_night := false

func build(id: String, variant := 0) -> void:
	if is_instance_valid(decoration):
		remove_child(decoration)
		decoration.queue_free()
	wheels.clear()
	record = Catalog.definition(id)
	model_id = id
	radius = float(record.radius)
	decoration = Node3D.new()
	add_child(decoration)
	var car := Art.place(decoration, "vehicles", id)
	var chassis := car.find_child("Chassis", true, false) as MeshInstance3D
	var swatch := Color.html(record.paint[posmod(variant, record.paint.size())])
	apply_paint(chassis, swatch)

	brake_lamps = car.find_child("BrakeLamps", true, false) as MeshInstance3D
	left_lamps = car.find_child("IndicatorLeft", true, false) as MeshInstance3D
	right_lamps = car.find_child("IndicatorRight", true, false) as MeshInstance3D
	headlamps = car.find_child("Headlamps", true, false) as MeshInstance3D
	for geometry in [brake_lamps, left_lamps, right_lamps, headlamps]:
		geometry.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var tire := Art.extract_mesh("vehicles", "wheel_" + str(record.wheel))
	for side in [-1.0, 1.0]:
		for axle in record.axles:
			var wheel := Node3D.new()
			wheel.position = Vector3(side * float(record.wheel_x), radius, float(axle))
			decoration.add_child(wheel)
			wheels.append(wheel)
	wheel_instances = MultiMesh.new()
	wheel_instances.transform_format = MultiMesh.TRANSFORM_3D
	wheel_instances.mesh = tire
	wheel_instances.instance_count = wheels.size()
	var rolling := MultiMeshInstance3D.new()
	rolling.name = "Wheels"
	rolling.multimesh = wheel_instances
	rolling.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	decoration.add_child(rolling)
	update_wheel_transforms()
	Art.contact(decoration, Vector3(0, 0.016, 0), float(record.width) * 1.96, float(record.length) * 1.40)
	head_pool = Art.light_pool(decoration, Vector3(0, 0.019, float(record.head_z) + 0.76),
		Vector2(float(record.width) * 1.53, 2.65), Color("#ffdaa2"), 0.63)
	configure_light_materials()
	apply_headlamps()

func apply_paint(chassis: MeshInstance3D, swatch: Color) -> void:
	for surface in range(chassis.mesh.get_surface_count()):
		var material := chassis.mesh.surface_get_material(surface) as StandardMaterial3D
		if material != null and material.resource_name == "CoachPaint":
			if not paints.has(swatch):
				var finish := StandardMaterial3D.new()
				finish.albedo_color = swatch
				finish.roughness = 0.28
				finish.metallic = 0.18
				paints[swatch] = finish
			chassis.set_surface_override_material(surface, paints[swatch])

func configure_light_materials() -> void:
	if brake_lit == null:
		brake_lit = luminous(Color("#fa513a"), 1.25)
		indicator_lit = luminous(Color("#ffb144"), 1.48)
		head_lit = luminous(Color("#fff0c1"), 1.65)

func luminous(tint: Color, energy: float) -> StandardMaterial3D:
	var lamp := StandardMaterial3D.new()
	lamp.albedo_color = tint
	lamp.emission_enabled = true
	lamp.emission = tint
	lamp.emission_energy_multiplier = energy
	lamp.roughness = 0.38
	return lamp

func set_night(enabled: bool) -> void:
	if lit_at_night != enabled:
		lit_at_night = enabled
		apply_headlamps()

func apply_headlamps() -> void:
	headlamps.material_override = head_lit if lit_at_night else null
	head_pool.visible = lit_at_night

func update_signals(braking: bool, turn: int, delta: float) -> void:
	blink_elapsed = fmod(blink_elapsed + delta, 0.78) if turn != 0 else 0.0
	var flash := blink_elapsed < 0.42
	brake_lamps.material_override = brake_lit if braking else null
	left_lamps.material_override = indicator_lit if turn == -1 and flash else null
	right_lamps.material_override = indicator_lit if turn == 1 and flash else null

func spin(distance: float) -> void:
	for wheel in wheels:
		wheel.rotate_x(distance / radius)
	update_wheel_transforms()

func update_wheel_transforms() -> void:
	for index in range(wheels.size()):
		var wheel := wheels[index]
		var pose := Transform3D(wheel.basis.scaled_local(Vector3.ONE * radius), wheel.position)
		wheel_instances.set_instance_transform(index, pose)
