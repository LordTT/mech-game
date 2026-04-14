extends Node

@export var mech_path: NodePath
@export var drone_path: NodePath

var mech = null
var drone = null
var mech_camera: Camera3D = null
var drone_camera: Camera3D = null

var controlling_drone: bool = false

func _ready() -> void:
	mech = get_node(mech_path)
	drone = get_node(drone_path)

	mech_camera = mech.get_node("CameraPivot/CameraYaw/CameraPitch/Camera3D")
	drone_camera = drone.get_node_or_null("CameraPivot/Camera3D")

	if mech_camera == null:
		push_error("Mech camera not found at CameraAnchor/Camera3D")

	if drone_camera == null:
		push_error("Drone camera not found at CameraPivot/Camera3D")

	_set_control_mode(false)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_mode"):
		controlling_drone = not controlling_drone
		_set_control_mode(controlling_drone)

func _set_control_mode(use_drone: bool) -> void:
	mech.set_player_controlled(not use_drone)
	drone.set_player_controlled(use_drone)

	mech_camera.current = not use_drone
	drone_camera.current = use_drone
