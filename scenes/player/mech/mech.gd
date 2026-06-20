extends CharacterBody3D

@export var move_speed: float = 5.0
@export var gravity: float = 20.0
@export var turn_speed: float = 8.0
@export var mouse_sensitivity: float = 0.002
@export var brace_when_missing_legs: bool = true

var yaw: float = 0.0
var pitch: float = 0.0
var is_player_controlled: bool = true
var attached_collision_proxies: Array[CollisionShape3D] = []

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_yaw: Node3D = $CameraPivot/CameraYaw
@onready var camera_pitch: Node3D = $CameraPivot/CameraYaw/CameraPitch
@onready var legs_slot: Node = $SlotsRoot/Slot_Legs
@onready var slots_root: Node3D = $SlotsRoot

func _ready() -> void:
	camera_pivot.top_level = true
	_rebuild_attached_collision_proxies()
	_update_camera_pivot_position()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if not is_player_controlled:
		return

	if event is InputEventMouseMotion:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, -1.2, 0.6)

		camera_yaw.rotation.y = yaw
		camera_pitch.rotation.x = pitch

func set_player_controlled(value: bool) -> void:
	is_player_controlled = value

func on_slot_part_changed(_slot: Node3D) -> void:
	call_deferred("_rebuild_attached_collision_proxies")

func _physics_process(delta: float) -> void:
	_update_camera_pivot_position()

	if _should_brace_without_legs():
		_apply_no_legs_brace()
		_update_attached_leg_animation(delta, Vector3.ZERO, 0.0)
		return

	if not is_player_controlled:
		velocity.x = 0.0
		velocity.z = 0.0

		if not is_on_floor():
			velocity.y -= gravity * delta
		else:
			velocity.y = 0.0

		_update_attached_leg_animation(delta, Vector3.ZERO, 0.0)
		move_and_slide()
		return

	var speed_mult: float = get_legs_move_speed_multiplier()
	var turn_mult: float = get_legs_turn_speed_multiplier()

	var input_dir: Vector2 = Vector2.ZERO
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.y = Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	input_dir = input_dir.normalized()

	var cam_basis: Basis = camera_yaw.global_transform.basis
	var forward: Vector3 = -cam_basis.z
	var right: Vector3 = cam_basis.x

	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()

	var move_vector: Vector3 = right * input_dir.x + forward * input_dir.y
	if move_vector.length() > 1.0:
		move_vector = move_vector.normalized()

	velocity.x = move_vector.x * move_speed * speed_mult
	velocity.z = move_vector.z * move_speed * speed_mult

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	if move_vector.length() > 0.01:
		var target_yaw: float = atan2(move_vector.x, move_vector.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, turn_speed * turn_mult * delta)

	var horizontal_velocity: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var local_horizontal_velocity: Vector3 = global_transform.basis.inverse() * horizontal_velocity
	var move_amount: float = clampf(horizontal_velocity.length() / maxf(move_speed, 0.001), 0.0, 1.0)
	_update_attached_leg_animation(delta, local_horizontal_velocity, move_amount)

	move_and_slide()

func _update_camera_pivot_position() -> void:
	camera_pivot.global_position = global_position + Vector3(0.0, 1.5, 0.0)

func has_legs() -> bool:
	return legs_slot.current_part != null

func _should_brace_without_legs() -> bool:
	return brace_when_missing_legs and not has_legs()

func _apply_no_legs_brace() -> void:
	velocity = Vector3.ZERO
	rotation.x = 0.0
	rotation.z = 0.0

func get_legs_move_speed_multiplier() -> float:
	if not has_legs():
		return 0.0

	var part = legs_slot.current_part
	if part != null and part.has_method("get_move_speed_multiplier"):
		return part.get_move_speed_multiplier()

	return 1.0

func get_legs_turn_speed_multiplier() -> float:
	if not has_legs():
		return 1.0

	var part = legs_slot.current_part
	if part != null and part.has_method("get_turn_speed_multiplier"):
		return part.get_turn_speed_multiplier()

	return 1.0

func _update_attached_leg_animation(delta: float, local_move_velocity: Vector3, move_amount: float) -> void:
	var part = legs_slot.current_part
	if part == null:
		return

	if part.has_method("update_leg_animation"):
		part.update_leg_animation(delta, local_move_velocity, move_amount)

func _rebuild_attached_collision_proxies() -> void:
	_clear_attached_collision_proxies()

	for slot_node in slots_root.get_children():
		var slot: Node3D = slot_node as Node3D
		if slot == null:
			continue

		if not slot.has_method("get_current_part"):
			continue

		var part: Node3D = slot.get_current_part()
		if part == null:
			continue

		_add_attached_collision_proxy(slot, part)

func _add_attached_collision_proxy(slot: Node3D, part: Node3D) -> void:
	if not part.has_method("get_attachment_collision_shape"):
		return

	if not part.has_method("get_attachment_collision_global_transform"):
		return

	var source_shape: Shape3D = part.get_attachment_collision_shape()
	if source_shape == null:
		return

	var proxy: CollisionShape3D = CollisionShape3D.new()
	proxy.name = "AttachedCollision_%s" % slot.name
	proxy.shape = source_shape.duplicate()
	add_child(proxy)
	proxy.global_transform = part.get_attachment_collision_global_transform()
	attached_collision_proxies.append(proxy)

func _clear_attached_collision_proxies() -> void:
	for proxy in attached_collision_proxies:
		if is_instance_valid(proxy):
			proxy.queue_free()

	attached_collision_proxies.clear()
