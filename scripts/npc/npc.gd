# scripts/npc/npc.gd
class_name NPC
extends RefCounted

# === IDENTYFIKACJA ===
var npc_id: String
var name: String
var age: int
var gender: String = "male"  # "male" or "female"

# === STATYSTYKI PODSTAWOWE (0-100) ===
var strength: int = 50
var endurance: int = 50
var intelligence: int = 50
var charisma: int = 50
var perception: int = 50
var agility: int = 50
var luck: int = 50

# === UMIEJĘTNOŚCI (0-100) ===
var combat_skill: int = 0
var trade_skill: int = 0
var tech_skill: int = 0
var medical_skill: int = 0
var research_skill: int = 0
var survival_skill: int = 0
var leadership_skill: int = 0

# === CECHY OSOBOWOŚCI (0-100) ===
var morality: int = 50
var courage: int = 50
var greed: int = 50
var loyalty: int = 50
var aggression: int = 50
var sociability: int = 50
var ambition: int = 50

# === STAN FIZYCZNY ===
var health: int = 100
var fatigue: int = 0
var stress: int = 0

# === POTRZEBY MVP (0-100, 100 = fully satisfied) ===
var needs: Dictionary = {
	NPCNeed.HUNGER: 100,
	NPCNeed.SHELTER: 100,
	NPCNeed.COMPANIONSHIP: 100,
	NPCNeed.WEALTH: 100,
	NPCNeed.EXPLORATION: 100,
	NPCNeed.COMBAT: 100
}

# === RELACJE ===
var group: Group = null
var relationships: Dictionary = {}  # npc_id -> relationship_value (-100 to 100)

# === AI I POZYCJA ===
var brain: NPCBrain
var position: Vector2
var target_position: Vector2
var position_3d: Vector3 = Vector3()  # For hybrid 2D/3D support
var target_position_3d: Vector3 = Vector3()  # For hybrid 2D/3D support
var movement_speed: float = 50.0
var velocity: Vector2 = Vector2()  # Current velocity in 2D
var velocity_3d: Vector3 = Vector3()  # Current velocity in 3D

# === HYBRID MODE SUPPORT ===
var current_mode: WorldManager.WorldMode = WorldManager.WorldMode.MODE_2D
var ai_can_change_modes: bool = true
var preferred_mode: WorldManager.WorldMode = WorldManager.WorldMode.MODE_2D
var hybrid_agent: HybridNPCAgent = null

# === NAVIGATION ===
var navigation_agent: NavigationAgent2D = null
var navigation_agent_3d: NavigationAgent3D = null
var navigation_update_timer: float = 0.0
var navigation_update_interval: float = 0.5  # Update path every 0.5 seconds
var is_navigating: bool = false
var stuck_timer: float = 0.0
var last_position: Vector2
var last_position_3d: Vector3 = Vector3()

# === LOD SYSTEM ===
var current_lod_level: int = 0
var ai_update_complexity: float = 1.0

# === GROUP RELATIONSHIPS ===
var is_group_leader: bool = false
var group_specialization: Group.GroupSpecialization = Group.GroupSpecialization.UNIVERSAL

# === STATE TRACKING ===
var alertness_level: int = 0  # 0 = relaxed, 3 = high alert
var morale: float = 100.0
var memory: NPCMemory  # Will be set up in _init

# === INVENTORY ===
var inventory: NPCInventory

# === IMPORTANCE ===
var importance: int = NPCImportance.REGULAR

enum NPCNeed {
	HUNGER,
	SHELTER,
	COMPANIONSHIP,
	WEALTH,
	EXPLORATION,
	COMBAT
}

enum NPCImportance {
	DISPOSABLE,
	REGULAR,
	NOTABLE,
	LEGENDARY
}

func _init():
	npc_id = generate_unique_id()
	brain = NPCBrain.new()
	brain.owner_npc = self
	inventory = NPCInventory.new()
	inventory.owner_npc = self
	memory = NPCMemory.new()
	memory.owner_npc = self
	last_position = position
	last_position_3d = position_3d

