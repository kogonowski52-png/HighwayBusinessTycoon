extends Node3D

const Art = preload("res://scripts/art/visual_library.gd")
const Kit = preload("res://scripts/buildings/model_kit.gd")
const Campus = preload("res://scripts/buildings/roadside_campus.gd")

var soft_disk: GradientTexture2D
var dust: CPUParticles3D
var steam: CPUParticles3D
var foam: CPUParticles3D
var water: CPUParticles3D
var smoke: CPUParticles3D
var mote: CPUParticles3D
var hose: Array[MeshInstance3D] = []
var washing := false
var repairing := false
var reduced := false
var emitters: Dictionary = {}

func _ready() -> void:
	soft_disk = soft_texture()
	dust = vapor(Vector3.ZERO, Color("#c7ab78"), 11, 0.66, Vector3(0, 0.80, 0))
	dust.emitting = false
	var washer := Campus.WASH_AT
	steam = vapor(washer + Vector3(0.09, 0.46, 1.94), Color("#ddeee1"), 12, 1.47, Vector3(0, 0.12, 0.18))
	steam.scale_amount_min = 0.34
	steam.scale_amount_max = 0.62
	steam.emitting = false
	smoke = vapor(Campus.WORKSHOP_AT + Vector3(2.74, 3.86, -1.86), Color("#a9a99b"), 10, 2.36,
		Vector3(0.13, 0.02, 0))
	smoke.scale_amount_max = 0.64
	smoke.emitting = false
	foam = drops(washer + Vector3(0, 0.43, 1.18), Color("#e8f5e3"), 21, 0.75,
		Vector3(0, 0.50, 0.32), 0.08)
	foam.gravity = Vector3(0, -1.15, 0)
	foam.emission_box_extents = Vector3(0.74, 0.11, 0.48)
	foam.emitting = false
	water = drops(washer + Vector3(0, 2.15, 0.88), Color("#8cd4d0"), 32, 0.60,
		Vector3(0, -1, 0.08), 0.046)
	water.gravity = Vector3(0, -4.6, 0)
	water.initial_velocity_min = 0.95
	water.initial_velocity_max = 2.14
	water.spread = 19.0
	water.emission_box_extents = Vector3(1.19, 0.13, 0.61)
	water.emitting = false
	mote = drops(Vector3(-9.65, 0.63, -3.3), Color("#f2ce84"), 15, 3.30,
		Vector3(0.68, 0.52, 0.33), 0.026)
	mote.emission_box_extents = Vector3(2.0, 0.42, 2.1)
	mote.gravity = Vector3(0, 0.055, 0)
	mote.initial_velocity_min = 0.16
	mote.initial_velocity_max = 0.36
	mote.spread = 39.0
	for i in range(11):
		var segment := Kit.cylinder(self, Vector3.ZERO, 0.034, 0.034, 1.0, Color("#283c3b"), 8)
		segment.visible = false
		segment.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		hose.append(segment)
	emitters = {dust: 11, steam: 12, smoke: 10, foam: 21, water: 32, mote: 15}

func set_quality(tier: int) -> void:
	reduced = tier == 0
	var ratio: float = [.45, .74, 1.0, 1.30][tier]
	for source: CPUParticles3D in emitters:
		source.amount = maxi(1, roundi(emitters[source] * ratio))

func soft_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.32, 0.71, 1.0])
	gradient.colors = PackedColorArray([Color(1, 1, 1, 0.61), Color(1, 1, 1, 0.49),
		Color(1, 1, 1, 0.11), Color(1, 1, 1, 0.0)])
	var image := GradientTexture2D.new()
	image.width = 64
	image.height = 64
	image.gradient = gradient
	image.fill = GradientTexture2D.FILL_RADIAL
	image.fill_from = Vector2(0.5, 0.5)
	image.fill_to = Vector2(1.0, 0.5)
	return image

func vapor(at: Vector3, tint: Color, count: int, lifetime: float, gravity: Vector3) -> CPUParticles3D:
	var face := QuadMesh.new()
	face.size = Vector2.ONE
	var surface := StandardMaterial3D.new()
	surface.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	surface.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	surface.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	surface.vertex_color_use_as_albedo = true
	surface.albedo_texture = soft_disk
	face.material = surface
	var vapour := emitter(at, tint, count, lifetime, face)
	vapour.gravity = gravity
	vapour.direction = Vector3(0.29, 1.0, 0.13)
	vapour.spread = 46.0
	vapour.initial_velocity_min = 0.21
	vapour.initial_velocity_max = 0.74
	vapour.scale_amount_min = 0.36
	vapour.scale_amount_max = 0.85
	vapour.color_ramp = fade()
	return vapour

func drops(at: Vector3, tint: Color, count: int, lifespan: float, direction: Vector3, size: float) -> CPUParticles3D:
	var bead := SphereMesh.new()
	bead.radius = size
	bead.height = size * 2.0
	bead.radial_segments = 6
	bead.rings = 3
	var surface := StandardMaterial3D.new()
	surface.vertex_color_use_as_albedo = true
	surface.roughness = 0.43
	bead.material = surface
	var particles := emitter(at, tint, count, lifespan, bead)
	particles.direction = direction
	particles.spread = 43.0
	particles.initial_velocity_min = 0.36
	particles.initial_velocity_max = 0.91
	particles.scale_amount_min = 0.41
	particles.scale_amount_max = 1.16
	return particles

