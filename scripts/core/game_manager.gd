extends Node3D

const EconomyManager = preload("res://scripts/economy/economy_manager.gd")
const TrafficManager = preload("res://scripts/traffic/traffic_manager.gd")
const Landscape = preload("res://scripts/buildings/roadside_landscape.gd")
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
var last_sale := 0
var sale_remaining := 0.0

func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--save-path="):
			economy.storage.path = argument.trim_prefix("--save-path=")
	economy.restore()
	environment()
	add_child(Landscape.new())
	add_child(station)
	station.setup(economy.level)
	add_child(traffic)
	add_child(driver)
	driver.position = Vector3(2.4, 0, 3.44)
	driver.rotation.y = -2.3
	add_child(hud)
	traffic.state_changed.connect(refresh)
	traffic.completed.connect(on_sale)
	economy.changed.connect(refresh)
	hud.serve_requested.connect(serve_customer)
	hud.upgrade_requested.connect(upgrade_station)
	hud.language_requested.connect(toggle_language)
	hud.power_requested.connect(toggle_power)
	get_viewport().size_changed.connect(frame_camera)
	frame_camera()
	refresh()

func environment() -> void:
	var backdrop := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#aab888")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#e2f2ef")
	env.ambient_light_energy = 0.36
	backdrop.environment = env
	add_child(backdrop)

	var sun := DirectionalLight3D.new()
	add_child(sun)
	sun.rotation_degrees = Vector3(-52, -37, 0)
	sun.light_color = Color("#ffe2b8")
	sun.light_energy = 0.74
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 65

	add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.position = Vector3(10.4, 26, 36.0)
	camera.look_at(Vector3(0.0, 0.0, 2.1))
	camera.current = true

func frame_camera() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var aspect := viewport_size.x / maxf(1.0, viewport_size.y)
	camera.size = maxf(25.5, aspect * 34.0)

func _process(delta: float) -> void:
	driver.represent_service(traffic.state == traffic.State.WAITING, traffic.state == traffic.State.SERVING, delta)
	var progress := traffic.progress()
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

func toggle_language() -> void:
	economy.language = "en" if economy.language == "pl" else "pl"
	economy.persist()

func toggle_power() -> void:
	economy.low_power = not economy.low_power
	economy.persist()

func on_sale() -> void:
	last_sale = economy.sell()
	sale_remaining = 2.8
	refresh()

func t(key: String) -> String:
	return Strings.phrase(economy.language, key)

func refresh() -> void:
	Engine.max_fps = 30 if economy.low_power else 60
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
