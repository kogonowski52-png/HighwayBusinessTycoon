class_name HbtDispatch
extends RefCounted
## Reservations are all-or-nothing. Waiting customers hold bays or queue slots only.

signal added(visit: HbtVisit)
signal removed(visit: HbtVisit)
signal state_changed
signal started(visit: HbtVisit)
signal completed(visit: HbtVisit)

const Routes = preload("res://data/economy/routes.gd")
const Demand = preload("res://scripts/customers/demand.gd")
const Phase = HbtVisit.Phase
const Staff = preload("res://scripts/employees/staff_rules.gd")
const WATCHDOG := 8.0
const QUEUE_SPEED := 5.1

var economy: HbtEconomy
var demand: Demand
var live: Dictionary = {}
var lanes := {"car": [], "truck": []}
var bays: Dictionary = {}
var guards: Dictionary = {}
var next_id := 1
var arrival_in := 0.20
var spawning := true
var admitted := 0
var departed := 0
var abandoned := 0
var recovered := 0
var capacity_rejected := 0
var peak_queue := 0

func _init(store: HbtEconomy, seed: int) -> void:
	economy = store
	demand = Demand.new(seed)
	for id in economy.facilities:
		bays[id] = {}

func seed_station() -> void:
	var client := demand.customer(economy, "local")
	client.budget = economy.price("fuel").times(2)
	var visit := make_visit(client, "fuel")
	visit.location = Routes.position_of("fuel", 0)
	visit.bay = 0
	visit.phase = Phase.READY
	bays.fuel[0] = visit.number
	added.emit(visit)

func try_admit(forced := "", requested := "") -> HbtVisit:
	var client := demand.customer(economy, forced)
	var lane: String = client.kind
	if lanes[lane].size() >= Routes.lane_size(lane) or guards.has("entry_" + lane):
		capacity_rejected += 1
		return null
	var selected := demand.pick(economy, client, queued_by_service()) if requested.is_empty() else requested
	if selected.is_empty() or economy.level(selected) == 0 or not Demand.accepts(economy.facilities[selected], client):
		return null
	var visit := make_visit(client, selected)
	visit.location = Routes.entrance(lane)
	var position: int = lanes[lane].size()
	lanes[lane].append(visit)
	acquire(visit, ["entry_" + lane])
	route(visit, Routes.entry(lane, position), Phase.ENTERING)
	added.emit(visit)
	state_changed.emit()
	return visit

func make_visit(client: Dictionary, id: String) -> HbtVisit:
	var visit := HbtVisit.new()
	visit.number = next_id
	visit.client = client
	visit.service = id
	visit.invoice = HbtAmount.new()
	visit.patience = client.patience
	live[next_id] = visit
	admitted += 1
	next_id += 1
	return visit

func tick(delta: float) -> void:
	if delta <= 0.0:
		return
	for ticket: HbtVisit in live.values():
		ticket.distance = 0.0
		ticket.signed_distance = 0.0
		match ticket.phase:
			Phase.ENTERING, Phase.APPROACH, Phase.DEPART:
				travel(ticket, delta)
			Phase.READY:
				ticket.walked = move_toward(ticket.walked, ticket.foot_length, delta * HbtVisit.WALK_SPEED)
				if ticket.number != 1 or economy.customers > 0:
					ticket.patience -= delta
				if ticket.patience <= 0.0:
					leave_unserved(ticket)
			Phase.WORKING:
				ticket.walked = move_toward(ticket.walked, ticket.foot_length, delta * HbtVisit.WALK_SPEED)
				ticket.timer -= delta
				if ticket.timer <= 0.0:
					finish(ticket)
			Phase.EXIT_WAIT:
				ticket.walked = move_toward(ticket.walked, 0.0, delta * HbtVisit.WALK_SPEED)
	for lane in lanes:
		update_queue(lane, delta)
	for ticket: HbtVisit in live.values():
		if ticket.phase == Phase.EXIT_WAIT and is_zero_approx(ticket.walked):
			start_departure(ticket)
	for lane in lanes:
		dispatch_head(lane)
	for ticket: HbtVisit in live.values():
		if ticket.phase == Phase.READY:
			var worker := free_worker(ticket.service)
			if worker != -1:
				begin(ticket, worker)
	peak_queue = maxi(peak_queue, lanes.car.size() + lanes.truck.size())
	if spawning:
		arrival_in -= delta
		if arrival_in <= 0.0:
			try_admit()
			arrival_in = economy.arrival_period() * demand.random.randf_range(0.83, 1.20)

