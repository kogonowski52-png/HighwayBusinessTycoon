extends CanvasLayer
## Debug exports only. Read-only measurements and real SDK status, with no grant controls.

const Budget = preload("res://scripts/core/render_budget.gd")

var game: Node3D
var board: PanelContainer
var text: Label
var frames := 0
var elapsed := 0.0
var average := 0.0
var probe: HTTPRequest
var verifier := "diagnostic_unconfigured"

func _ready() -> void:
	layer = 15
	board = PanelContainer.new()
	add_child(board)
	board.position = Vector2(31, 392)
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_theme_stylebox_override("panel", game.hud.style(Color("#253a41ee"), Color("#66928f"), 14, 2))
	text = game.hud.caption(board, 23, Color("#fff3d4"), game.hud.HEAVY)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.hide()
	probe = HTTPRequest.new()
	probe.timeout = 5.0
	probe.body_size_limit = 1024
	add_child(probe)
	probe.request_completed.connect(verification_status)
	if game.purchases.verified_checkout():
		verifier = "diagnostic_idle"
	set_process(false)

func toggle() -> void:
	board.visible = not board.visible
	set_process(board.visible)
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), board.visible)
	frames = 0
	elapsed = 0.0
	average = 0.0
	if board.visible:
		publish(0.0)

func _process(delta: float) -> void:
	if game.suspended_at >= 0 or game.traveling:
		return
	frames += 1
	elapsed += delta
	if elapsed >= .48:
		var fps := frames / elapsed
		average = fps if average == 0.0 else lerpf(average, fps, .21)
		publish(elapsed * 1000.0 / frames)
		frames = 0
		elapsed = 0.0

func publish(frame_ms: float) -> void:
	var view := get_viewport()
	var draw_calls := view.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
	var count := view.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_OBJECTS_IN_FRAME)
	var primitives := view.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)
	var gpu := RenderingServer.viewport_get_measured_render_time_gpu(view.get_viewport_rid())
	var gpu_copy := "%.1f ms" % gpu if gpu > 0.0 else "—"
	var ram := OS.get_static_memory_usage() / 1048576.0
	var video := Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0
	text.text = "%s · %s\nFPS %d · %s %.1f\n%s %.1f ms · GPU %s\nRAM %.1f MiB · VRAM %.1f MiB\n%s %d · %s %d · Δ %d\n%s %d · %s %d" % [
		game.district_name(game.economy.district), game.t(Budget.LABELS[game.render_quality]),
		Engine.get_frames_per_second(), game.t("diagnostic_average"), average, game.t("diagnostic_frame"), frame_ms, gpu_copy,
		ram, video, game.t("diagnostic_objects"), count, game.t("diagnostic_draws"), draw_calls, primitives,
		game.t("diagnostic_vehicles"), game.traffic.vehicles.size() + game.traffic.background.size(),
		game.t("diagnostic_workers"), game.crew.actor_count() - game.crew.visitors.size()]

func sdk_summary() -> String:
	var native: Object = game.ads.provider
	var ads_copy: String = game.t("diagnostic_unconfigured")
	var ump_copy := ads_copy
	var store_copy := ads_copy
	if is_instance_valid(native) and native.has_method("diagnosticAdState"):
		ads_copy = game.t("diagnostic_" + str(native.diagnosticAdState()))
		ump_copy = game.t("diagnostic_" + str(native.diagnosticConsent()))
		store_copy = game.t("diagnostic_" + str(native.diagnosticBilling()))
	return "AdMob · %s\nUMP · %s\n%s · %s / %s / %s\nBilling · %s  |  %s %d\nHTTPS · %s\nBOOST · %s  |  %s %d" % [
		ads_copy, ump_copy, game.t("diagnostic_placements"), ad_slot("boost"), ad_slot("offline"), ad_slot("cash"), store_copy, game.t("diagnostic_products"), game.purchases.catalogue.size(),
		game.t(verifier), game.clock_text(game.campaign.boost.remaining(game.economy.clock)),
		game.t("diagnostic_confirmed"), game.ads.reward_receipts]

func ad_slot(key: String) -> String:
	if not game.ads.available():
		return game.t("diagnostic_unconfigured")
	return game.t("diagnostic_ready" if game.ads.ready(key) else (
		"diagnostic_loading" if game.ads.loading(key) else "diagnostic_failed"))

func check_verifier() -> void:
	if not game.purchases.verified_checkout():
		return
	var address: String = game.purchases.bridge.purchaseEndpoint()
	verifier = "diagnostic_loading"
	if probe.request(address.trim_suffix("/") + "/health") != OK:
		verifier = "diagnostic_failed"
	game.operations.refresh()

func verification_status(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var payload: Variant = JSON.parse_string(body.get_string_from_utf8())
	verifier = "diagnostic_ready" if result == HTTPRequest.RESULT_SUCCESS and code == 200 \
		and payload is Dictionary and payload.get("status") == "ready" else "diagnostic_failed"
	if game.operations.page == "diagnostics":
		game.operations.refresh()

func _exit_tree() -> void:
	if is_instance_valid(board) and board.visible:
		RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), false)
