# scripts/world/npcs/npc_group.gd
extends RefCounted
class_name NPCGroup

## Enhanced NPC Group system for hybrid 2D/3D world
## Manages group behavior, coordination, and mode transitions

# === GROUP IDENTIFICATION ===
var group_id: String = ""
var group_name: String = ""

# === AREA ASSOCIATION ===
var area_id: String = ""
var home_area: Area = null

# === MODE SUPPORT ===
var mode: WorldManager.WorldMode = WorldManager.WorldMode.MODE_2D
var supports_mode_switching: bool = true

# === GROUP MEMBERS ===
var members: Array[NPC] = []
var hybrid_agents: Array[HybridNPCAgent] = []
var leader: NPC = null
var max_members: int = 12

# === GROUP BEHAVIOR ===
var group_specialization: Group.GroupSpecialization = Group.GroupSpecialization.UNIVERSAL
var group_activity: Group.GroupActivity = Group.GroupActivity.WANDERING
var cohesion_strength: float = 0.7  # How tightly group stays together
var formation_type: FormationType = FormationType.LOOSE

enum FormationType { 
	LOOSE,      # Casual grouping
	COLUMN,     # Single file
	WEDGE,      # V formation
	LINE,       # Side by side
	CIRCLE,     # Defensive circle
	SCATTER     # Spread out pattern
}

# === SPATIAL MANAGEMENT ===
var group_center_2d: Vector2 = Vector2()
var group_center_3d: Vector3 = Vector3()
var group_radius: float = 20.0
var formation_spacing: float = 3.0

# === OBJECTIVES ===
var current_objective: GroupObjective = null
var objective_queue: Array[GroupObjective] = []
var patrol_points: Array[Vector2] = []
var current_patrol_index: int = 0

# === COORDINATION ===
var coordination_update_interval: float = 1.0  # Update group coordination every second
var last_coordination_update: float = 0.0
var communication_range: float = 50.0

# === PERFORMANCE ===
var is_active: bool = true
var update_frequency: float = 0.1  # 10 FPS for group updates
var last_update_time: float = 0.0
var performance_scaling: float = 1.0

# === STATE ===
var is_in_combat: bool = false
var is_travelling: bool = false
var morale: float = 100.0
var alertness_level: int = 0  # 0 = relaxed, 3 = high alert

func _init():
	group_id = "group_" + str(randi())

func setup_for_area(area: Area):
	home_area = area
	area_id = area.area_id
	
	# Set group center to a random spawn point in the area
	group_center_2d = area.get_random_spawn_point_2d()
	group_center_3d = area.get_random_spawn_point_3d()
	
	# Generate initial members
	generate_initial_members()
	
	# Set initial patrol points
	generate_patrol_points()
	
	print("NPCGroup: Set up group ", group_id, " in area ", area_id, " with ", members.size(), " members")

func generate_initial_members():
	var member_count = randi_range(3, 8)
	
	for i in range(member_count):
		var npc = create_group_member()
		add_member(npc)
		
		# Create hybrid agent
		var agent = HybridNPCAgent.new(npc)
		agent.set_mode(mode)
		hybrid_agents.append(agent)
		
		# Position near group center
		var offset = Vector2(randf_range(-5, 5), randf_range(-5, 5))
		npc.position = group_center_2d + offset
		agent.position_2d = npc.position
		
		if mode == WorldManager.WorldMode.MODE_3D:
			agent.position_3d = WorldManager.coordinate_converter.convert_2d_to_3d(npc.position)
	
	# Assign leader
	if not members.is_empty():
		assign_leader(members[0])

func create_group_member() -> NPC:
	var npc = NPC.new()
	npc.name = NPCManager.generate_random_name()
	npc.age = randi_range(18, 65)
	NPCManager.randomize_npc_stats(npc)
	NPCManager.give_starting_equipment(npc)
	
	# Set group-specific traits
	npc.group_specialization = group_specialization
	npc.ai_can_change_modes = supports_mode_switching
	
	return npc

