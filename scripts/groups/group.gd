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

enum GroupSpecialization {
	UNIVERSAL,      # Bez specjalizacji
	TRADING,        # Handlowa
	MILITARY,       # Ochroniarska
	RESEARCH,       # Badawcza
	BANDIT         # Bandycka
}

enum GroupActivity {
	WANDERING,      # Swobodne wędrowanie
	PATROLLING,     # Patrol określonej trasy
	GUARDING,       # Ochrona punktu
	TRADING,        # Handel
	EXPLORING,      # Eksploracja
	RESTING,        # Odpoczynek
	COMBAT          # Walka
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
	# Update group mission
	if current_mission:
		current_mission.execute_group_goal(self, delta)
		
		if current_mission.is_completed():
			complete_mission()
	
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
		"member_ids": member_ids
	}
