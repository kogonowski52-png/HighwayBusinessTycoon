extends RefCounted
## Instances keep their source mesh, material, color and transform. Cells keep culling local to the camera.

const CELL := 33.0
const FINISHES = preload("res://assets/materials/vertex_finishes.gdshader")
const CONTACT = preload("res://assets/materials/contact.gdshader")
static var unit_box: BoxMesh

static func instances(parent: Node3D, mesh: Mesh, poses: Array[Transform3D], material: Material = null,
		shadow := GeometryInstance3D.SHADOW_CASTING_SETTING_ON, cell_width := CELL) -> void:
	if poses.size() <= 18 and is_equal_approx(cell_width, CELL):
		add_batch(parent, mesh, poses, material, shadow)
		return
	var cells := {}
	for pose in poses:
		var key := cell_at(pose.origin, cell_width)
		if not cells.has(key):
			var group: Array[Transform3D] = []
			cells[key] = group
		cells[key].append(pose)
	for group: Array[Transform3D] in cells.values():
		add_batch(parent, mesh, group, material, shadow)

static func compact(parent: Node3D, require_visible := true, opaque_shader: Shader = null) -> void:
	var groups := {}
	if unit_box == null:
		unit_box = BoxMesh.new()
		unit_box.size = Vector3.ONE
	var inverse := parent.global_transform.affine_inverse()
	for found: Node in parent.find_children("*", "MeshInstance3D", true, false):
		var part := found as MeshInstance3D
		if (require_visible and not part.is_visible_in_tree()) or not batchable(part, opaque_shader):
			continue
		var local := inverse * part.global_transform
		var override := part.material_override
		var shape := part.mesh
		if shape is BoxMesh and shape.subdivide_width == 0 and shape.subdivide_height == 0 and shape.subdivide_depth == 0:
			local.basis = local.basis.scaled_local(shape.size)
			shape = unit_box
		var key := [shape.get_instance_id(), override.get_instance_id() if override else 0,
			part.cast_shadow, cell_at(local.origin)]
		if not groups.has(key):
			groups[key] = {"mesh": shape, "parts": [], "poses": [] as Array[Transform3D]}
		groups[key].parts.append(part)
		groups[key].poses.append(local)
	for group: Dictionary in groups.values():
		if group.parts.size() < 3:
			continue
		var first: MeshInstance3D = group.parts[0]
		add_batch(parent, group.mesh, group.poses, first.material_override, first.cast_shadow)
		for part: MeshInstance3D in group.parts:
			part.hide()
			part.queue_free()

static func batchable(part: MeshInstance3D, opaque_shader: Shader = null) -> bool:
	if part.mesh == null or part.get_child_count() > 0 or part.skin != null or part.material_overlay != null \
			or part.visibility_range_begin != 0.0 or part.visibility_range_end != 0.0 or part.layers != 1:
		return false
	if part.material_override != null:
		# All contact stamps use the same tint and blend. Their world transforms and UV remain independent.
		return opaque(part.material_override) or (part.material_override is ShaderMaterial and
			part.material_override.shader in [CONTACT, opaque_shader])
	for surface in part.mesh.get_surface_count():
		if part.get_surface_override_material(surface) != null or not opaque(part.mesh.surface_get_material(surface)):
			return false
	return true

static func opaque(material: Material) -> bool:
	if material is ShaderMaterial and material.shader == FINISHES:
		return true
	return material is BaseMaterial3D and material.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED \
		and material.billboard_mode == BaseMaterial3D.BILLBOARD_DISABLED and material.next_pass == null

static func cell_at(at: Vector3, cell_width := CELL) -> Vector2i:
	return Vector2i(floori(at.x / cell_width), floori(at.z / cell_width))

static func add_batch(parent: Node3D, mesh: Mesh, poses: Array[Transform3D], material: Material,
		shadow: GeometryInstance3D.ShadowCastingSetting) -> void:
	if poses.is_empty():
		return
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = mesh
	instances.instance_count = poses.size()
	for i in poses.size():
		instances.set_instance_transform(i, poses[i])
	# Include the travel of animated vegetation in its culling bounds.
	instances.custom_aabb = instances.get_aabb().grow(.75)
	var batch := MultiMeshInstance3D.new()
	batch.multimesh = instances
	batch.material_override = material
	batch.cast_shadow = shadow
	parent.add_child(batch)
