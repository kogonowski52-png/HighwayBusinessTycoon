extends "res://tests/station_smoke.gd"
## Compare dispatcher and visuals CPU cost with no renderer, using the same work in both checkouts.

func run() -> void:
	save_path = "/tmp/hbt-fleet-profile-%d.cfg" % OS.get_process_id()
	game = mount(WALL)
	var dispatcher: HbtDispatch = game.traffic.dispatch
	dispatcher.spawning = false
	for count in [20, 50, 100, 200]:
		for ticket: HbtVisit in dispatcher.live.values():
			dispatcher.dispose(ticket)
		await process_frame
		for i in count:
			var customer := dispatcher.demand.customer(game.economy, "local")
			customer.model = "pine"
			customer.paint = 0
			var visit := dispatcher.make_visit(customer, "fuel")
			visit.location = Vector3(70.0 + (i % 20) * 19.0, 0, 125.0 + floori(i / 20.0) * 14.0)
			visit.yaw = PI * .5
			dispatcher.route(visit, [visit.location + Vector3(420, 0, 0)], Phase.DEPART)
			dispatcher.added.emit(visit)
		var timings: Array[float] = []
		for frame in 260:
			var before := Time.get_ticks_usec()
			game.traffic.physics_step(1.0 / 60.0)
			if frame >= 20:
				timings.append((Time.get_ticks_usec() - before) / 1000.0)
		timings.sort()
		var total: float = timings.reduce(func(a: float, b: float) -> float: return a + b, 0.0)
		expect(dispatcher.live.size() == count and dispatcher.consistent(), "fleet maintains %d active vehicles" % count)
		print("FLEET_PROFILE ", JSON.stringify({"count": count, "ticks": timings.size(), "total_ms": total,
			"median_ms": timings[120], "p95_ms": timings[227], "nodes": get_node_count()}))
	game.free()
	await process_frame
	clean_save(save_path)
	result("Fleet CPU comparison")
