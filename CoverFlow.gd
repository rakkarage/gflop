@tool
extends Node3D

@onready var _camera: Camera3D = $Camera3D
@onready var _ray: RayCast3D = $Camera3D/RayCast3D
@onready var _mask: MeshInstance3D = $Mask
@onready var _mask_back: Button = $Mask/SubViewport/Interface/Panel/Margin/VBox/HBox/Back
@onready var _scroll_bar: HScrollBar = $Mask/SubViewport/Interface/Panel/Margin/VBox/HBox/HScrollBar
@onready var _mask_fore: Button = $Mask/SubViewport/Interface/Panel/Margin/VBox/HBox/Fore
@onready var _mask_area: Area3D = $Mask/Area3D
@onready var _mask_children: Node3D = $Mask/Children

@export var _child_count := 10
@export var _child_scene: PackedScene:
	set(value):
		_child_scene = value
		update_configuration_warnings()

const _ray_length := 100.0
const _offset_x := 0.22
const _offset_z := 0.333
const _offset_depth := 0.0333

func _ready() -> void:
	_mask_back.pressed.connect(_on_back_pressed)
	_mask_fore.pressed.connect(_on_fore_pressed)
	_scroll_bar.value_changed.connect(_on_scroll_bar_value_changed)
	_generate_children.call_deferred()
	_update_scroll_bar()
	_on_scroll_bar_value_changed(0)

func _process(_delta: float) -> void:
	for child in _mask_children.get_children():
		var mat: ShaderMaterial = child.get_surface_override_material(0)
		if mat:
			mat.set_shader_parameter("mask_transform", _mask.global_transform)
			mat.set_shader_parameter("mask_size", _mask.mesh.size)

func _generate_children() -> void:
	if _child_scene == null:
		print_debug("CoverFlow: No child scene to instantiate.")
		return
	for i in range(_child_count):
		var child := _child_scene.instantiate() as QuadFace
		_mask_children.add_child(child)
		child._look_at_target = _camera.global_position
		_set_child_position(child, i, _scroll_bar.value)
		child.get_node("SubViewport/Interface/Panel/Margin/VBox/HBoxTop/Top").pressed.connect(_on_Top_pressed)
		child.get_node("SubViewport/Interface/Panel/Margin/VBox/HBoxBottom/Bottom").pressed.connect(_on_Bottom_pressed)

func _scroll_children(value: float) -> void:
	for i in range(_mask_children.get_child_count()):
		_set_child_position(_mask_children.get_child(i), i, value)

func _set_child_position(child: QuadFace, index: int, value: float) -> void:
	child.global_position = Vector3((index - value) * _offset_x, 0, _offset_z + (-abs(index - value) * _offset_depth))

func _update_scroll_bar() -> void:
	_scroll_bar.max_value = _child_count
	_scroll_bar.page = 1

func _on_scroll_bar_value_changed(value: float) -> void:
	_scroll_children(value)
	_mask_back.disabled = value == 0
	_mask_fore.disabled = value >= _scroll_bar.max_value - 1

func _on_back_pressed() -> void:
	_scroll_bar.value = max(0, _scroll_bar.value - 1)

func _on_fore_pressed() -> void:
	_scroll_bar.value = min(_scroll_bar.max_value, _scroll_bar.value + 1)

func _on_Top_pressed() -> void:
	print("Top")

func _on_Bottom_pressed() -> void:
	print("Bottom")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		for i in range(_mask_children.get_child_count()):
			var child := _mask_children.get_child(i) as QuadFace
			child._is_mouse_inside_mask = _is_mouse_inside_mask()

func _is_mouse_inside_mask() -> bool:
	_ray.target_position = _ray.global_position + _camera.project_ray_normal(_camera.get_viewport().get_mouse_position()) * _ray_length
	_ray.force_raycast_update()
	return _ray.is_colliding() and _ray.get_collider() == _mask_area

func _get_configuration_warnings() -> PackedStringArray:
	if _child_scene == null:
		return ["No child scene to instantiate."]
	else:
		return []
