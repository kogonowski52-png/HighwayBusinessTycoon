extends "res://tests/station_smoke.gd"
## Feed ScreenTouch/ScreenDrag directly into the production viewport, including emulated companions.

const Revenue = preload("res://data/monetization/config.gd")
const PAGES := ["sites", "team", "managers", "goals", "shop", "achievements", "calendar", "pass",
	"seasons", "atlas", "settings", "collections", "contracts", "upgrades"]

var panes_scrolled := 0
var panes_fit := 0
var emulated := false
var video := false

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			captures = arg.get_slice("=", 1)
		video = video or arg == "--record"
	root.borderless = true
	root.position = Vector2i.ZERO
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.size = Vector2i(432, 768) if video else Vector2i(540, 960)
	if not captures.is_empty():
		DirAccess.make_dir_recursive_absolute(captures)
	save_path = "/tmp/hbt-mobile-input-%d.cfg" % OS.get_process_id()
	game = mount(Revenue.SEASON_EPOCH + 2300)
	current_scene = game
	game.economy.preferences.auto_day = false
	game.economy.credit("cash", HbtAmount.from(11_000))
	game.economy.credit("reputation", HbtAmount.from(27))
	game.economy.buy_levels("fuel", 10)
	game.set_look(game.lighting.Look.DAY)
	await settle()
	if video:
		await record_scroll()
	else:
		await catalog_and_guide()
		await survey_pages()
		await test_slider()
		await test_camera_and_dialog()
		if DisplayServer.get_name() != "headless":
			await test_platform_input()
		await test_layouts()
		print("Touch lists with overflow: %d, lists fitting: %d" % [panes_scrolled, panes_fit])
	game.free()
	root.get_node("RouteAudio").shut_down()
	await create_timer(.18).timeout
	clean_save(save_path)
	result("Mobile gestures and business construction")

