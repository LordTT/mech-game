class_name LegsBase
extends PartBase

@export var move_speed_multiplier: float = 1.0
@export var turn_speed_multiplier: float = 1.0

@export_group("Procedural Walk")
@export var stride_length: float = 0.45
@export var step_height: float = 0.22
@export var cycle_speed: float = 4.5
@export var foot_pitch: float = 0.28
@export var leg_bend_axis: Vector3 = Vector3.FORWARD
@export var upper_leg_swing: float = 0.22
@export var lower_leg_swing: float = 0.34
@export var idle_bob_amount: float = 0.035
@export var walk_bob_amount: float = 0.075
@export var pose_return_speed: float = 8.0
@export var min_move_amount: float = 0.05

var walk_phase: float = 0.0
var current_move_amount: float = 0.0
var animation_space_root: Node3D = null

var animated_nodes: Dictionary[String, Node3D] = {}
var rest_transforms: Dictionary[Node3D, Transform3D] = {}

func _ready() -> void:
	part_type = "legs"
	super._ready()
	_cache_animation_nodes()

func get_move_speed_multiplier() -> float:
	return move_speed_multiplier

func get_turn_speed_multiplier() -> float:
	return turn_speed_multiplier

func update_leg_animation(delta: float, local_move_velocity: Vector3, move_amount: float) -> void:
	if animated_nodes.is_empty():
		return

	var target_move_amount: float = clampf(move_amount, 0.0, 1.0)
	current_move_amount = lerpf(current_move_amount, target_move_amount, minf(pose_return_speed * delta, 1.0))

	if current_move_amount <= min_move_amount:
		_update_idle_pose(delta)
		return

	var animation_velocity: Vector3 = _to_animation_space_velocity(local_move_velocity)
	var horizontal_speed: float = Vector2(animation_velocity.x, animation_velocity.z).length()
	walk_phase = fmod(walk_phase + delta * cycle_speed * maxf(horizontal_speed, 0.2), TAU)

	var travel_dir: Vector3 = Vector3(animation_velocity.x, 0.0, animation_velocity.z)
	if travel_dir.length() < 0.001:
		travel_dir = Vector3.RIGHT
	else:
		travel_dir = travel_dir.normalized()

	var side_dir: Vector3 = Vector3(travel_dir.z, 0.0, -travel_dir.x).normalized()
	_apply_leg_pose("left", walk_phase, travel_dir, side_dir, current_move_amount, delta)
	_apply_leg_pose("right", walk_phase + PI, travel_dir, side_dir, current_move_amount, delta)
	_apply_hip_pose(walk_phase, current_move_amount, delta)

func reset_leg_animation() -> void:
	walk_phase = 0.0
	current_move_amount = 0.0
	_blend_all_to_rest(1.0)

func pick_up() -> void:
	reset_leg_animation()
	super.pick_up()

func drop() -> void:
	reset_leg_animation()
	super.drop()

func on_attached_to_slot(slot: Node3D) -> void:
	reset_leg_animation()
	super.on_attached_to_slot(slot)

func detach_from_slot() -> void:
	reset_leg_animation()
	super.detach_from_slot()

func _cache_animation_nodes() -> void:
	animated_nodes.clear()
	rest_transforms.clear()

	var node_names: Array[String] = [
		"left_upper_leg",
		"left_lower_leg",
		"left_foot",
		"right_upper_leg",
		"right_lower_leg",
		"right_foot",
		"hips_block",
	]

	for node_name in node_names:
		var node: Node3D = _find_node_by_name(visual_root, node_name) as Node3D
		if node == null:
			continue

		animated_nodes[node_name] = node
		rest_transforms[node] = node.transform

	var hips: Node3D = _get_animated_node("hips_block")
	if hips != null:
		animation_space_root = hips.get_parent() as Node3D

func _update_idle_pose(delta: float) -> void:
	walk_phase = fmod(walk_phase + delta * cycle_speed * 0.25, TAU)
	_blend_all_to_rest(minf(pose_return_speed * delta, 1.0))

	var hips: Node3D = _get_animated_node("hips_block")
	if hips == null:
		return

	var rest: Transform3D = _get_rest_transform(hips)
	var target: Transform3D = rest
	target.origin.y += sin(walk_phase) * idle_bob_amount
	hips.transform = hips.transform.interpolate_with(target, minf(pose_return_speed * delta, 1.0))

func _apply_leg_pose(side: String, phase: float, travel_dir: Vector3, side_dir: Vector3, amount: float, delta: float) -> void:
	var upper: Node3D = _get_animated_node("%s_upper_leg" % side)
	var lower: Node3D = _get_animated_node("%s_lower_leg" % side)
	var foot: Node3D = _get_animated_node("%s_foot" % side)
	var blend: float = minf(pose_return_speed * delta, 1.0)

	var stride: float = cos(phase) * stride_length * amount
	var lift: float = maxf(sin(phase), 0.0) * step_height * amount
	var lateral: Vector3 = side_dir * sin(phase) * stride_length * 0.08 * amount
	var step_offset: Vector3 = travel_dir * stride + lateral
	step_offset.y += lift

	if upper != null:
		var upper_rest: Transform3D = _get_rest_transform(upper)
		var upper_target: Transform3D = upper_rest.rotated_local(leg_bend_axis.normalized(), -sin(phase) * upper_leg_swing * amount)
		upper.transform = upper.transform.interpolate_with(upper_target, blend)

	if lower != null:
		var lower_rest: Transform3D = _get_rest_transform(lower)
		var bend: float = maxf(sin(phase), 0.0) * lower_leg_swing * amount
		var lower_target: Transform3D = lower_rest.rotated_local(leg_bend_axis.normalized(), bend)
		lower.transform = lower.transform.interpolate_with(lower_target, blend)

	if foot != null:
		var foot_rest: Transform3D = _get_rest_transform(foot)
		var foot_target: Transform3D = foot_rest.rotated_local(leg_bend_axis.normalized(), -sin(phase) * foot_pitch * amount)
		foot_target.origin += step_offset
		foot.transform = foot.transform.interpolate_with(foot_target, blend)

func _apply_hip_pose(phase: float, amount: float, delta: float) -> void:
	var hips: Node3D = _get_animated_node("hips_block")
	if hips == null:
		return

	var rest: Transform3D = _get_rest_transform(hips)
	var target: Transform3D = rest
	target.origin.y += abs(sin(phase * 2.0)) * walk_bob_amount * amount
	target = target.rotated_local(Vector3.FORWARD, sin(phase * 2.0) * 0.035 * amount)
	hips.transform = hips.transform.interpolate_with(target, minf(pose_return_speed * delta, 1.0))

func _blend_all_to_rest(blend: float) -> void:
	for node_key in rest_transforms.keys():
		var node: Node3D = node_key as Node3D
		if node == null:
			continue

		var target: Transform3D = _get_rest_transform(node)
		node.transform = node.transform.interpolate_with(target, blend)

func _get_rest_transform(node: Node3D) -> Transform3D:
	if rest_transforms.has(node):
		return rest_transforms[node]

	return node.transform

func _get_animated_node(node_name: String) -> Node3D:
	if animated_nodes.has(node_name):
		return animated_nodes[node_name]

	return null

func _to_animation_space_velocity(local_move_velocity: Vector3) -> Vector3:
	if animation_space_root == null:
		return local_move_velocity

	return animation_space_root.transform.basis.inverse() * local_move_velocity

func _find_node_by_name(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node

	for child in node.get_children():
		var found: Node = _find_node_by_name(child, target_name)
		if found != null:
			return found

	return null
