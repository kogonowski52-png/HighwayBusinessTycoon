class_name HbtVisit
extends RefCounted

enum Phase { ENTERING, QUEUED, APPROACH, READY, WORKING, EXIT_WAIT, DEPART }

var number: int
var client: Dictionary
var service: String
var phase := Phase.ENTERING
var location := Vector3.ZERO
var yaw := -PI * 0.5
var bay := -1
var worker := -1
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
var paid := false
var bounced := false

func progress() -> float:
	return clampf(1.0 - timer / duration, 0.0, 1.0) if phase == Phase.WORKING else 0.0
