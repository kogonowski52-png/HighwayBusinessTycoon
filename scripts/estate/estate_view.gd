extends Node3D

const Art = preload("res://scripts/art/visual_library.gd")
const Kit = preload("res://scripts/buildings/model_kit.gd")
const Catalog = preload("res://data/estate/complex_design.gd")
const Depot = preload("res://scripts/logistics/depot_view.gd")
const Agency = preload("res://data/world/regions.gd")
const PAINT := ["facade", "roof", "canopy"]
const VEGETATION := [
	["regions","tropical_foliage"], ["desert","agave"], ["regions","alpine_foliage"], ["regions","japan_foliage"], ["landscape","broadleaf"],
]
const LOCATIONS := {
	"sign": Vector3(-5.2, 0, 2.9), "lights": Vector3(1.3,0,-2.27), "fence": Vector3(3.9,0,-3.7),
	"paving": Vector3(-4.34,0,.34), "plants": Vector3(4.1,0,2.9), "planter": Vector3(-2.18,0,2.5),
	"bench": Vector3(.28,0,2.1), "fountain": Vector3(3.7,0,-.3), "billboard": Vector3(-4.0,0,-3.15),
}
const WHITE := Color("#e9dfbb")
const TEAL := Color("#4a857a")
const CARBON := Color("#353f42")
const AMBER := Color("#e8ae64")

var game: Node3D
var scene_parts: Node3D
var upgrades: Node3D
var tint_stamp := ""
var decor_stamp := ""
var infra_stamp := ""
var original := {}
var preview := {}
var about := Vector3.ZERO

func bind(owner: Node3D) -> void:
	game = owner
	about = Depot.yard_position(game.economy.district) + Vector3(0, .12, 8.6)
	scene_parts = Node3D.new()
	scene_parts.position = about
	add_child(scene_parts)
	upgrades = Node3D.new()
	add_child(upgrades)

func refresh() -> void:
	var estate: HbtEconomy = game.economy
	var choices: Dictionary = estate.works.designs.duplicate()
	choices.merge(preview, true)
	var style := str(choices)
	if style != decor_stamp:
		decor_stamp = style
		rebuild(choices)
	var main := structure()
	var finish := str([main.get_instance_id(), choices.get("facade",0), choices.get("roof",0), choices.get("canopy",0)]) if main != null else ""
	if finish != tint_stamp:
		tint_stamp = finish
		repaint(main, choices)
	var state := str(estate.works.levels)
	if state != infra_stamp:
		infra_stamp = state
		rebuild_works(estate.works.levels)

func structure() -> Node3D:
	if game.economy.district == "desert":
		return game.station.canopy
	if game.is_regional():
		return game.station.building
	return game.station.structure

func rebuild(choices: Dictionary) -> void:
	clear(scene_parts)
	if not choices.keys().any(func(id: String) -> bool: return id not in PAINT and int(choices[id]) > 0):
		return
	var patio := Kit.box(scene_parts, Vector3(0,-.04,0), Vector3(12.9,.18,8.1), Color("#7daba3"))
	patio.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Kit.box(scene_parts, Vector3(0,-.01,0), Vector3(12.63,.16,7.91), Color("#b6bca1")).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for key: String in choices:
		var variant: int = choices[key]
		if key in PAINT or variant == 0:
			continue
		add_prop(scene_parts, key, variant, LOCATIONS[key])

static func add_prop(parent: Node3D, key: String, variant: int, position: Vector3) -> Node3D:
	if key == "plants":
		return plant(parent, variant, position)
	var item := Art.place(parent, "estates", "%s_%d" % [key, variant], position)
	if key in ["sign", "billboard"]:
		var poster: String = ["PALMWATER", "ROUTE 17", "GREEN VALLEY", "AKARI CIRCUIT", "COPPER SPUR"][variant - 1]
		var scale := 1.72 if key == "billboard" else 1.0
		Art.sign(item, Vector3(0, 1.84 * scale,.205), poster, .17 * scale, Color("#fff0cb"))
	return item

