class_name NPCMemory
extends Node

var memories: Array = []
var max_memories: int = 100
var memory_decay_time: float = 300.0  # 5 minutes

class Memory:
	var type: String
	var data: Dictionary
	var importance: float
	var timestamp: float
	var location: Vector3
	
	func _init(t: String, d: Dictionary, i: float = 0.5):
		type = t
		data = d
		importance = i
		timestamp = Time.get_ticks_usec()

func add_memory(type: String, data: Dictionary, importance: float = 0.5):
	var memory = Memory.new(type, data, importance)
	memories.append(memory)
	
	# Remove excess memories
	if memories.size() > max_memories:
		_cleanup_old_memories()

func _cleanup_old_memories():
	# Sort by importance and age, keep most important recent ones
	memories.sort_custom(func(a, b): return a.importance * (1.0 / (Time.get_ticks_usec() - a.timestamp + 1)) > b.importance * (1.0 / (Time.get_ticks_usec() - b.timestamp + 1)))
	
	# Remove excess
	while memories.size() > max_memories:
		memories.pop_back()

func get_memories_of_type(type: String) -> Array:
	return memories.filter(func(m): return m.type == type)

func get_recent_exploration_score() -> float:
	var exploration_memories = get_memories_of_type("exploration")
	var recent_count = 0
	var current_time = Time.get_ticks_usec()
	
	for memory in exploration_memories:
		if current_time - memory.timestamp < 60.0:  # Last minute
			recent_count += 1
	
	return float(recent_count) / 10.0  # Normalize to 0-1

func remember_location(location: Vector3, type: String, importance: float = 0.5):
	add_memory("location", {"position": location, "type": type}, importance)

func record_action_result(action: Dictionary):
	add_memory("action_result", action, 0.3)
