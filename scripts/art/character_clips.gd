extends RefCounted

const DURATIONS := {
	"idle": 2.84, "walk": 0.94, "run": 0.71, "service": 2.34, "fuel": 1.72,
	"clean": 1.84, "repair": 1.48, "cash": 1.66, "carry": 1.05, "exit_car": 0.51,
}

static var shared: AnimationLibrary

static func library(skeleton: Skeleton3D) -> AnimationLibrary:
	if shared != null:
		return shared
	shared = AnimationLibrary.new()
	for clip in DURATIONS:
		var animation := Animation.new()
		animation.length = DURATIONS[clip]
		animation.loop_mode = Animation.LOOP_NONE if clip == "exit_car" else Animation.LOOP_LINEAR
		var samples: Array[Dictionary] = []
		for i in range(25):
			samples.append(pose(clip, TAU * i / 24.0))
		for bone in range(skeleton.get_bone_count()):
			var name := skeleton.get_bone_name(bone)
			var rest := skeleton.get_bone_rest(bone)
			var bone_path := NodePath(".:" + name)
			var rotation := animation.add_track(Animation.TYPE_ROTATION_3D)
			animation.track_set_path(rotation, bone_path)
			for i in range(samples.size()):
				var angles: Vector3 = samples[i].get(name, Vector3.ZERO)
				var key_time: float = animation.length * i / 24.0
				animation.rotation_track_insert_key(rotation, key_time,
					rest.basis.get_rotation_quaternion() * Quaternion.from_euler(angles * PI / 180.0))
			if name == "pelvis":
				var position := animation.add_track(Animation.TYPE_POSITION_3D)
				animation.track_set_path(position, bone_path)
				for i in range(samples.size()):
					var bounce: float = samples[i].get("bounce", 0.0)
					var balance: float = samples[i].get("balance", 0.0)
					animation.position_track_insert_key(position, animation.length * i / 24.0,
						rest.origin + Vector3(balance, bounce, 0))
		shared.add_animation(clip, animation)
	return shared

