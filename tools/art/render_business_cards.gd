extends SceneTree
## Rasterize the original building meshes for the investment directory.

const Art = preload("res://scripts/art/visual_library.gd")
const Atlas = preload("res://data/world/atlas.gd")
const NORTH_MODELS := {"fuel": "canopy_rehab", "market": "market", "wash": "wash", "restaurant": "restaurant",
	"workshop": "workshop", "motel": "motel", "parking": "parking", "truck": "truck_canopy",
	"tires": "tire_shop", "charge": "ev_lounge", "truck_park": "freight_office"}

func _initialize() -> void:
	render_all.call_deferred()

func render_all() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	var folder := "res://assets/ui/business"
	var bounds_path := "res://data/visual/business_bounds.gd"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			folder = argument.trim_prefix("--output=")
		elif argument.begins_with("--bounds="):
			bounds_path = argument.trim_prefix("--bounds=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var file := FileAccess.open(bounds_path, FileAccess.WRITE)
	if file == null:
		quit(1)
		return
	file.store_line("extends RefCounted\n\n# Generated from the original venue meshes by tools/art/render_business_cards.gd.")
	file.store_line("const BOXES := {")
	var view := SubViewport.new()
	view.size = Vector2i(256, 256)
	view.own_world_3d = true
	view.transparent_bg = true
	view.msaa_3d = Viewport.MSAA_4X
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var studio := Node3D.new()
	view.add_child(studio)
	var ambient := WorldEnvironment.new()
	ambient.environment = Environment.new()
	ambient.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambient.environment.ambient_light_color = Color("#c6dfed")
	ambient.environment.ambient_light_energy = .42
	studio.add_child(ambient)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -34, 0)
	sun.light_color = Color("#ffe5bb")
	sun.light_energy = .92
	studio.add_child(sun)
	var lens := Camera3D.new()
	lens.projection = Camera3D.PROJECTION_ORTHOGONAL
	lens.current = true
	studio.add_child(lens)
	for district: String in Atlas.DESTINATIONS:
		var store := HbtEconomy.new(district)
		for site: String in store.facilities:
			var family := "architecture" if district == "north" else "desert" if district == "desert" else "regions"
			var key: String = NORTH_MODELS[site] if district == "north" else ("copper_mile" if site == "fuel" else site) \
				if district == "desert" else district + "_" + site
			var model := Art.place(studio, family, key)
			var bounds := AABB()
			for part: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
				var volume: AABB = part.global_transform * part.get_aabb()
				bounds = volume if not bounds.has_surface() else bounds.merge(volume)
			if not bounds.has_surface():
				push_error("No mesh for %s/%s" % [district, site])
				quit(1)
				return
			var id := district + "_" + site
			file.store_line('\t"%s": AABB(Vector3(%.3f, %.3f, %.3f), Vector3(%.3f, %.3f, %.3f)),' % [id, bounds.position.x, bounds.position.y,
				bounds.position.z, bounds.size.x, bounds.size.y, bounds.size.z])
			lens.size = maxf(1.2, bounds.size.length() * 1.045)
			lens.position = bounds.get_center() + Vector3(9.4, 8.7, 14.5)
			lens.look_at(bounds.get_center())
			for _frame in 3:
				await RenderingServer.frame_post_draw
			var image := view.get_texture().get_image()
			var silhouette := image.get_used_rect().grow(6).intersection(Rect2i(Vector2i.ZERO, image.get_size()))
			if not silhouette.has_area() or image.get_region(silhouette).save_png(folder.path_join(id + ".png")) != OK:
				push_error("Could not save " + id)
				quit(1)
				return
			model.free()
	file.store_line("}")
	file.close()
	print("Rendered business art for every location")
	quit()