func generate_unique_id() -> String:
	return "npc_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

func set_navigation_agent(agent: NavigationAgent2D):
	navigation_agent = agent
	if navigation_agent:
		# Configure navigation agent
		navigation_agent.path_desired_distance = 4.0
		navigation_agent.target_desired_distance = 4.0
		navigation_agent.path_max_distance = 6.0
		navigation_agent.navigation_layers = 1
		navigation_agent.avoidance_enabled = true
		navigation_agent.radius = 2.0
		navigation_agent.max_speed = movement_speed

func update(delta: float):
	# Update needs
	update_needs(delta)
	
	# Update AI
	brain.update(delta)
	
	# Update navigation
	update_navigation(delta)
	
	# Update movement
	update_movement(delta)

func update_needs(delta: float):
	# Decay rates per hour (game time)
	var decay_rates = {
		NPCNeed.HUNGER: 2.0,
		NPCNeed.SHELTER: 1.0,
		NPCNeed.COMPANIONSHIP: 0.5,
		NPCNeed.WEALTH: 0.2,
		NPCNeed.EXPLORATION: 0.3,
		NPCNeed.COMBAT: 0.1
	}
	
	for need_type in needs:
		var decay = decay_rates[need_type] * delta
		needs[need_type] = max(0, needs[need_type] - decay)
		
		# Check for critical needs
		if needs[need_type] < 20:
			EventBus.emit_signal("npc_need_critical", self, need_type)

func update_navigation(delta: float):
	if not navigation_agent:
		return
	
	navigation_update_timer += delta
	
	# Update navigation path periodically
	if navigation_update_timer >= navigation_update_interval:
		navigation_update_timer = 0.0
		
		if position.distance_to(target_position) > 1.0:
			set_navigation_target(target_position)
		else:
			is_navigating = false
	
	# Check if stuck
	if is_navigating:
		if position.distance_to(last_position) < 0.1:
			stuck_timer += delta
			if stuck_timer > 2.0:  # Stuck for 2 seconds
				handle_stuck_state()
		else:
			stuck_timer = 0.0
			last_position = position

func update_movement(delta: float):
	if not navigation_agent or not is_navigating:
		# Simple direct movement when no navigation agent
		if position.distance_to(target_position) > 0.1:
			var direction = (target_position - position).normalized()
			var move_distance = movement_speed * delta
			
			if position.distance_to(target_position) <= move_distance:
				position = target_position
			else:
				position += direction * move_distance
		return
	
	# Navigation-based movement
	if navigation_agent.is_navigation_finished():
		is_navigating = false
		return
	
	var next_position = navigation_agent.get_next_path_position()
	var direction = (next_position - position).normalized()
	var move_distance = movement_speed * delta
	
	# Check distance to next waypoint
	if position.distance_to(next_position) <= move_distance:
		position = next_position
	else:
		position += direction * move_distance

func set_navigation_target(new_target: Vector2):
	target_position = new_target
	
	if navigation_agent:
		navigation_agent.target_position = target_position
		is_navigating = true
		navigation_update_timer = 0.0

func handle_stuck_state():
	stuck_timer = 0.0
	
	# Try a slight random offset to unstick
	var random_offset = Vector2(
		randf_range(-10, 10),
		randf_range(-10, 10)
	)
	
	set_navigation_target(target_position + random_offset)
	
	# Notify brain that we're stuck
	if brain and brain.current_goal:
		brain.current_goal.handle_navigation_stuck()

func can_reach_position(check_position: Vector2) -> bool:
	if not navigation_agent:
		return true  # Assume reachable if no navigation
	
	# Quick distance check first
	if position.distance_to(check_position) > 1000:
		return false
	
	# Use navigation to check if path exists
	navigation_agent.target_position = check_position
	var path = navigation_agent.get_current_navigation_path()
	
	return path.size() > 0

