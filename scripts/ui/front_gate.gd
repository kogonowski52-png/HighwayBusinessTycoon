extends Control

const ROAD := "res://scenes/world/roadside.tscn"
const WORLD_LOGIC := "res://scripts/core/game_manager.gd"
const LOGO = preload("res://assets/ui/presentation/logo.png")
const ART = preload("res://assets/ui/presentation/station-portrait.jpg")
const Jade = preload("res://assets/ui/presentation/jade.png")
const Paper = preload("res://assets/ui/presentation/paper.png")
const FontHeavy = preload("res://assets/fonts/OpenSans-ExtraBold.ttf")
const Strings = preload("res://localization/strings.gd")
const Saving = preload("res://scripts/core/save_manager.gd")
const Preferences = preload("res://scripts/core/player_preferences.gd")
const Touch = preload("res://scripts/ui/touch_button.gd")

var play: Button
var language: Button
var loading: VBoxContainer
var load_caption: Label
var load_bar: ProgressBar
var column: VBoxContainer
var logo: TextureRect
var locale := "pl"
var resume_game := false
var busy := false
var wait_frames := 0
var load_progress := 0.0
var loading_world := false
var world_logic: Script
@onready var route_audio: Node = get_node("/root/RouteAudio")
var profile_path := ""

func _ready() -> void:
	var save := Saving.new()
	if not profile_path.is_empty():
		save.path = profile_path
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--save-path="):
			save.path = arg.trim_prefix("--save-path=")
	var profile := save.restore()
	resume_game = not profile.is_empty() or save.read_only
	locale = "en" if profile.get("language") == "en" else "pl"
	var prefs := Preferences.new()
	var stored: Variant = profile.get("preferences", {})
	prefs.restore(stored if stored is Dictionary else {}, profile.get("feedback_enabled", true) == true)
	route_audio.apply(prefs)
	route_audio.update_field({})
	route_audio.set_track("menu")
	build_layout()
	update_copy()

func build_layout() -> void:
	var colors := Gradient.new()
	colors.colors = PackedColorArray([Color("#102a31"), Color("#31555b"), Color("#153139")])
	colors.offsets = PackedFloat32Array([0.0, 0.47, 1.0])
	var sky := GradientTexture2D.new()
	sky.gradient = colors
	sky.fill_from = Vector2(0.5, 0)
	sky.fill_to = Vector2(0.5, 1)
	var backdrop := TextureRect.new()
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.texture = sky
	column = VBoxContainer.new()
	add_child(column)
	column.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", 21)
	logo = TextureRect.new()
	column.add_child(logo)
	logo.texture = LOGO
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size.y = 406
	logo.pivot_offset = Vector2(400, 210)
	logo.modulate.a = 0.0
	logo.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).tween_property(logo, "modulate:a", 1.0, .37)
	var picture_shell := PanelContainer.new()
	picture_shell.add_theme_stylebox_override("panel", skin(Paper, 11))
	picture_shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(picture_shell)
	var picture := TextureRect.new()
	picture_shell.add_child(picture)
	picture.texture = ART
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.clip_contents = true
	picture.custom_minimum_size.y = 360
	var stamp := Label.new()
	column.add_child(stamp)
	stamp.name = "Location"
	stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamp.add_theme_font_override("font", FontHeavy)
	stamp.add_theme_font_size_override("font_size", 28)
	stamp.add_theme_color_override("font_color", Color("#edc596"))
	loading = VBoxContainer.new()
	loading.custom_minimum_size.y = 123
	loading.add_theme_constant_override("separation", 9)
	column.add_child(loading)
	load_caption = Label.new()
	loading.add_child(load_caption)
	load_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	load_caption.add_theme_font_override("font", FontHeavy)
	load_caption.add_theme_font_size_override("font_size", 28)
	load_caption.add_theme_color_override("font_color", Color("#fff3d0"))
	load_bar = ProgressBar.new()
	loading.add_child(load_bar)
	load_bar.custom_minimum_size.y = 27
	load_bar.max_value = 1.0
	load_bar.step = 0.0
	load_bar.show_percentage = false
	load_bar.add_theme_stylebox_override("background", fill(Color("#192f36"), Color("#6f9286")))
	load_bar.add_theme_stylebox_override("fill", fill(Color("#efc074"), Color("#936641")))
	loading.hide()
	play = button(Jade, 126, true)
	column.add_child(play)
	play.pressed.connect(begin_loading)
	language = button(Paper, 89, false)
	language.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	language.custom_minimum_size.x = 198
	column.add_child(language)
	language.pressed.connect(switch_language)
	resized.connect(layout)
	call_deferred("layout")

