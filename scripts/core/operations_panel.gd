extends CanvasLayer

signal closed

const Rules = preload("res://scripts/employees/staff_rules.gd")
const Book = preload("res://data/economy/progression.gd")
const Managers = preload("res://data/economy/managers.gd")
const Journey = preload("res://data/economy/journey.gd")
const RARITY := {"common": Color("#dae9db"), "rare": Color("#d8e9f3"),
	"epic": Color("#ebe0f3"), "legendary": Color("#f6e2b6")}
const Campus = preload("res://scripts/buildings/roadside_campus.gd")

var controller: Node3D
var theme_source: CanvasLayer
var panel: PanelContainer
var header: Label
var page_icon: TextureRect
var back: Button
var shade: ColorRect
var scroll: ScrollContainer
var rows: VBoxContainer
var page := ""
var opening: Tween
var team_tab := "team_staff"
var goals_tab := "career"
var chapter_index := 0
var tutorial_targets: Dictionary = {}
var manager_render_state := ""

func setup(game: Node3D, hud: CanvasLayer) -> void:
	controller = game
	theme_source = hud
	layer = 5
	shade = ColorRect.new()
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
	var ribbon := PanelContainer.new()
	stack.add_child(ribbon)
	ribbon.add_theme_stylebox_override("panel", hud.sculpted(hud.PETROL, 35, 18))
	var top := HBoxContainer.new()
	ribbon.add_child(top)
	top.add_theme_constant_override("separation", 9)
	page_icon = hud.icon(top, hud.UPGRADE_ART, 76)
	header = hud.caption(top, 38, hud.CREAM, hud.HEAVY)
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
	var upgrades := name == "upgrades"
	shade.color = Color("#10252a5c") if upgrades else Color("#10252aab")
	panel.set_anchor(SIDE_TOP, 0.36 if compact else 0.38 if upgrades else 0.0)
	panel.set_anchor(SIDE_BOTTOM, 0.69 if compact else 1.0)
	panel.offset_top = 0.0 if compact or upgrades else 218.0
	panel.offset_bottom = 0.0 if compact else -48.0 if upgrades else -140.0
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
	var store: HbtEconomy = controller.economy
	if page == "team" and team_tab == "team_cards":
		var card_state := str([store.language, store.cards.keys(), store.manager_ranks, store.equipped,
			store.amount("diamond").decimal(), store.player_level()])
		if card_state == manager_render_state:
			return
		manager_render_state = card_state
	else:
		manager_render_state = ""
	var previous_scroll := scroll.scroll_vertical
	tutorial_targets.clear()
	header.text = controller.t(page + "_header")
	page_icon.texture = theme_source.NAV.get(page, theme_source.CASH if page == "offline" else theme_source.UPGRADE_ART)
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
		"upgrades": show_upgrades()
	if previous_scroll > 0:
		scroll.set_deferred("scroll_vertical", previous_scroll)

func section_tabs(keys: Array[String], selected: String, callback: Callable) -> void:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 8)
	rows.add_child(line)
	for key in keys:
		var tab := button(line, controller.t(key), callback.bind(key), false, key == selected)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func switch_team(key: String) -> void:
	team_tab = key
	scroll.scroll_vertical = 0
	refresh()

func switch_goals(key: String) -> void:
	goals_tab = key
	scroll.scroll_vertical = 0
	refresh()

func mission_bar(parent: Control, have: float, goal: float) -> void:
	var gauge := ProgressBar.new()
	parent.add_child(gauge)
	gauge.custom_minimum_size.y = 15
	gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gauge.show_percentage = false
	gauge.max_value = maxf(1.0, goal)
	gauge.value = clampf(have, 0.0, gauge.max_value)
	gauge.add_theme_stylebox_override("background", theme_source.style(Color("#e0d3ba"), theme_source.RIM, 8, 0))
	gauge.add_theme_stylebox_override("fill", theme_source.style(Color("#6ab18c"), theme_source.MINT, 8, 0))


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

