extends Node3D

const EconomyManager = preload("res://scripts/economy/economy_manager.gd")
const TrafficManager = preload("res://scripts/traffic/traffic_manager.gd")
const Landscape = preload("res://scripts/buildings/roadside_landscape.gd")
const Campus = preload("res://scripts/buildings/roadside_campus.gd")
const Lighting = preload("res://scripts/art/world_lighting.gd")
const Effects = preload("res://scripts/art/world_effects.gd")
const Station = preload("res://scenes/buildings/fuel_station.tscn")
const Driver = preload("res://scenes/characters/driver.tscn")
const Hud = preload("res://scenes/ui/station_hud.tscn")
const Strings = preload("res://localization/strings.gd")

var economy := EconomyManager.new()
var traffic := TrafficManager.new()
var station := Station.instantiate()
var driver := Driver.instantiate()
var hud := Hud.instantiate()
var camera := Camera3D.new()
var lighting := Lighting.new()
var effects := Effects.new()
var overview := false
const LOOK_LABELS := ["day", "golden", "evening", "night"]
var last_sale := 0
var sale_remaining := 0.0

func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--save-path="):
			economy.storage.path = argument.trim_prefix("--save-path=")
	economy.restore()
	add_child(lighting)
	setup_camera()
	add_child(Landscape.new())
	add_child(Campus.new())
	add_child(effects)
	add_child(station)
	station.setup(economy.level)
	add_child(traffic)
	add_child(driver)
	driver.position = Vector3(2.35, 0, 3.63)
	driver.rotation.y = -2.56
	add_child(hud)
	traffic.state_changed.connect(refresh)
	traffic.completed.connect(on_sale)
	economy.changed.connect(refresh)
	hud.serve_requested.connect(serve_customer)
	hud.upgrade_requested.connect(upgrade_station)
	hud.language_requested.connect(toggle_language)
	hud.power_requested.connect(toggle_power)
	hud.lighting_requested.connect(cycle_lighting)
	hud.view_requested.connect(toggle_view)
	get_viewport().size_changed.connect(frame_camera)
	frame_camera()
	refresh()

func setup_camera() -> void:
	add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.current = true

func frame_camera() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var aspect := viewport_size.x / maxf(1.0, viewport_size.y)
	if overview:
		aim_camera(Vector3(0.5, 0.0, -2.4), Vector3(9.0, 37.0, 30.0), maxf(46.0, aspect * 58.0))
	else:
		aim_camera(Vector3(-0.20, 0.0, 1.45), Vector3(9.4, 26.5, 35.0), maxf(24.8, aspect * 34.5))

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

func _process(delta: float) -> void:
	driver.represent_service(traffic.state == traffic.State.WAITING, traffic.state == traffic.State.SERVING, delta)
	var progress := traffic.progress()
	var refueling := traffic.state == traffic.State.SERVING
	effects.set_hose(refueling, driver.prop.global_position if refueling else Vector3.ZERO)
	if traffic.crosses_forecourt():
		effects.drive_on_dust(true, traffic.active.position - traffic.active.basis.z * 1.03)
	else:
		effects.drive_on_dust(false, Vector3.ZERO)
	hud.progress.value = progress
	station.set_service_progress(progress)
	if sale_remaining > 0.0:
		sale_remaining -= delta
		if sale_remaining <= 0.0:
			refresh()

func serve_customer() -> void:
	traffic.start_service(economy.PROFILE.service_seconds[economy.level - 1])

func upgrade_station() -> void:
	if traffic.state == traffic.State.SERVING:
		return
	if economy.upgrade():
		station.setup(economy.level)
		station.animate_construction()
		effects.construction(Vector3(1.13, 0.0, -0.51))

func toggle_language() -> void:
	economy.language = "en" if economy.language == "pl" else "pl"
	economy.persist()

func toggle_power() -> void:
	economy.low_power = not economy.low_power
	economy.persist()

func on_sale() -> void:
	last_sale = economy.sell()
	effects.coin_pop(Vector3(0.92, 1.32, 2.64), t("money") % last_sale)
	sale_remaining = 2.8
	refresh()

func t(key: String) -> String:
	return Strings.phrase(economy.language, key)

func refresh() -> void:
	Engine.max_fps = 30 if economy.low_power else 60
	lighting.set_reduced(economy.low_power)
	effects.reduced = economy.low_power
	var render_scale := 0.80 if economy.low_power else 1.0
	if not is_equal_approx(get_viewport().scaling_3d_scale, render_scale):
		get_viewport().scaling_3d_scale = render_scale
	hud.lighting.text = t(LOOK_LABELS[lighting.current])
	hud.lighting.tooltip_text = t("lighting_tip")
	hud.view.text = t("station_view" if overview else "map")
	hud.view.tooltip_text = t("view_tip")
	hud.language.text = economy.language.to_upper()
	hud.power.text = "%d FPS" % Engine.max_fps
	hud.location.text = t("location")
	hud.title.text = t("name")
	hud.cash_caption.text = t("cash")
	hud.cash.text = t("money") % economy.cash
	hud.traffic_caption.text = t("road")
	hud.people_caption.text = t("customers")
	hud.people.text = str(economy.customers)
	hud.level.text = t("level") % economy.level
	hud.station.text = t("fuel")
	hud.rate.text = t("rate") % economy.PROFILE.sale_prices[economy.level - 1]
	hud.serve.text = t("serve")
	hud.serve.disabled = traffic.state != traffic.State.WAITING
	var cost: int = economy.PROFILE.upgrade_cost(economy.level)
	hud.upgrade.text = t("upgrade") % cost if cost else t("max")
	hud.upgrade.disabled = cost == 0 or economy.cash < cost or traffic.state == traffic.State.SERVING
	var phase: String = {
		traffic.State.ARRIVING: "arriving", traffic.State.WAITING: "waiting",
		traffic.State.SERVING: "serving", traffic.State.LEAVING: "open", traffic.State.GAP: "open"
	}[traffic.state]
	hud.status.text = t(phase)
	if sale_remaining > 0.0 and traffic.state == traffic.State.LEAVING:
		hud.status.text = t("sale") % last_sale
	if economy.save_error != OK:
		hud.status.text = t("save_error")
