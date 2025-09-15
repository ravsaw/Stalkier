# scripts/world/npcs/hybrid_npc_agent.gd
extends RefCounted
class_name HybridNPCAgent

## Enhanced NPC agent that can operate seamlessly in both 2D and 3D modes
## Handles AI, navigation, rendering, and behavior adaptation based on current world mode

# === NPC REFERENCE ===
var npc: NPC = null

# === MODE MANAGEMENT ===
var current_mode: WorldManager.WorldMode = WorldManager.WorldMode.MODE_2D
var supports_mode_switching: bool = true
var preferred_mode: WorldManager.WorldMode = WorldManager.WorldMode.MODE_2D

# === POSITION AND MOVEMENT ===
var position_2d: Vector2 = Vector2()
var position_3d: Vector3 = Vector3()
var velocity_2d: Vector2 = Vector2()
var velocity_3d: Vector3 = Vector3()
var rotation_2d: float = 0.0
var rotation_3d: Vector3 = Vector3()

# === NAVIGATION ===
var navigation_agent_2d: NavigationAgent2D = null
var navigation_agent_3d: NavigationAgent3D = null
var current_navigation_agent: Node = null
var navigation_target_2d: Vector2 = Vector2()
var navigation_target_3d: Vector3 = Vector3()

# === VISUAL REPRESENTATION ===
var visual_node_2d: Node2D = null
var visual_node_3d: Node3D = null
var current_visual_node: Node = null

# === LOD SYSTEM ===
var current_lod_level: int = 0
var max_lod_levels: int = 4
var lod_distances: Array[float] = [25.0, 50.0, 100.0, 200.0]

# === BEHAVIOR ADAPTATION ===
var ai_complexity_2d: float = 1.0  # Full AI in 2D
var ai_complexity_3d: float = 0.8  # Slightly reduced in 3D for performance
var current_ai_complexity: float = 1.0

# === INTERACTION ===
var interaction_range_2d: float = 15.0
var interaction_range_3d: float = 10.0
var can_interact: bool = true

# === PERFORMANCE TRACKING ===
var update_frequency: float = 0.016  # Target 60 FPS
var last_update_time: float = 0.0
var performance_budget: float = 1.0  # 1.0 = full performance, 0.5 = half performance

# === STATE ===
var is_active: bool = true
var is_visible: bool = true
var is_culled: bool = false

func _init(npc_ref: NPC):
	npc = npc_ref
	setup_agent()

func setup_agent():
	print("HybridNPCAgent: Setting up agent for NPC ", npc.name)
	
	# Initialize positions
	position_2d = npc.position
	position_3d = WorldManager.coordinate_converter.convert_2d_to_3d(position_2d)
	
	# Set up navigation agents
	setup_navigation_agents()
	
	# Set up visual nodes
	setup_visual_nodes()
	
	# Set initial mode
	set_mode(WorldManager.get_current_mode())

func setup_navigation_agents():
	# Create 2D navigation agent
	navigation_agent_2d = NavigationAgent2D.new()
	navigation_agent_2d.path_desired_distance = 4.0
	navigation_agent_2d.target_desired_distance = 4.0
	navigation_agent_2d.path_max_distance = 100.0
	navigation_agent_2d.avoidance_enabled = true
	navigation_agent_2d.radius = 2.0
	navigation_agent_2d.max_speed = npc.movement_speed
	
	# Create 3D navigation agent
	navigation_agent_3d = NavigationAgent3D.new()
	navigation_agent_3d.path_desired_distance = 2.0
	navigation_agent_3d.target_desired_distance = 2.0
	navigation_agent_3d.path_max_distance = 100.0
	navigation_agent_3d.avoidance_enabled = true
	navigation_agent_3d.radius = 1.0
	navigation_agent_3d.height = 1.8
	navigation_agent_3d.max_speed = npc.movement_speed
	
	# Set initial agent
	current_navigation_agent = navigation_agent_2d

