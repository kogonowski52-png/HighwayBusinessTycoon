extends RefCounted

static var materials: Dictionary = {}

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
	var shape := BoxMesh.new()
	shape.size = size
	return mesh(parent, shape, pos, tint)

static func cylinder(parent: Node3D, pos: Vector3, base: float, tip: float, length: float, tint: Color, sides := 12) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.bottom_radius = base
	shape.top_radius = tip
	shape.height = length
	shape.radial_segments = sides
	shape.rings = 0
	return mesh(parent, shape, pos, tint)

static func beam(parent: Node3D, start: Vector3, end: Vector3, radius: float, tint: Color) -> void:
	var delta := end - start
	var part := cylinder(parent, (start + end) / 2.0, radius, radius, delta.length(), tint, 8)
	part.quaternion = Quaternion(Vector3.UP, delta.normalized())

static func sign_text(parent: Node3D, pos: Vector3, content: String, size: float, tint: Color) -> void:
	var sign := Label3D.new()
	sign.position = pos
	sign.text = content
	sign.font_size = 96
	sign.pixel_size = size / 96.0
	sign.outline_size = 0
	sign.modulate = tint
	parent.add_child(sign)

# Four corners per ring, with an independent width and length at each height.
static func loft(parent: Node3D, rings: Array[Vector4], tint: Color) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vertices := PackedVector3Array()
	for ring in rings:
		for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
			vertices.append(Vector3(corner.x * ring.y, ring.x, ring.w + corner.y * ring.z))
	for i in range(rings.size() - 1):
		for j in range(4):
			var a := i * 4 + j
			var b := i * 4 + (j + 1) % 4
			for index in [a, b, b + 4, a, b + 4, a + 4]:
				surface.add_vertex(vertices[index])
	var top := vertices.size() - 4
	for index in [top, top + 1, top + 2, top, top + 2, top + 3]:
		surface.add_vertex(vertices[index])
	surface.generate_normals()
	mesh(parent, surface.commit(), Vector3.ZERO, tint)
