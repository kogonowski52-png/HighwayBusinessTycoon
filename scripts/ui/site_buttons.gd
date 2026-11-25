extends CanvasLayer

const Building = preload("res://scripts/buildings/roadside_campus.gd")
const Desert = preload("res://scripts/buildings/desert_campus.gd")
const ELEVATION := {"fuel": 4.55, "market": 3.6, "parking": 2.9, "wash": 3.5, "truck": 5.7,
	"workshop": 4.2, "restaurant": 3.6, "tires": 3.55, "truck_park": 3.12, "motel": 4.7, "charge": 2.12}

var controller: Node3D
var hud: CanvasLayer
var root := Control.new()
var buttons: Dictionary = {}
var active: Dictionary = {}

func bind_to(game: Node3D) -> void:
	controller = game
	hud = controller.hud
	layer = 2
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for id in game.economy.facilities:
		var pin: Button = hud.action(root, 114, 105, false)
		hud.button_art(pin, hud.NAV.sites, 73)
		pin.pressed.connect(open_site.bind(id))
		pin.hide()
		buttons[id] = pin

func open_site(id: String) -> void:
	var selected: String = controller.selected
	controller.select_site(id)
	if selected == id or active.get(id, false):
		controller.open_page("upgrades")

func refresh() -> void:
	var store: HbtEconomy = controller.economy
	for id in buttons:
		var tier := store.level(id)
		var is_ready: bool = store.quote_upgrade(id, 1).affordable if tier > 0 else store.gate_open(id) \
			and store.can_afford(HbtAmount.from(store.facilities[id].unlock_cost))
		if active.get(id) != is_ready:
			var pin: Button = buttons[id]
			pin.add_theme_stylebox_override("normal", hud.sculpted(hud.UPGRADE if is_ready else hud.CREAM_BUTTON, 36, 10))
			pin.icon = hud.UPGRADE_ART if is_ready else hud.ROAD
		active[id] = is_ready
		buttons[id].tooltip_text = controller.site_name(id) + " · " + controller.t("site_upgrade_pin" if is_ready else "site_focus_pin")

func _process(_delta: float) -> void:
	if controller == null:
		return
	var obscured: bool = not controller.mounted or not hud.visible or controller.operations.modal_open() \
		or not controller.camera_rig.film.is_empty()
	var lens: Camera3D = controller.camera
	var selected: String = controller.selected
	var order: Array = [selected]
	if controller.overview:
		order.append_array(buttons.keys().filter(func(key: String) -> bool: return key != selected))
	var occupied: Array[Rect2] = []
	if obscured:
		for id in buttons:
			buttons[id].hide()
		return
	var shown := {}
	for id in order:
		if controller.economy.level(id) == 0 and not active.get(id, false) and id != selected:
			continue
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
	for id in buttons:
		buttons[id].visible = shown.has(id)

func world_anchor(id: String) -> Vector3:
	if controller.is_desert():
		return controller.campus.focus(id) + Vector3(0, float(Desert.ROOFLINE[id]) + 0.26, -1.26)
	if Building.ROOFS.has(id):
		return Building.ROOFS[id][0] + Vector3.UP * float(ELEVATION[id])
	return Vector3(1.13, float(ELEVATION[id]), 0.53)
