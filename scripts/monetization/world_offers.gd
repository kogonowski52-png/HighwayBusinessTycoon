extends Node3D

const Art = preload("res://scripts/art/visual_library.gd")
const Config = preload("res://data/monetization/config.gd")
const Vehicle = preload("res://scenes/vehicles/compact.tscn")
const SHOWCASES := [
	["vip", "regency"], ["cash", "post"], ["delivery", "cargo"], ["gift", "helicopter"],
	["cash", "crate"], ["delivery", "tanker"],
]

var game: Node3D
var billboard: Button
var actor: Node3D
var rotor: Node3D
var cargo: Node3D
var next := 0.0
var progress := 0.0
var option := ""
var carrier := ""
var chosen := 0
var site := Vector3.ZERO

func bind(host: Node3D) -> void:
	game = host
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	var root := Control.new()
	layer.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	billboard = game.hud.action(root, 113, 98, true)
	game.hud.button_art(billboard, game.hud.REWARD_VIDEO, 73)
	billboard.hide()
	billboard.pressed.connect(offer)
	next = game.campaign.premium.active_seconds + Config.WORLD_FIRST

func tick(delta: float) -> void:
	if not is_instance_valid(actor):
		if (game.ads.available() and game.campaign.premium.active_seconds >= next
				and not game.operations.modal_open() and game.economy.tutorial_step == game.economy.TUTORIAL_DONE):
			for attempt in SHOWCASES.size():
				var row: Array = SHOWCASES[posmod(chosen, SHOWCASES.size())]
				chosen += 1
				var selection := {"site": "fuel"} if row[1] == "tanker" else {}
				if game.ads.playable(row[0], selection):
					spawn(row[0], row[1])
					return
			next += 60.0
		return
	progress += delta
	if progress >= 30.0:
		dispose()
		return
	var u := clampf(progress / 30.0, 0.0, 1.0)
	actor.position.x = site.x + (5.2 if carrier == "crate" else lerpf(14.5, -14.5, u))
	actor.position.z = site.z + 6.1
	if carrier == "helicopter":
		actor.position.y = 3.9 + sin(u * TAU) * .51
		actor.position.z += sin(u * PI) * 2.0
		rotor.rotate_y(delta * 32.0)
		cargo.position.y = -.82 - sin(u * PI) * 1.6
	elif carrier == "crate":
		actor.position.y = .55 + sin(u * TAU * 3.0) * .14
		actor.rotate_y(delta * .7)
	else:
		actor.spin(delta * .975)
	var landmark := actor.global_position + Vector3.UP * (1.8 if carrier == "helicopter" else 2.17)
	var at: Vector2 = game.camera.unproject_position(landmark)
	var rect := Rect2(at - billboard.size * 0.5, billboard.size)
	var visible_now: bool = (not game.camera.is_position_behind(landmark)
		and get_viewport().get_visible_rect().grow(-12).encloses(rect) and not game.hud.overlaps_world(rect)
		and not game.operations.modal_open() and game.camera_rig.film.is_empty())
	billboard.visible = visible_now
	billboard.position = rect.position

func spawn(id: String, model: String) -> void:
	if is_instance_valid(actor):
		dispose()
	option = id
	carrier = model
	start_path()
	if model == "helicopter":
		actor = Art.place(self, "premium", "helicopter", site)
		rotor = Art.place(actor, "premium", "rotor", Vector3(0, 1.13, 0))
		cargo = Art.place(actor, "premium", "treasury", Vector3(0, -.82, 0))
		cargo.scale = Vector3.ONE * .43
	elif model == "crate":
		actor = Art.place(self, "premium", "treasury", site)
		actor.scale = Vector3.ONE * .85
	else:
		actor = Vehicle.instantiate()
		add_child(actor)
		actor.build("atlas" if model == "tanker" else model, 0)
		if model == "tanker":
			Art.place(actor, "transport", "tanker")
		else:
			var roof_height := 1.68 if model == "regency" else 2.48 if model == "cargo" else 1.85
			var decoration := Art.place(actor, "premium", "treasury" if model in ["cargo", "post"] else "bolt",
				Vector3(0, roof_height, -.57))
			decoration.scale = Vector3.ONE * (.66 if model == "cargo" else .40)
	actor.rotation.y = -PI / 2.0
	tick(.02)

func start_path() -> void:
	progress = 0.0
	# Roadside routes use different centre lines. Bonus vehicles cruise on the public highway.
	site = Vector3(0, .04, float(game.routes.layout.ambient) - 8.1) if game.is_regional() else Vector3(0, .04, 6.08)
	billboard.tooltip_text = game.t("offer_" + option)

func offer() -> void:
	var selection := {"site": "fuel"} if carrier == "tanker" else {}
	if not option.is_empty() and game.ads.playable(option, selection):
		game.log_commercial("roadside_offer_opened", option)
		game.operations.premium.select_offer(option, selection)
	dispose()

func dispose() -> void:
	if is_instance_valid(actor):
		actor.queue_free()
	actor = null
	billboard.hide()
	next = game.campaign.premium.active_seconds + lerpf(float(Config.WORLD_INTERVAL.x), float(Config.WORLD_INTERVAL.y), randf())