func queued_by_service() -> Dictionary:
	var count := {}
	for ticket: HbtVisit in live.values():
		if ticket.phase != Phase.DEPART:
			count[ticket.service] = count.get(ticket.service, 0) + 1
	return count

func visit_at(id: String, index: int) -> HbtVisit:
	return live.get(bays[id].get(index, -1))

func first_at(id: String, phase: HbtVisit.Phase) -> HbtVisit:
	for index in range(economy.capacity(id)):
		var candidate := visit_at(id, index)
		if candidate != null and candidate.phase == phase:
			return candidate
	return null

func free_bay(id: String) -> int:
	for index in range(economy.capacity(id)):
		if not bays[id].has(index):
			return index
	return -1

func free_worker(id: String) -> int:
	var busy := {}
	for index in bays[id]:
		var ticket := visit_at(id, index)
		if ticket != null and ticket.phase == Phase.WORKING and ticket.worker != -1:
			busy[ticket.worker] = true
	for index in range(economy.crew[id].size()):
		if not busy.has(index):
			return index
	if economy.crew[id].is_empty() and not busy.has(economy.MANAGER_WORKER) and economy.skill("automation", id) > 0:
		return economy.MANAGER_WORKER
	return -1

func update_queue(lane: String, delta: float) -> void:
	var line: Array = lanes[lane]
	var previous: HbtVisit
	for i in range(line.size()):
		var ticket: HbtVisit = line[i]
		if ticket.phase != Phase.QUEUED:
			break
		ticket.patience -= delta
		var target := Routes.queue_position(lane, i)
		if previous != null:
			var gap := (float(ticket.client.length) + float(previous.client.length)) * 0.5 + 0.65
			target.x = maxf(target.x, previous.location.x + gap)
		step(ticket, target, QUEUE_SPEED * delta, delta, false)
		previous = ticket

func dispatch_head(lane: String) -> void:
	if lanes[lane].is_empty():
		return
	var ticket: HbtVisit = lanes[lane].front()
	if ticket.phase != Phase.QUEUED or ticket.location.distance_to(Routes.queue_position(lane, 0)) > 0.45:
		return
	if ticket.patience <= 0.0:
		var sectors: Array[String] = ["truck_yard" if lane == "truck" else "plaza", "highway"]
		if acquire(ticket, sectors):
			lanes[lane].pop_front()
			ticket.bounced = true
			abandoned += 1
			route(ticket, Routes.bypass(lane), Phase.DEPART)
			state_changed.emit()
		return
	var index := free_bay(ticket.service)
	if index < 0 and ticket.patience < float(ticket.client.patience) * 0.63:
		var free := {}
		for id in economy.facilities:
			free[id] = free_bay(id) >= 0
		var alternate := demand.pick(economy, ticket.client, queued_by_service(), free)
		if not alternate.is_empty():
			ticket.service = alternate
			index = free_bay(alternate)
	if index < 0 or not acquire(ticket, Routes.sectors(ticket.service, false)):
		return
	lanes[lane].pop_front()
	ticket.bay = index
	bays[ticket.service][index] = ticket.number
	route(ticket, Routes.approach(ticket.service, index), Phase.APPROACH)
	state_changed.emit()

func start_manual(id: String) -> bool:
	var ticket := first_at(id, Phase.READY)
	if ticket == null:
		return false
	begin(ticket, -1)
	return true

