extends RefCounted
## Copper Mile uses two forecourts set back from separate highway turnoffs.

const BAYS := {
	"fuel": [Vector3(-3.5, 0.035, -0.6), Vector3(1.2, 0.035, -0.6)],
	"cafe": [Vector3(-14.6, 0.035, -2.0), Vector3(-10.8, 0.035, -2.0)],
	"restrooms": [Vector3(10.2, 0.035, -3.0), Vector3(13.0, 0.035, -3.0)],
	"vip_park": [Vector3(-0.8, 0.035, -12.8), Vector3(2.6, 0.035, -12.8), Vector3(6.0, 0.035, -12.8)],
	"truck": [Vector3(24.6, 0.035, -19.25), Vector3(31.4, 0.035, -19.25)],
	"showers": [Vector3(28.0, 0.035, -7.7), Vector3(33.8, 0.035, -7.7)],
	"motel": [Vector3(-16.8, 0.035, -17.1), Vector3(-13.3, 0.035, -17.1), Vector3(-9.8, 0.035, -17.1)],
	"truck_park": [Vector3(39.5, 0.035, -20.15), Vector3(46.2, 0.035, -20.15)],
	"drive_through": [Vector3(-23.3, 0.035, -12.5), Vector3(-19.4, 0.035, -12.5)],
	"charge": [Vector3(11.0, 0.035, -17.1), Vector3(14.5, 0.035, -17.1)],
}
const FRONTS := {
	"fuel": Vector3(-1.1, 0, -1.55), "cafe": Vector3(-12.8, 0, -6.45),
	"restrooms": Vector3(11.6, 0, -6.6), "vip_park": Vector3(2.6, 0, -14.45),
	"truck": Vector3(28.0, 0, -23.3), "showers": Vector3(32.0, 0, -3.15),
	"motel": Vector3(-13.3, 0, -23.55), "truck_park": Vector3(43.25, 0, -23.9),
	"drive_through": Vector3(-21.35, 0, -15.8), "charge": Vector3(12.75, 0, -20.6),
}
const ENTRY_CAR := Vector3(33.8, 0.025, 3.7)
const ENTRY_TRUCK := Vector3(50.6, 0.025, -11.5)
const EXIT_CAR := [Vector3(-30.25, 0.025, 3.7), Vector3(-33.5, 0.025, 7.1), Vector3(-37.0, 0.025, 9.3), Vector3(-49, 0, 9.3)]
const EXIT_TRUCK := [Vector3(54.3, 0.025, -15.6), Vector3(54.7, 0.025, -7.0), Vector3(54.2, 0.025, 3.5),
	Vector3(49.4, 0.025, 8.5), Vector3(44.0, 0.025, 9.3), Vector3(-49.0, 0, 9.3)]

static func queue_position(lane: String, index: int) -> Vector3:
	return Vector3(36.8 + index * 8.8, .025, -11.5) if lane == "truck" else Vector3(16.6 + index * 5.70, .025, 3.7)

static func lane_size(lane: String) -> int:
	return 2 if lane == "truck" else 4

static func entrance(lane: String) -> Vector3:
	return Vector3(70, 0, 9.3) if lane == "truck" else Vector3(43, 0, 9.3)

static func entry(lane: String, slot: int) -> Array[Vector3]:
	if lane == "truck":
		return [Vector3(58, 0, 9.3), Vector3(51, .025, 6.6), ENTRY_TRUCK, queue_position(lane, slot)]
	return [Vector3(35, .025, 9.3), Vector3(31.0, .025, 7.2), ENTRY_CAR, queue_position(lane, slot)]

static func is_truck(id: String) -> bool:
	return id in ["truck", "showers", "truck_park"]

static func spine(id: String) -> float:
	match id:
		"vip_park", "drive_through": return -9.9
		"motel", "charge": return -14.95
		_: return 3.7

static func approach(id: String, index: int) -> Array[Vector3]:
	var bay := position_of(id, index)
	if is_truck(id):
		return [Vector3(bay.x, .025, -11.5), bay]
	var row := spine(id)
	if is_equal_approx(row, 3.7):
		return [Vector3(bay.x, .025, row), bay]
	return [Vector3(-28.0, .025, 3.7), Vector3(-28.0, .025, row), Vector3(bay.x, .025, row), bay]

static func departure(id: String, index: int) -> Array[Vector3]:
	var bay := position_of(id, index)
	var result: Array[Vector3] = []
	if is_truck(id):
		result.append(Vector3(bay.x, .025, -15.6))
		result.append_array(EXIT_TRUCK)
		return result
	var row := spine(id)
	result.append(Vector3(bay.x, .025, row))
	if not is_equal_approx(row, 3.7):
		result.append_array([Vector3(-29.0, .025, row), Vector3(-29.0, .025, 2.7)])
	result.append_array(EXIT_CAR)
	return result

static func bypass(lane: String) -> Array[Vector3]:
	var result: Array[Vector3] = []
	result.assign(EXIT_TRUCK if lane == "truck" else EXIT_CAR)
	if lane == "truck":
		result.push_front(Vector3(34.3, .025, -15.6))
	return result

static func sectors(id: String, outgoing: bool) -> Array[String]:
	var required: Array[String] = ["truck_yard" if is_truck(id) else "plaza"]
	if outgoing:
		required.append("highway")
		if is_truck(id):
			required.append("entry_truck")
	return required

static func reverse_first(_id: String) -> bool:
	return true

static func position_of(id: String, index: int) -> Vector3:
	var row: Array = BAYS.get(id, BAYS.fuel)
	return row[clampi(index, 0, row.size() - 1)]

static func stopping_yaw(id: String) -> float:
	return 0.0 if id == "showers" else PI

static func worker_at(id: String, bay: int) -> Vector3:
	var parked := position_of(id, bay)
	match id:
		"fuel": return parked + Vector3(1.33, 0, -.69)
		"cafe", "restrooms", "motel": return FRONTS[id] + Vector3((bay - 0.5) * .85, .03, 1.96)
		"showers": return FRONTS[id] + Vector3((bay - 0.5) * 1.3, .03, -1.7)
		"truck": return parked + Vector3(1.95, 0, -.57)
		"drive_through": return parked + Vector3(1.21, 0, -.75)
		_: return parked + Vector3(1.22, 0, -.85)

static func guest_path(id: String, index: int) -> PackedVector3Array:
	if id not in ["cafe", "restrooms", "showers", "motel", "vip_park", "truck_park", "charge"]:
		return PackedVector3Array()
	var bay := position_of(id, index)
	var side := -1.0 if id == "showers" else 1.0
	var door := bay + Vector3(.95 * side, 0, .23)
	var target := worker_at(id, index) + Vector3(-.73, 0, .66 * side)
	return PackedVector3Array([door, Vector3(door.x, .035, target.z), target])