func setup_visual_nodes():
	# Create 2D visual representation
	create_visual_node_2d()
	
	# Create 3D visual representation
	create_visual_node_3d()
	
	# Set initial visual
	current_visual_node = visual_node_2d

func create_visual_node_2d():
	visual_node_2d = Node2D.new()
	visual_node_2d.name = "NPC_2D_" + npc.name
	
	# Add sprite
	var sprite = Sprite2D.new()
	sprite.texture = preload("res://npc.png")
	sprite.scale = Vector2(0.5, 0.5)
	visual_node_2d.add_child(sprite)
	
	# Add health bar
	var health_bar = ProgressBar.new()
	health_bar.position = Vector2(-10, -20)
	health_bar.size = Vector2(20, 4)
	health_bar.show_percentage = false
	visual_node_2d.add_child(health_bar)
	
	# Add name label
	var name_label = Label.new()
	name_label.text = npc.name
	name_label.position = Vector2(-25, -30)
	name_label.size = Vector2(50, 15)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	visual_node_2d.add_child(name_label)

func create_visual_node_3d():
	visual_node_3d = CharacterBody3D.new()
	visual_node_3d.name = "NPC_3D_" + npc.name
	
	# Add collision shape
	var collision = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	collision.shape = capsule
	visual_node_3d.add_child(collision)
	
	# Add mesh instance
	var mesh_instance = MeshInstance3D.new()
	var capsule_mesh = CapsuleMesh.new()
	capsule_mesh.radius = 0.4
	capsule_mesh.height = 1.8
	mesh_instance.mesh = capsule_mesh
	visual_node_3d.add_child(mesh_instance)
	
	# Add billboard for name/health
	var billboard = create_3d_billboard()
	visual_node_3d.add_child(billboard)

func create_3d_billboard() -> Node3D:
	var billboard = Node3D.new()
	billboard.position = Vector3(0, 2.2, 0)  # Above head
	
	# This would contain UI elements that face the camera
	# In a full implementation, this would be a proper 3D UI billboard
	
	return billboard

func update(delta: float):
	if not is_active or is_culled:
		return
	
	last_update_time += delta
	
	if last_update_time >= update_frequency * (1.0 / performance_budget):
		last_update_time = 0.0
		
		# Update based on current mode
		match current_mode:
			WorldManager.WorldMode.MODE_2D:
				update_2d_mode(delta)
			WorldManager.WorldMode.MODE_3D:
				update_3d_mode(delta)
		
		# Update AI with current complexity
		update_ai(delta * current_ai_complexity)
		
		# Update visual representation
		update_visual()

func update_2d_mode(delta: float):
	# Update 2D navigation
	if navigation_agent_2d and not navigation_agent_2d.is_navigation_finished():
		var next_position = navigation_agent_2d.get_next_path_position()
		var direction = (next_position - position_2d).normalized()
		
		velocity_2d = direction * npc.movement_speed * performance_budget
		position_2d += velocity_2d * delta
		
		# Update rotation
		if velocity_2d.length() > 0.1:
			rotation_2d = velocity_2d.angle()
	
	# Sync with NPC
	npc.position = position_2d
	npc.velocity = velocity_2d

func update_3d_mode(delta: float):
	# Update 3D navigation
	if navigation_agent_3d and not navigation_agent_3d.is_navigation_finished():
		var next_position = navigation_agent_3d.get_next_path_position()
		var direction = (next_position - position_3d).normalized()
		
		velocity_3d = direction * npc.movement_speed * performance_budget
		position_3d += velocity_3d * delta
		
		# Update rotation (Y-axis rotation for turning)
		if velocity_3d.length() > 0.1:
			rotation_3d.y = atan2(velocity_3d.x, velocity_3d.z)
	
	# Sync with NPC
	npc.position_3d = position_3d
	npc.velocity_3d = velocity_3d

func update_ai(delta: float):
	# Update NPC AI with reduced complexity if needed
	if current_ai_complexity > 0.1:
		npc.update_ai(delta)
	else:
		# Skip AI updates when complexity is very low (distant NPCs)
		npc.update_basic_state(delta)

