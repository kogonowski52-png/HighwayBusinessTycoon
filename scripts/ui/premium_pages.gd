extends RefCounted

const Atlas = preload("res://data/world/atlas.gd")
const Config = preload("res://data/monetization/config.gd")
const TREASURY := "res://assets/ui/premium/treasury.png"
const GEMS := "res://assets/ui/premium/gems.png"
const BUILDER := "res://assets/ui/premium/builder.png"
const SEASON := "res://assets/ui/premium/season.png"
const PACK_ART := "res://assets/ui/premium/offers/"
const REWARDS := ["gift", "cash", "boost", "upgrade", "daily", "training", "vip", "delivery", "manager", "event"]
const QUICK_TABS := ["shop_featured", "shop_free", "shop_gems"]

const SHOP_TABS: Array[String] = ["shop_featured", "shop_free", "shop_gems", "shop_special", "shop_cash", "shop_directors",
	"shop_business", "shop_boost", "shop_season", "shop_remove_ads"]
const SHOP_TINTS := {
	"shop_featured": Color("#31586b"),
	"shop_special": Color("#3b6574"), "shop_free": Color("#307968"), "shop_gems": Color("#634979"),
	"shop_cash": Color("#795525"), "shop_directors": Color("#70466b"), "shop_business": Color("#315d79"),
	"shop_boost": Color("#755527"), "shop_season": Color("#375e77"), "shop_remove_ads": Color("#3c6f61"),
}
const SHOP_SKINS := {
	"shop_featured": "petrol",
	"shop_special": "petrol", "shop_free": "jade", "shop_gems": "plum",
	"shop_cash": "amber", "shop_directors": "berry", "shop_business": "blue",
	"shop_boost": "amber", "shop_season": "blue", "shop_remove_ads": "jade",
}
const PASS_TABS: Array[String] = ["pass_free", "pass_premium"]

var panel: CanvasLayer
var game: Node3D
var hud: CanvasLayer
var offer := "cash"
var detail := {}
var shop_tab := "shop_featured"
var pass_index := -1
var pass_paid := false
var clock_label: Label
var boost_bar: ProgressBar
var boost_mark: Label
var clocks := {}
var textures: Dictionary = {}
var navigation: GridContainer
var tabs := {}
var slide_cards := false

func bind(owner: CanvasLayer) -> void:
	panel = owner
	game = owner.controller
	hud = owner.theme_source

func setup_navigation(parent: Control) -> void:
	navigation = GridContainer.new()
	navigation.columns = 3
	navigation.add_theme_constant_override("h_separation", 7)
	navigation.add_theme_constant_override("v_separation", 7)
	parent.add_child(navigation)
	for id: String in QUICK_TABS:
		var tab: Button = hud.action(navigation, 0, 70, false)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		tab.add_theme_font_size_override("font_size", 23)
		hud.button_art(tab, tab_art(id), 38)
		tab.pressed.connect(choose_tab.bind(id))
		tabs[id] = tab
	navigation.hide()

func show(page: String) -> bool:
	clocks.clear()
	match page:
		"boost": booster()
		"shop": shop()
		"pass": season_pass()
		"reward_offer": ad_offer()
		"free_rewards": free_rewards()
		_: return false
	return true

