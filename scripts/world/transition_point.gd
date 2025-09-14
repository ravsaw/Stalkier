# scripts/world/transition_point.gd
class_name TransitionPoint
extends RefCounted

# === IDENTIFICATION ===
var transition_id: String
var from_area_id: String
var to_area_id: String

# === SPATIAL PROPERTIES ===
var from_position: Vector2  # Position in the source area
var to_position: Vector2    # Position in the destination area
var activation_radius: float = 10.0  # Distance to trigger transition

# === TRANSITION PROPERTIES ===
var transition_type: int = TransitionType.SEAMLESS
var loading_time: float = 0.0  # Time to load destination area
var is_bidirectional: bool = true
var requires_key: bool = false
var key_item_id: String = ""

# === STATE ===
var is_active: bool = true
var last_used: float = 0.0
var usage_count: int = 0

# === NAVIGATION ===
var approach_waypoints: Array[Vector2] = []  # Waypoints to guide NPCs to transition
var exit_waypoints: Array[Vector2] = []      # Waypoints after transition

enum TransitionType {
	SEAMLESS,       # Instant transition
	LOADING,        # Requires loading time
	TELEPORT,       # Instant teleport with effect
	GRADUAL         # Smooth movement transition
}

func _init():
	transition_id = generate_unique_id()

func generate_unique_id() -> String:
	"""Generate unique transition point ID"""
	return "transition_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

func setup(from_area: String, to_area: String, from_pos: Vector2, to_pos: Vector2):
	"""Set up basic transition point"""
	from_area_id = from_area
	to_area_id = to_area
	from_position = from_pos
	to_position = to_pos

func can_npc_use_transition(npc: NPC) -> bool:
	"""Check if an NPC can use this transition point"""
	if not is_active:
		return false
	
	# Check if NPC is close enough
	if npc.position.distance_to(from_position) > activation_radius:
		return false
	
	# Check key requirement
	if requires_key and npc.inventory:
		if not npc.inventory.has_item(key_item_id):
			return false
	
	return true

func can_group_use_transition(group: Group) -> bool:
	"""Check if a group can use this transition point"""
	if not is_active:
		return false
	
	if not group.leader:
		return false
	
	# Check if group leader is close enough
	if group.leader.position.distance_to(from_position) > activation_radius:
		return false
	
	# Check key requirement for leader
	if requires_key and group.leader.inventory:
		if not group.leader.inventory.has_item(key_item_id):
			return false
	
	return true

func execute_transition(npc: NPC) -> bool:
	"""Execute transition for a single NPC"""
	if not can_npc_use_transition(npc):
		return false
	
	# Record usage
	last_used = Time.get_unix_time_from_system()
	usage_count += 1
	
	# Move NPC to destination
	npc.position = to_position
	npc.target_position = to_position
	
	# Reset navigation
	if npc.navigation_agent:
		npc.set_navigation_target(to_position)
	
	# Emit transition event
	EventBus.emit_signal("npc_transitioned", npc, from_area_id, to_area_id, self)
	
	return true

func execute_group_transition(group: Group) -> bool:
	"""Execute transition for an entire group"""
	if not can_group_use_transition(group):
		return false
	
	var successfully_transitioned: Array[NPC] = []
	
	# Transition all group members
	for member in group.members:
		if execute_transition(member):
			successfully_transitioned.append(member)
	
	# Emit group transition event
	if successfully_transitioned.size() > 0:
		EventBus.emit_signal("group_transitioned", group, from_area_id, to_area_id, self)
		return true
	
	return false

func get_approach_waypoint_for_npc(npc: NPC) -> Vector2:
	"""Get the best approach waypoint for an NPC"""
	if approach_waypoints.is_empty():
		return from_position
	
	var best_waypoint = approach_waypoints[0]
	var shortest_distance = npc.position.distance_to(best_waypoint)
	
	for waypoint in approach_waypoints:
		var distance = npc.position.distance_to(waypoint)
		if distance < shortest_distance:
			shortest_distance = distance
			best_waypoint = waypoint
	
	return best_waypoint

func get_exit_waypoint() -> Vector2:
	"""Get a waypoint for NPCs after transition"""
	if exit_waypoints.is_empty():
		# Generate default exit position slightly away from transition
		var direction = Vector2.RIGHT.rotated(randf() * TAU)
		return to_position + direction * 20.0
	
	return exit_waypoints[randi() % exit_waypoints.size()]

func add_approach_waypoint(position: Vector2):
	"""Add an approach waypoint"""
	if position not in approach_waypoints:
		approach_waypoints.append(position)

func add_exit_waypoint(position: Vector2):
	"""Add an exit waypoint"""
	if position not in exit_waypoints:
		exit_waypoints.append(position)

