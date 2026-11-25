extends Node3D

const Routes = preload("res://data/economy/routes.gd")
const TrafficManager = preload("res://scripts/traffic/traffic_manager.gd")
const Landscape = preload("res://scripts/buildings/roadside_landscape.gd")
const Campus = preload("res://scripts/buildings/roadside_campus.gd")
const Lighting = preload("res://scripts/art/world_lighting.gd")
const Effects = preload("res://scripts/art/world_effects.gd")
const Crew = preload("res://scripts/employees/world_crew.gd")
const Ads = preload("res://scripts/monetization/offline_ads.gd")
const Operations = preload("res://scripts/core/operations_panel.gd")
const Station = preload("res://scenes/buildings/fuel_station.tscn")
const Driver = preload("res://scenes/characters/driver.tscn")
const Hud = preload("res://scenes/ui/station_hud.tscn")
const Strings = preload("res://localization/strings.gd")
const BOOK = preload("res://data/economy/progression.gd")
const LOOK_LABELS := ["day", "golden", "evening", "night"]
const Phase = HbtVisit.Phase

var economy := HbtEconomy.new()
var traffic := TrafficManager.new()
var station := Station.instantiate()
var landscape := Landscape.new()
var driver := Driver.instantiate()
var hud := Hud.instantiate()
var campus := Campus.new()
var crew := Crew.new()
var operations := Operations.new()
var camera := Camera3D.new()
var lighting := Lighting.new()
var effects := Effects.new()
var ads := Ads.new()

var selected := "fuel"
var quantity := 1
var overview := false
var wall_override := -1
var seed_override := -1
var hud_time := 0.0
var autosave := 0.0
var simulation_clock := 0.0
var message := ""
var message_time := 0.0
var suspended_at := -1
var mounted := false
var fuel_art_level := 1

func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--save-path="):
			economy.storage.path = argument.trim_prefix("--save-path=")
	economy.restore(wall_override)
	simulation_clock = float(economy.clock)
	add_child(lighting)
	setup_camera()
	add_child(landscape)
	add_child(campus)
	add_child(effects)
	add_child(station)
	fuel_art_level = mini(5, economy.level("fuel"))
	station.set_market_open(economy.level("market") > 0)
	station.setup(fuel_art_level)
	landscape.set_forecourt_tier(fuel_art_level)
	add_child(traffic)
	traffic.start(economy, int(Time.get_ticks_usec()) if seed_override < 0 else seed_override)
	add_child(crew)
	add_child(driver)
	driver.position = Routes.worker_at("fuel", 0)
	driver.rotation.y = -2.56
	add_child(hud)
	add_child(operations)
	operations.setup(self, hud)
	economy.changed.connect(on_economy_changed)
	traffic.dispatch.state_changed.connect(refresh)
	traffic.dispatch.completed.connect(on_sale)
	hud.serve_requested.connect(serve_customer)
	hud.upgrade_requested.connect(invest)
	hud.language_requested.connect(toggle_language)
	hud.power_requested.connect(toggle_power)
	hud.lighting_requested.connect(cycle_lighting)
	hud.view_requested.connect(toggle_view)
	hud.page_requested.connect(operations.show_page)
	hud.quantity_requested.connect(select_quantity)
	hud.income_requested.connect(income_action)
	ads.attach()
	ads.earned.connect(claim_rewarded)
	ads.availability_changed.connect(operations.refresh)
	get_viewport().size_changed.connect(frame_camera)
	frame_camera()
	on_economy_changed()
	mounted = true
	get_tree().auto_accept_quit = false
	economy.checkpoint()
	if not economy.offline_pending.empty():
		operations.show_page("offline")

func setup_camera() -> void:
	add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.current = true

func frame_camera() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var aspect := viewport_size.x / maxf(1.0, viewport_size.y)
	if overview:
		aim_camera(Vector3(7.0, 0.0, -3.9), Vector3(16.0, 39.0, 32.5), maxf(72.0, aspect * 63.0))
	else:
		var subject: Vector3 = campus.focus(selected) + Vector3(-0.54, 0.62, -0.88)
		aim_camera(subject, Vector3(15.3, 34.7, 31.5), maxf(22.6, aspect * 31.5))

func aim_camera(target: Vector3, offset: Vector3, width: float) -> void:
	camera.position = target + offset
	camera.look_at(target)
	camera.size = width

func set_look(preset: Lighting.Look) -> void:
	lighting.set_look(preset)
	traffic.set_night(preset >= Lighting.Look.EVENING)
	refresh()

func cycle_lighting() -> void:
	set_look((int(lighting.current) + 1) % LOOK_LABELS.size())

func toggle_view() -> void:
	overview = not overview
	frame_camera()
	refresh()

func _physics_process(delta: float) -> void:
	if suspended_at < 0:
		tick_game(delta)

