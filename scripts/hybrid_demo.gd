# scripts/hybrid_demo.gd
# Demonstration script for the hybrid 2D/3D world system

extends RefCounted
class_name HybridDemo

static func create_demonstration_scenario():
	"""Create a demonstration scenario to show the hybrid system working"""
	print("\n=== Creating Hybrid 2D/3D World System Demo ===")
	
	# Create some test NPCs at different distances
	create_demo_npcs()
	
	# Create test groups
	create_demo_groups()
	
	# Show system statistics
	show_system_stats()
	
	print("=== Demo Setup Complete ===")
	print("Use WASD to move around, TAB to switch 2D/3D view")
	print("Use I/J/K/L to move player position and see state changes")

static func create_demo_npcs():
	"""Create NPCs at different distances to demonstrate state transitions"""
	print("\nCreating demo NPCs...")
	
	var positions = [
		Vector2(50, 50),     # Close - should be 3D
		Vector2(300, 200),   # Medium - should be 3D
		Vector2(700, 500),   # Far - should be 2D
		Vector2(1200, 800),  # Very far - should be despawned
	]
	
	for i in range(positions.size()):
		var npc = NPC.new()
		npc.name = "Demo NPC %d" % (i + 1)
		npc.age = randi_range(20, 50)
		npc.gender = "male" if randf() < 0.5 else "female"
		
		# Randomize stats
		NPCManager.randomize_npc_stats(npc)
		
		# Set position
		npc.position = positions[i]
		npc.target_position = npc.position
		
		# Give basic equipment
		NPCManager.give_starting_equipment(npc)
		
		# Add to world
		if NPCManager.add_npc(npc):
			print("  Created %s at %s" % [npc.name, npc.position])
		
		# Small delay to ensure unique IDs
		await get_tree().process_frame

static func create_demo_groups():
	"""Create demo groups to show formation behavior"""
	print("\nCreating demo groups...")
	
	# Create a military patrol group
	var military_group = create_group_at_position(Vector2(400, 300), "Military Patrol", 4)
	military_group.specialization = Group.GroupSpecialization.MILITARY
	military_group.set_formation_type("wedge")
	
	# Create a trading caravan
	var trade_group = create_group_at_position(Vector2(800, 600), "Trade Caravan", 6)
	trade_group.specialization = Group.GroupSpecialization.TRADING
	trade_group.set_formation_type("line")
	
	# Create a bandit gang
	var bandit_group = create_group_at_position(Vector2(1000, 200), "Bandit Gang", 5)
	bandit_group.specialization = Group.GroupSpecialization.BANDIT
	bandit_group.set_formation_type("circle")

static func create_group_at_position(center_pos: Vector2, group_name: String, size: int) -> Group:
	"""Create a group of NPCs at a specific position"""
	var group = Group.new()
	group.name = group_name
	
	# Create leader
	var leader = create_npc_at_position(center_pos, group_name + " Leader")
	leader.leadership_skill = randi_range(60, 90)
	leader.combat_skill = randi_range(50, 80)
	group.add_member(leader)
	
	# Create members around the leader
	for i in range(size - 1):
		var angle = (TAU / (size - 1)) * i
		var offset = Vector2.RIGHT.rotated(angle) * randf_range(20, 40)
		var member_pos = center_pos + offset
		
		var member = create_npc_at_position(member_pos, "%s Member %d" % [group_name, i + 1])
		group.add_member(member)
	
	# Add group to manager
	GroupManager.add_group(group)
	
	print("  Created group: %s with %d members at %s" % [group_name, size, center_pos])
	return group

static func create_npc_at_position(pos: Vector2, npc_name: String) -> NPC:
	"""Create an NPC at a specific position"""
	var npc = NPC.new()
	npc.name = npc_name
	npc.age = randi_range(20, 50)
	npc.gender = "male" if randf() < 0.7 else "female"
	
	# Randomize stats
	NPCManager.randomize_npc_stats(npc)
	
	# Set position
	npc.position = pos
	npc.target_position = pos
	
	# Give equipment
	NPCManager.give_starting_equipment(npc)
	
	# Add to world
	NPCManager.add_npc(npc)
	
	return npc

static func show_system_stats():
	"""Show current system statistics"""
	print("\nSystem Statistics:")
	
	var world_stats = WorldManager.get_world_statistics()
	print("  Active 3D Areas: %d" % world_stats.active_3d_areas)
	print("  Total Areas: %d" % world_stats.total_areas)
	print("  Current Area: %s" % world_stats.current_area)
	
	var npc_stats = NPCManager.get_population_statistics()
	print("  Total NPCs: %d" % npc_stats.total_population)
	print("  Living NPCs: %d" % npc_stats.living_count)
	
	var group_stats = GroupManager.get_group_statistics()
	print("  Total Groups: %d" % group_stats.total_groups)
	print("  Active Groups: %d" % group_stats.active_groups)

static func get_tree():
	"""Get the scene tree (helper for async operations)"""
	return Engine.get_main_loop()

# Add some utility functions for testing the system
static func demonstrate_state_transitions():
	"""Demonstrate NPC state transitions by moving player"""
	print("\n=== Demonstrating State Transitions ===")
	
	# Move player to different positions and show state changes
	var test_positions = [
		Vector2(0, 0),      # Center - many NPCs should be 3D
		Vector2(600, 600),  # Edge - mixed states
		Vector2(1500, 1500) # Far corner - most should be 2D/despawned
	]
	
	for pos in test_positions:
		print("\nMoving player to: %s" % pos)
		WorldManager.update_player_position(pos)
		
		# Count NPCs in each state
		var state_counts = {"2d": 0, "3d": 0, "despawned": 0}
		
		for npc in NPCManager.get_all_npcs():
			var state = npc.get_representation_state()
			if state in state_counts:
				state_counts[state] += 1
		
		print("  NPC States - 2D: %d, 3D: %d, Despawned: %d" % [
			state_counts["2d"], 
			state_counts["3d"], 
			state_counts["despawned"]
		])
		
		# Small delay
		await get_tree().create_timer(1.0).timeout

static func demonstrate_formations():
	"""Demonstrate group formations"""
	print("\n=== Demonstrating Group Formations ===")
	
	var formations = ["line", "wedge", "column", "circle"]
	
	for group in GroupManager.get_all_groups():
		if group.get_member_count() >= 3:
			print("\nTesting formations for group: %s" % group.name)
			
			for formation in formations:
				print("  Setting formation: %s" % formation)
				group.set_formation_type(formation)
				group.update_formation()
				
				# Show member positions
				for i in range(min(3, group.members.size())):
					var member = group.members[i]
					print("    %s at %s" % [member.name, member.target_position])
				
				await get_tree().create_timer(0.5).timeout
			
			break  # Only test first group