func show_upgrades() -> void:
	var store: HbtEconomy = controller.economy
	var site: String = controller.selected
	var tier := store.level(site)
	var status: String = controller.gate_text(site) if tier == 0 else controller.t("level") % [tier, store.CONFIG.max_level]
	var card := box(controller.site_name(site), status)
	var purchase: Button = button(card, controller.hud.upgrade.text, controller.invest, controller.hud.upgrade.disabled, true)
	tutorial_targets["upgrade_buy"] = purchase
	theme_source.button_art(purchase, theme_source.UPGRADE_ART, 56)
	var thresholds: Array = [1, 2, 3, 4, 5] if site == "fuel" else Campus.THRESHOLDS
	for index in range(thresholds.size()):
		var stage_number: int = thresholds[index]
		var achieved := tier >= stage_number
		var icon_set: Array = theme_source.STAGE_ART
		var picture: Texture2D = icon_set[index] if site == "fuel" else theme_source.NAV.sites
		var tile := PanelContainer.new()
		tile.add_theme_stylebox_override("panel", theme_source.style(Color("#e8efd9") if achieved else Color("#f6ecda"), theme_source.RIM, 19, 12))
		rows.add_child(tile)
		var slot := HBoxContainer.new()
		tile.add_child(slot)
		slot.add_theme_constant_override("separation", 14)
		theme_source.icon(slot, picture, 144)
		var copy := VBoxContainer.new()
		slot.add_child(copy)
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		copy.alignment = BoxContainer.ALIGNMENT_CENTER
		var name_key: String = ("fuel_stage_" if site == "fuel" else "roof_stage_") + str(index + 1)
		var name: Label = theme_source.caption(copy, 29, theme_source.INK, theme_source.HEAVY)
		name.text = controller.t(name_key)
		name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var requirement: Label = theme_source.caption(copy, 22, theme_source.MINT if achieved else theme_source.FADE)
		requirement.text = controller.t("look_built") if achieved else controller.t("look_requires") % stage_number

