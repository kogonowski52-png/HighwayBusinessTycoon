extends RefCounted

const Config = preload("res://data/monetization/config.gd")
const TREASURY := "res://assets/ui/premium/treasury.png"
const GEMS := "res://assets/ui/premium/gems.png"
const BUILDER := "res://assets/ui/premium/builder.png"
const SEASON := "res://assets/ui/premium/season.png"

const SHOP_TABS: Array[String] = ["shop_special", "shop_packs", "shop_free", "shop_season"]
const PASS_TABS: Array[String] = ["pass_free", "pass_premium"]

var panel: CanvasLayer
var game: Node3D
var hud: CanvasLayer
var offer := "cash"
var detail := {}
var shop_tab := "shop_special"
var pass_index := -1
var pass_paid := false
var clock_label: Label
var boost_bar: ProgressBar
var textures: Dictionary = {}

func bind(owner: CanvasLayer) -> void:
	panel = owner
	game = owner.controller
	hud = owner.theme_source

func show(page: String) -> bool:
	match page:
		"boost": booster()
		"shop": shop()
		"pass": season_pass()
		"reward_offer": ad_offer()
		_: return false
	return true

func signature(page: String) -> String:
	var e: HbtEconomy = game.economy
	var p: HbtPremiumState = game.campaign.premium
	match page:
		"boost":
			var boost: HbtBoost = game.campaign.boost
			return str([page, e.language, boost.earning(e.clock), boost.can_extend(e.clock),
				game.ads.available(), game.ads.ready("boost"), game.ads.loading("boost"), game.ads.busy()])
		"shop":
			return str([page, shop_tab, e.language, e.amount("diamond").decimal(), e.amount("event").decimal(),
				e.recognition.vouchers, e.boost_until > e.clock, p.entitlements, p.play_session.is_empty(),
				game.purchases.catalogue, game.purchases.status, game.purchases.busy(), game.ads.busy(),
				game.ads.ready("gift"), p.allowed("gift", e.clock), e.levels, p.account])
		"pass":
			var chosen := selected_pass()
			return str([page, pass_index, pass_paid, e.language, p.pass_progress.get(chosen.get("sku"), {}),
				p.entitlements, game.purchases.catalogue, game.purchases.status, e.clock >= chosen.get("end", 0), e.clock >= chosen.get("claim_end", 0)])
		"reward_offer":
			return str([page, offer, detail, e.language, game.ads.available(), game.ads.playable(offer, detail),
				game.ads.ready(offer), game.ads.loading(offer), game.ads.busy()])
	return ""

func art(path: String) -> Texture2D:
	if not textures.has(path):
		textures[path] = load(path)
	return textures[path]

func text(key: String) -> String:
	return game.t(key)

func hero(icon: Texture2D, title: String, copy: String, tint := Color.WHITE) -> VBoxContainer:
	var card: VBoxContainer = panel.feature(icon, title, copy)
	var landscape: TextureRect = card.get_child(0).get_child(0)
	landscape.custom_minimum_size = Vector2(220, 184)
	landscape.modulate = tint
	if panel.animate_bars and game.motion_enabled():
		var art_tween := landscape.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		landscape.pivot_offset = Vector2(95, 120)
		landscape.scale = Vector2(.92, .92)
		art_tween.tween_property(landscape, "scale", Vector2.ONE, .26)
	return card

func booster() -> void:
	var card := hero(hud.BOLT, text("boost_offer_title"), text("boost_copy"))
	clock_label = hud.caption(card, 37, Color("#ffe196"), hud.HEAVY)
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boost_bar = ProgressBar.new()
	boost_bar.show_percentage = false
	boost_bar.max_value = Config.CAP_SECONDS
	boost_bar.custom_minimum_size.y = 21
	boost_bar.add_theme_stylebox_override("background", hud.style(Color("#213942"), Color("#3e6260"), 9, 0))
	boost_bar.add_theme_stylebox_override("fill", hud.style(Color("#efb94f"), Color("#ba8530"), 9, 0))
	card.add_child(boost_bar)
	update_clock()
	var action: VBoxContainer = panel.box(text("boost_offer_blurb"), text("boost_offer_body"))
	ad_action(action, "boost", {})
	panel.box(text("boost_cap") % floori(Config.CAP_SECONDS / 60.0), text("boost_offline_copy"))

func update_clock() -> void:
	if panel.page != "boost" or not is_instance_valid(clock_label) or not is_instance_valid(boost_bar):
		return
	var left: int = game.campaign.boost.remaining(game.economy.clock)
	clock_label.text = "%s  ·  %s" % [text("boost_active"), game.boost_time(left)] if left > 0 else text("boost_off")
	boost_bar.value = left

