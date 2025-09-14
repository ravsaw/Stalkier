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
var movement_speed: float = 50.0

# === NAVIGATION ===
var navigation_agent: NavigationAgent2D = null
var navigation_agent_3d: NavigationAgent3D = null
var navigation_update_timer: float = 0.0
var navigation_update_interval: float = 0.5  # Update path every 0.5 seconds
var is_navigating: bool = false
var stuck_timer: float = 0.0
var last_position: Vector2

# === 2D/3D STATE MANAGEMENT ===
var representation_state: String = "2d"  # "2d", "3d", or "despawned"
var state_transition_timer: float = 0.0
var last_distance_check: float = 0.0
var current_area_id: String = ""
var position_3d: Vector3 = Vector3.ZERO

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
	last_position = position

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

func set_navigation_agent_3d(agent: NavigationAgent3D):
	"""Set the 3D navigation agent for this NPC"""
	navigation_agent_3d = agent
	if navigation_agent_3d:
		# Configure 3D navigation agent
		navigation_agent_3d.path_desired_distance = 4.0
		navigation_agent_3d.target_desired_distance = 4.0
		navigation_agent_3d.path_max_distance = 6.0
		navigation_agent_3d.navigation_layers = 1
		navigation_agent_3d.avoidance_enabled = true
		navigation_agent_3d.radius = 2.0
		navigation_agent_3d.max_speed = movement_speed

func get_representation_state() -> String:
	"""Get current representation state"""
	return representation_state

func set_representation_state(new_state: String):
	"""Set representation state and handle transitions"""
	if representation_state == new_state:
		return
	
	var old_state = representation_state
	representation_state = new_state
	state_transition_timer = 0.0
	
	# Handle state-specific logic
	match new_state:
		"3d":
			# Convert position to 3D coordinates
			position_3d = CoordinateConverter.world_2d_to_local_3d(position, Vector2.ZERO)
			# Use 3D navigation if available
			if navigation_agent_3d:
				navigation_agent_3d.target_position = position_3d
		"2d":
			# Update 2D position from 3D if needed
			if old_state == "3d":
				position = CoordinateConverter.local_3d_to_world_2d(position_3d, Vector2.ZERO)
			# Use 2D navigation
			if navigation_agent:
				navigation_agent.target_position = position
		"despawned":
			# Stop all navigation
			is_navigating = false
	
	# Emit transition event
	EventBus.emit_signal("npc_state_changed", self, old_state, new_state)

func update(delta: float):
	# Skip update if despawned
	if representation_state == "despawned":
		return
	
	# Update needs
	update_needs(delta)
	
	# Update AI
	brain.update(delta)
	
	# Update navigation based on current state
	if representation_state == "3d":
		update_navigation_3d(delta)
		update_movement_3d(delta)
	else:
		update_navigation(delta)
		update_movement(delta)
	
	# Update state transition timer
	state_transition_timer += delta

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
	if representation_state == "3d" and navigation_agent_3d:
		var next_pos = navigation_agent_3d.get_next_path_position()
		var direction_3d = (next_pos - position_3d).normalized()
		return Vector2(direction_3d.x, direction_3d.z)
	elif is_navigating and navigation_agent:
		var next_pos = navigation_agent.get_next_path_position()
		return (next_pos - position).normalized()
	elif target_position.distance_to(position) > 0.1:
		return (target_position - position).normalized()
	else:
		# Default to facing right if stationary
		return Vector2.RIGHT

# === 3D NAVIGATION METHODS ===
func update_navigation_3d(delta: float):
	"""Update 3D navigation"""
	if not navigation_agent_3d:
		return
	
	navigation_update_timer += delta
	
	# Update navigation path periodically
	if navigation_update_timer >= navigation_update_interval:
		navigation_update_timer = 0.0
		
		var target_3d = CoordinateConverter.world_2d_to_local_3d(target_position, Vector2.ZERO)
		if position_3d.distance_to(target_3d) > 1.0:
			set_navigation_target_3d(target_3d)
		else:
			is_navigating = false
	
	# Check if stuck in 3D
	if is_navigating:
		var current_2d = Vector2(position_3d.x, position_3d.z)
		var last_2d = Vector2(last_position.x, last_position.y)
		
		if current_2d.distance_to(last_2d) < 0.1:
			stuck_timer += delta
			if stuck_timer > 2.0:  # Stuck for 2 seconds
				handle_stuck_state_3d()
		else:
			stuck_timer = 0.0
			last_position = current_2d

func update_movement_3d(delta: float):
	"""Update 3D movement"""
	if not navigation_agent_3d or not is_navigating:
		return
	
	if navigation_agent_3d.is_navigation_finished():
		is_navigating = false
		return
	
	var next_position = navigation_agent_3d.get_next_path_position()
	var direction = (next_position - position_3d).normalized()
	var move_distance = movement_speed * delta
	
	# Check distance to next waypoint
	if position_3d.distance_to(next_position) <= move_distance:
		position_3d = next_position
	else:
		position_3d += direction * move_distance
	
	# Update 2D position for compatibility
	position = Vector2(position_3d.x, position_3d.z)

func set_navigation_target_3d(target_3d: Vector3):
	"""Set 3D navigation target"""
	if navigation_agent_3d:
		navigation_agent_3d.target_position = target_3d
		is_navigating = true
		navigation_update_timer = 0.0

func handle_stuck_state_3d():
	"""Handle stuck state in 3D navigation"""
	stuck_timer = 0.0
	
	# Try a slight random offset to unstick
	var random_offset = Vector3(
		randf_range(-10, 10),
		0,
		randf_range(-10, 10)
	)
	
	var target_3d = CoordinateConverter.world_2d_to_local_3d(target_position, Vector2.ZERO)
	set_navigation_target_3d(target_3d + random_offset)
	
	# Notify brain that we're stuck
	if brain and brain.current_goal:
		brain.current_goal.handle_navigation_stuck()

func can_reach_position_3d(check_position: Vector3) -> bool:
	"""Check if NPC can reach a 3D position"""
	if not navigation_agent_3d:
		return true  # Assume reachable if no navigation
	
	# Quick distance check first
	if position_3d.distance_to(check_position) > 1000:
		return false
	
	# Use navigation to check if path exists
	navigation_agent_3d.target_position = check_position
	var path = navigation_agent_3d.get_current_navigation_path()
	
	return path.size() > 0

func get_effective_position() -> Vector2:
	"""Get effective 2D position regardless of current state"""
	if representation_state == "3d":
		return Vector2(position_3d.x, position_3d.z)
	else:
		return position

func get_effective_position_3d() -> Vector3:
	"""Get effective 3D position regardless of current state"""
	if representation_state == "3d":
		return position_3d
	else:
		return Vector3(position.x, 0, position.y)

func transition_to_area(area_id: String, new_position: Vector2):
	"""Transition NPC to a different area"""
	current_area_id = area_id
	position = new_position
	target_position = new_position
	
	# Update 3D position if in 3D mode
	if representation_state == "3d":
		position_3d = CoordinateConverter.world_2d_to_local_3d(position, Vector2.ZERO)
	
	# Reset navigation
	is_navigating = false
	stuck_timer = 0.0
	
	# Emit area transition event
	EventBus.emit_signal("npc_area_changed", self, area_id)
