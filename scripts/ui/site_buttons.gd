extends CanvasLayer

const Building = preload("res://scripts/buildings/roadside_campus.gd")
const Station = preload("res://scripts/buildings/building_manager.gd")
const Desert = preload("res://scripts/buildings/desert_campus.gd")
const DesertRoutes = preload("res://data/world/desert_routes.gd")
const Geometry = preload("res://data/visual/business_bounds.gd")
const HAMMER = preload("res://assets/ui/business/hammer.png")
const LOCK = preload("res://assets/ui/business/locked.png")
const ELEVATION := {"fuel": 4.55, "market": 3.6, "parking": 2.9, "wash": 3.5, "truck": 5.7,
	"workshop": 4.2, "restaurant": 3.6, "tires": 3.55, "truck_park": 3.12, "motel": 4.7, "charge": 2.12}

var controller: Node3D
var hud: CanvasLayer
var root := Control.new()
var buttons: Dictionary = {}
var states: Dictionary = {}

func bind_to(game: Node3D) -> void:
	controller = game
	hud = controller.hud
	layer = 2
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for id in game.economy.facilities:
		var pin: Button = hud.action(root, 86, 83, false)
		pin.pressed.connect(controller.manage_site.bind(id))
		pin.hide()
		buttons[id] = pin

func refresh() -> void:
	var store: HbtEconomy = controller.economy
	for id: String in buttons:
		var tier := store.level(id)
		var quote := store.construction_quote(id) if tier == 0 else {}
		var state := "build" if tier == 0 and quote.ready else "locked" if tier == 0 \
			else "upgrade" if store.quote_upgrade(id, 1).affordable else "built"
		var pin: Button = buttons[id]
		var changed: bool = states.get(id) != state
		if changed:
			var tint: Texture2D = hud.ACTION if state == "build" else hud.UPGRADE if state == "upgrade" else hud.CREAM_BUTTON
			var skin: StyleBox = hud.style(Color("#dddccf"), Color("#929b91"), 20, 7) if state == "locked" else hud.sculpted(tint, 32, 8)
			for mode in ["normal", "hover", "pressed"]:
				pin.add_theme_stylebox_override(mode, skin)
			var picture: Texture2D = HAMMER if state == "build" else LOCK if state == "locked" else hud.UPGRADE_ART if state == "upgrade" else hud.ROAD
			hud.button_art(pin, picture, 48)
			for color_key in ["font_color", "font_hover_color", "font_pressed_color"]:
				pin.add_theme_color_override(color_key, hud.CREAM if state == "build" else hud.INK)
			pin.custom_minimum_size.x = 163 if state == "build" else 82
			states[id] = state
		var amount: String = controller.money(quote.cost) if state == "build" else ""
		if changed or pin.text != amount:
			pin.text = amount
			pin.reset_size()
		var description := "site_ready" if state == "build" else "site_closed" if state == "locked" \
			else "site_upgrade_pin" if state == "upgrade" else "site_manage"
		pin.tooltip_text = controller.site_name(id) + " · " + controller.t(description)

func _process(_delta: float) -> void:
	if controller == null:
		return
	if not controller.mounted or not hud.visible or controller.operations.visible or not controller.camera_rig.film.is_empty():
		for pin: Button in buttons.values():
			pin.hide()
		return
	var lens: Camera3D = controller.camera
	var selected: String = controller.selected
	var order: Array = buttons.keys().filter(func(id: String) -> bool: return states.get(id) == "build")
	if selected not in order:
		order.append(selected)
	for id: String in buttons:
		if id not in order and (controller.overview or states.get(id) == "locked"):
			order.append(id)
	var occupied: Array[Rect2] = []
	var shown := {}
	for id: String in order:
		var pin: Button = buttons[id]
		var target := world_anchor(id)
		var center := lens.unproject_position(target)
		var rect := Rect2(center - pin.size * 0.5, pin.size)
		if lens.is_position_behind(target) or not get_viewport().get_visible_rect().grow(-12.0).encloses(rect) \
			or hud.overlaps_world(rect) or occupied.any(func(other: Rect2) -> bool: return other.intersects(rect)):
			continue
		pin.position = rect.position
		shown[id] = true
		occupied.append(rect.grow(8.0))
	for id: String in buttons:
		buttons[id].visible = shown.has(id)

func tap_world(point: Vector2) -> bool:
	var lens: Camera3D = controller.camera
	var from := lens.project_ray_origin(point)
	var to := from + lens.project_ray_normal(point) * lens.far
	var best := INF
	var picked := ""
	for id: String in buttons:
		var hit: Variant = venue_bounds(id).intersects_segment(from, to)
		if hit is Vector3:
			var distance := from.distance_squared_to(hit)
			if distance < best:
				best = distance
				picked = id
	if picked.is_empty():
		return false
	controller.manage_site(picked)
	return true

func venue_bounds(id: String) -> AABB:
	var district: String = controller.economy.district
	var bounds: AABB = Geometry.BOXES[district + "_" + id]
	var origin: Vector3
	if controller.is_regional():
		origin = controller.routes.origin(id)
	elif controller.is_desert():
		origin = DesertRoutes.FRONTS[id] if id != "fuel" else controller.station.position
	else:
		origin = Station.CANOPY_AT if id == "fuel" else Building.ROOFS[id][0]
	bounds.position += origin
	if district != "north" and controller.economy.level(id) == 0:
		bounds.position.y = origin.y - .10
		bounds.size.y = .95
	return bounds.grow(.22)

func world_anchor(id: String) -> Vector3:
	if controller.economy.district != "north" and controller.economy.level(id) == 0:
		return venue_bounds(id).get_center() + Vector3.UP * 1.40
	if controller.is_regional():
		return controller.campus.pin_at(id)
	if controller.is_desert():
		return controller.campus.focus(id) + Vector3(0, float(Desert.ROOFLINE[id]) + 0.26, -1.26)
	if Building.ROOFS.has(id):
		return Building.ROOFS[id][0] + Vector3.UP * float(ELEVATION[id])
	return Vector3(1.13, float(ELEVATION[id]), 0.53)
