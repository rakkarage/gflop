@tool
class_name Pool extends Node

@export var _size := 21
@export var _scene: PackedScene:
	set(value):
		_scene = value
		update_configuration_warnings()

var _pool: Array[Node] = []

func _ready() -> void:
	if _scene == null:
		print_debug("Pool: No scene to instantiate.")
		return
	for i in range(_size):
		var child := _scene.instantiate()
		add_child(child)
		child.name = str(i)
		child.visible = false
		_pool.append(child)

func enter() -> Node:
	var child: Node
	if not _pool.is_empty():
		child = _pool.pop_back()
	else:
		print_debug("Pool: Empty, creating new instance.")
		child = _scene.instantiate()
		add_child(child)
	child.visible = true
	return child

func exit(child: Node) -> void:
	child.visible = false
	_pool.append(child)

func _get_configuration_warnings() -> PackedStringArray:
	if _scene == null:
		return ["No scene to instantiate."]
	else:
		return []
