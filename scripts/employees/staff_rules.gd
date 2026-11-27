extends RefCounted

const MAX_TRAINING := 10
const MAX_RANK := 3
const BPS := 10_000
const SPECIALTIES := ["speed", "quality", "mentor"]

static func recruit_cost(service: HbtService, employment_count: int, level: int) -> HbtAmount:
	return HbtAmount.from(service.wage).times(100 + employment_count * 58 + maxi(0, level - 4) * 3).divided(100)

static func training_cost(service: HbtService, employee: Dictionary) -> HbtAmount:
	return HbtAmount.from(service.wage).times(70 + int(employee.training) * 46 + (int(employee.rank) - 1) * 65) \
		.times(78 if employee.get("specialty", "") == "mentor" else 100).divided(10_000)

static func promotion_cost(service: HbtService, employee: Dictionary) -> HbtAmount:
	return HbtAmount.from(service.wage).times(2 + int(employee.rank) * 2)

static func promotion_ready(employee: Dictionary) -> bool:
	var rank := int(employee.rank)
	return rank < MAX_RANK and int(employee.xp) >= rank * 12 and int(employee.training) >= rank * 2

static func speed(employee: Dictionary) -> int:
	return BPS + int(employee.training) * 660 + int(employee.rank) * 1_050 + mini(int(employee.xp), 100) * 19 + (850 if employee.get("specialty", "") == "speed" else 0)

static func efficiency(employee: Dictionary) -> int:
	return BPS + int(employee.training) * 290 + (int(employee.rank) - 1) * 760 + (780 if employee.get("specialty", "") == "quality" else 0)

static func sanitize(rule: Dictionary) -> Dictionary:
	var record := {
		"xp": clampi(int(rule.get("xp", 0)), 0, 1_000_000),
		"training": clampi(int(rule.get("training", 0)), 0, MAX_TRAINING),
		"rank": clampi(int(rule.get("rank", 1)), 1, MAX_RANK),
	}
	if rule.get("specialty", "") in SPECIALTIES:
		record["specialty"] = rule.specialty
	return record

static func preparation_seconds(employee: Dictionary) -> float:
	return [0.82, 0.49, 0.26][int(employee.rank) - 1]
