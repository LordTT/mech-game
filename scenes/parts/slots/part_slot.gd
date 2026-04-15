extends Node3D

@export var slot_type: String = "generic"
var current_part: Node3D = null

var debug_mesh: MeshInstance3D = null
var normal_material: StandardMaterial3D = null
var highlight_material: StandardMaterial3D = null

func _ready() -> void:
	_ensure_debug_mesh()

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

	clear_highlight()

func detach_part() -> Node3D:
	var part: Node3D = current_part
	current_part = null
	return part

func show_highlight(valid: bool = true) -> void:
	_ensure_debug_mesh()

	if debug_mesh == null:
		return

	debug_mesh.visible = true
	debug_mesh.set_surface_override_material(0, highlight_material if valid else normal_material)

func clear_highlight() -> void:
	if debug_mesh == null:
		return

	debug_mesh.visible = false

func _ensure_debug_mesh() -> void:
	if has_node("DebugMesh"):
		debug_mesh = $DebugMesh
		return

	debug_mesh = MeshInstance3D.new()
	debug_mesh.name = "DebugMesh"

	var sphere := SphereMesh.new()
	sphere.radius = 0.18
	sphere.height = 0.36
	debug_mesh.mesh = sphere

	normal_material = StandardMaterial3D.new()
	normal_material.albedo_color = Color(0.3, 0.3, 0.3, 0.5)
	normal_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	highlight_material = StandardMaterial3D.new()
	highlight_material.albedo_color = Color(0.2, 1.0, 0.2, 0.7)
	highlight_material.emission_enabled = true
	highlight_material.emission = Color(0.2, 1.0, 0.2)
	highlight_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	debug_mesh.set_surface_override_material(0, normal_material)
	debug_mesh.visible = false
	add_child(debug_mesh)
