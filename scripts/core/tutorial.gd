extends CanvasLayer

var controller: Node3D
var hud: CanvasLayer
var stage: Control
var bubble: PanelContainer
var glow: Panel
var instruction: Label
var skip: Button
var phase := 0.0

func setup(game: Node3D, source: CanvasLayer) -> void:
	controller = game
	hud = source
	layer = 6
	stage = Control.new()
	add_child(stage)
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow = Panel.new()
	stage.add_child(glow)
	glow.add_theme_stylebox_override("panel", hud.style(Color.TRANSPARENT, Color("#ffd477"), 19, 0))
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble = PanelContainer.new()
	stage.add_child(bubble)
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.add_theme_stylebox_override("panel", hud.sculpted(hud.PETROL, 35, 14))
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.add_child(row)
	row.add_theme_constant_override("separation", 15)
	hud.icon(row, hud.NAV.goals, 71)
	var words := VBoxContainer.new()
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(words)
	var badge: Label = hud.caption(words, 19, Color("#ffc984"), hud.HEAVY)
	badge.name = "GuideHeading"
	instruction = hud.caption(words, 27, hud.CREAM)
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skip = hud.action(row, 114, 61, false)
	skip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	skip.pressed.connect(controller.skip_tutorial)

func _process(delta: float) -> void:
	if not is_instance_valid(stage):
		return
	var step: int = controller.economy.tutorial_step
	visible = step < controller.economy.TUTORIAL_DONE
	if not visible:
		return
	var shop: Dictionary = controller.economy.construction_quote("market") if step == 5 else {}
	var target := control_for(step, shop)
	var over_panel: bool = controller.operations.modal_open()
	bubble.visible = not over_panel or is_instance_valid(target)
	glow.visible = is_instance_valid(target) and target.is_visible_in_tree()
	if not bubble.visible:
		return
	phase = fmod(phase + delta, 2.0)
	var title: Label = instruction.get_parent().get_node("GuideHeading")
	title.text = "%s · %d/6" % [controller.t("guide_title"), step + 1]
	instruction.text = guidance(step, shop, over_panel)
	skip.text = controller.t("guide_skip")
	bubble.size = Vector2(stage.size.x - 78, 0)
	var y: float = 36 + hud.inset.y if over_panel else hud.bottom.get_global_rect().position.y - bubble.size.y - 13
	bubble.position = Vector2(39, y)
	if glow.visible:
		var rect := target.get_global_rect()
		if over_panel and controller.operations.scroll.is_ancestor_of(target):
			rect = rect.intersection(controller.operations.scroll.get_global_rect())
		glow.visible = rect.has_area()
		glow.position = rect.position - Vector2.ONE * 4
		glow.size = rect.size + Vector2.ONE * 8
		glow.modulate.a = 0.65 + 0.35 * (0.5 + 0.5 * sin(phase * TAU))

func guidance(step: int, shop: Dictionary, over_panel: bool) -> String:
	if not over_panel and hud.management_collapsed and (step in [0, 1, 4] or (step == 5 and not shop.ready)):
		return controller.t("guide_expand")
	if step != 5 or shop.ready and not over_panel:
		return controller.t("guide_%d" % step)
	if over_panel:
		return controller.t("guide_5_build" if shop.ready else "guide_5_wait")
	var market: HbtService = controller.economy.facilities.market
	if not shop.level_ok:
		return controller.t("guide_5_level") % market.prerequisite_level
	if not shop.reputation_ok:
		return controller.t("guide_5_reputation") % [shop.reputation, market.reputation_gate]
	return controller.t("guide_5_cash") % controller.money(shop.cost)

func control_for(step: int, shop: Dictionary = {}) -> Control:
	var panel: CanvasLayer = controller.operations
	if panel.modal_open():
		match step:
			1: return panel.tutorial_targets.get("upgrade_buy")
			2:
				var item := "upgrade" if controller.economy.claimed.has("first") else "first"
				return panel.tutorial_targets.get(item)
			3: return panel.tutorial_targets.get("hire")
			5:
				if panel.page == "sites":
					return panel.tutorial_targets.get("first_business", panel.business.buttons.sites_all)
				return panel.tutorial_targets.get("first_business")
		return null
	if hud.management_collapsed and step in [0, 1, 4]:
		return hud.management_toggle
	match step:
		0: return hud.serve if controller.selected == "fuel" else hud.pages.sites
		1: return hud.upgrade
		2: return hud.pages.goals
		3: return hud.pages.team
		4: return hud.income if hud.income.visible else null
		5:
			if shop.is_empty():
				shop = controller.economy.construction_quote("market")
			if shop.ready or controller.selected != "fuel":
				return hud.pages.sites
			if hud.management_collapsed:
				return hud.management_toggle
			if not shop.level_ok and not hud.upgrade.disabled:
				return hud.upgrade
			if not shop.cash_ok and hud.income.visible:
				return hud.income
			return hud.progress if hud.serve.disabled else hud.serve
	return null
