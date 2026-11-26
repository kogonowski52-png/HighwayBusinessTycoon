extends Node
## Keep a small preload window for the destination, then replace the active scene in one tree operation.

const PREFIX := "res://assets/models/"
const SHARED := ["vehicles/pine", "vehicles/wheel_street", "characters/driver", "characters/hand_props"]
const NORTH := ["architecture/canopy_worn", "architecture/market_shuttered", "architecture/pump_vintage",
	"architecture/island", "landscape/broadleaf", "landscape/pine"]
const DESERT := ["desert/copper_mile", "desert/pump", "desert/buttress", "desert/saguaro", "desert/agave",
	"desert/median_planter", "desert/highway_lamp", "desert/pylon"]

var target := ""
var queued: Array[String] = []
var running: Array[String] = []
var resource_holds: Array[Resource] = []
var target_scene: PackedScene
var failed := false
var total := 1
var ready_count := 0

func start(path: String, region: String) -> void:
	target = path
	queued.append(target)
	var files: Array = SHARED.duplicate()
	match region:
		"north": files.append_array(NORTH)
		"desert": files.append_array(DESERT)
		_: files.append_array(["regions/" + region + "_fuel", "regions/" + region + "_foliage"])
	for name: String in files:
		var key := PREFIX + name + ".glb"
		if ResourceLoader.exists(key, "PackedScene") and not ResourceLoader.has_cached(key):
			queued.append(key)
	total = queued.size()
	fill()

func fill() -> void:
	while running.size() < 3 and not queued.is_empty():
		var path: String = queued.pop_front()
		if ResourceLoader.load_threaded_request(path, "PackedScene") == OK:
			running.append(path)
		else:
			failed = failed or path == target
			ready_count += 1

func poll() -> float:
	var partial := 0.0
	for path: String in running.duplicate():
		var info := []
		var status := ResourceLoader.load_threaded_get_status(path, info)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			partial += float(info[0]) if not info.is_empty() else 0.0
			continue
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var resource := ResourceLoader.load_threaded_get(path) as PackedScene
			if path == target:
				target_scene = resource
				failed = resource == null
			elif resource != null:
				resource_holds.append(resource)
		else:
			if status == ResourceLoader.THREAD_LOAD_FAILED:
				ResourceLoader.load_threaded_get(path)
			failed = failed or path == target
		running.erase(path)
		ready_count += 1
	fill()
	return (ready_count + partial) / float(total)

func done() -> bool:
	return queued.is_empty() and running.is_empty()

func replace(previous: Node3D, profile: HbtCampaign, seed: int, wall: int) -> void:
	var tree := get_tree()
	var budget: RefCounted = previous.render_budget
	budget.clear_sample()
	tree.current_scene = null
	previous.free()
	var next := target_scene.instantiate()
	next.campaign = profile
	next.render_budget = budget
	next.seed_override = seed
	next.wall_override = wall
	next.arrived_from_trip = true
	tree.root.add_child(next)
	tree.current_scene = next
	queue_free()
