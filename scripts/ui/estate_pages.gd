extends RefCounted

const Catalog = preload("res://data/estate/complex_design.gd")
const WorkshopArt = preload("res://scripts/estate/estate_view.gd")
const DEPOT = preload("res://assets/ui/business/metro_logistics.png")
const GARDEN = preload("res://assets/ui/business/ocean_vip_park.png")
const PAGES := ["design", "infrastructure", "marketing", "inspections"]

var panel: CanvasLayer
var game: Node3D
var hud: CanvasLayer
var family := "facade"
var selected := -1

func bind(owner: CanvasLayer) -> void:
	panel = owner
	game = owner.controller
	hud = owner.theme_source

func t(key: String) -> String:
	return game.t(key)

func name_of(translation: Array) -> String:
	return translation[int(game.economy.language == "en")]

func signature(page: String) -> String:
	if page not in PAGES:
		return ""
	var estate: HbtEconomy = game.economy
	return str([page, estate.language, estate.works.revision, estate.customers, estate.levels,
		estate.amount("cash").decimal(), family, selected, not estate.works.active(estate.clock).is_empty()])

func show(page: String) -> bool:
	match page:
		"design": show_design()
		"infrastructure": show_infrastructure()
		"marketing": show_marketing()
		"inspections": show_inspections()
		_: return false
	return true

func nav(container: Control, page: String) -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 7)
	container.add_child(grid)
	for target in PAGES:
		if target != page:
			panel.button(grid, t(target + "_header"), panel.show_page.bind(target)).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.button(grid, t("empire_header"), panel.show_page.bind("empire")).size_flags_horizontal = Control.SIZE_EXPAND_FILL

func show_design() -> void:
	var hero: VBoxContainer = panel.feature(GARDEN, t("design_header"), t("design_intro"))
	nav(hero, "design")
	var chooser := GridContainer.new()
	chooser.columns = 3
	chooser.add_theme_constant_override("h_separation", 7)
	chooser.add_theme_constant_override("v_separation", 7)
	panel.rows.add_child(chooser)
	for category: String in Catalog.STYLES:
		var tab: Button = panel.button(chooser, t("design_" + category), choose.bind(category), false, family == category)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.add_theme_font_size_override("font_size", 23)
	var theme: VBoxContainer = panel.box(t("design_" + family))
	var estate: HbtEconomy = game.economy
	if selected > 0 and DisplayServer.get_name() != "headless":
		preview(theme)
	if family == "planter":
		panel.logistics.offer(theme, "yard_gift", {})
	var variants: Array = Catalog.STYLES[family]
	var current: int = int(estate.works.designs.get(family, 0))
	for variant in range(0, variants.size() + 1):
		var quote: Dictionary = estate.works.custom_quote(estate, family, variant)
		var description := name_of(variants[variant - 1]) if variant > 0 else t("design_default")
		var row: VBoxContainer = panel.box(description, t("design_active") if variant == current else "")
		if quote.requirement > 0 and not quote.owned:
			hud.caption(row, 22, hud.FADE).text = t("design_unlock") % quote.requirement
		if quote.cost.empty() and quote.ready and variant != current:
			hud.caption(row, 22, hud.FADE).text = t("design_earned")
		if selected != variant and variant > 0:
			panel.button(row, t("design_preview"), select_style.bind(variant))
		if selected == variant or variant == 0:
			var text := t("design_apply") if quote.cost.empty() else t("design_buy") % game.money(quote.cost)
			panel.button(row, text, apply_style.bind(variant), variant == current or not quote.ready, true)
	panel.button(panel.rows, t("design_view_yard"), game.view_estate.bind(false))

func choose(category: String) -> void:
	family = category
	selected = -1
	panel.refresh()

func select_style(variant: int) -> void:
	selected = variant
	panel.refresh()

func apply_style(variant: int) -> void:
	if game.economy.works.set_style(game.economy, family, variant):
		game.feedback.play("build", true)
		game.sync_estate()
	panel.refresh()

func preview(parent: Control) -> void:
	var frame := SubViewportContainer.new()
	frame.custom_minimum_size.y = 302
	frame.stretch = true
	frame.stretch_shrink = 2
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(frame)
	var scene := SubViewport.new()
	scene.own_world_3d = true
	scene.render_target_update_mode = SubViewport.UPDATE_ONCE
	frame.add_child(scene)
	var room := Node3D.new()
	scene.add_child(room)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("#3d616c")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("#d7e5dd")
	world.environment.ambient_light_energy = .61
	room.add_child(world)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-52,-26,0)
	key.light_color = Color("#fff1cc")
	key.light_energy = 1.15
	key.shadow_enabled = true
	room.add_child(key)
	var lens := Camera3D.new()
	lens.projection = Camera3D.PROJECTION_ORTHOGONAL
	lens.size = 3.98 if family != "billboard" else 5.1
	room.add_child(lens)
	lens.position = Vector3(4,4.7,7.0)
	lens.look_at(Vector3(0,.77,0))
	lens.current = true
	WorkshopArt.slab(room,Vector3(0,-.13,0),Vector3(18,.21,18),Color("#4a7777"))
	if family not in WorkshopArt.PAINT:
		WorkshopArt.add_prop(room, family, selected, Vector3.ZERO)
		return
	game.sync_estate(true)
	var base: Node3D = game.estate_view.structure()
	if base == null:
		return
	var sample := base.duplicate() as Node3D
	sample.position = Vector3.ZERO
	sample.rotation.y = 0
	sample.scale = Vector3.ONE * .45
	room.add_child(sample)
	for node: MeshInstance3D in sample.find_children("*", "MeshInstance3D", true, false):
		if node.mesh is ArrayMesh:
			node.mesh = WorkshopArt.dyed(node.mesh, {family:selected})

