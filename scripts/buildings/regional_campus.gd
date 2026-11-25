extends Node3D

const Art = preload("res://scripts/art/visual_library.gd")
const Kit = preload("res://scripts/buildings/model_kit.gd")
const Car = preload("res://scenes/vehicles/compact.tscn")
const Commerce = preload("res://scripts/economy/regional_commerce.gd")
const THRESHOLDS := [1, 12, 30, 60, 90]
const SIGNS := {
	"valley": {"restaurant": ["ORCHARD TABLE", 2.76, 3.34, 4.05], "workshop": ["MILL & MOTOR", 2.76, 3.34, 4.05],
		"market": ["GREENBANK", 2.76, 3.34, 4.05]},
	"alpine": {"restaurant": ["EMBER HEARTH", 2.76, 3.34, 4.39], "motel": ["SNOWLINE LODGE", 2.60, 3.99, 5.86],
		"parking": ["GLACIER VIEW", 2.97, 2.18, 3.84]},
	"ocean": {"restaurant": ["TIDAL ROOM", 3.23, 2.50, 3.54], "motel": ["CORAL KEY", 4.73, 2.50, 5.04],
		"vip_park": ["MARINA VIP", 2.97, 2.18, 3.24], "wash": ["PEARL BAY", 3.03, 2.50, 3.38]},
	"metro": {"logistics": ["MERIDIAN FREIGHT", 4.55, 4.22, 5.77], "warehouse": ["JUNCTION WAREHOUSE", 4.00, 4.56, 5.23],
		"dealership": ["APEX MOTORS", 3.67, 3.21, 4.20], "mall": ["CROSSLINE", 4.42, 3.27, 4.96],
		"charge": ["PULSE PLAZA", 2.97, 2.18, 3.23], "truck_park": ["FREIGHT EXCHANGE", 4.79, 2.18, 5.04]},
}

var routes: RefCounted
var buildings: Dictionary = {}
var plots: Dictionary = {}
var upgrades: Dictionary = {}
var roof_counts: Dictionary = {}
var cargo: Dictionary = {}
var pallets: Dictionary = {}
var docks: Dictionary = {}
var stage_lamps: Dictionary = {}
var display_cars: Array[Node3D] = []
var stock_models: Array[String] = []

func _init(course: RefCounted) -> void:
	routes = course

func _ready() -> void:
	var region: String = routes.district
	for id in routes.layout.plots:
		var at: Vector3 = routes.origin(id)
		roof_counts[id] = 0
		upgrades[id] = []
		for stage in range(1, 5):
			var fixture := Art.place(self, "regions", "%s_%s_%d" % [region, id, stage], at)
			fixture.hide()
			upgrades[id].append(fixture)
		if id == "fuel":
			continue
		var venue := Art.place(self, "regions", region + "_" + id, at)
		venue.hide()
		var sign_data: Array = SIGNS[region][id]
		var title_height := .30 if sign_data[0].length() < 14 else .23
		Art.sign(venue, Vector3(0, sign_data[1], sign_data[2]), sign_data[0], title_height, Color("#fff0d1"))
		Art.contact(venue, Vector3(0, -.014, -.45), 18.9 if routes.lane_of(id) == "truck" else 10.02, 6.04)
		buildings[id] = venue
		var parcel := Node3D.new()
		parcel.position = at
		add_child(parcel)
		var stakes := Art.place(parcel, "desert", "upgrade_storage", Vector3(.2, 0, -.1))
		stakes.scale = Vector3(.8, .8, .8)
		Art.place(parcel, "desert", "barrier", Vector3(1.40, 0, 2.30), .14)
		Art.place(parcel, "desert", "barrier", Vector3(-1.14, 0, 2.11), -.16)
		plots[id] = parcel
		if id in ["logistics", "warehouse"]:
			setup_freight(id)
		if id in ["mall", "dealership", "charge"]:
			setup_counters(id)

func setup_freight(id: String) -> void:
	var root: Node3D = buildings[id]
	var origin: Vector3 = routes.origin(id)
	var tint := Color("#73949c") if id == "warehouse" else Color("#a28c75")
	cargo[id] = []
	docks[id] = []
	pallets[id] = []
	var count := 3 if id == "logistics" else 2
	for index in count:
		var bay: Vector3 = routes.position_of(id, index) - origin
		var dock := Kit.box(root, Vector3(bay.x, 1.51, 4.22), Vector3(3.57, 2.72, .12), tint)
		for stripe in range(6):
			Kit.box(dock, Vector3(0, -.98 + stripe * .385, .077), Vector3(3.52, .032, .043), Color("#adbac0"))
		if index >= 2:
			dock.position.z -= .52
		docks[id].append(dock)
		var load := Art.place(root, "landscape", "parcel_carton", bay + Vector3(0, .40, .6))
		load.scale = Vector3.ONE * 1.57
		load.hide()
		cargo[id].append(load)
	for index in 8:
		var x := -4.1 if index < 4 else 4.29
		var part := Art.place(root, "landscape", "parcel_carton",
			Vector3(x + float(index % 2) * .70, .10 + .45 * float((index % 4) / 2), -4.90))
		part.scale = Vector3.ONE * 1.30
		pallets[id].append(part)