static func plant(parent: Node3D, variant: int, position: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = position
	parent.add_child(root)
	# Existing region foliage has baked contact tones and instanced trunks.
	var preferred: Array = VEGETATION[variant - 1]
	var family: String = preferred[0]
	var identity: String = preferred[1]
	if not ResourceLoader.exists("res://assets/models/%s/%s.glb" % [family, identity]):
		match variant:
			1:
				family = "regions"
				identity = "tropical_palm"
			3:
				family = "landscape"
				identity = "fir"
			4:
				family = "regions"
				identity = "japan_blossom"
	var exact := "res://assets/models/%s/%s.glb" % [family, identity]
	if not ResourceLoader.exists(exact):
		family = "desert"
		identity = ["saguaro","agave","saguaro","agave","agave"][variant - 1]
	for i in 3:
		var point := Vector3((i - 1.0) * .83, 0, (i % 2) * .44)
		Art.place(root, family, identity, point, .4 * i).scale = Vector3.ONE * (.43 + i * .12)
	return root

func clear(node: Node) -> void:
	for part in node.get_children():
		node.remove_child(part)
		part.queue_free()

func repaint(model: Node3D, choices: Dictionary) -> void:
	if model == null:
		return
	var painted := PAINT.any(func(key: String) -> bool: return int(choices.get(key, 0)) > 0)
	for part: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		var code := part.get_instance_id()
		if original.has(code):
			part.mesh = original[code]
		if not painted or not part.mesh is ArrayMesh:
			continue
		if not original.has(code):
			original[code] = part.mesh
		part.mesh = dyed(part.mesh, choices)

static func dyed(source: ArrayMesh, choices: Dictionary) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var height := maxf(.01, source.get_aabb().size.y)
	var base := source.get_aabb().position.y
	var depth := maxf(.01, source.get_aabb().size.z)
	var front := source.get_aabb().position.z
	for surface in source.get_surface_count():
		var material := source.surface_get_material(surface)
		var arrays := source.surface_get_arrays(surface)
		var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: Variant = arrays[Mesh.ARRAY_NORMAL]
		var opaque := material is BaseMaterial3D or (material is ShaderMaterial and material.resource_name == "Packed surface finishes")
		if opaque and arrays[Mesh.ARRAY_COLOR] is PackedColorArray and normals is PackedVector3Array:
			var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
			for i in points.size():
				var y := (points[i].y - base) / height
				var z := (points[i].z - front) / depth
				var key := "canopy" if y > .62 and z > .47 else "roof" if y > .62 else "facade" if y > .22 and absf(normals[i].y) < .55 else ""
				var variant := int(choices.get(key, 0))
				if variant > 0:
					var coat := Color(Catalog.PALETTE[variant - 1]).srgb_to_linear()
					colors[i] = colors[i].lerp(coat * (.62 + colors[i].get_luminance() * .68), .73)
					colors[i].a = 1.0
			arrays[Mesh.ARRAY_COLOR] = colors
		mesh.add_surface_from_arrays(source.surface_get_primitive_type(surface), arrays, [], surface_lods(source, surface))
		mesh.surface_set_material(surface, material)
	return mesh

static func surface_lods(mesh: ArrayMesh, surface: int) -> Dictionary:
	var info := RenderingServer.mesh_get_surface(mesh.get_rid(), surface)
	var result := {}
	for lod: Dictionary in info.get("lods", []):
		var packed: PackedByteArray = lod.index_data
		var indices: PackedInt32Array
		if int(info.vertex_count) > 65535:
			indices = packed.to_int32_array()
		else:
			indices.resize(packed.size() / 2)
			for i in indices.size():
				indices[i] = packed.decode_u16(i * 2)
		result[lod.edge_length] = indices
	return result

func rebuild_works(levels: Dictionary) -> void:
	clear(upgrades)
	if levels.is_empty():
		return
	var depot := Depot.yard_position(game.economy.district)
	var direction: float = (1.0 if game.economy.district in ["north","desert","ocean","tropical"] else -1.0)
	for id: String in levels:
		var stage: int = int(levels[id])
		var node := Node3D.new()
		var shift: Vector3
		match id:
			"roads": shift = Vector3(.6,.16,4.95)
			"entry": shift = Vector3(-6.6,.16,3.07)
			"exit": shift = Vector3(7.0,.16,3.06)
			"junction": shift = Vector3(8.28,.16,5.42)
			"roundabout": shift = Vector3(10.18,.16,8.19)
			"parking": shift = Vector3(-3.65,.17,.02)
			"bays": shift = Vector3(1.0,.16,.24)
			"signals": shift = Vector3(-6.46,.16,2.45)
			"walkways": shift = Vector3(2.4,.17,6.37)
			"lamps": shift = Vector3(0,.16,6.81)
		node.position = depot + Vector3(shift.x, shift.y, shift.z * direction)
		node.set_meta("work", id)
		upgrades.add_child(node)
		build_art(node, id, stage)

static func slab(root: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var shape := Kit.box(root, at, size, color)
	shape.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return shape

static func build_art(node: Node3D, id: String, stage: int) -> void:
	match id:
		"roads":
			slab(node,Vector3(0,.02,0),Vector3(11.6+stage*2.2,.079,3.08),CARBON)
			for i in range(-3, 4):
				slab(node,Vector3(i*1.80,.065,0),Vector3(.91,.016,.096),WHITE)
		"entry","exit":
			var sign := "IN" if id == "entry" else "OUT"
			for z in [-1.08,1.08]:
				Kit.cylinder(node,Vector3(0,.91,z),.095,.095,1.85,TEAL)
				Kit.cylinder(node,Vector3(0,1.57,z),.119,.119,.29,AMBER)
			var rail := Kit.box(node,Vector3(0,2.08,0),Vector3(.22,.25,2.41),TEAL)
			rail.scale.y += .11*stage
			Art.sign(node,Vector3(.14,2.05,0),sign,.22,WHITE).rotation.y = PI*.5
		"junction":
			for i in stage + 3:
				slab(node,Vector3(-1.38+i*.40,.041,0),Vector3(.21,.019,1.81),WHITE)
			for end in [-1,1]:
				Kit.cylinder(node,Vector3(end*1.64,.23,.82),.13,.13,.46,AMBER)
		"roundabout":
			Kit.cylinder(node,Vector3.ZERO,1.00+.23*stage,1.07+.24*stage,.205,TEAL,24)
			Kit.cylinder(node,Vector3(0,.14,0),.71+.19*stage,.70+.19*stage,.19,Color("#85a178"),24)
			for i in 8:
				var point := Vector2.from_angle(TAU*i/8.0) * (1.22+stage*.23)
				Kit.cylinder(node,Vector3(point.x,.15,point.y),.076,.08,.24,WHITE)
		"parking","bays":
			var count := 2 + stage
			for i in count:
				slab(node,Vector3((i-(count-1)*.5)*1.42,.07,0),Vector3(.048,.020,2.71),WHITE)
				slab(node,Vector3((i-(count-1)*.5)*1.42,.069,-1.43),Vector3(.76,.024,.096),TEAL)
		"signals":
			Kit.cylinder(node,Vector3(0,.83,0),.081,.081,1.67,TEAL)
			Kit.box(node,Vector3(0,1.71,0),Vector3(.31,.62,.28),CARBON)
			for i in 3:
				Kit.cylinder(node,Vector3(0,1.49+i*.17,.16),.083,.083,.086,
					[Color("#70ba93"),AMBER,Color("#e08161")][i],12).rotation.x = PI*.5
		"walkways":
			for i in range(-6,7):
				slab(node,Vector3(i*.62,.027,0),Vector3(.599,.11,1.09+stage*.20),Color("#d5cbb0"))
			for i in [-2,2]:
				Kit.cylinder(node,Vector3(i,.26,.74),.084,.084,.5,TEAL)
		"lamps":
			for i in stage + 1:
				var x := -4.0+2.651*i
				Kit.cylinder(node,Vector3(x,1.27,0),.071,.071,2.54,CARBON)
				Kit.box(node,Vector3(x,2.58,.21),Vector3(.36,.17,.62),TEAL)
				Art.light_pool(node,Vector3(x,.032,.21),Vector2(2.73,2.42),AMBER,.64)
