extends StaticBody3D

@export var part_type: String = "arm"

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var interact_area: Area3D = $InteractArea

var original_material: Material = null
var is_held: bool = false
var attached_slot: Node3D = null

func _ready() -> void:
	original_material = mesh.get_active_material(0)

func get_part_type() -> String:
	return part_type

func highlight() -> void:
	if is_held:
		return
	if original_material == null:
		return

	var mat := original_material.duplicate() as StandardMaterial3D
	mat.albedo_color = Color(1, 1, 0)
	mesh.set_surface_override_material(0, mat)

func unhighlight() -> void:
	if original_material == null:
		return

	mesh.set_surface_override_material(0, original_material)

func pick_up() -> void:
	is_held = true
	collision.disabled = true
	interact_area.monitoring = false

func drop() -> void:
	is_held = false
	collision.disabled = false
	interact_area.monitoring = true

func on_attached_to_slot(slot: Node3D) -> void:
	is_held = false
	attached_slot = slot
	collision.disabled = true
	interact_area.monitoring = true
	global_transform = slot.global_transform

func detach_from_slot() -> void:
	if attached_slot == null:
		return

	var world_parent := get_tree().current_scene
	var saved_transform := global_transform
	var old_slot := attached_slot

	attached_slot = null
	old_slot.current_part = null

	reparent(world_parent)
	global_transform = saved_transform

	is_held = true
	collision.disabled = true
	interact_area.monitoring = false