func signature(page: String) -> String:
	var e: HbtEconomy = game.economy
	var p: HbtPremiumState = game.campaign.premium
	match page:
		"boost":
			var boost: HbtBoost = game.campaign.boost
			return str([page, e.language, boost.earning(e.clock), boost.can_extend(e.clock),
				ad_signature("boost"), game.purchases.busy()])
		"shop":
			return str([page, shop_tab, e.language, e.amount("diamond").decimal(), e.amount("event").decimal(),
				e.recognition.vouchers, e.boost_until > e.clock, p.entitlements, p.play_session.is_empty(),
				purchase_signature(), ad_signature("gift"), ad_signature("boost"), ad_signature("cash"), e.levels, p.account,
				shop_availability(), game.campaign.boost.can_extend(e.clock), game.campaign.boost.earning(e.clock)])
		"free_rewards":
			return str([page, e.language, e.recognition.last_day, p.offer_history, e.levels, reward_availability(),
				ad_signature("gift"), ad_signature("boost"), ad_signature("cash"), game.purchases.busy()])
		"pass":
			var chosen := selected_pass()
			return str([page, pass_index, pass_paid, e.language, p.pass_progress.get(chosen.get("sku"), {}),
				p.entitlements, purchase_signature(), e.clock >= chosen.get("end", 0), e.clock >= chosen.get("claim_end", 0)])
		"reward_offer":
			return str([page, offer, detail, e.language, game.ads.playable(offer, detail), ad_signature(offer), game.purchases.busy()])
	return ""

func purchase_signature() -> Array:
	var store: Node = game.purchases
	return [store.catalogue, store.catalog_status, store.status, store.verifier, store.busy(), store.pending_products]

func ad_signature(id: String) -> Array:
	return [game.ads.available(), game.ads.placement_status(id), game.ads.issue(id), game.ads.wait_offer, game.ads.displaying()]

func reward_availability() -> Array:
	var states: Array = []
	for id: String in REWARDS:
		var selection: Dictionary = game.ads.featured_context(id)
		states.append([selection, game.ads.playable(id, selection)])
	return states

func shop_availability() -> Array:
	var keys: Array = []
	for id in ["gift", "cash", "manager", "vip", "delivery"]:
		keys.append(game.ads.playable(id))
	for id in Config.PRODUCTS:
		keys.append(game.purchases.eligible(id))
	keys.append(Config.season_at(game.economy.clock).get("sku", ""))
	return keys

func tab_art(id: String) -> Texture2D:
	match id:
		"shop_free": return hud.REWARD_VIDEO
		"shop_gems": return hud.DIAMOND
		"shop_cash": return hud.CASH
		"shop_directors": return hud.NAV.managers
		"shop_business": return hud.UPGRADE_ART
		"shop_boost": return hud.BOLT
		"shop_season": return art(SEASON)
		"shop_remove_ads": return art(PACK_ART + "quiet.png")
	return hud.GIFT

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
	var card := market_card(art(PACK_ART + "boost_feature.png"), text("boost_offer_title"), text("boost_copy"), "shop_boost")
	var timer := HBoxContainer.new()
	card.add_child(timer)
	boost_mark = hud.caption(timer, 53, Color("#ffd16a"), hud.HEAVY)
	boost_mark.text = "×2"
	boost_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boost_mark.custom_minimum_size.x = 146
	clock_label = hud.caption(timer, 34, Color("#ffe196"), hud.HEAVY)
	clock_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boost_bar = ProgressBar.new()
	boost_bar.show_percentage = false
	boost_bar.max_value = Config.CAP_SECONDS
	boost_bar.custom_minimum_size.y = 21
	boost_bar.add_theme_stylebox_override("background", hud.style(Color("#213942"), Color("#3e6260"), 9, 0))
	boost_bar.add_theme_stylebox_override("fill", hud.style(Color("#efb94f"), Color("#ba8530"), 9, 0))
	card.add_child(boost_bar)
	update_clock()
	note(card, text("boost_cap") % floori(Config.CAP_SECONDS / 60.0), Color("#fff0c2"))
	ad_action(card, "boost", {}, true)
	panel.box(text("boost_offer_blurb"), text("boost_offer_body") + "\n" + text("boost_offline_copy"))
	if panel.animate_bars:
		boost_flash()

func boost_flash() -> void:
	if not is_instance_valid(boost_mark) or not game.motion_enabled():
		return
	boost_mark.pivot_offset = boost_mark.size * .5
	boost_mark.scale = Vector2.ONE * .83
	var effect := boost_mark.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	effect.tween_property(boost_mark, "scale", Vector2.ONE, .35)

