extends RefCounted
## Automatic quality is opt-in on existing profiles and never changes the stored manual choice.

const SCALES := [0.74, 0.88, 1.0, 1.10]
const LOD_PIXELS := [2.4, 1.45, 1.0, .65]
const SAMPLES := [Viewport.MSAA_DISABLED, Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X]
const LABELS := ["quality_low", "quality_mid", "quality_high", "quality_ultra"]
const WINDOW := 6.0

var ceiling := 2
var active := 2
var elapsed := 0.0
var slow := 0.0
var healthy_windows := 0
var recovery_windows := 4
var initialized := false

func reset() -> void:
	initialized = true
	recovery_windows = 4
	var ram := int(OS.get_memory_info().get("physical", 0))
	var gib := float(ram) / 1073741824.0
	ceiling = 2
	if OS.has_feature("mobile"):
		ceiling = 0 if gib > 0.0 and gib < 4.5 else (1 if gib < 7.0 else 2)
	active = ceiling
	clear_sample()

func clear_sample() -> void:
	elapsed = 0.0
	slow = 0.0
	healthy_windows = 0

func sample(delta: float, fps_limit: int) -> bool:
	if delta <= 0.0 or delta > 2.0:
		return false
	var target := float(fps_limit) if active > 0 else 30.0
	var seconds := minf(delta, .25)
	elapsed += seconds
	if delta > 1.25 / target:
		slow += seconds
	if elapsed < WINDOW:
		return false
	var poor := slow / elapsed
	elapsed = 0.0
	slow = 0.0
	if poor > .36 and active > 0:
		active -= 1
		recovery_windows = mini(recovery_windows * 2, 24)
		healthy_windows = 0
		return true
	healthy_windows = healthy_windows + 1 if poor < .07 else 0
	if healthy_windows >= recovery_windows and active < ceiling:
		active += 1
		healthy_windows = 0
		return true
	return false

func apply(view: Viewport, tier: int) -> void:
	if not is_equal_approx(view.scaling_3d_scale, SCALES[tier]):
		view.scaling_3d_scale = SCALES[tier]
	if view.msaa_3d != SAMPLES[tier]:
		view.msaa_3d = SAMPLES[tier]
	view.mesh_lod_threshold = LOD_PIXELS[tier]
