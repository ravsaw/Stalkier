# scripts/world/world_main.gd
extends Node

## Main World Scene Controller
## Handles the hybrid 2D/3D world visualization and user interaction

# === SCENE REFERENCES ===
@onready var world_2d: Node2D = $"2DWorld"
@onready var world_3d: Node3D = $"3DWorld" 
@onready var camera_2d: Camera2D = $"2DWorld/Camera2D"
@onready var camera_3d: Camera3D = $"3DWorld/Camera3D"
@onready var areas_2d: Node2D = $"2DWorld/Areas2D"
@onready var npcs_2d: Node2D = $"2DWorld/NPCs2D"
@onready var areas_3d: Node3D = $"3DWorld/Areas3D"
@onready var npcs_3d: Node3D = $"3DWorld/NPCs3D"
@onready var transition_overlay: ColorRect = $TransitionOverlay
@onready var debug_info: VBoxContainer = $DebugInfo

# === UI REFERENCES ===
@onready var mode_label: Label = $DebugInfo/ModeLabel
@onready var area_label: Label = $DebugInfo/AreaLabel
@onready var npc_count_label: Label = $DebugInfo/NPCCountLabel
@onready var performance_label: Label = $DebugInfo/PerformanceLabel

# === WORLD MANAGER REFERENCE ===
var world_manager: WorldManager = null

# === CURRENT STATE ===
var current_mode: WorldManager.WorldMode = WorldManager.WorldMode.MODE_2D
var is_transitioning: bool = false

# === VISUAL NODES ===
var area_visual_nodes_2d: Dictionary = {}  # area_id -> Node2D
var area_visual_nodes_3d: Dictionary = {}  # area_id -> Node3D
var npc_visual_nodes_2d: Dictionary = {}   # npc_id -> Node2D
var npc_visual_nodes_3d: Dictionary = {}   # npc_id -> Node3D

# === INPUT HANDLING ===
var camera_move_speed: float = 200.0
var camera_zoom_speed: float = 0.1
var mouse_sensitivity: float = 0.001

# === DEBUG ===
var show_debug_info: bool = true
var debug_update_timer: float = 0.0

func _ready():
	print("WorldMain: Initializing main world scene")
	
	# Set up world manager
	setup_world_manager()
	
	# Set initial mode
	set_world_mode(WorldManager.WorldMode.MODE_2D)
	
	# Connect signals
	connect_signals()
	
	# Initialize UI
	update_debug_ui()
	
	print("WorldMain: Ready")

func setup_world_manager():
	# Create and configure WorldManager
	world_manager = WorldManager.new()
	add_child(world_manager)
	
	# Set camera references
	world_manager.camera_2d = camera_2d
	world_manager.camera_3d = camera_3d
	world_manager.active_camera = camera_2d

func connect_signals():
	# Connect WorldManager signals
	world_manager.world_mode_changed.connect(_on_world_mode_changed)
	world_manager.area_loaded.connect(_on_area_loaded)
	world_manager.area_unloaded.connect(_on_area_unloaded)
	world_manager.transition_started.connect(_on_transition_started)
	world_manager.transition_completed.connect(_on_transition_completed)
	
	# Connect EventBus signals
	EventBus.npc_spawned.connect(_on_npc_spawned)
	EventBus.npc_died.connect(_on_npc_died)

func _process(delta: float):
	# Update debug info
	if show_debug_info:
		debug_update_timer += delta
		if debug_update_timer >= 1.0:  # Update every second
			debug_update_timer = 0.0
			update_debug_ui()
	
	# Handle camera input
	handle_camera_input(delta)

func _unhandled_input(event: InputEvent):
	# Mode switching
	if event.is_action_pressed("toggle_world_mode"):
		toggle_world_mode()
	
	# Debug toggles
	if event.is_action_pressed("toggle_debug_info"):
		toggle_debug_info()
	
	# Camera controls
	handle_camera_input_events(event)

func handle_camera_input(delta: float):
	match current_mode:
		WorldManager.WorldMode.MODE_2D:
			handle_2d_camera_input(delta)
		WorldManager.WorldMode.MODE_3D:
			handle_3d_camera_input(delta)

func handle_2d_camera_input(delta: float):
	var movement = Vector2()
	
	# WASD movement
	if Input.is_action_pressed("camera_left"):
		movement.x -= 1
	if Input.is_action_pressed("camera_right"):
		movement.x += 1
	if Input.is_action_pressed("camera_up"):
		movement.y -= 1
	if Input.is_action_pressed("camera_down"):
		movement.y += 1
	
	if movement.length() > 0:
		camera_2d.position += movement.normalized() * camera_move_speed * delta

