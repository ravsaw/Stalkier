# scripts/world/world_manager.gd
extends Node

## Hybrid 2D/3D World Manager
## Manages the seamless transition between 2D top-down and 3D FPS modes
## Handles area management, NPC coordination, and world state

# === WORLD STATE ===
enum WorldMode { MODE_2D, MODE_3D, TRANSITIONING }
var current_mode: WorldMode = WorldMode.MODE_2D
var transitioning_to: WorldMode = WorldMode.MODE_2D

# === AREA MANAGEMENT ===
var current_area: Area = null
var loaded_areas: Dictionary = {}  # area_id -> Area
var area_load_queue: Array[String] = []
var max_loaded_areas: int = 9  # 3x3 grid of areas

# === COORDINATE SYSTEM ===
var coordinate_converter: CoordinateConverter
var world_bounds_2d: Rect2 = Rect2(0, 0, 1000, 1000)  # 1000x1000 units
var world_bounds_3d: AABB = AABB(Vector3(-500, -50, -500), Vector3(1000, 100, 1000))

# === CAMERAS ===
var camera_2d: Camera2D
var camera_3d: Camera3D
var active_camera: Node

# === NPC MANAGEMENT ===
var npc_groups_2d: Dictionary = {}  # area_id -> Array[NPCGroup]
var npc_groups_3d: Dictionary = {}  # area_id -> Array[NPCGroup]

# === TRANSITION POINTS ===
var transition_points: Array[TransitionPoint] = []

# === PERFORMANCE ===
var update_timer: float = 0.0
var update_frequency: float = 0.016  # 60 FPS target
var lod_distance_thresholds: Array[float] = [50.0, 100.0, 200.0, 500.0]

# === SIGNALS ===
signal world_mode_changed(new_mode: WorldMode, old_mode: WorldMode)
signal area_loaded(area: Area)
signal area_unloaded(area_id: String)
signal transition_started(from_mode: WorldMode, to_mode: WorldMode)
signal transition_completed(new_mode: WorldMode)

func _ready():
	print("WorldManager: Initializing Hybrid 2D/3D World System")
	
	# Initialize coordinate converter
	coordinate_converter = CoordinateConverter.new()
	coordinate_converter.setup_conversion(world_bounds_2d, world_bounds_3d)
	
	# Connect to events
	EventBus.connect("area_transition_requested", _on_area_transition_requested)
	EventBus.connect("mode_transition_requested", _on_mode_transition_requested)
	
	# Setup initial world
	call_deferred("initialize_world")

func _process(delta: float):
	update_timer += delta
	if update_timer >= update_frequency:
		update_timer = 0.0
		update_world_systems(delta)

func initialize_world():
	print("WorldManager: Setting up initial world areas...")
	
	# Create and load central area
	var central_area = create_initial_area("central", Vector2(500, 500))
	load_area(central_area)
	set_current_area(central_area)
	
	# Set up cameras
	setup_cameras()
	
	# Initialize transition points
	setup_transition_points()
	
	print("WorldManager: World initialization complete")

func create_initial_area(area_id: String, center_position: Vector2) -> Area:
	var area = Area.new()
	area.area_id = area_id
	area.area_type = Area.AreaType.MIXED  # Can support both 2D and 3D
	area.bounds_2d = Rect2(center_position - Vector2(250, 250), Vector2(500, 500))
	area.bounds_3d = coordinate_converter.convert_rect2d_to_aabb(area.bounds_2d)
	area.is_loaded = false
	return area

func setup_cameras():
	# Create 2D camera
	camera_2d = Camera2D.new()
	camera_2d.position_smoothing_enabled = true
	camera_2d.position_smoothing_speed = 5.0
	add_child(camera_2d)
	
	# Create 3D camera
	camera_3d = Camera3D.new()
	camera_3d.position = Vector3(0, 10, 0)
	add_child(camera_3d)
	
	# Set initial active camera
	set_active_camera(camera_2d)

func setup_transition_points():
	# Create example transition points
	var tp1 = TransitionPoint.new()
	tp1.position_2d = Vector2(250, 250)
	tp1.position_3d = coordinate_converter.convert_2d_to_3d(tp1.position_2d)
	tp1.from_mode = WorldMode.MODE_2D
	tp1.to_mode = WorldMode.MODE_3D
	tp1.trigger_radius = 15.0
	transition_points.append(tp1)
	
	var tp2 = TransitionPoint.new()
	tp2.position_2d = Vector2(750, 750)
	tp2.position_3d = coordinate_converter.convert_2d_to_3d(tp2.position_2d)
	tp2.from_mode = WorldMode.MODE_3D
	tp2.to_mode = WorldMode.MODE_2D
	tp2.trigger_radius = 15.0
	transition_points.append(tp2)

