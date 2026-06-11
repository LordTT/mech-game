class_name LegsBase
extends PartBase

@export var move_speed_multiplier: float = 1.0
@export var turn_speed_multiplier: float = 1.0

func _ready() -> void:
	part_type = "legs"
	super._ready()

func get_move_speed_multiplier() -> float:
	return move_speed_multiplier

func get_turn_speed_multiplier() -> float:
	return turn_speed_multiplier
