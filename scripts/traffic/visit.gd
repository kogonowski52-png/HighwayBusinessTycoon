class_name HbtVisit
extends RefCounted

enum Phase { ENTERING, QUEUED, APPROACH, READY, WORKING, EXIT_WAIT, DEPART }
const WALK_SPEED := 2.42

var number: int
var client: Dictionary
var service: String
var phase := Phase.ENTERING
var location := Vector3.ZERO
var yaw := -PI * 0.5
var bay := -1
var worker := -1
var director := ""
var timer := 0.0
var duration := 1.0
var patience := 0.0
var path: Array[Vector3] = []
var cursor := 0
var reverse_first := false
var spaces: Array[String] = []
var stalled := 0.0
var distance := 0.0
var signed_distance := 0.0
var steer := 0
var invoice: HbtAmount
var base_invoice: HbtAmount
var ad_guest := false
var spotlight: Dictionary = {}
var trade := ""
var stock_delta := 0
var sold_model := ""
var paid := false
var bounced := false
var footpath := PackedVector3Array()
var foot_length := 0.0
var walked := 0.0

func set_footpath(points: PackedVector3Array) -> void:
	footpath = points
	foot_length = 0.0
	for index in range(1, points.size()):
		foot_length += points[index - 1].distance_to(points[index])

func foot_position(distance: float) -> Vector3:
	var remaining := distance
	for index in range(1, footpath.size()):
		var previous := footpath[index - 1]
		var next := footpath[index]
		var length := previous.distance_to(next)
		if remaining <= length:
			return previous.move_toward(next, remaining)
		remaining -= length
	return footpath[-1]

func progress() -> float:
	return clampf(1.0 - timer / duration, 0.0, 1.0) if phase == Phase.WORKING else 0.0
