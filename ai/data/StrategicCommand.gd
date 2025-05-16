class_name StrategicCommand
extends Resource

var type: String
var target: Vector3
var priority: float = 0.5
var parameters: Dictionary = {}
var estimated_duration: float = 0.0
var issued_time: float

func _init():
	issued_time = Time.get_ticks_usec()

func is_expired(timeout: float = 5.0) -> bool:
	return Time.get_ticks_usec() - issued_time > timeout
