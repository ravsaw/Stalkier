extends Node
class_name NPCData

@export var npc_id: String
@export var npc_name: String
@export var faction_id: String = ""
@export var group_id: String = ""

# Basic stats
@export var health: float = 100.0
@export var max_health: float = 100.0
@export var move_speed: float = 50.0

# Needs (0.0 to 1.0, where 1.0 is fully satisfied)
var needs: Dictionary = {
	"hunger": 0.8,
	"safety": 0.7,
	"energy": 0.9
}

# Spatial data
var current_location: String = ""
var current_poi: String = ""
var target_poi: String = ""

# State data
var current_state: String = "idle"
var last_state_change: float = 0.0

func _ready():
	if npc_id.is_empty():
		npc_id = generate_unique_id()
	if npc_name.is_empty():
		npc_name = "NPC_" + npc_id
	
	# Connect to periodic updates
	var timer = Timer.new()
	timer.wait_time = GameGlobals.BASE_UPDATE_RATE
	timer.timeout.connect(_update_needs)
	add_child(timer)
	timer.start()
	print("NPCData initializing for ", name)

func generate_unique_id() -> String:
	return "npc_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

func _update_needs():
	# Slowly decrease needs over time
	needs.hunger = max(0.0, needs.hunger - 0.01)
	needs.energy = max(0.0, needs.energy - 0.008)
	
	# If unsafe location, decrease safety
	if not is_location_safe():
		needs.safety = max(0.0, needs.safety - 0.02)

func is_location_safe() -> bool:
	# Simple safety check - TODO: implement based on actual location data
	return true

func get_most_urgent_need() -> String:
	var min_need = "hunger"
	var min_value = needs.hunger
	
	for need_name in needs:
		if needs[need_name] < min_value:
			min_value = needs[need_name]
			min_need = need_name
	
	return min_need

func get_need_urgency(need_name: String) -> float:
	# Returns urgency from 0.0 (not urgent) to 1.0 (critical)
	return 1.0 - needs.get(need_name, 1.0)
