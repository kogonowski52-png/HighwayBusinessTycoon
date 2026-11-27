extends SubViewportContainer
## A single streamed inspection view. Animation reflects the ticket at the real service bay.

const Art = preload("res://scripts/art/visual_library.gd")
const Kit = preload("res://scripts/buildings/model_kit.gd")
const Actor = preload("res://scripts/customers/customer_manager.gd")
const Unit = preload("res://scenes/vehicles/compact.tscn")
const PLACE := {
	"market": ["market", "parts"],
	"workshop": ["workshop", "truck_service", "repair", "tuning", "restoration", "tires"],
	"restaurant": ["restaurant", "drive_through", "cafe", "food"],
	"wash": ["wash", "truck_wash", "detail"],
	"hotel": ["hotel", "motel", "resort"],
	"dealership": ["dealership", "showroom"],
	"mall": ["mall"],
	"warehouse": ["warehouse", "coldstore"],
	"logistics": ["logistics", "terminal", "distribution", "transport", "transfer", "logging", "haulage", "freight"],
}

var game: Node3D
var apartment := ""
var service := ""
var path := ""
var awaiting_model := false
var loaded := false
var failed := false
var viewport: SubViewport
var room: Node3D
var camera: Camera3D
var roof: Node3D
var attendant: Node3D
var guest: Node3D
var vehicle: Node3D
var display_model := ""
var package: Node3D
var brush: Node3D
var progress: Label

static func for_site(estate: HbtEconomy, id: String) -> String:
	if estate.level(id) <= 0:
		return ""
	for key: String in PLACE:
		if id in PLACE[key]:
			return key
	var kind: String = estate.facilities[id].venue_kind
	for key: String in PLACE:
		if kind in PLACE[key]:
			return key
	return ""

func open(owner: Node3D, id: String, label: Label) -> void:
	game = owner
	service = id
	progress = label
	apartment = for_site(game.economy, id)
	custom_minimum_size.y = 680
	stretch = true
	stretch_shrink = 2
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	path = "res://assets/models/interiors/" + apartment + ".glb"
	awaiting_model = ResourceLoader.load_threaded_request(path, "PackedScene") == OK
	if not awaiting_model:
		failed = true
		progress.text = game.t("interior_error")

func _process(delta: float) -> void:
	if failed or game.suspended_at >= 0:
		return
	if not loaded:
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			return
		awaiting_model = false
		var model: PackedScene
		if status != ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			model = ResourceLoader.load_threaded_get(path) as PackedScene
		if model == null:
			failed = true
			progress.text = game.t("interior_error")
		else:
			assemble(model)
		return
	update_activity(delta)

func _exit_tree() -> void:
	if awaiting_model:
		awaiting_model = false
		release_model_request(get_tree(), path)

static func release_model_request(tree: SceneTree, requested_path: String) -> void:
	# Closing the panel still owes the loader one get call. Poll outside the freed view.
	var status := ResourceLoader.load_threaded_get_status(requested_path)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		tree.process_frame.connect(func() -> void: release_model_request(tree, requested_path), CONNECT_ONE_SHOT)
	elif status != ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		ResourceLoader.load_threaded_get(requested_path)

