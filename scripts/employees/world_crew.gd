extends Node3D

const Routes = preload("res://data/economy/routes.gd")
const RegionalRoutes = preload("res://data/world/regional_routes.gd")
const Actor = preload("res://scripts/customers/customer_manager.gd")
const Managers = preload("res://data/economy/managers.gd")
const MANAGER_SPOTS := {
	"ada": Vector3(-5.58, 0.28, -2.06), "iga": Vector3(-15.12, 0.29, -6.43),
	"maks": Vector3(8.34, 0.25, -13.92), "mira": Vector3(15.24, 0, 0.76),
	"leon": Vector3(-7.31, 0.30, -14.42), "vera": Vector3(-8.17, 0.30, -14.45),
}

var routes: Object = Routes
var staff: Dictionary = {}
var directors: Dictionary = {}
var manual: Dictionary = {}
var visitors: Dictionary = {}

func roster(economy: HbtEconomy) -> void:
	for id in economy.facilities:
		if not staff.has(id):
			staff[id] = []
		for index in range(staff[id].size(), economy.crew[id].size()):
			var profile: HbtService = economy.facilities[id]
			staff[id].append(person(profile.role, standby(id, index)))
	for id in economy.equipped:
		if not directors.has(id):
			directors[id] = person(id, manager_post(id))
	for id in directors.keys():
		if id not in economy.equipped:
			directors[id].queue_free()
			directors.erase(id)

func update(economy: HbtEconomy, dispatch: HbtDispatch, delta: float) -> void:
	var jobs := {}
	var assignments := {}
	for visit: HbtVisit in dispatch.live.values():
		if not visit.footpath.is_empty() and visit.phase != HbtVisit.Phase.DEPART:
			update_visitor(visit, delta)
		if visit.phase != HbtVisit.Phase.WORKING:
			continue
		var profile: HbtService = economy.facilities[visit.service]
		if visit.worker >= 0:
			jobs[identity(visit.service, visit.worker)] = visit
		elif visit.worker == economy.MANAGER_WORKER and directors.has(visit.director):
			assignments[visit.director] = visit
		elif (visit.service != "fuel" or visit.bay != 0) and not manual.has(visit.number):
			var role := profile.role if visit.director.is_empty() else visit.director
			var actor := person(role, routes.worker_at(visit.service, visit.bay))
			orient(actor, visit)
			actor.play(profile.task)
			manual[visit.number] = actor
	for id in manual.keys():
		var ticket: HbtVisit = dispatch.live.get(id)
		if ticket == null or ticket.phase != HbtVisit.Phase.WORKING:
			manual[id].queue_free()
			manual.erase(id)
	for number in visitors.keys():
		var ticket: HbtVisit = dispatch.live.get(number)
		if ticket == null or ticket.phase == HbtVisit.Phase.DEPART:
			visitors[number].queue_free()
			visitors.erase(number)
	for id in staff:
		for index in range(staff[id].size()):
			var job: HbtVisit = jobs.get(identity(id, index))
			walk_to_work(staff[id][index], job, standby(id, index), economy.facilities[id].task, delta)
	for id in directors:
		var job: HbtVisit = assignments.get(id)
		var task: String = "service" if job == null else economy.facilities[job.service].task
		walk_to_work(directors[id], job, manager_post(id), task, delta)

func walk_to_work(actor: Actor, job: HbtVisit, post: Vector3, task: String, delta: float) -> void:
	var target: Vector3 = post if job == null else routes.worker_at(job.service, job.bay)
	var offset := target - actor.position
	var distance := offset.length()
	if distance > 0.045:
		actor.position = actor.position.move_toward(target, delta * 2.32)
		actor.rotation.y = lerp_angle(actor.rotation.y, atan2(offset.x, offset.z), minf(delta * 12.0, 1.0))
	if job != null and distance < 0.33:
		orient(actor, job)
		actor.play(task)
	else:
		actor.play("walk" if distance > 0.045 else "idle")

func update_visitor(visit: HbtVisit, delta: float) -> void:
	if not visitors.has(visit.number):
		var role := "driver" if visit.client.kind == "truck" else "customer"
		visitors[visit.number] = person(role, visit.footpath[0])
	var guest: Actor = visitors[visit.number]
	var delivery: bool = routes is RegionalRoutes and routes.district == "valley" and visit.service == "market" and visit.client.model in ["parcel", "post"]
	if delivery and not is_instance_valid(guest.prop):
		guest.attach_prop("Crate")
	var next := visit.foot_position(visit.walked)
	var shift := next - guest.position
	guest.position = next
	if delivery:
		guest.prop.visible = visit.walked > .90 and visit.phase != HbtVisit.Phase.EXIT_WAIT
	if visit.phase != HbtVisit.Phase.EXIT_WAIT and visit.walked < 0.91:
		guest.rotation.y = visit.yaw + PI * 0.5
		guest.pose_at("exit_car", visit.walked / 0.91 * 0.51)
		return
	if shift.length_squared() > 0.000005:
		guest.rotation.y = lerp_angle(guest.rotation.y, atan2(shift.x, shift.z), minf(delta * 12.0, 1.0))
		guest.play("carry" if delivery and guest.prop.visible else "walk")
	else:
		guest.play("service" if visit.phase == HbtVisit.Phase.WORKING else "idle")

func performer(visit: HbtVisit) -> Node3D:
	if visit.worker >= 0:
		return staff[visit.service][visit.worker]
	return directors.get(visit.director, manual.get(visit.number))

func person(role: String, at: Vector3) -> Actor:
	var figure := Actor.new()
	figure.role = role
	figure.position = at
	add_child(figure)
	return figure

func identity(id: String, index: int) -> String:
	return "%s:%d" % [id, index]

func standby(id: String, index: int) -> Vector3:
	return routes.worker_at(id, index) + Vector3(0.63, 0, -0.76)

func manager_post(id: String) -> Vector3:
	if routes == Routes and MANAGER_SPOTS.has(id):
		return MANAGER_SPOTS[id]
	var site: String = Managers.ROSTER[id].site
	if routes is RegionalRoutes:
		if not routes.layout.plots.has(site):
			site = "fuel"
	elif routes != Routes and site not in routes.FRONTS:
		site = "fuel"
	return routes.worker_at(site, 0) + Vector3(-0.74, 0.0, -0.50)

func orient(actor: Actor, job: HbtVisit) -> void:
	var relative := job.location - actor.position
	actor.rotation.y = 0.18 if job.service == "market" else atan2(relative.x, relative.z)
