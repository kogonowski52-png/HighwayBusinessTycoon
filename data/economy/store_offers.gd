extends RefCounted

# Local offers use the same kind and currency fields that a billing catalog can
# provide later. The shipped catalog contains earned currencies exclusively.
const OFFERS := [
	{"key": "voucher", "title": "offer_voucher", "currency": "voucher", "action": "redeem_voucher"},
	{"key": "boost", "title": "offer_boost", "currency": "diamond", "action": "buy_boost"},
	{"key": "event_diamond", "title": "offer_diamonds", "currency": "event", "action": "exchange_points"},
	{"key": "event_card", "title": "offer_manager", "currency": "event", "action": "exchange_points"},
]
