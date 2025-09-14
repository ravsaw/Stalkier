# scripts/singletons/game_manager.gd
extends Node

# === GAME STATE ===
var game_time: float = 6.0  # Start at 6:00 AM
var game_day: int = 1
var game_speed: float = 1.0  # Time multiplier
var is_paused: bool = false

# === TIME CONFIGURATION ===
@export var day_length_seconds: float = 2400.0  # 20 minutes real time = 1 game day
@export var hours_per_day: float = 24.0

# === SPAWN TIMER ===
var spawn_check_timer: float = 0.0
var group_formation_timer: float = 0.0

signal time_updated(time: float, day: int)
signal day_passed(day: int)
signal game_paused(paused: bool)

func _ready():
	print("GameManager initialized")
	
	# Connect to events
	EventBus.connect("npc_died", _on_npc_died)
	
	# Run hybrid system tests
	call_deferred("run_system_tests")
	
	# Initialize world
	call_deferred("initialize_game_world")

func _process(delta: float):
	if is_paused:
		return
	
	# Update game time
	update_game_time(delta)
	
	# Update timers
	update_timers(delta)

func initialize_game_world():
	print("Initializing game world...")
	
	# Spawn initial population
	spawn_initial_population()
	
	# Form initial groups
	form_initial_groups()
	
	# Create demonstration scenario
	call_deferred("create_demo_scenario")
	
	print("World initialization complete!")

func create_demo_scenario():
	"""Create hybrid system demonstration scenario"""
	HybridDemo.create_demonstration_scenario()

func spawn_initial_population():
	var initial_count = NPCManager.minimum_population
	
	print("Spawning %d initial NPCs..." % initial_count)
	
	for i in range(initial_count):
		NPCManager.spawn_single_npc()
	
	print("Initial population spawned: %d NPCs" % NPCManager.get_living_npc_count())

func form_initial_groups():
	# Let some NPCs form groups immediately
	var solo_npcs = []
	
	for npc in NPCManager.get_all_npcs():
		if not npc.group:
			solo_npcs.append(npc)
	
	# Form 10-15 initial groups
	var groups_to_form = randi_range(10, 15)
	var groups_formed = 0
	
	for npc in solo_npcs:
		if groups_formed >= groups_to_form:
			break
		
		if npc.leadership_skill > 40:
			GroupManager.attempt_group_formation(npc)
			groups_formed += 1
	
	print("Initial groups formed: %d" % GroupManager.get_all_groups().size())

func update_game_time(delta: float):
	var time_increment = (hours_per_day / day_length_seconds) * delta * game_speed
	game_time += time_increment
	
	# Handle day rollover
	if game_time >= 24.0:
		game_time -= 24.0
		game_day += 1
		emit_signal("day_passed", game_day)
		EventBus.emit_signal("day_passed", game_day)
	
	emit_signal("time_updated", game_time, game_day)

func update_timers(delta: float):
	# Spawn check timer
	spawn_check_timer += delta
	if spawn_check_timer >= NPCManager.spawn_check_interval:
		spawn_check_timer = 0.0
		NPCManager.check_spawn_population()
	
	# Group formation timer
	group_formation_timer += delta
	if group_formation_timer >= 60.0:  # Check every minute
		group_formation_timer = 0.0
		GroupManager.check_group_formation()
		CombatManager.check_revenge_opportunities()

func _on_npc_died(npc: NPC, killer: NPC):
	# Handle death consequences
	if killer and killer.group and npc.group and killer.group != npc.group:
		# Create revenge motivation
		CombatManager.create_revenge_target(npc.group, killer.group, 0.5)

# === TIME CONTROL ===
func set_game_speed(speed: float):
	game_speed = clamp(speed, 0.0, 100.0)

func pause_game():
	is_paused = true
	emit_signal("game_paused", true)

func unpause_game():
	is_paused = false
	emit_signal("game_paused", false)

func toggle_pause():
	if is_paused:
		unpause_game()
	else:
		pause_game()

# === UTILITY FUNCTIONS ===
func get_time_string() -> String:
	var hour = int(game_time)
	var minute = int((game_time - hour) * 60)
	return "%02d:%02d" % [hour, minute]

func get_date_string() -> String:
	return "Day %d" % game_day

func is_night_time() -> bool:
	return game_time < 6.0 or game_time > 20.0

# === STATISTICS ===
func get_world_statistics() -> Dictionary:
	var stats = {
		"game_time": get_time_string(),
		"game_day": game_day,
		"population": NPCManager.get_population_statistics(),
		"groups": GroupManager.get_group_statistics(),
		"pois": POIManager.get_poi_statistics(),
		"economy": EconomyManager.get_economy_statistics(),
		"conflict_intensity": CombatManager.get_recent_conflict_intensity()
	}
	
	return stats

# === SAVE/LOAD SYSTEM ===
func save_game(save_path: String = "user://savegame.dat"):
	var save_file = FileAccess.open(save_path, FileAccess.WRITE)
	if not save_file:
		print("Failed to save game!")
		return
	
	var save_data = {
		"version": 1,
		"game_time": game_time,
		"game_day": game_day,
		"npcs": [],
		"groups": [],
		"pois": []
	}
	
	# Save NPCs
	for npc in NPCManager.get_all_npcs():
		save_data["npcs"].append(npc.to_dict())
	
	# Save groups
	for group in GroupManager.get_all_groups():
		save_data["groups"].append(group.to_dict())
	
	# Save POIs
	for poi in POIManager.get_all_pois():
		save_data["pois"].append(poi.to_dict())
	
	save_file.store_var(save_data)
	save_file.close()
	
	print("Game saved successfully!")

func load_game(save_path: String = "user://savegame.dat"):
	if not FileAccess.file_exists(save_path):
		print("Save file not found!")
		return
	
	var save_file = FileAccess.open(save_path, FileAccess.READ)
	if not save_file:
		print("Failed to load game!")
		return
	
	var save_data = save_file.get_var()
	save_file.close()
	
	# Restore game state
	game_time = save_data.get("game_time", 6.0)
	game_day = save_data.get("game_day", 1)
	
	# Clear current state
	# Note: In full implementation, would need to properly clear all managers
	
	print("Game loaded successfully!")

# === DEBUG FUNCTIONS ===
func spawn_test_combat():
	# Find two nearby groups for testing
	var groups = GroupManager.get_all_groups()
	if groups.size() >= 2:
		CombatManager.initiate_combat(groups[0], groups[1])
		print("Test combat initiated between %s and %s" % [groups[0].name, groups[1].name])
	else:
		print("Not enough groups for test combat!")

func add_test_resources():
	# Add resources to all POIs for testing
	for poi in POIManager.get_all_pois():
		poi.available_resources["food"] += 50
		poi.available_resources["medical"] += 20
		poi.available_resources["ammo"] += 30
	print("Test resources added to all POIs")

func run_system_tests():
	"""Run hybrid system tests"""
	print("Running hybrid 2D/3D world system tests...")
	HybridSystemTest.run_tests()
	print("System tests completed!")
