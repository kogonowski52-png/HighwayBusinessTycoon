extends RefCounted
## The game uses an orthogonal camera. Margins keep wheels, props and shadows active just beyond its edges.

var to_camera := Transform3D.IDENTITY
var bounds := Vector2.ZERO
var near_plane := 0.0
var far_plane := INF
var enabled := false

func update(camera: Camera3D) -> void:
	if not is_instance_valid(camera) or camera.projection != Camera3D.PROJECTION_ORTHOGONAL:
		enabled = false
		return
	var size := camera.get_viewport().get_visible_rect().size
	var aspect := maxf(.1, size.aspect())
	var radius := camera.size * .5
	bounds = Vector2(radius, radius / aspect) if camera.keep_aspect == Camera3D.KEEP_WIDTH else Vector2(radius * aspect, radius)
	to_camera = camera.global_transform.affine_inverse()
	near_plane = camera.near
	far_plane = camera.far
	enabled = true

func sees(at: Vector3, margin: float) -> bool:
	if not enabled:
		return true
	var p := to_camera * at
	return absf(p.x) <= bounds.x + margin and absf(p.y) <= bounds.y + margin \
		and -p.z >= near_plane - margin and -p.z <= far_plane + margin
