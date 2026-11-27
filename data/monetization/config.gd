extends RefCounted

const STEP_SECONDS := 300
const CAP_SECONDS := 1800
const INCOME_MULTIPLIER := 2
const AD_WAIT_MSEC := 12_000
const DAY := 86_400
const PLAY_BEFORE_BREAK := 900
const BREAK_INTERVAL := 480
const BREAK_WINDOW := 3600
const BREAK_LIMIT := 4
const COMMERCIAL_QUIET := 120
const WORLD_FIRST := 300
const WORLD_INTERVAL := Vector2i(395, 595)
const CASH_QUOTE_SECONDS := 180

# Cooldown, daily units, reward amount. Unitless offers resolve their disclosed target.
const OFFERS := {
	"offline": [90, 8, 0],
	"cash": [600, 4, 120],
	"upgrade": [1200, 3, 1],
	"daily": [0, 1, 4],
	"mission": [600, 2, 125],
	"event": [1800, 1, 3],
	"gift": [1800, 5, 5],
	"training": [900, 3, 1],
	"delivery": [1200, 3, 1],
	"manager": [0, 1, 0],
	"vip": [900, 4, 1],
	"arrival": [0, 12, 0],
	"freight_rush": [600, 3, 0], "driver_rush": [600, 3, 0],
	"practice_bonus": [600, 3, 0], "freight_tip": [600, 3, 0], "yard_gift": [0, 1, 0],
}
const AD_MANAGER := "reese"
const STARTER_CARD := "sana"
const STARTER_DECOR := "gold_gate"
const SEASON_CARD := "rhea"

# The suggested price in grosz is for Play Console only.
const PRODUCTS := {
	"starter_pack": {"price_pln": 999, "kind": "entitlement", "section": "special", "item": {"diamond": 200, "cash": 2400, "card": "sana", "decor": "gold_gate", "voucher": 3}},
	"remove_ads": {"price_pln": 2499, "kind": "entitlement", "section": "special", "item": {}},
	"gems_100": {"price_pln": 499, "kind": "consumable", "section": "gems", "item": {"diamond": 100}},
	"gems_550": {"price_pln": 1999, "kind": "consumable", "section": "gems", "item": {"diamond": 550}},
	"gems_1200": {"price_pln": 3999, "kind": "consumable", "section": "gems", "item": {"diamond": 1200}},
	"gems_2500": {"price_pln": 7999, "kind": "consumable", "section": "gems", "item": {"diamond": 2500}},
	"gems_6500": {"price_pln": 19999, "kind": "consumable", "section": "gems", "item": {"diamond": 6500}},
	"manager_pack": {"price_pln": 2999, "kind": "entitlement", "section": "directors", "item": {"diamond": 250, "card": "reese", "voucher": 4}},
	"builder_pack": {"price_pln": 3999, "kind": "entitlement", "section": "business", "item": {"diamond": 420, "cash": 7800, "voucher": 6}},
	"workshop_pack": {"price_pln": 1499, "kind": "entitlement", "section": "business", "gate": "workshop", "item": {"diamond": 120, "cash": 3200, "voucher": 4}},
	"wash_pack": {"price_pln": 1499, "kind": "entitlement", "section": "business", "gate": "wash", "item": {"diamond": 140, "cash": 2800, "voucher": 3}},
	"freight_pack": {"price_pln": 1999, "kind": "entitlement", "section": "business", "gate": "truck", "item": {"diamond": 200, "cash": 6400, "voucher": 4}},
	"coast_pack": {"price_pln": 2499, "kind": "entitlement", "section": "business", "district": "ocean", "item": {"diamond": 260, "cash": 9000, "voucher": 5}},
}

const SEASON_EPOCH := 1795392000 # 2026-11-23 00:00 UTC
const SEASON_SPAN := 14 * DAY
const SEASON_CLAIM_GRACE := 7 * DAY
const SEASON_TIERS := 30
const XP_PER_TIER := 70
const SEASONS := [
	{"id": "snow", "sku": "season_pass_2026_snow", "tint": "#507f99", "task": "repairs", "goal": 15},
	{"id": "holiday", "sku": "season_pass_2026_holiday", "tint": "#b05c5e", "task": "food", "goal": 24},
	{"id": "sport", "sku": "season_pass_2026_sport", "tint": "#ac643f", "task": "sports", "goal": 18},
	{"id": "truck", "sku": "season_pass_2027_truck", "tint": "#997349", "task": "trucks", "goal": 18},
	{"id": "summer", "sku": "season_pass_2027_summer", "tint": "#388a8a", "task": "stay", "goal": 20},
	{"id": "green", "sku": "season_pass_2027_green", "tint": "#60835b", "task": "charged", "goal": 20},
]

static func product(id: String) -> Dictionary:
	if PRODUCTS.has(id):
		return PRODUCTS[id]
	for season in SEASONS:
		if id == season.sku:
			return {"price_pln": 2499, "kind": "entitlement", "section": "season", "item": {}}
	return {}

static func season_at(wall: int) -> Dictionary:
	if wall < SEASON_EPOCH:
		return {}
	var offset := floori((wall - SEASON_EPOCH) / float(SEASON_SPAN))
	if offset >= SEASONS.size():
		return {}
	return season_profile(offset)

static func season_profile(index: int) -> Dictionary:
	var data: Dictionary = SEASONS[index].duplicate()
	data["start"] = SEASON_EPOCH + index * SEASON_SPAN
	data["end"] = data.start + SEASON_SPAN
	data["claim_end"] = data.end + SEASON_CLAIM_GRACE
	return data

static func pass_reward(tier: int, premium: bool, theme: String) -> Dictionary:
	if tier <= 0 or tier > SEASON_TIERS:
		return {}
	if tier == 30:
		return {"decor": theme, "card": SEASON_CARD, "diamond": 100} if premium else {"decor": theme, "diamond": 18}
	if tier % 5 == 0:
		return {"voucher": (2 if premium else 1), "diamond": (15 if premium else 4)}
	if tier % 3 == 0:
		return {"diamond": (8 if premium else 2)}
	return {"cash": (230 + tier * 70) * (3 if premium else 1)}