func begin(ticket: HbtVisit, worker: int) -> void:
	ticket.phase = Phase.WORKING
	ticket.worker = worker
	ticket.duration = economy.duration(ticket.service, worker)
	var preparation := (ticket.foot_length - ticket.walked) / HbtVisit.WALK_SPEED
	if worker >= 0:
		preparation = maxf(preparation, Staff.preparation_seconds(economy.crew[ticket.service][worker]))
	elif worker == economy.MANAGER_WORKER:
		ticket.director = economy.manager_for("automation", ticket.service)
	ticket.duration += preparation
	ticket.timer = ticket.duration
	ticket.invoice = economy.payout(ticket.service, ticket.client.tip, worker)
	started.emit(ticket)
	state_changed.emit()

func finish(ticket: HbtVisit) -> void:
	ticket.phase = Phase.EXIT_WAIT
	ticket.paid = true
	economy.serve(ticket.service, ticket.invoice, ticket.client.reputation, ticket.worker)
	completed.emit(ticket)
	state_changed.emit()

func leave_unserved(ticket: HbtVisit) -> void:
	ticket.phase = Phase.EXIT_WAIT
	ticket.bounced = true
	abandoned += 1
	state_changed.emit()

func start_departure(ticket: HbtVisit) -> void:
	if not acquire(ticket, Routes.sectors(ticket.service, true)):
		return
	route(ticket, Routes.departure(ticket.service, ticket.bay), Phase.DEPART)
	ticket.reverse_first = Routes.reverse_first(ticket.service)
	state_changed.emit()

func acquire(ticket: HbtVisit, sectors: Array[String]) -> bool:
	for id in sectors:
		if guards.has(id) and guards[id] != ticket.number:
			return false
	for id in sectors:
		guards[id] = ticket.number
	ticket.spaces = sectors
	return true

func release(ticket: HbtVisit) -> void:
	for id in ticket.spaces:
		if guards.get(id) == ticket.number:
			guards.erase(id)
	ticket.spaces.clear()

func route(ticket: HbtVisit, points: Array[Vector3], phase: HbtVisit.Phase) -> void:
	ticket.path = points
	ticket.cursor = 0
	ticket.stalled = 0.0
	ticket.reverse_first = false
	ticket.phase = phase

func travel(ticket: HbtVisit, delta: float) -> void:
	var speed := 9.7
	if ticket.phase == Phase.ENTERING:
		var outer := ticket.cursor == 0
		speed = 17.5 if outer else 8.0
	elif ticket.phase == Phase.DEPART and ticket.cursor == ticket.path.size() - 1:
		speed = 20.0
	elif ticket.phase == Phase.APPROACH and ticket.cursor == ticket.path.size() - 1:
		speed = 5.0
	var remaining := delta * speed
	while remaining > 0.00001:
		var target := ticket.path[ticket.cursor]
		var direction := target - ticket.location
		var allowance := minf(remaining, clearance(ticket, direction))
		var backing := ticket.reverse_first and ticket.cursor == 0
		var moved := step(ticket, target, allowance, delta, backing)
		remaining -= moved
		if ticket.location.distance_squared_to(target) > 0.0004:
			break
		ticket.cursor += 1
		if ticket.cursor == ticket.path.size():
			arrive(ticket)
			return
		if ticket.phase == Phase.DEPART and ticket.cursor == 1:
			release_bay(ticket)
		# The final straight runs outside the complex and no longer holds its corridors.
		if ticket.phase == Phase.DEPART and ticket.cursor == ticket.path.size() - 1:
			release(ticket)
	if ticket.distance < 0.001:
		ticket.stalled += delta
		if ticket.stalled >= WATCHDOG:
			recover(ticket)
	else:
		ticket.stalled = 0.0

