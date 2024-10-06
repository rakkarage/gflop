@tool
class_name QuadFace extends QuadInput

const SPEED: float = 5.0

var target: Vector3 = Vector3.ZERO
var face := true

func _process(delta: float) -> void:
	if face:
		var direction := (target - global_position).normalized()
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), SPEED * delta)