func add_member(npc: NPC) -> bool:
	if members.size() >= max_members:
		return false
	
	members.append(npc)
	npc.group = self
	
	# Update group stats
	update_group_morale()
	
	print("NPCGroup: Added member ", npc.name, " to group ", group_id)
	return true

func remove_member(npc: NPC):
	var index = members.find(npc)
	if index >= 0:
		members.remove_at(index)
		npc.group = null
		
		# Remove corresponding agent
		for agent in hybrid_agents:
			if agent.npc == npc:
				hybrid_agents.erase(agent)
				agent.cleanup()
				break
		
		# Reassign leader if necessary
		if leader == npc and not members.is_empty():
			assign_leader(members[0])
		
		update_group_morale()
		print("NPCGroup: Removed member ", npc.name, " from group ", group_id)

func assign_leader(npc: NPC):
	if npc not in members:
		return
	
	# Remove old leader status
	if leader:
		leader.is_group_leader = false
	
	# Assign new leader
	leader = npc
	leader.is_group_leader = true
	
	print("NPCGroup: Assigned ", npc.name, " as leader of group ", group_id)

func generate_patrol_points():
	if not home_area:
		return
	
	patrol_points.clear()
	var num_points = randi_range(3, 6)
	
	for i in range(num_points):
		var point = home_area.get_random_spawn_point_2d()
		# Ensure points are reasonably spaced
		var valid = true
		for existing_point in patrol_points:
			if point.distance_to(existing_point) < 30:
				valid = false
				break
		
		if valid:
			patrol_points.append(point)
	
	if patrol_points.is_empty():
		patrol_points.append(group_center_2d)

func update(delta: float):
	if not is_active or members.is_empty():
		return
	
	last_update_time += delta
	
	if last_update_time >= update_frequency:
		last_update_time = 0.0
		
		# Update group coordination
		update_coordination(delta)
		
		# Update formation
		update_formation()
		
		# Update objectives
		update_objectives(delta)
		
		# Update individual agents
		update_agents(delta)
		
		# Update group state
		update_group_state()

func update_coordination(delta: float):
	last_coordination_update += delta
	
	if last_coordination_update >= coordination_update_interval:
		last_coordination_update = 0.0
		
		# Update group center
		calculate_group_center()
		
		# Check member distances and regroup if necessary
		check_member_cohesion()
		
		# Update communication between members
		update_member_communication()

func calculate_group_center():
	if members.is_empty():
		return
	
	var center_sum_2d = Vector2()
	var center_sum_3d = Vector3()
	var valid_members = 0
	
	for agent in hybrid_agents:
		if agent.is_active:
			center_sum_2d += agent.position_2d
			center_sum_3d += agent.position_3d
			valid_members += 1
	
	if valid_members > 0:
		group_center_2d = center_sum_2d / valid_members
		group_center_3d = center_sum_3d / valid_members

func check_member_cohesion():
	var max_distance = group_radius * 2.0
	var stragglers = []
	
	for agent in hybrid_agents:
		var distance = agent.get_current_position().distance_to(group_center_2d)
		if distance > max_distance:
			stragglers.append(agent)
	
	# Command stragglers to regroup
	for straggler in stragglers:
		command_regroup(straggler)

func command_regroup(agent: HybridNPCAgent):
	# Find a position near the group center for the straggler
	var regroup_position = find_formation_position_for_member(agent)
	
	match mode:
		WorldManager.WorldMode.MODE_2D:
			agent.set_navigation_target_2d(regroup_position)
		WorldManager.WorldMode.MODE_3D:
			agent.set_navigation_target_3d(WorldManager.coordinate_converter.convert_2d_to_3d(regroup_position))

