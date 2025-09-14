# scenes/Main.gd
extends Node

# === SCENE REFERENCES ===
@onready var world_2d: Node2D = $World2D
@onready var simulation_world: Node2D = $World2D/SimulationWorld
@onready var world_3d: Node3D = $World3D
@onready var camera_3d: Camera3D = $World3D/Camera3D
@onready var player_controller: Node = $PlayerController
@onready var ui_layer: CanvasLayer = $UILayer
@onready var world_info: Label = $UILayer/WorldInfo
@onready var state_info: Label = $UILayer/StateInfo

# === WORLD STATE ===
var current_view_mode: String = "2d"  # "2d" or "3d"
var player_position: Vector2 = Vector2(0, 0)
var update_timer: float = 0.0

func _ready():
	print("Main scene initialized - Hybrid 2D/3D World System")
	
	# Connect world manager to world nodes
	WorldManager.set_world_nodes(world_2d, world_3d)
	
	# Connect to world events
	WorldManager.connect("area_loaded", _on_area_loaded)
	WorldManager.connect("area_unloaded", _on_area_unloaded)
	WorldManager.connect("npc_state_changed", _on_npc_state_changed)
	
	# Initialize player position in world center
	player_position = Vector2(0, 0)
	WorldManager.update_player_position(player_position)
	
	# Setup initial camera
	setup_cameras()
	
	# Start in 2D mode
	switch_to_2d_view()

func _process(delta: float):
	# Update UI periodically
	update_timer += delta
	if update_timer >= 1.0:  # Update every second
		update_timer = 0.0
		update_ui_info()
	
	# Handle input
	handle_input()

func _input(event: InputEvent):
	# Toggle between 2D and 3D views
	if event.is_action_pressed("toggle_view_mode"):
		toggle_view_mode()
	
	# Move player (for testing)
	if event.is_action_pressed("move_player_up"):
		move_player(Vector2(0, -50))
	elif event.is_action_pressed("move_player_down"):
		move_player(Vector2(0, 50))
	elif event.is_action_pressed("move_player_left"):
		move_player(Vector2(-50, 0))
	elif event.is_action_pressed("move_player_right"):
		move_player(Vector2(50, 0))

func handle_input():
	"""Handle continuous input"""
	var movement = Vector2.ZERO
	
	if Input.is_action_pressed("camera_up"):
		movement.y -= 1
	if Input.is_action_pressed("camera_down"):
		movement.y += 1
	if Input.is_action_pressed("camera_left"):
		movement.x -= 1
	if Input.is_action_pressed("camera_right"):
		movement.x += 1
	
	if movement.length() > 0:
		move_player(movement.normalized() * 100 * get_process_delta_time())

func setup_cameras():
	"""Setup camera systems"""
	# 2D camera is handled by simulation_world
	# 3D camera setup
	camera_3d.position = Vector3(0, 50, 50)
	camera_3d.look_at(Vector3.ZERO, Vector3.UP)

func toggle_view_mode():
	"""Toggle between 2D and 3D view modes"""
	if current_view_mode == "2d":
		switch_to_3d_view()
	else:
		switch_to_2d_view()

func switch_to_2d_view():
	"""Switch to 2D view mode"""
	current_view_mode = "2d"
	
	# Show 2D world, hide 3D world
	world_2d.visible = true
	world_3d.visible = false
	
	# Update camera
	var camera_2d = simulation_world.get_node("Camera2D")
	if camera_2d:
		camera_2d.enabled = true
		camera_2d.position = player_position
	
	camera_3d.current = false
	
	world_info.text = "Hybrid 2D/3D World System\nMode: 2D View"
	print("Switched to 2D view")

func switch_to_3d_view():
	"""Switch to 3D view mode"""
	current_view_mode = "3d"
	
	# Show 3D world, hide 2D world
	world_2d.visible = false
	world_3d.visible = true
	
	# Update 3D camera position
	var player_3d_pos = CoordinateConverter.world_2d_to_world_3d(player_position, 10.0)
	camera_3d.position = player_3d_pos + Vector3(0, 30, 30)
	camera_3d.look_at(player_3d_pos, Vector3.UP)
	camera_3d.current = true
	
	# Disable 2D camera
	var camera_2d = simulation_world.get_node("Camera2D")
	if camera_2d:
		camera_2d.enabled = false
	
	world_info.text = "Hybrid 2D/3D World System\nMode: 3D View"
	print("Switched to 3D view")

func move_player(movement: Vector2):
	"""Move player position and update world state"""
	player_position += movement
	WorldManager.update_player_position(player_position)
	
	# Update camera position
	if current_view_mode == "2d":
		var camera_2d = simulation_world.get_node("Camera2D")
		if camera_2d:
			camera_2d.position = player_position
	else:
		var player_3d_pos = CoordinateConverter.world_2d_to_world_3d(player_position, 10.0)
		camera_3d.position = player_3d_pos + Vector3(0, 30, 30)
		camera_3d.look_at(player_3d_pos, Vector3.UP)

func update_ui_info():
	"""Update UI information display"""
	var stats = WorldManager.get_world_statistics()
	var npc_stats = NPCManager.get_population_statistics()
	
	var npcs_3d = 0
	var npcs_2d = 0
	var npcs_despawned = 0
	
	for npc in NPCManager.get_all_npcs():
		match npc.get_representation_state():
			"3d":
				npcs_3d += 1
			"2d":
				npcs_2d += 1
			"despawned":
				npcs_despawned += 1
	
	state_info.text = "Areas Loaded: %d\nNPCs in 3D: %d\nNPCs in 2D: %d\nDespawned: %d\nPlayer Area: %s" % [
		stats.active_3d_areas,
		npcs_3d,
		npcs_2d,
		npcs_despawned,
		stats.current_area
	]

func _on_area_loaded(area_id: String):
	"""Handle area loaded event"""
	print("Area loaded: %s" % area_id)

func _on_area_unloaded(area_id: String):
	"""Handle area unloaded event"""
	print("Area unloaded: %s" % area_id)

func _on_npc_state_changed(npc: NPC, from_state: String, to_state: String):
	"""Handle NPC state change event"""
	print("NPC %s changed from %s to %s" % [npc.name, from_state, to_state])

# Add input actions to project settings if they don't exist
func _notification(what):
	if what == NOTIFICATION_READY:
		# Add input actions if they don't exist
		if not InputMap.has_action("toggle_view_mode"):
			InputMap.add_action("toggle_view_mode")
			var event = InputEventKey.new()
			event.keycode = KEY_TAB
			InputMap.action_add_event("toggle_view_mode", event)
		
		if not InputMap.has_action("move_player_up"):
			InputMap.add_action("move_player_up")
			var event = InputEventKey.new()
			event.keycode = KEY_I
			InputMap.action_add_event("move_player_up", event)
		
		if not InputMap.has_action("move_player_down"):
			InputMap.add_action("move_player_down")
			var event = InputEventKey.new()
			event.keycode = KEY_K
			InputMap.action_add_event("move_player_down", event)
		
		if not InputMap.has_action("move_player_left"):
			InputMap.add_action("move_player_left")
			var event = InputEventKey.new()
			event.keycode = KEY_J
			InputMap.action_add_event("move_player_left", event)
		
		if not InputMap.has_action("move_player_right"):
			InputMap.add_action("move_player_right")
			var event = InputEventKey.new()
			event.keycode = KEY_L
			InputMap.action_add_event("move_player_right", event)