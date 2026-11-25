extends Node3D

signal arrived

const Art = preload("res://scripts/art/visual_library.gd")
const Clips = preload("res://scripts/art/character_clips.gd")
const ROLE_PROPS := {"driver": "Nozzle", "attendant": "Nozzle", "wash_worker": "Mop", "mechanic": "Spanner", "server": "Tray", "manager": "Clipboard", "ada": "Clipboard", "iga": "Clipboard",
	"maks": "Clipboard", "mira": "Clipboard", "leon": "Clipboard"}

@export var role := "driver"

var skeleton: Skeleton3D
var animation := AnimationPlayer.new()
var prop: BoneAttachment3D
var cycles := ""
var gait_route: Array[Vector3] = []
var gait_index := 1
var pace := 1.14
var looping_walk := true

func _ready() -> void:
	var visual := Art.place(self, "characters", role)
	visual.scale = Vector3(1.055, 1.095, 1.055)
	skeleton = visual.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	skeleton.add_child(animation)
	animation.root_node = NodePath("..")
	animation.add_animation_library("", Clips.library(skeleton))
	Art.contact(self, Vector3(0, 0.020, 0), 0.99, 0.89)
	if ROLE_PROPS.has(role):
		attach_prop(ROLE_PROPS[role])
	play("idle")

func attach_prop(key: String) -> void:
	prop = BoneAttachment3D.new()
	prop.bone_name = "hand_l"
	skeleton.add_child(prop)
	var utensil := MeshInstance3D.new()
	utensil.mesh = Art.extract_mesh("characters", "hand_props", key)
	utensil.position = Vector3(0.005, -0.028, 0.087)
	if key == "Tray":
		utensil.rotation.x = PI * 0.48
	prop.add_child(utensil)
	prop.visible = key != "Nozzle"

func play(clip: String, blend := 0.12) -> void:
	if cycles == clip:
		return
	cycles = clip
	animation.play(clip, blend)
	if role in ["driver", "attendant"] and is_instance_valid(prop):
		prop.visible = clip == "fuel"

func configure_walk(points: Array[Vector3], clip := "walk", speed := 1.10, loop := true) -> void:
	gait_route = points
	gait_index = 1
	looping_walk = loop
	position = points[0]
	pace = speed
	play(clip)

func _process(delta: float) -> void:
	if gait_route.is_empty():
		return
	var target := gait_route[gait_index]
	var along := target - position
	if along.length_squared() < 0.009:
		gait_index += 1
		if gait_index == gait_route.size():
			if looping_walk:
				gait_index = 0
			else:
				gait_route.clear()
				play("idle")
				arrived.emit()
		return
	rotation.y = lerp_angle(rotation.y, atan2(along.x, along.z), minf(1.0, delta * 8.0))
	position = position.move_toward(target, delta * pace)

func represent_service(waiting: bool, serving: bool, _delta: float) -> void:
	visible = waiting or serving
	if visible:
		play("fuel" if serving else "service")

func pose_at(clip: String, time: float) -> void:
	if cycles != clip:
		play(clip, 0.0)
	animation.seek(time, true)
	animation.advance(0)
