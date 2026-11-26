extends RefCounted

static var materials: Dictionary = {}
static var boxes: Dictionary = {}
static var cylinders: Dictionary = {}

static func material(color: Color) -> StandardMaterial3D:
	if not materials.has(color):
		var surface := StandardMaterial3D.new()
		surface.albedo_color = color
		surface.roughness = 0.78
		materials[color] = surface
	return materials[color]

static func mesh(parent: Node3D, shape: Mesh, pos: Vector3, tint: Color) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = shape
	part.material_override = material(tint)
	part.position = pos
	parent.add_child(part)
	return part

static func box(parent: Node3D, pos: Vector3, size: Vector3, tint: Color) -> MeshInstance3D:
	if not boxes.has(size):
		var shape := BoxMesh.new()
		shape.size = size
		boxes[size] = shape
	return mesh(parent, boxes[size], pos, tint)

static func cylinder(parent: Node3D, pos: Vector3, base: float, tip: float, length: float, tint: Color, sides := 12) -> MeshInstance3D:
	var key := Vector4(base, tip, length, sides)
	if not cylinders.has(key):
		var shape := CylinderMesh.new()
		shape.bottom_radius = base
		shape.top_radius = tip
		shape.height = length
		shape.radial_segments = sides
		shape.rings = 0
		cylinders[key] = shape
	return mesh(parent, cylinders[key], pos, tint)
