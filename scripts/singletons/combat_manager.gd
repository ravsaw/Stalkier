# scripts/singletons/combat_manager.gd
extends Node

# === ACTIVE COMBATS ===
var active_combats: Array[Combat] = []
var combat_history: Array[CombatResult] = []
var recent_conflict_intensity: float = 0.0

# === CONFIGURATION ===
@export var base_combat_duration: float = 5.0  # Base combat time in seconds
@export var casualty_rate_min: float = 0.05
@export var casualty_rate_max: float = 0.5

# Combat outcomes
enum CombatOutcome {
	DECISIVE_VICTORY,
	TACTICAL_VICTORY,
	STALEMATE,
	TACTICAL_RETREAT,
	ROUT,
	MUTUAL_DESTRUCTION
}

class Combat extends RefCounted:
	var combat_id: String
	var attacker: Group
	var defender: Group
	var start_time: float
	var duration: float
	var is_resolved: bool = false

class CombatResult extends RefCounted:
	var combat_id: String
	var outcome: int  # CombatOutcome
	var victor: Group
	var defeated: Group
	var attacker_casualties: int
	var defender_casualties: int
	var duration: float
	var timestamp: float
	
	func to_dict() -> Dictionary:
		return {
			"combat_id": combat_id,
			"outcome": outcome,
			"victor": victor,
			"defeated": defeated,
			"attacker_casualties": attacker_casualties,
			"defender_casualties": defender_casualties,
			"duration": duration,
			"timestamp": timestamp,
		}

func _ready():
	print("CombatManager initialized")

func initiate_combat(attacker_group: Group, defender_group: Group):
	if not attacker_group or not defender_group:
		return
	
	if attacker_group == defender_group:
		return
	
	var combat = Combat.new()
	combat.combat_id = generate_combat_id()
	combat.attacker = attacker_group
	combat.defender = defender_group
	combat.start_time = Time.get_unix_time_from_system()
	combat.duration = calculate_combat_duration(attacker_group, defender_group)
	
	active_combats.append(combat)
	print("🛡️ Combat started: ", combat.combat_id,
		  "  Attacker=", attacker_group.group_id,
		  "  Defender=", defender_group.group_id,
		  "  Duration=", combat.duration)
	
	EventBus.emit_signal("combat_started", attacker_group, defender_group)
	
	# Schedule resolution
	var timer = Timer.new()
	timer.wait_time = combat.duration
	timer.one_shot = true
	timer.timeout.connect(func(): resolve_combat(combat))
	add_child(timer)
	timer.start()

func calculate_combat_duration(attacker: Group, defender: Group) -> float:
	var duration = base_combat_duration
	
	# Larger groups take longer
	var total_combatants = attacker.get_member_count() + defender.get_member_count()
	duration *= (1.0 + total_combatants * 0.1)
	
	# High discipline speeds up resolution
	var avg_discipline = (attacker.discipline + defender.discipline) / 2.0
	duration *= (2.0 - avg_discipline / 100.0)
	
	return duration

