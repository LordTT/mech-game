class_name ArmBase
extends PartBase

@export var damage: float = 10.0
@export var fire_rate: float = 1.0

func _ready() -> void:
	part_type = "arm"
	super._ready()

func get_damage() -> float:
	return damage

func get_fire_rate() -> float:
	return fire_rate