func get_navigation_path_to_transition(from_pos: Vector2) -> PackedVector2Array:
	"""Get navigation path from position to this transition point"""
	# If we have approach waypoints, use them
	if not approach_waypoints.is_empty():
		var best_waypoint = from_pos
		var shortest_distance = INF
		
		for waypoint in approach_waypoints:
			var distance = from_pos.distance_to(waypoint)
			if distance < shortest_distance:
				shortest_distance = distance
				best_waypoint = waypoint
		
		# Return path through best waypoint to transition
		return PackedVector2Array([from_pos, best_waypoint, from_position])
	
	# Direct path to transition
	return PackedVector2Array([from_pos, from_position])

func is_npc_approaching(npc: NPC, approach_distance: float = 50.0) -> bool:
	"""Check if NPC is approaching this transition point"""
	var distance = npc.position.distance_to(from_position)
	
	if distance > approach_distance:
		return false
	
	# Check if NPC is moving towards the transition
	var direction_to_transition = (from_position - npc.position).normalized()
	var npc_direction = (npc.target_position - npc.position).normalized()
	
	var dot_product = direction_to_transition.dot(npc_direction)
	return dot_product > 0.5  # NPC is generally moving towards transition

func get_reverse_transition() -> TransitionPoint:
	"""Create a reverse transition point"""
	var reverse = TransitionPoint.new()
	reverse.from_area_id = to_area_id
	reverse.to_area_id = from_area_id
	reverse.from_position = to_position
	reverse.to_position = from_position
	reverse.activation_radius = activation_radius
	reverse.transition_type = transition_type
	reverse.loading_time = loading_time
	reverse.is_bidirectional = is_bidirectional
	reverse.requires_key = requires_key
	reverse.key_item_id = key_item_id
	
	return reverse

func get_congestion_level() -> float:
	"""Get congestion level at this transition point"""
	var nearby_npcs = 0
	var search_radius = activation_radius * 2.0
	
	for npc in NPCManager.get_all_npcs():
		if npc.position.distance_to(from_position) <= search_radius:
			nearby_npcs += 1
	
	# Return congestion as ratio (0.0 = empty, 1.0+ = very crowded)
	return nearby_npcs / 10.0

func should_queue_transitions() -> bool:
	"""Check if transitions should be queued due to congestion"""
	return get_congestion_level() > 0.5

func get_queue_position(npc: NPC) -> int:
	"""Get NPC's position in transition queue"""
	var nearby_npcs: Array[NPC] = []
	var search_radius = activation_radius * 3.0
	
	for check_npc in NPCManager.get_all_npcs():
		if check_npc.position.distance_to(from_position) <= search_radius:
			if is_npc_approaching(check_npc):
				nearby_npcs.append(check_npc)
	
	# Sort by distance to transition
	nearby_npcs.sort_custom(func(a, b): return a.position.distance_to(from_position) < b.position.distance_to(from_position))
	
	# Find NPC's position in queue
	for i in range(nearby_npcs.size()):
		if nearby_npcs[i] == npc:
			return i
	
	return -1

func get_estimated_wait_time(npc: NPC) -> float:
	"""Get estimated wait time for NPC to use transition"""
	if not should_queue_transitions():
		return 0.0
	
	var queue_position = get_queue_position(npc)
	if queue_position == -1:
		return 0.0
	
	# Assume 3 seconds per transition
	var base_transition_time = 3.0
	return queue_position * base_transition_time

func to_dict() -> Dictionary:
	"""Convert to dictionary for serialization"""
	return {
		"transition_id": transition_id,
		"from_area_id": from_area_id,
		"to_area_id": to_area_id,
		"from_position": {"x": from_position.x, "y": from_position.y},
		"to_position": {"x": to_position.x, "y": to_position.y},
		"activation_radius": activation_radius,
		"transition_type": transition_type,
		"loading_time": loading_time,
		"is_bidirectional": is_bidirectional,
		"requires_key": requires_key,
		"key_item_id": key_item_id,
		"is_active": is_active,
		"usage_count": usage_count
	}

func from_dict(data: Dictionary):
	"""Load from dictionary"""
	transition_id = data.get("transition_id", "")
	from_area_id = data.get("from_area_id", "")
	to_area_id = data.get("to_area_id", "")
	
	var from_pos_data = data.get("from_position", {"x": 0, "y": 0})
	from_position = Vector2(from_pos_data.x, from_pos_data.y)
	
	var to_pos_data = data.get("to_position", {"x": 0, "y": 0})
	to_position = Vector2(to_pos_data.x, to_pos_data.y)
	
	activation_radius = data.get("activation_radius", 10.0)
	transition_type = data.get("transition_type", TransitionType.SEAMLESS)
	loading_time = data.get("loading_time", 0.0)
	is_bidirectional = data.get("is_bidirectional", true)
	requires_key = data.get("requires_key", false)
	key_item_id = data.get("key_item_id", "")
	is_active = data.get("is_active", true)
	usage_count = data.get("usage_count", 0)