func resolve_combat(combat: Combat):
	if combat.is_resolved:
		return
	
	print("⚔️ Resolving combat: ", combat.combat_id)
	combat.is_resolved = true
	active_combats.erase(combat)
	
	# Calculate combat strengths
	var attacker_strength = calculate_group_combat_strength(combat.attacker, true)
	var defender_strength = calculate_group_combat_strength(combat.defender, false)
	print("    Attacker strength=", attacker_strength,
		  "  Defender strength=", defender_strength)
	
	# Determine winner
	var total_strength = attacker_strength + defender_strength
	var attacker_win_chance = attacker_strength / total_strength
	
	# Add some randomness
	attacker_win_chance += randf_range(-0.2, 0.2)
	attacker_win_chance = clamp(attacker_win_chance, 0.1, 0.9)
	
	var attacker_wins = randf() < attacker_win_chance
	
	# Calculate casualties
	var result = CombatResult.new()
	result.combat_id = combat.combat_id
	result.duration = combat.duration
	result.timestamp = Time.get_unix_time_from_system()
	
	if attacker_wins:
		result.victor = combat.attacker
		result.defeated = combat.defender
	else:
		result.victor = combat.defender
		result.defeated = combat.attacker
	
	print("    Victor=", result.victor.group_id,
		  "  Defeated=", result.defeated.group_id)
		
	# Determine outcome type and casualties
	determine_combat_outcome(result, combat, attacker_strength, defender_strength)
	
	# Apply casualties
	apply_combat_casualties(combat.attacker, result.attacker_casualties)
	apply_combat_casualties(combat.defender, result.defender_casualties)
	
	# Update group morale
	update_post_combat_morale(result)
	
	var dict = result.to_dict()
	print("    Result:", dict)
	# Store result
	combat_history.append(result)
	update_conflict_intensity()
	
	EventBus.emit_signal("combat_ended", result.to_dict())

func calculate_group_combat_strength(group: Group, is_attacking: bool) -> float:
	var strength = group.get_total_combat_strength()
	
	# Attacking vs defending modifier
	if is_attacking:
		strength *= 0.9  # Slight defender advantage
	else:
		strength *= 1.1
	
	return strength

func determine_combat_outcome(result: CombatResult, combat: Combat, attacker_str: float, defender_str: float):
	var strength_ratio = max(attacker_str, defender_str) / min(attacker_str, defender_str)
	var victor_is_attacker = (result.victor == combat.attacker)
	
	# Calculate base casualty rates
	var victor_casualty_rate = randf_range(casualty_rate_min, 0.2)
	var defeated_casualty_rate = randf_range(0.2, casualty_rate_max)
	
	# Determine outcome based on strength ratio and casualties
	if strength_ratio > 3.0:
		result.outcome = CombatOutcome.DECISIVE_VICTORY
		victor_casualty_rate *= 0.5
		defeated_casualty_rate *= 1.5
	elif strength_ratio > 1.5:
		result.outcome = CombatOutcome.TACTICAL_VICTORY
		# Normal rates
	elif defeated_casualty_rate > 0.8:
		result.outcome = CombatOutcome.ROUT
		defeated_casualty_rate = 0.9
	elif victor_casualty_rate > 0.7 and defeated_casualty_rate > 0.7:
		result.outcome = CombatOutcome.MUTUAL_DESTRUCTION
		victor_casualty_rate = 0.8
		defeated_casualty_rate = 0.8
	elif abs(victor_casualty_rate - defeated_casualty_rate) < 0.1:
		result.outcome = CombatOutcome.STALEMATE
	else:
		result.outcome = CombatOutcome.TACTICAL_RETREAT
		defeated_casualty_rate *= 0.8  # Organized retreat reduces casualties
	
	# Apply casualties based on who won
	if victor_is_attacker:
		result.attacker_casualties = int(combat.attacker.get_member_count() * victor_casualty_rate)
		result.defender_casualties = int(combat.defender.get_member_count() * defeated_casualty_rate)
	else:
		result.attacker_casualties = int(combat.attacker.get_member_count() * defeated_casualty_rate)
		result.defender_casualties = int(combat.defender.get_member_count() * victor_casualty_rate)

func apply_combat_casualties(group: Group, casualties: int):
	if casualties <= 0:
		return
	
	# Sort members by combat effectiveness (weakest first)
	var members = group.members.duplicate()
	members.sort_custom(func(a, b): return a.get_combat_effectiveness() < b.get_combat_effectiveness())
	
	# Apply casualties to weakest members first
	for i in range(min(casualties, members.size())):
		var casualty = members[i]
		
		# 30% chance of death, 70% wounded
		if randf() < 0.3:
			casualty.die()
		else:
			# Wound the NPC
			casualty.health = max(1, casualty.health - randi_range(30, 60))
			casualty.stress += 30