func update_member_communication():
	# NPCs communicate information within the group
	if leader and leader.is_alive():
		# Leader shares information with all members
		var leader_memory = leader.memory
		
		for member in members:
			if member != leader and member.is_alive():
				# Share important memories
				share_memory_between_npcs(leader, member)

func share_memory_between_npcs(from_npc: NPC, to_npc: NPC):
	# Share recent important events
	for memory in from_npc.memory.get_recent_memories(10):
		if memory.importance >= NPCMemory.MemoryImportance.IMPORTANT:
			to_npc.memory.add_shared_memory(memory, from_npc)

func update_formation():
	if members.size() < 2:
		return
	
	match formation_type:
		FormationType.LOOSE:
			update_loose_formation()
		FormationType.COLUMN:
			update_column_formation()
		FormationType.WEDGE:
			update_wedge_formation()
		FormationType.LINE:
			update_line_formation()
		FormationType.CIRCLE:
			update_circle_formation()
		FormationType.SCATTER:
			update_scatter_formation()

func update_loose_formation():
	# Members stay loosely around the leader/center
	for i in range(hybrid_agents.size()):
		var agent = hybrid_agents[i]
		var target_pos = group_center_2d + Vector2(
			randf_range(-group_radius * 0.5, group_radius * 0.5),
			randf_range(-group_radius * 0.5, group_radius * 0.5)
		)
		
		assign_formation_position(agent, target_pos)

func update_column_formation():
	# Single file formation
	if not leader:
		return
	
	var leader_agent = get_agent_for_npc(leader)
	if not leader_agent:
		return
	
	var leader_pos = leader_agent.get_current_position()
	var direction = leader_agent.velocity_2d.normalized()
	
	for i in range(hybrid_agents.size()):
		var agent = hybrid_agents[i]
		if agent.npc == leader:
			continue
		
		var offset = direction * (-formation_spacing * (i + 1))
		var target_pos = leader_pos + offset
		assign_formation_position(agent, target_pos)

func update_wedge_formation():
	# V-shaped formation with leader at front
	if not leader:
		return
	
	var leader_agent = get_agent_for_npc(leader)
	if not leader_agent:
		return
	
	var leader_pos = leader_agent.get_current_position()
	var direction = leader_agent.velocity_2d.normalized()
	var perpendicular = Vector2(-direction.y, direction.x)
	
	var member_index = 0
	for agent in hybrid_agents:
		if agent.npc == leader:
			continue
		
		member_index += 1
		var side = 1 if member_index % 2 == 0 else -1
		var distance_back = formation_spacing * ((member_index + 1) / 2)
		var distance_side = formation_spacing * ((member_index + 1) / 2) * side
		
		var offset = direction * (-distance_back) + perpendicular * distance_side
		var target_pos = leader_pos + offset
		assign_formation_position(agent, target_pos)

func update_line_formation():
	# Side by side formation
	var direction = Vector2(1, 0)  # Default direction
	if leader:
		var leader_agent = get_agent_for_npc(leader)
		if leader_agent and leader_agent.velocity_2d.length() > 0.1:
			direction = leader_agent.velocity_2d.normalized()
	
	var perpendicular = Vector2(-direction.y, direction.x)
	var center = group_center_2d
	
	for i in range(hybrid_agents.size()):
		var agent = hybrid_agents[i]
		var offset_distance = (i - hybrid_agents.size() / 2.0) * formation_spacing
		var target_pos = center + perpendicular * offset_distance
		assign_formation_position(agent, target_pos)

func update_circle_formation():
	# Defensive circle formation
	var center = group_center_2d
	var angle_step = TAU / hybrid_agents.size()
	
	for i in range(hybrid_agents.size()):
		var agent = hybrid_agents[i]
		var angle = i * angle_step
		var offset = Vector2(cos(angle), sin(angle)) * formation_spacing * 2
		var target_pos = center + offset
		assign_formation_position(agent, target_pos)

