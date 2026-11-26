extends RefCounted
## A single authored centreline defines pavement placement and the reserved route.

const Regions = preload("res://data/world/regions.gd")
const ROAD_Y := .035

var layout: Dictionary
var district: String
var kinds: Dictionary = {}

func _init(id: String) -> void:
	district = id
	layout = Regions.LAYOUTS[id]
	if layout.get("frontier", false):
		for definition: Array in Regions.SERVICES[id]:
			kinds[definition[0]] = definition[15]

func centerline(lane: String) -> Array:
	return layout.get(lane, layout.car)

func lane_of(id: String) -> String:
	return layout.plots[id][1]

func origin(id: String) -> Vector3:
	var point: Vector2 = layout.plots.get(id, layout.plots.fuel)[0]
	return Vector3(point.x, 0, point.y)

func queue_position(lane: String, index: int) -> Vector3:
	var head: float = layout.truck_queue if lane == "truck" else layout.queue
	return point_at(lane, head + index * (9.5 if lane == "truck" else 7.5))

func lane_size(lane: String) -> int:
	return 2 if lane == "truck" else 3

func entrance(lane: String) -> Vector3:
	var source: Vector2 = centerline(lane).back()
	return Vector3(source.x + 6, ROAD_Y, source.y)

func entry(lane: String, slot: int) -> Array[Vector3]:
	var stop := queue_position(lane, slot)
	return westbound(lane, entrance(lane).x, stop.x)

func approach(id: String, index: int) -> Array[Vector3]:
	var lane := lane_of(id)
	var bay := position_of(id, index)
	var result := westbound(lane, queue_position(lane, 0).x, bay.x)
	result.append(bay)
	return result

func departure(id: String, index: int) -> Array[Vector3]:
	var lane := lane_of(id)
	var bay := position_of(id, index)
	var result := westbound(lane, bay.x, exit_x(lane))
	result.push_front(point_at(lane, bay.x))
	return result

func bypass(lane: String) -> Array[Vector3]:
	return westbound(lane, queue_position(lane, 0).x, exit_x(lane))

func sectors(id: String, _outgoing: bool) -> Array[String]:
	var lock: Array[String] = ["truck_yard" if lane_of(id) == "truck" else "plaza"]
	return lock

func reverse_first(_id: String) -> bool:
	return true

func position_of(id: String, index: int) -> Vector3:
	var plot: Array = layout.plots[id]
	var at := origin(id)
	var offsets := [-.5, .5, 1.5]
	if plot.size() > 4 and int(plot[4]) == 3:
		offsets = [-.85, 0.0, .85]
	var offset: float = offsets[clampi(index, 0, 2)]
	return Vector3(at.x + offset * float(plot[2]), ROAD_Y, at.z + float(plot[3]))

func stopping_yaw(_id: String) -> float:
	return PI

func worker_at(id: String, bay: int) -> Vector3:
	var position := position_of(id, bay)
	if lane_of(id) == "truck" and id != "truck_park":
		return position + Vector3(1.9, 0, -2.75)
	if id in ["fuel", "wash", "workshop", "charge", "parking", "vip_park", "truck_park"] \
			or kinds.get(id, "") in ["wash", "ev", "repair", "parking"]:
		return position + Vector3(1.48, 0, -.8)
	var entrance_z := (origin(id) + Vector3(0, 0, 4.13 if id in ["mall", "dealership"] else 3.38)).z
	return Vector3(position.x + .50, position.y, maxf(entrance_z, position.z - 1.52))

func guest_path(id: String, index: int) -> PackedVector3Array:
	if id in ["fuel", "workshop", "wash", "logistics", "warehouse", "truck_park", "charge"] \
			or (not kinds.is_empty() and lane_of(id) == "truck") or kinds.get(id, "") in ["wash", "ev", "repair", "parking"]:
		return PackedVector3Array()
	var parked := position_of(id, index)
	var gate := worker_at(id, index) + Vector3(-.55, 0, -.57)
	return PackedVector3Array([parked + Vector3(1.12, 0, .25), Vector3(parked.x + 1.22, ROAD_Y, gate.z), gate])

func point_at(lane: String, x: float) -> Vector3:
	var points := centerline(lane)
	var left: Vector2 = points.front()
	if x <= left.x:
		return Vector3(x, ROAD_Y, left.y)
	for right: Vector2 in points.slice(1):
		if x <= right.x:
			return Vector3(x, ROAD_Y, lerpf(left.y, right.y, (x - left.x) / (right.x - left.x)))
		left = right
	return Vector3(x, ROAD_Y, left.y)

func westbound(lane: String, start: float, finish: float) -> Array[Vector3]:
	var points: Array[Vector3] = []
	var course := centerline(lane)
	for i in range(course.size() - 1, -1, -1):
		var bend: Vector2 = course[i]
		if bend.x < start and bend.x > finish:
			points.append(Vector3(bend.x, ROAD_Y, bend.y))
	points.append(point_at(lane, finish))
	return points

func exit_x(lane: String) -> float:
	var last: Vector2 = centerline(lane).front()
	return last.x - 12.0