func show_infrastructure() -> void:
	var hero: VBoxContainer = panel.feature(DEPOT, t("infrastructure_header"), t("infrastructure_intro"))
	nav(hero, "infrastructure")
	var estate: HbtEconomy = game.economy
	var rule: RefCounted = estate.works
	panel.button(panel.rows, t("infrastructure_view"), game.view_estate.bind(true))
	for id: String in Catalog.INFRASTRUCTURE:
		var stage: int = rule.stage(id)
		var card: VBoxContainer = panel.box(name_of(Catalog.INFRASTRUCTURE[id]), t("infrastructure_level") % stage)
		var detail: Label = hud.caption(card, 23, hud.FADE)
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.text = t("works_" + id)
		var needed := 4 + stage * 4
		if stage < 3:
			var quote: HbtAmount = rule.construction_cost(estate, id)
			if estate.level("fuel") < needed:
				hud.caption(card, 22, hud.FADE).text = t("infrastructure_gate") % needed
			panel.button(card, t("infrastructure_build") % game.money(quote), install.bind(id),
				not estate.can_afford(quote) or estate.level("fuel") < needed, true)

func install(id: String) -> void:
	if game.economy.works.build(game.economy, id):
		game.feedback.play("build", true)
		game.view_estate(true)
		if game.motion_enabled():
			for node: Node3D in game.estate_view.upgrades.get_children():
				if node.get_meta("work") == id:
					WorkshopArt.Art.settle(node)
					break
	else:
		panel.refresh()

func show_marketing() -> void:
	var hero: VBoxContainer = panel.feature(GARDEN, t("marketing_header"), t("marketing_intro"))
	nav(hero, "marketing")
	var estate: HbtEconomy = game.economy
	var advertising: Dictionary = estate.works.active(estate.clock)
	if not advertising.is_empty():
		panel.box(name_of(advertising.name), t("marketing_running") % game.clock_text(int(estate.works.campaign.until) - estate.clock))
	for id: String in Catalog.CAMPAIGNS:
		var offer: Dictionary = Catalog.CAMPAIGNS[id]
		var card: VBoxContainer = panel.box(name_of(offer.name), t("marketing_effect") % [
			roundi((float(offer.traffic) - 1.0) * 100.0), game.clock_text(int(offer.seconds))])
		var bill: HbtAmount = estate.works.campaign_price(estate, id)
		var available: bool = estate.works.market_ready(estate, id)
		if not available:
			hud.caption(card, 22, hud.FADE).text = t("marketing_gate")
		panel.button(card, t("marketing_launch") % game.money(bill), start_campaign.bind(id),
			not advertising.is_empty() or not available or not estate.can_afford(bill), true)

func start_campaign(id: String) -> void:
	if game.economy.works.promote(game.economy, id):
		game.feedback.play("reward")
	panel.refresh()

func show_inspections() -> void:
	var hero: VBoxContainer = panel.feature(GARDEN, t("inspections_header"), t("inspections_intro"))
	nav(hero, "inspections")
	var estate: HbtEconomy = game.economy
	var office: RefCounted = estate.works
	var demand: VBoxContainer = panel.box(t("inspection_rating") % office.rating, t("inspection_samples") % office.samples)
	panel.logistics.add_bar(demand, office.rating, 100, Color("#6aa883"))
	var queue := int(office.bottlenecks.get("queue",0))
	var capacity := int(office.bottlenecks.get("capacity",0))
	var detail := t("inspection_queue") if queue > capacity else t("inspection_capacity")
	if max(queue,capacity) > 0:
		hud.caption(demand, 23, hud.FADE).text = detail
	for id: String in Catalog.AUDITS:
		var goal: Dictionary = Catalog.AUDITS[id]
		var check: Dictionary = office.inspection(estate, id)
		var card: VBoxContainer = panel.box(name_of(goal.name), t("inspection_thresholds") % [
			check.best, goal.level, check.visits, goal.sales, goal.rating])
		if office.awards.has(id):
			hud.caption(card, 26, Color("#538677"), hud.HEAVY).text = t("inspection_awarded")
		else:
			panel.button(card, t("inspection_prize") % game.money(check.reward), claim.bind(id), not check.ready, true)

func claim(id: String) -> void:
	if game.economy.works.claim_inspection(game.economy, id):
		game.reward_feedback()
	panel.refresh()
