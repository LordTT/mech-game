class_name PartBase
extends Node3D

@export var part_type: String = "default"
@export var display_name: String = "Part"
@export var detach_resistance: float = 1.0
@export var loose_mass: float = 35.0
@export var loose_friction: float = 1.8
@export var loose_bounce: float = 0.0
@export var loose_linear_damp: float = 8.0
@export var loose_angular_damp: float = 10.0
@export var settle_linear_speed: float = 0.08
@export var settle_angular_speed: float = 0.08
@export var settle_delay: float = 0.35

@onready var visual_root: Node3D = $VisualRoot
@onready var interact_area: Area3D = $InteractArea
@onready var interact_collision: CollisionShape3D = $InteractArea/CollisionShape3D
@onready var loose_body: RigidBody3D = $LooseBody
@onready var loose_collision: CollisionShape3D = $LooseBody/CollisionShape3D

var meshes: Array[MeshInstance3D] = []
var original_materials: Dictionary = {}

var is_held: bool = false
var attached_slot: Node3D = null
var loose_wake_timer: float = 0.0

func _ready() -> void:
	meshes.clear()
	_find_meshes(visual_root)

	if meshes.is_empty():
		push_error("PartBase: No MeshInstance3D found under VisualRoot in " + name)
		return

	_cache_original_materials()
	_configure_loose_body()

	interact_area.set_meta("part_root", self)
	loose_body.set_meta("part_root", self)

	_sync_loose_body_to_root()
	_set_loose_state(true)

func _physics_process(delta: float) -> void:
	if _is_loose():
		if loose_wake_timer > 0.0:
			loose_wake_timer = max(loose_wake_timer - delta, 0.0)

		global_transform = loose_body.global_transform
		interact_area.global_transform = global_transform
		_sleep_if_settled()

func get_part_type() -> String:
	return part_type

func get_display_name() -> String:
	return display_name

func get_detach_resistance() -> float:
	return detach_resistance

func get_attachment_collision_shape() -> Shape3D:
	return loose_collision.shape

func get_attachment_collision_global_transform() -> Transform3D:
	return loose_collision.global_transform

func highlight() -> void:
	if is_held:
		return

	for mesh in meshes:
		var mat := _create_highlight_material()
		for surface_index in range(_get_surface_count(mesh)):
			mesh.set_surface_override_material(surface_index, mat)

func unhighlight() -> void:
	for mesh in meshes:
		var materials: Array = original_materials.get(mesh, [])
		var surface_count := _get_surface_count(mesh)

		for surface_index in range(surface_count):
			var original_material: Material = null
			if surface_index < materials.size():
				original_material = materials[surface_index]
			mesh.set_surface_override_material(surface_index, original_material)

func pick_up() -> void:
	is_held = true
	attached_slot = null
	_set_loose_state(false)
	interact_area.monitoring = false

func drop() -> void:
	is_held = false
	attached_slot = null
	_sync_loose_body_to_root()
	_set_loose_state(true)
	interact_area.monitoring = true

func on_attached_to_slot(slot: Node3D) -> void:
	is_held = false
	attached_slot = slot
	_set_loose_state(false)
	interact_area.monitoring = true
	global_transform = slot.global_transform
	_sync_loose_body_to_root()

func detach_from_slot() -> void:
	if attached_slot == null:
		return

	var world_parent: Node = get_tree().current_scene
	var saved_transform: Transform3D = global_transform
	var old_slot: Node3D = attached_slot

	attached_slot = null
	old_slot.current_part = null
	if old_slot.has_method("notify_part_changed"):
		old_slot.notify_part_changed()

	reparent(world_parent)
	global_transform = saved_transform

	is_held = true
	_set_loose_state(false)
	interact_area.monitoring = false
	_sync_loose_body_to_root()

func _is_loose() -> bool:
	return not is_held and attached_slot == null and not loose_body.freeze

func _set_loose_state(enabled: bool) -> void:
	loose_body.top_level = true
	loose_collision.disabled = not enabled
	loose_body.freeze = not enabled
	loose_body.linear_velocity = Vector3.ZERO
	loose_body.angular_velocity = Vector3.ZERO
	loose_body.sleeping = not enabled

	if enabled:
		loose_wake_timer = settle_delay
		loose_body.set_deferred("sleeping", false)
	else:
		loose_wake_timer = 0.0

func _sync_loose_body_to_root() -> void:
	loose_body.global_transform = global_transform

func _sleep_if_settled() -> void:
	if loose_wake_timer > 0.0:
		return

	if loose_body.get_contact_count() == 0:
		return

	if loose_body.linear_velocity.length() > settle_linear_speed:
		return

	if loose_body.angular_velocity.length() > settle_angular_speed:
		return

	loose_body.linear_velocity = Vector3.ZERO
	loose_body.angular_velocity = Vector3.ZERO
	loose_body.sleeping = true

func _cache_original_materials() -> void:
	original_materials.clear()

	for mesh in meshes:
		var materials: Array = []
		for surface_index in range(_get_surface_count(mesh)):
			materials.append(mesh.get_active_material(surface_index))
		original_materials[mesh] = materials

func _configure_loose_body() -> void:
	loose_body.mass = loose_mass
	loose_body.can_sleep = true
	loose_body.contact_monitor = true
	loose_body.max_contacts_reported = 4

	var material := loose_body.physics_material_override
	if material == null:
		material = PhysicsMaterial.new()
		loose_body.physics_material_override = material

	material.friction = loose_friction
	material.bounce = loose_bounce
	material.rough = true
	material.absorbent = true
	loose_body.linear_damp = loose_linear_damp
	loose_body.angular_damp = loose_angular_damp

func _create_highlight_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 0.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.85, 0.0)
	return mat

func _get_surface_count(mesh_instance: MeshInstance3D) -> int:
	if mesh_instance.mesh == null:
		return 1

	return max(mesh_instance.mesh.get_surface_count(), 1)

func _find_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		meshes.append(node)

	for child in node.get_children():
		_find_meshes(child)
