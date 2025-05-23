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

func generate_unique_id() -> String:
	return "npc_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

func update(delta: float):
	# Update needs
	update_needs(delta)
	
	# Update AI
	brain.update(delta)
	
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

func update_movement(delta: float):
	if position.distance_to(target_position) > 0.1:
		var direction = (target_position - position).normalized()
		var move_distance = movement_speed * delta
		
		if position.distance_to(target_position) <= move_distance:
			position = target_position
		else:
			position += direction * move_distance

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
