# scripts/world/test_world.gd
extends Node

## Simple test scene for the hybrid 2D/3D world system

var world_manager: WorldManager

func _ready():
	print("TestWorld: Starting hybrid system test")
	
	# Create a minimal world manager for testing
	world_manager = WorldManager.new()
	add_child(world_manager)
	
	# Give it some time to initialize
	await get_tree().create_timer(1.0).timeout
	
	# Test basic functionality
	test_coordinate_conversion()
	test_area_creation()
	test_npc_creation()

func test_coordinate_conversion():
	print("TestWorld: Testing coordinate conversion...")
	
	if world_manager.coordinate_converter:
		var pos_2d = Vector2(100, 200)
		var pos_3d = world_manager.coordinate_converter.convert_2d_to_3d(pos_2d)
		var back_to_2d = world_manager.coordinate_converter.convert_3d_to_2d(pos_3d)
		
		print("  2D->3D->2D: ", pos_2d, " -> ", pos_3d, " -> ", back_to_2d)
		print("  Error: ", pos_2d.distance_to(back_to_2d))
	else:
		print("  ERROR: CoordinateConverter not found!")

func test_area_creation():
	print("TestWorld: Testing area creation...")
	
	var area = Area.new()
	area.setup("test_area", Area.AreaType.MIXED, Rect2(0, 0, 200, 200))
	area.load_resources()
	
	print("  Created area: ", area.area_id)
	print("  Bounds 2D: ", area.bounds_2d)
	print("  Bounds 3D: ", area.bounds_3d)
	print("  Spawn points: ", area.spawn_points_2d.size())

func test_npc_creation():
	print("TestWorld: Testing NPC creation...")
	
	var npc = NPC.new()
	npc.name = "TestNPC"
	npc.position = Vector2(50, 50)
	npc.setup_hybrid_agent()
	
	print("  Created NPC: ", npc.name)
	print("  Position 2D: ", npc.position)
	print("  Has hybrid agent: ", npc.hybrid_agent != null)
	
	if npc.hybrid_agent:
		npc.hybrid_agent.set_mode(WorldManager.WorldMode.MODE_3D)
		print("  Switched to 3D mode")
		print("  Position 3D: ", npc.hybrid_agent.position_3d)

func _input(event: InputEvent):
	if event.is_action_pressed("ui_accept"):
		print("TestWorld: Running additional tests...")
		test_transition_points()
		test_mode_switching()

func test_transition_points():
	print("TestWorld: Testing transition points...")
	
	var tp = TransitionPoint.new()
	tp.setup(Vector2(100, 100), Vector3.ZERO, WorldManager.WorldMode.MODE_2D, WorldManager.WorldMode.MODE_3D)
	tp.trigger_radius = 20.0
	
	print("  Created transition point at ", tp.position_2d)
	print("  Trigger radius: ", tp.trigger_radius)
	print("  From mode: ", WorldManager.WorldMode.keys()[tp.from_mode])
	print("  To mode: ", WorldManager.WorldMode.keys()[tp.to_mode])

func test_mode_switching():
	print("TestWorld: Testing mode switching...")
	
	if world_manager:
		print("  Current mode: ", WorldManager.WorldMode.keys()[world_manager.current_mode])
		
		# Test mode transition
		var new_mode = WorldManager.WorldMode.MODE_3D if world_manager.current_mode == WorldManager.WorldMode.MODE_2D else WorldManager.WorldMode.MODE_2D
		print("  Requesting switch to: ", WorldManager.WorldMode.keys()[new_mode])
		
		world_manager.transition_to_mode(new_mode)
		
		await get_tree().create_timer(2.0).timeout
		print("  Final mode: ", WorldManager.WorldMode.keys()[world_manager.current_mode])