func get_path_distance_to(check_position: Vector2) -> float:
	if not navigation_agent:
		return position.distance_to(check_position)
	
	navigation_agent.target_position = check_position
	var path = navigation_agent.get_current_navigation_path()
	
	if path.is_empty():
		return INF
	
	# Calculate total path distance
	var total_distance = 0.0
	var current_pos = position
	
	for waypoint in path:
		total_distance += current_pos.distance_to(waypoint)
		current_pos = waypoint
	
	return total_distance

func stop_movement():
	is_navigating = false
	target_position = position
	if navigation_agent:
		navigation_agent.target_position = position

func get_movement_speed_modifier() -> float:
	var modifier = 1.0
	
	# Fatigue reduces speed
	modifier *= (100 - fatigue) / 100.0
	
	# Health affects speed
	if health < 50:
		modifier *= 0.5 + (health / 100.0)
	
	# Overloaded inventory
	if inventory.is_overloaded():
		modifier *= (1.0 - inventory.get_weight_penalty())
	
	return max(0.1, modifier)

func update_movement_speed():
	var base_speed = 50.0
	movement_speed = base_speed * get_movement_speed_modifier()
	
	if navigation_agent:
		navigation_agent.max_speed = movement_speed

func get_most_urgent_need() -> int:
	var most_urgent = NPCNeed.HUNGER
	var lowest_value = 100
	
	for need_type in needs:
		if needs[need_type] < lowest_value:
			lowest_value = needs[need_type]
			most_urgent = need_type
	
	return most_urgent if lowest_value < 70 else -1

func satisfy_need(need_type: int, amount: float):
	if need_type in needs:
		needs[need_type] = min(100, needs[need_type] + amount)

func get_relationship_with(other_npc: NPC) -> float:
	if other_npc.npc_id in relationships:
		return relationships[other_npc.npc_id]
	return 0.0

func set_relationship_with(other_npc: NPC, value: float):
	relationships[other_npc.npc_id] = clamp(value, -100, 100)

func get_net_worth() -> int:
	return inventory.calculate_total_value()

func is_alive() -> bool:
	return health > 0

func die(killer: NPC = null):
	health = 0
	EventBus.emit_signal("npc_died", self, killer)

func get_combat_effectiveness() -> float:
	var effectiveness = combat_skill / 100.0
	effectiveness *= (health / 100.0)
	effectiveness *= (100 - fatigue) / 100.0
	effectiveness *= inventory.get_equipment_modifier()
	return effectiveness

func to_dict() -> Dictionary:
	return {
		"npc_id": npc_id,
		"name": name,
		"age": age,
		"gender": gender,
		"position": {"x": position.x, "y": position.y},
		"health": health,
		"needs": needs,
		"group_id": group.group_id if group else "",
		"importance": importance
	}
# === NAVIGATION HELPERS ===
func get_navigation_path_to(target_pos: Vector2) -> PackedVector2Array:
	"""Get navigation path to target position"""
	if navigation_agent:
		navigation_agent.target_position = target_pos
		return navigation_agent.get_current_navigation_path()
	else:
		# Fallback to POIManager's navigation
		return POIManager.get_navigation_path(position, target_pos)

func can_see_position(check_position: Vector2) -> bool:
	"""Check if there's a clear line of sight to position"""
	# Use physics raycast in the future, for now just distance check
	return position.distance_to(check_position) <= perception * 2.0

func find_cover_position(threat_position: Vector2) -> Vector2:
	"""Find a position that provides cover from threat"""
	# Simple implementation - move away from threat
	var away_direction = (position - threat_position).normalized()
	var cover_distance = 20.0
	var potential_cover = position + away_direction * cover_distance
	
	# Check if cover position is navigable
	if can_reach_position(potential_cover):
		return potential_cover
	
	# Try different angles
	for i in range(8):
		var angle = (PI / 4) * i
		var rotated_direction = away_direction.rotated(angle)
		potential_cover = position + rotated_direction * cover_distance
		
		if can_reach_position(potential_cover):
			return potential_cover
	
	# No good cover found
	return position