func show_team() -> void:
	section_tabs(["team_staff", "team_cards"], team_tab, switch_team)
	if team_tab == "team_cards":
		show_managers()
		return
	var store: HbtEconomy = controller.economy
	var id: String = controller.selected
	var facility: HbtService = store.facilities[id]
	var employees: Array = store.crew[id]
	var cap := store.capacity(id)
	var summary := box(controller.site_name(id), controller.t("crew_capacity") % [employees.size(), cap, controller.t("role_" + facility.role)])
	var cost := store.recruit_cost(id)
	tutorial_targets["hire"] = button(summary, controller.t("recruit") % controller.money(cost), controller.hire_worker,
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
func show_managers() -> void:
	var store: HbtEconomy = controller.economy
	box(controller.t("manager_collection") % [store.cards.size(), Book.MANAGERS.size()],
		controller.t("manager_capacity") % [store.equipped.size(), store.CONFIG.max_active_managers])
	for key in Book.MANAGERS:
		var director: Dictionary = Book.MANAGERS[key]
		var rank := store.manager_rank(key)
		var base: Color = RARITY[director.rarity]
		var surface := PanelContainer.new()
		rows.add_child(surface)
		surface.add_theme_stylebox_override("panel", theme_source.style(base.lerp(theme_source.PANEL, 0.66), base.darkened(0.20), 21, 17))
		var stack := VBoxContainer.new()
		stack.add_theme_constant_override("separation", 8)
		surface.add_child(stack)
		var hero := HBoxContainer.new()
		hero.add_theme_constant_override("separation", 17)
		stack.add_child(hero)
		var portrait := load("res://assets/ui/managers/%s.png" % key) as Texture2D
		theme_source.icon(hero, portrait, 138)
		var copy := VBoxContainer.new()
		hero.add_child(copy)
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		copy.alignment = BoxContainer.ALIGNMENT_CENTER
		var title: Label = theme_source.caption(copy, 29, theme_source.INK, theme_source.HEAVY)
		title.text = director.name
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var badge: Label = theme_source.caption(copy, 21, base.darkened(0.60), theme_source.HEAVY)
		var specialty: String = controller.t("manager_all") if director.site.is_empty() else controller.site_name(director.site)
		badge.text = controller.t("rarity_" + director.rarity) + " · " + specialty
		badge.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var description: Label = theme_source.caption(copy, 23, theme_source.INK)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.text = controller.t("skill_" + director.skill)
		if director.skill != "collect":
			description.text = description.text % int(store.manager_effect(key) / 100.0)
		elif rank > 1:
			description.text += " " + controller.t("skill_collect_bonus") % ((rank - 1) * 3)
		if rank == 0:
			var source := card_source(store, key)
			button(stack, controller.t("manager_source") % source.label, open_card_source.bind(source))
			continue
		var rank_label: Label = theme_source.caption(stack, 22, theme_source.MINT, theme_source.HEAVY)
		rank_label.text = controller.t("manager_rank") % [rank, Managers.MAX_RANK]
		mission_bar(stack, rank, Managers.MAX_RANK)
		var band := HBoxContainer.new()
		stack.add_child(band)
		band.add_theme_constant_override("separation", 9)
		var active: bool = key in store.equipped
		var toggle := button(band, controller.t("remove" if active else "assign"), controller.assign_manager.bind(key),
			not active and store.equipped.size() >= store.CONFIG.max_active_managers, true)
		toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var quote := store.manager_training(key)
		if not quote.is_empty():
			var train := button(band, controller.t("manager_train") % quote.cost, controller.train_manager.bind(key), not quote.ready)
			train.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if store.player_level() < quote.level:
				var requirement: Label = theme_source.caption(stack, 20, theme_source.FADE)
				requirement.text = controller.t("manager_gate") % quote.level

func card_source(store: HbtEconomy, id: String) -> Dictionary:
	for item in Book.MILESTONES:
		if item.reward.get("card") == id:
			return {"tab": "career", "chapter": 0, "label": controller.t("objective_" + item.id)}
	for item in store.missions.values():
		if item.reward.get("card") == id:
			var index := 0
			for chapter in Journey.CHAPTERS:
				if chapter[0] == item.site:
					return {"tab": "chapters", "chapter": index, "label": controller.site_name(item.site)}
				index += 1
	return {"tab": "events_tab", "chapter": 0, "label": controller.t("events_tab")}

func open_card_source(source: Dictionary) -> void:
	goals_tab = source.tab
	chapter_index = source.chapter
	show_page("goals")

func show_goals() -> void:
	section_tabs(["career", "chapters", "events_tab"], goals_tab, switch_goals)
	var store: HbtEconomy = controller.economy
	match goals_tab:
		"chapters": show_chapter(store)
		"events_tab": show_event(store)
		"career":
			show_player_rank(store)
			for item in Book.MILESTONES:
				show_mission(store, item, controller.t("objective_" + item.id), true)

func show_player_rank(store: HbtEconomy) -> void:
	var rank := store.player_level()
	var card := box(controller.t("career_level") % rank)
	if rank < Journey.LEVEL_XP.size():
		var start: int = Journey.LEVEL_XP[rank - 1]
		var end: int = Journey.LEVEL_XP[rank]
		var label: Label = theme_source.caption(card, 23, theme_source.FADE)
		label.text = controller.t("career_xp") % [store.player_xp - start, end - start]
		mission_bar(card, store.player_xp - start, end - start)
	else:
		var label: Label = theme_source.caption(card, 23, theme_source.MINT)
		label.text = controller.t("career_max")
	if rank > store.paid_player_level:
		var reward := store.player_reward()
		var action := button(card, controller.t("career_reward") % [controller.money(HbtAmount.from(reward.cash)), reward.diamond],
			controller.claim_player_reward, false, true)
		theme_source.button_art(action, theme_source.REPUTATION, 61)

func show_chapter(store: HbtEconomy) -> void:
	var data: Array = Journey.CHAPTERS[chapter_index]
	var site: String = data[0]
	var missions: Array = store.chapters[site]
	var done := 0
	for item in missions:
		done += int(store.claimed.has(item.id))
	var title := box(controller.site_name(site), controller.t("chapter_progress") % [chapter_index + 1, Journey.CHAPTERS.size(), done, missions.size()])
	mission_bar(title, done, missions.size())
	var movement := HBoxContainer.new()
	title.add_child(movement)
	movement.add_theme_constant_override("separation", 10)
	button(movement, "‹", open_chapter.bind(chapter_index - 1), chapter_index == 0).custom_minimum_size.x = 88
	var place := button(movement, controller.t("site_details"), go_to_site.bind(site), false, true)
	place.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button(movement, "›", open_chapter.bind(chapter_index + 1), chapter_index == Journey.CHAPTERS.size() - 1).custom_minimum_size.x = 88
	if store.player_level() < int(data[1]):
		box(controller.t("chapter_locked") % data[1])
		return
	for item in missions:
		var available := store.mission_available(item)
		if not available:
			continue
		var title_text: String
		match item.counter:
			"site_level":
				title_text = controller.t("mission_open") % controller.site_name(site) if item.goal == 1 else \
					controller.t("mission_site_level") % [controller.site_name(site), item.goal]
			"site_revenue":
				title_text = controller.t("mission_site_revenue") % [controller.site_name(site), controller.money(HbtAmount.from(item.goal))]
			"reputation", "manager_ranks":
				title_text = controller.t("mission_" + item.counter) % item.goal
			_:
				title_text = controller.t("mission_" + item.counter) % [controller.site_name(site), item.goal]
		show_mission(store, item, title_text, false)
	if missions.any(func(item: Dictionary) -> bool: return not store.mission_available(item)):
		box(controller.t("mission_next_wave"))

func open_chapter(index: int) -> void:
	chapter_index = clampi(index, 0, Journey.CHAPTERS.size() - 1)
	scroll.scroll_vertical = 0
	refresh()

func go_to_site(site: String) -> void:
	controller.select_site(site)
	hide_page()

func show_mission(store: HbtEconomy, item: Dictionary, title: String, original: bool) -> void:
	var count := store.mission_progress(item)
	var rewards: PackedStringArray = []
	for key in item.reward:
		if key == "card":
			rewards.append(Book.MANAGERS[item.reward.card].name)
		else:
			rewards.append("%d %s" % [item.reward[key], controller.t("currency_" + key)])
	var current: String = str(count)
	var required: String = str(item.goal)
	if item.counter == "site_revenue":
		current = controller.money(HbtAmount.from(count))
		required = controller.money(HbtAmount.from(item.goal))
	var detail: String = controller.t("progress_pair") % [current, required]
	var category: String = controller.t(item.group if original else "mission")
	var row := box(title, "%s · %s\n%s" % [category, detail, "  +  ".join(rewards)])
	mission_bar(row, count, item.goal)
	var done := store.claimed.has(item.id)
	var action := button(row, controller.t("claimed" if done else "claim"), controller.claim_milestone.bind(item.id),
		done or count < item.goal, true)
	if item.id in ["first", "upgrade"]:
		tutorial_targets[item.id] = action

func show_event(store: HbtEconomy) -> void:
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

func show_finance() -> void:
	var store: HbtEconomy = controller.economy
	var till := store.holding()
	box(controller.t("fin_cash"), controller.money(store.amount("cash"), true))
	var registers := box(controller.t("fin_register"), controller.money(till, true))
	button(registers, controller.t("collect_action") % controller.money(till), controller.collect_income, till.empty(), true)
	box(controller.t("fin_gross"), controller.money(store.gross, true))
	box(controller.t("fin_spent"), controller.money(store.spent, true))
	box(controller.t("fin_flow"), controller.flow_text())
	var bonus := store.boost_until - store.clock
	var boost := box(controller.t("boost_running") % controller.clock_text(bonus) if bonus > 0 else
		controller.t("boost") % store.CONFIG.boost_cost)
	if bonus <= 0:
		button(boost, controller.t("boost") % store.CONFIG.boost_cost, controller.buy_boost,
			not store.can_afford(HbtAmount.from(store.CONFIG.boost_cost), "diamond"))
	if controller.ads.privacy_required():
		button(rows, controller.t("ad_privacy"), controller.ads.privacy)
	var away := box(controller.t("offline_header"), controller.t("fin_offline") % controller.clock_text(store.offline_limit()))
	var offer := store.offline_upgrade()
	if not offer.is_empty():
		var note: Label = theme_source.caption(away, 22, theme_source.FADE)
		note.text = controller.t("offline_gate") % offer.level
		button(away, controller.t("offline_upgrade") % [offer.hours, controller.money(offer.cost)],
			controller.upgrade_offline, not offer.ready, true)
	if not store.offline_pending.empty():
		button(away, controller.t("offline_banner") % controller.money(store.offline_pending), show_page.bind("offline"))
	button(rows, controller.t("haptics_on" if store.feedback_enabled else "haptics_off"), controller.toggle_feedback)
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
	var card := box(controller.t("offline_panel"))
	var hero := HBoxContainer.new()
	card.add_child(hero)
	theme_source.icon(hero, theme_source.CASH, 126)
	var stats := VBoxContainer.new()
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero.add_child(stats)
	var score: Label = theme_source.caption(stats, 43, theme_source.MINT, theme_source.HEAVY)
	score.text = controller.money(value)
	var elapsed: Label = theme_source.caption(stats, 25, theme_source.INK)
	elapsed.text = controller.t("offline_away") % controller.clock_text(store.offline_away_seconds)
	var credited: Label = theme_source.caption(card, 24, theme_source.FADE)
	credited.text = controller.t("offline_limit") % [controller.clock_text(store.offline_seconds), controller.clock_text(store.offline_limit())]
	mission_bar(card, store.offline_seconds, store.offline_limit())
	button(card, controller.t("claim_offline") % controller.money(value), controller.claim_offline,
		controller.ads.busy(), true)
	if controller.ads.available():
		if controller.ads.busy() or controller.ads.ready():
			var desc: String = controller.t("bonus_running") if controller.ads.busy() else controller.t("claim_bonus") % controller.money(value.times(2))
			button(card, desc, controller.start_offline_ad, controller.ads.busy())
		else:
			var loading: bool = controller.ads.loading()
			button(card, controller.t("ad_loading" if loading else "ad_prepare"), controller.ads.prepare, loading)
