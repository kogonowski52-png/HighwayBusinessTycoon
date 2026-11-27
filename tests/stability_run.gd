extends "res://tests/station_smoke.gd"
## Real wall-clock endurance through the ordinary game node and event loop.

const Atlas = preload("res://data/world/atlas.gd")
const PAGES := ["finance", "calendar", "goals", "shop", "atlas", "boost", "settings"]
var seconds := 7200
var travel_every := 180
var sample_every := 900
var departures := 0
var checkpoints := 0
var moves := 0
var reopenings := 0
var reports: Array[Dictionary] = []
var report_path := ""
var district_index := 0
var restarts := 0
var started_at := 0

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seconds="):
			seconds = maxi(8, int(arg.get_slice("=", 1)))
		elif arg.begins_with("--travel-every="):
			travel_every = maxi(2, int(arg.get_slice("=", 1)))
		elif arg.begins_with("--sample-every="):
			sample_every = maxi(2, int(arg.get_slice("=", 1)))
		elif arg.begins_with("--report="):
			report_path = arg.get_slice("=", 1)
	save_path = "/tmp/hbt-stage7-endurance-%d.cfg" % OS.get_process_id()
	started_at = int(Time.get_unix_time_from_system())
	seed_campaign()
	if failures:
		result("Continuous gameplay")
		return
	var began := Time.get_ticks_msec()
	var period := 0
	var last_panel := -1
	var last_checkpoint := -1
	var next_move := travel_every
	var next_sample := sample_every
	var next_reboot := travel_every * 5
	game = mount(-1)
	current_scene = game
	activate()
	print("ENDURANCE begin, duration=", seconds, " seconds, display=", DisplayServer.get_name())
	while period < seconds and failures == 0:
		await create_timer(.22).timeout
		period = (Time.get_ticks_msec() - began) / 1000
		if period >= next_move:
			next_move += travel_every
			if period >= next_reboot:
				next_reboot += travel_every * 5
				await reopen_all(period)
			else:
				await migrate()
		if period % 7 == 3 and last_panel != period:
			last_panel = period
			game.operations.show_page(PAGES[reopenings % PAGES.size()])
			reopenings += 1
		elif period % 7 == 5 and game.operations.modal_open():
			game.operations.hide_page()
		if period % 31 == 2 and last_checkpoint != period:
			last_checkpoint = period
			if game.economy.checkpoint() == OK:
				checkpoints += 1
		if period >= next_sample or period >= seconds:
			next_sample += sample_every
			sample(period)
	store_report()
	expect(period >= seconds and absi(game.economy.clock - int(Time.get_unix_time_from_system())) <= 2,
		"the economy tracks wall time across game ticks, travel and restarts")
	expect(moves > 0 and game.campaign.districts.size() == Atlas.DESTINATIONS.size() and checkpoints > 0, "map switching and frequent saves across all twelve estates")
	if seconds >= 900:
		expect(departures > 100 and reopenings > 20 and restarts >= 1, "ordinary paid traffic, many panels and actual scene restarts")
	game.free()
	root.get_node("RouteAudio").shut_down()
	await create_timer(.18).timeout
	clean_save(save_path)
	result("Continuous gameplay")

func seed_campaign() -> void:
	var world := HbtCampaign.new(HbtEconomy.new())
	world.storage.path = save_path
	world.restore(started_at)
	for id: String in Atlas.DESTINATIONS:
		if id != "north":
			expect(world.travel(id) == OK, "unlock real map " + id)
		var estate := world.current()
		estate.finish_tutorial()
		estate.credit("cash", HbtAmount.from("10000000000000000000000000"))
		estate.credit("reputation", HbtAmount.from(200))
		for site: String in estate.facilities:
			if site != "fuel":
				estate.unlock(site)
			estate.buy_levels(site, 0)
			while estate.crew[site].size() < estate.capacity(site):
				if not estate.hire(site):
					break
	world.current().preferences.fps = 30
	world.current().preferences.quality = 0
	world.current().low_power = true
	expect(world.travel("north") == OK and world.boost.extend_confirmed(started_at) and world.checkpoint() == OK,
		"seed maximally developed estates and a five-minute bonus")

func activate() -> void:
	game.operations.hide_page()
	game.set_physics_process(true)

func migrate() -> void:
	var old := game
	var old_count: int = old.traffic.dispatch.departed
	district_index = (district_index + 1) % Atlas.DESTINATIONS.size()
	var id: String = Atlas.DESTINATIONS.keys()[district_index]
	old.travel_to(id)
	for _frame in 240:
		await process_frame
		if is_instance_valid(current_scene) and current_scene != old and current_scene.economy.district == id:
			game = current_scene
			departures += old_count
			moves += 1
			activate()
			return
	expect(false, "timed out visiting " + id)

func reopen_all(period: int) -> void:
	departures += game.traffic.dispatch.departed
	var wanted: String = game.economy.district
	expect(game.economy.checkpoint() == OK, "checkpoint before restart at %ds" % period)
	var currency: HbtAmount = game.economy.amount("cash")
	game.free()
	await process_frame
	game = mount(-1)
	current_scene = game
	restarts += 1
	expect(game.economy.district == wanted and game.economy.amount("cash").compare(currency) == 0,
		"restarted same balance and region at %ds" % period)
	activate()

func sample(period: int) -> void:
	var fleet: HbtDispatch = game.traffic.dispatch
	expect(fleet.consistent() and game.campaign.storage.read_candidate(save_path).schema >= 8, "valid reservations and profile at %ds" % period)
	var row := {"elapsed_wall_seconds": period, "elapsed_game_seconds": game.economy.clock - started_at,
		"region": game.economy.district, "map_changes": moves, "scene_restarts": restarts,
		"served": game.campaign.districts.values().reduce(func(sum: int, site: HbtEconomy) -> int: return sum + site.customers, 0),
		"departures": departures + fleet.departed, "nodes": get_node_count(), "heap_bytes": OS.get_static_memory_usage(),
		"views_opened": reopenings, "manual_checkpoints": checkpoints, "save_sequence": game.campaign.storage.sequence,
		"boost_left": game.campaign.boost.remaining(game.economy.clock)}
	reports.append(row)
	print("ENDURANCE ", JSON.stringify(row))
	store_report()

func store_report() -> void:
	if report_path.is_empty():
		return
	var report := FileAccess.open(report_path, FileAccess.WRITE)
	report.store_string(JSON.stringify({"target_wall_seconds": seconds, "display": DisplayServer.get_name(), "samples": reports}, "\t"))