func setup_counters(id: String) -> void:
	var root: Node3D = buildings[id]
	if id == "dealership":
		for index in 2:
			var mount := Node3D.new()
			root.add_child(mount)
			mount.position = Vector3((index * 2 - 1) * 5.66, .31, .22)
			display_cars.append(mount)
			stock_models.append("")
	var count := 3 if id == "mall" else 2
	var group: Array[MeshInstance3D] = []
	for i in count:
		var stop: Vector3 = routes.position_of(id, i) - routes.origin(id)
		var surface := StandardMaterial3D.new()
		surface.albedo_color = Color("#89aba6")
		surface.emission = Color("#8bf4d4")
		var lamp := Kit.box(root, Vector3(stop.x, 1.43, 3.33), Vector3(.54, .13, .085), surface.albedo_color)
		lamp.material_override = surface
		group.append(lamp)
	stage_lamps[id] = group

func focus(id: String) -> Vector3:
	var at: Vector3 = routes.origin(id)
	return at.lerp(routes.position_of(id, 0), .35)

func pin_at(id: String) -> Vector3:
	var height: float = 3.93 if id == "fuel" else SIGNS[routes.district][id][3]
	return routes.origin(id) + Vector3(0, height + .48, .80)

func update_sites(economy: HbtEconomy) -> void:
	for id in routes.layout.plots:
		var level := economy.level(id)
		if id != "fuel":
			buildings[id].visible = level > 0
			plots[id].visible = level == 0
		var stage := 0
		for line in THRESHOLDS:
			stage += int(level >= line)
		roof_counts[id] = stage
		for i in 4:
			upgrades[id][i].visible = i + 1 < stage

func animate_install(id: String, previous: int) -> void:
	if previous == 0 and id in buildings:
		Art.settle(buildings[id])
	for i in range(maxi(0, previous - 1), maxi(0, roof_counts[id] - 1)):
		Art.settle(upgrades[id][i])

func hose_anchor(visit: HbtVisit) -> Vector3:
	return routes.position_of(visit.service, visit.bay) + Vector3(1.83, 1.09, -.52)

func update_chargers(dispatch: HbtDispatch) -> void:
	for id in cargo:
		if not buildings[id].visible:
			continue
		update_docks(id, dispatch)
		var stock := int(dispatch.economy.commerce.record(id).stock)
		for i in pallets[id].size():
			pallets[id][i].visible = i < stock
	for id in stage_lamps:
		for i in stage_lamps[id].size():
			var lamp: MeshInstance3D = stage_lamps[id][i]
			lamp.visible = i < dispatch.economy.capacity(id)
			var task := dispatch.visit_at(id, i)
			lamp.material_override.emission_enabled = task != null and task.phase == HbtVisit.Phase.WORKING
	if not display_cars.is_empty() and buildings.dealership.visible:
		update_showroom(dispatch.economy)

func update_docks(id: String, dispatch: HbtDispatch) -> void:
	var root: Node3D = buildings[id]
	for index in cargo[id].size():
		var task := dispatch.visit_at(id, index)
		var active := task != null and task.phase == HbtVisit.Phase.WORKING and not task.trade.is_empty()
		var package: Node3D = cargo[id][index]
		var door: Node3D = docks[id][index]
		door.visible = index < dispatch.economy.capacity(id)
		door.position.y = lerpf(door.position.y, 3.36 if active else 1.51, .10)
		package.visible = active
		if active:
			var truck := task.location - root.position + Vector3(0, .75, 1.72)
			var stack := Vector3(truck.x, .41, 4.78)
			var path := smoothstep(.15, .91, task.progress())
			package.position = truck.lerp(stack, path) if task.trade == "inbound" else stack.lerp(truck, path)

func update_showroom(economy: HbtEconomy) -> void:
	var inventory := economy.commerce.record("dealership")
	for i in display_cars.size():
		var preview := display_cars[i]
		preview.visible = i < int(inventory.stock)
		var model: String = Commerce.SHOWROOM_MODELS[(int(inventory.sold) + i) % Commerce.SHOWROOM_MODELS.size()]
		if preview.visible and model != stock_models[i]:
			for child in preview.get_children():
				preview.remove_child(child)
				child.queue_free()
			var turn := Car.instantiate()
			preview.add_child(turn)
			turn.build(model, i, false, routes.district)
			turn.rotation.y = .62 * (1 - 2 * i)
			turn.scale = Vector3.ONE * .79
			stock_models[i] = model
