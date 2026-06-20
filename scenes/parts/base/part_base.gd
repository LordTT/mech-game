class_name PartBase
extends Node3D

@export var part_type: String = "default"
@export var display_name: String = "Part"
@export var detach_resistance: float = 1.0

@onready var visual_root: Node3D = $VisualRoot
@onready var interact_area: Area3D = $InteractArea
@onready var interact_collision: CollisionShape3D = $InteractArea/CollisionShape3D
@onready var loose_body: RigidBody3D = $LooseBody
@onready var loose_collision: CollisionShape3D = $LooseBody/CollisionShape3D

var meshes: Array[MeshInstance3D] = []
var original_materials: Dictionary = {}

var is_held: bool = false
var attached_slot: Node3D = null

func _ready() -> void:
	meshes.clear()
	_find_meshes(visual_root)

	if meshes.is_empty():
		push_error("PartBase: No MeshInstance3D found under VisualRoot in " + name)
		return

	for mesh in meshes:
		original_materials[mesh] = mesh.get_active_material(0)

	interact_area.set_meta("part_root", self)
	loose_body.set_meta("part_root", self)

	_sync_loose_body_to_root()
	_set_loose_state(true)

func _physics_process(_delta: float) -> void:
	if _is_loose():
		global_transform = loose_body.global_transform
		interact_area.global_transform = global_transform

func get_part_type() -> String:
	return part_type

func get_display_name() -> String:
	return display_name

func get_detach_resistance() -> float:
	return detach_resistance

func highlight() -> void:
	if is_held:
		return

	for mesh in meshes:
		var original_material: Material = original_materials.get(mesh)
		if original_material == null:
			continue

		var mat := original_material.duplicate() as StandardMaterial3D
		mat.albedo_color = Color(1, 1, 0)
		mesh.set_surface_override_material(0, mat)

func unhighlight() -> void:
	for mesh in meshes:
		var original_material: Material = original_materials.get(mesh)
		if original_material == null:
			mesh.set_surface_override_material(0, null)
		else:
			mesh.set_surface_override_material(0, original_material)

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

	reparent(world_parent)
	global_transform = saved_transform

	is_held = true
	_set_loose_state(false)
	interact_area.monitoring = false
	_sync_loose_body_to_root()

func _is_loose() -> bool:
	return not is_held and attached_slot == null and not loose_body.freeze

func _set_loose_state(enabled: bool) -> void:
	loose_collision.disabled = not enabled
	loose_body.freeze = not enabled
	loose_body.sleeping = false

func _sync_loose_body_to_root() -> void:
	loose_body.global_transform = global_transform

func _find_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		meshes.append(node)

	for child in node.get_children():
		_find_meshes(child)
