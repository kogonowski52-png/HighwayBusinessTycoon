extends Node3D

const Catalog = preload("res://data/estate/spotlight.gd")
const Art = preload("res://scripts/art/visual_library.gd")

var game: Node3D
var visit: HbtVisit
var sign: Label3D

func bind(owner: Node3D) -> void:
	game = owner
	set_process(false)

func tick() -> void:
	var store: HbtEconomy = game.economy
	if not game.traffic.dispatch.spawning or store.customers < 20 or store.tutorial_step < store.TUTORIAL_DONE:
		return
	var schedule: RefCounted = store.works
	if schedule.next_spotlight <= 0:
		schedule.next_spotlight = store.clock + 150
		store.dirty = true
		return
	if visit != null or store.clock < schedule.next_spotlight:
		return
	if start_round(schedule.spotlight_cursor):
		schedule.next_spotlight = store.clock + 420 + posmod(store.clock, 130)
		schedule.spotlight_cursor += 1
	else:
		schedule.next_spotlight = store.clock + 11
	store.dirty = true

func start_round(offset: int) -> bool:
	if visit != null:
		return false
	for n in Catalog.MOMENTS.size():
		var item: Dictionary = Catalog.MOMENTS[posmod(offset + n, Catalog.MOMENTS.size())]
		for target: String in item.services:
			if game.economy.level(target) <= 0:
				continue
			var activity: HbtVisit = game.traffic.dispatch.try_admit(item.guest, target, item.model)
			if activity == null:
				continue
			show_arrival(activity, item)
			return true
	return false

func show_arrival(ticket: HbtVisit, item: Dictionary) -> void:
	visit = ticket
	visit.spotlight = item
	sign = Art.sign(self, ticket.location + Vector3.UP * 2.36, game.t("spotlight_" + str(item.id)), .32, Color(item.color))
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.outline_size = 7
	sign.outline_modulate = Color("#2a3839")
	set_process(true)

func _process(_delta: float) -> void:
	if visit != null and game.traffic.dispatch.live.has(visit.number):
		sign.position = visit.location + Vector3.UP * 2.44
		sign.visible = game.traffic.visual_area.sees(visit.location, 4.0)
	else:
		if is_instance_valid(sign):
			sign.queue_free()
		sign = null
		visit = null
		set_process(false)

func arrived(ticket: HbtVisit) -> void:
	if ticket.spotlight.is_empty():
		return
	var prize := ticket.base_invoice.times(int(ticket.spotlight.reward))
	var estate: HbtEconomy = game.economy
	estate.credit("cash", prize)
	estate.credit("reputation", HbtAmount.from(2))
	estate.dirty = true
	estate.checkpoint()
	game.hud.announce(game.t("spotlight_finished") % game.money(prize), game.hud.CASH, game.motion_enabled())
	if game.motion_enabled():
		game.effects.confetti(ticket.location, Color(ticket.spotlight.color), 8)