func tick_game(delta: float) -> void:
	simulation_clock += delta
	economy.clock = int(simulation_clock)
	traffic.physics_step(delta)
	crew.update(economy, traffic.dispatch, delta)
	update_scene(delta)
	autosave += delta
	if autosave >= economy.CONFIG.checkpoint_seconds:
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
	var primary_manual := primary != null and primary.phase == Phase.WORKING and primary.worker < 0
	driver.represent_service(primary_ready and economy.crew.fuel.is_empty(), primary_manual, delta)
	var filling := traffic.dispatch.first_at("fuel", Phase.WORKING)
	if filling == null:
		filling = traffic.dispatch.first_at("truck", Phase.WORKING)
	if filling != null:
		var worker: Node3D = driver if filling == primary and primary_manual else crew.performer(filling)
		var has_prop: bool = is_instance_valid(worker) and is_instance_valid(worker.prop) and worker.prop.visible
		var source: Vector3 = station.hose_anchor() if filling == primary else campus.hose_anchor(filling)
		effects.set_hose(has_prop, worker.prop.global_position if has_prop else Vector3.ZERO, source)
	else:
		effects.set_hose(false, Vector3.ZERO)
	effects.set_activity(traffic.dispatch.first_at("wash", Phase.WORKING), traffic.dispatch.first_at("workshop", Phase.WORKING))
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
	hud.progress.value = job.progress() if job != null else 0.0

func _notification(what: int) -> void:
	if not mounted:
		return
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			if suspended_at < 0:
				var wall := int(Time.get_unix_time_from_system())
				if wall_override < 0 and absi(wall - economy.clock) < economy.CONFIG.clock_tolerance_seconds:
					economy.clock = maxi(economy.clock, wall)
				economy.checkpoint()
				suspended_at = Time.get_ticks_msec()
		NOTIFICATION_APPLICATION_RESUMED:
			if suspended_at >= 0:
				var away := floori((Time.get_ticks_msec() - suspended_at) / 1000.0)
				var now := int(Time.get_unix_time_from_system())
				economy.capture_absence(now, away)
				suspended_at = -1
				simulation_clock = float(economy.clock)
				economy.checkpoint()
				if not economy.offline_pending.empty() and not ads.busy():
					operations.show_page("offline")
				refresh()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			if operations.visible:
				operations.hide_page()
			else:
				economy.checkpoint()
				get_tree().quit()
		NOTIFICATION_WM_CLOSE_REQUEST:
			economy.checkpoint()
			get_tree().quit()

func _exit_tree() -> void:
	if mounted and economy.dirty:
		economy.checkpoint()

func select_site(id: String) -> void:
	selected = id
	overview = false
	quantity = 1
	message_time = 0.0
	frame_camera()
	refresh()

func select_quantity(count: int) -> void:
	quantity = count
	refresh()

func serve_customer() -> void:
	traffic.dispatch.start_manual(selected)

func invest() -> void:
	var installed: int = campus.roof_counts[selected]
	var before_art := fuel_art_level
	if economy.level(selected) == 0:
		if economy.unlock(selected):
			campus.animate_install(selected, installed)
			effects.construction(Routes.position_of(selected, 0))
			economy.checkpoint()
		return
	var count := economy.buy_levels(selected, quantity)
	if count <= 0:
		return
	if selected == "fuel" and fuel_art_level > before_art:
		station.animate_construction()
	campus.animate_install(selected, installed)
	effects.construction(Routes.position_of(selected, 0))
	show_message(t("bought_levels") % count)
	economy.checkpoint()

func hire_worker() -> void:
	if economy.hire(selected):
		economy.checkpoint()

func train_worker(index: int) -> void:
	if economy.train(selected, index):
		economy.checkpoint()

func promote_worker(index: int) -> void:
	if economy.promote(selected, index):
		economy.checkpoint()

func assign_manager(id: String) -> void:
	if economy.assign(id):
		economy.checkpoint()

func claim_milestone(id: String) -> void:
	if economy.claim_reward(id):
		economy.checkpoint()

func claim_daily() -> void:
	if economy.claim_daily():
		economy.checkpoint()

func exchange_points(card: bool) -> void:
	if economy.exchange(card):
		economy.checkpoint()

func buy_boost() -> void:
	if economy.buy_boost():
		economy.checkpoint()

func toggle_language() -> void:
	economy.language = "en" if economy.language == "pl" else "pl"
	economy.touch()
	economy.checkpoint()

func toggle_power() -> void:
	economy.low_power = not economy.low_power
	economy.touch()
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
		economy.checkpoint()

func claim_offline() -> void:
	if ads.busy():
		return
	var value := economy.redeem_offline()
	if not value.empty():
		operations.hide_page()
		show_message(t("collect_action") % money(value))
		economy.checkpoint()

func start_offline_ad() -> void:
	if not ads.request(economy.offline_pending):
		show_message(t("bonus_unavailable"))
	operations.refresh()

func claim_rewarded(base: HbtAmount) -> void:
	var value := economy.redeem_offline(true, base)
	if not value.empty():
		operations.hide_page()
		show_message(t("collect_action") % money(value))
		economy.checkpoint()

