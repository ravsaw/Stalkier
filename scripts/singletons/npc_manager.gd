# scripts/singletons/npc_manager.gd
extends Node

# === POPULACJA ===
var all_npcs: Array[NPC] = []
var npcs_by_id: Dictionary = {}  # npc_id -> NPC
var max_population: int = 300

# === SPAWN CONFIGURATION ===
@export var spawn_check_interval: float = 24.0  # Check every 24 game hours
@export var spawn_chance: float = 0.25
@export var spawn_batch_min: int = 1
@export var spawn_batch_max: int = 4
@export var minimum_population: int = 100

# === UPDATE MANAGEMENT ===
var update_timer: float = 0.0
var update_interval: float = 0.1  # Update NPCs every 0.1 seconds
var current_batch_index: int = 0
var npcs_per_batch: int = 100

func _ready():
	print("NPCManager initialized")

func _process(delta: float):
	# Batch update NPCs
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		update_npc_batch(delta)

func update_npc_batch(delta: float):
	if all_npcs.is_empty():
		return
	
	var batch_start = current_batch_index * npcs_per_batch
	var batch_end = min(batch_start + npcs_per_batch, all_npcs.size())
	
	for i in range(batch_start, batch_end):
		if i < all_npcs.size():
			all_npcs[i].update(update_interval)
	
	current_batch_index = (current_batch_index + 1) % ceili(float(all_npcs.size()) / npcs_per_batch)

func add_npc(npc: NPC) -> bool:
	if all_npcs.size() >= max_population:
		return false
	
	all_npcs.append(npc)
	npcs_by_id[npc.npc_id] = npc
	
	EventBus.emit_signal("npc_spawned", npc)
	EventBus.emit_signal("population_changed", all_npcs.size() - 1, all_npcs.size())
	
	return true

func remove_npc(npc: NPC):
	all_npcs.erase(npc)
	npcs_by_id.erase(npc.npc_id)
	
	# Handle group membership
	if npc.group:
		npc.group.remove_member(npc)
	
	EventBus.emit_signal("population_changed", all_npcs.size() + 1, all_npcs.size())

func get_npc_by_id(npc_id: String) -> NPC:
	return npcs_by_id.get(npc_id, null)

func get_all_npcs() -> Array[NPC]:
	return all_npcs

func get_living_npc_count() -> int:
	var count = 0
	for npc in all_npcs:
		if npc.is_alive():
			count += 1
	return count

func find_npcs_in_radius(position: Vector2, radius: float) -> Array[NPC]:
	var found: Array[NPC] = []
	
	for npc in all_npcs:
		if npc.position.distance_to(position) <= radius:
			found.append(npc)
	
	return found

func find_nearest_npc(position: Vector2, filter_func: Callable = Callable()) -> NPC:
	var nearest: NPC = null
	var min_distance: float = INF
	
	for npc in all_npcs:
		if filter_func.is_valid() and not filter_func.call(npc):
			continue
		
		var distance = npc.position.distance_to(position)
		if distance < min_distance:
			min_distance = distance
			nearest = npc
	
	return nearest

# === SPAWN SYSTEM ===
func check_spawn_population():
	var current_count = get_living_npc_count()
	
	if current_count >= max_population:
		return
	
	# Always spawn if critically low
	if current_count < minimum_population:
		spawn_npc_batch()
		return
	
	# Random chance to spawn
	if randf() < spawn_chance:
		spawn_npc_batch()

func spawn_npc_batch():
	var spawn_count = randi_range(spawn_batch_min, spawn_batch_max)
	
	for i in range(spawn_count):
		spawn_single_npc()

func spawn_single_npc():
	var npc = NPC.new()
	
	# Generate basic stats
	npc.name = generate_random_name()
	npc.age = randi_range(18, 65)
	npc.gender = "male" if randf() < 0.7 else "female"
	
	# Randomize stats
	randomize_npc_stats(npc)
	
	# Set spawn position (edge of map)
	npc.position = get_random_spawn_position() * 6
	npc.target_position = npc.position
	
	# Give starting equipment
	give_starting_equipment(npc)
	
	# Add to world
	add_npc(npc)

