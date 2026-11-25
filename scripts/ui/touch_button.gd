extends Button

var press_motion: Tween

func _ready() -> void:
	button_down.connect(respond.bind(0.965))
	button_up.connect(respond.bind(1.0))
	pressed.connect(tap)

func respond(weight: float) -> void:
	if DisplayServer.get_name() == "headless" or Engine.max_fps == 30:
		return
	if press_motion != null and press_motion.is_running():
		press_motion.kill()
	pivot_offset = size * 0.5
	press_motion = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	press_motion.tween_property(self, "scale", Vector2.ONE * weight, 0.12 if weight < 1.0 else 0.17)

func tap() -> void:
	get_node("/root/RouteAudio").cue("click")
