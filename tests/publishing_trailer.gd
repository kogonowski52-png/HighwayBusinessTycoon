extends "res://tests/publishing_listing_window.gd"
## Cinematic cameras follow the running campaign. The manifest marks editorial cut points.

var cuts: Array[Dictionary] = []

func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			captures = argument.trim_prefix("--capture-dir=")
	if captures.is_empty() or DisplayServer.get_name() == "headless":
		expect(false, "a real Movie Maker viewport and destination are required")
		result("Publishing trailer")
		return
	DirAccess.make_dir_recursive_absolute(captures)
	root.borderless = true
	root.position = Vector2i.ZERO
	root.size = Vector2i(1280, 720)
	save_path = "/tmp/hbt-publishing-trailer-%d.cfg" % OS.get_process_id()
	game = mount(AT)
	current_scene = game
	develop_site(24)
	step(15.0)
	await shoot("station", Vector3(-.5, .40, -3.3), 31.0, 26.0, 184)
	game.select_site("workshop")
	game.traffic.dispatch.try_admit("local", "workshop", "vela")
	step(4.0)
	await shoot("services", Vector3(9.5, .8, -10.15), 23.0, 18.0, 170)
	game.travel_to("desert")
	if not await arrive("desert"):
		fail_movie("Could not film Desert Highway")
		return
	develop_site(22)
	step(13.0)
	await shoot("copper-mile", Vector3(-4.2, .5, -9.0), 34.0, 28.0, 180)
	var sponsor: HbtEconomy = game.economy
	sponsor.credit("cash", HbtAmount.from(70_000))
	if sponsor.level("cafe") == 0:
		sponsor.unlock("cafe")
	if sponsor.level("cafe") < 3:
		sponsor.buy_levels("cafe", 3 - sponsor.level("cafe"))
	if not game.campaign.available("valley"):
		fail_movie("Riverbend gate was not reached in the capture profile")
		return
	game.travel_to("valley")
	if not await arrive("valley"):
		fail_movie("Could not film Green Valley")
		return
	develop_site(22)
	step(12.0)
	await shoot("riverbend", Vector3(-4.8, .7, -7.6), 36.0, 30.0, 180)
	var report := FileAccess.open(captures.path_join("cuts.json"), FileAccess.WRITE)
	expect(report != null, "record four running game scenes across three districts")
	if report != null:
		report.store_string(JSON.stringify(cuts, "\t") + "\n")
		report.close()
	root.get_node("RouteAudio").shut_down()
	game.free()
	clean_save(save_path)
	result("Publishing trailer")

func shoot(id: String, subject: Vector3, start: float, end: float, length: int) -> void:
	game.operations.hide_page()
	game.hud.hide()
	game.site_buttons.hide()
	game.set_look(game.lighting.Look.GOLDEN if id in ["station", "copper-mile"] else game.lighting.Look.DAY)
	game.aim_camera(subject, Vector3(14, 27, 31), start)
	for frame in 6:
		await process_frame
	var marker := Engine.get_frames_drawn()
	for index in length:
		var factor := smoothstep(0.0, 1.0, float(index) / (length - 1))
		game.tick_game(1.0 / 24.0)
		game.aim_camera(subject.lerp(subject + Vector3(-2.4, .2, -.8), factor),
			Vector3(14, 27, 31).lerp(Vector3(18.6, 25, 28), factor), lerpf(start, end, factor))
		await process_frame
	cuts.append({"scene": id, "frame": marker, "length": length})
	game.hud.show()
	game.site_buttons.show()

func fail_movie(reason: String) -> void:
	expect(false, reason)
	root.get_node("RouteAudio").shut_down()
	if is_instance_valid(current_scene):
		current_scene.free()
	clean_save(save_path)
	result("Publishing trailer")
