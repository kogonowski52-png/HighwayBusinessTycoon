extends CanvasLayer
## Debug exports only. Read-only measurements and real SDK status, with no grant controls.

const Budget = preload("res://scripts/core/render_budget.gd")

var game: Node3D
var board: PanelContainer
var text: Label
var frames := 0
var elapsed := 0.0
var average := 0.0

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
	var ump_code := ""
	if is_instance_valid(native) and native.has_method("diagnosticAdState"):
		ads_copy = game.t("diagnostic_" + str(native.diagnosticAdState()))
		ump_copy = game.t("diagnostic_" + str(native.diagnosticConsent()))
		store_copy = game.t("diagnostic_" + str(native.diagnosticBilling()))
		if native.has_method("diagnosticConsentError"):
			ump_code = str(native.diagnosticConsentError())
	var mode: String = game.purchases.service_mode()
	var bill_code := ""
	if not game.purchases.billing_source.is_empty():
		bill_code = code_text("%s %d" % [game.purchases.billing_source, game.purchases.billing_code])
	return "\n".join([
		game.t("diagnostic_test_mode" if mode == "test" else "diagnostic_prod_mode" if mode == "production" else "diagnostic_desktop_mode"),
		"AdMob · %s" % ads_copy,
		"UMP · %s%s" % [ump_copy, code_text(ump_code)],
		"BOOST · " + ad_slot("boost"),
		game.t("offline_header") + " · " + ad_slot("offline"),
		game.t("diagnostic_slot_gems") + " · " + ad_slot("gems"),
		game.t("diagnostic_slot_bonus") + " · " + ad_slot("bonus"),
		game.t("diagnostic_slot_break") + " · " + ad_slot("interstitial"),
		"%s · %s (%d)" % [game.t("diagnostic_last_reward"), game.t("diagnostic_reward_" + game.ads.last_reward), game.ads.reward_receipts],
		"Billing · %s · %s %d%s" % [store_copy, game.t("diagnostic_products"), game.purchases.catalogue.size(), bill_code],
		"HTTPS · %s" % game.t(game.purchases.verifier),
	])

func ad_slot(key: String) -> String:
	var native: Object = game.ads.provider
	if not is_instance_valid(native) or not native.has_method("diagnosticAdSlot"):
		return game.t("diagnostic_unconfigured")
	var fields := str(native.diagnosticAdSlot(key)).split("|")
	if fields.size() != 3:
		return game.t("diagnostic_unconfigured")
	return game.t("diagnostic_" + fields[0]) + (" · %s ms" % fields[1] if fields[1] != "-1" else "") + code_text(fields[2])

func code_text(value: String) -> String:
	return "" if value.is_empty() else " · " + game.t("diagnostic_sdk_code") % value

func _exit_tree() -> void:
	if is_instance_valid(board) and board.visible:
		RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), false)
