@tool
extends QuadInput

const RANGE := 0.022
const SPEED := 5.0

var _initial := Quaternion.IDENTITY
var _tilt := Vector2.ZERO

func _process(delta: float) -> void:
	var viewport := get_viewport()
	var viewport_size: Vector2 = viewport.size
	var half_size := viewport_size * 0.5

	var normalized := (viewport.get_mouse_position() - half_size) / half_size
	normalized = normalized.clamp(Vector2(-1.0, -1.0), Vector2(1.0, 1.0))

	_tilt = _tilt.lerp(normalized, delta * SPEED)

	var yaw := Quaternion(Vector3.UP, _tilt.x).normalized()
	var pitch := Quaternion(Vector3.RIGHT, _tilt.y).normalized()
	var tilt_rotation := (yaw * pitch).normalized()

	global_transform.basis = Basis(_initial.slerp(tilt_rotation, RANGE).normalized())