static func pose(clip: String, phase: float) -> Dictionary:
	var wave := sin(phase)
	var opposite := cos(phase)
	var angles := {
		"spine": Vector3(2.0 + 1.9 * wave, 2.1 * opposite, 1.3 * wave),
		"head": Vector3(-1.2 * wave, 3.0 * opposite, -2.2 * wave),
		"arm_l": Vector3(-4.8 + 2.3 * wave, 0, 4.0),
		"arm_r": Vector3(-3.7 - 2.4 * wave, 0, -4.0),
		"elbow_l": Vector3(-9, 0, 0), "elbow_r": Vector3(-7, 0, 0),
	}
	if clip in ["walk", "run", "carry"]:
		var stride := 39.0 if clip == "run" else 24.0
		angles["leg_l"] = Vector3(stride * wave, 0, 0)
		angles["leg_r"] = Vector3(-stride * wave, 0, 0)
		angles["knee_l"] = Vector3(maxf(0.0, opposite) * 43.0, 0, 0)
		angles["knee_r"] = Vector3(maxf(0.0, -opposite) * 43.0, 0, 0)
		angles["foot_l"] = Vector3(-maxf(0.0, opposite) * 11.0, 0, 0)
		angles["foot_r"] = Vector3(-maxf(0.0, -opposite) * 11.0, 0, 0)
		angles["bounce"] = (1.0 - cos(phase * 2.0)) * (0.048 if clip == "run" else 0.016)
		angles["balance"] = opposite * (0.031 if clip == "run" else 0.024)
		angles["spine"] = Vector3(13.0 if clip == "run" else 4.0, 6.5 * wave, 3.3 * wave)
		angles["arm_l"] = Vector3(-20.0 * wave, 0, 5.0)
		angles["arm_r"] = Vector3(20.0 * wave, 0, -5.0)
		if clip == "run":
			angles["elbow_l"] = Vector3(-63, 0, 0)
			angles["elbow_r"] = Vector3(-63, 0, 0)
		elif clip == "carry":
			angles["arm_l"] = Vector3(-25, -2, 3)
			angles["elbow_l"] = Vector3(-68, 0, 0)
			angles["elbow_r"] = Vector3(-16, 0, 0)
		return angles
	match clip:
		"exit_car":
			var lift := smoothstep(0.0, 4.8, phase)
			var remaining := 1.0 - lift
			angles["bounce"] = -0.27 * remaining
			angles["balance"] = -0.11 * remaining
			angles["spine"] = Vector3(30.0 * remaining, -18.0 * remaining, 14.0 * remaining)
			angles["leg_l"] = Vector3(-41.0 * remaining, 9.0 * remaining, 0.0)
			angles["knee_l"] = Vector3(64.0 * remaining, 0, 0)
			angles["leg_r"] = Vector3(-17.0 * remaining, 0, 0)
			angles["knee_r"] = Vector3(38.0 * remaining, 0, 0)
			angles["arm_r"] = Vector3(-49.0 * remaining, 14.0 * remaining, 4.0)
			angles["elbow_r"] = Vector3(-32.0 * remaining, 0, 0)
		"idle":
			angles["bounce"] = 0.012 + 0.012 * wave
			angles["head"] = Vector3(-1.9 * wave, 4.7 * opposite, 1.9 * wave)
		"service":
			var greet := smoothstep(-0.37, 0.96, wave)
			angles["balance"] = 0.029 * greet
			angles["arm_r"] = Vector3(-28 - 48 * greet, -8, -10)
			angles["elbow_r"] = Vector3(-62, 0, -17.0 * opposite)
			angles["hand_r"] = Vector3(8.0 * wave, 12.5 * opposite, 0)
			angles["head"] = Vector3(-2.0, opposite * 8.0, 3.0 * wave)
		"fuel":
			angles["spine"] = Vector3(8.0 + 1.60 * opposite, -4, -5)
			angles["bounce"] = -0.030 + wave * 0.012
			angles["balance"] = 0.032 + wave * 0.016
			angles["leg_l"] = Vector3(-6, 0, 2)
			angles["knee_l"] = Vector3(11, 0, 0)
			angles["leg_r"] = Vector3(4, 0, -3)
			angles["head"] = Vector3(14, -5, -3.2 * wave)
			angles["arm_l"] = Vector3(-37 - 3.4 * wave, -10, 5)
			angles["elbow_l"] = Vector3(-47 + 4.5 * wave, 4, 2)
			angles["hand_l"] = Vector3(15 + 4.0 * opposite, -2, 0)
			angles["arm_r"] = Vector3(-7, 0, -13)
		"clean":
			angles["spine"] = Vector3(12, 12.5 * wave, 5.0 * wave)
			angles["arm_l"] = Vector3(-38 + 21 * wave, -19 + 14 * opposite, 6)
			angles["elbow_l"] = Vector3(-31 + 18 * opposite, 0, -12)
			angles["arm_r"] = Vector3(-37 - 19 * wave, 16, -11)
			angles["elbow_r"] = Vector3(-46, 6, 9)
			angles["head"] = Vector3(14, 10 * wave, 0)
		"repair":
			angles["spine"] = Vector3(19 + 5.3 * wave, -6, 1.8 * wave)
			angles["arm_l"] = Vector3(-54 + 11.0 * wave, -12, 6.5)
			angles["elbow_l"] = Vector3(-55 - 18.0 * wave, 0, 5.0 * opposite)
			angles["hand_l"] = Vector3(3, 25 * wave, 14 * opposite)
			angles["arm_r"] = Vector3(-51, 8, -7)
			angles["elbow_r"] = Vector3(-29, 0, 0)
			angles["leg_l"] = Vector3(-10, 0, 0)
			angles["knee_l"] = Vector3(16, 0, 0)
			angles["bounce"] = -0.065
		"cash":
			angles["head"] = Vector3(15 - 5 * wave, 7.7 * wave, 0)
			angles["arm_l"] = Vector3(-44, -11 - 12 * wave, 7)
			angles["arm_r"] = Vector3(-49, 18 + 9.5 * wave, -5)
			angles["elbow_l"] = Vector3(-68 + 13 * wave, 0, 2)
			angles["elbow_r"] = Vector3(-64 - 15 * wave, 0, 6)
	return angles