func update_clock() -> void:
	for id: String in clocks:
		var label: Label = clocks[id]
		if is_instance_valid(label):
			var remaining: int = game.campaign.premium.offer_wait(id, game.economy.clock)
			label.text = text("reward_next") % game.clock_text(remaining)
	if panel.page != "boost" and (panel.page != "shop" or shop_tab != "shop_boost"):
		return
	if not is_instance_valid(clock_label) or not is_instance_valid(boost_bar):
		return
	var left: int = game.campaign.boost.remaining(game.economy.clock)
	clock_label.text = "%s  ·  %s" % [text("boost_active"), game.boost_time(left)] if left > 0 else text("boost_off")
	boost_bar.value = left

func shop() -> void:
	for id in QUICK_TABS:
		var tab: Button = tabs[id]
		tab.text = text(id)
		tab.tooltip_text = tab.text
		var current: bool = id == shop_tab
		var face: Texture2D = hud.ACTION if current else hud.CREAM_BUTTON
		var text_tint: Color = hud.CREAM if current else hud.INK
		for state in ["normal", "hover", "pressed"]:
			tab.add_theme_stylebox_override(state, hud.sculpted(face, 40, 11))
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			tab.add_theme_color_override(state, text_tint)
	match shop_tab:
		"shop_featured":
			recommended()
		"shop_special":
			show_products("special")
			panel.extra.shop()
		"shop_free":
			var rewards := market_card(art(PACK_ART + "rewards_feature.png"), text("free_rewards_header"), text("free_collect_detail"), "shop_free")
			panel.button(rewards, text("shop_feature_rewards"), game.open_page.bind("free_rewards"), false, true)
			reward_card("gift", art(GEMS))
		"shop_gems":
			show_products("gems")
		"shop_cash":
			reward_card("cash", art(TREASURY))
			panel.box(text("shop_cash_title"), text("shop_cash_copy"))
			show_products("cash")
		"shop_directors":
			show_products("directors")
			reward_card("manager", panel.extra.portrait(Config.AD_MANAGER))
		"shop_business":
			var district: String = game.economy.district
			if Atlas.DESTINATIONS.has(district):
				var sign := "res://assets/ui/business/%s_fuel.png" % district
				var card := hero(art(sign), game.district_name(district), text("shop_regional_business"))
				panel.button(card, text("shop_regional_open"), game.open_page.bind("sites"), false, true)
			show_products("business")
		"shop_boost":
			booster()
		"shop_season":
			var pass_card := market_card(art(SEASON), text("pass_header"), text("pass_shop_copy"))
			panel.button(pass_card, text("pass_view"), game.open_page.bind("pass"), false, true)
			var season := Config.season_at(game.economy.clock)
			if not season.is_empty():
				product(season.sku, art(SEASON))
			else:
				panel.box(text("pass_between"))
		"shop_remove_ads":
			product("remove_ads", art(PACK_ART + "quiet.png"))
	if shop_tab not in ["shop_free", "shop_boost"]:
		store_status()

func recommended() -> void:
	var display := market_card(art(PACK_ART + "market_feature.png"), text("shop_feature_title"), text("shop_feature_detail"), "shop_featured")
	var rewards: Button = panel.button(display, text("shop_feature_rewards"), game.open_page.bind("free_rewards"), false, true)
	hud.button_art(rewards, hud.REWARD_VIDEO, 49)
	panel.button(display, text("shop_feature_special"), choose_tab.bind("shop_special"))
	if game.purchases.purchasable("starter_pack"):
		product("starter_pack", product_art("starter_pack", "special"))
	var shelf: VBoxContainer = panel.box(text("shop_sections"))
	var sections := GridContainer.new()
	sections.columns = 2
	sections.add_theme_constant_override("h_separation", 9)
	sections.add_theme_constant_override("v_separation", 8)
	shelf.add_child(sections)
	for id in SHOP_TABS.slice(2):
		var link: Button = panel.button(sections, text(id), choose_tab.bind(id))
		link.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		link.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		hud.button_art(link, tab_art(id), 50)

