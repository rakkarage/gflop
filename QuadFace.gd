@tool
class_name QuadFace extends QuadInput

const SPEED := 5.0

var face := true
var target := Vector3.ZERO

func _process(delta: float) -> void:
	if face:
		var direction := (target - global_position).normalized()
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), SPEED * delta)
