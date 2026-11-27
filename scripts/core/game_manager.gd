extends Node3D

const Art = preload("res://scripts/art/visual_library.gd")
const Routes = preload("res://data/economy/routes.gd")
const DesertRoutes = preload("res://data/world/desert_routes.gd")
const Atlas = preload("res://data/world/atlas.gd")
const DesertLandscape = preload("res://scripts/buildings/desert_landscape.gd")
const DesertCampus = preload("res://scripts/buildings/desert_campus.gd")
const DesertStation = preload("res://scripts/buildings/desert_station.gd")
const Regions = preload("res://data/world/regions.gd")
const RegionalRoutes = preload("res://data/world/regional_routes.gd")
const RegionalLandscape = preload("res://scripts/buildings/regional_landscape.gd")
const FrontierLandscape = preload("res://scripts/buildings/frontier_landscape.gd")
const RegionalCampus = preload("res://scripts/buildings/regional_campus.gd")
const RegionalStation = preload("res://scripts/buildings/regional_station.gd")
const Diagnostics := "res://scripts/core/runtime_diagnostics.gd"
const Practice = preload("res://scripts/challenges/service_practice.gd")
const PracticeScreen = preload("res://scripts/challenges/practice_screen.gd")
const Spotlight = preload("res://scripts/estate/spotlight_director.gd")
const EstateView = preload("res://scripts/estate/estate_view.gd")
const Depot = preload("res://scripts/logistics/depot_view.gd")
const WorldStream = preload("res://scripts/core/world_stream.gd")
const RenderBudget = preload("res://scripts/core/render_budget.gd")
const Weather = preload("res://scripts/art/expedition_weather.gd")
const TrafficManager = preload("res://scripts/traffic/traffic_manager.gd")
const Landscape = preload("res://scripts/buildings/roadside_landscape.gd")
const Campus = preload("res://scripts/buildings/roadside_campus.gd")
const Lighting = preload("res://scripts/art/world_lighting.gd")
const Effects = preload("res://scripts/art/world_effects.gd")
const VenueActivity = preload("res://scripts/art/venue_activity.gd")
const Crew = preload("res://scripts/employees/world_crew.gd")
const Ads = preload("res://scripts/monetization/ads_manager.gd")
const Purchases = preload("res://scripts/monetization/purchase_manager.gd")
const WorldOffers = preload("res://scripts/monetization/world_offers.gd")
const RevenueConfig = preload("res://data/monetization/config.gd")
const Operations = preload("res://scripts/core/operations_panel.gd")
const Tutorial = preload("res://scripts/core/tutorial.gd")
const Rig = preload("res://scripts/ui/camera_rig.gd")
const SiteButtons = preload("res://scripts/ui/site_buttons.gd")
const Feedback = preload("res://scripts/core/feedback.gd")
const Station = preload("res://scenes/buildings/fuel_station.tscn")
const Driver = preload("res://scenes/characters/driver.tscn")
const Hud = preload("res://scenes/ui/station_hud.tscn")
const Strings = preload("res://localization/strings.gd")
const BOOK = preload("res://data/economy/progression.gd")
const LOOK_LABELS := ["day", "golden", "evening", "night", "dawn"]
const Phase = HbtVisit.Phase
const SERVICE_SOUND := {"fuel": "pump", "truck": "pump", "wash": "wash",
	"workshop": "workshop", "tires": "workshop", "restaurant": "diner", "drive_through": "diner", "cafe": "diner", "mall": "diner", "logistics": "workshop", "warehouse": "workshop", "dealership": "diner"}

@export var district_profile: HbtDistrict
var economy := HbtEconomy.new()
var campaign: HbtCampaign
var routes: Object = Routes
var traveling := false
var deferred_ad_feedback := ""
var travel_layer: CanvasLayer
var travel_progress: ProgressBar
var arrived_from_trip := false
var weather: Node3D
var world_second := -1
var depot: Node3D
var estate_view: Node3D
var roadside_moments := Spotlight.new()
var practice_screen: CanvasLayer
var scene_elapsed := 0.0
var paused_3d := false
var shown_event := ""
var traffic := TrafficManager.new()
var station: Node3D
var landscape: Node3D
var driver := Driver.instantiate()
var hud := Hud.instantiate()
var campus: Node3D
var crew := Crew.new()
var venue_activity: Node3D
var operations := Operations.new()
var camera := Camera3D.new()
var lighting := Lighting.new()
var effects := Effects.new()
var ads := Ads.new()
var purchases := Purchases.new()
var boost_was_active := false
var last_mission: Dictionary = {}
var world_offers := WorldOffers.new()
var tutorial := Tutorial.new()
var feedback := Feedback.new()
var camera_rig := Rig.new()
var site_buttons := SiteButtons.new()
var preferences_timer := Timer.new()
@onready var route_audio: Node = get_node("/root/RouteAudio")
var entry_language := ""
var shown_cards: Dictionary
var known_diamonds := HbtAmount.new()
var sound_elapsed := 0.0
var calendar_day := -1

var selected := "fuel"
var quantity := 1
var overview := false
var wall_override := -1
var seed_override := -1
var hud_time := 0.0
var autosave := 0.0
var diagnostics: CanvasLayer
var render_budget := RenderBudget.new()
var render_quality := -1
var live_levels: Dictionary = {}
var live_language := ""
var live_crew: Dictionary = {}
var live_directors: Array = []
var simulation_clock := 0.0
var message := ""
var message_time := 0.0
var suspended_at := -1
var mounted := false
var closing := false
var fuel_art_level := 1
var displayed_rank := 1
var guided_step := 0