func shop() -> void:
	hero(art(TREASURY), text("shop_header"), text("premium_shop_copy"))
	if game.purchases.catalogue.is_empty():
		panel.box(text("store_play_price"))
	panel.section_tabs(SHOP_TABS, shop_tab, choose_tab)
	match shop_tab:
		"shop_special":
			for id in ["starter_pack", "remove_ads"]:
				product(id, art(TREASURY) if id == "starter_pack" else hud.BOLT)
			shop_shortcuts()
		"shop_packs":
			panel.box(text("shop_gems_title"))
			for id in Config.PRODUCTS:
				if Config.PRODUCTS[id].section == "gems":
					product(id, art(GEMS))
			panel.box(text("shop_business_title"))
			for id in ["manager_pack", "builder_pack", "workshop_pack", "wash_pack", "freight_pack", "coast_pack"]:
				if game.purchases.eligible(id):
					product(id, art(BUILDER) if id != "manager_pack" else panel.extra.portrait(Config.AD_MANAGER))
		"shop_free":
			free_rewards()
		"shop_season":
			panel.feature(art(SEASON), text("pass_header"), text("pass_shop_copy"))
			panel.button(panel.rows, text("pass_view"), game.open_page.bind("pass"), false, true)
			var season := Config.season_at(game.economy.clock)
			if not season.is_empty():
				product(season.sku, art(SEASON))
	if game.purchases.verified_checkout():
		panel.button(panel.rows, text("store_restore"), game.purchases.restore_purchases,
			game.purchases.busy() or game.ads.busy())
		panel.box(text(game.purchases.status))
	elif game.purchases.configured():
		panel.box(text("store_sandbox_info"))

func shop_shortcuts() -> void:
	panel.button(panel.rows, text("boost_header"), game.open_page.bind("boost"), false, true)
	# The existing shop uses earned in-game currency and remains available offline.
	panel.extra.shop()

func choose_tab(id: String) -> void:
	shop_tab = id
	panel.scroll.scroll_vertical = 0
	panel.refresh()

func free_rewards() -> void:
	for id in ["gift", "cash", "manager", "vip", "delivery"]:
		if id == "delivery" and game.economy.level("warehouse") == 0:
			continue
		var card: VBoxContainer = panel.feature(hud.GIFT if id != "manager" else panel.extra.portrait(Config.AD_MANAGER),
			text("offer_" + id), text("offer_detail_" + id))
		ad_action(card, id, {}, true)
	panel.button(panel.rows, text("calendar_header"), game.open_page.bind("calendar"))
	panel.button(panel.rows, text("boost_header"), game.open_page.bind("boost"), false, true)

func product(id: String, icon: Texture2D) -> void:
	var spec := Config.product(id)
	var items: Dictionary = spec.item
	var named := text("product_" + id) if spec.section != "season" else text("pass_premium")
	var copy := "" if spec.section == "gems" else content(items) if not items.is_empty() else text("no_ads_scope" if id == "remove_ads" else "pass_scope")
	var card := hero(icon, named, copy)
	var premium: HbtPremiumState = game.campaign.premium
	if game.economy.storage.read_only:
		panel.box(text("store_save_read_only"))
		return
	if premium.entitlements.has(id):
		panel.box(text("store_owned"))
		return
	var current: Dictionary = game.purchases.catalogue.get(id, {})
	var price := str(current.get("price", ""))
	if price.is_empty():
		return
	if game.purchases.verified_checkout():
		var cue := text("store_sign_in") + "  ·  " + price if premium.play_session.is_empty() else price
		panel.button(card, cue, game.purchases.buy.bind(id), game.purchases.busy() or game.ads.busy(), true)
	else:
		hud.caption(card, 29, hud.CREAM, hud.HEAVY).text = price

func content(items: Dictionary) -> String:
	var line: PackedStringArray = []
	for key in items:
		match key:
			"cash": line.append(game.money(HbtAmount.from(items.cash)))
			"diamond": line.append(text("item_diamond") % items.diamond)
			"voucher": line.append(text("item_coupon") % items.voucher)
			"card": line.append(HbtEconomy.Managers.ROSTER[items.card].name)
			"decor": line.append(text("item_furnishing"))
	return "  ·  ".join(line)

func select_offer(id: String, selection: Dictionary) -> void:
	offer = id
	detail = selection.duplicate()
	game.open_page("reward_offer")

