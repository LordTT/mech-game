extends CharacterBody3D

@export var speed: float = 6.0
@export var mouse_sensitivity: float = 0.002
@export var mech_path: NodePath
var mech: Node = null

var yaw: float = 0.0
var pitch: float = 0.0
var current_target: Node = null
var is_player_controlled: bool = false

var beam_active: bool = false
var held_object: Node3D = null
var pulling_part: Node3D = null
var pull_progress: float = 0.0

var last_detached_part: Node3D = null
var reattach_block_timer: float = 0.0

@export var reattach_block_duration: float = 0.35
@export var snap_radius: float = 1.5
@export var attach_radius: float = 0.45
@export var snap_follow_speed: float = 10.0

@export var detach_distance: float = 1.6
@export var detach_time_required: float = 0.45

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
		beam_active = true
		_begin_beam_interaction()

	if event.is_action_released("grab"):
		beam_active = false
		_end_beam_interaction()

func _begin_beam_interaction() -> void:
	if current_target == null:
		return

	if held_object != null:
		return

	if pulling_part != null:
		return

	if current_target.has_method("detach_from_slot") and current_target.attached_slot != null:
		pulling_part = current_target
		pull_progress = 0.0
		return

	if current_target.has_method("pick_up"):
		current_target.pick_up()
		held_object = current_target

func _end_beam_interaction() -> void:
	if pulling_part != null:
		pulling_part = null
		pull_progress = 0.0

	if held_object != null:
		_drop_held_object()

func set_player_controlled(value: bool) -> void:
	is_player_controlled = value

func _physics_process(delta: float) -> void:
	
	if reattach_block_timer > 0.0:
		reattach_block_timer -= delta
	
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

	if reattach_block_timer > 0.0:
		reattach_block_timer -= delta

	_update_highlight()
	_update_pulling(delta)
	_update_held_object()

	move_and_slide()

func _update_highlight() -> void:
	var ray: RayCast3D = $CameraPivot/InteractRay

	if ray.is_colliding():
		var collider = ray.get_collider()
		var target: Node = collider as Node

		if target != null and target is Area3D:
			target = target.get_parent()

		if target != current_target:
			if current_target and current_target.has_method("unhighlight"):
				current_target.unhighlight()

			current_target = target
			print("Target: ", target.name)

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

	# If attached → start pulling instead of instant detach
	if current_target.has_method("detach_from_slot") and current_target.attached_slot != null:
		print("Start pulling")
		pulling_part = current_target
		return

	# Normal pickup
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
	
	if not beam_active:
		return

	if pulling_part != null:
		return
	
	if held_object == null:
		return
		
	if pulling_part != null:
		return
		
	var target_transform: Transform3D = hold_point.global_transform
	var best_slot := _find_best_slot_for_held_object()
	if held_object == last_detached_part and reattach_block_timer > 0.0:
		best_slot = null

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
	
func _update_pulling(delta: float) -> void:
	if not beam_active:
		pull_progress = 0.0
		return

	if pulling_part == null:
		pull_progress = 0.0
		return

	var slot = pulling_part.attached_slot
	if slot == null:
		pulling_part = null
		pull_progress = 0.0
		return

	pulling_part.global_transform = slot.global_transform

	var distance: float = hold_point.global_position.distance_to(slot.global_position)

	if distance >= detach_distance:
		pull_progress += delta

		if pull_progress >= detach_time_required:
			pulling_part.detach_from_slot()
			held_object = pulling_part

			last_detached_part = pulling_part
			reattach_block_timer = reattach_block_duration

			pulling_part = null
			pull_progress = 0.0
	else:
		pull_progress = 0.0
