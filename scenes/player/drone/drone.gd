extends CharacterBody3D

@export var speed: float = 6.0
@export var mouse_sensitivity: float = 0.002
@export var mech_path: NodePath
var mech: Node = null

var yaw: float = 0.0
var pitch: float = 0.0
var current_target: Node = null
var is_player_controlled: bool = false

@export var snap_radius: float = 1.5
@export var attach_radius: float = 0.45
@export var snap_follow_speed: float = 10.0

var held_object: Node3D = null
@onready var hold_point: Marker3D = $CameraPivot/HoldPoint

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mech = get_node_or_null(mech_path)

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
			print(current_target)
			
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

	var target_transform: Transform3D = hold_point.global_transform
	var best_slot := _find_best_slot_for_held_object()

	if best_slot != null:
		target_transform = best_slot.global_transform

		var distance := held_object.global_position.distance_to(best_slot.global_position)
		if distance <= attach_radius:
			best_slot.attach_part(held_object)
			held_object = null
			return

	var t := snap_follow_speed * get_physics_process_delta_time()

	held_object.global_position = held_object.global_position.lerp(target_transform.origin, t)
	held_object.global_rotation = held_object.global_rotation.lerp(target_transform.basis.get_euler(), t)

	
func _find_best_slot_for_held_object() -> Node3D:
	if held_object == null:
		return null

	if mech == null:
		return null

	if not mech.has_node("SlotsRoot"):
		return null

	var slots_root = mech.get_node("SlotsRoot")
	var best_slot: Node3D = null
	var best_distance := INF

	for child in slots_root.get_children():
		if not child.has_method("can_attach"):
			continue

		if not child.can_attach(held_object):
			continue

		var slot: Node3D = child
		var distance := held_object.global_position.distance_to(slot.global_position)

		if distance < best_distance and distance <= snap_radius:
			best_distance = distance
			best_slot = slot

	return best_slot
