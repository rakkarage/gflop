@tool
class_name QuadFace extends QuadInput

@export var _speed: float = 5.0

var target: Vector3 = Vector3.ZERO
var face := true

func _process(_delta: float) -> void:
	if face:
		var direction := (target - global_position).normalized()
		rotation = rotation.slerp(Vector3(asin(-direction.y), atan2(direction.x, direction.z), 0), _speed * _delta)
