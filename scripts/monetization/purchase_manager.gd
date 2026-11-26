extends Node

signal changed
signal delivered(id: String)

const Catalog = preload("res://data/monetization/config.gd")
const Native := "HighwayRewarded"

var game: Node3D
var bridge: Object
var catalogue: Dictionary
var status := "store_local"
var checkout := false
var waiting_identity := false
var queried := false
var client := HTTPRequest.new()
var request_kind := ""
var nonce := ""
var queued := {}
var verifying := ""
var retry_at := 0
var next_sync := 0

func bind(host: Node3D) -> void:
	game = host
	client.timeout = 22.0
	client.body_size_limit = 512_000
	client.max_redirects = 0
	add_child(client)
	client.request_completed.connect(response)
	if not Engine.has_singleton(Native):
		return
	bridge = Engine.get_singleton(Native)
	bridge.connect("billing_catalog", on_catalog)
	bridge.connect("billing_state", on_billing_state)
	bridge.connect("billing_purchases", on_purchases)
	bridge.connect("identity_result", on_identity)
	status = "store_connect" if configured() else "store_local"

func configured() -> bool:
	return is_instance_valid(bridge) and bridge.billingConfigured()

func verified_checkout() -> bool:
	return configured() and bridge.identityConfigured() and str(bridge.purchaseEndpoint()).begins_with("https://")

func privacy_url() -> String:
	if not is_instance_valid(bridge) or not bridge.has_method("privacyPolicyUrl"):
		return ""
	var url: String = bridge.privacyPolicyUrl()
	return url if url.begins_with("https://") else ""

func busy() -> bool:
	return waiting_identity or checkout or not request_kind.is_empty()

func open() -> void:
	if not configured():
		return
	if not queried:
		var product_ids := PackedStringArray(Catalog.PRODUCTS.keys())
		for season in Catalog.SEASONS:
			product_ids.append(season.sku)
		queried = true
		status = "store_connect"
		bridge.startBilling(",".join(product_ids))

func state() -> HbtPremiumState:
	return game.campaign.premium

func restore_purchases() -> void:
	if not verified_checkout() or busy() or game.ads.busy() or game.economy.storage.read_only:
		return
	open()
	if state().play_session.is_empty():
		send("challenge", {}, false)
	else:
		bridge.restoreBilling()
		send("sync", {"install": state().install_id})

func buy(id: String) -> void:
	if game.economy.storage.read_only or not verified_checkout() or busy() or game.ads.busy() or not catalogue.has(id) or state().entitlements.has(id) or not eligible(id):
		return
	if state().play_session.is_empty():
		restore_purchases()
		return
	if bridge.launchBilling(id, state().play_account):
		checkout = true
		state().quiet(game.economy.clock)
		track("purchase_started", id)
		update("store_checkout")

func eligible(id: String) -> bool:
	var product := Catalog.product(id)
	if product.is_empty():
		return false
	if product.section == "season":
		return Catalog.season_at(game.economy.clock).get("sku") == id
	var gate := str(product.get("gate", ""))
	if gate.is_empty():
		return not product.has("district") or game.campaign.districts.has(product.district)
	for estate: HbtEconomy in game.campaign.districts.values():
		if estate.level(gate) > 0:
			return true
	return false

func on_catalog(data: String) -> void:
	catalogue = HbtEconomy.safe_dict(JSON.parse_string(data))
	update("store_catalog" if not catalogue.is_empty() else "store_no_catalog")

func on_billing_state(source: String, code: int) -> void:
	if source == "purchase":
		checkout = false
		if code == 1:
			track("purchase_cancelled", "")
			update("store_cancel")
		elif code == 7:
			update("store_restore")
		elif code != 0:
			update("store_network")
	elif source in ["connect", "disconnect"] and code != 0:
		queried = false
		catalogue.clear()
		update("store_network")

func on_purchases(raw: String) -> void:
	var incoming: Variant = JSON.parse_string(raw)
	if not incoming is Array:
		return
	for purchase in incoming:
		if not purchase is Dictionary or Catalog.product(str(purchase.get("product", ""))).is_empty():
			continue
		if purchase.get("state") == 2:
			update("store_pending")
		elif purchase.get("state") == 1 and purchase.get("token") is String:
			queued[purchase.token] = purchase.product
	process_queue()

func on_identity(token: String) -> void:
	if not waiting_identity:
		return
	waiting_identity = false
	if token.is_empty():
		update("store_cancel")
	else:
		send("session", {"id_token": token, "nonce": nonce}, false)
	nonce = ""