func update_post_combat_morale(result: CombatResult):
	# Victor morale boost
	match result.outcome:
		CombatOutcome.DECISIVE_VICTORY:
			result.victor.update_morale(25)
		CombatOutcome.TACTICAL_VICTORY:
			result.victor.update_morale(15)
		CombatOutcome.STALEMATE:
			result.victor.update_morale(-5)
		CombatOutcome.MUTUAL_DESTRUCTION:
			result.victor.update_morale(-20)
		_:
			result.victor.update_morale(10)
	
	# Defeated morale penalty
	match result.outcome:
		CombatOutcome.DECISIVE_VICTORY:
			result.defeated.update_morale(-30)
		CombatOutcome.ROUT:
			result.defeated.update_morale(-40)
		CombatOutcome.MUTUAL_DESTRUCTION:
			result.defeated.update_morale(-30)
		CombatOutcome.TACTICAL_RETREAT:
			result.defeated.update_morale(-15)
		_:
			result.defeated.update_morale(-20)

func update_conflict_intensity():
	# Calculate recent conflict intensity (affects spawn rates, etc.)
	var recent_threshold = 24.0 * 7  # Last 7 days
	var current_time = Time.get_unix_time_from_system()
	var recent_combats = 0
	var total_casualties = 0
	
	for result in combat_history:
		if current_time - result.timestamp <= recent_threshold:
			recent_combats += 1
			total_casualties += result.attacker_casualties + result.defender_casualties
	
	recent_conflict_intensity = min(1.0, recent_combats / 10.0 + total_casualties / 50.0)

func get_recent_conflict_intensity() -> float:
	return recent_conflict_intensity

func generate_combat_id() -> String:
	return "combat_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

# === REVENGE SYSTEM ===
var revenge_targets: Dictionary = {}  # group_id -> Array of RevengeTarget

class RevengeTarget extends RefCounted:
	var target_group: Group
	var intensity: float = 1.0
	var time_limit: float = 30.0  # Days
	var creation_time: float

func create_revenge_target(victim_group: Group, target_group: Group, intensity: float = 1.0):
	if not victim_group or not target_group:
		return
	
	var revenge = RevengeTarget.new()
	revenge.target_group = target_group
	revenge.intensity = clamp(intensity, 0.1, 1.0)
	revenge.creation_time = Time.get_unix_time_from_system()
	
	if not victim_group.group_id in revenge_targets:
		revenge_targets[victim_group.group_id] = []
	
	revenge_targets[victim_group.group_id].append(revenge)
	
	EventBus.emit_signal("revenge_declared", victim_group, target_group)

func check_revenge_opportunities():
	var current_time = Time.get_unix_time_from_system()
	
	for group_id in revenge_targets:
		var group = GroupManager.get_group_by_id(group_id)
		if not group:
			continue
		
		var targets = revenge_targets[group_id]
		var expired_targets = []
		
		for i in range(targets.size()):
			var target = targets[i]
			
			# Check if expired
			if current_time - target.creation_time > target.time_limit * 24 * 3600:
				expired_targets.append(i)
				continue
			
			# Check if can execute revenge
			if can_execute_revenge(group, target.target_group):
				if randf() < target.intensity * 0.1:  # Intensity affects chance
					initiate_combat(group, target.target_group)
					expired_targets.append(i)  # Revenge satisfied
		
		# Remove expired/satisfied revenge targets
		expired_targets.reverse()
		for idx in expired_targets:
			targets.remove_at(idx)

func can_execute_revenge(avenger: Group, target: Group) -> bool:
	if not avenger or not target:
		return false
	
	# Groups must be close enough
	if avenger.get_average_position().distance_to(target.get_average_position()) > 20.0:
		return false
	
	# Avenger must be strong enough
	if avenger.get_total_combat_strength() < target.get_total_combat_strength() * 0.5:
		return false
	
	return true
