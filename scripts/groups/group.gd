# scripts/groups/group.gd
class_name Group
extends RefCounted

# === IDENTYFIKACJA ===
var group_id: String
var name: String
var formation_date: float

# === CZŁONKOWIE ===
var members: Array[NPC] = []
var leader: NPC = null
var max_size: int = 12

# === SPECJALIZACJA ===
var specialization: int = GroupSpecialization.UNIVERSAL
var morale: float = 50.0
var discipline: float = 50.0

# === CELE I MISJE ===
var current_mission: Goal = null
var group_inventory: Dictionary = {}  # Shared resources

# === REPUTACJA ===
var reputation: Dictionary = {}  # group_id -> reputation_value

# === 2D/3D STATE MANAGEMENT ===
var group_representation_state: String = "2d"  # "2d", "3d", or "mixed"
var formation_type: String = "line"  # "line", "wedge", "circle", "column"
var formation_spacing: float = 10.0
var update_frequency_2d: float = 5.0  # Update every 5 seconds in 2D
var update_frequency_3d: float = 0.1   # Update every 0.1 seconds in 3D
var last_update_time: float = 0.0

enum GroupSpecialization {
	UNIVERSAL,      # Bez specjalizacji
	TRADING,        # Handlowa
	MILITARY,       # Ochroniarska
	RESEARCH,       # Badawcza
	BANDIT         # Bandycka
}

func _init():
	group_id = generate_unique_id()
	formation_date = Time.get_unix_time_from_system()

func generate_unique_id() -> String:
	return "group_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

func add_member(npc: NPC) -> bool:
	if members.size() >= max_size:
		return false
	
	if npc in members:
		return false
	
	# Remove from old group if any
	if npc.group:
		npc.group.remove_member(npc)
	
	members.append(npc)
	npc.group = self
	
	# First member becomes leader
	if not leader and members.size() == 1:
		leader = npc
	
	update_morale(5)  # New member boosts morale
	EventBus.emit_signal("npc_joined_group", npc, self)
	
	return true

func remove_member(npc: NPC):
	members.erase(npc)
	npc.group = null
	
	# Handle leader loss
	if npc == leader:
		elect_new_leader()
	
	update_morale(-10)  # Member loss hurts morale
	EventBus.emit_signal("npc_left_group", npc, self)
	
	# Dissolve if too small
	if members.size() < 2:
		dissolve()

func elect_new_leader():
	leader = null
	var best_candidate: NPC = null
	var best_score: float = 0
	
	for member in members:
		var score = member.leadership_skill + member.charisma * 0.5
		if score > best_score:
			best_score = score
			best_candidate = member
	
	if best_candidate:
		leader = best_candidate

func update_morale(change: float):
	morale = clamp(morale + change, 0, 100)
	
	# Low morale effects
	if morale < 20:
		# Members might leave
		for member in members:
			if member != leader and randf() < 0.1:  # 10% chance
				remove_member(member)

func get_average_position() -> Vector2:
	if members.is_empty():
		return Vector2.ZERO
	
	var sum = Vector2.ZERO
	for member in members:
		sum += member.position
	
	return sum / members.size()

func get_member_count() -> int:
	return members.size()

func get_specialization_name() -> String:
	match specialization:
		GroupSpecialization.UNIVERSAL: return "Universal"
		GroupSpecialization.TRADING: return "Trading"
		GroupSpecialization.MILITARY: return "Military"
		GroupSpecialization.RESEARCH: return "Research"
		GroupSpecialization.BANDIT: return "Bandit"
		_: return "Unknown"

func get_total_combat_strength() -> float:
	var total = 0.0
	for member in members:
		total += member.get_combat_effectiveness()
	
	# Apply morale and discipline modifiers
	total *= (morale / 100.0)
	total *= (0.5 + discipline / 200.0)  # 50% to 100% based on discipline
	
	return total

func can_accept_member(npc: NPC) -> bool:
	if members.size() >= max_size:
		return false
	
	# Check if NPC fits group culture
	var avg_morality = get_average_morality()
	if abs(npc.morality - avg_morality) > 40:
		return false  # Too different morally
	
	return true

