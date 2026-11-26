extends "res://tests/station_smoke.gd"

const CampaignRules = preload("res://data/world/atlas.gd")
const Config = preload("res://data/monetization/config.gd")
const Fixture = preload("res://tests/reward_fixture.gd")
const UTC := Config.SEASON_EPOCH + 300

func run() -> void:
	clock_checks()
	campaign_checks()
	boost_in_each_district()
	save_path = "/tmp/hbt-premium-check-%s.cfg" % OS.get_process_id()
	game = mount(UTC)
	current_scene = game
	await process_frame
	game.skip_tutorial()
	var provider := Fixture.new()
	game.ads.connect_provider(provider)
	check_rewards(provider)
	check_programs(provider)
	check_billing()
	check_purchase_queue()
	check_catalogue()
	check_final_season_grace()
	game.free()
	await process_frame
	clean_save(save_path)
	await check_delivery()
	result("Monetization, saves and SDK boundaries")

func clock_checks() -> void:
	var b := HbtBoost.new()
	expect(b.remaining(UTC) == 0 and b.extend_confirmed(UTC), "initial boost opens with a whole five minutes")
	expect(b.remaining(UTC + 298) == 2 and b.remaining(UTC + 299) == 1 and not b.earning(UTC + 300), "expiry exactly at 300 seconds")
	for i in 5:
		expect(b.extend_confirmed(UTC), "complete extension %d" % (i + 1))
	expect(b.remaining(UTC) == 1800 and not b.can_extend(UTC + 299) and not b.extend_confirmed(UTC + 299), "cap blocks starting an ad without room at one second")
	expect(b.can_extend(UTC + 300) and b.extend_confirmed(UTC + 300) and b.remaining(UTC + 300) == 1800, "complete extension after freeing 300 seconds")
	var restarted := HbtBoost.new()
	restarted.restore(b.snapshot())
	expect(restarted.advance(UTC - 300, 8000) == UTC + 300 and restarted.advance(UTC - 320, 11000) == UTC + 303, "backward changes cannot pause a live countdown")
	expect(restarted.remaining(UTC + 301) == 1799, "unused interval is restored")
	expect(restarted.advance(UTC + 60_000, 11500) == UTC + 60_000 and not restarted.earning(restarted.clock), "forward clock movement expires rather than extending")
	var future := HbtBoost.new()
	expect(future.extend_confirmed(2_400_000_000) and future.remaining(2_400_000_001) == 299, "64-bit UTC timestamps")

	var uptime := HbtBoost.new()
	uptime.observe_boot(UTC, 10_000, 9)
	uptime.extend_confirmed(UTC)
	var relaunched := HbtBoost.new()
	relaunched.restore(uptime.snapshot())
	expect(relaunched.observe_boot(UTC - 8, 13_000, 9) == UTC + 3 and relaunched.remaining(UTC + 3) == 297,
		"Android elapsedRealtime protects a restart on the same boot")

func campaign_checks() -> void:
	var path := "/tmp/hbt-premium-campaign-%s.cfg" % OS.get_process_id()
	var e := HbtEconomy.new()
	e.storage.path = path
	var world := HbtCampaign.new(e)
	world.restore(UTC)
	expect(world.boost.extend_confirmed(UTC), "global interval")
	e.hire("fuel")
	e.credit("cash", HbtAmount.from(55_000))
	e.credit("reputation", HbtAmount.from(95))
	e.buy_levels("fuel", 10)
	var unit := e.payout("fuel", 100, 0, false)
	e.recognition.vouchers = 1
	e.redeem_voucher()
	expect(e.payout("fuel", 100, 0).compare(unit.times(2)) == 0, "legacy bonuses do not stack with ×2")
	var payment := e.amount("cash")
	e.grant_reward({"cash": 222, "diamond": 4})
	expect(e.amount("cash").compare(payment.plus(HbtAmount.from(222))) == 0 and e.amount("diamond").decimal() == "4",
		"campaign bonus applies neither to missions nor to diamonds")
	var nonboost := e.offline_quote(820)
	var early := e.offline_quote(300)
	expect(world.travel("desert") == OK, "travel uses the shared interval")
	var local := world.current()
	expect(local.global_boost == e.global_boost and local.payout("fuel", 100, -1).compare(local.price("fuel").times(2)) == 0,
		"bonus reaches another district immediately")
	local.clock = UTC + 820
	expect(world.travel("north") == OK and e.offline_pending.compare(nonboost.plus(early)) == 0,
		"absence credited for base wages plus only the overlapping interval")
	expect(e.offline_boosted.compare(early.times(2)) == 0 and e.offline_eligible().compare(nonboost.minus(early)) == 0,
		"the optional offline advertisement cannot turn a prior ×2 into ×4")
	var before := e.offline_pending
	var copy := HbtEconomy.new()
	copy.storage.path = path
	var loaded := HbtCampaign.new(copy)
	loaded.restore(UTC + 820)
	expect(copy.offline_pending.compare(before) == 0 and copy.offline_boosted.compare(early.times(2)) == 0,
		"restart preserves credited divisions and does not rerun the same absence")
	expect(copy.redeem_offline(true, copy.offline_eligible()).compare(nonboost.times(2)) == 0 and copy.redeem_offline().empty(),
		"one offline grant uses one multiplier per eligible period")
	clean_save(path)

