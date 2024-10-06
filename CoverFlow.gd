@tool
extends Node3D

@onready var _camera: Camera3D = $Camera3D
@onready var _ray: RayCast3D = $Camera3D/RayCast3D
@onready var _mask: MeshInstance3D = $Mask
@onready var _mask_back: Button = $Mask/SubViewport/Interface/Panel/Margin/VBox/HBox/Back
@onready var _scroll_bar: HScrollBar = $Mask/SubViewport/Interface/Panel/Margin/VBox/HBox/HScrollBar
@onready var _mask_fore: Button = $Mask/SubViewport/Interface/Panel/Margin/VBox/HBox/Fore
@onready var _mask_area: Area3D = $Mask/Area3D
@onready var _pool: Pool = $Mask/Pool

@export var child_count := 5000000

const RAY_LENGTH := 100.0
const OFFSET_X := 0.22
const OFFSET_Z := 0.333
const OFFSET_DEPTH := 0.0333
const TWEEN_TIME := 0.333
const MOMENTUM_FACTOR := -100.0
const MOMENTUM_FRICTION := 0.9
const MOMENTUM_THRESHOLD := 0.001
const MOVE_TIME_THRESHOLD := 0.1
const CLICK_THRESHOLD := 1
const VISIBLE_RANGE := 10

var _current := 0.0
var _dragging := false
var _drag_velocity := 0.0
var _last_mouse_position := Vector2.ZERO
var _last_mouse_time := 0.0
var _momentum := 0.0
var _snap := false
var _tween: Tween
var _drag_factor: float
var _active_children: Dictionary = {}
var _click_position := Vector2.ZERO

func _ready() -> void:
	_mask_back.gui_input.connect(_on_back_input)
	_mask_fore.gui_input.connect(_on_fore_input)
	_scroll_bar.value_changed.connect(_drag_to)
	_scroll_bar.max_value = child_count
	_scroll_bar.page = 1
	_generate_children()
	_drag_to(0)
	var distance := _camera.global_position.distance_to(_mask.global_position)
	var width := 2.0 * distance * tan(deg_to_rad(_camera.fov * 0.5))
	_drag_factor = width / (get_viewport().size.x * OFFSET_X)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragging = true
				_last_mouse_position = event.global_position
				_last_mouse_time = Time.get_ticks_msec() / 1000.0
				_momentum = 0.0
			else:
				_dragging = false
				var current_time := Time.get_ticks_msec() / 1000.0
				if current_time - _last_mouse_time > MOVE_TIME_THRESHOLD:
					_drag_velocity = 0.0
				_momentum = _drag_velocity * MOMENTUM_FACTOR
	elif event is InputEventMouseMotion:
		if _dragging:
			var delta: Vector2 = event.global_position - _last_mouse_position
			if abs(delta.x) < MOMENTUM_THRESHOLD:
				_drag_velocity = 0.0
			else:
				_drag_velocity = delta.x * _drag_factor
			_drag_to(_current - _drag_velocity)
			_last_mouse_position = event.global_position
			_last_mouse_time = Time.get_ticks_msec() / 1000.0
		for child in _pool.get_children():
			child.is_mouse_inside_mask = _is_mouse_inside_mask()

func _process(delta: float) -> void:
	for child in _pool.get_children():
		var mat: ShaderMaterial = child.get_surface_override_material(0)
		if mat:
			mat.set_shader_parameter("mask_transform", _mask.global_transform)
			mat.set_shader_parameter("mask_size", _mask.mesh.size)
	if _dragging:
		if abs(_drag_velocity) > MOMENTUM_THRESHOLD:
			_snap = true
	else:
		if abs(_momentum) > MOMENTUM_THRESHOLD:
			_drag_to(_current + _momentum * delta)
			_momentum *= MOMENTUM_FRICTION
		else:
			if _snap:
				_snap = false
				_momentum = 0.0
				_ease_to(clamp(roundi(_current), 0, child_count - 1))

# disables mouse input when the mouse is outside the mask, so only the visible parts of controls are interactive
func _is_mouse_inside_mask() -> bool:
	_ray.target_position = _ray.global_position + _camera.project_ray_normal(_camera.get_viewport().get_mouse_position()) * RAY_LENGTH
	_ray.force_raycast_update()
	return _ray.is_colliding() and _ray.get_collider() == _mask_area

# get node from pool and add it to active children
func enter(index: int) -> void:
	var child := _pool.enter()
	child.target = _camera.global_position
	child.get_node("SubViewport/Interface/Panel/Margin/Panel").gui_input.connect(_on_child_gui_input.bind(child))
	child.get_node("SubViewport/Interface/Panel/Margin/Panel/LabelTop").text = "%02x" % index
	child.get_node("SubViewport/Interface/Panel/Margin/Panel/LabelMiddle").text = "%02x" % index
	child.get_node("SubViewport/Interface/Panel/Margin/Panel/LabelBottom").text = "%02x" % index
	_active_children[index] = child

# return node to pool and remove it from active children
func exit(index: int) -> void:
	var child: Node = _active_children[index]
	child.get_node("SubViewport/Interface/Panel/Margin/Panel").gui_input.disconnect(_on_child_gui_input.bind(child))
	_active_children.erase(index)
	_pool.exit(child)

func _generate_children() -> void:
	for i in range(-VISIBLE_RANGE, VISIBLE_RANGE + 1):
		var index := i + roundi(_current)
		if index >= 0 and index < child_count:
			enter(index)

func _on_back_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventKey and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE)):
		if event.is_pressed():
			Audio.click()
			_momentum = 0
			_ease_to(roundi(_current) - 1)

func _on_fore_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventKey and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE)):
		if event.is_pressed():
			Audio.click()
			_momentum = 0
			_ease_to(roundi(_current) + 1)

func _on_child_gui_input(event: InputEvent, child: Node) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_click_position = event.global_position
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var distance = _click_position.distance_to(event.global_position)
			if distance < CLICK_THRESHOLD:
				Audio.click()
				child.face = false
				var tween := create_tween()
				tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)
				tween.tween_property(child, "global_rotation:y", child.global_rotation.y + deg_to_rad(360), TWEEN_TIME)
				tween.tween_callback(func() -> void: child.face = true)

func _ease_to(target: int) -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)
	_tween.tween_method(_drag_to, _current, target, TWEEN_TIME)

func _drag_to(target: float) -> void:
	_current = target
	var center := roundi(_current)
	var visible_start := center - VISIBLE_RANGE
	var visible_end := center + VISIBLE_RANGE
	# pool out
	for i in _active_children.keys():
		if i < visible_start or i > visible_end:
			exit(i)
	# pool in
	for i in range(visible_start, visible_end + 1):
		if i >= 0 and i < child_count and not _active_children.has(i):
			enter(i)
	# update positions
	for i in _active_children:
		_active_children[i].global_position = Vector3((i - _current) * OFFSET_X, 0, OFFSET_Z + -abs(i - _current) * OFFSET_DEPTH)
	# update scroll bar and buttons
	_scroll_bar.set_value_no_signal(_current)
	_mask_back.disabled = _current <= 0
	_mask_fore.disabled = _current >= child_count - 1