func _ready() -> void:
	if campaign == null:
		for argument in OS.get_cmdline_user_args():
			if OS.is_debug_build() and argument.begins_with("--save-path="):
				economy.storage.path = argument.trim_prefix("--save-path=")
		campaign = HbtCampaign.new(economy)
		campaign.restore(wall_override)
	economy = campaign.current()
	economy.save_hook = campaign.checkpoint
	if entry_language in ["pl", "en"]:
		economy.language = entry_language
	if not render_budget.initialized:
		render_budget.reset()
	setup_district()
	shown_cards = economy.cards.duplicate()
	known_diamonds = economy.amount("diamond")
	calendar_day = economy.day_index()
	displayed_rank = economy.player_level()
	guided_step = economy.tutorial_step
	simulation_clock = float(economy.clock)
	add_child(lighting)
	setup_camera()
	add_child(landscape)
	add_child(campus)
	if venue_activity != null:
		add_child(venue_activity)
		venue_activity.parcels_delivered.connect(on_supply_delivery)
	add_child(effects)
	add_child(station)
	fuel_art_level = -1
	weather = Weather.new()
	add_child(weather)
	weather.setup(lighting, economy.district, routes)
	weather.display_collection(campaign.ledger.chosen.get(campaign.active, {}))
	add_child(traffic)
	traffic.sighting.connect(on_sighting)
	traffic.start(economy, int(Time.get_ticks_usec()) if seed_override < 0 else seed_override, routes)
	crew.routes = routes
	add_child(crew)
	add_child(driver)
	driver.position = routes.worker_at("fuel", 0)
	driver.rotation.y = -1.2 if economy.district != "north" else -2.56
	add_child(hud)
	add_child(operations)
	operations.setup(self, hud)
	add_child(tutorial)
	tutorial.setup(self, hud)
	add_child(camera_rig)
	camera_rig.bind_to(self, camera)
	add_child(site_buttons)
	site_buttons.bind_to(self)
	add_child(feedback)
	add_child(preferences_timer)
	preferences_timer.one_shot = true
	preferences_timer.timeout.connect(economy.checkpoint)
	route_audio.set_track("day")
	economy.changed.connect(on_economy_changed)
	traffic.dispatch.state_changed.connect(refresh)
	traffic.dispatch.completed.connect(on_sale)
	add_child(roadside_moments)
	roadside_moments.bind(self)
	traffic.dispatch.completed.connect(roadside_moments.arrived)
	hud.serve_requested.connect(serve_customer)
	hud.upgrade_requested.connect(invest)
	hud.lighting_requested.connect(cycle_lighting)
	hud.view_requested.connect(toggle_view)
	hud.page_requested.connect(open_page)
	hud.income_requested.connect(income_action)
	hud.management_toggled.connect(refresh)
	add_child(ads)
	ads.bind(self)
	ads.rewarded.connect(ad_rewarded)
	ads.failed.connect(func() -> void: show_message(t("bonus_unavailable")))
	ads.unconfirmed.connect(func() -> void: show_message(t("boost_unconfirmed")))
	ads.commercial_started.connect(route_audio.set_ad_fullscreen.bind(true))
	ads.commercial_finished.connect(route_audio.set_ad_fullscreen.bind(false))
	add_child(purchases)
	purchases.bind(self)
	purchases.changed.connect(operations.refresh)
	purchases.delivered.connect(purchase_delivered)
	operations.closed.connect(consider_ad_break)
	add_child(world_offers)
	world_offers.bind(self)
	if debug_tools_available():
		diagnostics = load(Diagnostics).new()
		diagnostics.game = self
		add_child(diagnostics)
	ads.availability_changed.connect(on_ad_state_changed)
	get_viewport().size_changed.connect(frame_camera)
	get_viewport().size_changed.connect(operations.apply_layout)
	frame_camera()
	on_economy_changed()
	mounted = true
	boost_was_active = campaign.boost.earning(economy.clock)
	if not arrived_from_trip:
		log_commercial("game_start")
		economy.checkpoint()
	if not economy.preferences.auto_day:
		var opening_look := int(Regions.LAYOUTS.get(economy.district, {}).get("look", Lighting.Look.DAY))
		if economy.district == "metro":
			opening_look = Lighting.Look.NIGHT
		if opening_look != Lighting.Look.DAY:
			set_look(opening_look)
	update_expedition()
	sync_depot()
	sync_estate()
	get_tree().auto_accept_quit = false
	if not economy.offline_pending.empty():
		operations.show_page("offline")
	if arrived_from_trip and motion_enabled():
		travel_veil(t("journey_arrived") % district_name(campaign.active), false)

func setup_district() -> void:
	if is_regional():
		routes = RegionalRoutes.new(economy.district)
		station = RegionalStation.new(routes)
		landscape = FrontierLandscape.new(routes) if Regions.FRONTIERS.has(economy.district) else RegionalLandscape.new(routes)
		campus = RegionalCampus.new(routes)
		lighting.district = economy.district
		traffic.district = economy.district
	elif is_desert():
		var profile := district_profile if district_profile != null else HbtEconomy.DESERT
		routes = DesertRoutes
		station = DesertStation.new()
		landscape = DesertLandscape.new()
		campus = DesertCampus.new()
		lighting.district = profile.id
		traffic.district = profile.id
	else:
		station = Station.instantiate()
		landscape = Landscape.new()
		campus = Campus.new()
		venue_activity = VenueActivity.new()

func is_desert() -> bool:
	return economy.district == "desert"

func is_regional() -> bool:
	return Regions.has_region(economy.district)

func setup_camera() -> void:
	add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.current = true

func debug_tools_available() -> bool:
	if not OS.is_debug_build():
		return false
	return not OS.has_feature("mobile") or (Engine.has_singleton("HighwayRewarded") \
		and Engine.get_singleton("HighwayRewarded").diagnosticsEnabled())

func motion_enabled() -> bool:
	return not economy.low_power and DisplayServer.get_name() != "headless"

func frame_camera() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var aspect := viewport_size.x / maxf(1.0, viewport_size.y)
	if is_regional():
		var plan: Dictionary = Regions.LAYOUTS[economy.district]
		var center: Vector3 = plan.center if overview else campus.focus(selected)
		var width := maxf(94.0, aspect * 81.0) if overview else maxf(float(plan.width), aspect * 38.0)
		camera_rig.frame(center, Vector3(16, 36, 31), width, not mounted or not motion_enabled())
		return
	if is_desert():
		var center: Vector3 = Vector3(6, .0, -9.6) if overview else campus.focus(selected) + Vector3(-.31, .54, -.24)
		camera_rig.frame(center, Vector3(19, 36, 29), maxf(90.0, aspect * 78.0) if overview else maxf(25.6, aspect * 33.0),
			not mounted or not motion_enabled())
		return
	if overview:
		camera_rig.frame(Vector3(4.5, 0.0, -4.3), Vector3(16.0, 39.0, 32.5), maxf(94.0, aspect * 69.0), not mounted or not motion_enabled())
	else:
		var subject: Vector3 = campus.focus(selected) + Vector3(-0.54, 0.62, -0.88)
		if selected == "tires":
			camera_rig.frame(Campus.TIRES_AT + Vector3(0.4, 0.95, 1.1), Vector3(-5.8, 8.5, 8.0),
				maxf(17.2, aspect * 24.0), not mounted or not motion_enabled())
		else:
			camera_rig.frame(subject, Vector3(15.3, 34.7, 31.5), maxf(22.6, aspect * 31.5), not mounted or not motion_enabled())