func get_average_morality() -> float:
	if members.is_empty():
		return 50.0
	
	var sum = 0.0
	for member in members:
		sum += member.morality
	
	return sum / members.size()

func dissolve():
	# Clear all members
	var members_copy = members.duplicate()
	for member in members_copy:
		member.group = null
	
	members.clear()
	leader = null
	
	EventBus.emit_signal("group_dissolved", self)

func update(delta: float):
	# Skip update based on representation state and timing
	last_update_time += delta
	var update_frequency = update_frequency_3d if group_representation_state == "3d" else update_frequency_2d
	
	if last_update_time < update_frequency:
		return
	
	last_update_time = 0.0
	
	# Update group mission
	if current_mission:
		current_mission.execute_group_goal(self, delta)
		
		if current_mission.is_completed():
			complete_mission()
	
	# Update formation
	update_formation()
	
	# Natural morale changes
	if morale > 50:
		update_morale(-0.1 * delta)  # Slowly decay to neutral
	elif morale < 50:
		update_morale(0.1 * delta)   # Slowly recover to neutral

func complete_mission():
	if current_mission:
		# Reward based on mission type
		morale += 10
		discipline += 5
		
		current_mission = null
		
		# Leader chooses new mission
		if leader and leader.brain:
			# Simplified - in full implementation, leader would choose group goals
			pass

func to_dict() -> Dictionary:
	var member_ids = []
	for member in members:
		member_ids.append(member.npc_id)
	
	return {
		"group_id": group_id,
		"name": name,
		"specialization": specialization,
		"member_count": members.size(),
		"leader_id": leader.npc_id if leader else "",
		"morale": morale,
		"discipline": discipline,
		"member_ids": member_ids,
		"representation_state": group_representation_state,
		"formation_type": formation_type
	}

# === 2D/3D STATE MANAGEMENT ===
func set_representation_state(new_state: String):
	"""Set the representation state for the entire group"""
	if group_representation_state == new_state:
		return
	
	var old_state = group_representation_state
	group_representation_state = new_state
	
	# Update all members
	for member in members:
		member.set_representation_state(new_state)
	
	# Reset update timer
	last_update_time = 0.0
	
	# Emit state change event
	EventBus.emit_signal("group_state_changed", self, old_state, new_state)

func get_representation_state() -> String:
	"""Get current representation state"""
	return group_representation_state

func get_distance_to_player() -> float:
	"""Get distance from group center to player"""
	if not leader:
		return INF
	
	return leader.position.distance_to(WorldManager.player_position)

func should_be_in_3d() -> bool:
	"""Check if group should be in 3D mode based on distance"""
	return get_distance_to_player() <= WorldManager.DISTANCE_2D_TO_3D

func should_despawn() -> bool:
	"""Check if group should be despawned based on distance"""
	return get_distance_to_player() >= WorldManager.DISTANCE_DESPAWN

# === FORMATION MANAGEMENT ===
func set_formation_type(new_formation: String):
	"""Set group formation type"""
	formation_type = new_formation
	update_formation()

func update_formation():
	"""Update member positions based on formation"""
	if not leader or members.size() <= 1:
		return
	
	var leader_pos = leader.get_effective_position()
	var leader_direction = leader.get_facing_direction()
	
	var member_index = 0
	for member in members:
		if member == leader:
			continue
		
		var formation_pos = get_formation_position(member_index, leader_pos, leader_direction)
		
		# Set target position for member
		if group_representation_state == "3d":
			var formation_3d = CoordinateConverter.world_2d_to_world_3d(formation_pos)
			member.set_navigation_target_3d(formation_3d)
		else:
			member.set_navigation_target(formation_pos)
		
		member_index += 1