func emitter(at: Vector3, tint: Color, count: int, lifespan: float, shape: Mesh) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.position = at
	particles.amount = count
	particles.lifetime = lifespan
	particles.mesh = shape
	particles.color = tint
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = Vector3(0.15, 0.073, 0.19)
	add_child(particles)
	return particles

func fade() -> Gradient:
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.15, 0.62, 1.0])
	ramp.colors = PackedColorArray([Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.83),
		Color(1, 1, 1, 0.36), Color(1, 1, 1, 0.0)])
	return ramp

func set_activity(wash: HbtVisit, workshop: HbtVisit) -> void:
	washing = wash != null
	repairing = workshop != null
	if washing:
		var at := wash.location
		water.position = at + Vector3(0, 1.94, 0.28)
		foam.position = at + Vector3(0, 0.40, 0.68)
		steam.position = at + Vector3(0.10, 0.48, 1.40)
	water.emitting = washing and not reduced
	foam.emitting = washing and not reduced
	steam.emitting = washing
	smoke.emitting = repairing and not reduced
	mote.emitting = not reduced

func drive_on_dust(enabled: bool, at: Vector3) -> void:
	dust.emitting = enabled and not reduced
	if dust.emitting:
		dust.position = at + Vector3(0, 0.14, 0)

func set_hose(connected: bool, grip: Vector3, start := Vector3(1.61, 1.085, 0.63)) -> void:
	for piece in hose:
		piece.visible = connected
	if not connected:
		return
	var guide := start + Vector3(2.14, -0.935, 1.11)
	var control := grip + Vector3(0.62, -0.84, 0.24)
	for index in range(hose.size()):
		var from := start.bezier_interpolate(guide, control, grip, index / float(hose.size()))
		var to := start.bezier_interpolate(guide, control, grip, (index + 1) / float(hose.size()))
		var span := to - from
		var piece := hose[index]
		piece.position = (from + to) * 0.5
		piece.quaternion = Quaternion(Vector3.UP, span.normalized())
		piece.scale.y = span.length() + 0.026

func coin_pop(at: Vector3, payout: String) -> void:
	var group := Node3D.new()
	group.position = at
	add_child(group)
	var label := Art.sign(group, Vector3(0, 0.52, 0), "+" + payout, 0.42, Color("#ffdc91"))
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.outline_size = 9
	label.outline_modulate = Color("#254b49")
	var bounce := group.create_tween().set_parallel()
	bounce.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	bounce.tween_property(group, "position:y", at.y + 1.51, 1.08)
	bounce.tween_property(label, "modulate:a", 0.0, 0.36).set_delay(0.79)
	for i in range(3 if reduced else 5):
		var displacement := float(i) / 4.0 - 0.5
		var coin := Kit.cylinder(group, Vector3(displacement * 0.58, 0.02, 0.04),
			0.13, 0.13, 0.046, Color("#ecb858"), 18)
		coin.rotation.z = PI / 2
		bounce.tween_property(coin, "position", Vector3(displacement * 1.55, 0.29, 0.05), 0.67)
		bounce.tween_property(coin, "rotation:y", TAU * 2.20, 1.17)
		bounce.tween_property(coin, "scale", Vector3.ZERO, 0.33).set_delay(0.81)
	bounce.chain().tween_callback(group.queue_free)

func construction(at: Vector3) -> void:
	var debris := vapor(at + Vector3(0, 0.15, 0), Color("#c8b18f"), 7 if reduced else 16, 1.06, Vector3(0, 0.28, 0))
	debris.emission_box_extents = Vector3(1.65, 0.14, 1.12)
	debris.initial_velocity_min = 0.65
	debris.initial_velocity_max = 1.65
	debris.one_shot = true
	debris.explosiveness = 0.92
	debris.finished.connect(debris.queue_free)
	debris.restart()
	var glow := Art.light_pool(self, at + Vector3(0, 0.036, 0), Vector2(1.50, 1.50),
		Color("#ffe1a8"), 0.86)
	var flash := glow.create_tween().set_parallel()
	flash.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	flash.tween_property(glow, "scale", Vector3(10.0, 1.0, 8.0), 0.69)
	flash.tween_method(func(alpha: float) -> void:
		(glow.material_override as ShaderMaterial).set_shader_parameter("intensity", alpha),
		0.86, 0.0, 0.91)
	flash.chain().tween_callback(glow.queue_free)
	if reduced:
		confetti(at, Color("#ffcf75"), 15)
	else:
		confetti(at, Color("#ffcf75"), 26)
		confetti(at + Vector3(1.35, 0, 0), Color("#72c8ad"), 22)

func confetti(at: Vector3, tint: Color, count: int) -> void:
	var tile := BoxMesh.new()
	tile.size = Vector3(0.12, 0.018, 0.064)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	tile.material = material
	var burst := emitter(at + Vector3(0, 0.35, 0), tint, count, 1.23, tile)
	burst.one_shot = true
	burst.explosiveness = 0.98
	burst.direction = Vector3.UP
	burst.spread = 56.0
	burst.initial_velocity_min = 3.0
	burst.initial_velocity_max = 5.6
	burst.angular_velocity_min = -130.0
	burst.angular_velocity_max = 230.0
	burst.gravity = Vector3(0, -5.7, 0)
	burst.finished.connect(burst.queue_free)
	burst.restart()
