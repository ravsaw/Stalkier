class_name TacticalStatus
extends Resource

var current_state: String = "idle"
var position: Vector3
var velocity: Vector3
var health: float = 100.0
var stamina: float = 100.0
var last_update_time: float

func _init():
	last_update_time = Time.get_ticks_usec()

func update_position(new_pos: Vector3):
	position = new_pos
	last_update_time = Time.get_ticks_usec()
