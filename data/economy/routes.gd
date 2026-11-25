extends RefCounted
## Approach and departure corridors use authored coordinates in the existing campus.

const CAR_ENTRY := [Vector3(46, 0, 8.78), Vector3(35.7, 0, 8.78),
	Vector3(33.4, 0, 7.30), Vector3(31.5, 0, 5.41)]
const TRUCK_ENTRY := [Vector3(60, 0, 8.78), Vector3(49.2, 0, 8.78),
	Vector3(46.20, 0, 6.45), Vector3(46.20, 0, -0.05), Vector3(43.65, 0, -3.55)]
const PLAZA := Vector3(12.80, 0, 6.06)
const MAIN_IN := Vector3(7.25, 0, 5.28)
const MAIN_CROSS := Vector3(4.98, 0, 4.45)
const WEST_IN := Vector3(-11.96, 0, 6.22)
const WEST_OUT := Vector3(-11.89, 0, 7.96)
const EXIT := [Vector3(-14.32, 0, 8.78), Vector3(-40.0, 0, 8.78)]
const EAST_TURN := Vector3(12.0, 0, 4.70)
const BACK_IN := [Vector3(-12.06, 0, -9.97), Vector3(-10.34, 0, -11.68)]
const TRUCK_END := [Vector3(17.80, 0, -1.45), Vector3(17.80, 0, 2.15),
	Vector3(36.60, 0, 2.24), Vector3(36.87, 0, 6.92), Vector3(34.70, 0, 8.77), Vector3(-40.0, 0, 8.77)]
const CAR_QUEUE := 4
const TRUCK_QUEUE := 2

static func queue_position(lane: String, index: int) -> Vector3:
	return Vector3(32.2 + index * 8.45, 0, -3.55) if lane == "truck" else Vector3(15.8 + index * 4.95, 0, 5.41)

static func lane_size(lane: String) -> int:
	return TRUCK_QUEUE if lane == "truck" else CAR_QUEUE

static func entry(lane: String, slot: int) -> Array[Vector3]:
	var points: Array[Vector3] = []
	points.assign((TRUCK_ENTRY if lane == "truck" else CAR_ENTRY).slice(1))
	points.append(queue_position(lane, slot))
	return points

static func entrance(lane: String) -> Vector3:
	return TRUCK_ENTRY[0] if lane == "truck" else CAR_ENTRY[0]

static func approach(id: String, index: int) -> Array[Vector3]:
	var bay := position_of(id, index)
	var route: Array[Vector3] = []
	match id:
		"fuel":
			route.assign([PLAZA, MAIN_IN, MAIN_CROSS])
			if index == 0:
				route.append_array([Vector3(3.7, 0, 2.76), bay])
			else:
				route.append_array([Vector3(-1.84, 0, 4.45), Vector3(-2.48, 0, 3.03), bay])
		"market":
			route.assign([PLAZA, MAIN_IN, MAIN_CROSS, Vector3(0.7, 0, 4.91),
				Vector3(bay.x, 0, 4.91), bay])
		"wash":
			route.assign([PLAZA, EAST_TURN, Vector3(bay.x, 0, -2.03),
				Vector3(bay.x, bay.y, -4.79 if index == 0 else -3.18), bay])
		"truck":
			route.assign([Vector3(31.42, 0, -3.55)])
			if index > 0:
				route.append(Vector3(31.42, 0, bay.z))
			route.append_array([Vector3(28.40, 0, bay.z), bay])
		"truck_park":
			route.assign([Vector3(31.42, 0, -3.55), Vector3(31.42, 0, bay.z), bay])
		"parking", "restaurant", "tires", "charge":
			var turn := 3.70 if id == "charge" else 2.90 if id == "parking" else -3.75
			route.assign([PLAZA, Vector3(5.64, 0, 6.39), WEST_IN, Vector3(-12.08, 0, turn),
				Vector3(bay.x, 0, turn), bay])
		"workshop", "motel":
			route.assign([PLAZA, Vector3(5.64, 0, 6.39), WEST_IN])
			route.append_array(BACK_IN)
			route.append_array([Vector3(bay.x, 0, -11.70), bay])
	return route

static func departure(id: String, index: int) -> Array[Vector3]:
	var bay := position_of(id, index)
	var route: Array[Vector3] = []
	match id:
		"fuel":
			route.assign([Vector3(0.04, 0, 2.75), Vector3(-0.80, 0, 3.68), Vector3(-1.90, 0, 4.94),
				Vector3(-7.21, 0, 4.94), Vector3(-9.49, 0, 5.46), WEST_OUT] if index == 0 else
				[Vector3(-6.42, 0, 3.08), Vector3(-9.08, 0, 4.82), WEST_OUT])
		"market":
			route.assign([Vector3(bay.x, 0, 3.92), Vector3(-9.40, 0, 4.46), WEST_OUT])
		"wash":
			route.assign([Vector3(bay.x, 0, -2.77 if index == 0 else 0.25), EAST_TURN,
				Vector3(11.40, 0, 7.21), Vector3(9.0, 0, 8.78)])
		"truck":
			route.assign([Vector3(18.50, 0, bay.z)])
			route.append_array(TRUCK_END)
			return route
		"truck_park":
			route.assign([Vector3(48.9, 0, bay.z), Vector3(48.9, 0, 2.31), Vector3(46.5, 0, 5.27),
				Vector3(44.95, 0, 7.58), Vector3(43.35, 0, 8.78), EXIT.back()])
			return route
		"parking", "restaurant", "tires", "charge":
			var turn := 3.70 if id == "charge" else 2.90 if id == "parking" else -3.75
			route.assign([Vector3(bay.x, 0, turn), Vector3(-12.08, 0, turn), WEST_OUT])
		"workshop", "motel":
			route.assign([Vector3(bay.x, 0, -11.8), Vector3(-10.34, 0, -11.8),
				Vector3(-12.06, 0, -9.95), WEST_OUT])
	route.append_array(EXIT)
	return route