func on_economy_changed() -> void:
	station.set_market_open(economy.level("market") > 0)
	var art_level := mini(5, economy.level("fuel"))
	if fuel_art_level != art_level:
		fuel_art_level = art_level
		station.setup(art_level)
		landscape.set_forecourt_tier(art_level)
	campus.update_sites(economy)
	crew.roster(economy)
	Engine.max_fps = 30 if economy.low_power else 60
	lighting.set_reduced(economy.low_power)
	effects.reduced = economy.low_power
	var render_scale := 0.80 if economy.low_power else 1.0
	if not is_equal_approx(get_viewport().scaling_3d_scale, render_scale):
		get_viewport().scaling_3d_scale = render_scale
	operations.call_deferred("refresh")
	refresh()

func on_sale(ticket: HbtVisit) -> void:
	var in_register := ticket.worker >= 0 and economy.skill("collect") == 0
	if ticket.service == selected:
		show_message(t("register_sale" if in_register else "sale") % money(ticket.invoice))
	effects.coin_pop(ticket.location + Vector3(0, 1.24, 0), money(ticket.invoice))
	if not economy.low_power:
		hud.animate_reward(camera.unproject_position(ticket.location + Vector3.UP * 1.54), not in_register)
	if ticket.worker < 0:
		economy.checkpoint()

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
	return t("money") % (value.decimal() if full else value.compact(economy.language))

func flow_text() -> String:
	var flow := economy.income_per_minute()
	var units := flow.divided(60)
	if units.empty():
		var digit := flow.divided(6).decimal()
		if digit != "0":
			var decimal := "," if economy.language == "pl" else "."
			return t("per_second") % (t("money") % ("0" + decimal + digit))
	return t("per_second") % money(units)

@warning_ignore("integer_division")
func clock_text(seconds: int) -> String:
	return "%dh %02dm" % [seconds / 3600, seconds / 60 % 60] if seconds >= 3600 else "%dm %02ds" % [seconds / 60, seconds % 60]

func refresh() -> void:
	if not is_instance_valid(hud.cash):
		return
	hud.lighting.text = t(LOOK_LABELS[lighting.current])
	hud.lighting.tooltip_text = t("lighting_tip")
	hud.view.text = t("station_view" if overview else "map")
	hud.view.tooltip_text = t("view_tip")
	hud.language.text = economy.language.to_upper()
	hud.power.text = "%d FPS" % Engine.max_fps
	hud.location.text = t("location")
	hud.title.text = t("name")
	hud.cash_caption.text = t("cash")
	hud.update_cash(economy.amount("cash"), economy.language, t("money"), not economy.low_power)
	hud.traffic_caption.text = t("road")
	hud.queued.text = str(traffic.dispatch.lanes.car.size() + traffic.dispatch.lanes.truck.size())
	hud.people_caption.text = t("customers")
	hud.people.text = HbtAmount.from(economy.customers).compact(economy.language)
	for key in hud.wallet_stats:
		hud.wallet_names[key].text = t(key)
		hud.wallet_stats[key].text = economy.amount(key).compact(economy.language)
	for name in hud.pages:
		hud.pages[name].text = t(name)
	var ready_goals := 0
	for item in BOOK.MILESTONES:
		ready_goals += int(not economy.claimed.has(item.id) and economy.metric(item.counter) >= item.goal)
	if ready_goals > 0:
		hud.pages.goals.text = t("goals_ready") % ready_goals
	hud.station.text = site_name(selected)
	hud.upgrade_preview.text = t("look_action")
	hud.serve.icon = hud.PUMP if selected in ["fuel", "truck"] else hud.NAV.sites
	var tier := economy.level(selected)
	hud.level.text = t("level") % [tier, economy.CONFIG.max_level] if tier > 0 else t("site_closed").to_upper()
	hud.rate.text = flow_text()
	var checkout := traffic.dispatch.first_at(selected, Phase.READY)
	var job := traffic.dispatch.first_at(selected, Phase.WORKING)
	hud.serve.text = t("serve_fuel" if selected in ["fuel", "truck"] else "serve_work")
	hud.serve.disabled = checkout == null
	for option in hud.quantities:
		hud.quantities[option].set_pressed_no_signal(option == quantity)
		hud.quantities[option].disabled = tier == 0 or tier >= economy.CONFIG.max_level
	if tier == 0:
		var unlock_cost := HbtAmount.from(economy.facilities[selected].unlock_cost)
		hud.upgrade.text = t("unlock") % money(unlock_cost)
		hud.upgrade.disabled = not economy.gate_open(selected) or not economy.can_afford(unlock_cost)
	else:
		var estimate := economy.quote_upgrade(selected, quantity)
		hud.upgrade.text = t("max") if tier == economy.CONFIG.max_level else t("upgrade") % money(estimate.cost)
		hud.upgrade.disabled = not estimate.affordable
	var waiting: int = traffic.dispatch.queued_by_service().get(selected, 0) - traffic.dispatch.bays[selected].size()
	hud.reserve.visible = tier > 0
	hud.reserve.text = t("site_state") % [traffic.dispatch.bays[selected].size(), economy.capacity(selected), maxi(0, waiting)]
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
