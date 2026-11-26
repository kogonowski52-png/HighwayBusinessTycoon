extends "res://scripts/buildings/regional_landscape.gd"
## Each frontier has its own geographic landmarks, horizon, structures and vegetation.

const WALL_TRIM := Color("#f6ddb2")
const SHORE := Color("#d2bb80")

func ground(pigments: Array) -> void:
	if routes.district == "tropical":
		var sea := water_material(true)
		sea.set_shader_parameter("shallows", Color("#72d4c1"))
		sea.set_shader_parameter("channel", Color("#2a8daf"))
		Art.plane(self, Vector3(0, -.151, 0), Vector2(265, 192), sea)
		Art.place(self, "regions", "tropical_shore")
		return
	super(pigments)

func surrounding() -> void:
	var region: String = routes.district
	var edge: Array[Vector2] = []
	match region:
		"tropical":
			for at in [Vector3(-35, -.12, 28.0), Vector3(18, -.12, 31.0), Vector3(37, -.12, 29.0)]:
				var pier := landmark(at, 1.37, .14 if at.x > 0.0 else -.02)
				pier.position.z += 1.4
			Art.plane(self, Vector3(-13, -.094, 24.0), Vector2(51, 1.7), surface("#b7aa85", "#e9d299"))
			for x in [-26.0, 11.2, 32.6]:
				Art.place(self, "desert", "median_planter", Vector3(x, -.078, 20.2))
			edge.assign([Vector2(-39, 18), Vector2(-43, 24), Vector2(-28, 22), Vector2(-17, 20), Vector2(-3, 18),
				Vector2(4, 21), Vector2(10, 20), Vector2(19, 21), Vector2(31, 20), Vector2(40, 20),
				Vector2(-18,-28), Vector2(8,-24), Vector2(26,-28), Vector2(47,-19)])
		"route66":
			for i in 10:
				var node := landmark(Vector3(-73 + i*16.5, -.11, -31.8 + cos(i*.73)*4.6),
					1.23+sin(i*1.17)*.36, i*.365)
				node.scale.y *= 1.31 if i in [1,5,8] else .88
			for x in [-41.8, 0.0, 31.0]:
				billboard(Vector3(x, -.08, 21.92), ["COPPER SPUR", "MOTOR LODGE", "DINER · OPEN"][int(absf(x)) % 3])
			edge.assign([Vector2(-19, 8.9), Vector2(28, 8.6), Vector2(-40, -25),
				Vector2(33, -24), Vector2(-22,-18), Vector2(6.8,-17.5)])
		"harbor":
			var bay: ShaderMaterial = water_material(true)
			bay.set_shader_parameter("shallows", Color("#749b9f"))
			bay.set_shader_parameter("channel", Color("#486f8a"))
			Art.plane(self, Vector3(0, -.105, -94), Vector2(256, 88), bay)
			Art.plane(self, Vector3(0, -.070, -48.0), Vector2(177, 2.62), surface("#7f837d", "#aca895"))
			for x in [-38.5, 39.0]:
				landmark(Vector3(x, -.127, -59.0), 1.71, PI * .5)
			for x in [-54.0, -15.2, 19.9, 53.5]:
				gantry(Vector3(x, -.05, -47.0))
			edge.assign([Vector2(-29,-4), Vector2(4, -6.5),Vector2(27,-9),Vector2(45,-8),Vector2(40,-41)])
		"luxury":
			Art.plane(self, Vector3(0, -.106, -43.0), Vector2(151, 16.7), surface("#a39786", "#c6bea1"))
			for point in [Vector3(-9.5,-.09,-6.5), Vector3(32.0,-.09,29.4), Vector3(-17,-.09,26.9)]:
				landmark(point, .84)
			establish_skyline(-50.0, 14, 7.3, 1.44)
			edge.assign([Vector2(-43, 27.8), Vector2(-34, 30), Vector2(-23, 24), Vector2(-12, 25.3),
				Vector2(4, 28.5), Vector2(15, 28.5), Vector2(22, 26), Vector2(37, 26), Vector2(47, 24.5)])
		"japan":
			for x in [-40.0, 5.6, 42.0]:
				landmark(Vector3(x, -.105, 24.0), 1.08, .26)
			establish_skyline(-47.3, 12, 8.0, 1.16)
			edge.assign([Vector2(-32, 24), Vector2(-22, 22.2), Vector2(-15, 25.0), Vector2(-8, 23),
				Vector2(17, 24.1), Vector2(31, 24.5),Vector2(40, 23.4), Vector2(-35,-23),Vector2(39,-25),Vector2(22,-27)])
		"wilderness":
			var lake := water_material(false)
			lake.set_shader_parameter("shallows", Color("#77b1aa"))
			lake.set_shader_parameter("channel", Color("#416e86"))
			Art.plane(self, Vector3(-20, -.106, 46), Vector2(91, 39), lake)
			Art.plane(self, Vector3(-18, -.062, 27.2), Vector2(88, 1.15), surface("#aaa48d", "#b9b397"))
			for i in 10:
				landmark(Vector3(-62 + i*14.7, -.13, -54.0 + sin(i*.74)*6), 1.64 + .46*cos(i*1.4), i*.28)
			for i in 16:
				edge.append(Vector2(-58.0+i*7.30, rng.randf_range(-47.0, -43.1)))
			edge.append_array([Vector2(-8, -16.7), Vector2(39, -12.3), Vector2(25,-27),Vector2(-46,-28)])
	for i in 21:
		edge.append(Vector2(-64.0 + i*6.10 + rng.randf_range(-1.5, 1.5),
			rng.randf_range(19.0, 28.0) if region != "tropical" else rng.randf_range(18.4, 23.1)))
	for i in 9:
		var x := -59.1+i*13.7
		edge.append(Vector2(x+rng.randf_range(-2.4, 2.1), -27.0 if region == "tropical" else -41.5 + rng.randf_range(-2,2)))
	foliage(edge)
	roadside_details([Vector3(-25.1, 0, 7.65), Vector3(-8, 0, 6.05), Vector3(17.7, 0, 7.2)], "meadow")