func ad_offer() -> void:
	var copy := text("offer_detail_" + offer)
	if offer in ["training", "upgrade"] and detail.has("site"):
		copy += "\n" + game.site_name(detail.site)
	var card := hero(art(TREASURY), text("offer_" + offer), copy)
	ad_action(card, offer, detail, true)
	panel.button(panel.rows, text("offer_decline"), panel.hide_page)

func ad_action(parent: Control, id: String, ctx: Dictionary, dark := false) -> void:
	var ink: Color = hud.CREAM if dark else hud.INK
	var active: bool = game.campaign.boost.earning(game.economy.clock)
	var key := "boost_extend" if id == "boost" and active else "boost_watch" if id == "boost" else "offer_watch"
	if not game.ads.playable(id, ctx):
		hud.caption(parent, 22, ink).text = text("boost_max" if id == "boost" else "offer_cooldown")
	elif not game.ads.available():
		var message: Label = hud.caption(parent, 23, ink)
		message.text = text("bonus_unavailable")
		message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	elif game.ads.busy() or game.ads.loading(id):
		hud.caption(parent, 23, ink).text = text("bonus_running" if game.ads.busy() else "ad_loading")
	else:
		var ready: bool = game.ads.ready(id)
		panel.button(parent, text(key if ready else "ad_prepare"), game.offer_ad.bind(id, ctx), game.purchases.busy(), true)

func selected_pass() -> Dictionary:
	if pass_index >= 0 and pass_index < Config.SEASONS.size():
		return Config.season_profile(pass_index)
	var active := Config.season_at(game.economy.clock)
	if not active.is_empty():
		return active
	var last := Config.season_profile(Config.SEASONS.size() - 1)
	if game.economy.clock >= last.end and game.economy.clock < last.claim_end:
		return last
	return {}

func season_pass() -> void:
	var season := selected_pass()
	hero(art(SEASON), text("pass_header") if season.is_empty() else text("season_" + season.id), text("pass_shop_copy"))
	if season.is_empty():
		panel.box(text("pass_between"))
		return
	var index := floori((int(season.start) - Config.SEASON_EPOCH) / float(Config.SEASON_SPAN))
	var active := Config.season_at(game.economy.clock)
	if index > 0 and game.economy.clock < season.start + Config.SEASON_CLAIM_GRACE:
		panel.button(panel.rows, text("pass_previous"), change_season.bind(index - 1))
	if pass_index >= 0 and not active.is_empty() and active.sku != season.sku:
		panel.button(panel.rows, text("pass_current"), change_season.bind(-1))
	var ledger: HbtPremiumState = game.campaign.premium
	var results := ledger.progress(season.sku)
	var level := floori(results.xp / float(Config.XP_PER_TIER))
	var stamp := Time.get_datetime_string_from_unix_time(season.end).left(10)
	var heading: VBoxContainer = panel.box(text("pass_tier") % [level, Config.SEASON_TIERS], text("pass_until") % stamp)
	panel.mission_bar(heading, int(results.xp) % Config.XP_PER_TIER if level < Config.SEASON_TIERS else Config.XP_PER_TIER, Config.XP_PER_TIER)
	var task: VBoxContainer = panel.box(text("pass_mission"), text("metric_" + season.task))
	panel.mission_bar(task, results.tasks, season.goal)
	panel.section_tabs(PASS_TABS, "pass_premium" if pass_paid else "pass_free", change_track)
	if pass_paid and not ledger.entitlements.has(season.sku) and game.economy.clock < season.end:
		game.purchases.open()
		product(season.sku, art(SEASON))
	var completed: Dictionary = results.premium if pass_paid else results.free
	for tier in range(1, Config.SEASON_TIERS + 1):
		var gift := Config.pass_reward(tier, pass_paid, season.id)
		var row: VBoxContainer = panel.box(text("pass_reward_tier") % tier, content(gift))
		var can: bool = tier <= level and not completed.has(str(tier)) and game.economy.clock < season.claim_end 			and (not pass_paid or ledger.entitlements.has(season.sku))
		if can:
			panel.button(row, text("claim"), game.claim_pass.bind(index, tier, pass_paid), false, true)
		elif completed.has(str(tier)):
			hud.caption(row, 21, hud.MINT).text = text("claimed")

func change_season(index: int) -> void:
	pass_index = index
	panel.scroll.scroll_vertical = 0
	panel.refresh()

func change_track(id: String) -> void:
	pass_paid = id == "pass_premium"
	panel.scroll.scroll_vertical = 0
	panel.refresh()
