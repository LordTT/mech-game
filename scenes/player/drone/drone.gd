extends CharacterBody3D

@export var speed: float = 6.0
@export var mouse_sensitivity: float = 0.002

var yaw: float = 0.0
var pitch: float = 0.0
var current_target: Node = null
var is_player_controlled: bool = false

var held_object: Node3D = null
@onready var hold_point: Marker3D = $CameraPivot/HoldPoint

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if not is_player_controlled:
		return

	if event is InputEventMouseMotion:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, -1.5, 1.5)

		rotation.y = yaw
		$CameraPivot.rotation.x = pitch
	if event.is_action_pressed("grab"):
		if held_object:
			_drop_held_object()
		else:
			_try_grab()

func set_player_controlled(value: bool) -> void:
	is_player_controlled = value

func _physics_process(delta: float) -> void:
	if not is_player_controlled:
		_clear_current_target()
		velocity = Vector3.ZERO
		move_and_slide()
		return

	var input_dir := Vector3.ZERO
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.z = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	input_dir.y = Input.get_action_strength("move_up") - Input.get_action_strength("move_down")

	var forward: Vector3 = transform.basis.z
	var right: Vector3 = transform.basis.x

	var move_dir: Vector3 = (right * input_dir.x + forward * input_dir.z + Vector3.UP * input_dir.y).normalized()
	velocity = move_dir * speed

	_update_highlight()
	
	_update_held_object()
	
	move_and_slide()

func _update_highlight() -> void:
	var ray: RayCast3D = $CameraPivot/InteractRay

	if ray.is_colliding():
		var collider: Object = ray.get_collider()
		var target: Node = collider as Node

		if target != current_target:
			if current_target and current_target.has_method("unhighlight"):
				current_target.unhighlight()

			current_target = target
			
			if current_target and current_target.has_method("highlight"):
				current_target.highlight()
	else:
		_clear_current_target()

func _clear_current_target() -> void:
	if current_target and current_target.has_method("unhighlight"):
		current_target.unhighlight()

	current_target = null

func _try_grab() -> void:
	if current_target == null:
		return

	if current_target.has_method("pick_up"):
		current_target.pick_up()
		held_object = current_target

func _drop_held_object() -> void:
	if held_object == null:
		return

	if held_object.has_method("drop"):
		held_object.drop()

	held_object = null
	
func _update_held_object() -> void:
	if held_object == null:
		return

	var target_pos = hold_point.global_position
	var current_pos = held_object.global_position

	held_object.global_position = current_pos.lerp(target_pos, 5.0 * get_physics_process_delta_time())
	
	held_object.global_rotation = held_object.global_rotation.lerp(
	hold_point.global_rotation,
	10.0 * get_physics_process_delta_time()
)
