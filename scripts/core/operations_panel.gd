extends CanvasLayer

signal closed

const Rules = preload("res://scripts/employees/staff_rules.gd")
const Book = preload("res://data/economy/progression.gd")

var controller: Node3D
var theme_source: CanvasLayer
var panel: PanelContainer
var header: Label
var back: Button
var scroll: ScrollContainer
var rows: VBoxContainer
var page := ""
var opening: Tween

func setup(game: Node3D, hud: CanvasLayer) -> void:
	controller = game
	theme_source = hud
	layer = 5
	var shade := ColorRect.new()
	shade.color = Color("#10252aab")
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel = PanelContainer.new()
	shade.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 42
	panel.offset_right = -42
	panel.offset_top = 218
	panel.offset_bottom = -140
	panel.add_theme_stylebox_override("panel", hud.sculpted(hud.IVORY, 35, 31))
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 26)
	panel.add_child(stack)
	var top := HBoxContainer.new()
	stack.add_child(top)
	header = hud.caption(top, 42, hud.INK, hud.HEAVY)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	back = hud.action(top, 146, 72, false)
	back.pressed.connect(hide_page)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(scroll)
	rows = VBoxContainer.new()
	rows.add_theme_constant_override("separation", 17)
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	visible = false

func show_page(name: String) -> void:
	var entering := not visible or page != name
	if name != page:
		scroll.scroll_vertical = 0
	page = name
	var compact := name == "offline"
	panel.set_anchor(SIDE_TOP, 0.36 if compact else 0.0)
	panel.set_anchor(SIDE_BOTTOM, 0.65 if compact else 1.0)
	panel.offset_top = 0.0 if compact else 218.0
	panel.offset_bottom = 0.0 if compact else -140.0
	visible = true
	refresh()
	if entering:
		panel.pivot_offset = panel.size * 0.5
		panel.modulate.a = 0.78
		panel.scale = Vector2(0.98, 0.98)
		if opening != null and opening.is_running():
			opening.kill()
		opening = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		opening.tween_property(panel, "scale", Vector2.ONE, 0.20)
		opening.tween_property(panel, "modulate:a", 1.0, 0.17)

func hide_page() -> void:
	visible = false
	closed.emit()

func refresh() -> void:
	if not visible:
		return
	header.text = controller.t(page + "_header")
	back.text = controller.t("close")
	for node in rows.get_children():
		rows.remove_child(node)
		node.queue_free()
	match page:
		"sites": show_sites()
		"team": show_team()
		"goals": show_goals()
		"finance": show_finance()
		"offline": show_offline()

func box(title: String, detail := "") -> VBoxContainer:
	var surface := PanelContainer.new()
	surface.add_theme_stylebox_override("panel", theme_source.style(theme_source.PANEL, theme_source.RIM, 18, 21))
	rows.add_child(surface)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	surface.add_child(stack)
	var main: Label = theme_source.caption(stack, 30, theme_source.INK, theme_source.HEAVY)
	main.text = title
	main.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if not detail.is_empty():
		var body: Label = theme_source.caption(stack, 24, theme_source.FADE, theme_source.REGULAR)
		body.text = detail
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return stack

func button(parent: Control, label: String, operation: Callable, disabled := false, primary := false) -> Button:
	var action: Button = theme_source.action(parent, 0, 74, primary)
	action.text = label
	action.disabled = disabled
	action.pressed.connect(operation)
	return action

func show_sites() -> void:
	var store: HbtEconomy = controller.economy
	for id in store.facilities:
		var tier := store.level(id)
		var subtitle: String = controller.gate_text(id) if tier == 0 else controller.t("level") % [tier, store.CONFIG.max_level]
		var card := box(controller.site_name(id), subtitle)
		button(card, controller.t("map") if tier > 0 else controller.t("site_details"),
			func() -> void:
				controller.select_site(id)
				hide_page(), false, id == controller.selected)

func show_team() -> void:
	var store: HbtEconomy = controller.economy
	var id: String = controller.selected
	var facility: HbtService = store.facilities[id]
	var employees: Array = store.crew[id]
	var cap := store.capacity(id)
	var summary := box(controller.site_name(id), controller.t("crew_capacity") % [employees.size(), cap, controller.site_name(id)])
	var cost := store.recruit_cost(id)
	button(summary, controller.t("recruit") % controller.money(cost), controller.hire_worker,
		employees.size() >= cap or not store.can_afford(cost), true)
	for index in range(employees.size()):
		var worker: Dictionary = employees[index]
		var detail: String = controller.t("worker_detail") % [worker.xp, worker.training, Rules.MAX_TRAINING,
			int(Rules.speed(worker) / 100.0), int(Rules.efficiency(worker) / 100.0), worker.rank]
		if not Rules.promotion_ready(worker) and worker.rank < Rules.MAX_RANK:
			detail += "\n" + controller.t("promotion_require") % [worker.rank * 12, worker.rank * 2]
		var card := box(controller.t("worker") % [index + 1, worker.rank], detail)
		var actions := HBoxContainer.new()
		card.add_child(actions)
		var training := Rules.training_cost(facility, worker)
		var promotion := Rules.promotion_cost(facility, worker)
		var train := button(actions, controller.t("training") % controller.money(training), controller.train_worker.bind(index),
			worker.training >= Rules.MAX_TRAINING or not store.can_afford(training))
		var promote := button(actions, controller.t("promotion") % controller.money(promotion), controller.promote_worker.bind(index),
			not Rules.promotion_ready(worker) or not store.can_afford(promotion))
		train.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		promote.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box(controller.t("manager_capacity") % [store.equipped.size(), store.CONFIG.max_active_managers])
	for key in Book.MANAGERS:
		var director: Dictionary = Book.MANAGERS[key]
		var description: String = controller.t("skill_" + director.skill)
		if director.skill != "collect":
			description = description % int(director.value / 100.0)
		if not store.cards.has(key):
			description += "\n" + controller.t("cards_locked")
		var row := box(director.name, description)
		var active: bool = key in store.equipped
		button(row, controller.t("remove" if active else "assign"), controller.assign_manager.bind(key),
			not store.cards.has(key) or (not active and store.equipped.size() >= store.CONFIG.max_active_managers))

