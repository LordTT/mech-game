extends Node3D

@export var slot_type: String = "generic"
var current_part: Node3D = null

func can_attach(part: Node) -> bool:
	if current_part != null:
		return false

	if not part.has_method("get_part_type"):
		return false

	return part.get_part_type() == slot_type

func attach_part(part: Node3D) -> void:
	current_part = part

	var saved_transform := global_transform
	part.reparent(self)
	part.global_transform = saved_transform

	if part.has_method("on_attached_to_slot"):
		part.on_attached_to_slot(self)