func watch(provider: Fixture, id: String, context: Dictionary = {}) -> bool:
	game.ads.prepare(id)
	var began: bool = game.ads.request(id, context)
	if began:
		provider.finish(true, true)
	return began

func check_delivery() -> void:
	var path := "/tmp/hbt-delivery-ad-%s.cfg" % OS.get_process_id()
	var north := HbtEconomy.new()
	north.storage.path = path
	var world := HbtCampaign.new(north)
	world.restore(UTC)
	var metro := HbtEconomy.new("metro")
	metro.storage = world.storage
	metro.global_boost = world.boost
	metro.restore_profile({}, UTC, false)
	world.districts.metro = metro
	world.active = "metro"
	game = load(CampaignRules.DESTINATIONS.metro.scene).instantiate()
	game.campaign = world
	game.wall_override = UTC
	root.add_child(game)
	current_scene = game
	game.set_physics_process(false)
	await process_frame
	metro.credit("cash", HbtAmount.from(1_000_000))
	metro.credit("reputation", HbtAmount.from(200))
	metro.buy_levels("fuel", 25)
	var opened := metro.unlock("logistics")
	metro.buy_levels("logistics", 5)
	expect(opened and metro.unlock("warehouse"), "test opens the real Metro warehouse")
	var provider := Fixture.new()
	game.ads.connect_provider(provider)
	var loadout := metro.commerce.record("warehouse")
	var before := int(loadout.stock)
	expect(watch(provider, "delivery") and int(loadout.stock) == before + 1, "bonus delivery grants one real unit of stock")
	metro.clock += Config.OFFERS.delivery[0] + 1
	loadout.stock = metro.commerce.capacity("warehouse", metro.level("warehouse"))
	expect(not watch(provider, "delivery"), "ad delivery suppressed when the real warehouse is full")
	game.free()
	await process_frame
	clean_save(path)

func boost_in_each_district() -> void:
	var path := "/tmp/hbt-boost-estates-%d.cfg" % OS.get_process_id()
	var estate := HbtEconomy.new()
	estate.storage.path = path
	var world := HbtCampaign.new(estate)
	world.restore(UTC)
	expect(world.boost.extend_confirmed(UTC), "one campaign-wide BOOST starts on North")
	for region: String in CampaignRules.DESTINATIONS:
		if region != "north":
			var travelled := world.travel(region) == OK
			expect(travelled, "campaign travels with active BOOST to " + region)
			if not travelled:
				break
		estate = world.current()
		estate.credit("cash", HbtAmount.from(1_000_000_000))
		estate.credit("reputation", HbtAmount.from(160))
		estate.buy_levels("fuel", 10)
		for site: String in estate.facilities:
			if site != "fuel" and estate.unlock(site):
				estate.buy_levels(site, 10)
		var base := estate.payout("fuel", 100, -1, false)
		expect(estate.district == region and estate.global_boost == world.boost and estate.payout("fuel", 100, -1).compare(base.times(2)) == 0,
			"exactly double service income in " + region)
	clean_save(path)

