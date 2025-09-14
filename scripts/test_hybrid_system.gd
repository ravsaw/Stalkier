# scripts/test_hybrid_system.gd
# Test script to verify hybrid 2D/3D world system functionality

extends RefCounted
class_name HybridSystemTest

static func run_tests():
	print("=== Hybrid 2D/3D World System Tests ===")
	
	test_coordinate_conversion()
	test_area_management()
	test_npc_state_transitions()
	test_group_formations()
	test_transition_points()
	
	print("=== All Tests Completed ===")

static func test_coordinate_conversion():
	print("\n--- Testing Coordinate Conversion ---")
	
	# Test 2D to 3D conversion
	var pos_2d = Vector2(100, 200)
	var area_center = Vector2(0, 0)
	var pos_3d = CoordinateConverter.world_2d_to_local_3d(pos_2d, area_center)
	
	print("2D pos %s -> 3D pos %s" % [pos_2d, pos_3d])
	assert(pos_3d.x == 100.0 and pos_3d.z == 200.0, "2D to 3D conversion failed")
	
	# Test 3D to 2D conversion
	var converted_back = CoordinateConverter.local_3d_to_world_2d(pos_3d, area_center)
	print("3D pos %s -> 2D pos %s" % [pos_3d, converted_back])
	assert(converted_back.x == 100.0 and converted_back.y == 200.0, "3D to 2D conversion failed")
	
	# Test area coordinates
	var world_pos = Vector2(1500, -500)
	var area_coords = CoordinateConverter.get_area_from_world_position(world_pos)
	print("World pos %s -> Area coords %s" % [world_pos, area_coords])
	
	print("✓ Coordinate conversion tests passed")

static func test_area_management():
	print("\n--- Testing Area Management ---")
	
	# Create test area
	var area = Area.new()
	area.setup_basic_area("test_area", Vector2(1000, 1000), "Test Area")
	
	print("Created area: %s at %s" % [area.display_name, area.world_position])
	assert(area.area_id == "test_area", "Area ID not set correctly")
	assert(area.world_position == Vector2(1000, 1000), "Area position not set correctly")
	
	# Test position checks
	var test_pos = Vector2(1200, 800)
	var in_area = area.is_position_in_area(test_pos)
	print("Position %s in area: %s" % [test_pos, in_area])
	assert(in_area, "Position should be in area bounds")
	
	# Test spawn points
	area.generate_default_spawn_points()
	var spawn_point = area.get_random_spawn_point()
	print("Random spawn point: %s" % spawn_point)
	assert(spawn_point != Vector2.ZERO, "Should have valid spawn point")
	
	print("✓ Area management tests passed")

static func test_npc_state_transitions():
	print("\n--- Testing NPC State Transitions ---")
	
	# Create test NPC
	var npc = NPC.new()
	npc.name = "Test NPC"
	npc.position = Vector2(100, 100)
	
	print("Created NPC: %s at %s" % [npc.name, npc.position])
	
	# Test state changes
	assert(npc.get_representation_state() == "2d", "NPC should start in 2D state")
	
	npc.set_representation_state("3d")
	assert(npc.get_representation_state() == "3d", "NPC should be in 3D state")
	print("NPC state changed to: %s" % npc.get_representation_state())
	
	npc.set_representation_state("despawned")
	assert(npc.get_representation_state() == "despawned", "NPC should be despawned")
	print("NPC state changed to: %s" % npc.get_representation_state())
	
	print("✓ NPC state transition tests passed")

static func test_group_formations():
	print("\n--- Testing Group Formations ---")
	
	# Create test group with leader
	var group = Group.new()
	group.name = "Test Group"
	
	var leader = NPC.new()
	leader.name = "Leader"
	leader.position = Vector2(0, 0)
	group.add_member(leader)
	
	print("Created group: %s with leader: %s" % [group.name, leader.name])
	assert(group.leader == leader, "Leader should be set correctly")
	
	# Add members
	for i in range(3):
		var member = NPC.new()
		member.name = "Member %d" % (i + 1)
		member.position = Vector2(i * 10, 0)
		group.add_member(member)
	
	print("Group has %d members" % group.get_member_count())
	assert(group.get_member_count() == 4, "Group should have 4 members")
	
	# Test formation positions
	group.set_formation_type("line")
	var leader_pos = Vector2(0, 0)
	var leader_dir = Vector2(1, 0)
	
	for i in range(3):
		var formation_pos = group.get_formation_position(i, leader_pos, leader_dir)
		print("Member %d formation position: %s" % [i, formation_pos])
		assert(formation_pos.x < 0, "Formation members should be behind leader")
	
	print("✓ Group formation tests passed")

static func test_transition_points():
	print("\n--- Testing Transition Points ---")
	
	# Create transition point
	var transition = TransitionPoint.new()
	transition.setup("area_1", "area_2", Vector2(500, 0), Vector2(-500, 0))
	
	print("Created transition from %s to %s" % [transition.from_area_id, transition.to_area_id])
	assert(transition.from_area_id == "area_1", "From area not set correctly")
	assert(transition.to_area_id == "area_2", "To area not set correctly")
	
	# Test NPC transition capability
	var npc = NPC.new()
	npc.position = Vector2(495, 0)  # Close to transition point
	
	var can_use = transition.can_npc_use_transition(npc)
	print("NPC can use transition: %s" % can_use)
	assert(can_use, "NPC should be able to use transition when close enough")
	
	# Test distance check
	npc.position = Vector2(600, 0)  # Too far from transition
	can_use = transition.can_npc_use_transition(npc)
	print("NPC can use transition when far: %s" % can_use)
	assert(not can_use, "NPC should not be able to use transition when too far")
	
	print("✓ Transition point tests passed")

# Helper assertion function
static func assert(condition: bool, message: String):
	if not condition:
		print("ASSERTION FAILED: %s" % message)
		push_error("Test assertion failed: %s" % message)