func update_world_systems(delta: float):
	if current_mode == WorldMode.TRANSITIONING:
		return
	
	# Update current area
	if current_area:
		current_area.update(delta)
	
	# Update NPC groups in current mode
	update_npc_groups(delta)
	
	# Check for area transitions
	check_area_transitions()
	
	# Update LOD system
	update_lod_system()
	
	# Process area loading queue
	process_area_loading()

func update_npc_groups(delta: float):
	var current_groups = npc_groups_2d if current_mode == WorldMode.MODE_2D else npc_groups_3d
	
	for area_id in current_groups:
		var groups = current_groups[area_id]
		for group in groups:
			if group and group.is_active:
				group.update(delta)

func check_area_transitions():
	# Check if player or important NPCs are near area boundaries
	# This would trigger loading of adjacent areas
	pass

func update_lod_system():
	# Update Level of Detail based on distance and current mode
	if not active_camera:
		return
	
	var camera_pos = get_camera_position()
	
	# Update NPCs LOD
	for npc in NPCManager.get_all_npcs():
		if npc.is_alive():
			update_npc_lod(npc, camera_pos)

func get_camera_position() -> Vector3:
	if current_mode == WorldMode.MODE_2D and camera_2d:
		var pos_2d = camera_2d.global_position
		return coordinate_converter.convert_2d_to_3d(pos_2d)
	elif current_mode == WorldMode.MODE_3D and camera_3d:
		return camera_3d.global_position
	return Vector3.ZERO

func update_npc_lod(npc: NPC, camera_pos: Vector3):
	var npc_pos_3d = coordinate_converter.convert_2d_to_3d(npc.position)
	var distance = camera_pos.distance_to(npc_pos_3d)
	
	# Determine LOD level
	var lod_level = 0
	for i in range(lod_distance_thresholds.size()):
		if distance > lod_distance_thresholds[i]:
			lod_level = i + 1
		else:
			break
	
	npc.set_lod_level(lod_level)

func process_area_loading():
	if area_load_queue.is_empty():
		return
	
	# Load one area per frame to avoid hitches
	var area_id = area_load_queue.pop_front()
	if area_id not in loaded_areas:
		var area = create_area_from_id(area_id)
		load_area(area)

func create_area_from_id(area_id: String) -> Area:
	# This would be expanded to load area data from files/resources
	var area = Area.new()
	area.area_id = area_id
	area.area_type = Area.AreaType.MIXED
	return area

func load_area(area: Area):
	if area.is_loaded:
		return
	
	print("WorldManager: Loading area: ", area.area_id)
	
	# Load area resources
	area.load_resources()
	
	# Create NPC groups for this area
	create_area_npc_groups(area)
	
	# Add to loaded areas
	loaded_areas[area.area_id] = area
	area.is_loaded = true
	
	# Emit signal
	emit_signal("area_loaded", area)
	
	# Manage memory - unload distant areas if we have too many
	manage_loaded_areas()

func create_area_npc_groups(area: Area):
	# Create 2D NPC groups
	var groups_2d = []
	for i in range(randi_range(1, 3)):  # 1-3 groups per area
		var group = NPCGroup.new()
		group.area_id = area.area_id
		group.mode = WorldMode.MODE_2D
		group.setup_for_area(area)
		groups_2d.append(group)
	
	npc_groups_2d[area.area_id] = groups_2d
	
	# Create 3D NPC groups
	var groups_3d = []
	for i in range(randi_range(1, 2)):  # Fewer groups in 3D mode
		var group = NPCGroup.new()
		group.area_id = area.area_id
		group.mode = WorldMode.MODE_3D
		group.setup_for_area(area)
		groups_3d.append(group)
	
	npc_groups_3d[area.area_id] = groups_3d

func manage_loaded_areas():
	if loaded_areas.size() <= max_loaded_areas:
		return
	
	# Find areas furthest from current position to unload
	var camera_pos = get_camera_position()
	var areas_by_distance = []
	
	for area_id in loaded_areas:
		var area = loaded_areas[area_id]
		if area == current_area:
			continue  # Never unload current area
		
		var area_center = coordinate_converter.convert_2d_to_3d(area.bounds_2d.get_center())
		var distance = camera_pos.distance_to(area_center)
		areas_by_distance.append([area_id, distance])
	
	# Sort by distance (furthest first)
	areas_by_distance.sort_custom(func(a, b): return a[1] > b[1])
	
	# Unload furthest areas
	var areas_to_unload = loaded_areas.size() - max_loaded_areas
	for i in range(min(areas_to_unload, areas_by_distance.size())):
		var area_id = areas_by_distance[i][0]
		unload_area(area_id)

