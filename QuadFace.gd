@tool
class_name QuadFace extends QuadInput

@export var face_speed: float = 5.0

var target: Vector3 = Vector3.ZERO
var face := true

func _process(_delta: float) -> void:
	if face:
		var direction := (target - global_position).normalized()
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), face_speed * _delta)
