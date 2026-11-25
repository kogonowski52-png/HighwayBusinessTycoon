extends RefCounted

const CHANNELS := ["music", "ambient", "effects"]
const DEFAULTS := {"music": 0.64, "ambient": 0.53, "effects": 0.77}

var volumes: Dictionary = DEFAULTS.duplicate()
var quality := 2
var fps := 60
var haptics := true

func restore(data: Dictionary, old_feedback := true) -> void:
	haptics = data.get("haptics", old_feedback) == true
	quality = clampi(int(data.get("quality", 2)), 0, 2)
	fps = 30 if int(data.get("fps", 60)) == 30 else 60
	var mixer: Variant = data.get("volumes", {})
	for channel in CHANNELS:
		var value: Variant = mixer.get(channel, DEFAULTS[channel]) if mixer is Dictionary else DEFAULTS[channel]
		volumes[channel] = clampf(float(value), 0.0, 1.0) if typeof(value) in [TYPE_FLOAT, TYPE_INT] else DEFAULTS[channel]
	if data.is_empty() and not old_feedback:
		volumes.effects = 0.0

func snapshot() -> Dictionary:
	return {"volumes": volumes.duplicate(), "quality": quality, "fps": fps, "haptics": haptics}

func effective_quality(power_saving: bool) -> int:
	return 0 if power_saving else quality

func effective_fps(power_saving: bool) -> int:
	return 30 if power_saving else fps
