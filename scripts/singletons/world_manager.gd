# scripts/singletons/world_manager.gd
extends Node

# === WORLD STATE ===
var player_position: Vector2 = Vector2.ZERO  # Player's current 2D position
var current_area_id: String = "area_center"
var active_areas: Dictionary = {}  # area_id -> Area3D instance
var loaded_2d_areas: Dictionary = {}  # area_id -> Area2D instance
var transition_points: Array[TransitionPoint] = []

# === AREA MANAGEMENT ===
var all_areas: Dictionary = {}  # area_id -> Area data
var area_connections: Dictionary = {}  # area_id -> Array[connected_area_ids]
var area_loading_timer: float = 0.0
var area_loading_delay: float = 60.0  # 60 seconds before preloading

# === 3D WORLD REFERENCE ===
var world_3d_node: Node3D = null
var world_2d_node: Node2D = null

# === DISTANCE THRESHOLDS ===
const DISTANCE_2D_TO_3D: float = 500.0  # Switch to 3D state when closer
const DISTANCE_3D_TO_2D: float = 500.0  # Switch to 2D state when farther
const DISTANCE_DESPAWN: float = 600.0    # Despawn groups when farther

# === COORDINATE SYSTEM ===
const WORLD_SCALE_2D_TO_3D: float = 1.0  # 1 unit 2D = 1 unit 3D
const AREA_SIZE: Vector2 = Vector2(1000, 1000)  # Each area is 1000x1000 units

signal area_loaded(area_id: String)
signal area_unloaded(area_id: String)
signal npc_state_changed(npc: NPC, from_state: String, to_state: String)

func _ready():
	print("WorldManager initialized")
	
	# Initialize world areas
	call_deferred("initialize_world_areas")
	
	# Connect to events
	EventBus.connect("npc_spawned", _on_npc_spawned)
	GameManager.connect("time_updated", _on_time_updated)

func _process(delta: float):
	if GameManager.is_paused:
		return
	
	# Update area loading timer
	area_loading_timer += delta
	if area_loading_timer >= area_loading_delay:
		area_loading_timer = 0.0
		preload_connected_areas()
	
	# Update NPC states based on distance
	update_npc_states()

func initialize_world_areas():
	"""Create the initial world area structure"""
	
	# Create central areas
	create_area("area_center", Vector2(0, 0), "Central Valley")
	create_area("area_north", Vector2(0, -1000), "Northern Forest")
	create_area("area_south", Vector2(0, 1000), "Southern Wasteland")
	create_area("area_east", Vector2(1000, 0), "Eastern Hills")
	create_area("area_west", Vector2(-1000, 0), "Western Swamps")
	
	# Create connections between areas
	connect_areas("area_center", "area_north")
	connect_areas("area_center", "area_south")
	connect_areas("area_center", "area_east")
	connect_areas("area_center", "area_west")
	
	# Create transition points
	create_transition_point("area_center", "area_north", Vector2(0, -500), Vector2(0, 500))
	create_transition_point("area_center", "area_south", Vector2(0, 500), Vector2(0, -500))
	create_transition_point("area_center", "area_east", Vector2(500, 0), Vector2(-500, 0))
	create_transition_point("area_center", "area_west", Vector2(-500, 0), Vector2(500, 0))
	
	# Load the starting area in 3D
	load_area_3d("area_center")
	
	print("World areas initialized: %d areas, %d transition points" % [all_areas.size(), transition_points.size()])

func create_area(area_id: String, world_position: Vector2, display_name: String):
	"""Create a new area definition"""
	var area_data = Area.new()
	area_data.area_id = area_id
	area_data.world_position = world_position
	area_data.display_name = display_name
	area_data.bounds = Rect2(world_position - AREA_SIZE/2, AREA_SIZE)
	
	all_areas[area_id] = area_data
	area_connections[area_id] = []

func connect_areas(area1_id: String, area2_id: String):
	"""Create bidirectional connection between areas"""
	if area1_id in area_connections:
		if area2_id not in area_connections[area1_id]:
			area_connections[area1_id].append(area2_id)
	
	if area2_id in area_connections:
		if area1_id not in area_connections[area2_id]:
			area_connections[area2_id].append(area1_id)

