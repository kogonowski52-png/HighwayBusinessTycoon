@tool
extends EditorScenePostImport

const PRACTICAL = preload("res://assets/materials/practical.gdshader")

var practical: ShaderMaterial

func _post_import(scene: Node) -> Object:
	practical = ShaderMaterial.new()
	practical.shader = PRACTICAL
	practical.resource_name = "Practical fixture"
	var asset := get_source_file().get_file().get_basename()
	practical.set_shader_parameter("beacon", asset in ["price_sign", "service_lantern"])
	color_surfaces(scene)
	return scene

func color_surfaces(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh: Mesh = node.mesh
		for surface in range(mesh.get_surface_count()):
			var material := mesh.surface_get_material(surface) as StandardMaterial3D
			if material == null or mesh.surface_get_format(surface) & Mesh.ARRAY_FORMAT_COLOR == 0:
				continue
			# The first glTF primitive can lose this flag when its material is shared.
			material.vertex_color_use_as_albedo = true
			if material.resource_name == "Light":
				mesh.surface_set_material(surface, practical)
	for child in node.get_children():
		color_surfaces(child)