func update_visual():
	# Update visual node position and properties
	if current_visual_node:
		match current_mode:
			WorldManager.WorldMode.MODE_2D:
				if visual_node_2d:
					visual_node_2d.position = position_2d
					visual_node_2d.rotation = rotation_2d
					update_2d_visual_elements()
			
			WorldManager.WorldMode.MODE_3D:
				if visual_node_3d:
					visual_node_3d.position = position_3d
					visual_node_3d.rotation = rotation_3d
					update_3d_visual_elements()

func update_2d_visual_elements():
	if not visual_node_2d:
		return
	
	# Update health bar
	var health_bar = visual_node_2d.get_child(1) as ProgressBar
	if health_bar:
		health_bar.value = npc.health
		health_bar.visible = npc.health < 100 or current_lod_level <= 1
	
	# Update name visibility based on LOD
	var name_label = visual_node_2d.get_child(2) as Label
	if name_label:
		name_label.visible = current_lod_level <= 2
	
	# Update sprite color based on state
	var sprite = visual_node_2d.get_child(0) as Sprite2D
	if sprite:
		sprite.modulate = get_npc_color()

func update_3d_visual_elements():
	if not visual_node_3d:
		return
	
	# Update mesh color
	var mesh_instance = visual_node_3d.get_child(1) as MeshInstance3D
	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override as StandardMaterial3D
		if material:
			material.albedo_color = get_npc_color()

func get_npc_color() -> Color:
	var base_color = Color.WHITE
	
	# Color by group
	if npc.group:
		match npc.group.specialization:
			Group.GroupSpecialization.MILITARY:
				base_color = Color.DARK_GREEN
			Group.GroupSpecialization.TRADING:
				base_color = Color.ORANGE
			Group.GroupSpecialization.RESEARCH:
				base_color = Color.CYAN
			Group.GroupSpecialization.BANDIT:
				base_color = Color.DARK_RED
	
	# Modify based on health
	if npc.health < 30:
		base_color = base_color.lerp(Color.RED, 0.5)
	
	# Modify based on state
	if not npc.is_alive():
		base_color = base_color.darkened(0.7)
	
	return base_color

func set_mode(new_mode: WorldManager.WorldMode):
	if current_mode == new_mode:
		return
	
	var old_mode = current_mode
	current_mode = new_mode
	
	print("HybridNPCAgent: Switching ", npc.name, " from ", WorldManager.WorldMode.keys()[old_mode], " to ", WorldManager.WorldMode.keys()[new_mode])
	
	# Convert positions
	convert_positions(old_mode, new_mode)
	
	# Switch navigation agent
	switch_navigation_agent()
	
	# Switch visual representation
	switch_visual_node()
	
	# Update AI complexity
	update_ai_complexity()

func convert_positions(from_mode: WorldManager.WorldMode, to_mode: WorldManager.WorldMode):
	if from_mode == WorldManager.WorldMode.MODE_2D and to_mode == WorldManager.WorldMode.MODE_3D:
		position_3d = WorldManager.coordinate_converter.convert_2d_to_3d(position_2d)
		velocity_3d = WorldManager.coordinate_converter.convert_velocity_2d_to_3d(velocity_2d, position_3d)
		rotation_3d.y = WorldManager.coordinate_converter.convert_angle_2d_to_3d_y_rotation(rotation_2d)
	
	elif from_mode == WorldManager.WorldMode.MODE_3D and to_mode == WorldManager.WorldMode.MODE_2D:
		position_2d = WorldManager.coordinate_converter.convert_3d_to_2d(position_3d)
		velocity_2d = WorldManager.coordinate_converter.convert_velocity_3d_to_2d(velocity_3d)
		rotation_2d = WorldManager.coordinate_converter.convert_3d_y_rotation_to_2d_angle(rotation_3d.y)