func aim_camera(target: Vector3, offset: Vector3, width: float) -> void:
	camera_rig.frame(target, offset, width, true)

func set_look(preset: Lighting.Look) -> void:
	lighting.set_look(preset)
	var artificial := preset in [Lighting.Look.EVENING, Lighting.Look.NIGHT]
	traffic.set_night(artificial)
	route_audio.set_track("night" if artificial else "day")
	refresh()

func cycle_lighting() -> void:
	if economy.preferences.auto_day:
		economy.preferences.auto_day = false
		economy.checkpoint()
	set_look((int(lighting.current) + 1) % LOOK_LABELS.size())

func toggle_view() -> void:
	overview = not overview
	frame_camera()
	refresh()

func _physics_process(delta: float) -> void:
	if suspended_at < 0 and not traveling:
		tick_game(delta)

func tick_game(delta: float) -> void:
	simulation_clock += delta
	economy.clock = int(simulation_clock)
	if wall_override < 0:
		economy.clock = campaign.boost.observe_device(int(Time.get_unix_time_from_system()), false)
	else:
		campaign.boost.advance(economy.clock)
	if not ads.displaying() and not purchases.busy():
		campaign.premium.active_seconds += delta
	if world_second != economy.clock:
		world_second = economy.clock
		var current := campaign.boost.earning(economy.clock)
		if boost_was_active and not current:
			log_commercial("boost_expired", "boost")
		boost_was_active = current
		purchases.tick()
		if campaign.freight.advance(campaign, economy.clock):
			economy.checkpoint()
			if operations.modal_open() and operations.page in operations.logistics.PAGES:
				operations.refresh()
		sync_depot()
		roadside_moments.tick()
		if operations.modal_open():
			operations.logistics.update_clocks(economy.clock)
			if operations.page == "marketing":
				operations.refresh()
		update_expedition()
		if operations.modal_open() and operations.page == "diagnostics":
			operations.refresh()
	if campaign.premium.vip.has(economy.district) and not traffic.dispatch.live.values().any(func(ticket: HbtVisit) -> bool: return ticket.ad_guest):
		var guest := traffic.dispatch.try_admit("vip")
		if guest != null:
			guest.ad_guest = true
	traffic.physics_step(delta)
	scene_elapsed += delta
	if scene_elapsed >= (1.0 / 30.0 if render_quality == 0 else 1.0 / 60.0):
		crew.update(economy, traffic.dispatch, scene_elapsed)
		world_offers.tick(scene_elapsed)
		update_scene(scene_elapsed)
		scene_elapsed = 0.0
	sound_elapsed += delta
	if sound_elapsed > (0.32 if economy.low_power else 0.19):
		sound_elapsed = 0.0
		update_soundscape()
	var day := economy.day_index()
	if calendar_day != day:
		calendar_day = day
		if operations.modal_open() and operations.page == "calendar":
			operations.refresh()
	autosave += delta
	var base_interval: float = economy.CONFIG.checkpoint_seconds
	var idle_interval := base_interval * (3.0 if economy.low_power else 2.0)
	if autosave >= (base_interval if economy.dirty else idle_interval):
		autosave = 0.0
		economy.checkpoint()
	hud_time += delta
	message_time -= delta
	if hud_time >= 0.45:
		hud_time = 0.0
		refresh()

func update_scene(delta: float) -> void:
	var primary := traffic.dispatch.visit_at("fuel", 0)
	var primary_ready := primary != null and primary.phase == Phase.READY
	var primary_manual := primary != null and primary.phase == Phase.WORKING and primary.worker == -1
	driver.represent_service(primary_ready and economy.crew.fuel.is_empty(), primary_manual, delta)
	var filling := traffic.dispatch.first_at("fuel", Phase.WORKING)
	if filling == null and economy.district == "north":
		filling = traffic.dispatch.first_at("truck", Phase.WORKING)
	if filling != null:
		var worker: Node3D = driver if filling == primary and primary_manual else crew.performer(filling)
		var has_prop: bool = is_instance_valid(worker) and is_instance_valid(worker.prop) and worker.prop.visible
		var source: Vector3 = station.hose_anchor() if filling == primary else campus.hose_anchor(filling)
		effects.set_hose(has_prop, worker.prop.global_position if has_prop else Vector3.ZERO, source)
	else:
		effects.set_hose(false, Vector3.ZERO)
	if Regions.FRONTIERS.has(economy.district):
		effects.set_activity(campus.active_job("wash", traffic.dispatch), campus.active_job("repair", traffic.dispatch))
	else:
		effects.set_activity(traffic.dispatch.first_at("wash", Phase.WORKING), traffic.dispatch.first_at("workshop", Phase.WORKING))
	campus.update_chargers(traffic.dispatch)
	if venue_activity != null:
		venue_activity.service_activity(traffic.dispatch, delta)
		venue_activity.move_delivery(delta)
	weather.follow(camera_rig.focus)
	var road_car: HbtVisit
	for ticket: HbtVisit in traffic.dispatch.live.values():
		if ticket.distance > 0.04 and ticket.location.z > -1.5 and ticket.location.z < 6.9 \
			and ticket.phase in [Phase.APPROACH, Phase.DEPART]:
			road_car = ticket
			break
	var at := Vector3.ZERO if road_car == null else road_car.location - Vector3(sin(road_car.yaw), 0, cos(road_car.yaw)) * 1.30
	effects.drive_on_dust(road_car != null, at)
	station.set_service_progress(primary.progress() if primary != null else 0.0)
	var job := traffic.dispatch.first_at(selected, Phase.WORKING)
	var progress := job.progress() if job != null else 0.0
	hud.progress.value = lerpf(hud.progress.value, progress, 1.0 - exp(-24.0 * delta)) if job != null else 0.0