func update_scatter_formation():
	# Spread out formation for stealth or area coverage
	for agent in hybrid_agents:
		var random_offset = Vector2(
			randf_range(-group_radius, group_radius),
			randf_range(-group_radius, group_radius)
		)
		var target_pos = group_center_2d + random_offset
		assign_formation_position(agent, target_pos)

func assign_formation_position(agent: HybridNPCAgent, target_pos: Vector2):
	# Only assign if agent is not too close to target already
	var current_pos = agent.get_current_position()
	if current_pos.distance_to(target_pos) > formation_spacing * 0.5:
		match mode:
			WorldManager.WorldMode.MODE_2D:
				agent.set_navigation_target_2d(target_pos)
			WorldManager.WorldMode.MODE_3D:
				agent.set_navigation_target_3d(WorldManager.coordinate_converter.convert_2d_to_3d(target_pos))

func find_formation_position_for_member(agent: HybridNPCAgent) -> Vector2:
	# Find a good position for this member in the current formation
	match formation_type:
		FormationType.LOOSE:
			return group_center_2d + Vector2(randf_range(-group_radius * 0.5, group_radius * 0.5), randf_range(-group_radius * 0.5, group_radius * 0.5))
		_:
			return group_center_2d  # Default fallback

func update_objectives(delta: float):
	# Process current objective
	if current_objective:
		current_objective.update(delta)
		
		if current_objective.is_completed():
			complete_current_objective()
	
	# Assign new objective if needed
	if not current_objective and not objective_queue.is_empty():
		current_objective = objective_queue.pop_front()
		start_objective(current_objective)
	
	# Default behavior: patrol
	if not current_objective and not patrol_points.is_empty():
		start_patrol_objective()

func start_patrol_objective():
	var patrol_objective = GroupObjective.new()
	patrol_objective.objective_type = GroupObjective.ObjectiveType.PATROL
	patrol_objective.target_position = patrol_points[current_patrol_index]
	patrol_objective.setup_patrol(patrol_points, current_patrol_index)
	
	current_objective = patrol_objective
	start_objective(current_objective)

func start_objective(objective: GroupObjective):
	print("NPCGroup: Starting objective ", GroupObjective.ObjectiveType.keys()[objective.objective_type], " for group ", group_id)
	
	# Command all members to work on this objective
	for agent in hybrid_agents:
		objective.assign_to_agent(agent)

func complete_current_objective():
	print("NPCGroup: Completed objective for group ", group_id)
	
	if current_objective.objective_type == GroupObjective.ObjectiveType.PATROL:
		# Move to next patrol point
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
	
	current_objective = null

func update_agents(delta: float):
	for agent in hybrid_agents:
		agent.update(delta * performance_scaling)

func update_group_state():
	# Update group-wide state
	update_group_morale()
	update_alertness_level()
	check_combat_status()

func update_group_morale():
	if members.is_empty():
		return
	
	var total_morale = 0.0
	var alive_members = 0
	
	for member in members:
		if member.is_alive():
			total_morale += member.morale
			alive_members += 1
	
	if alive_members > 0:
		morale = total_morale / alive_members
	
	# Group size affects morale
	if alive_members < members.size() * 0.5:
		morale *= 0.8  # Low member count hurts morale

func update_alertness_level():
	var max_alertness = 0
	
	for member in members:
		if member.is_alive():
			max_alertness = max(max_alertness, member.alertness_level)
	
	alertness_level = max_alertness
	
	# Adjust formation based on alertness
	if alertness_level >= 2 and formation_type == FormationType.LOOSE:
		formation_type = FormationType.WEDGE
	elif alertness_level == 0 and formation_type == FormationType.WEDGE:
		formation_type = FormationType.LOOSE

func check_combat_status():
	var in_combat = false
	
	for member in members:
		if member.is_alive() and member.is_in_combat():
			in_combat = true
			break
	
	if in_combat != is_in_combat:
		is_in_combat = in_combat
		
		if is_in_combat:
			enter_combat_mode()
		else:
			exit_combat_mode()

