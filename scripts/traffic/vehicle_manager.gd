extends Node3D

const Kit = preload("res://scripts/buildings/model_kit.gd")
const TIRE := Color("#1c282c")
const GLASS := Color("#284c59")
var wheels: Array[Node3D] = []

func build(paint: Color, wagon := false) -> void:
	var cabin_height := 1.12 if wagon else 0.99
	Kit.loft(self, [Vector4(0.26, 0.65, 1.4, 0), Vector4(0.43, 0.76, 1.55, 0),
		Vector4(0.67, 0.73, 1.47, 0), Vector4(0.74, 0.65, 1.36, 0)], paint)
	Kit.loft(self, [Vector4(0.70, 0.61, 0.88, -0.17),
		Vector4(cabin_height, 0.48, 0.62 if wagon else 0.48, -0.22)], GLASS)
	Kit.loft(self, [Vector4(cabin_height, 0.49, 0.63 if wagon else 0.49, -0.22),
		Vector4(cabin_height + 0.075, 0.44, 0.59 if wagon else 0.44, -0.22)], paint)
	for x in [-0.77, 0.77]:
		var side := signf(x)
		Kit.beam(self, Vector3(side * 0.6, 0.73, -0.12),
			Vector3(side * 0.49, cabin_height, -0.15), 0.031, paint)
		Kit.box(self, Vector3(x, 0.77, 0.4), Vector3(0.19, 0.11, 0.18), paint)
		for z in [-0.96, 0.98]:
			var wheel := Node3D.new()
			wheel.position = Vector3(x, 0.29, z)
			add_child(wheel)
			wheels.append(wheel)
			Kit.cylinder(wheel, Vector3.ZERO, 0.29, 0.29, 0.21, TIRE, 16).rotation.z = PI / 2
			Kit.cylinder(wheel, Vector3(side * 0.117, 0, 0), 0.175, 0.175, 0.025, Color("#a6bab6")).rotation.z = PI / 2
			Kit.cylinder(wheel, Vector3(side * 0.135, 0, 0), 0.063, 0.063, 0.025, TIRE).rotation.z = PI / 2
		Kit.box(self, Vector3(side * 0.48, 0.59, 1.47), Vector3(0.29, 0.115, 0.067), Color("#fff0a8"))
		Kit.box(self, Vector3(side * 0.49, 0.59, -1.48), Vector3(0.27, 0.11, 0.06), Color("#ed5b43"))
	Kit.box(self, Vector3(0, 0.47, 1.55), Vector3(0.55, 0.13, 0.045), TIRE)
	Kit.box(self, Vector3(0, 0.43, -1.55), Vector3(0.29, 0.09, 0.025), Color("#efe2b8"))

func spin(distance: float) -> void:
	for wheel in wheels:
		wheel.rotate_x(distance / 0.29)
