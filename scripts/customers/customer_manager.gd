extends Node3D

const Kit = preload("res://scripts/buildings/model_kit.gd")
const JACKET := Color("#b85b3d")
const DENIM := Color("#293e50")
const SKIN := Color("#ba7952")
const SHOE := Color("#202928")
var arm: Node3D
var phase := 0.0

func _ready() -> void:
	Kit.loft(self, [Vector4(0.85, 0.19, 0.13, 0), Vector4(1.07, 0.25, 0.14, 0),
		Vector4(1.37, 0.29, 0.165, 0), Vector4(1.49, 0.14, 0.11, 0)], JACKET)
	Kit.cylinder(self, Vector3(0, 1.48, 0), 0.096, 0.092, 0.18, SKIN, 8)
	var head := Node3D.new()
	add_child(head)
	Kit.loft(head, [Vector4(1.50, 0.095, 0.105, 0.01), Vector4(1.56, 0.136, 0.12, 0.01),
		Vector4(1.73, 0.136, 0.125, 0), Vector4(1.79, 0.107, 0.11, 0)], SKIN)
	Kit.loft(head, [Vector4(1.68, 0.144, 0.128, 0), Vector4(1.80, 0.138, 0.125, 0),
		Vector4(1.85, 0.106, 0.1, 0)], SHOE)
	Kit.box(head, Vector3(0, 1.71, 0.13), Vector3(0.27, 0.033, 0.15), SHOE)
	for x in [-0.126, 0.126]:
		Kit.beam(self, Vector3(x, 0.9, 0), Vector3(x * 1.25, 0.14, 0.02), 0.092, DENIM)
		Kit.box(self, Vector3(x * 1.25, 0.073, 0.064), Vector3(0.2, 0.146, 0.33), SHOE)
	for x in [-0.27, 0.27]:
		var shoulder := Node3D.new()
		shoulder.position = Vector3(x, 1.39, 0)
		add_child(shoulder)
		var elbow := Vector3(signf(x) * 0.062, -0.28, 0.02)
		var hand := Vector3(signf(x) * 0.06, -0.52, 0.098)
		Kit.beam(shoulder, Vector3.ZERO, elbow, 0.071, JACKET)
		Kit.beam(shoulder, elbow, hand, 0.055, SKIN)
		Kit.box(shoulder, hand, Vector3(0.102, 0.12, 0.10), SKIN)
		if x > 0.0:
			arm = shoulder
			Kit.box(arm, hand + Vector3(0, -0.04, 0.064), Vector3(0.075, 0.10, 0.22), SHOE)
	visible = false

func represent_service(waiting: bool, serving: bool, delta: float) -> void:
	visible = waiting or serving
	if not visible:
		phase = 0.0
		return
	phase += delta
	arm.rotation.x = (-0.92 + sin(phase * 7.0) * 0.095) if serving else -0.12