func unload_area(area_id: String):
	if area_id not in loaded_areas:
		return
	
	print("WorldManager: Unloading area: ", area_id)
	
	var area = loaded_areas[area_id]
	area.unload_resources()
	
	# Clean up NPC groups
	if area_id in npc_groups_2d:
		for group in npc_groups_2d[area_id]:
			group.cleanup()
		npc_groups_2d.erase(area_id)
	
	if area_id in npc_groups_3d:
		for group in npc_groups_3d[area_id]:
			group.cleanup()
		npc_groups_3d.erase(area_id)
	
	# Remove from loaded areas
	loaded_areas.erase(area_id)
	
	emit_signal("area_unloaded", area_id)

func set_current_area(area: Area):
	if current_area == area:
		return
	
	current_area = area
	print("WorldManager: Current area set to: ", area.area_id)

func set_active_camera(camera: Node):
	if active_camera == camera:
		return
	
	# Disable previous camera
	if active_camera:
		active_camera.enabled = false if active_camera.has_method("set_enabled") else true
		active_camera.current = false if active_camera.has_method("set_current") else true
	
	# Enable new camera
	active_camera = camera
	if active_camera is Camera2D:
		active_camera.enabled = true
	elif active_camera is Camera3D:
		active_camera.current = true

func transition_to_mode(new_mode: WorldMode):
	if current_mode == new_mode or current_mode == WorldMode.TRANSITIONING:
		return
	
	print("WorldManager: Transitioning from ", WorldMode.keys()[current_mode], " to ", WorldMode.keys()[new_mode])
	
	var old_mode = current_mode
	current_mode = WorldMode.TRANSITIONING
	transitioning_to = new_mode
	
	emit_signal("transition_started", old_mode, new_mode)
	
	# Perform transition
	await perform_mode_transition(old_mode, new_mode)
	
	# Complete transition
	current_mode = new_mode
	emit_signal("world_mode_changed", new_mode, old_mode)
	emit_signal("transition_completed", new_mode)

func perform_mode_transition(from_mode: WorldMode, to_mode: WorldMode):
	# Switch cameras
	if to_mode == WorldMode.MODE_2D:
		set_active_camera(camera_2d)
	else:
		set_active_camera(camera_3d)
	
	# Convert NPC positions if needed
	convert_npc_positions(from_mode, to_mode)
	
	# Wait for transition to complete (could add visual effects here)
	await get_tree().create_timer(0.5).timeout

func convert_npc_positions(from_mode: WorldMode, to_mode: WorldMode):
	# Convert all NPC positions between coordinate systems
	for npc in NPCManager.get_all_npcs():
		if from_mode == WorldMode.MODE_2D and to_mode == WorldMode.MODE_3D:
			npc.position_3d = coordinate_converter.convert_2d_to_3d(npc.position)
		elif from_mode == WorldMode.MODE_3D and to_mode == WorldMode.MODE_2D:
			npc.position = coordinate_converter.convert_3d_to_2d(npc.position_3d)

func _on_area_transition_requested(area_id: String):
	# Queue area for loading if not already loaded
	if area_id not in loaded_areas and area_id not in area_load_queue:
		area_load_queue.append(area_id)

func _on_mode_transition_requested(new_mode: WorldMode):
	transition_to_mode(new_mode)

# === UTILITY FUNCTIONS ===
func get_current_mode() -> WorldMode:
	return current_mode

func get_areas_in_range(center: Vector2, range_units: float) -> Array[Area]:
	var areas = []
	for area in loaded_areas.values():
		var area_center = area.bounds_2d.get_center()
		if center.distance_to(area_center) <= range_units:
			areas.append(area)
	return areas

func find_nearest_transition_point(position: Vector2, mode: WorldMode) -> TransitionPoint:
	var nearest: TransitionPoint = null
	var nearest_distance = INF
	
	for tp in transition_points:
		if tp.from_mode != mode:
			continue
		
		var distance = position.distance_to(tp.position_2d)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = tp
	
	return nearest

func is_position_in_transition_range(position: Vector2, mode: WorldMode) -> bool:
	var tp = find_nearest_transition_point(position, mode)
	return tp != null and position.distance_to(tp.position_2d) <= tp.trigger_radius