func update_soundscape() -> void:
	var focus := camera_rig.focus
	var layers := {"wind": 0.26 if lighting.current in [Lighting.Look.EVENING, Lighting.Look.NIGHT] else 0.35, "cars": 0.12}
	for visit: HbtVisit in traffic.dispatch.live.values():
		var nearness := 1.0 - clampf(visit.location.distance_to(focus) / 22.0, 0.0, 1.0)
		if visit.distance > 0.01:
			var key := "truck" if visit.client.kind == "truck" else "cars"
			layers[key] = maxf(layers.get(key, 0.0), nearness * 0.62)
		if visit.phase != Phase.WORKING:
			continue
		if SERVICE_SOUND.has(visit.service):
			var cue: String = "workshop" if visit.service == "truck" and is_desert() else SERVICE_SOUND[visit.service]
			layers[cue] = maxf(layers.get(cue, 0.0), nearness * 0.70)
	route_audio.update_field(layers, operations.modal_open())

func _notification(what: int) -> void:
	if not mounted:
		return
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			if suspended_at < 0:
				if wall_override < 0:
					economy.clock = campaign.boost.observe_device(int(Time.get_unix_time_from_system()))
				economy.checkpoint()
				suspended_at = Time.get_ticks_msec()
				ads.cancel_wait()
				render_budget.clear_sample()
				if OS.has_feature("mobile"):
					paused_3d = get_viewport().disable_3d
					get_viewport().disable_3d = true
		NOTIFICATION_APPLICATION_RESUMED:
			if suspended_at >= 0:
				var now := campaign.boost.observe_device(int(Time.get_unix_time_from_system())) if wall_override < 0 else wall_override
				economy.capture_absence(now)
				if OS.has_feature("mobile"):
					get_viewport().disable_3d = paused_3d
				purchases.resume()
				suspended_at = -1
				simulation_clock = float(economy.clock)
				economy.checkpoint()
				if not deferred_ad_feedback.is_empty():
					var reward := deferred_ad_feedback
					deferred_ad_feedback = ""
					ad_rewarded(reward)
				elif not economy.offline_pending.empty() and not ads.busy() and not operations.modal_open():
					operations.show_page("offline")
				refresh()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			if practice_open():
				practice_screen.dismiss()
			elif operations.modal_open():
				operations.hide_page()
			else:
				leave_game()
		NOTIFICATION_WM_CLOSE_REQUEST:
			leave_game()

func leave_game() -> void:
	if closing:
		return
	closing = true
	ads.cancel_wait()
	set_physics_process(false)
	economy.checkpoint()
	route_audio.shut_down()
	# Playback handles are released on the next audio mix cycles.
	await get_tree().create_timer(.15).timeout
	get_tree().quit()

func _exit_tree() -> void:
	if not paused_3d and suspended_at >= 0 and OS.has_feature("mobile"):
		get_viewport().disable_3d = false
	if mounted and not traveling and economy.dirty:
		economy.checkpoint()
	if mounted:
		economy.commerce.reservations.clear()
		Art.release_region(economy.district)
		economy.save_hook = Callable()

func select_site(id: String) -> void:
	selected = id
	overview = false
	quantity = 1
	message_time = 0.0
	frame_camera()
	refresh()

func manage_site(id: String) -> void:
	select_site(id)
	open_page("upgrades")

func select_quantity(count: int) -> void:
	quantity = count
	refresh()
	if operations.modal_open() and operations.page == "upgrades":
		operations.refresh()

func serve_customer() -> void:
	traffic.dispatch.start_manual(selected)

func practice_open() -> bool:
	return is_instance_valid(practice_screen) and practice_screen.visible

func start_practice(id: String) -> void:
	var kind := Practice.mode(economy, id)
	if kind.is_empty() or Practice.wait(economy, kind) > 0 or practice_open() or traveling or ads.busy() or purchases.busy():
		return
	operations.hide_page()
	camera_rig.release_gestures()
	practice_screen = PracticeScreen.new()
	add_child(practice_screen)
	practice_screen.open(self, kind, id, func() -> void: open_page("upgrades"))

func open_page(name: String) -> void:
	if name == "diagnostics" and not is_instance_valid(diagnostics):
		return
	if traveling or ads.displaying() or practice_open():
		return
	if name in operations.development.PAGES:
		sync_estate(true)
	if name == "shop":
		log_commercial("shop_opened")
		purchases.open()
	elif name == "pass":
		purchases.open()
	camera_rig.release_gestures()
	camera_rig.cancel_film(true)
	if economy.tutorial_step == 2 and name == "goals":
		operations.goals_tab = "career"
	operations.show_page(name)

func skip_tutorial() -> void:
	economy.finish_tutorial()
	economy.checkpoint()

func invest() -> void:
	invest_in(selected, economy.level(selected) == 0)

func build_site(id: String) -> void:
	if economy.level(id) == 0:
		invest_in(id, true)

func invest_in(id: String, opening: bool) -> void:
	if traveling or economy.storage.read_only:
		return
	var installed: int = campus.roof_counts[id]
	var before_art := fuel_art_level
	var previous_bays := economy.capacity(id)
	var finishes_guide := opening and id == "market" and economy.tutorial_step == 5
	var bought := int(economy.unlock(id)) if opening else economy.buy_levels(id, quantity)
	if bought <= 0:
		return
	if opening and selected != id:
		select_site(id)
	campaign.ledger.increment(economy, {"building": bought})
	campaign.premium.record_season(economy.clock, {"building": bought}, bought * 4)
	log_commercial("building_upgrade", id)
	var after_bays := economy.capacity(id)
	var rebuilt: bool = fuel_art_level > before_art or campus.roof_counts[id] > installed or after_bays > previous_bays
	if id == "fuel" and fuel_art_level > before_art:
		station.animate_construction()
	campus.animate_install(id, installed)
	feedback.play("new_site" if opening else "build", true)
	if rebuilt or opening:
		var at: Vector3 = routes.position_of(id, 0)
		effects.construction(at)
		if operations.modal_open() and (opening or operations.page == "upgrades"):
			operations.hide_page()
		camera_rig.start_film(campus.focus(id), func() -> void:
			var caption := t("opened_notice" if opening else "venue_expanded") % site_name(id)
			if after_bays > previous_bays:
				caption += "\n" + t("venue_capacity") % after_bays
			hud.announce(caption, hud.UPGRADE_ART, motion_enabled()))
	if not opening:
		show_message(t("bought_levels") % bought)
	elif finishes_guide:
		show_message(t("guide_complete"))
	economy.checkpoint()

