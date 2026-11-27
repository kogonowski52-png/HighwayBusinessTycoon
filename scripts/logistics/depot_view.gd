extends Node3D
## One small dispatch yard and a bounded pool of trucks for the mounted estate.

const Art = preload("res://scripts/art/visual_library.gd")
const Catalog = preload("res://data/logistics/fleet.gd")
const Vehicle = preload("res://scenes/vehicles/compact.tscn")
const Kit = preload("res://scripts/buildings/model_kit.gd")
const Regions = preload("res://data/world/regions.gd")
const MAX_SHOWN := 4

var fleet: RefCounted
var parked: Node3D
var parked_signature := ""
var visible_jobs := {}
var trucks := {}
var spare := {}
var region := ""
var clock := 0
var subsecond := 0.0

static func yard_position(id: String) -> Vector3:
	if id == "north":
		return Vector3(14.6, -.11, 20.55)
	if id == "desert":
		return Vector3(6.5, -.12, 24)
	var road: float = Regions.LAYOUTS[id].ambient
	return Vector3(22.25, -.095, road + 10.9)

func bind(manager: RefCounted, id: String, local_now: int) -> void:
	fleet = manager
	region = id
	position = yard_position(region)
	Art.place(self, "transport", "depot")
	Art.sign(self, Vector3(-2.95, 2.95, 1.46), "HIGHWAY  /  DISPATCH", .23, Color("#fff0c8"))
	Art.sign(self, Vector3(4.49, 2.32, -.354), "17 • FREIGHT", .148, Color("#294447"))
	Art.contact(self, Vector3(0, .035, 0), 15.4, 8.25)
	parked = Node3D.new()
	add_child(parked)
	update_clock(local_now)

func update_clock(now: int) -> void:
	if now != clock:
		clock = now
		subsecond = 0
	visible_jobs = fleet.visible_jobs(region, now)
	var snapshot: Array = []
	for id: String in fleet.vehicles:
		var data: Dictionary = fleet.vehicles[id]
		if data.home == region and not fleet.busy(id):
			snapshot.append([id, data.trailer])
		if snapshot.size() >= 2:
			break
	var signature := str(snapshot)
	if signature != parked_signature:
		parked_signature = signature
		for car in parked.get_children():
			parked.remove_child(car)
			car.queue_free()
		for i in snapshot.size():
			var car := create_vehicle(str(snapshot[i][0]))
			car.position = Vector3(-4.73 + i * 3.0, .28, -.45)
			add_exhibit(car, parked)
	for id: String in trucks.keys():
		if not visible_jobs.has(id) or not visible_jobs.keys().slice(0, MAX_SHOWN).has(id):
			var car: Node3D = trucks[id]
			var key: String = car.get_meta("spec")
			car.hide()
			if spare.has(key):
				car.queue_free()
			elif spare.size() >= MAX_SHOWN:
				car.queue_free()
			else:
				spare[key] = car
			trucks.erase(id)
	for id: String in visible_jobs.keys().slice(0, MAX_SHOWN):
		if trucks.has(id):
			continue
		var ticket: Dictionary = visible_jobs[id].job
		var truck: Dictionary = fleet.vehicles[ticket.truck]
		var key: String = truck.kind + "_" + truck.trailer
		var car: Node3D = spare.get(key)
		if car != null:
			spare.erase(key)
			car.show()
			car.reset_drive()
		else:
			car = create_vehicle(ticket.truck)
			car.set_meta("spec", key)
			add_exhibit(car, self)
		trucks[id] = car
	set_process(not trucks.is_empty())

func add_exhibit(car: Node3D, parent: Node3D) -> void:
	parent.add_child(car)
	var model: String = car.get_meta("model")
	car.build(model, 0, false, region)
	var body: String = car.get_meta("body")
	if not body.is_empty():
		Art.place(car, "transport", body)
	if body not in ["", "tanker"]:
		var wheel := Art.extract_mesh("vehicles", "wheel_heavy")
		for z in [-4.62, -5.16]:
			for side in [-1.0, 1.0]:
				var tire := MeshInstance3D.new()
				tire.mesh = wheel
				tire.position = Vector3(.77 * side, .43, z)
				tire.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				car.add_child(tire)
	if body == "autos":
		Art.place(car, "vehicles", "kestrel", Vector3(0, 2.08, -4.12)).scale = Vector3.ONE * .57

func create_vehicle(id: String) -> Node3D:
	var record: Dictionary = fleet.vehicles[id]
	var car := Vehicle.instantiate()
	car.set_meta("model", Catalog.TYPES[record.kind].model)
	car.set_meta("body", "tanker" if record.kind == "tank" else record.trailer)
	return car

func _process(delta: float) -> void:
	animate(delta)

func animate(delta: float) -> void:
	subsecond = minf(.999, subsecond + delta)
	var index := 0
	for id: String in trucks:
		var car: Node3D = trucks[id]
		var run: Dictionary = visible_jobs[id]
		var now := float(clock) + subsecond
		var fraction: float = (now - float(run.job.due - fleet.SHOW_SECONDS)) / fleet.SHOW_SECONDS if run.arrival 			else (now - float(run.job.start)) / fleet.SHOW_SECONDS
		var blend := smoothstep(0.0, 1.0, clampf(fraction, 0.0, 1.0))
		var start := Vector3(-4.2 + minf(3.0, index * 2.15), .28, 2.05 + index * 1.85)
		var junction := Vector3(1.8, .20, 3.10 + index * 1.85)
		var exit := Vector3(35.0, .14, 3.10 + index * 1.85)
		var path := 1.0 - blend if run.arrival else blend
		var motion := start.lerp(junction, path / .3) if path < .3 else junction.lerp(exit, (path - .3) / .7)
		var next :=  path + (-.005 if run.arrival else .005)
		var look := start.lerp(junction, next / .3) if next < .3 else junction.lerp(exit, (next - .3) / .7)
		var distance := car.position.distance_to(motion)
		car.position = motion
		car.rotation.y = atan2(look.x - motion.x, look.z - motion.z)
		car.spin(distance)
		index += 1