func show_goals() -> void:
	var store: HbtEconomy = controller.economy
	var event := store.current_event()
	var places: PackedStringArray = []
	for id in event.services:
		places.append(controller.site_name(id))
	var progress := mini(store.daily_progress(), int(event.goal))
	var event_detail: String = controller.t("event_rule") % ", ".join(places)
	event_detail += "\n" + controller.t("event_daily") % [progress, event.goal, event.reward]
	var event_box := box(event["name_" + store.language], event_detail)
	var claimed := store.event_claimed == store.day_index()
	button(event_box, controller.t("claimed" if claimed else "claim_daily"), controller.claim_daily,
		claimed or progress < event.goal)
	button(event_box, controller.t("event_card") % Book.EVENT_CARD_COST, controller.exchange_points.bind(true),
		store.cards.has("mira") or not store.can_afford(HbtAmount.from(Book.EVENT_CARD_COST), "event"))
	button(event_box, controller.t("event_trade") % [Book.EVENT_DIAMOND_COST, Book.EVENT_DIAMONDS],
		controller.exchange_points.bind(false), not store.can_afford(HbtAmount.from(Book.EVENT_DIAMOND_COST), "event"))
	for item in Book.MILESTONES:
		var count := mini(item.goal, store.metric(item.counter))
		var rewards: PackedStringArray = []
		for key in item.reward:
			if key == "card":
				rewards.append(Book.MANAGERS[item.reward.card].name)
			else:
				rewards.append("%d %s" % [item.reward[key], controller.t("currency_" + key)])
		var detail := "%s  ·  %d/%d\n%s" % [controller.t(item.group), count, item.goal, "  +  ".join(rewards)]
		var row := box(controller.t("objective_" + item.id), detail)
		var done := store.claimed.has(item.id)
		button(row, controller.t("claimed" if done else "claim"), controller.claim_milestone.bind(item.id),
			done or count < item.goal, true)

func show_finance() -> void:
	var store: HbtEconomy = controller.economy
	var till := store.holding()
	box(controller.t("fin_cash"), controller.money(store.amount("cash"), true))
	var registers := box(controller.t("fin_register"), controller.money(till, true))
	button(registers, controller.t("collect_action") % controller.money(till), controller.collect_income, till.empty(), true)
	box(controller.t("fin_gross"), controller.money(store.gross, true))
	box(controller.t("fin_spent"), controller.money(store.spent, true))
	box(controller.t("fin_flow"), controller.money(store.income_per_minute()) + "   ·   " + controller.flow_text())
	var bonus := store.boost_until - store.clock
	var boost := box(controller.t("boost_running") % controller.clock_text(bonus) if bonus > 0 else
		controller.t("boost") % store.CONFIG.boost_cost)
	if bonus <= 0:
		button(boost, controller.t("boost") % store.CONFIG.boost_cost, controller.buy_boost,
			not store.can_afford(HbtAmount.from(store.CONFIG.boost_cost), "diamond"))
	if controller.ads.privacy_required():
		button(rows, controller.t("ad_privacy"), controller.ads.privacy)
	var away := box(controller.t("offline_header"), controller.t("fin_offline"))
	button(away, controller.t("offline_banner") % controller.money(store.offline_pending),
		show_page.bind("offline"), store.offline_pending.empty())
	for id in store.facilities:
		if store.level(id) > 0:
			var record: Dictionary = store.per_service[id]
			box(controller.site_name(id), "%d  ·  %s" % [record.count, controller.money(record.gross, true)])

func show_offline() -> void:
	var store: HbtEconomy = controller.economy
	var value := store.offline_pending
	if value.empty():
		box(controller.t("offline_no_income"))
		return
	var card := box(controller.money(value, true), controller.t("offline_time") % controller.clock_text(store.offline_seconds))
	button(card, controller.t("claim_offline") % controller.money(value), controller.claim_offline,
		controller.ads.busy(), true)
	if controller.ads.available():
		if controller.ads.busy() or controller.ads.ready():
			var desc: String = controller.t("bonus_running") if controller.ads.busy() else controller.t("claim_bonus") % controller.money(value.times(2))
			button(card, desc, controller.start_offline_ad, controller.ads.busy())
		else:
			var loading: bool = controller.ads.loading()
			button(card, controller.t("ad_loading" if loading else "ad_prepare"), controller.ads.prepare, loading)