func store_status() -> void:
	var store: Node = game.purchases
	var status: String = store.catalog_status
	var purchase_copy: String = store.status
	if not store.configured():
		note(panel.rows, text("store_closed_caption"), hud.FADE)
		return
	var detail_copy := ""
	if not store.verified_checkout() and store.configured():
		detail_copy = text("store_no_verifier")
	elif store.verified_checkout() and not store.checkout_ready():
		detail_copy = text("store_checking_verifier" if store.verifier == "diagnostic_loading" else "store_verifier_unavailable")
	if store.sideloaded() and status != "store_catalog":
		detail_copy = "\n".join([detail_copy, text("store_sideload")]).strip_edges()
	if purchase_copy != "store_local" and not purchase_copy.is_empty():
		detail_copy = "\n".join([detail_copy, text(purchase_copy)]).strip_edges()
	var title := text(status)
	if status == "store_catalog" and not store.checkout_ready():
		title = text("store_prices_only")
	var narrow: VBoxContainer = panel.box(title, detail_copy)
	if not store.configured():
		return
	if status != "store_catalog" or not store.checkout_ready():
		var in_progress: bool = store.busy() or status == "store_connect" or store.verifier == "diagnostic_loading"
		panel.button(narrow, text("store_retry"), store.open.bind(true), in_progress)
	if store.checkout_ready() and not game.economy.storage.read_only:
		panel.button(narrow, text("store_restore"), store.restore_purchases, store.busy() or game.ads.busy())

func show_products(section: String) -> void:
	for id: String in Config.PRODUCTS:
		var spec: Dictionary = Config.PRODUCTS[id]
		var matches: bool = spec.item.has("cash") if section == "cash" else spec.section == section and id != "remove_ads"
		if matches and game.purchases.eligible(id):
			product(id, product_art(id, spec.section))

func product_art(id: String, section: String) -> Texture2D:
	match section:
		"gems":
			return art(PACK_ART + id + ".png")
		"directors":
			return panel.extra.portrait(Config.AD_MANAGER)
		"business":
			var image := "res://assets/ui/business/north_%s.png"
			if id == "wash_pack":
				return art(image % "wash")
			if id == "workshop_pack":
				return art(image % "workshop")
			if id == "freight_pack":
				return art(image % "truck")
			if id == "coast_pack":
				return art("res://assets/ui/business/ocean_motel.png")
			return art(BUILDER)
	return art(PACK_ART + "starter.png")

func choose_tab(id: String) -> void:
	if shop_tab == id:
		return
	game.ads.cancel_wait()
	game.purchases.cancel_selection()
	shop_tab = id
	panel.scroll.scroll_vertical = 0
	slide_cards = game.motion_enabled()
	panel.refresh()
	slide_cards = false

func free_rewards() -> void:
	market_card(art(PACK_ART + "rewards_feature.png"), text("free_collect_title"), text("free_collect_detail"), "shop_free")
	for id: String in REWARDS:
		var image: Texture2D = hud.GIFT
		match id:
			"gift", "daily", "event": image = art(GEMS)
			"cash": image = art(TREASURY)
			"boost": image = hud.BOLT
			"delivery", "upgrade": image = art(BUILDER)
			"training": image = hud.STAFF
			"manager": image = panel.extra.portrait(Config.AD_MANAGER)
			"vip": image = hud.ROAD
		reward_card(id, image, game.ads.featured_context(id))
	if game.ads.playable("arrival"):
		reward_card("arrival", art(TREASURY))
	var calendar := market_card(hud.CALENDAR, text("calendar_header"), text("shop_calendar_copy"))
	panel.button(calendar, text("shop_calendar_open"), game.open_page.bind("calendar"), false, true)