func step(ticket: HbtVisit, target: Vector3, allowance: float, delta: float, backing: bool) -> float:
	var direction := target - ticket.location
	if direction.length_squared() <= 0.000004 or allowance <= 0.00001:
		return 0.0
	var finish := ticket.location.move_toward(target, allowance)
	var moved := finish.distance_to(ticket.location)
	var angle := atan2(direction.x, direction.z) + (PI if backing else 0.0)
	var turn := wrapf(angle - ticket.yaw, -PI, PI)
	ticket.steer = 1 if turn > 0.25 else -1 if turn < -0.25 else 0
	ticket.yaw = lerp_angle(ticket.yaw, angle, minf(1.0, delta * 7.5))
	ticket.location = finish
	ticket.distance += moved
	ticket.signed_distance += -moved if backing else moved
	return moved

func clearance(ticket: HbtVisit, direction: Vector3) -> float:
	if direction.length_squared() <= 0.000004:
		return 0.0
	var unit := Vector2(direction.x, direction.z).normalized()
	var limit := INF
	for obstacle: HbtVisit in live.values():
		if obstacle == ticket:
			continue
		var shift := Vector2(obstacle.location.x - ticket.location.x, obstacle.location.z - ticket.location.z)
		var ahead := shift.dot(unit)
		var lateral := absf(unit.cross(shift))
		var width := 0.44 * (float(ticket.client.width) + float(obstacle.client.width))
		if ahead <= 0.0 or lateral > width:
			continue
		var heading := Vector2(sin(obstacle.yaw), cos(obstacle.yaw))
		var projection := absf(heading.dot(unit)) * float(obstacle.client.length)
		projection += absf(heading.cross(unit)) * float(obstacle.client.width)
		var safe := (float(ticket.client.length) + projection) * 0.43 + 0.28
		limit = minf(limit, maxf(0.0, ahead - safe))
	return limit

func arrive(ticket: HbtVisit) -> void:
	release(ticket)
	match ticket.phase:
		Phase.ENTERING:
			ticket.yaw = -PI * 0.5
			ticket.phase = Phase.QUEUED
		Phase.APPROACH:
			ticket.yaw = Routes.stopping_yaw(ticket.service)
			ticket.set_footpath(Routes.guest_path(ticket.service, ticket.bay))
			ticket.phase = Phase.READY
			ticket.patience = maxf(ticket.patience, 13.0)
		Phase.DEPART:
			dispose(ticket)
	state_changed.emit()

func release_bay(ticket: HbtVisit) -> void:
	if bays[ticket.service].get(ticket.bay) == ticket.number:
		bays[ticket.service].erase(ticket.bay)

func recover(ticket: HbtVisit) -> void:
	recovered += 1
	if "--trace-blockage" in OS.get_cmdline_user_args():
		var others := {}
		for car: HbtVisit in live.values():
			if car != ticket and car.location.distance_to(ticket.location) < 10.0:
				others[car.number] = [car.service, car.phase, car.location]
		print("Blocked ", ticket.service, " phase=", ticket.phase, " bay=", ticket.bay, " at=", ticket.location,
			" goal=", ticket.path[ticket.cursor], " nearby=", others)
	if not ticket.paid and not ticket.bounced:
		abandoned += 1
	dispose(ticket)
	state_changed.emit()

func dispose(ticket: HbtVisit) -> void:
	release(ticket)
	release_bay(ticket)
	lanes[ticket.client.kind].erase(ticket)
	live.erase(ticket.number)
	departed += 1
	removed.emit(ticket)

func consistent() -> bool:
	for id in guards:
		var ticket: HbtVisit = live.get(guards[id])
		if ticket == null or id not in ticket.spaces:
			return false
	for id in bays:
		for index in bays[id]:
			var ticket := visit_at(id, index)
			if ticket == null or ticket.bay != index or ticket.service != id:
				return false
	for lane in lanes:
		for ticket: HbtVisit in lanes[lane]:
			if ticket.phase not in [Phase.ENTERING, Phase.QUEUED] or not live.has(ticket.number):
				return false
	return true