func randomize_npc_stats(npc: NPC):
	# Base stats (35-65 range for most)
	npc.strength = randi_range(35, 65)
	npc.endurance = randi_range(35, 65)
	npc.intelligence = randi_range(35, 65)
	npc.charisma = randi_range(35, 65)
	npc.perception = randi_range(35, 65)
	npc.agility = randi_range(35, 65)
	npc.luck = randi_range(35, 65)
	
	# Skills (0-50 for starting NPCs)
	npc.combat_skill = randi_range(0, 50)
	npc.trade_skill = randi_range(0, 50)
	npc.tech_skill = randi_range(0, 50)
	npc.medical_skill = randi_range(0, 50)
	npc.research_skill = randi_range(0, 50)
	npc.survival_skill = randi_range(0, 50)
	npc.leadership_skill = randi_range(0, 50)
	
	# Personality
	npc.morality = randi_range(20, 80)
	npc.courage = randi_range(20, 80)
	npc.greed = randi_range(20, 80)
	npc.loyalty = randi_range(20, 80)
	npc.aggression = randi_range(20, 80)
	npc.sociability = randi_range(20, 80)
	npc.ambition = randi_range(20, 80)

func get_random_spawn_position() -> Vector2:
	var edge = randi() % 4  # 0=north, 1=east, 2=south, 3=west
	
	match edge:
		0:  # North
			return Vector2(randf_range(10, 90), 5)
		1:  # East
			return Vector2(95, randf_range(10, 90))
		2:  # South
			return Vector2(randf_range(10, 90), 95)
		3:  # West
			return Vector2(5, randf_range(10, 90))
		_:
			return Vector2(50, 50)

func give_starting_equipment(npc: NPC):
	# Basic money
	npc.inventory.money = randi_range(50, 500)
	
	# Random starting weapon
	var weapon_chance = randf()
	if weapon_chance < 0.3:
		npc.inventory.add_item("pistol", 1)
		npc.inventory.add_item("pistol_ammo", randi_range(10, 30))
		npc.inventory.equip_weapon("pistol")
	elif weapon_chance < 0.5:
		npc.inventory.add_item("shotgun", 1)
		npc.inventory.equip_weapon("shotgun")
	
	# Random armor
	if randf() < 0.4:
		npc.inventory.add_item("leather_jacket", 1)
		npc.inventory.equip_armor("leather_jacket")
	
	# Basic supplies
	npc.inventory.add_item("bread", randi_range(1, 3))
	npc.inventory.add_item("bandage", randi_range(1, 2))

# === NAME GENERATION ===
var first_names_male = ["Ivan", "Sergei", "Dmitri", "Alexei", "Nikolai", "Viktor", "Andrei", "Boris", "Mikhail", "Pavel"]
var first_names_female = ["Anna", "Elena", "Natasha", "Olga", "Marina", "Tatiana", "Svetlana", "Irina", "Maria", "Katya"]
var last_names = ["Petrov", "Ivanov", "Sidorov", "Volkov", "Kozlov", "Novak", "Morozov", "Popov", "Sokolov", "Lebedev"]

func generate_random_name() -> String:
	var is_male = randf() < 0.7
	var first_name = ""
	
	if is_male:
		first_name = first_names_male[randi() % first_names_male.size()]
	else:
		first_name = first_names_female[randi() % first_names_female.size()]
	
	var last_name = last_names[randi() % last_names.size()]
	
	return first_name + " " + last_name

# === STATISTICS ===
func get_population_statistics() -> Dictionary:
	var stats = {
		"total_population": all_npcs.size(),
		"living_count": get_living_npc_count(),
		"groups_count": 0,
		"average_health": 0.0,
		"average_wealth": 0.0,
		"armed_percentage": 0.0
	}
	
	if all_npcs.is_empty():
		return stats
	
	var health_sum = 0
	var wealth_sum = 0
	var armed_count = 0
	var groups_tracked = {}
	
	for npc in all_npcs:
		if npc.is_alive():
			health_sum += npc.health
			wealth_sum += npc.get_net_worth()
			
			if npc.inventory.equipped_weapon != "":
				armed_count += 1
			
			if npc.group and not npc.group.group_id in groups_tracked:
				groups_tracked[npc.group.group_id] = true
				stats["groups_count"] += 1
	
	var living = stats["living_count"]
	if living > 0:
		stats["average_health"] = float(health_sum) / living
		stats["average_wealth"] = float(wealth_sum) / living
		stats["armed_percentage"] = float(armed_count) / living * 100.0
	
	return stats