func create_transition_point(from_area: String, to_area: String, from_pos: Vector2, to_pos: Vector2):
	"""Create a transition point between areas"""
	var transition = TransitionPoint.new()
	transition.from_area_id = from_area
	transition.to_area_id = to_area
	transition.from_position = from_pos
	transition.to_position = to_pos
	transition_points.append(transition)

func get_area_from_position(world_pos: Vector2) -> String:
	"""Get area ID from world position"""
	for area_id in all_areas:
		var area: Area = all_areas[area_id]
		if area.bounds.has_point(world_pos):
			return area_id
	
	return "area_center"  # Default fallback

func get_distance_to_area(from_pos: Vector2, area_id: String) -> float:
	"""Get distance from position to area center"""
	if area_id not in all_areas:
		return INF
	
	var area: Area = all_areas[area_id]
	return from_pos.distance_to(area.world_position)

func load_area_3d(area_id: String):
	"""Load an area in 3D mode"""
	if area_id in active_areas:
		return  # Already loaded
	
	if area_id not in all_areas:
		print("Warning: Trying to load unknown area: %s" % area_id)
		return
	
	# Create 3D area instance
	var area_3d_scene = preload("res://scenes/areas/Area3D.tscn")
	var area_3d_instance = area_3d_scene.instantiate()
	var area_data: Area = all_areas[area_id]
	
	area_3d_instance.setup(area_data)
	
	# Add to 3D world if available
	if world_3d_node:
		world_3d_node.add_child(area_3d_instance)
	
	active_areas[area_id] = area_3d_instance
	
	# Move NPCs in this area to 3D representation
	for npc in NPCManager.get_all_npcs():
		if get_area_from_position(npc.position) == area_id:
			transition_npc_to_3d(npc)
	
	emit_signal("area_loaded", area_id)
	print("Loaded 3D area: %s" % area_id)

func unload_area_3d(area_id: String):
	"""Unload a 3D area"""
	if area_id not in active_areas:
		return
	
	# Move NPCs back to 2D representation
	for npc in NPCManager.get_all_npcs():
		if get_area_from_position(npc.position) == area_id:
			transition_npc_to_2d(npc)
	
	# Remove 3D instance
	var area_3d_instance = active_areas[area_id]
	active_areas.erase(area_id)
	area_3d_instance.queue_free()
	
	emit_signal("area_unloaded", area_id)
	print("Unloaded 3D area: %s" % area_id)

func preload_connected_areas():
	"""Preload all areas connected to currently active areas"""
	var areas_to_load = []
	
	for area_id in active_areas:
		if area_id in area_connections:
			for connected_id in area_connections[area_id]:
				if connected_id not in active_areas and connected_id not in areas_to_load:
					areas_to_load.append(connected_id)
	
	for area_id in areas_to_load:
		load_area_3d(area_id)

func update_npc_states():
	"""Update NPC 2D/3D states based on distance to player"""
	for npc in NPCManager.get_all_npcs():
		if not npc.is_alive():
			continue
		
		var distance_to_player = npc.position.distance_to(player_position)
		var current_state = get_npc_current_state(npc)
		var new_state = determine_npc_state(distance_to_player)
		
		if current_state != new_state:
			transition_npc_state(npc, current_state, new_state)

func get_npc_current_state(npc: NPC) -> String:
	"""Get current representation state of NPC"""
	# Add state tracking to NPC class or use a separate dictionary
	if npc.has_method("get_representation_state"):
		return npc.get_representation_state()
	return "2d"  # Default to 2D

func determine_npc_state(distance_to_player: float) -> String:
	"""Determine what state NPC should be in based on distance"""
	if distance_to_player >= DISTANCE_DESPAWN:
		return "despawned"
	elif distance_to_player > DISTANCE_2D_TO_3D:
		return "2d"
	else:
		return "3d"

