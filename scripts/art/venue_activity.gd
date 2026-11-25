extends Node3D

const Art = preload("res://scripts/art/visual_library.gd")
const Kit = preload("res://scripts/buildings/model_kit.gd")
const Campus = preload("res://scripts/buildings/roadside_campus.gd")
const Vehicle = preload("res://scenes/vehicles/compact.tscn")
const Actor = preload("res://scripts/customers/customer_manager.gd")
const VAN_STOP := Vector3(-2.16, 0.03, -7.94)
const VAN_START := Vector3(0.90, 0.03, -8.13)
const UNLOAD_AT := Vector3(-2.95, 0.04, -7.47)
const STOCK_AT := Vector3(-4.00, 0.04, -6.65)

var door: Node3D
var spray: Node3D
var door_progress := 0.0
var elapsed := -1.0
var van: Node3D
var courier: Actor
var stack: Node3D

func _ready() -> void:
	door = Art.place(self, "architecture", "workshop_shutter", Campus.WORKSHOP_AT)
	door.hide()
	spray = Node3D.new()
	add_child(spray)
	var beam := Kit.cylinder(spray, Vector3.ZERO, 0.053, 0.053, 2.08, Color("#89a49b"), 12)
	beam.rotation.z = PI * 0.5
	for x in [-.72, 0.0, .72]:
		Kit.box(spray, Vector3(x, -0.054, 0.012), Vector3(.11, .07, .12), Color("#53a59b"))
	spray.hide()

func service_activity(dispatch: HbtDispatch, delta: float) -> void:
	var visit := dispatch.visit_at("workshop", 0)
	var open := visit != null and visit.phase in [
		HbtVisit.Phase.APPROACH, HbtVisit.Phase.READY, HbtVisit.Phase.WORKING, HbtVisit.Phase.EXIT_WAIT, HbtVisit.Phase.DEPART]
	door_progress = move_toward(door_progress, float(open), delta * 1.9)
	var scale_y := 1.0 - smoothstep(0.0, 1.0, door_progress) * 0.92
	door.scale.y = scale_y
	door.position.y = Campus.WORKSHOP_AT.y + (1.0 - scale_y) * 2.31
	door.visible = dispatch.economy.level("workshop") > 0
	var wash := dispatch.visit_at("wash", 0)
	spray.visible = wash != null and wash.phase == HbtVisit.Phase.WORKING
	if spray.visible:
		spray.position = wash.location + Vector3(0, 1.84, sin(wash.progress() * TAU) * 0.61)

func on_shop_sale(total: int, night: bool) -> void:
	if posmod(total, 5) != 1 or elapsed >= 0.0:
		return
	elapsed = 0.0
	van = Vehicle.instantiate()
	van.position = VAN_START
	van.rotation.y = -PI * 0.5
	add_child(van)
	van.build("parcel", 1)
	van.set_night(night)

func move_delivery(delta: float) -> void:
	if elapsed < 0.0:
		return
	elapsed += delta
	var previous := van.position
	if elapsed < 1.28:
		van.position = VAN_START.lerp(VAN_STOP, smoothstep(0.0, 1.28, elapsed))
	elif elapsed < 5.34:
		if not is_instance_valid(courier):
			courier = Actor.new()
			courier.role = "cashier"
			courier.position = UNLOAD_AT
			add_child(courier)
			courier.attach_prop("Crate")
		var outgoing := elapsed >= 3.29
		var next := STOCK_AT if not outgoing else UNLOAD_AT
		var shift := next - courier.position
		courier.position = courier.position.move_toward(next, 1.42 * delta)
		if shift.length_squared() > 0.004:
			courier.rotation.y = atan2(shift.x, shift.z)
			courier.play("walk" if outgoing else "carry")
		else:
			courier.play("service" if not outgoing else "idle")
		if outgoing and courier.prop.visible:
			courier.prop.hide()
			if is_instance_valid(stack):
				stack.queue_free()
			stack = Art.place(self, "landscape", "parcel_carton", STOCK_AT + Vector3(0, 0.08, 0), .43)
	else:
		if is_instance_valid(courier):
			courier.queue_free()
			courier = null
		van.position = VAN_STOP.lerp(VAN_START, smoothstep(5.34, 6.70, elapsed))
	van.spin(van.position.distance_to(previous))
	van.update_signals(previous == van.position, 0, delta)
	if elapsed >= 6.70:
		van.queue_free()
		van = null
		elapsed = -1.0
