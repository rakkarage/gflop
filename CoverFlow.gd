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

const RAY_LENGTH := 100.0
const OFFSET_X := 0.22
const OFFSET_Z := 0.333
const OFFSET_DEPTH := 0.0333

const TWEEN_TIME := 0.333

const MOMENTUM_FACTOR := -100.0
const MOMENTUM_FRICTION := 0.9
const MOMENTUM_THRESHOLD := 0.001

const MOVE_TIME_THRESHOLD := 100

var _current := 0.0
var _dragging := false
var _drag_velocity := 0.0
var _last_mouse_position := Vector2()
var _last_move_time := 0.0
var _momentum := 0.0
var _snap := false
var _tween: Tween

func _ready() -> void:
	_mask_back.pressed.connect(_on_back_pressed)
	_mask_fore.pressed.connect(_on_fore_pressed)
	_scroll_bar.value_changed.connect(_on_scroll_bar_value_changed)
	_generate_children.call_deferred()
	_update_scroll_bar()
	_on_scroll_bar_value_changed(0)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragging = true
				_last_mouse_position = event.position
				_last_move_time = Time.get_ticks_msec()
				_momentum = 0.0
			else:
				_dragging = false
				var current_time = Time.get_ticks_msec()
				if current_time - _last_move_time > MOVE_TIME_THRESHOLD:
					_drag_velocity = 0.0
				_momentum = _drag_velocity * MOMENTUM_FACTOR
	elif event is InputEventMouseMotion:
		if _dragging:
			var delta = event.position - _last_mouse_position
			if abs(delta.x) < MOMENTUM_THRESHOLD:
				_drag_velocity = 0.0
			else:
				_drag_velocity = delta.x / get_viewport().size.x * _child_count
			_drag_to(_current - _drag_velocity)
			_last_mouse_position = event.position
			_last_move_time = Time.get_ticks_msec()
		for i in range(_mask_children.get_child_count()):
			var child := _mask_children.get_child(i) as QuadFace
			child._is_mouse_inside_mask = _is_mouse_inside_mask()

func _process(delta: float) -> void:
	for child in _mask_children.get_children():
		var mat: ShaderMaterial = child.get_surface_override_material(0)
		if mat:
			mat.set_shader_parameter("mask_transform", _mask.global_transform)
			mat.set_shader_parameter("mask_size", _mask.mesh.size)
	if not _dragging:
		if abs(_momentum) > MOMENTUM_THRESHOLD:
			_drag_to(_current + _momentum * delta)
			_momentum *= MOMENTUM_FRICTION
		else:
			if _snap:
				_snap = false
				_momentum = 0.0
				_ease_to(clamp(roundi(_current), 0, _child_count - 1))
	else:
		if abs(_drag_velocity) > MOMENTUM_THRESHOLD:
			_snap = true

# disables mouse input when the mouse is outside the mask, so only the visible parts of controls are interactive
func _is_mouse_inside_mask() -> bool:
	_ray.target_position = _ray.global_position + _camera.project_ray_normal(_camera.get_viewport().get_mouse_position()) * RAY_LENGTH
	_ray.force_raycast_update()
	return _ray.is_colliding() and _ray.get_collider() == _mask_area

func _generate_children() -> void:
	if _child_scene == null:
		print_debug("CoverFlow: No child scene to instantiate.")
		return
	for i in range(_child_count):
		var child := _child_scene.instantiate() as QuadFace
		_mask_children.add_child(child)
		child._look_at_target = _camera.global_position
		_set_child_position(child, i, _scroll_bar.value)
		child.get_node("SubViewport/Interface/Panel/Margin/Button").pressed.connect(_on_Child_pressed.bind(child))

func _get_child_position(index: int, value: float) -> Vector3:
	return Vector3((index - value) * OFFSET_X, 0, OFFSET_Z + (-abs(index - value) * OFFSET_DEPTH))

func _set_child_position(child: QuadFace, index: int, value: float) -> void:
	child.global_position = _get_child_position(index, value)

func _update_scroll_bar() -> void:
	_scroll_bar.max_value = _child_count
	_scroll_bar.page = 1

func _on_scroll_bar_value_changed(value: float) -> void:
	_drag_to(value)

func _on_back_pressed() -> void:
	Audio.click()
	_momentum = 0
	_ease_to(roundi(_current) - 1)

func _on_fore_pressed() -> void:
	Audio.click()
	_momentum = 0
	_ease_to(roundi(_current) + 1)

func _on_Child_pressed(child) -> void:
	Audio.click()
	child._face_camera = false
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)
	tween.tween_property(child, "global_rotation:y", child.global_rotation.y + deg_to_rad(360), TWEEN_TIME)
	tween.tween_callback(func() -> void: child._face_camera = true)

func _get_configuration_warnings() -> PackedStringArray:
	if _child_scene == null:
		return ["No child scene to instantiate."]
	else:
		return []

func _ease_to(target: int) -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)
	_tween.tween_method(_drag_to, _current, target, TWEEN_TIME)

func _drag_to(value: float) -> void:
	_current = value
	for i in range(_mask_children.get_child_count()):
		_set_child_position(_mask_children.get_child(i), i, _current)
	_update_scroll_status(_current)

func _update_scroll_status(value: float) -> void:
	_scroll_bar.set_value_no_signal(value)
	_mask_back.disabled = value <= 0
	_mask_fore.disabled = value >= _child_count - 1