func catalog_and_guide() -> void:
	var store: HbtEconomy = game.economy
	store.tutorial_step = 5
	game.guided_step = 5
	# Measure the six states from actual gates, preserving the test profile.
	var cash := store.amount("cash")
	var rep := store.amount("reputation")
	var tier := store.level("fuel")
	var wanted := "market"
	store.levels.fuel = 1
	expect(label_for(wanted) == "site_no_level", "level requirement is distinct")
	store.levels.fuel = tier
	store.wallet.reputation = HbtAmount.new()
	expect(label_for(wanted) == "site_no_rep", "reputation requirement is distinct")
	store.wallet.reputation = rep
	store.wallet.cash = HbtAmount.new()
	expect(label_for(wanted) == "site_no_cash", "unaffordable opening is distinct")
	store.wallet.cash = cash
	expect(label_for(wanted) == "site_ready", "fully funded opening is ready")
	game.site_buttons.refresh()
	await settle()
	var pin: Button = game.site_buttons.buttons.market
	expect(pin.visible and pin.text == game.money(store.construction_quote(wanted).cost),
		"ready shop has a priced hammer marker in the normal camera")
	await capture("00-pin-inwestycji.jpg")
	await tap(game.hud.pages.sites)
	expect(game.operations.page == "sites" and game.operations.modal_open() and store.tutorial_step == 5,
		"touch on Build opens the directory and keeps the guide active")
	var quote := store.construction_quote(wanted)
	var buy := find_button(game.operations.rows, game.t("unlock") % game.money(quote.cost))
	expect(is_instance_valid(buy), "the shop has a direct priced action")
	expect(game.operations.rows.get_child(0).name == "Business_market", "ready investment sorts before built and locked sites")
	if not is_instance_valid(buy):
		return
	await settle()
	expect(game.tutorial.glow.visible and game.tutorial.control_for(5) == buy, "the guide highlights the actual build action")
	await capture("01-rozbudowa.jpg")
	print("Investment card height ", game.operations.rows.get_child(0).size.y)
	var original_camera: Vector3 = game.camera_rig.target
	var original_row: Node = game.operations.rows.get_child(0)
	var pointer := buy.get_global_rect().get_center()
	emulated = true
	touch(pointer, true)
	store.credit("cash", HbtAmount.from(1))
	await process_frame
	expect(game.operations.rows.get_child(0) == original_row, "income refresh does not replace cards during a press")
	for i in range(1, 7):
		drag(pointer - Vector2(0, float(i) * 27), Vector2(0, -27))
	var before_release: int = game.operations.scroll.scroll_vertical
	touch(pointer - Vector2(0, 162), false)
	await create_timer(.14).timeout
	expect(before_release > 60 and game.operations.scroll.scroll_vertical > before_release, "finger drag and inertia move the list")
	expect(store.level(wanted) == 0 and game.camera_rig.target == original_camera, "swiping across the priced button never builds or pans")
	var brake: Vector2 = game.operations.scroll.get_global_rect().get_center()
	touch(brake, true)
	touch(brake, false)
	await settle()
	expect(not game.operations.scroll.interacting() and store.level(wanted) == 0, "a tap stops momentum without activating a row")
	emulated = false
	await tap(game.operations.business.buttons.sites_available)
	expect(game.operations.business.filter == "sites_available" and game.operations.rows.get_child(0).name == "Business_market",
		"Available filter shows funded construction")
	await capture("02-dostepne.jpg")
	await tap(game.operations.business.buttons.sites_locked)
	expect(game.operations.business.filter == "sites_locked" and not game.operations.rows.has_node("Business_market"),
		"Locked filter hides ready construction")
	await capture("03-zablokowane.jpg")
	await tap(game.operations.business.buttons.sites_all)
	quote = store.construction_quote(wanted)
	var before := store.amount("cash")
	buy = find_button(game.operations.rows, game.t("unlock") % game.money(quote.cost))
	emulated = true
	await tap(buy)
	emulated = false
	expect(store.level(wanted) == 1 and store.amount("cash").compare(before.minus(quote.cost)) == 0,
		"screen tap and emulated pair make exactly one purchase")
	expect(not game.operations.modal_open() and game.selected == wanted and store.tutorial_step == store.TUTORIAL_DONE,
		"building closes the sheet, selects the shop and completes the guide")
	var copy := HbtEconomy.new()
	copy.storage.path = save_path
	var snapshot := HbtCampaign.new(copy)
	snapshot.restore(store.clock)
	expect(snapshot.current().level(wanted) == 1 and snapshot.current().tutorial_step == store.TUTORIAL_DONE,
		"the completed construction and tutorial survive loading the save")
	if DisplayServer.get_name() != "headless":
		expect(not game.camera_rig.film.is_empty() and game.camera_rig.target.distance_to(game.campus.focus(wanted)) < 1.5,
			"construction starts the existing cinematic on the correct investment")
	await create_timer(1.1).timeout
	game.build_site(wanted)
	expect(store.level(wanted) == 1, "stale build action is harmless after opening")
	await capture("04-sklep-wybudowany.jpg")
	game.open_page("sites")
	await settle()
	await tap(game.operations.business.buttons.sites_built)
	expect(game.operations.rows.has_node("Business_market") and label_for(wanted) == "site_can_upgrade",
		"Built filter shows the newly opened shop and its available upgrade")
	await capture("05-wybudowane.jpg")
	await close_sheet()

func label_for(id: String) -> String:
	return game.operations.business.availability(id, game.economy.level(id), game.economy.construction_quote(id))

func survey_pages() -> void:
	game.select_site("fuel")
	game.operations.business.filter = "sites_all"
	game.economy.hire("fuel")
	game.economy.hire("fuel")
	game.economy.cards.ada = true
	for page: String in PAGES:
		game.open_page(page)
		await settle()
		var scroll: ScrollContainer = game.operations.scroll
		var area := scroll.get_global_rect()
		var rail := scroll.get_v_scroll_bar()
		var extent := rail.max_value - rail.page
		var point := area.position + Vector2(area.size.x * .49, minf(305, area.size.y * .65))
		var camera: Vector3 = game.camera_rig.target
		touch(point, true)
		for i in range(1, 6):
			drag(point - Vector2(0, i * 32), Vector2(0, -32))
		var moved := scroll.scroll_vertical
		touch(point - Vector2(0, 160), false, true)
		if extent >= 1.0:
			panes_scrolled += 1
			expect(moved > 0, page + " scrolls from its content")
		else:
			panes_fit += 1
			expect(moved == 0, page + " fits without overscroll")
		expect(game.operations.modal_open() and game.operations.page == page and game.camera_rig.target == camera,
			page + " leaves controls and camera alone during the drag")
		print("TOUCH %s extent=%d moved=%d" % [page, extent, moved])
		await close_sheet()

