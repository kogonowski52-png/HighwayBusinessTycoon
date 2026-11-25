extends "res://tests/expedition_recording.gd"
## Movie Maker captures a real Metro delivery and a trip to Green Valley.

const Atlas = preload("res://data/world/atlas.gd")

func run() -> void:
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.size = Vector2i(486, 864)
	root.borderless = true
	root.position = Vector2i.ZERO
	path = "/tmp/hbt-atlas-film-%d.cfg" % OS.get_process_id()
	var north := HbtEconomy.new()
	north.storage.path = path
	var atlas := HbtCampaign.new(north)
	atlas.restore()
	north.finish_tutorial()
	north.preferences.weather = "clear"
	for id in Atlas.DESTINATIONS:
		if id != "north" and atlas.travel(id) != OK:
			finish(false)
			return
		var estate := atlas.current()
		estate.credit("cash", HbtAmount.from(80_000_000))
		estate.credit("reputation", HbtAmount.from(200))
		for service in estate.facilities:
			if service != "fuel":
				estate.unlock(service)
			estate.buy_levels(service, 25)
			estate.buy_levels(service, 25)
			estate.buy_levels(service, 10)
			estate.hire(service)
			estate.hire(service)
		estate.cards.dev = true
		if id == "metro":
			estate.assign("dev")
	if atlas.travel("north") != OK:
		finish(false)
		return
	var title := Front.instantiate()
	title.profile_path = path
	root.add_child(title)
	current_scene = title
	await create_timer(.7).timeout
	press(title.play)
	var start := await district("north")
	if start == null:
		finish(false)
		return
	await create_timer(.40).timeout
	await travel(start, "metro")
	var metro := await district("metro")
	if metro == null:
		finish(false)
		return
	metro.set_look(metro.lighting.Look.DAWN)
	metro.select_site("logistics")
	metro.aim_camera(Vector3(-15.32, .21, -35.9), Vector3(10.1, 16.5, 18.8), 24.0)
	metro.traffic.dispatch.spawning = false
	var load: HbtVisit = metro.traffic.dispatch.try_admit("trucker", "logistics")
	if load == null:
		finish(false)
		return
	for i in range(320):
		if load.phase == HbtVisit.Phase.APPROACH and load.location.distance_to(Vector3(-22.0, 0, -24)) < 10:
			break
		metro.tick_game(.07)
	for i in range(42):
		metro.tick_game(.06)
		if load.phase == HbtVisit.Phase.WORKING:
			break
	await create_timer(6.84).timeout
	var arrived := load.phase == HbtVisit.Phase.WORKING or load.paid
	for i in 170:
		if load.paid:
			break
		metro.tick_game(.05)
	await create_timer(.60).timeout
	metro.select_site("mall")
	metro.aim_camera(Vector3(15.0, .50, -7.63), Vector3(10.1, 17.5, 19.2), 26.5)
	await create_timer(2.3).timeout
	await travel(metro, "valley")
	var valley := await district("valley")
	if valley == null:
		finish(false)
		return
	valley.aim_camera(Vector3(-24.8, .54, -2.10), Vector3(10.8, 21.0, 20.2), 33.1)
	await create_timer(3.10).timeout
	valley.select_site("restaurant")
	valley.aim_camera(Vector3(8.3, .42, -5.57), Vector3(9.0, 15.1, 17.6), 19.3)
	await create_timer(1.9).timeout
	print("Regional film: freight_paid=%s districts=%d final=%s" % [load.paid, valley.campaign.districts.size(), valley.economy.district])
	var audio := root.get_node("RouteAudio")
	audio.set_process(false)
	for player in audio.get_children():
		if player is AudioStreamPlayer:
			player.stop()
	valley.queue_free()
	await valley.tree_exited
	for i in 5:
		await process_frame
	finish(arrived and load.paid)

func travel(node: Node3D, id: String) -> void:
	if node.operations.modal_open():
		press(node.operations.back)
		await create_timer(.26).timeout
	press(node.hud.pages.atlas)
	await create_timer(.68).timeout
	await select_button(node, node.district_name(id))
	await create_timer(.80).timeout
	await select_button(node, node.t("district_travel"))
