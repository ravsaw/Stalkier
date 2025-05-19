extends Node
class_name NPCManager

@export var initial_npc_count: int = 100
@export var max_npcs: int = 300

var active_npcs: Dictionary = {}
var npc_pool: Array = []

func _ready():
	add_to_group("npc_manager")
	
	# Connect to events once at startup
	EventBus.npc_destroyed.connect(_on_npc_destroyed)
	
	# Wait for world to be set up
	await get_tree().create_timer(1.0).timeout
	spawn_initial_npcs()

func spawn_initial_npcs():
	for i in range(initial_npc_count):
		await get_tree().process_frame  # Wait a frame between spawns
		spawn_npc()

func spawn_npc() -> NPCController:
	var npc_scene = preload("res://scenes/NPC.tscn")
	var npc = npc_scene.instantiate()
	
	# Place NPC in random location
	var random_location = get_random_location()
	if random_location:
		random_location.add_child(npc)
		
		# Wait for the NPC to be fully initialized
		await get_tree().process_frame
		
		npc.global_position = get_random_position_in_location(random_location)
		
		# Register NPC
		if npc.npc_data:
			active_npcs[npc.npc_data.npc_id] = npc
			print("Spawned NPC: ", npc.npc_data.npc_name, " at ", npc.global_position)
		else:
			print("Warning: NPCData not ready for NPC at ", npc.global_position)
		
		# Don't connect the signal here - it's already connected in _ready()
		
		return npc
	
	return null

func get_random_location() -> Node2D:
	var locations_container = GameGlobals.simulation_layer.get_node("LocationsContainer")
	var locations = locations_container.get_children()
	if locations.size() > 0:
		return locations[randi() % locations.size()]
	return null

func get_random_position_in_location(location: Node2D) -> Vector2:
	# Get random position within location bounds
	var location_center = location.global_position
	var offset = Vector2(
		randf_range(-GameGlobals.LOCATION_SIZE.x/2, GameGlobals.LOCATION_SIZE.x/2),
		randf_range(-GameGlobals.LOCATION_SIZE.y/2, GameGlobals.LOCATION_SIZE.y/2)
	)
	return location_center + offset

func _on_npc_destroyed(npc_id: String):
	if npc_id in active_npcs:
		active_npcs.erase(npc_id)

func get_npc_count() -> int:
	return active_npcs.size()
