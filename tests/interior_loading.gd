extends SceneTree

const Cutaway = preload("res://scripts/interiors/cutaway.gd")
const MODEL := "res://assets/models/interiors/market.glb"

class Host extends Node3D:
	var economy := HbtEconomy.new()

	func t(key: String) -> String:
		return key

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var host := Host.new()
	host.economy.levels.market = 4
	root.add_child(host)
	var requested := true
	for attempt in 3:
		var view := Cutaway.new()
		var progress := Label.new()
		view.add_child(progress)
		host.add_child(view)
		view.open(host, "market", progress)
		requested = requested and view.awaiting_model
		view.free()
	for frame in 120:
		await process_frame
		if ResourceLoader.load_threaded_get_status(MODEL) == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			break
	var released := ResourceLoader.load_threaded_get_status(MODEL) == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE
	host.free()
	print("Canceled interior stream: %d/2 passed" % (int(requested) + int(released)))
	quit(0 if requested and released else 1)