func reward_card(id: String, icon: Texture2D, selection: Dictionary = {}) -> void:
	var title := text("boost_header") if id == "boost" else text("offer_" + id)
	var card := market_card(icon, title, reward_copy(id, selection))
	if id == "gift":
		var used: int = game.campaign.premium.day_used(id, game.economy.clock)
		note(card, text("reward_gems_counter") % [used, Config.OFFERS.gift[1]], Color("#f5d788"))
	ad_action(card, id, selection, true)

func market_card(icon: Texture2D, title: String, copy: String, palette := "") -> VBoxContainer:
	var tile := PanelContainer.new()
	panel.rows.add_child(tile)
	var section := palette if not palette.is_empty() else shop_tab if panel.page == "shop" else "shop_free" if panel.page == "free_rewards" else "shop_season"
	var tint: Color = SHOP_TINTS[section]
	tile.add_theme_stylebox_override("panel", hud.sculpted(art(PACK_ART + "tile_" + SHOP_SKINS[section] + ".png"), 35, 20))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 13)
	tile.add_child(column)
	var art_row := HBoxContainer.new()
	art_row.add_theme_constant_override("separation", 14)
	column.add_child(art_row)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", hud.style(tint, tint.lightened(.18), 27, 2))
	art_row.add_child(frame)
	var picture: TextureRect = hud.icon(frame, icon, 195)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	art_row.add_child(words)
	var name_label: Label = hud.caption(words, 37, hud.CREAM, hud.HEAVY)
	name_label.text = title
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note(words, copy, Color("#f6ddb0"))
	if panel.animate_bars or slide_cards:
		var reveal := tile.create_tween().set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tile.modulate.a = .50
		picture.pivot_offset = Vector2(97, 97)
		picture.scale = Vector2(.88, .88)
		reveal.tween_property(tile, "modulate:a", 1.0, .22)
		reveal.tween_property(picture, "scale", Vector2.ONE, .28)
	return column

func note(parent: Control, copy: String, tint: Color) -> void:
	if copy.is_empty():
		return
	var label: Label = hud.caption(parent, 24, tint)
	label.text = copy
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func product(id: String, icon: Texture2D) -> void:
	var spec := Config.product(id)
	var items: Dictionary = spec.item
	var named := text("product_" + id) if spec.section != "season" else text("pass_premium")
	var copy := "" if spec.section == "gems" else content(items) if not items.is_empty() else text("no_ads_scope" if id == "remove_ads" else "pass_scope")
	var card := market_card(icon, named, copy)
	var premium: HbtPremiumState = game.campaign.premium
	var store: Node = game.purchases
	if game.economy.storage.read_only:
		note(card, text("store_save_read_only"), hud.CREAM)
		return
	if premium.entitlements.has(id):
		note(card, text("store_owned"), Color("#b4e3ba"))
		return
	if store.pending_products.has(id):
		note(card, text("store_pending"), Color("#f5d88b"))
		return
	var current: Dictionary = store.catalogue.get(id, {})
	var price := str(current.get("price", ""))
	if store.purchasable(id):
		var cue := text("store_sign_in_price" if premium.play_session.is_empty() else "store_buy_price") % price
		var button: Button = panel.button(card, cue, buy_product.bind(id), store.busy() or game.ads.busy(), true)
		hud.button_art(button, hud.CASH, 49)
	else:
		note(card, text("store_not_on_sale") if price.is_empty() else text("store_price_no_checkout") % price, hud.CREAM)

func buy_product(id: String) -> void:
	game.log_commercial("shop_offer_clicked", id)
	game.purchases.buy(id)

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
	var artwork := art(TREASURY) if offer in ["cash", "arrival", "mission", "freight_tip", "practice_bonus"] else art(PACK_ART + "rewards_feature.png")
	var card := market_card(artwork, text("offer_" + offer), reward_copy(offer, detail), "shop_free")
	ad_action(card, offer, detail, true)
	panel.button(panel.rows, text("offer_decline"), panel.hide_page)

