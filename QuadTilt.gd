extends QuadInput

@export var _tilt_range: float = 0.022
@export var _tilt_speed: float = 5.0

var _initial_rotation: Quaternion
var _tilt := Vector2.ZERO

func _ready() -> void:
	super._ready()
	_initial_rotation = global_transform.basis.get_rotation_quaternion()

func _process(delta: float) -> void:
	var viewport := get_viewport()
	var viewport_size: Vector2 = viewport.size
	var half_size := viewport_size * 0.5

	var normalized := (viewport.get_mouse_position() - half_size) / half_size
	normalized.x = clamp(normalized.x, -1.0, 1.0)
	normalized.y = clamp(normalized.y, -1.0, 1.0)

	_tilt = _tilt.lerp(normalized, delta * _tilt_speed)

	var yaw := Quaternion(Vector3.UP, _tilt.x).normalized()
	var pitch := Quaternion(Vector3.RIGHT, _tilt.y).normalized()
	var tilt_rotation := (yaw * pitch).normalized()

	global_transform.basis = Basis(_initial_rotation.slerp(tilt_rotation, _tilt_range).normalized())