func hire_worker() -> void:
	if economy.hire(selected):
		economy.checkpoint()

func train_worker(index: int) -> void:
	if economy.train(selected, index):
		economy.checkpoint()

func promote_worker(index: int) -> void:
	if economy.promote(selected, index):
		promotion_feedback(t("promotion_notice"), hud.STAFF)
		economy.checkpoint()

func assign_manager(id: String) -> void:
	if economy.assign(id):
		economy.checkpoint()

func train_manager(id: String) -> void:
	if economy.train_manager(id):
		promotion_feedback(t("manager_notice") % [BOOK.MANAGERS[id].name, economy.manager_rank(id)], hud.STAFF)
		economy.checkpoint()

func claim_milestone(id: String) -> void:
	if economy.claim_reward(id):
		last_mission = {"mission": id, "offer_day": economy.day_index()}
		reward_feedback("mission")
		economy.checkpoint()

func claim_calendar() -> void:
	var offer := economy.claim_calendar()
	if offer.is_empty():
		return
	reward_feedback("reward", offer[0] == "cash")
	if offer[0] != "card":
		hud.announce(t("calendar_received") % operations.extra.reward_name(offer),
			operations.extra.reward_icon(offer), motion_enabled())
	economy.checkpoint()

func claim_achievement(id: String) -> void:
	if economy.claim_achievement(id):
		reward_feedback("mission", false)
		economy.checkpoint()

func redeem_voucher() -> void:
	if economy.redeem_voucher():
		feedback.play("reward", true)
		economy.checkpoint()

func claim_player_reward() -> void:
	if economy.claim_player_reward():
		reward_feedback()
		economy.checkpoint()

func claim_daily() -> void:
	if economy.claim_daily():
		reward_feedback()
		economy.checkpoint()

func exchange_points(card: bool) -> void:
	if economy.exchange(card):
		economy.checkpoint()

func buy_boost() -> void:
	if economy.buy_boost():
		economy.checkpoint()

func toggle_language() -> void:
	set_language("en" if economy.language == "pl" else "pl")

func set_language(value: String) -> void:
	economy.language = "en" if value.to_lower() == "en" else "pl"
	apply_setting()

func set_quality(index: int) -> void:
	economy.preferences.quality = clampi(index, 0, 3)
	economy.preferences.quality_auto = false
	apply_setting()

func set_quality_auto() -> void:
	economy.preferences.quality_auto = not economy.preferences.quality_auto
	render_budget.reset()
	apply_setting()

func apply_render_quality() -> void:
	var prefs = economy.preferences
	var tier: int = 0 if economy.low_power else (render_budget.active if prefs.quality_auto else prefs.quality)
	var cap := 30 if tier == 0 else int(prefs.effective_fps(economy.low_power))
	if Engine.max_fps != cap:
		Engine.max_fps = cap
	if render_quality == tier:
		return
	render_quality = tier
	render_budget.apply(get_viewport(), tier)
	lighting.set_quality(tier)
	effects.set_quality(tier)
	apply_weather()

func _process(delta: float) -> void:
	if mounted and suspended_at < 0 and not traveling and not economy.low_power \
			and economy.preferences.quality_auto and not operations.modal_open() and not ads.busy() \
			and render_budget.sample(delta, economy.preferences.fps):
		apply_render_quality()

func set_fps(choice: int) -> void:
	economy.preferences.fps = 30 if choice in [0, 30] else 60
	apply_setting()

func toggle_power() -> void:
	economy.low_power = not economy.low_power
	apply_setting()

func toggle_haptics() -> void:
	economy.preferences.haptics = not economy.preferences.haptics
	economy.feedback_enabled = economy.preferences.haptics
	apply_setting()

func set_volume(channel: String, level: float) -> void:
	if channel in economy.preferences.volumes:
		economy.preferences.volumes[channel] = clampf(level, 0.0, 1.0)
		route_audio.apply(economy.preferences)
		economy.dirty = true
		preferences_timer.start(0.3)

func apply_setting() -> void:
	economy.touch()
	if operations.modal_open() and operations.page == "settings":
		operations.refresh()
	economy.checkpoint()

func upgrade_offline() -> void:
	if economy.buy_offline_limit():
		feedback.play("build", true)
		economy.checkpoint()

func income_action() -> void:
	if not economy.offline_pending.empty():
		operations.show_page("offline")
	else:
		collect_income()

func collect_income() -> void:
	var origin: Vector2 = hud.income.get_global_rect().get_center()
	var cash := economy.collect()
	if not cash.empty():
		show_message(t("collect_action") % money(cash))
		if not economy.low_power:
			hud.animate_reward(origin, true)
		feedback.play("reward", true)
		economy.checkpoint()

func claim_offline() -> void:
	if ads.displaying():
		return
	ads.cancel_wait()
	var value := economy.redeem_offline()
	if not value.empty():
		operations.hide_page()
		show_message(t("collect_action") % money(value))
		reward_feedback()
		economy.checkpoint()

func sync_commercial_clock() -> void:
	if wall_override >= 0:
		return
	var now := campaign.boost.observe_device(int(Time.get_unix_time_from_system()))
	if suspended_at >= 0:
		economy.capture_absence(now)
	else:
		economy.clock = now

func offer_ad(id: String, detail: Dictionary = {}) -> void:
	if not ads.request(id, detail):
		show_message(t("bonus_unavailable"))
	operations.refresh()

func on_ad_state_changed() -> void:
	if is_instance_valid(hud.boost_button):
		refresh_boost_hud()
	operations.refresh()

