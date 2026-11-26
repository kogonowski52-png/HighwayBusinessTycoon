extends RefCounted

const CHANNELS := ["music", "ambient", "effects"]
const DEFAULTS := {"music": 0.64, "ambient": 0.53, "effects": 0.77}

var volumes: Dictionary = DEFAULTS.duplicate()
var quality := 2
var quality_auto := OS.has_feature("mobile")
var fps := 60
var haptics := true
var weather := "auto"
var auto_day := false

func restore(data: Dictionary, old_feedback := true) -> void:
	haptics = data.get("haptics", old_feedback) == true
	quality = clampi(int(data.get("quality", 2)), 0, 3)
	quality_auto = data.get("quality_auto", data.is_empty() and OS.has_feature("mobile")) == true
	fps = 30 if int(data.get("fps", 60)) == 30 else 60
	var climate: Variant = data.get("weather", "auto")
	weather = climate if climate in ["auto", "clear", "cloud", "rain", "snow", "wind", "haze"] else "auto"
	auto_day = data.get("auto_day", false) == true
	var mixer: Variant = data.get("volumes", {})
	for channel in CHANNELS:
		var value: Variant = mixer.get(channel, DEFAULTS[channel]) if mixer is Dictionary else DEFAULTS[channel]
		volumes[channel] = clampf(float(value), 0.0, 1.0) if typeof(value) in [TYPE_FLOAT, TYPE_INT] else DEFAULTS[channel]
	if data.is_empty() and not old_feedback:
		volumes.effects = 0.0

func snapshot() -> Dictionary:
	return {"volumes": volumes.duplicate(), "quality": quality, "quality_auto": quality_auto, "fps": fps, "haptics": haptics,
		"weather": weather, "auto_day": auto_day}

func effective_quality(power_saving: bool) -> int:
	return 0 if power_saving else quality

func effective_fps(power_saving: bool) -> int:
	return 30 if power_saving else fps