func landmark(at: Vector3, size: float, yaw := 0.0) -> Node3D:
	var model := Art.place(self, "regions", routes.district + "_landmark", at, yaw)
	model.scale = Vector3.ONE * size
	return model

func establish_skyline(z: float, count: int, interval: float, scale_y: float) -> void:
	for index in count:
		var model := Art.place(self, "regions", "%s_skyline_%d" % [routes.district, index%3],
			Vector3(-50 + index*interval+rng.randf_range(-.9,.9), -.08, z+rng.randf_range(-4,4)), .17*sin(index))
		model.scale = Vector3(1.1, scale_y * rng.randf_range(.80, 1.39), 1.17)

func billboard(at: Vector3, title: String) -> void:
	for shift in [-1.70, 1.70]:
		Kit.box(self, at + Vector3(shift, 1.75, -.09), Vector3(.13, 3.5, .16), Color("#7f6956"))
	Kit.box(self, at + Vector3(0, 3.0, 0), Vector3(4.64, 1.39, .28), Color("#a75748"))
	Kit.box(self, at + Vector3(0, 3.6, .18), Vector3(4.36, .046, .06), WALL_TRIM)
	Art.sign(self, at + Vector3(0, 3.10, .174), title, .285, WALL_TRIM)

func gantry(at: Vector3) -> void:
	for x in [-3.6, 3.6]:
		Kit.box(self, at + Vector3(x,3.7,0), Vector3(.42,7.4,.49), Color("#bf8657"))
		Kit.box(self, at + Vector3(x,.2,0), Vector3(.66,.39,1.45), Color("#52676c"))
	Kit.box(self, at + Vector3(0,7.02,0), Vector3(7.91,.54,.67), Color("#c8935e"))
	Kit.box(self, at + Vector3(1.2,6.65,.38), Vector3(1.25,.67,.95), Color("#67818a"))
	Kit.box(self, at + Vector3(-1.1,5.1,.16), Vector3(.044,3.35,.052), Color("#4c5b5d"))
