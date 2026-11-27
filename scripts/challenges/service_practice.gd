extends RefCounted

const MODES := ["fuel", "wash", "cargo"]
const SECONDS := {"fuel": 29.0, "wash": 27.0, "cargo": 39.0}
const REST := 420
const LOAD := [
	[Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0)],
	[Vector2i(0,0), Vector2i(0,1), Vector2i(1,1)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0)],
	[Vector2i(0,0), Vector2i(1,0)],
]
const BANDS := [.44, .67, .32, .56]
const WIDTHS := [.16, .14, .12, .10]

var practice := ""
var site := ""
var started := false
var done := false
var elapsed := 0.0
var round_start := 0.0
var attempts: Array[float] = []
var dirty := PackedFloat32Array()
var loaded := {}
var rotation := 0

static func mode(estate: HbtEconomy, id: String) -> String:
	if estate.level(id) <= 0:
		return ""
	var service: HbtService = estate.facilities[id]
	if id == "fuel" or service.venue_kind == "refuel":
		return "fuel"
	if id in ["wash", "truck_wash", "detail"] or service.venue_kind == "wash":
		return "wash"
	if id in ["logistics", "warehouse", "terminal", "coldstore", "transfer", "logging", "haulage", "distribution"] 		or service.venue_kind in ["freight", "cold"]:
		return "cargo"
	return ""

static func wait(estate: HbtEconomy, kind: String) -> int:
	return maxi(0, int(estate.practice_state.get(kind, {}).get("ready", 0)) - estate.clock)

func begin(kind: String, target: String) -> void:
	practice = kind
	site = target
	dirty.resize(12)
	dirty.fill(1.0)

func last() -> float:
	return float(SECONDS[practice])

func advance(delta: float) -> void:
	if started and not done:
		elapsed = minf(elapsed + delta, last())

func needle() -> float:
	var frequency := 0.66 + 0.105 * attempts.size()
	return pingpong(elapsed * frequency + .13, 1.0)

func fuel_ready() -> bool:
	return practice == "fuel" and started and not done and elapsed < last() 		and attempts.size() < BANDS.size() and elapsed >= round_start + 3.3

func mark_pressure() -> bool:
	if not fuel_ready():
		return false
	var index := attempts.size()
	var distance := absf(needle() - float(BANDS[index]))
	attempts.append(clampf(1.0 - distance / (float(WIDTHS[index]) * 2.10), 0.0, 1.0))
	round_start = elapsed
	return true

func scrub(coords: Vector2, strength: float) -> void:
	if practice != "wash" or not started or done or elapsed >= last():
		return
	for y in 4:
		for x in 3:
			var center := Vector2((x + .5) / 3.0, (y + .5) / 4.0)
			var distance := Vector2((coords.x - center.x) * 1.20, coords.y - center.y).length()
			if distance < .24:
				var i := y * 3 + x
				dirty[i] = maxf(0.0, dirty[i] - strength * (1.0 - distance / .24))

func piece() -> Array[Vector2i]:
	var placed := piece_count()
	var shape: Array[Vector2i] = []
	if placed >= LOAD.size():
		return shape
	for cell: Vector2i in LOAD[placed]:
		for step in rotation:
			cell = Vector2i(-cell.y, cell.x)
		shape.append(cell)
	var origin := shape.reduce(func(previous: Vector2i, cell: Vector2i) -> Vector2i: return Vector2i(mini(previous.x, cell.x), mini(previous.y, cell.y)), Vector2i(4, 6)) as Vector2i
	for i in shape.size():
		shape[i] -= origin
	return shape

func piece_count() -> int:
	if loaded.is_empty():
		return 0
	return int(loaded.values().max()) + 1

func fits(at: Vector2i) -> bool:
	for cell in piece():
		var point := cell + at
		if point.x < 0 or point.y < 0 or point.x >= 4 or point.y >= 6 or loaded.has(point):
			return false
	return true

func pack(at: Vector2i) -> bool:
	var shape := piece()
	if practice != "cargo" or not started or done or elapsed >= last() or shape.is_empty() or not fits(at):
		return false
	var batch := piece_count()
	for cell in shape:
		loaded[cell + at] = batch
	rotation = 0
	return true

func score() -> int:
	match practice:
		"fuel":
			return roundi(attempts.reduce(func(total: float, shot: float) -> float: return total + shot, 0.0) * 25.0)
		"wash":
			var dirt := 0.0
			for stain: float in dirty:
				dirt += stain
			return clampi(roundi(100.0 - dirt * 100.0 / dirty.size()), 0, 100)
		"cargo":
			var count := piece_count()
			var area := 0
			for cell: Vector2i in loaded:
				area = maxi(area, cell.y + 1)
			var order := minf(1.0, loaded.size() / (4.0 * maxi(1, area)))
			return clampi(roundi(count * 14.0 + count * (16.0 / LOAD.size()) * order), 0, 100)
	return 0

func complete() -> bool:
	return elapsed >= last() or (practice == "fuel" and attempts.size() == BANDS.size()) 		or (practice == "wash" and elapsed >= 15.0 and score() == 100) 		or (practice == "cargo" and elapsed >= 15.0 and piece_count() == LOAD.size())

func award(estate: HbtEconomy) -> HbtAmount:
	if done or not started or not complete():
		return HbtAmount.new()
	done = true
	var points := score()
	if points < 35 or wait(estate, practice) > 0 or mode(estate, site) != practice or estate.storage.read_only:
		return HbtAmount.new()
	var previous := estate.practice_state.duplicate(true)
	var wallet := estate.amount("cash")
	var standing := estate.amount("reputation")
	var record: Dictionary = estate.practice_state.get(practice, {})
	var amount := estate.price(site).times(130 + points * 4).divided(100).plus(HbtAmount.from(points / 3))
	estate.credit("cash", amount)
	estate.credit("reputation", HbtAmount.from(1 + points / 40))
	estate.practice_state[practice] = {
		"ready": estate.clock + REST, "best": maxi(points, int(record.get("best", 0))),
		"count": int(record.get("count", 0)) + 1, "last": amount.decimal(), "claimed_bonus": false,
	}
	if estate.checkpoint() != OK:
		estate.wallet.cash = wallet
		estate.wallet.reputation = standing
		estate.practice_state = previous
		return HbtAmount.new()
	estate.touch()
	return amount
