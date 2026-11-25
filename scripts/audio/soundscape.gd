extends Node
## The title and the diorama share this mixer so their tracks can crossfade.

const BUSES := {"music": "Route Music", "ambient": "Route Ambience", "effects": "Route Effects"}
const MUSIC := {
	"menu": "res://assets/audio/music_menu.ogg",
	"day": "res://assets/audio/music_day.ogg",
	"night": "res://assets/audio/music_night.ogg",
}
const FIELD := {
	"cars": "res://assets/audio/world_cars.ogg",
	"truck": "res://assets/audio/world_truck.ogg",
	"wind": "res://assets/audio/world_wind.ogg",
	"pump": "res://assets/audio/world_pump.ogg",
	"wash": "res://assets/audio/world_wash.ogg",
	"workshop": "res://assets/audio/world_workshop.ogg",
	"diner": "res://assets/audio/world_diner.ogg",
}
const CUES := {
	"boost": "res://assets/audio/boost.wav",
	"sale": "res://assets/audio/sale.wav",
	"reward": "res://assets/audio/reward.wav",
	"build": "res://assets/audio/build.wav",
	"rank": "res://assets/audio/rank.wav",
	"click": "res://assets/audio/ui_click.ogg",
	"new_site": "res://assets/audio/ui_new_site.ogg",
	"manager": "res://assets/audio/ui_manager.ogg",
	"mission": "res://assets/audio/ui_mission.ogg",
}

var decks: Array[AudioStreamPlayer] = []
var voices: Dictionary = {}
var ambience: Dictionary = {}
var targets: Dictionary = {}
var active := 0
var track := ""
var transition: Tween
var haptics := true
var ducked := false
var streams: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for name in BUSES.values():
		if AudioServer.get_bus_index(name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, name)
	for index in range(2):
		decks.append(player(BUSES.music, -65.0))
	for key in FIELD:
		var sound := player(BUSES.ambient, -58.0)
		sound.stream = looped(sound_file(FIELD[key]) as AudioStreamOggVorbis)
		ambience[key] = sound
		targets[key] = 0.0
	voices = {"small": player(BUSES.effects, -11.0), "sale": player(BUSES.effects, -7.5),
		"signal": player(BUSES.effects, -5.5)}

func player(bus_name: String, volume: float) -> AudioStreamPlayer:
	var voice := AudioStreamPlayer.new()
	add_child(voice)
	voice.bus = bus_name
	voice.volume_db = volume
	return voice

func sound_file(path: String) -> AudioStream:
	if not streams.has(path):
		streams[path] = load(path)
	return streams[path]

func looped(source: AudioStreamOggVorbis) -> AudioStreamOggVorbis:
	var instance := source.duplicate() as AudioStreamOggVorbis
	instance.loop = true
	return instance

func apply(preferences: RefCounted) -> void:
	haptics = preferences.haptics
	for group in BUSES:
		var index := AudioServer.get_bus_index(BUSES[group])
		var level: float = preferences.volumes[group]
		AudioServer.set_bus_mute(index, level <= 0.001)
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(level, 0.001)))

func set_track(key: String) -> void:
	if track == key:
		return
	track = key
	if DisplayServer.get_name() == "headless":
		return
	if transition != null and transition.is_running():
		transition.kill()
	var previous := decks[active]
	active = 1 - active
	var current := decks[active]
	current.stop()
	current.stream = looped(sound_file(MUSIC[key]) as AudioStreamOggVorbis)
	current.volume_db = -45.0
	current.play()
	transition = create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	transition.tween_property(current, "volume_db", -9.0, 0.84)
	transition.tween_property(previous, "volume_db", -52.0, 0.84)
	transition.chain().tween_callback(previous.stop)

func update_field(strength: Dictionary, mute := false) -> void:
	ducked = mute
	for key in targets:
		targets[key] = clampf(strength.get(key, 0.0), 0.0, 1.0)

func _process(delta: float) -> void:
	if DisplayServer.get_name() == "headless":
		return
	for key in ambience:
		var voice: AudioStreamPlayer = ambience[key]
		var level: float = targets[key] * (0.44 if ducked else 1.0)
		var destination := -10.0 + linear_to_db(maxf(level, 0.004))
		if level > 0.02 and not voice.playing:
			voice.play()
		voice.volume_db = lerpf(voice.volume_db, destination, 1.0 - exp(-4.0 * delta))
		if level <= 0.02 and voice.playing and voice.volume_db < -46.0:
			voice.stop()
		if key in ["cars", "truck"]:
			voice.pitch_scale = lerpf(voice.pitch_scale, 0.83 + targets[key] * 0.24, 1.0 - exp(-3.0 * delta))

func cue(key: String, vibrate := false) -> void:
	if vibrate and haptics and OS.has_feature("mobile"):
		Input.vibrate_handheld(22 if key == "sale" else 37, 0.29)
	if DisplayServer.get_name() == "headless" or not CUES.has(key):
		return
	var lane := "small" if key == "click" else "sale" if key == "sale" else "signal"
	var voice: AudioStreamPlayer = voices[lane]
	if lane != "signal" and voice.playing:
		return
	voice.stream = sound_file(CUES[key])
	voice.play()
