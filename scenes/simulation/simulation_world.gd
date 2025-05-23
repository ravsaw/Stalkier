# scripts/simulation/simulation_world.gd
extends Node2D

# === SCENE REFERENCES ===
@onready var camera: Camera2D = $Camera2D
@onready var ui_controller: Control = $UILayer/UIController
@onready var npcs_container: Node2D = $NPCs
@onready var pois_container: Node2D = $POIs
@onready var grid_overlay: Node2D = $GridOverlay

# === VISUAL NODES ===
var npc_nodes: Dictionary = {}  # npc_id -> NPC2D node
var poi_nodes: Dictionary = {}  # poi_id -> POI visual node

# === PREFABS ===
var npc_2d_scene = preload("res://scenes/simulation/npc_2d.tscn")

# === SELECTION ===
var selected_npc_node: Node2D = null

func _ready():
	print("SimulationWorld ready")
	
	# Connect to events
	EventBus.connect("npc_spawned", _on_npc_spawned)
	EventBus.connect("npc_died", _on_npc_died)
	
	# Create visuals for existing entities
	create_all_visuals()
	
	# Set up grid
	setup_grid_overlay()

func create_all_visuals():
	# Create NPC visuals
	for npc in NPCManager.get_all_npcs():
		create_npc_visual(npc)
	
	# Create POI visuals
	for poi in POIManager.get_all_pois():
		create_poi_visual(poi)

func create_npc_visual(npc: NPC):
	if npc.npc_id in npc_nodes:
		return  # Already exists
	
	var npc_node = npc_2d_scene.instantiate()
	npc_node.setup(npc)
	npc_node.position = npc.position
	npc_node.connect("npc_clicked", _on_npc_clicked)
	
	npcs_container.add_child(npc_node)
	npc_nodes[npc.npc_id] = npc_node

func create_poi_visual(poi: POI):
	if poi.poi_id in poi_nodes:
		return  # Already exists
	
	# Create simple POI visualization
	var poi_node = Node2D.new()
	poi_node.position = poi.position
	
	# Add sprite based on POI type
	var sprite = Sprite2D.new()
	sprite.texture = preload("res://icon.svg")  # Placeholder - use actual POI icons
	sprite.scale = Vector2(0.2, 0.2)
	
	# Color based on type
	match poi.poi_type:
		POI.POIType.MAIN_BASE:
			sprite.modulate = Color.GREEN
			sprite.scale = Vector2(0.2, 0.2)
		POI.POIType.MILITARY_POST:
			sprite.modulate = Color.DARK_GREEN
		POI.POIType.CIVILIAN_SETTLEMENT:
			sprite.modulate = Color.LIGHT_BLUE
		POI.POIType.ANOMALY_ZONE:
			sprite.modulate = Color.PURPLE
			sprite.scale = Vector2(0.2, 0.2)
		POI.POIType.TRADING_POST:
			sprite.modulate = Color.ORANGE
		_:
			sprite.modulate = Color.GRAY
	
	poi_node.add_child(sprite)
	
	# Add label
	var label = Label.new()
	label.text = poi.name
	label.position = Vector2(-50, -30)
	label.add_theme_font_size_override("font_size", 12)
	poi_node.add_child(label)
	
	# Add clickable area
	var area = Area2D.new()
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 20
	collision.shape = shape
	area.add_child(collision)
	poi_node.add_child(area)
	
	area.input_event.connect(func(_viewport, event, _shape_idx): _on_poi_input(event, poi))
	
	pois_container.add_child(poi_node)
	poi_nodes[poi.poi_id] = poi_node

func setup_grid_overlay():
	# Draw grid for reference
	grid_overlay.set_draw_behind_parent(true)
	grid_overlay.queue_redraw()

func _draw():
	# Override in grid overlay node to draw grid
	pass

func _on_grid_overlay_draw():
	var grid_color = Color(0.2, 0.2, 0.2, 0.3)
	var grid_size = 10  # 10x10 units grid
	
	# Draw vertical lines
	for x in range(0, 101, grid_size):
		grid_overlay.draw_line(
			Vector2(x, 0),
			Vector2(x, 100),
			grid_color,
			1.0
		)
	
	# Draw horizontal lines
	for y in range(0, 101, grid_size):
		grid_overlay.draw_line(
			Vector2(0, y),
			Vector2(100, y),
			grid_color,
			1.0
		)
	
	# Draw border
	grid_overlay.draw_rect(
		Rect2(0, 0, 100, 100),
		Color(0.4, 0.4, 0.4, 0.5),
		false,
		2.0
	)

func _on_npc_spawned(npc: NPC):
	create_npc_visual(npc)

func _on_npc_died(npc: NPC, _killer: NPC):
	if npc.npc_id in npc_nodes:
		var node = npc_nodes[npc.npc_id]
		npc_nodes.erase(npc.npc_id)
		node.queue_free()

func _on_npc_clicked(npc: NPC):
	# Deselect previous
	if selected_npc_node:
		selected_npc_node.deselect()
	
	# Select new
	if npc.npc_id in npc_nodes:
		selected_npc_node = npc_nodes[npc.npc_id]
		selected_npc_node.select()
		
		# Update UI
		ui_controller.select_npc(npc)
		
		# Center camera on NPC
		if Input.is_key_pressed(KEY_F):
			camera.center_on_npc(npc)

func _on_poi_input(event: InputEvent, poi: POI):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Deselect NPC if selected
			if selected_npc_node:
				selected_npc_node.deselect()
				selected_npc_node = null
			
			# Update UI
			ui_controller.select_poi(poi)
			
			# Center camera on POI
			if Input.is_key_pressed(KEY_F):
				camera.center_on_poi(poi)

func _unhandled_input(event: InputEvent):
	# Debug functions
	if event.is_action_pressed("debug_spawn_npc"):
		var mouse_pos = get_global_mouse_position()
		debug_spawn_npc_at_position(mouse_pos)
	
	if event.is_action_pressed("debug_spawn_combat"):
		GameManager.spawn_test_combat()

func debug_spawn_npc_at_position(pos: Vector2):
	var npc = NPC.new()
	npc.name = NPCManager.generate_random_name()
	npc.age = randi_range(18, 65)
	NPCManager.randomize_npc_stats(npc)
	npc.position = pos
	npc.target_position = pos
	NPCManager.give_starting_equipment(npc)
	
	if NPCManager.add_npc(npc):
		print("Debug: Spawned NPC at position %s" % pos)
	else:
		print("Debug: Failed to spawn NPC (population limit reached)")

# === MINIMAP ===
func setup_minimap():
	# In full implementation, would create a minimap camera
	# that renders simplified version of the world
	pass

# Debug action mappings to add:
# debug_spawn_npc: N
# debug_spawn_combat: C
