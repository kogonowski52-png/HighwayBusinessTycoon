extends "res://tests/station_smoke.gd"
## Real viewport layout checks plus simulated Android safe insets.

const CASES := {
	"phone-16x9": Vector2i(486, 864),
	"phone-20x9": Vector2i(432, 960),
	"tablet-4x3": Vector2i(780, 1040),
}

func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			captures = argument.get_slice("=", 1)
	if DisplayServer.get_name() == "headless":
		expect(false, "layout comparison requires a real viewport")
		result("Quality settings and screen sizes")
		return
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.borderless = true
	root.position = Vector2i.ZERO
	root.size = CASES["phone-16x9"]
	save_path = "/tmp/hbt-stage7-layout-%d.cfg" % OS.get_process_id()
	if not captures.is_empty():
		DirAccess.make_dir_recursive_absolute(captures)
	game = mount(WALL)
	current_scene = game
	game.skip_tutorial()
	game.set_quality(1)
	for label: String in CASES:
		root.size = CASES[label]
		for _frame in 5:
			await process_frame
		var screen := Vector2(root.size)
		var notch := Rect2(Vector2(4, 31), screen - Vector2(8, 56))
		var safe: Vector4 = game.hud.safe_insets(notch, screen, root.get_visible_rect().size)
		game.hud.apply_safe(safe)
		game.operations.apply_layout()
		await process_frame
		expect(controls_fit() and game.hud.top.get_global_rect().position.y >= safe.y,
			"controls and top inset fit %s" % label)
		click(game.hud.settings)
		for _frame in 5:
			await process_frame
		var ultra := find_button(game.operations.rows, game.t("quality_ultra"))
		expect(ultra != null and ultra.get_global_rect().size.x >= 75 and root.get_visible_rect().encloses(game.operations.panel.get_global_rect()),
			"four-profile settings sheet and fourth button fit %s" % label)
		await capture(label + "-settings.png")
		await click_row(game.t("diagnostics_header"))
		expect(game.operations.page == "diagnostics", "debug service screen opens in %s" % label)
		if label == "phone-20x9":
			await capture("service-diagnostics.png")
			await click_row(game.t("diagnostic_fps_off"))
			expect(game.diagnostics.board.visible, "option enables a read-only panel")
			await close_sheet()
			await capture("renderer-telemetry.png")
			game.diagnostics.toggle()
		else:
			await close_sheet()
	game.free()
	root.get_node("RouteAudio").shut_down()
	await create_timer(.18).timeout
	clean_save(save_path)
	result("Quality settings and screen sizes")