func test_slider() -> void:
	game.open_page("settings")
	await settle()
	var slider: HSlider = game.operations.rows.find_children("*", "HSlider", true, false)[0]
	game.operations.scroll.ensure_control_visible(slider)
	await settle()
	var shown_at: int = game.operations.scroll.scroll_vertical
	var previous := slider.value
	var thumb := slider.get_global_rect()
	var start := thumb.position + Vector2(thumb.size.x * .30, thumb.size.y * .5)
	touch(start, true)
	drag(start + Vector2(0, -72), Vector2(0, -72))
	touch(start + Vector2(0, -72), false, true)
	expect(is_equal_approx(slider.value, previous) and game.operations.scroll.scroll_vertical > shown_at,
		"vertical drag across an audio slider scrolls without changing its value")
	game.operations.scroll.scroll_vertical = shown_at
	await settle()
	thumb = slider.get_global_rect()
	start = thumb.position + Vector2(thumb.size.x * .25, thumb.size.y * .5)
	var end := start + Vector2(thumb.size.x * .45, 0)
	touch(start, true)
	drag(end, end - start)
	touch(end, false)
	expect(not is_equal_approx(slider.value, previous) and game.operations.scroll.scroll_vertical == shown_at,
		"horizontal drag adjusts an audio slider without scrolling")
	# Stay in the sheet when the finger leaves the list during a drag.
	var area: Rect2 = game.operations.scroll.get_global_rect()
	start = area.position + Vector2(150, 90)
	end = Vector2(start.x, game.operations.panel.get_global_rect().position.y - 72)
	touch(start, true)
	drag(end, end - start)
	touch(end, false)
	expect(game.operations.modal_open(), "drag ending on the overlay does not dismiss the sheet")
	await close_sheet()

func test_camera_and_dialog() -> void:
	game.select_site("fuel")
	await create_timer(.48).timeout
	var pane: CanvasLayer = game.operations
	var lens: Camera3D = game.camera
	var world: AABB = game.site_buttons.venue_bounds("market")
	var point := lens.unproject_position(world.position + Vector3(world.size.x * .45, world.size.y * .80, world.size.z * .71))
	touch(point, true)
	touch(point, false)
	await settle()
	expect(pane.modal_open() and pane.page == "upgrades" and game.selected == "market",
		"touching the actual shop mesh opens its management sheet")
	if pane.modal_open():
		var shade_point := Vector2(45, maxf(72, pane.panel.get_global_rect().position.y - 120))
		touch(shade_point, true)
		drag(shade_point + Vector2(0, 44), Vector2(0, 44))
		touch(shade_point + Vector2(0, 44), false)
		expect(pane.modal_open(), "dragging the shade is not treated as a dismissal")
		touch(shade_point, true)
		touch(shade_point, false)
		await settle()
		expect(not pane.visible, "a genuine tap on the shade closes the dialog")
	var prior: Vector3 = game.camera_rig.target
	point = Vector2(490, 800)
	touch(point, true)
	drag(point + Vector2(102, 27), Vector2(102, 27))
	touch(point + Vector2(102, 27), false)
	expect(game.camera_rig.target.distance_to(prior) > .4 and not pane.visible, "pan stays available on the map")
	point = Vector2(380, 800)
	var other := Vector2(570, 800)
	var prior_zoom: float = game.camera_rig.zoom
	touch(point, true)
	touch(other, true, false, 1)
	drag(other + Vector2(68, 0), Vector2(68, 0), 1)
	touch(other + Vector2(68, 0), false, false, 1)
	touch(point, false)
	expect(game.camera_rig.zoom < prior_zoom and not pane.visible, "two-finger pinch zooms without opening a building")