func send(kind: String, body: Dictionary, authenticated := true) -> void:
	if not verified_checkout() or not request_kind.is_empty():
		return
	var headers := PackedStringArray(["Content-Type: application/json"])
	if authenticated:
		headers.append("Authorization: Bearer " + state().play_session)
	request_kind = kind
	var address: String = bridge.purchaseEndpoint()
	var error := client.request(address.trim_suffix("/") + "/v1/" + kind,
		headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if error != OK:
		request_kind = ""
		retry_at = game.economy.clock + 30
		update("store_network")

func response(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var kind := request_kind
	request_kind = ""
	var values := HbtEconomy.safe_dict(JSON.parse_string(body.get_string_from_utf8()))
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		var reason := str(values.get("error", ""))
		if code == 401:
			state().play_session = ""
			state().play_account = ""
		var terminal := kind == "receipt" and (code in [400, 410] or (code == 422 \
			and reason in ["invalid_product", "invalid_quantity", "test_purchase"]) or (code == 409 \
			and reason in ["account_mismatch", "already_owned", "consumed_without_grant"]))
		if terminal:
			queued.erase(verifying)
			verifying = ""
		elif kind == "receipt" and queued.has(verifying):
			# A delayed Publisher response must not pin the first token at the head of the queue.
			var product: String = queued[verifying]
			queued.erase(verifying)
			queued[verifying] = product
		retry_at = game.economy.clock if terminal else game.economy.clock + 30
		update("store_pending" if reason == "pending" else "store_account_issue" if code in [401, 409] else "store_network")
		if terminal:
			process_queue()
		return
	match kind:
		"challenge":
			nonce = str(values.get("nonce", ""))
			waiting_identity = nonce.length() == 64 and bridge.signIn(nonce)
			update("store_signing" if waiting_identity else "store_network")
		"session":
			var session := str(values.get("session", ""))
			var account := str(values.get("account", ""))
			if session.length() != 43 or account.length() != 64:
				update("store_network")
				return
			state().play_session = session
			state().play_account = account
			bridge.restoreBilling()
			send("sync", {"install": state().install_id})
		"sync", "receipt":
			if not apply_verified(values):
				retry_at = game.economy.clock + 30
				update("store_network")
				return
			if kind == "receipt":
				queued.erase(verifying)
				verifying = ""
			next_sync = game.economy.clock + 600
			update("store_synced")
			process_queue()

func apply_verified(payload: Dictionary) -> bool:
	var p := state()
	if p.play_account.length() != 64 or payload.get("account") != p.play_account 			or not payload.get("entitlements") is Array or not payload.get("grants") is Array:
		return false
	var products := {}
	for id in payload.entitlements:
		var spec := Catalog.product(str(id))
		if spec.get("kind") == "entitlement":
			products[id] = true
	var paid: Array[String] = []
	var world: HbtCampaign = game.campaign
	var receipt_format := RegEx.create_from_string("^[a-f0-9]{64}$")
	var accepted := p.apply(world, func() -> bool:
		var previous := p.entitlements
		p.entitlements = products
		p.account = p.play_account
		if products.has("starter_pack"):
			p.grant_items(world, game.economy, {"card": Catalog.STARTER_CARD, "decor": Catalog.STARTER_DECOR})
		elif previous.has("starter_pack"):
			game.economy.cards.erase(Catalog.STARTER_CARD)
			game.economy.equipped.erase(Catalog.STARTER_CARD)
			world.ledger.cosmetics.erase(Catalog.STARTER_DECOR)
			for region in world.ledger.chosen:
				if world.ledger.chosen[region].get("decor") == Catalog.STARTER_DECOR:
					world.ledger.chosen[region].erase("decor")
		for transaction in payload.grants:
			if not transaction is Dictionary:
				continue
			var id := str(transaction.get("product", ""))
			var hash_id := str(transaction.get("id", ""))
			if receipt_format.search(hash_id) == null or p.grants.has(hash_id) or Catalog.product(id).is_empty():
				continue
			if Catalog.product(id).kind == "entitlement" and not p.entitlements.has(id):
				continue
			p.grants[hash_id] = true
			p.grant_items(world, game.economy, Catalog.product(id).item)
			p.quiet(game.economy.clock)
			track("purchase_completed", id)
			if id.ends_with("_pack"):
				track("special_offer_redeemed", id)
			paid.append(id)
		return true)
	if accepted:
		for id in paid:
			delivered.emit(id)
	return accepted

func process_queue() -> void:
	if busy() or queued.is_empty() or state().play_session.is_empty() or game.economy.clock < retry_at:
		return
	verifying = str(queued.keys().front())
	send("receipt", {"token": verifying, "product": queued[verifying], "install": state().install_id})

func tick() -> void:
	if not configured() or busy():
		return
	if not queued.is_empty():
		process_queue()
	elif not state().play_session.is_empty() and game.economy.clock >= maxi(next_sync, retry_at):
		send("sync", {"install": state().install_id})

func resume() -> void:
	if configured() and queried and not waiting_identity:
		bridge.restoreBilling()

func track(key: String, product: String) -> void:
	state().record(key, game.economy.clock, product)

func update(key: String) -> void:
	status = key
	changed.emit()