func enter_combat_mode():
	print("NPCGroup: Group ", group_id, " entering combat mode")
	formation_type = FormationType.CIRCLE
	performance_scaling = 1.2  # Boost performance during combat

func exit_combat_mode():
	print("NPCGroup: Group ", group_id, " exiting combat mode")
	formation_type = FormationType.LOOSE
	performance_scaling = 1.0

func get_agent_for_npc(npc: NPC) -> HybridNPCAgent:
	for agent in hybrid_agents:
		if agent.npc == npc:
			return agent
	return null

func set_mode(new_mode: WorldManager.WorldMode):
	if mode == new_mode:
		return
	
	print("NPCGroup: Switching group ", group_id, " to mode ", WorldManager.WorldMode.keys()[new_mode])
	
	mode = new_mode
	
	# Switch all agents to new mode
	for agent in hybrid_agents:
		agent.set_mode(new_mode)
	
	# Update group center for new mode
	if new_mode == WorldManager.WorldMode.MODE_3D:
		group_center_3d = WorldManager.coordinate_converter.convert_2d_to_3d(group_center_2d)
	else:
		group_center_2d = WorldManager.coordinate_converter.convert_3d_to_2d(group_center_3d)

func activate():
	is_active = true
	for agent in hybrid_agents:
		agent.activate()

func deactivate():
	is_active = false
	for agent in hybrid_agents:
		agent.deactivate()

func cleanup():
	print("NPCGroup: Cleaning up group ", group_id)
	
	# Clean up all agents
	for agent in hybrid_agents:
		agent.cleanup()
	
	# Clear references
	hybrid_agents.clear()
	members.clear()
	leader = null
	current_objective = null
	objective_queue.clear()

func get_group_info() -> Dictionary:
	return {
		"group_id": group_id,
		"group_name": group_name,
		"area_id": area_id,
		"mode": WorldManager.WorldMode.keys()[mode],
		"member_count": members.size(),
		"leader": leader.name if leader else "None",
		"specialization": Group.GroupSpecialization.keys()[group_specialization],
		"activity": Group.GroupActivity.keys()[group_activity],
		"formation": FormationType.keys()[formation_type],
		"morale": morale,
		"alertness_level": alertness_level,
		"is_in_combat": is_in_combat,
		"is_active": is_active,
		"group_center_2d": group_center_2d,
		"group_radius": group_radius
	}

# === NESTED CLASS ===
class GroupObjective extends RefCounted:
	enum ObjectiveType { PATROL, MOVE_TO, DEFEND, ATTACK, GATHER, TRADE }
	
	var objective_type: ObjectiveType = ObjectiveType.PATROL
	var target_position: Vector2 = Vector2()
	var target_npc: NPC = null
	var target_poi: POI = null
	var duration: float = 0.0
	var max_duration: float = 300.0  # 5 minutes default
	var is_completed_flag: bool = false
	
	func update(delta: float):
		duration += delta
		
		# Check completion conditions
		check_completion()
		
		# Auto-complete after max duration
		if duration >= max_duration:
			is_completed_flag = true
	
	func check_completion():
		# This would be implemented based on objective type
		pass
	
	func is_completed() -> bool:
		return is_completed_flag
	
	func setup_patrol(points: Array[Vector2], start_index: int):
		target_position = points[start_index]
	
	func assign_to_agent(agent: HybridNPCAgent):
		# Assign this objective to an agent
		match objective_type:
			ObjectiveType.PATROL, ObjectiveType.MOVE_TO:
				if agent.current_mode == WorldManager.WorldMode.MODE_2D:
					agent.set_navigation_target_2d(target_position)
				else:
					agent.set_navigation_target_3d(WorldManager.coordinate_converter.convert_2d_to_3d(target_position))