func get_formation_position(member_index: int, leader_pos: Vector2, leader_direction: Vector2) -> Vector2:
	"""Get formation position for a member"""
	match formation_type:
		"line":
			# Single line behind leader
			var offset = leader_direction * (-formation_spacing * (member_index + 1))
			return leader_pos + offset
		
		"wedge":
			# V-formation
			var side = 1 if member_index % 2 == 0 else -1
			var row = (member_index + 1) / 2
			var back_offset = leader_direction * (-formation_spacing * row)
			var side_offset = leader_direction.rotated(PI/2) * (side * formation_spacing * row * 0.5)
			return leader_pos + back_offset + side_offset
		
		"column":
			# Two columns
			var column = member_index % 2
			var row = member_index / 2 + 1
			var back_offset = leader_direction * (-formation_spacing * row)
			var side_offset = leader_direction.rotated(PI/2) * (column * formation_spacing - formation_spacing * 0.5)
			return leader_pos + back_offset + side_offset
		
		"circle":
			# Circular formation around leader
			var angle = (TAU / max(members.size() - 1, 1)) * member_index
			var circle_pos = Vector2.RIGHT.rotated(angle) * formation_spacing
			return leader_pos + circle_pos
		
		_:
			# Default: spread out randomly behind leader
			var random_offset = Vector2(
				randf_range(-formation_spacing, formation_spacing),
				randf_range(-formation_spacing, formation_spacing)
			)
			return leader_pos + leader_direction * (-formation_spacing) + random_offset

func move_group_to_position(target_position: Vector2):
	"""Move entire group to target position maintaining formation"""
	if not leader:
		return
	
	# Move leader to target
	if group_representation_state == "3d":
		var target_3d = CoordinateConverter.world_2d_to_world_3d(target_position)
		leader.set_navigation_target_3d(target_3d)
	else:
		leader.set_navigation_target(target_position)
	
	# Formation will be updated automatically by update_formation()

func get_group_bounds() -> Rect2:
	"""Get bounding rectangle containing all group members"""
	if members.is_empty():
		return Rect2()
	
	var min_pos = members[0].get_effective_position()
	var max_pos = min_pos
	
	for member in members:
		var pos = member.get_effective_position()
		min_pos.x = min(min_pos.x, pos.x)
		min_pos.y = min(min_pos.y, pos.y)
		max_pos.x = max(max_pos.x, pos.x)
		max_pos.y = max(max_pos.y, pos.y)
	
	return Rect2(min_pos, max_pos - min_pos)

func is_group_coherent() -> bool:
	"""Check if group members are close enough to leader"""
	if not leader:
		return false
	
	var leader_pos = leader.get_effective_position()
	var max_distance = formation_spacing * 3.0  # Allow some flexibility
	
	for member in members:
		if member == leader:
			continue
		
		if member.get_effective_position().distance_to(leader_pos) > max_distance:
			return false
	
	return true

func rally_group():
	"""Rally scattered group members back to leader"""
	if not leader:
		return
	
	var rally_point = leader.get_effective_position()
	
	for member in members:
		if member == leader:
			continue
		
		# Move member to rally point
		if group_representation_state == "3d":
			var rally_3d = CoordinateConverter.world_2d_to_world_3d(rally_point)
			member.set_navigation_target_3d(rally_3d)
		else:
			member.set_navigation_target(rally_point)
	
	# Boost morale slightly for rallying
	update_morale(5)

func can_cross_area_boundary(from_area: String, to_area: String) -> bool:
	"""Check if group can cross between areas"""
	# Leaders make decisions for the group
	if not leader:
		return false
	
	# Check if transition exists
	var transition = WorldManager.get_transition_point(from_area, to_area)
	if not transition:
		return false
	
	# Check if group is coherent enough to move together
	if not is_group_coherent():
		rally_group()
		return false
	
	return true

func initiate_area_transition(from_area: String, to_area: String):
	"""Initiate transition to another area"""
	var transition = WorldManager.get_transition_point(from_area, to_area)
	if not transition:
		return
	
	# Move group to transition point
	move_group_to_position(transition.from_position)
	
	# When leader reaches transition, move whole group
	# This would be handled by the transition system