static func bypass(lane: String) -> Array[Vector3]:
	var route: Array[Vector3] = []
	if lane == "truck":
		route.assign(TRUCK_END.slice(2))
	else:
		route.assign([PLAZA, Vector3(11.2, 0, 7.35), Vector3(9.0, 0, 8.78)])
		route.append_array(EXIT)
	return route

static func sectors(id: String, outbound: bool) -> Array[String]:
	if id in ["truck", "truck_park"]:
		var truck: Array[String] = ["truck_yard"]
		if outbound:
			truck.append("highway")
			if id == "truck_park":
				truck.append_array(["entry_truck", "entry_car"])
		return truck
	var required: Array[String] = ["plaza"]
	if outbound:
		required.append("highway")
	if id in ["motel", "workshop"]:
		required.append("back")
	elif id == "wash":
		required.append("wash_drive")
	return required

static func reverse_first(id: String) -> bool:
	return id in ["market", "parking", "wash", "workshop", "restaurant", "motel", "tires", "charge"]

static func position_of(id: String, index: int) -> Vector3:
	match id:
		"fuel": return [Vector3(0.80, 0, 2.55), Vector3(-4.27, 0, 3.02)][index]
		"market": return [Vector3(-9.26, 0, 0.57), Vector3(-7.00, 0, 0.61)][index]
		"parking": return Vector3(-18.38 + index * 1.87, 0.177, -0.55)
		"wash": return [Vector3(11.47, 0.265, -7.04), Vector3(13.02, 0, -4.10)][index]
		"workshop": return [Vector3(10.33, 0.245, -15.35), Vector3(6.55, 0, -13.91)][index]
		"restaurant": return Vector3([-21.55, -24.42][index], 0.0, -5.82)
		"motel": return Vector3([-9.68, -7.12, -4.53][index], 0, -8.11)
		"truck": return Vector3(23.95, 0.0, [-3.55, -6.87, -10.19][index])
		"tires": return Vector3([-30.12, -33.59][index], 0.12, -7.04)
		"truck_park": return Vector3(37.55, 0.0, [-7.44, -10.83][index])
		"charge": return Vector3(-28.80 - index * 3.13, 0.03, 0.05)
	return Vector3.ZERO

static func stopping_yaw(id: String) -> float:
	if id == "motel":
		return 0.0
	if id == "truck_park":
		return PI * 0.5
	return -PI * 0.5 if id in ["fuel", "truck"] else PI

static func worker_at(id: String, bay: int) -> Vector3:
	var at := position_of(id, bay)
	match id:
		"fuel", "truck": return at + Vector3(1.38 if id == "fuel" else 1.83, 0, 1.10)
		"workshop": return at + Vector3(1.26, 0, 0.26)
		"wash": return at + Vector3(-1.28, 0, 1.08)
		"market": return Vector3(-3.95 - bay * 0.85, 0.28, -5.16)
		"restaurant": return at + Vector3(1.05, 0.30, -1.31)
		"motel": return at + Vector3(1.09, 0.30, -1.20)
		"tires": return at + Vector3(-1.08, 0.0, -0.10)
		"truck_park": return at + Vector3(1.58, 0.0, -1.49)
		"charge": return at + Vector3(-1.08, 0.0, -0.50)
	return at + Vector3(0.91, 0, 1.30)

static func guest_path(id: String, bay: int) -> PackedVector3Array:
	var at := position_of(id, bay)
	var door := at + Vector3(0.82, 0.015, -0.29)
	match id:
		"market":
			return PackedVector3Array([door, Vector3(door.x, 0.06, -1.26), Vector3(-6.19, 0.06, -1.26), Vector3(-6.07, 0.25, -2.19)])
		"restaurant":
			return PackedVector3Array([door, Vector3(door.x, 0.025, -7.62), Vector3(-18.53, 0.06, -7.62), Vector3(-17.22, 0.26, -6.59)])
		"motel":
			return PackedVector3Array([door, Vector3(door.x, 0.04, -10.03), Vector3(-9.80, 0.04, -10.03),
				Vector3(-9.80, 0.08, -13.42), Vector3(-9.80, 0.34, -14.65)])
		"parking":
			return PackedVector3Array([door, Vector3(door.x, at.y, -2.38), Vector3(-16.69, at.y, -2.38)])
		"tires":
			return PackedVector3Array([door, Vector3(door.x, 0.15, -5.62), Vector3(-28.58, 0.15, -5.62), Vector3(-28.58, 0.15, -7.42)])
		"truck_park":
			return PackedVector3Array([at + Vector3(1.46, 0.02, 1.58), Vector3(44.31, 0.06, at.z + 1.58), Vector3(44.68, 0.14, -11.63)])
		"charge":
			return PackedVector3Array([door, at + Vector3(1.24, 0.045, -0.58), at + Vector3(1.04, 0.045, -1.65)])
	return PackedVector3Array()
