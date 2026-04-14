extends CharacterBody3D

@export var move_speed: float = 5.0
@export var gravity: float = 20.0
@export var turn_speed: float = 8.0
@export var mouse_sensitivity: float = 0.002

var yaw: float = 0.0
var pitch: float = 0.0
var is_player_controlled: bool = true

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_yaw: Node3D = $CameraPivot/CameraYaw
@onready var camera_pitch: Node3D = $CameraPivot/CameraYaw/CameraPitch
@onready var legs_slot: Node = $SlotsRoot/Slot_Legs

func _ready() -> void:
	camera_pivot.top_level = true
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

func _physics_process(delta: float) -> void:
	_update_camera_pivot_position()

	if not is_player_controlled:
		velocity.x = 0.0
		velocity.z = 0.0

		if not is_on_floor():
			velocity.y -= gravity * delta
		else:
			velocity.y = 0.0

		move_and_slide()
		return

	var can_move := has_legs()
	
	
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

	if can_move:
		velocity.x = move_vector.x * move_speed
		velocity.z = move_vector.z * move_speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	if move_vector.length() > 0.01:
		var target_yaw: float = atan2(move_vector.x, move_vector.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, turn_speed * delta)

	move_and_slide()

func _update_camera_pivot_position() -> void:
	camera_pivot.global_position = global_position + Vector3(0.0, 1.5, 0.0)
	
func has_legs() -> bool:
	return legs_slot.current_part != null
