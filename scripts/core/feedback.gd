extends Node

func play(key: String, vibrate := false) -> void:
	get_node("/root/RouteAudio").cue(key, vibrate)
