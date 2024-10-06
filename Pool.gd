@tool
class_name Pool extends Node

@export var size := 21
@export var scene: PackedScene:
	set(value):
		scene = value
		update_configuration_warnings()

var _pool: Array[Node] = []

func _ready() -> void:
	if scene == null:
		push_warning("Pool: No scene to instantiate.")
		return
	for i in size:
		var child := scene.instantiate()
		add_child(child)
		child.name = str(i)
		child.visible = false
		_pool.append(child)

func enter() -> Node:
	var child: Node
	if _pool.is_empty():
		push_warning("Pool: Empty, creating new instance.")
		child = scene.instantiate()
		add_child(child)
	else:
		child = _pool.pop_back()
	child.visible = true
	return child

func exit(child: Node) -> void:
	child.visible = false
	_pool.append(child)

func _get_configuration_warnings() -> PackedStringArray:
	return ["No scene to instantiate."] if not scene else []