func move_to_position_with_avoidance(target_pos: Vector2, avoid_positions: Array[Vector2], avoid_radius: float = 10.0):
	"""Navigate to target while avoiding certain positions"""
	if not navigation_agent:
		set_navigation_target(target_pos)
		return
	
	# This would be more complex in practice, using NavigationObstacle2D
	# For now, just check if path goes too close to avoid positions
	var path = get_navigation_path_to(target_pos)
	
	for avoid_pos in avoid_positions:
		for point in path:
			if point.distance_to(avoid_pos) < avoid_radius:
				# Path goes too close, find alternative
				var offset = Vector2(avoid_radius, 0).rotated(randf() * TAU)
				var alt_target = target_pos + offset
				set_navigation_target(alt_target)
				return
	
	# Path is clear
	set_navigation_target(target_pos)

func patrol_between_points(waypoints: Array[Vector2], current_waypoint_index: int = 0) -> int:
	"""Patrol between multiple waypoints, returns next waypoint index"""
	if waypoints.is_empty():
		return 0
	
	var current_waypoint = waypoints[current_waypoint_index]
	
	# Check if reached current waypoint
	if position.distance_to(current_waypoint) < 4.0:
		# Move to next waypoint
		current_waypoint_index = (current_waypoint_index + 1) % waypoints.size()
		set_navigation_target(waypoints[current_waypoint_index])
	elif not is_navigating:
		# Not navigating but haven't reached waypoint - restart navigation
		set_navigation_target(current_waypoint)
	
	return current_waypoint_index

func follow_target_at_distance(target: NPC, desired_distance: float = 10.0):
	"""Follow another NPC while maintaining distance"""
	if not target or not target.is_alive():
		stop_movement()
		return
	
	var distance_to_target = position.distance_to(target.position)
	
	if distance_to_target > desired_distance + 4.0:
		# Too far - move closer
		set_navigation_target(target.position)
	elif distance_to_target < desired_distance - 4.0:
		# Too close - move away
		var away_direction = (position - target.position).normalized()
		var retreat_position = position + away_direction * 8.0
		if can_reach_position(retreat_position):
			set_navigation_target(retreat_position)
		else:
			stop_movement()
	else:
		# Good distance - stop or slow down
		if is_navigating and abs(distance_to_target - desired_distance) < 2.0:
			stop_movement()

func find_nearest_navigable_position(target_pos: Vector2, search_radius: float = 10.0) -> Vector2:
	"""Find the nearest position that can be navigated to"""
	# First check if target is already navigable
	if POIManager.is_position_navigable(target_pos):
		return target_pos
	
	# Search in expanding circles
	var angles = 8
	var rings = 3
	
	for ring in range(1, rings + 1):
		var radius = (ring / float(rings)) * search_radius
		
		for i in range(angles):
			var angle = (TAU / angles) * i
			var test_pos = target_pos + Vector2.RIGHT.rotated(angle) * radius
			
			if POIManager.is_position_navigable(test_pos):
				return test_pos
	
	# No navigable position found nearby
	return position  # Stay where we are

func get_escape_routes(threat_position: Vector2, num_routes: int = 3) -> Array[Vector2]:
	"""Find multiple escape routes away from threat"""
	var escape_routes: Array[Vector2] = []
	var escape_distance = 30.0
	
	# Get general escape direction (away from threat)
	var escape_direction = (position - threat_position).normalized()
	
	# Try different angles around the escape direction
	var angle_spread = PI / 3  # 60 degree spread
	
	for i in range(num_routes):
		var angle_offset = (i - num_routes/2) * (angle_spread / num_routes)
		var route_direction = escape_direction.rotated(angle_offset)
		var escape_position = position + route_direction * escape_distance
		
		# Check if route is viable
		if can_reach_position(escape_position):
			escape_routes.append(escape_position)
	
	return escape_routes