func switch_navigation_agent():
	match current_mode:
		WorldManager.WorldMode.MODE_2D:
			current_navigation_agent = navigation_agent_2d
			if navigation_target_2d != Vector2():
				set_navigation_target_2d(navigation_target_2d)
		
		WorldManager.WorldMode.MODE_3D:
			current_navigation_agent = navigation_agent_3d
			if navigation_target_3d != Vector3():
				set_navigation_target_3d(navigation_target_3d)

func switch_visual_node():
	# Hide old visual
	if current_visual_node:
		current_visual_node.visible = false
	
	# Show new visual
	match current_mode:
		WorldManager.WorldMode.MODE_2D:
			current_visual_node = visual_node_2d
		WorldManager.WorldMode.MODE_3D:
			current_visual_node = visual_node_3d
	
	if current_visual_node:
		current_visual_node.visible = is_visible

func update_ai_complexity():
	match current_mode:
		WorldManager.WorldMode.MODE_2D:
			current_ai_complexity = ai_complexity_2d * performance_budget
		WorldManager.WorldMode.MODE_3D:
			current_ai_complexity = ai_complexity_3d * performance_budget

func set_navigation_target_2d(target: Vector2):
	navigation_target_2d = target
	
	if current_mode == WorldManager.WorldMode.MODE_2D and navigation_agent_2d:
		navigation_agent_2d.target_position = target

func set_navigation_target_3d(target: Vector3):
	navigation_target_3d = target
	
	if current_mode == WorldManager.WorldMode.MODE_3D and navigation_agent_3d:
		navigation_agent_3d.target_position = target

func set_lod_level(lod_level: int):
	current_lod_level = clamp(lod_level, 0, max_lod_levels - 1)
	
	# Adjust performance budget based on LOD
	match current_lod_level:
		0:  # Highest detail
			performance_budget = 1.0
			is_culled = false
		1:  # High detail
			performance_budget = 0.8
			is_culled = false
		2:  # Medium detail
			performance_budget = 0.5
			is_culled = false
		3:  # Low detail
			performance_budget = 0.2
			is_culled = false
		_:  # Culled
			performance_budget = 0.0
			is_culled = true
	
	update_ai_complexity()

func get_interaction_range() -> float:
	match current_mode:
		WorldManager.WorldMode.MODE_2D:
			return interaction_range_2d
		WorldManager.WorldMode.MODE_3D:
			return interaction_range_3d
		_:
			return 10.0

func can_interact_with_position(pos: Vector2) -> bool:
	if not can_interact:
		return false
	
	var agent_pos = position_2d if current_mode == WorldManager.WorldMode.MODE_2D else WorldManager.coordinate_converter.convert_3d_to_2d(position_3d)
	return agent_pos.distance_to(pos) <= get_interaction_range()

func set_visible(visible: bool):
	is_visible = visible
	
	if current_visual_node:
		current_visual_node.visible = visible and not is_culled

func activate():
	is_active = true
	set_visible(true)

func deactivate():
	is_active = false
	set_visible(false)

func cleanup():
	print("HybridNPCAgent: Cleaning up agent for ", npc.name)
	
	# Remove visual nodes
	if visual_node_2d:
		visual_node_2d.queue_free()
	if visual_node_3d:
		visual_node_3d.queue_free()
	
	# Clear references
	navigation_agent_2d = null
	navigation_agent_3d = null
	current_navigation_agent = null
	current_visual_node = null

func get_current_position() -> Vector2:
	match current_mode:
		WorldManager.WorldMode.MODE_2D:
			return position_2d
		WorldManager.WorldMode.MODE_3D:
			return WorldManager.coordinate_converter.convert_3d_to_2d(position_3d)
		_:
			return Vector2()

func get_debug_info() -> Dictionary:
	return {
		"npc_name": npc.name if npc else "None",
		"current_mode": WorldManager.WorldMode.keys()[current_mode],
		"position_2d": position_2d,
		"position_3d": position_3d,
		"lod_level": current_lod_level,
		"performance_budget": performance_budget,
		"ai_complexity": current_ai_complexity,
		"is_active": is_active,
		"is_visible": is_visible,
		"is_culled": is_culled,
		"can_interact": can_interact
	}