func ad_rewarded(id: String) -> void:
	if suspended_at >= 0:
		deferred_ad_feedback = id
		return
	if id == "boost":
		boost_was_active = true
		feedback.play("boost", true)
		if motion_enabled():
			for building in economy.facilities:
				if economy.level(building) > 0:
					effects.confetti(routes.position_of(building, 0), Color("#f6cb58"), 6)
			hud.animate_reward(hud.boost_button.get_global_rect().get_center(), true)
		hud.announce(t("boost_earned"), hud.BOLT, motion_enabled())
	elif id == "offline":
		if operations.page == "offline":
			operations.hide_page()
		reward_feedback()
	else:
		reward_feedback("reward", id in ["cash", "mission", "freight_tip", "practice_bonus"])
		if id == "upgrade":
			effects.construction(routes.position_of(selected, 0))
		show_message(t("ad_rewarded"))
	operations.refresh()
	refresh()

func purchase_delivered(id: String) -> void:
	feedback.play("reward", true)
	hud.announce(t("store_delivered") % t("product_" + id), hud.GIFT, motion_enabled())
	if motion_enabled():
		hud.animate_reward(get_viewport().get_visible_rect().get_center(), true, "diamond")

func consider_ad_break() -> void:
	if operations.page == "atlas":
		ads.natural_break()

func log_commercial(event: String, placement := "") -> void:
	campaign.premium.record(event, economy.clock, placement)

func set_local_analytics() -> void:
	var state := campaign.premium
	state.analytics = not state.analytics
	if not state.analytics:
		state.activity_log.clear()
	economy.checkpoint()
	operations.refresh()

func claim_pass(index: int, tier: int, paid: bool) -> void:
	if index < 0 or index >= RevenueConfig.SEASONS.size() or tier < 1 or tier > RevenueConfig.SEASON_TIERS:
		return
	var season := RevenueConfig.season_profile(index)
	if economy.clock < season.start or economy.clock >= season.claim_end:
		return
	var result := campaign.premium.apply(campaign, func() -> bool:
		var p := campaign.premium.progress(season.sku)
		var track: Dictionary = p.premium if paid else p.free
		if p.xp < tier * RevenueConfig.XP_PER_TIER or track.has(str(tier)) or (paid and not campaign.premium.entitlements.has(season.sku)):
			return false
		track[str(tier)] = true
		campaign.premium.grant_items(campaign, economy, RevenueConfig.pass_reward(tier, paid, season.id))
		return true)
	if result:
		reward_feedback()
		operations.refresh()

func on_economy_changed() -> void:
	var geometry_changed := live_levels != economy.levels or live_language != economy.language
	if geometry_changed:
		live_levels = economy.levels.duplicate()
		live_language = economy.language
		campus.update_sites(economy)
		var art_level: int = mini(5, economy.level("fuel")) if economy.district == "north" else campus.roof_counts.fuel
		if economy.district != "north":
			station.set_bays(economy.capacity("fuel"))
		else:
			station.set_market_open(economy.level("market") > 0)
		if fuel_art_level != art_level:
			fuel_art_level = art_level
			if economy.district == "north":
				station.setup(art_level)
			landscape.set_forecourt_tier(art_level)
	if is_instance_valid(estate_view) or not economy.works.levels.is_empty() or not economy.works.designs.is_empty():
		sync_estate()
	var roster := {}
	for id in economy.crew:
		roster[id] = economy.crew[id].map(func(person: Dictionary) -> Array: return [person.rank, person.get("specialty", "")])
	if live_crew != roster or live_directors != economy.equipped:
		live_crew = roster
		live_directors = economy.equipped.duplicate()
		crew.roster(economy)
	route_audio.apply(economy.preferences)
	if mounted:
		for id in economy.cards:
			if not shown_cards.has(id):
				feedback.play("manager", true)
				hud.announce(t("manager_received") % BOOK.MANAGERS[id].name, operations.extra.portrait(id), motion_enabled())
		if economy.amount("diamond").compare(known_diamonds) > 0 and motion_enabled():
			hud.animate_reward(get_viewport().get_visible_rect().get_center(), true, "diamond")
	shown_cards = economy.cards.duplicate()
	known_diamonds = economy.amount("diamond")
	if economy.tutorial_step != guided_step:
		guided_step = economy.tutorial_step
		if guided_step == economy.TUTORIAL_DONE:
			log_commercial("tutorial_completed")
		if guided_step < 5:
			select_site("fuel")
	if economy.player_level() > displayed_rank:
		displayed_rank = economy.player_level()
		promotion_feedback(t("career_level") % displayed_rank, hud.REPUTATION)
	apply_render_quality()
	if operations.page not in ["settings", "help", "privacy", "licenses", "diagnostics"]:
		operations.call_deferred("refresh")
	site_buttons.refresh()
	refresh()

func on_sale(ticket: HbtVisit) -> void:
	var metrics: Dictionary = campaign.ledger.visit(economy, ticket)
	campaign.premium.record_season(economy.clock, metrics, 6)
	if ticket.ad_guest:
		campaign.premium.vip.erase(economy.district)
		economy.checkpoint()
	if ticket.service == "market" and venue_activity != null:
		venue_activity.on_shop_sale(economy.per_service.market.count, traffic.night)
	var in_register := ticket.worker != -1 and economy.skill("collect", ticket.service) == 0
	if ticket.service == selected:
		show_message(t("register_sale" if in_register else "sale") % money(ticket.invoice))
	effects.coin_pop(ticket.location + Vector3(0, 1.24, 0), money(ticket.invoice))
	if not economy.low_power:
		hud.animate_reward(camera.unproject_position(ticket.location + Vector3.UP * 1.54), not in_register)
	if ticket.service == selected:
		feedback.play("sale", ticket.worker == -1)
	if ticket.worker == -1:
		economy.checkpoint()

func reward_feedback(cue := "reward", cash := true) -> void:
	feedback.play(cue, true)
	if cash and motion_enabled():
		hud.animate_reward(get_viewport().get_visible_rect().get_center(), true)

func promotion_feedback(value: String, icon: Texture2D) -> void:
	feedback.play("rank", true)
	hud.announce(value, icon, not economy.low_power)
	if not economy.low_power:
		effects.confetti(routes.position_of(selected, 0), Color("#f4bd6b"), 20)

func show_message(value: String) -> void:
	message = value
	message_time = 2.8
	refresh()

func t(key: String) -> String:
	return Strings.phrase(economy.language, key)

func site_name(id: String) -> String:
	var profile: HbtService = economy.facilities[id]
	return profile.name_pl if economy.language == "pl" else profile.name_en