func handle_3d_camera_input(delta: float):
	var movement = Vector3()
	
	# WASD movement
	if Input.is_action_pressed("camera_left"):
		movement -= camera_3d.transform.basis.x
	if Input.is_action_pressed("camera_right"):
		movement += camera_3d.transform.basis.x
	if Input.is_action_pressed("camera_up"):
		movement -= camera_3d.transform.basis.z
	if Input.is_action_pressed("camera_down"):
		movement += camera_3d.transform.basis.z
	
	if movement.length() > 0:
		camera_3d.position += movement.normalized() * camera_move_speed * delta

func handle_camera_input_events(event: InputEvent):
	match current_mode:
		WorldManager.WorldMode.MODE_2D:
			handle_2d_camera_events(event)
		WorldManager.WorldMode.MODE_3D:
			handle_3d_camera_events(event)

func handle_2d_camera_events(event: InputEvent):
	# Zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_2d.zoom *= (1.0 + camera_zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_2d.zoom *= (1.0 - camera_zoom_speed)
	
	# Click to move camera
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
		var world_pos = camera_2d.get_global_mouse_position()
		var tween = create_tween()
		tween.tween_property(camera_2d, "position", world_pos, 0.5)

func handle_3d_camera_events(event: InputEvent):
	# Mouse look
	if event is InputEventMouseMotion and Input.is_action_pressed("camera_look"):
		var rotation_x = -event.relative.y * mouse_sensitivity
		var rotation_y = -event.relative.x * mouse_sensitivity
		
		camera_3d.rotate_x(rotation_x)
		camera_3d.rotate_y(rotation_y)
		
		# Clamp vertical rotation
		var euler = camera_3d.rotation
		euler.x = clamp(euler.x, -PI/2, PI/2)
		camera_3d.rotation = euler

func set_world_mode(new_mode: WorldManager.WorldMode):
	if current_mode == new_mode or is_transitioning:
		return
	
	current_mode = new_mode
	
	# Show/hide appropriate world nodes
	match new_mode:
		WorldManager.WorldMode.MODE_2D:
			world_2d.visible = true
			world_3d.visible = false
			camera_2d.enabled = true
			camera_3d.current = false
		
		WorldManager.WorldMode.MODE_3D:
			world_2d.visible = false
			world_3d.visible = true
			camera_2d.enabled = false
			camera_3d.current = true

func toggle_world_mode():
	if is_transitioning:
		return
	
	var new_mode = WorldManager.WorldMode.MODE_3D if current_mode == WorldManager.WorldMode.MODE_2D else WorldManager.WorldMode.MODE_2D
	
	# Request mode change through WorldManager
	EventBus.emit_signal("mode_transition_requested", new_mode)

func toggle_debug_info():
	show_debug_info = !show_debug_info
	debug_info.visible = show_debug_info

func update_debug_ui():
	if not show_debug_info:
		return
	
	# Update mode
	mode_label.text = "Mode: " + WorldManager.WorldMode.keys()[current_mode]
	
	# Update area
	var current_area = world_manager.current_area
	area_label.text = "Area: " + (current_area.area_id if current_area else "None")
	
	# Update NPC count
	var npc_count = NPCManager.get_all_npcs().size()
	npc_count_label.text = "NPCs: " + str(npc_count)
	
	# Update FPS
	performance_label.text = "FPS: " + str(Engine.get_frames_per_second())

# === SIGNAL HANDLERS ===

func _on_world_mode_changed(new_mode: WorldManager.WorldMode, old_mode: WorldManager.WorldMode):
	print("WorldMain: Mode changed from ", WorldManager.WorldMode.keys()[old_mode], " to ", WorldManager.WorldMode.keys()[new_mode])
	set_world_mode(new_mode)

func _on_area_loaded(area: Area):
	print("WorldMain: Area loaded - ", area.area_id)
	create_area_visuals(area)

func _on_area_unloaded(area_id: String):
	print("WorldMain: Area unloaded - ", area_id)
	remove_area_visuals(area_id)

func _on_transition_started(from_mode: WorldManager.WorldMode, to_mode: WorldManager.WorldMode):
	print("WorldMain: Transition started")
	is_transitioning = true
	start_transition_effect()

func _on_transition_completed(new_mode: WorldManager.WorldMode):
	print("WorldMain: Transition completed")
	is_transitioning = false
	end_transition_effect()

func _on_npc_spawned(npc: NPC):
	create_npc_visuals(npc)

func _on_npc_died(npc: NPC, killer: NPC):
	remove_npc_visuals(npc.npc_id)

# === VISUAL MANAGEMENT ===