func navigate_around_obstacle(obstacle_center: Vector2, obstacle_radius: float, final_target: Vector2):
	"""Navigate around a circular obstacle to reach target"""
	var to_target = final_target - position
	var to_obstacle = obstacle_center - position
	
	# Check if we need to go around
	var closest_point_on_line = position + to_target.normalized() * to_target.dot(to_obstacle.normalized())
	var distance_to_obstacle = closest_point_on_line.distance_to(obstacle_center)
	
	if distance_to_obstacle < obstacle_radius * 1.5:
		# Need to go around - choose shortest path
		var cross_product = to_target.cross(to_obstacle)
		var go_left = cross_product > 0
		
		var angle = PI / 3  # 60 degrees around
		if go_left:
			angle = -angle
		
		var waypoint_direction = (obstacle_center - position).normalized().rotated(angle)
		var waypoint = obstacle_center + waypoint_direction * (obstacle_radius * 1.5)
		
		set_navigation_target(waypoint)
	else:
		# Direct path is clear
		set_navigation_target(final_target)

func estimate_travel_time_to(target_pos: Vector2) -> float:
	"""Estimate time in seconds to reach target position"""
	var path_distance = get_path_distance_to(target_pos)
	if path_distance == INF:
		return INF
	
	var effective_speed = movement_speed * get_movement_speed_modifier()
	return path_distance / effective_speed

func find_nearest_poi_by_path() -> POI:
	"""Find the POI that's actually closest by navigation path, not straight line"""
	var nearest_poi: POI = null
	var shortest_path: float = INF
	
	for poi in POIManager.get_all_pois():
		var path_distance = get_path_distance_to(poi.position)
		if path_distance < shortest_path:
			shortest_path = path_distance
			nearest_poi = poi
	
	return nearest_poi

# === GROUP MOVEMENT HELPERS ===
func move_in_formation(formation_position: Vector2, leader: NPC, formation_type: String = "line"):
	"""Move while maintaining formation with group"""
	if not leader or not leader.is_alive():
		return
	
	var target_pos: Vector2
	
	match formation_type:
		"line":
			# Simple line formation behind leader
			var leader_direction = leader.get_facing_direction()
			target_pos = leader.position - leader_direction * formation_position.x
			target_pos += leader_direction.rotated(PI/2) * formation_position.y
			
		"wedge":
			# V formation
			var leader_direction = leader.get_facing_direction()
			target_pos = leader.position - leader_direction * formation_position.x
			target_pos += leader_direction.rotated(PI/4 * sign(formation_position.y)) * abs(formation_position.y)
			
		"circle":
			# Circular formation around point
			var angle = formation_position.x
			var radius = formation_position.y
			target_pos = leader.position + Vector2.RIGHT.rotated(angle) * radius
			
		_:
			target_pos = leader.position + formation_position
	
	# Only update navigation if significantly different from current target
	if target_pos.distance_to(target_position) > 2.0:
		set_navigation_target(target_pos)

func get_facing_direction() -> Vector2:
	"""Get the direction NPC is facing based on movement"""
	if is_navigating and navigation_agent:
		var next_pos = navigation_agent.get_next_path_position()
		return (next_pos - position).normalized()
	elif target_position.distance_to(position) > 0.1:
		return (target_position - position).normalized()
	else:
		# Default to facing right if stationary
		return Vector2.RIGHT

# === HYBRID 2D/3D MODE SUPPORT ===

func setup_hybrid_agent():
	"""Initialize the hybrid agent for 2D/3D mode switching"""
	if not hybrid_agent:
		hybrid_agent = HybridNPCAgent.new(self)