func gate_text(id: String) -> String:
	var profile: HbtService = economy.facilities[id]
	return t("needs_gate") % [site_name(profile.prerequisite), profile.prerequisite_level, profile.reputation_gate]

func money(value: HbtAmount, full := false) -> String:
	return t("money") % (value.grouped(economy.language) if full else value.compact(economy.language))

func flow_text() -> String:
	return t("per_minute") % money(economy.income_per_minute())

func boost_time(seconds: int) -> String:
	return "%02d:%02d" % [floori(seconds / 60.0), seconds % 60]

func refresh_boost_hud() -> void:
	var left := campaign.boost.remaining(economy.clock)
	var placement := ads.placement_status("boost")
	var status := "ad_short_ready" if placement == "ready" else "ad_short_loading" \
		if placement in ["initializing", "loading", "reloading"] else "ad_short_showing" \
		if placement == "showing" else "ad_short_unavailable"
	hud.set_boost(left, RevenueConfig.CAP_SECONDS, boost_time(left), t("boost_active"), t(status), motion_enabled())

@warning_ignore("integer_division")
func clock_text(seconds: int) -> String:
	return "%dh %02dm" % [seconds / 3600, seconds / 60 % 60] if seconds >= 3600 else "%dm %02ds" % [seconds / 60, seconds % 60]

func refresh() -> void:
	if not is_instance_valid(hud.cash):
		return
	refresh_boost_hud()
	if operations.page in ["boost", "reward_offer"] and operations.modal_open():
		operations.refresh()
	if operations.modal_open():
		operations.premium.update_clock()
	hud.lighting.text = t(LOOK_LABELS[lighting.current])
	hud.lighting.tooltip_text = t("lighting_tip")
	hud.view.text = t("station_view" if overview else "map")
	hud.view.tooltip_text = t("view_tip")
	hud.location.text = Atlas.DESTINATIONS[campaign.active].area if economy.district != "north" else t("location")
	hud.title.text = district_name(campaign.active)
	hud.pages.atlas.text = t("atlas_button")
	hud.cash_caption.text = t("cash_short")
	hud.update_cash(economy.amount("cash"), economy.language, t("money"), motion_enabled())
	for key in hud.wallet_stats:
		hud.wallet_names[key].text = t(key)
		hud.update_balance(key, economy.amount(key), economy.language, motion_enabled())
	for name in ["sites", "team", "managers", "goals", "shop"]:
		hud.pages[name].text = t("nav_" + name)
	for name in ["finance", "calendar", "settings", "rank"]:
		hud.pages[name].tooltip_text = t(name + "_header")
	hud.rank.text = t("player_short") % economy.player_level()
	hud.badges.rank.visible = economy.player_level() > economy.paid_player_level
	hud.badges.goals.visible = economy.ready_rewards() > 0
	hud.badges.calendar.visible = economy.recognition.is_available(economy.day_index())
	hud.station.text = site_name(selected)
	hud.management_toggle.text = t("management_expand" if hud.management_collapsed else "management_collapse")
	hud.upgrade_preview.text = t("look_action")
	if quantity != 1:
		hud.upgrade_preview.text = "MAX" if quantity == 0 else "+%d" % quantity
	var pumps := selected == "fuel" or (selected == "truck" and economy.district == "north")
	hud.detail_icon.texture = hud.PUMP if pumps else hud.NAV.sites
	hud.serve.icon = hud.PUMP if pumps else hud.NAV.sites
	var tier := economy.level(selected)
	hud.level.text = t("level") % [tier, economy.CONFIG.max_level] if tier > 0 else t("site_closed").to_upper()
	hud.rate.text = flow_text()
	var checkout := traffic.dispatch.first_at(selected, Phase.READY)
	var job := traffic.dispatch.first_at(selected, Phase.WORKING)
	hud.serve.text = t("serve_fuel" if pumps else "serve_work")
	hud.serve.disabled = checkout == null
	if tier == 0:
		var quote := economy.construction_quote(selected)
		hud.upgrade.text = t("unlock") % money(quote.cost)
		hud.upgrade.disabled = not quote.ready
	else:
		var estimate := economy.quote_upgrade(selected, quantity)
		hud.upgrade.text = t("max") if tier == economy.CONFIG.max_level else t("upgrade") % money(estimate.cost)
		hud.upgrade.disabled = not estimate.affordable
	hud.set_upgrade_ready(not hud.upgrade.disabled, motion_enabled())
	var waiting: int = traffic.dispatch.queued_by_service().get(selected, 0) - traffic.dispatch.bays[selected].size()
	hud.station.tooltip_text = t("site_state") % [traffic.dispatch.bays[selected].size(), economy.capacity(selected), maxi(0, waiting)]
	if economy.save_error != OK:
		hud.status.text = t("save_error")
	elif tier == 0:
		hud.status.text = gate_text(selected)
	elif message_time > 0.0:
		hud.status.text = message
	elif checkout != null:
		hud.status.text = t("waiting_type") % t("type_" + checkout.client.type)
	elif job != null:
		hud.status.text = t("working_type") % t("type_" + job.client.type)
	else:
		hud.status.text = t("arrivals") % waiting if waiting > 0 else t("idle_site")
	var till := economy.holding()
	hud.income.visible = not till.empty() or not economy.offline_pending.empty()
	hud.income.text = t("offline_banner") % money(economy.offline_pending) if not economy.offline_pending.empty() else t("collect_action") % money(till)

func district_name(id: String) -> String:
	return Atlas.location_name(id, economy.language)

func update_expedition() -> void:
	campaign.ledger.advance(economy.clock)
	var event: Dictionary = campaign.ledger.season()
	var token := str([event.index, event.live])
	if token != shown_event:
		shown_event = token
		campaign.theme()
		apply_weather()
		if operations.page == "seasons":
			operations.refresh()
	if economy.preferences.auto_day:
		var phase := posmod(floori(economy.clock / 90.0), 4)
		var look: Lighting.Look = [Lighting.Look.DAWN, Lighting.Look.DAY, Lighting.Look.GOLDEN, Lighting.Look.NIGHT][phase]
		if look != lighting.current:
			set_look(look)
	if operations.page == "contracts":
		operations.refresh()
	operations.expedition.update_clock()

