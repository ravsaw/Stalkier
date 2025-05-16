class_name StrategyGoal
extends Resource

enum Type {
	SURVIVAL,
	EXPLORATION,
	HUNTING,
	GATHERING,
	SOCIAL_INTERACTION,
	RESOURCE_ACQUISITION,
	TERRITORY_CONTROL
}

var type: Type = Type.SURVIVAL
var priority: float = 0.0
var description: String = ""
var target_location: Vector3
var parameters: Dictionary = {}
var deadline: float = 0.0  # 0 means no deadline
var created_time: float

func _init():
	created_time = Time.get_ticks_usec()

func get_age() -> float:
	return Time.get_ticks_usec() - created_time

func is_expired() -> bool:
	return deadline > 0 and Time.get_ticks_usec() > deadline