func create_area_visuals(area: Area):
	# Create 2D area visuals
	var area_node_2d = Node2D.new()
	area_node_2d.name = "Area_" + area.area_id
	areas_2d.add_child(area_node_2d)
	area_visual_nodes_2d[area.area_id] = area_node_2d
	
	# Draw area bounds
	draw_area_bounds_2d(area_node_2d, area.bounds_2d)
	
	# Create 3D area visuals (simplified)
	var area_node_3d = Node3D.new()
	area_node_3d.name = "Area_" + area.area_id
	areas_3d.add_child(area_node_3d)
	area_visual_nodes_3d[area.area_id] = area_node_3d
	
	# Create ground mesh for 3D
	create_area_ground_3d(area_node_3d, area.bounds_3d)

func draw_area_bounds_2d(area_node: Node2D, bounds: Rect2):
	# Create a simple border visualization
	var line = Line2D.new()
	line.add_point(bounds.position)
	line.add_point(Vector2(bounds.position.x + bounds.size.x, bounds.position.y))
	line.add_point(bounds.position + bounds.size)
	line.add_point(Vector2(bounds.position.x, bounds.position.y + bounds.size.y))
	line.add_point(bounds.position)
	line.default_color = Color(0.5, 0.5, 0.5, 0.8)
	line.width = 2.0
	area_node.add_child(line)

func create_area_ground_3d(area_node: Node3D, bounds: AABB):
	# Create a simple ground plane
	var mesh_instance = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(bounds.size.x, bounds.size.z)
	mesh_instance.mesh = plane_mesh
	mesh_instance.position = bounds.get_center()
	
	# Create basic material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.4, 0.6, 0.3)  # Grass-like color
	mesh_instance.material_override = material
	
	area_node.add_child(mesh_instance)

func remove_area_visuals(area_id: String):
	# Remove 2D visuals
	if area_id in area_visual_nodes_2d:
		area_visual_nodes_2d[area_id].queue_free()
		area_visual_nodes_2d.erase(area_id)
	
	# Remove 3D visuals
	if area_id in area_visual_nodes_3d:
		area_visual_nodes_3d[area_id].queue_free()
		area_visual_nodes_3d.erase(area_id)

func create_npc_visuals(npc: NPC):
	# The HybridNPCAgent handles its own visuals
	# This is just for any additional world-level NPC visuals
	pass

func remove_npc_visuals(npc_id: String):
	# Clean up any world-level NPC visuals
	if npc_id in npc_visual_nodes_2d:
		npc_visual_nodes_2d[npc_id].queue_free()
		npc_visual_nodes_2d.erase(npc_id)
	
	if npc_id in npc_visual_nodes_3d:
		npc_visual_nodes_3d[npc_id].queue_free()
		npc_visual_nodes_3d.erase(npc_id)

# === TRANSITION EFFECTS ===

func start_transition_effect():
	# Fade transition overlay
	var tween = create_tween()
	tween.tween_property(transition_overlay, "color", Color(0, 0, 0, 1), 0.3)

func end_transition_effect():
	# Fade out transition overlay
	var tween = create_tween()
	tween.tween_property(transition_overlay, "color", Color(0, 0, 0, 0), 0.3)

# === UTILITY FUNCTIONS ===

func get_world_mouse_position() -> Vector2:
	match current_mode:
		WorldManager.WorldMode.MODE_2D:
			return camera_2d.get_global_mouse_position()
		WorldManager.WorldMode.MODE_3D:
			# This would require 3D mouse picking
			return Vector2()
		_:
			return Vector2()

func focus_camera_on_position(position: Vector2):
	match current_mode:
		WorldManager.WorldMode.MODE_2D:
			var tween = create_tween()
			tween.tween_property(camera_2d, "position", position, 1.0)
		WorldManager.WorldMode.MODE_3D:
			var pos_3d = world_manager.coordinate_converter.convert_2d_to_3d(position)
			pos_3d.y += 10.0  # Elevate camera
			var tween = create_tween()
			tween.tween_property(camera_3d, "position", pos_3d, 1.0)

func focus_camera_on_npc(npc: NPC):
	focus_camera_on_position(npc.position)

# === DEBUG FUNCTIONS ===

func _on_debug_spawn_npc():
	var mouse_pos = get_world_mouse_position()
	if mouse_pos != Vector2():
		spawn_debug_npc_at(mouse_pos)

func spawn_debug_npc_at(position: Vector2):
	var npc = NPC.new()
	npc.name = NPCManager.generate_random_name()
	npc.age = randi_range(18, 65)
	NPCManager.randomize_npc_stats(npc)
	npc.position = position
	npc.target_position = position
	NPCManager.give_starting_equipment(npc)
	
	if NPCManager.add_npc(npc):
		print("WorldMain: Debug spawned NPC at ", position)