func set_lod_level(lod_level: int):
	"""Set Level of Detail level for performance optimization"""
	current_lod_level = lod_level
	
	# Adjust AI complexity based on LOD
	match lod_level:
		0:  # Highest detail
			ai_update_complexity = 1.0
		1:  # High detail
			ai_update_complexity = 0.8
		2:  # Medium detail
			ai_update_complexity = 0.5
		3:  # Low detail
			ai_update_complexity = 0.2
		_:  # Very low detail or culled
			ai_update_complexity = 0.1

func update_ai(delta: float):
	"""Update AI with complexity scaling"""
	if brain and ai_update_complexity > 0.1:
		brain.update(delta * ai_update_complexity)

func update_basic_state(delta: float):
	"""Update only basic NPC state (used when AI complexity is very low)"""
	update_needs(delta * 0.5)  # Slower need decay when not actively simulated
	
	# Basic movement without complex AI
	if position.distance_to(target_position) > 1.0:
		var direction = (target_position - position).normalized()
		position += direction * movement_speed * delta * 0.5

func is_in_combat() -> bool:
	"""Check if NPC is currently in combat"""
	return brain.current_goal and brain.current_goal.goal_type == Goal.GoalType.COMBAT

func can_transition_modes() -> bool:
	"""Check if NPC can switch between 2D and 3D modes"""
	return ai_can_change_modes and not is_in_combat()

func set_current_mode(new_mode: WorldManager.WorldMode):
	"""Set the current world mode for this NPC"""
	if current_mode != new_mode:
		current_mode = new_mode
		
		# Update navigation agent reference based on mode
		if hybrid_agent:
			hybrid_agent.set_mode(new_mode)

func get_position_for_mode(mode: WorldManager.WorldMode) -> Vector2:
	"""Get position in the specified mode (returns 2D position for both modes)"""
	if mode == WorldManager.WorldMode.MODE_2D:
		return position
	else:
		return WorldManager.coordinate_converter.convert_3d_to_2d(position_3d)

func set_navigation_target_for_mode(target: Vector2, mode: WorldManager.WorldMode = WorldManager.WorldMode.MODE_2D):
	"""Set navigation target for specified mode"""
	if mode == WorldManager.WorldMode.MODE_2D:
		set_navigation_target(target)
	else:
		var target_3d = WorldManager.coordinate_converter.convert_2d_to_3d(target)
		set_navigation_target_3d(target_3d)

func set_navigation_target_3d(target_3d: Vector3):
	"""Set 3D navigation target"""
	target_position_3d = target_3d
	
	if navigation_agent_3d:
		navigation_agent_3d.target_position = target_3d
		is_navigating = true

func get_interaction_range_for_mode(mode: WorldManager.WorldMode) -> float:
	"""Get interaction range based on current mode"""
	if mode == WorldManager.WorldMode.MODE_2D:
		return 15.0  # Larger range in 2D top-down view
	else:
		return 5.0   # Smaller range in 3D first-person view

func can_interact_with_npc(other_npc: NPC) -> bool:
	"""Check if this NPC can interact with another NPC in current mode"""
	var my_pos = get_position_for_mode(current_mode)
	var other_pos = other_npc.get_position_for_mode(current_mode)
	var interaction_range = get_interaction_range_for_mode(current_mode)
	
	return my_pos.distance_to(other_pos) <= interaction_range

func get_debug_info_hybrid() -> Dictionary:
	"""Get debug information including hybrid mode data"""
	var base_info = to_dict()
	
	base_info["current_mode"] = WorldManager.WorldMode.keys()[current_mode]
	base_info["position_3d"] = {"x": position_3d.x, "y": position_3d.y, "z": position_3d.z}
	base_info["can_change_modes"] = ai_can_change_modes
	base_info["preferred_mode"] = WorldManager.WorldMode.keys()[preferred_mode]
	base_info["lod_level"] = current_lod_level
	base_info["ai_complexity"] = ai_update_complexity
	base_info["is_group_leader"] = is_group_leader
	base_info["alertness_level"] = alertness_level
	base_info["morale"] = morale
	
	return base_info