func check_rewards(provider: Fixture) -> void:
	var e: HbtEconomy = game.economy
	var ads: Node = game.ads
	var world: HbtCampaign = game.campaign
	provider.loads = false
	provider.ready.erase("boost")
	ads.prepare("boost")
	expect(ads.request("boost") and ads.waiting("boost") and world.boost.remaining(UTC) == 0, "no fill waits without a reward")
	ads.cancel_wait()
	provider.loads = true
	ads.prepare("boost")
	expect(ads.request("boost"), "explicit ad placement starts")
	var notices: Array[bool] = []
	ads.unconfirmed.connect(func() -> void: notices.append(true))
	ads.receive("invalid-callback")
	provider.finish(false)
	expect(world.boost.remaining(UTC) == 0 and notices.size() == 1, "cancelled ad and unrelated token do not grant; cancellation is reported")
	expect(watch(provider, "boost") and world.boost.remaining(UTC) == 300, "SDK earnings callback gives five minutes once")
	expect(notices.size() == 1, "completed video has no cancellation notice")
	for i in 5:
		expect(watch(provider, "boost"), "another completed video")
	expect(not watch(provider, "boost") and world.boost.remaining(UTC) == 1800, "the seventh ad is never shown")
	var prior := e.amount("cash")
	expect(watch(provider, "cash") and e.amount("cash").compare(prior.plus(HbtAmount.from(Config.OFFERS.cash[2]))) == 0, "fixed cash grant no ×2")
	expect(not watch(provider, "cash"), "cash cooldown")
	var previous := e.level("fuel")
	expect(watch(provider, "upgrade", {"site": "fuel"}) and e.level("fuel") == previous + 1, "actual free building level")
	e.credit("cash", HbtAmount.from(6000))
	e.hire("fuel")
	expect(watch(provider, "training", {"site": "fuel", "index": 0}) and e.crew.fuel[0].training == 1, "actual free training")
	e.claim_calendar()
	expect(watch(provider, "daily") and not watch(provider, "daily"), "supplementary calendar reward once")
	expect(watch(provider, "gift"), "fixed store gift")
	expect(watch(provider, "manager") and e.cards.has(Config.AD_MANAGER) and not watch(provider, "manager"), "identified, nonrandom manager")
	expect(watch(provider, "vip") and world.premium.vip.has("north") and not watch(provider, "vip"), "one outstanding VIP visit")
	var saved_purse := e.amount("cash")
	var invalid_path: String = world.storage.path
	world.storage.path = invalid_path + "/rejected"
	expect(watch(provider, "mission", {"mission": "first", "offer_day": e.day_index()}) == false,
		"unclaimed mission cannot trigger a reward")
	e.claimed.first = true
	expect(watch(provider, "mission", {"mission": "first", "offer_day": e.day_index()})
		and e.amount("cash").compare(saved_purse) == 0 and not world.premium.offer_history.has("mission"), "save failure rolls back both receipt and cash")
	world.storage.path = invalid_path
	var mission := {"mission": "first", "offer_day": e.day_index()}
	expect(watch(provider, "mission", mission), "one supplementary mission claim")
	e.clock += 601
	expect(not watch(provider, "mission", mission), "same mission is not a second bonus after the cooldown")
	var event: Dictionary = world.ledger.season()
	for task in event.tasks:
		world.ledger.increment(e, {task[0]: task[1]})
	expect(world.ledger.claim_event(e) and watch(provider, "event"), "supplementary event consumes a completed event")
	e.clock += 1840
	expect(not watch(provider, "event"), "each weekly event has a single bonus")
	e.offline_pending = HbtAmount.from(80)
	e.offline_boosted = HbtAmount.from(20)
	var old := e.amount("cash")
	expect(watch(provider, "offline") and e.amount("cash").compare(old.plus(HbtAmount.from(140))) == 0 and e.offline_pending.empty(),
		"confirmed offline ad pays only the specifically eligible extra")
	e.clock = UTC

func check_programs(provider: Fixture) -> void:
	var e: HbtEconomy = game.economy
	var save: HbtPremiumState = game.campaign.premium
	var now := e.clock + 3400
	expect(not save.break_allowed(now, true), "no interstitial in first fifteen minutes")
	save.active_seconds = 901.0
	expect(not save.break_allowed(now, false), "no interstitial during tutorial")
	game.ads.natural_break()
	expect(game.ads.interstitial.is_empty(), "recent ad or introductory session cannot open a break")
	e.clock = now
	game.ads.natural_break()
	game.ads.natural_break()
	expect(not game.ads.interstitial.is_empty(), "eligible natural break takes the actual ad path")
	var token: String = game.ads.interstitial
	provider.break_shown.emit(token)
	provider.break_shown.emit(token)
	provider.break_closed.emit(token)
	expect(save.ad_breaks.size() == 1 and not save.break_allowed(now + 479, true), "one charge per impression and eight-minute floor")
	for t in [480, 960, 1440]:
		save.ad_breaks.append(now + t)
	expect(not save.break_allowed(now + 2100, true), "four breaks per hour")
	save.entitlements.remove_ads = true
	expect(not save.break_allowed(now + 7200, true), "remove_ads blocks breaks only")
	expect(watch(provider, "boost"), "remove_ads preserves explicitly chosen reward videos")
	var season := Config.season_at(e.clock)
	var progress := save.progress(season.sku)
	for i in 380:
		save.record_season(e.clock, {"repairs": 1}, 6)
	expect(progress.xp == Config.SEASON_TIERS * Config.XP_PER_TIER and progress.awarded, "thirty tiers and mission XP")
	game.claim_pass(0, 30, false)
	game.claim_pass(0, 30, true)
	expect(progress.free.has("30") and not progress.premium.has("30"), "free pass works and paid pass gates entitlement")
	save.entitlements[season.sku] = true
	game.claim_pass(0, 30, true)
	expect(save.progress(season.sku).premium.has("30") and e.cards.has(Config.SEASON_CARD), "premium milestone grants known card once")
	expect(Config.season_profile(0).sku != Config.season_profile(1).sku, "different one-time products across seasons")