func test_layouts() -> void:
	var before: float = game.hud.bottom.size.y
	await tap(game.hud.management_toggle)
	expect(game.hud.management_collapsed and not game.hud.serve.is_visible_in_tree() and game.hud.bottom.size.y < before - 60,
		"collapse frees space while keeping the active business header")
	await capture("06-panel-zwiniety.jpg")
	await tap(game.hud.management_toggle)
	expect(not game.hud.management_collapsed and game.hud.serve.is_visible_in_tree(), "expanding restores the controls")
	print("Top band height ", game.hud.top.size.y)
	for viewport: Vector2i in [Vector2i(432, 960), Vector2i(780, 1040)]:
		root.size = viewport
		await settle()
		var area := Rect2(5, 36, viewport.x - 10, viewport.y - 65)
		game.hud.apply_safe(game.hud.safe_insets(area, Vector2(viewport), root.get_visible_rect().size))
		await tap(game.hud.pages.sites)
		expect(game.operations.modal_open() and root.get_visible_rect().encloses(game.operations.panel.get_global_rect())
			and game.operations.panel.get_global_rect().encloses(game.operations.business.tabs.get_global_rect()),
			"sheet and four filters fit safe insets at %s" % str(viewport))
		await close_sheet()

func test_platform_input() -> void:
	game.open_page("sites")
	game.operations.business.select_filter("sites_all")
	await settle()
	var area: Rect2 = game.operations.scroll.get_global_rect()
	var start := area.position + Vector2(area.size.x * .65, 280)
	var transform := root.get_final_transform()
	var camera: Vector3 = game.camera_rig.target
	platform_touch(start, true, transform)
	for i in range(1, 6):
		var event := InputEventScreenDrag.new()
		event.window_id = root.get_window_id()
		event.position = transform * (start - Vector2(0, i * 32))
		event.relative = transform.basis_xform(Vector2(0, -32))
		Input.parse_input_event(event)
		Input.flush_buffered_events()
	platform_touch(start - Vector2(0, 160), false, transform)
	expect(game.operations.scroll.scroll_vertical > 100 and game.camera_rig.target == camera and game.operations.page == "sites",
		"Godot's platform input path scrolls once with touch-to-mouse emulation enabled")
	await close_sheet()
	var toggle: Button = game.hud.management_toggle
	var point := toggle.get_global_rect().get_center()
	platform_touch(point, true, transform)
	platform_touch(point, false, transform)
	await settle()
	expect(game.hud.management_collapsed, "platform touch toggles the HUD once")
	await tap(toggle)

func platform_touch(point: Vector2, pressed: bool, transform: Transform2D) -> void:
	var event := InputEventScreenTouch.new()
	event.window_id = root.get_window_id()
	event.position = transform * point
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func tap(button: Button) -> void:
	if not is_instance_valid(button):
		expect(false, "expected a visible control for a screen tap")
		return
	var point := button.get_global_rect().get_center()
	touch(point, true)
	touch(point, false)
	await settle()

func touch(point: Vector2, down: bool, canceled := false, index := 0) -> void:
	if emulated and index == 0:
		var mouse := InputEventMouseButton.new()
		mouse.device = InputEvent.DEVICE_ID_EMULATION
		mouse.position = point
		mouse.global_position = point
		mouse.pressed = down
		mouse.button_index = MOUSE_BUTTON_LEFT
		root.push_input(mouse, true)
	var event := InputEventScreenTouch.new()
	event.position = point
	event.index = index
	event.pressed = down
	event.canceled = canceled
	root.push_input(event, true)

func drag(point: Vector2, delta: Vector2, index := 0) -> void:
	if emulated and index == 0:
		var mouse := InputEventMouseMotion.new()
		mouse.device = InputEvent.DEVICE_ID_EMULATION
		mouse.position = point
		mouse.global_position = point
		mouse.relative = delta
		mouse.button_mask = MOUSE_BUTTON_MASK_LEFT
		root.push_input(mouse, true)
	var event := InputEventScreenDrag.new()
	event.position = point
	event.relative = delta
	event.index = index
	root.push_input(event, true)

func settle() -> void:
	await create_timer(.24).timeout
	await process_frame

func record_scroll() -> void:
	game.skip_tutorial()
	game.open_page("sites")
	await create_timer(.6).timeout
	var start := Vector2(740, 1390)
	touch(start, true)
	for i in range(1, 15):
		await create_timer(.031).timeout
		drag(start - Vector2(0, i * 35), Vector2(0, -35))
	touch(start - Vector2(0, 490), false)
	await create_timer(.85).timeout
	expect(game.operations.scroll.scroll_vertical > 460, "movie records real list movement")
	await tap(game.operations.business.buttons.sites_available)
	await create_timer(.8).timeout
