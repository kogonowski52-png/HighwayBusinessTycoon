extends Node

const SOUNDS := {
	"sale": preload("res://assets/audio/sale.wav"),
	"reward": preload("res://assets/audio/reward.wav"),
	"build": preload("res://assets/audio/build.wav"),
	"rank": preload("res://assets/audio/rank.wav"),
}
var coins := AudioStreamPlayer.new()
var cues := AudioStreamPlayer.new()
var enabled := true

func _ready() -> void:
	add_child(coins)
	add_child(cues)
	coins.volume_db = -9.0
	cues.volume_db = -5.5

func play(key: String, vibrate := false) -> void:
	if not enabled or DisplayServer.get_name() == "headless":
		return
	var bus := coins if key == "sale" else cues
	if bus == coins and bus.playing:
		return
	bus.stream = SOUNDS[key]
	bus.play()
	if vibrate and OS.has_feature("mobile"):
		Input.vibrate_handheld(26 if key == "sale" else 44, 0.35)

func _exit_tree() -> void:
	coins.stop()
	cues.stop()
