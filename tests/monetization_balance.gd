extends "res://tests/campaign_balance.gd"
## Compare four simulated choices using the same route seed and ordinary progression.
## No store, SDK, external account, IAP or network is invoked from this fixture.

const Config = preload("res://data/monetization/config.gd")
const POLICIES := ["none", "occasional", "regular", "packs"]
const CHECKPOINTS := [3600, 86400, 604800, 2592000]
var policy := ""
var videos := 0
var next_video := 0
var purchases_applied := 0

func run() -> void:
	for selection in POLICIES:
		policy = selection
		simulate(612)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--report="):
			var file := FileAccess.open(argument.trim_prefix("--report="), FileAccess.WRITE)
			expect(file != null, "write comparison")
			if file != null:
				file.store_string(JSON.stringify(table, "\t") + "\n")
				file.close()
	result("Four monetization balance scenarios")

func simulate(seed: int) -> void:
	run_seed = seed
	seconds = 0
	first_sale = -1
	first_upgrade = -1
	offline = HbtAmount.new()
	recovered = 0
	departed = 0
	patience_left = 0
	cadence = 0
	return_cursor = 0
	openings = {"north": 0}
	opened_at = {"fuel": 0}
	last_sale = {}
	cash_from_absence = {}
	recovery_counts = {}
	videos = 0
	next_video = WALL + 180
	purchases_applied = 0
	economy = HbtEconomy.new()
	save_path = "/tmp/hbt-monetization-balance-%s-%s.cfg" % [OS.get_process_id(), policy]
	economy.storage.path = save_path
	campaign = HbtCampaign.new(economy)
	campaign.restore(WALL)
	begin_session(true)
	var previous := HbtAmount.new()
	for horizon in CHECKPOINTS:
		if horizon == CHECKPOINTS.front():
			active_until(horizon)
		else:
			check_in_until(horizon)
		var evidence := campaign_evidence(horizon)
		evidence.policy = policy
		evidence.completed_ads = videos
		evidence.packs = purchases_applied
		table.append(evidence)
		var gross := HbtAmount.from(evidence.gross)
		expect(gross.compare(previous) > 0 and traffic.consistent(), "%s continues growing without invalid reservations" % policy)
		if horizon == CHECKPOINTS.back():
			expect(evidence.districts == 6 and evidence.sites == total_businesses(), "%s reaches every region and business" % policy)
		previous = gross
		print("Monetization " + JSON.stringify(evidence))
	clean_save(save_path)

func invest() -> void:
	if policy in ["occasional", "regular"] and economy.clock >= next_video and campaign.boost.can_extend(economy.clock):
		if campaign.boost.extend_confirmed(economy.clock):
			videos += 1
			next_video = economy.clock + (366 if policy == "regular" else 1800)
	if policy == "packs":
		if purchases_applied == 0 and seconds >= 110:
			campaign.premium.grant_items(campaign, economy, Config.PRODUCTS.starter_pack.item)
			purchases_applied += 1
		if purchases_applied == 1 and seconds >= 1650:
			campaign.premium.grant_items(campaign, economy, Config.PRODUCTS.builder_pack.item)
			campaign.premium.grant_items(campaign, economy, Config.PRODUCTS.gems_550.item)
			purchases_applied += 2
		economy.redeem_voucher()
	super.invest()