func check_billing() -> void:
	var e: HbtEconomy = game.economy
	var p: HbtPremiumState = game.campaign.premium
	var id := "a".repeat(64)
	var hash_value := "b".repeat(64)
	var before := e.amount("diamond")
	p.play_account = id
	game.purchases.on_purchases(JSON.stringify([{"product": "gems_100", "state": 2, "token": "pending-test"}]))
	expect(game.purchases.status == "store_pending" and game.purchases.queued.is_empty(), "pending is neither delivered nor verified as a finished purchase")
	var authenticated := {"account": id, "entitlements": ["remove_ads"], "grants": [{"id": hash_value, "product": "gems_100"}]}
	expect(game.purchases.apply_verified(authenticated) and game.purchases.apply_verified(authenticated)
		and e.amount("diamond").compare(before.plus(HbtAmount.from(100))) == 0, "same server receipt cannot credit diamonds twice")
	expect(p.entitlements.has("remove_ads"), "verified non-consumable restores")
	expect(not game.purchases.apply_verified({"account": "other", "entitlements": [], "grants": []}),
		"security boundary ignores mismatched account payload")
	expect(game.purchases.apply_verified({"account": id, "entitlements": [], "grants": []}) and not p.entitlements.has("remove_ads"),
		"verified refund revokes interstitial exemption")

func check_purchase_queue() -> void:
	var purchases: Node = game.purchases
	purchases.queued = {"invalid": "starter_pack", "pending": "gems_550", "next": "gems_100"}
	purchases.request_kind = "receipt"
	purchases.verifying = "invalid"
	purchases.response(HTTPRequest.RESULT_SUCCESS, 409, [], '{"error":"account_mismatch"}'.to_utf8_buffer())
	expect(not purchases.queued.has("invalid") and purchases.queued.size() == 2, "terminal receipt does not block the following purchase")
	purchases.request_kind = "receipt"
	purchases.verifying = "pending"
	purchases.response(HTTPRequest.RESULT_SUCCESS, 503, [], '{"error":"google_unavailable"}'.to_utf8_buffer())
	expect(purchases.queued.keys() == ["next", "pending"] and purchases.retry_at > game.economy.clock,
		"retryable receipt keeps a delayed retry after the next purchase")
	purchases.request_kind = "receipt"
	purchases.verifying = "next"
	purchases.response(HTTPRequest.RESULT_SUCCESS, 422, [], '{"error":"unverified"}'.to_utf8_buffer())
	expect(purchases.queued.keys() == ["pending", "next"], "a token not yet visible to Publisher can be retried")
	purchases.queued.clear()

func check_catalogue() -> void:
	var estate: HbtEconomy = game.economy
	var premium: HbtPremiumState = game.campaign.premium
	var account := "a".repeat(64)
	var ids := Config.PRODUCTS.keys()
	for season in Config.SEASONS:
		ids.append(season.sku)
	var expected_gems := estate.amount("diamond")
	var grants: Array[Dictionary] = []
	var entitlements: Array[String] = []
	var existing := premium.grants.size()
	for id: String in ids:
		var item := Config.product(id)
		expected_gems = expected_gems.plus(HbtAmount.from(item.item.get("diamond", 0)))
		grants.append({"id": id.sha256_text(), "product": id})
		if item.kind == "entitlement":
			entitlements.append(id)
	premium.play_account = account
	var snapshot := {"account": account, "entitlements": entitlements, "grants": grants}
	expect(game.purchases.apply_verified(snapshot) and game.purchases.apply_verified(snapshot)
		and premium.grants.size() == existing + ids.size() and estate.amount("diamond").compare(expected_gems) == 0,
		"each catalogue product enters the client ledger once, including all season SKUs")
	expect(premium.entitlements.size() == entitlements.size() and estate.cards.has(Config.STARTER_CARD)
		and game.campaign.ledger.cosmetics.has(Config.STARTER_DECOR), "verified starter items and non-consumables restore")
	game.economy.storage.read_only = true
	var previous := estate.amount("diamond")
	var new_grant := {"account": account, "entitlements": entitlements,
		"grants": [{"id": "read-only-grant".sha256_text(), "product": "gems_100"}]}
	expect(not game.purchases.apply_verified(new_grant) and estate.amount("diamond").compare(previous) == 0,
		"incompatible save never consumes a local grant")
	game.economy.storage.read_only = false

func check_final_season_grace() -> void:
	var last := Config.season_profile(Config.SEASONS.size() - 1)
	game.economy.clock = last.end + 1
	expect(game.operations.premium.selected_pass().get("sku") == last.sku and not game.purchases.eligible(last.sku),
		"final season claims stay accessible during grace while checkout closes")
	game.economy.clock = last.claim_end
	expect(game.operations.premium.selected_pass().is_empty(), "expired final season closes claims")