func apply_weather() -> void:
	weather.apply(economy, campaign.ledger.season(), maxi(0, render_quality),
		economy.preferences.weather)

func choose_weather(choice: String) -> void:
	economy.preferences.weather = choice
	apply_weather()
	economy.checkpoint()
	operations.refresh()

func toggle_auto_day() -> void:
	economy.preferences.auto_day = not economy.preferences.auto_day
	economy.checkpoint()
	update_expedition()
	operations.refresh()

func on_sighting(id: String) -> void:
	if campaign.ledger.spot(economy.district, id):
		economy.dirty = true

func on_supply_delivery() -> void:
	campaign.ledger.increment(economy, {"deliveries": 1})
	economy.checkpoint()
	if operations.page == "contracts":
		operations.refresh()

func start_contract(id: String) -> void:
	if campaign.storage.read_only:
		return
	if campaign.ledger.accept(economy, id):
		feedback.play("click")
		economy.checkpoint()
		operations.refresh()

func claim_contract(id: String) -> void:
	if not campaign.storage.read_only and campaign.ledger.claim_contract(economy, id):
		reward_feedback("mission")
		economy.checkpoint()

func claim_season() -> void:
	if not campaign.storage.read_only and campaign.ledger.claim_event(economy):
		log_commercial("event_completed", str(campaign.ledger.season().id))
		reward_feedback("reward")
		economy.checkpoint()

func equip_collection(group: String, id: String) -> void:
	if not campaign.storage.read_only and campaign.ledger.select_cosmetic(economy, group, id):
		weather.display_collection(campaign.ledger.chosen.get(campaign.active, {}))
		economy.checkpoint()
		operations.refresh()

func redeem_collection(group: String) -> void:
	if not campaign.storage.read_only and campaign.ledger.set_reward(economy, group):
		reward_feedback()
		economy.checkpoint()

func sync_estate(force := false) -> void:
	if not is_instance_valid(estate_view):
		if not force and economy.works.levels.is_empty() and economy.works.designs.is_empty():
			return
		estate_view = EstateView.new()
		add_child(estate_view)
		estate_view.bind(self)
	estate_view.refresh()

func view_estate(building_works: bool) -> void:
	sync_estate(true)
	operations.hide_page()
	var at: Vector3 = Depot.yard_position(economy.district) + Vector3(0,.52,4.8) if building_works else estate_view.about
	camera_rig.frame(at, Vector3(14,24,26), 23.0, not motion_enabled())

func sync_depot() -> void:
	if is_instance_valid(depot):
		depot.update_clock(economy.clock)
	elif campaign.freight.vehicles.values().any(func(record: Dictionary) -> bool: return record.home == economy.district) \
			or not campaign.freight.visible_jobs(economy.district, economy.clock).is_empty():
		depot = Depot.new()
		add_child(depot)
		depot.bind(campaign.freight, economy.district, economy.clock)

func view_depot() -> void:
	sync_depot()
	if not is_instance_valid(depot):
		return
	operations.hide_page()
	camera_rig.frame(depot.position + Vector3(0, .8, 0), Vector3(14, 24, 26), 24.0, not motion_enabled())

func travel_to(id: String) -> void:
	if closing or traveling or ads.busy() or purchases.busy() or not campaign.available(id) or id == campaign.active:
		return
	var first := not campaign.districts.has(id)
	var stream := await stream_destination(id)
	if stream == null:
		return
	sync_commercial_clock()
	if campaign.travel(id) != OK:
		stream.queue_free()
		stop_travel()
		return
	if first:
		log_commercial("location_unlocked", id)
		economy.checkpoint()
	stream.replace.call_deferred(self, campaign, seed_override, wall_override)

func confirm_prestige() -> void:
	if closing or traveling or ads.busy() or purchases.busy() or operations.page != "prestige_confirm" or not operations.modal_open():
		return
	var stream := await stream_destination(campaign.active)
	if stream == null:
		return
	if campaign.prestige(true) != OK:
		stream.queue_free()
		stop_travel()
		return
	feedback.play("rank", true)
	stream.replace.call_deferred(self, campaign, seed_override, wall_override)

func stream_destination(id: String) -> WorldStream:
	traveling = true
	set_physics_process(false)
	var stream := WorldStream.new()
	get_tree().root.add_child(stream)
	stream.start(Atlas.DESTINATIONS[id].scene, id)
	var animated := motion_enabled()
	var curtain: Tween
	if animated:
		curtain = travel_veil(t("journey_depart") % district_name(id), true)
	while not stream.done():
		var loading := stream.poll()
		if is_instance_valid(travel_progress):
			travel_progress.value = loading
		await get_tree().process_frame
	if animated and curtain.is_running():
		await curtain.finished
	if closing:
		stream.queue_free()
		return null
	if stream.failed or stream.target_scene == null:
		stream.queue_free()
		stop_travel()
		show_message(t("front_error"))
		return null
	return stream

func stop_travel() -> void:
	traveling = false
	if is_instance_valid(travel_layer):
		travel_layer.queue_free()
	set_physics_process(true)
	refresh()

func travel_veil(label: String, departing: bool) -> Tween:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	travel_layer = layer
	var curtain := ColorRect.new()
	curtain.color = Color("#142f38")
	layer.add_child(curtain)
	curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var title := Label.new()
	curtain.add_child(title)
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", hud.HEAVY)
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", hud.CREAM)
	title.text = label
	if departing:
		travel_progress = ProgressBar.new()
		curtain.add_child(travel_progress)
		travel_progress.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		travel_progress.offset_left = -220
		travel_progress.offset_right = 220
		travel_progress.offset_top = 72
		travel_progress.offset_bottom = 93
		travel_progress.max_value = 1.0
		travel_progress.show_percentage = false
		travel_progress.add_theme_stylebox_override("background", hud.style(Color("#274551"), Color("#56777d"), 8, 1))
		travel_progress.add_theme_stylebox_override("fill", hud.style(Color("#ebb96f"), Color("#f0d39f"), 8, 1))
	curtain.modulate.a = 0.0 if departing else 1.0
	var fade := create_tween().set_trans(Tween.TRANS_CUBIC)
	fade.tween_property(curtain, "modulate:a", 1.0 if departing else 0.0, .37 if departing else .51)
	if not departing:
		fade.tween_callback(layer.queue_free)
	return fade