func layout() -> void:
	var safe := Rect2(Vector2.ZERO, Vector2(get_window().size))
	if OS.has_feature("mobile"):
		var area := Rect2(DisplayServer.get_display_safe_area())
		if area.has_area():
			safe = area
	var ratio := size / Vector2(get_window().size).max(Vector2.ONE)
	var gutter := maxf(41.0, (size.x - 935.0) * .5)
	column.offset_left = gutter + safe.position.x * ratio.x
	column.offset_right = -gutter - (float(get_window().size.x) - safe.end.x) * ratio.x
	column.offset_top = 58 + safe.position.y * ratio.y
	column.offset_bottom = -53 - (float(get_window().size.y) - safe.end.y) * ratio.y
	logo.custom_minimum_size.y = minf(406.0, size.y * 0.23)

func button(texture: Texture2D, height: int, primary: bool) -> Button:
	var action := Touch.new()
	action.custom_minimum_size.y = height
	action.add_theme_font_override("font", FontHeavy)
	action.add_theme_font_size_override("font_size", 51 if primary else 31)
	action.add_theme_stylebox_override("normal", skin(texture, 16))
	action.add_theme_stylebox_override("hover", skin(texture, 16))
	action.add_theme_stylebox_override("pressed", fill(Color("#3a7568") if primary else Color("#ead19e"), Color("#90b4a7")))
	action.add_theme_stylebox_override("focus", fill(Color.TRANSPARENT, Color("#ffcc80")))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		action.add_theme_color_override(state, Color("#fff3d0") if primary else Color("#233d44"))
	return action

func skin(texture: Texture2D, gap: float) -> StyleBoxTexture:
	var shape := StyleBoxTexture.new()
	shape.texture = texture
	for edge in [SIDE_TOP, SIDE_LEFT, SIDE_BOTTOM, SIDE_RIGHT]:
		shape.set_texture_margin(edge, 46)
		shape.set_content_margin(edge, gap)
	return shape

func fill(color: Color, edge: Color) -> StyleBoxFlat:
	var shape := StyleBoxFlat.new()
	shape.bg_color = color
	shape.border_color = edge
	shape.set_border_width_all(3)
	shape.set_corner_radius_all(15)
	return shape

func update_copy() -> void:
	play.text = Strings.phrase(locale, "front_resume" if resume_game else "front_play")
	language.text = Strings.phrase(locale, "front_locale")
	column.get_node("Location").text = Strings.phrase(locale, "name") + " · " + Strings.phrase(locale, "location")

func switch_language() -> void:
	locale = "en" if locale == "pl" else "pl"
	update_copy()

func begin_loading() -> void:
	if busy:
		return
	busy = true
	wait_frames = 0
	load_progress = 0.0
	load_bar.value = 0.0
	loading.show()
	load_caption.text = Strings.phrase(locale, "front_loading")
	play.hide()
	language.disabled = true

func _process(delta: float) -> void:
	if not busy:
		return
	wait_frames += 1
	if wait_frames < 3:
		return
	if not loading_world:
		# Compile shared GDScript dependencies on the main thread before streaming the scene.
		world_logic = load(WORLD_LOGIC) as Script
		if world_logic == null or not world_logic.can_instantiate() or ResourceLoader.load_threaded_request(ROAD) != OK:
			show_failure()
			return
		loading_world = true
		return
	var progress := []
	var status := ResourceLoader.load_threaded_get_status(ROAD, progress)
	if status in [ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE]:
		if status == ResourceLoader.THREAD_LOAD_FAILED:
			ResourceLoader.load_threaded_get(ROAD)
		show_failure()
		return
	var latest: float = progress[0] if not progress.is_empty() else 0.0
	load_progress = move_toward(load_progress, latest, delta * 3.2)
	load_bar.value = load_progress
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var scene := ResourceLoader.load_threaded_get(ROAD) as PackedScene
		if scene == null:
			show_failure()
			return
		busy = false
		enter_game.call_deferred(scene)

func enter_game(scene: PackedScene) -> void:
	var route := scene.instantiate()
	route.entry_language = locale
	if not profile_path.is_empty():
		route.economy.storage.path = profile_path
	get_tree().root.add_child(route)
	get_tree().current_scene = route
	queue_free()

func show_failure() -> void:
	busy = false
	loading_world = false
	loading.show()
	load_caption.text = Strings.phrase(locale, "front_error")
	play.show()
	language.disabled = false
