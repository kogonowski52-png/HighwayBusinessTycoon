extends Node3D
## The yard follows dispatch tickets. There is no visual shipment before a reserved operation.

const Art = preload("res://scripts/art/visual_library.gd")
const Kit = preload("res://scripts/buildings/model_kit.gd")
const Phase = HbtVisit.Phase

var service: String
var kind: String
var bays: Array[Dictionary] = []

func _init(id: String, task: String) -> void:
	service = id
	kind = task

func assemble(routes: RefCounted) -> void:
	var count: int = routes.layout.plots[service][4]
	var origin: Vector3 = routes.origin(service)
	for index in count:
		var spot: Vector3 = routes.position_of(service, index) - origin
		var pieces := {"spot": spot}
		if kind == "wash":
			pieces["pair"] = []
			var width := 1.46 if routes.lane_of(service) == "truck" else 1.10
			for side in [-1, 1]:
				var brush := Art.place(self, "architecture", "wash_brush", spot + Vector3(side * width, 1.29, -.63))
				brush.scale.y = 1.34 if routes.lane_of(service) == "truck" else .93
				brush.hide()
				pieces.pair.append(brush)
		elif kind in ["freight", "cold"]:
			var unit := Art.place(self, "landscape", "parcel_carton", spot)
			unit.scale = Vector3.ONE * 1.94
			unit.hide()
			pieces["load"] = unit
			var carriage := Kit.box(self, spot + Vector3(0, 3.75, -2.54), Vector3(1.28, .21, .81), Color("#d29351"))
			carriage.hide()
			pieces["carriage"] = carriage
		elif kind == "repair":
			var lift := Kit.box(self, spot + Vector3(0, .10, -1.82), Vector3(1.76, .16, .47), Color("#b5724e"))
			pieces["lift"] = lift
		else:
			var lamp := Kit.box(self, spot + Vector3(.81, 1.16, -.79), Vector3(.26, .12, .14), Color("#aec4a7"))
			pieces["lamp"] = lamp
		bays.append(pieces)

func advance(dispatch: HbtDispatch) -> void:
	for index in bays.size():
		var info := bays[index]
		var enabled := dispatch.economy.capacity(service) > index
		var ticket := dispatch.visit_at(service, index)
		var working := enabled and ticket != null and ticket.phase == Phase.WORKING 			and ticket.walked >= ticket.foot_length
		var progress := ticket.progress() if working else 0.0
		var at: Vector3 = info.spot
		match kind:
			"wash":
				for brush: Node3D in info.pair:
					brush.visible = working
					if working:
						brush.rotation.y = progress * TAU * 12.0
						brush.position.z = at.z + lerpf(-1.65, 1.0, sin(progress * PI))
			"freight", "cold":
				var moving := working and ticket.trade in ["inbound", "outbound"]
				info.load.visible = moving
				info.carriage.visible = moving
				if moving:
					var deck: Vector3 = at + Vector3(.06, 1.02, 1.80)
					var floor: Vector3 = at + Vector3(-.91, .39, -2.76)
					var share := smoothstep(.10, .94, progress)
					var actual := deck.lerp(floor, share) if ticket.trade == "inbound" else floor.lerp(deck, share)
					actual.y += sin(share * PI) * 2.53
					info.load.position = actual
					info.carriage.position = Vector3(actual.x, maxf(3.65, actual.y + .80), actual.z)
			"repair":
				info.lift.visible = enabled
				if enabled:
					info.lift.position.y = .11 + sin(progress * PI) * .27
			_:
				info.lamp.visible = enabled and working

func active_ticket(dispatch: HbtDispatch) -> HbtVisit:
	return dispatch.first_at(service, Phase.WORKING)