func assemble(model: PackedScene) -> void:
	loaded = true
	viewport = SubViewport.new()
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(viewport)
	room = model.instantiate()
	viewport.add_child(room)
	var dome := WorldEnvironment.new()
	dome.environment = Environment.new()
	dome.environment.background_mode = Environment.BG_COLOR
	dome.environment.background_color = Color("#325865")
	dome.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	dome.environment.ambient_light_color = Color("#e0eeea")
	dome.environment.ambient_light_energy = .57
	room.add_child(dome)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -22, 0)
	sun.light_color = Color("#fff2d0")
	sun.light_energy = 1.12
	sun.shadow_enabled = true
	room.add_child(sun)
	var ground := Kit.box(room, Vector3(0,-.27,0), Vector3(34,.16,34), Color("#3d6670"))
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12.0
	room.add_child(camera)
	camera.position = Vector3(14, 16, 19)
	camera.look_at(Vector3(0,.7,0))
	camera.current = true
	roof = room.find_child("Roof", true, false)
	if roof != null:
		if game.motion_enabled():
			var lift := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			lift.tween_property(roof, "position", roof.position + Vector3(-5.1, 6.0, -6), .82)
			lift.tween_property(roof, "rotation:x", -.23, .82)
			lift.tween_property(camera, "size", 10.95, .65)
			lift.chain().tween_callback(roof.hide)
		else:
			roof.hide()
	if apartment in ["logistics", "warehouse"]:
		package = Kit.box(room, Vector3.ZERO, Vector3(1.01,.63,.78), Color("#d79a67"))
		Kit.box(package, Vector3(0,.318,.0), Vector3(.21,.022,.79), Color("#efca85"))
		package.hide()
	if apartment == "wash":
		brush = Node3D.new()
		room.add_child(brush)
		brush.position = Vector3(0,2.14,.50)
		Kit.cylinder(brush, Vector3.ZERO, .48, .48, 4.55, Color("#e2a45b"), 16).rotation.z = PI * .5
		for i in 9:
			Kit.cylinder(brush, Vector3(-2.0 + i * .5,0,0), .52,.52,.118, Color("#ecce76"), 15).rotation.z = PI * .5
	if apartment == "dealership":
		for i in 3:
			var car := Unit.instantiate()
			var choices: Array = ["orion","regency","vela"]
			room.add_child(car)
			car.position = Vector3(-3.38 + i * 3.45,.48,-.78)
			car.rotation.y = -.16
			car.build(choices[i], 0)
	update_activity(0.0)

func actor(role: String, at: Vector3) -> Node3D:
	var figure := Actor.new()
	figure.role = role
	figure.position = at
	room.add_child(figure)
	return figure

func update_activity(delta: float) -> void:
	var dispatch: HbtDispatch = game.traffic.dispatch
	var ticket := dispatch.first_at(service, HbtVisit.Phase.WORKING)
	var client := ticket if ticket != null else dispatch.first_at(service, HbtVisit.Phase.READY)
	var profile: HbtService = game.economy.facilities[service]
	if attendant == null and (not game.economy.crew[service].is_empty() or ticket != null):
		attendant = actor(profile.role, Vector3(2.39, .24, .90))
	if attendant != null:
		attendant.visible = not game.economy.crew[service].is_empty() or ticket != null
		attendant.rotation.y = -1.02 if apartment in ["wash","workshop","logistics"] else 1.68
		attendant.play(profile.task if ticket != null else "idle")
	if guest == null and client != null:
		guest = actor("customer", Vector3(-1.44, .24, 1.87))
	if guest != null:
		guest.visible = client != null
		if client != null:
			guest.position = Vector3(-1.44, .24, 2.62 - minf(1.52, client.walked))
			guest.rotation.y = 1.72
			guest.play("service" if ticket != null else "walk")
	if package != null:
		package.visible = ticket != null
		if ticket != null:
			var progress_now := ticket.progress()
			package.position = Vector3(0, .52, 2.18).lerp(Vector3(1.44,.71,-1.59), smoothstep(.05,.94,progress_now))
	if brush != null and ticket != null:
		brush.rotate_x(delta * 6)
		brush.position.z = sin(ticket.progress() * TAU) * 1.25
	if apartment in ["workshop","wash","logistics"] and client != null:
		if vehicle == null:
			vehicle = Unit.instantiate()
			room.add_child(vehicle)
			vehicle.position = Vector3(-.42,.24,.68)
		vehicle.show()
		var model: String = client.client.model
		if model != display_model:
			display_model = model
			vehicle.build(model, client.client.paint)
	elif vehicle != null:
		vehicle.hide()
	var note: String = game.t("interior_working") % roundi(ticket.progress() * 100.0) if ticket != null else game.t("interior_waiting")
	if progress.text != note:
		progress.text = note