func transition_npc_state(npc: NPC, from_state: String, to_state: String):
	"""Transition NPC between 2D/3D states"""
	match to_state:
		"3d":
			transition_npc_to_3d(npc)
		"2d":
			transition_npc_to_2d(npc)
		"despawned":
			despawn_npc(npc)
	
	emit_signal("npc_state_changed", npc, from_state, to_state)

func transition_npc_to_3d(npc: NPC):
	"""Transition NPC to 3D representation"""
	var area_id = get_area_from_position(npc.position)
	
	# Ensure area is loaded in 3D
	if area_id not in active_areas:
		load_area_3d(area_id)
	
	# Create 3D agent if needed
	# This would interact with the visual representation in simulation_world
	if npc.has_method("set_representation_state"):
		npc.set_representation_state("3d")

func transition_npc_to_2d(npc: NPC):
	"""Transition NPC to 2D representation"""
	if npc.has_method("set_representation_state"):
		npc.set_representation_state("2d")

func despawn_npc(npc: NPC):
	"""Temporarily despawn NPC (but keep in memory)"""
	if npc.has_method("set_representation_state"):
		npc.set_representation_state("despawned")

func get_path_between_areas(from_area: String, to_area: String) -> Array[String]:
	"""Get path between areas using transition points"""
	# Simple pathfinding between areas
	if from_area == to_area:
		return [from_area]
	
	# Check direct connection
	if from_area in area_connections and to_area in area_connections[from_area]:
		return [from_area, to_area]
	
	# TODO: Implement proper pathfinding for multi-hop paths
	return [from_area]

func get_transition_point(from_area: String, to_area: String) -> TransitionPoint:
	"""Get transition point between two areas"""
	for transition in transition_points:
		if transition.from_area_id == from_area and transition.to_area_id == to_area:
			return transition
	return null

func convert_2d_to_3d_position(pos_2d: Vector2, area_id: String = "") -> Vector3:
	"""Convert 2D world position to 3D local position"""
	if area_id == "":
		area_id = get_area_from_position(pos_2d)
	
	if area_id not in all_areas:
		return Vector3(pos_2d.x, 0, pos_2d.y)
	
	var area: Area = all_areas[area_id]
	var local_pos = pos_2d - area.world_position
	
	return Vector3(local_pos.x * WORLD_SCALE_2D_TO_3D, 0, local_pos.y * WORLD_SCALE_2D_TO_3D)

func convert_3d_to_2d_position(pos_3d: Vector3, area_id: String) -> Vector2:
	"""Convert 3D local position to 2D world position"""
	if area_id not in all_areas:
		return Vector2(pos_3d.x, pos_3d.z)
	
	var area: Area = all_areas[area_id]
	var local_2d = Vector2(pos_3d.x / WORLD_SCALE_2D_TO_3D, pos_3d.z / WORLD_SCALE_2D_TO_3D)
	
	return area.world_position + local_2d

func set_world_nodes(world_2d: Node2D, world_3d: Node3D):
	"""Set references to 2D and 3D world nodes"""
	world_2d_node = world_2d
	world_3d_node = world_3d

func update_player_position(new_position: Vector2):
	"""Update player position and check for area changes"""
	var old_area = get_area_from_position(player_position)
	player_position = new_position
	var new_area = get_area_from_position(player_position)
	
	if old_area != new_area:
		current_area_id = new_area
		area_loading_timer = 0.0  # Reset loading timer on area change
		
		# Ensure new area is loaded
		if new_area not in active_areas:
			load_area_3d(new_area)

func _on_npc_spawned(npc: NPC):
	"""Handle new NPC spawning"""
	# Set initial state based on distance to player
	var distance = npc.position.distance_to(player_position)
	var state = determine_npc_state(distance)
	transition_npc_state(npc, "spawning", state)

func _on_time_updated(time: float, day: int):
	"""Handle game time updates"""
	# Could be used for time-based area events
	pass

func get_world_statistics() -> Dictionary:
	"""Get world management statistics"""
	return {
		"current_area": current_area_id,
		"active_3d_areas": active_areas.size(),
		"total_areas": all_areas.size(),
		"transition_points": transition_points.size(),
		"player_position": {"x": player_position.x, "y": player_position.y}
	}