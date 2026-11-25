extends Node3D

const Routes = preload("res://data/economy/routes.gd")
const Actor = preload("res://scripts/customers/customer_manager.gd")
const MANAGER_SPOTS := {
	"ada": Vector3(-5.58, 0.28, -2.06), "iga": Vector3(-15.12, 0.29, -6.43),
	"maks": Vector3(8.34, 0.25, -13.92), "mira": Vector3(15.24, 0, 0.76),
	"leon": Vector3(-7.31, 0.30, -14.42),
}

var staff: Dictionary = {}
var directors: Dictionary = {}
var manual: Dictionary = {}
var market_visitors: Dictionary = {}

func roster(economy: HbtEconomy) -> void:
	for id in economy.facilities:
		if not staff.has(id):
			staff[id] = []
		for index in range(staff[id].size(), economy.crew[id].size()):
			var profile: HbtService = economy.facilities[id]
			staff[id].append(person(profile.role, standby(id, index)))
	for id in MANAGER_SPOTS:
		if id in economy.equipped and not directors.has(id):
			directors[id] = person(id, MANAGER_SPOTS[id])
			directors[id].play("service")
		elif id not in economy.equipped and directors.has(id):
			directors[id].queue_free()
			directors.erase(id)

func update(economy: HbtEconomy, dispatch: HbtDispatch, delta: float) -> void:
	var jobs := {}
	for visit: HbtVisit in dispatch.live.values():
		if visit.service == "market" and visit.phase in [HbtVisit.Phase.READY, HbtVisit.Phase.WORKING] and not market_visitors.has(visit.number):
			market_visitors[visit.number] = market_walk(visit)
		if visit.phase != HbtVisit.Phase.WORKING:
			continue
		if visit.worker >= 0:
			jobs[identity(visit.service, visit.worker)] = visit
		elif visit.service != "fuel" or visit.bay != 0:
			if not manual.has(visit.number):
				var profile: HbtService = economy.facilities[visit.service]
				var actor := person(profile.role, Routes.worker_at(visit.service, visit.bay))
				orient(actor, visit)
				actor.play(profile.task)
				manual[visit.number] = actor
	for id in manual.keys():
		var ticket: HbtVisit = dispatch.live.get(id)
		if ticket == null or ticket.phase != HbtVisit.Phase.WORKING:
			manual[id].queue_free()
			manual.erase(id)
	for number in market_visitors.keys():
		var ticket: HbtVisit = dispatch.live.get(number)
		if ticket == null or ticket.phase not in [HbtVisit.Phase.READY, HbtVisit.Phase.WORKING]:
			var shopper: Actor = market_visitors[number]
			var bay := 0 if ticket == null or ticket.bay < 0 else ticket.bay
			var walk: Array[Vector3] = [shopper.position, Vector3(-6.19, 0.06, -1.26),
				Routes.position_of("market", bay) + Vector3(0.69, 0, -0.53)]
			shopper.arrived.connect(shopper.queue_free, CONNECT_ONE_SHOT)
			shopper.configure_walk(walk, "walk", 2.0, false)
			market_visitors.erase(number)
	for id in staff:
		for index in range(staff[id].size()):
			var actor: Actor = staff[id][index]
			var job: HbtVisit = jobs.get(identity(id, index))
			var target := standby(id, index) if job == null else Routes.worker_at(id, job.bay)
			var offset := target - actor.position
			if offset.length_squared() > 0.002:
				actor.position = actor.position.move_toward(target, delta * 2.32)
				actor.rotation.y = lerp_angle(actor.rotation.y, atan2(offset.x, offset.z), minf(delta * 12.0, 1.0))
				if job != null and offset.length() < 0.33:
					orient(actor, job)
					actor.play(economy.facilities[id].task)
				else:
					actor.play("walk")
			elif job != null:
				orient(actor, job)
				actor.play(economy.facilities[id].task)
			else:
				actor.play("idle")

func performer(visit: HbtVisit) -> Node3D:
	return staff[visit.service][visit.worker] if visit.worker >= 0 else manual.get(visit.number)

func market_walk(visit: HbtVisit) -> Actor:
	var start := visit.location + Vector3(0.69, 0, -0.53)
	var shopper := person("customer", start)
	var walk: Array[Vector3] = [start, Vector3(start.x, 0.06, -1.26), Vector3(-6.19, 0.06, -1.26),
		Vector3(-6.07, 0.25, -2.19)]
	shopper.configure_walk(walk, "walk", 1.75, false)
	return shopper

func person(role: String, at: Vector3) -> Actor:
	var figure := Actor.new()
	figure.role = role
	figure.position = at
	add_child(figure)
	return figure

func identity(id: String, index: int) -> String:
	return "%s:%d" % [id, index]

func standby(id: String, index: int) -> Vector3:
	return Routes.worker_at(id, index) + Vector3(0.63, 0, -0.76)

func orient(actor: Actor, job: HbtVisit) -> void:
	var relative := job.location - actor.position
	actor.rotation.y = 0.18 if job.service == "market" else atan2(relative.x, relative.z)
