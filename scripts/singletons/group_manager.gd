# scripts/singletons/group_manager.gd
extends Node

# === GRUPY ===
var all_groups: Array[Group] = []
var groups_by_id: Dictionary = {}  # group_id -> Group

# === KONFIGURACJA ===
@export var max_groups: int = 50
@export var min_group_size: int = 2
@export var max_group_size: int = 12
@export var group_formation_chance: float = 0.1  # Per NPC per day

func _ready():
	print("GroupManager initialized")

func _process(delta: float):
	# Update all groups
	for group in all_groups:
		group.update(delta)

func create_group(leader: NPC) -> Group:
	if all_groups.size() >= max_groups:
		return null
	
	var group = Group.new()
	group.name = generate_group_name()
	
	# Add leader
	group.add_member(leader)
	
	# Determine specialization based on leader
	group.specialization = determine_group_specialization(leader)
	
	# Register group
	add_group(group)
	
	EventBus.emit_signal("group_formed", group)
	
	return group

func add_group(group: Group):
	all_groups.append(group)
	groups_by_id[group.group_id] = group

func remove_group(group: Group):
	all_groups.erase(group)
	groups_by_id.erase(group.group_id)

func get_group_by_id(group_id: String) -> Group:
	return groups_by_id.get(group_id, null)

func get_all_groups() -> Array[Group]:
	return all_groups

func find_joinable_group(npc: NPC) -> Group:
	var best_group: Group = null
	var best_compatibility: float = -1.0
	
	for group in all_groups:
		if not group.can_accept_member(npc):
			continue
		
		# Skip if too far away
		if npc.position.distance_to(group.get_average_position()) > 20.0:
			continue
		
		var compatibility = calculate_group_compatibility(npc, group)
		if compatibility > best_compatibility:
			best_compatibility = compatibility
			best_group = group
	
	return best_group if best_compatibility > 0.3 else null

func calculate_group_compatibility(npc: NPC, group: Group) -> float:
	var compatibility = 0.5  # Base compatibility
	
	# Morality difference
	var morality_diff = abs(npc.morality - group.get_average_morality())
	compatibility -= morality_diff / 100.0
	
	# Skill match bonus
	match group.specialization:
		Group.GroupSpecialization.TRADING:
			compatibility += npc.trade_skill / 100.0
		Group.GroupSpecialization.MILITARY:
			compatibility += npc.combat_skill / 100.0
		Group.GroupSpecialization.RESEARCH:
			compatibility += npc.research_skill / 100.0
		Group.GroupSpecialization.BANDIT:
			compatibility += (100 - npc.morality) / 100.0
	
	# Social bonus
	compatibility += npc.sociability / 200.0
	
	return clamp(compatibility, 0.0, 1.0)

func request_join_group(npc: NPC, group: Group) -> bool:
	if not group.can_accept_member(npc):
		return false
	
	# Calculate acceptance chance
	var acceptance_chance = 0.5
	
	# Leader's charisma affects acceptance
	if group.leader:
		acceptance_chance += group.leader.charisma / 200.0
	
	# Group morale affects acceptance
	acceptance_chance += (group.morale - 50) / 100.0
	
	# NPC's skills affect acceptance
	acceptance_chance += calculate_npc_value_to_group(npc, group)
	
	if randf() < acceptance_chance:
		return group.add_member(npc)
	
	return false

func calculate_npc_value_to_group(npc: NPC, group: Group) -> float:
	var value = 0.0
	
	match group.specialization:
		Group.GroupSpecialization.TRADING:
			value = npc.trade_skill / 200.0 + npc.charisma / 400.0
		Group.GroupSpecialization.MILITARY:
			value = npc.combat_skill / 200.0 + npc.strength / 400.0
		Group.GroupSpecialization.RESEARCH:
			value = npc.research_skill / 200.0 + npc.intelligence / 400.0
		Group.GroupSpecialization.BANDIT:
			value = npc.combat_skill / 300.0 + npc.aggression / 300.0
		_:  # Universal
			value = 0.1  # Base value
	
	return value

func determine_group_specialization(leader: NPC) -> int:
	# Based on leader's skills and personality
	var specs = []
	
	if leader.trade_skill > 40 or leader.charisma > 60:
		specs.append(Group.GroupSpecialization.TRADING)
	
	if leader.combat_skill > 50 or leader.strength > 60:
		specs.append(Group.GroupSpecialization.MILITARY)
	
	if leader.research_skill > 40 or leader.intelligence > 60:
		specs.append(Group.GroupSpecialization.RESEARCH)
	
	if leader.morality < 40 and leader.aggression > 60:
		specs.append(Group.GroupSpecialization.BANDIT)
	
	if specs.is_empty():
		return Group.GroupSpecialization.UNIVERSAL
	
	return specs[randi() % specs.size()]

# === GROUP FORMATION ===
func check_group_formation():
	# Find solo NPCs who might form groups
	var solo_npcs = []
	
	for npc in NPCManager.get_all_npcs():
		if npc.is_alive() and not npc.group:
			solo_npcs.append(npc)
	
	# Try to form groups
	for npc in solo_npcs:
		if npc.leadership_skill > 40 and randf() < group_formation_chance:
			attempt_group_formation(npc)

func attempt_group_formation(leader: NPC):
	# Check if can form group
	if leader.group or all_groups.size() >= max_groups:
		return
	
	# Find nearby solo NPCs
	var candidates = NPCManager.find_npcs_in_radius(leader.position, 10.0)
	var recruits = []
	
	for candidate in candidates:
		if candidate == leader or candidate.group:
			continue
		
		# Check compatibility
		if calculate_recruitment_chance(leader, candidate) > randf():
			recruits.append(candidate)
			
			if recruits.size() >= max_group_size - 1:
				break
	
	# Form group if enough recruits
	if recruits.size() >= min_group_size - 1:
		var group = create_group(leader)
		if group:
			for recruit in recruits:
				group.add_member(recruit)

func calculate_recruitment_chance(leader: NPC, candidate: NPC) -> float:
	var chance = 0.3  # Base chance
	
	# Leader charisma
	chance += leader.charisma / 200.0
	
	# Morality compatibility
	var morality_diff = abs(leader.morality - candidate.morality)
	chance -= morality_diff / 200.0
	
	# Candidate's social need
	chance += (100 - candidate.needs[NPC.NPCNeed.COMPANIONSHIP]) / 200.0
	
	return clamp(chance, 0.1, 0.8)

# === NAME GENERATION ===
var group_prefixes = ["Iron", "Steel", "Red", "Black", "Free", "Wild", "Lone", "Silent", "Thunder", "Shadow"]
var group_suffixes = ["Wolves", "Hawks", "Stalkers", "Hunters", "Rangers", "Guards", "Company", "Band", "Brotherhood", "Collective"]

func generate_group_name() -> String:
	var prefix = group_prefixes[randi() % group_prefixes.size()]
	var suffix = group_suffixes[randi() % group_suffixes.size()]
	return prefix + " " + suffix

# === STATISTICS ===
func get_group_statistics() -> Dictionary:
	var stats = {
		"total_groups": all_groups.size(),
		"total_members": 0,
		"average_size": 0.0,
		"by_specialization": {}
	}
	
	# Initialize specialization counts
	for spec in Group.GroupSpecialization.values():
		stats["by_specialization"][spec] = 0
	
	for group in all_groups:
		stats["total_members"] += group.get_member_count()
		stats["by_specialization"][group.specialization] += 1
	
	if all_groups.size() > 0:
		stats["average_size"] = float(stats["total_members"]) / all_groups.size()
	
	return stats
