extends Node

# Core simulation events
signal npc_created(npc_data)
signal npc_destroyed(npc_id)
signal location_changed(player_pos, new_location)
signal poi_entered(npc_id, poi_id)
signal poi_exited(npc_id, poi_id)

# Debug events
signal debug_mode_toggled(enabled)
signal simulation_speed_changed(multiplier)

func _ready():
	print("EventBus initialized")
