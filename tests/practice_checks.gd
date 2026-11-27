extends "res://tests/run_checks.gd"

const Rules = preload("res://scripts/challenges/service_practice.gd")
const AT := 1_804_980_000
var path := "/tmp/hbt-practice-%d.cfg" % OS.get_process_id()

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var store := HbtEconomy.new()
	store.storage.path = path
	store.restore(AT)
	var paused := Rules.new()
	paused.begin("fuel", "fuel")
	expect(not paused.mark_pressure() and paused.award(store).empty(), "an unstarted run cannot pay")
	var pump := Rules.new()
	pump.begin("fuel", "fuel")
	pump.started = true
	for i in Rules.BANDS.size():
		expect(not pump.mark_pressure(), "a measurement requires the minimum interval")
		while not pump.fuel_ready() or absf(pump.needle() - Rules.BANDS[i]) > .025:
			pump.advance(.02)
			if pump.elapsed >= pump.last():
				break
		expect(pump.mark_pressure(), "lock a valid reading")
	expect(pump.complete() and pump.score() >= 90, "hit four green targets")
	var wallet := store.amount("cash")
	var reward := pump.award(store)
	expect(not reward.empty() and store.amount("cash").compare(wallet.plus(reward)) == 0 and pump.award(store).empty(),
		"one completed challenge pays once")
	var restored := HbtEconomy.new()
	restored.storage.path = path
	restored.restore(AT)
	expect(Rules.wait(restored, "fuel") == Rules.REST and restored.practice_state.fuel.count == 1, "score, reward and cooldown survive an actual save")
	var wash := Rules.new()
	wash.begin("wash", "wash")
	wash.started = true
	for y in 4:
		for x in 3:
			wash.scrub(Vector2((x+.5)/3.0, (y+.5)/4.0), 2.0)
	expect(wash.score() == 100 and not wash.complete(), "washing all twelve zones still respects the time limit")
	wash.advance(16)
	expect(wash.complete() and Rules.mode(store, "wash").is_empty(), "locked business cannot pay a mini-game")
	var loader := Rules.new()
	loader.begin("cargo", "terminal")
	loader.started = true
	expect(not loader.pack(Vector2i(3,5)), "load cannot overhang the deck")
	expect(loader.pack(Vector2i(0,0)) and not loader.pack(Vector2i(0,0)), "cargo cannot overlap a loaded cell")
	loader.rotation = 1
	expect(loader.pack(Vector2i(2,0)), "rotated three-pallet row fits")
	for at: Vector2i in [Vector2i(2,3),Vector2i(0,2),Vector2i(1,5),Vector2i(0,4)]:
		expect(loader.pack(at), "load a real piece")
	loader.advance(18.0)
	expect(loader.complete() and loader.score() >= 90 and loader.piece_count() == 6, "full cargo bay records score based on placements")
	clean_save(path)
	result("Precision refueling, wash and cargo practice")
