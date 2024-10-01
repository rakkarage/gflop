@tool
class_name QuadFace extends QuadInput

@export var _rotation_speed: float = 5.0
@export var _look_at_target: Vector3 = Vector3.ZERO

var _face_camera := true

func _process(_delta: float) -> void:
	if _face_camera:
		var direction = (_look_at_target - global_position).normalized()
		rotation = rotation.slerp(Vector3(asin(-direction.y), atan2(direction.x, direction.z), 0), _rotation_speed * _delta)