func reward_copy(id: String, selection: Dictionary) -> String:
	match id:
		"cash", "arrival":
			var value: HbtAmount = game.ads.cash_reward()
			if game.ads.waiting(id):
				value = game.ads.wait_context.get("cash", value)
			elif game.ads.displaying() and game.ads.offer == id:
				value = game.ads.context.get("cash", value)
			return text("offer_detail_" + id) % game.money(value, true)
		"boost": return text("boost_offer_body")
		"delivery":
			return text("offer_detail_fuel_delivery" if game.ads.delivery_site(selection) == "fuel" else "offer_detail_delivery")
		"upgrade", "training":
			if selection.has("site"):
				var building: String = game.site_name(selection.site)
				var target := text("reward_worker_target") % [building, int(selection.get("index", 0)) + 1] if id == "training" else building
				return "%s\n%s" % [text("offer_detail_" + id), target]
	return text("offer_detail_" + id)

func unavailable_reward(parent: Control, id: String, ink: Color) -> void:
	if Config.OFFERS.has(id):
		var remaining: int = game.campaign.premium.offer_wait(id, game.economy.clock)
		if remaining > 0:
			var label: Label = hud.caption(parent, 24, ink)
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.text = text("reward_next") % game.clock_text(remaining)
			clocks[id] = label
			return
	var requirements := {"boost": "boost_max", "training": "reward_need_worker", "upgrade": "reward_need_upgrade",
		"daily": "reward_need_daily", "event": "reward_need_event", "delivery": "reward_need_delivery"}
	note(parent, text(requirements.get(id, "offer_cooldown")), ink)

func ad_unavailable_message(id: String) -> String:
	var issue: String = game.ads.issue(id)
	if issue in ["network", "no_fill", "privacy", "consent_error", "unconfigured", "timeout"]:
		return text("ad_issue_" + issue)
	return text("ad_wait_available")

func ad_action(parent: Control, id: String, ctx: Dictionary, dark := false, action := "") -> void:
	var ink: Color = hud.CREAM if dark else hud.INK
	var active: bool = game.campaign.boost.earning(game.economy.clock)
	var key := "boost_extend" if id == "boost" and active else "boost_watch" if id == "boost" else "offer_watch"
	if game.ads.waiting(id):
		note(parent, text("ad_loading_wait"), ink)
		if game.motion_enabled():
			var progress := ProgressBar.new()
			progress.show_percentage = false
			progress.indeterminate = true
			progress.custom_minimum_size.y = 10
			parent.add_child(progress)
		panel.button(parent, text("ad_cancel_wait"), game.ads.cancel_wait)
	elif not game.ads.playable(id, ctx):
		unavailable_reward(parent, id, ink)
	elif not game.ads.available():
		note(parent, ad_unavailable_message(id), ink)
	elif game.ads.busy():
		note(parent, text("bonus_running"), ink)
	else:
		var phase: String = game.ads.placement_status(id)
		var status := text("ad_ready") if phase == "ready" else text("ad_loading") if phase in ["initializing", "loading", "reloading"] else ad_unavailable_message(id)
		note(parent, status, ink)
		if game.ads.issue(id) == "privacy" and game.ads.privacy_required():
			panel.button(parent, text("ad_privacy"), game.ads.privacy)
			return
		var button: Button = panel.button(parent, text(key) if action.is_empty() else action,
			game.offer_ad.bind(id, ctx), game.purchases.busy(), true)
		hud.button_art(button, hud.REWARD_VIDEO, 53)

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
		store_status()
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
	game.purchases.cancel_selection()
	pass_index = index
	panel.scroll.scroll_vertical = 0
	panel.refresh()

func change_track(id: String) -> void:
	game.purchases.cancel_selection()
	pass_paid = id == "pass_premium"
	panel.scroll.scroll_vertical = 0
	panel.refresh()
