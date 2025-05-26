# scripts/simulation/npc_2d.gd
extends Node2D

# === NPC REFERENCE ===
var npc: NPC = null
var is_selected: bool = false

# === VISUAL COMPONENTS ===
@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var name_label: Label = $NameLabel
@onready var selection_indicator: Node2D = $SelectionIndicator
@onready var group_indicator: Node2D = $GroupIndicator
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

# === COLORS ===
var color_by_specialization = {
	Group.GroupSpecialization.UNIVERSAL: Color.WHITE,
	Group.GroupSpecialization.TRADING: Color.ORANGE,
	Group.GroupSpecialization.MILITARY: Color.DARK_GREEN,
	Group.GroupSpecialization.RESEARCH: Color.CYAN,
	Group.GroupSpecialization.BANDIT: Color.DARK_RED
}

var importance_scale = {
	NPC.NPCImportance.DISPOSABLE: 0.8,
	NPC.NPCImportance.REGULAR: 1.0,
	NPC.NPCImportance.NOTABLE: 1.2,
	NPC.NPCImportance.LEGENDARY: 1.5
}

# === DEBUG VISUALIZATION ===
var show_navigation_path: bool = false
var navigation_path: PackedVector2Array = []

signal npc_clicked(npc: NPC)

func _ready():
	# Set up clickable area
	var area = Area2D.new()
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 10
	collision.shape = shape
	area.add_child(collision)
	add_child(area)
	
	area.input_event.connect(_on_area_input_event)
	area.mouse_entered.connect(_on_mouse_entered)
	area.mouse_exited.connect(_on_mouse_exited)
	
	# Initially hide selection
	if selection_indicator:
		selection_indicator.visible = false
	
	# Configure navigation agent
	if navigation_agent:
		navigation_agent.path_postprocessing = NavigationPathQueryParameters2D.PATH_POSTPROCESSING_CORRIDORFUNNEL
		navigation_agent.avoidance_enabled = true
		navigation_agent.radius = 2.0
		navigation_agent.neighbor_distance = 10.0
		navigation_agent.max_neighbors = 10
		navigation_agent.time_horizon = 1.0
		navigation_agent.max_speed = 50.0
		
		# Connect navigation signals
		navigation_agent.velocity_computed.connect(_on_velocity_computed)
		navigation_agent.navigation_finished.connect(_on_navigation_finished)
		navigation_agent.path_changed.connect(_on_path_changed)

func setup(npc_ref: NPC):
	npc = npc_ref
	update_visual()
	
	# Set initial position
	position = npc.position

func get_navigation_agent() -> NavigationAgent2D:
	return navigation_agent

func _physics_process(delta: float):
	if not npc:
		return
	
	# Sync position from NPC to visual
	position = npc.position
	
	# Update navigation agent position
	if navigation_agent and npc.is_navigating:
		
		# Calculate velocity for avoidance
		if not navigation_agent.is_navigation_finished():
			var next_position = navigation_agent.get_next_path_position()
			var direction = (next_position - global_position).normalized()
			var desired_velocity = direction * npc.movement_speed
			
			if navigation_agent.avoidance_enabled:
				navigation_agent.velocity = desired_velocity
			else:
				# Direct movement without avoidance
				npc.position = npc.position + desired_velocity * delta
	
	# Update debug visualization
	if show_navigation_path and navigation_agent:
		navigation_path = navigation_agent.get_current_navigation_path()
		queue_redraw()

func _process(_delta: float):
	if not npc:
		return
	
	# Update visuals
	update_visual()

func update_visual():
	if not npc:
		return
	
	# Update health bar
	if health_bar:
		health_bar.value = npc.health
		health_bar.visible = npc.health < 100
	
	# Update name
	if name_label:
		name_label.text = npc.name
		name_label.visible = is_selected or scale.x > 1.0
	
	# Update color based on group
	if sprite:
		if npc.group:
			sprite.modulate = color_by_specialization.get(npc.group.specialization, Color.WHITE)
		else:
			sprite.modulate = Color.LIGHT_GRAY
		
		# Add red tint if hostile/aggressive
		if npc.aggression > 70:
			sprite.modulate = sprite.modulate.lerp(Color.RED, 0.3)
		
		# Darken if dead
		if not npc.is_alive():
			sprite.modulate = sprite.modulate.darkened(0.7)
	
	# Update scale based on importance
	var target_scale = importance_scale.get(npc.importance, 1.0)
	scale = scale.lerp(Vector2(target_scale, target_scale), 0.1)
	
	# Update group indicator
	if group_indicator:
		group_indicator.visible = npc.group != null and npc.group.leader == npc

func _on_velocity_computed(safe_velocity: Vector2):
	# Apply computed velocity that avoids other agents
	if npc and npc.is_navigating:
		npc.position = npc.position + safe_velocity * get_physics_process_delta_time()

func _on_navigation_finished():
	if npc:
		npc.is_navigating = false

func _on_path_changed():
	if show_navigation_path:
		queue_redraw()

func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			emit_signal("npc_clicked", npc)
			select()

func _on_mouse_entered():
	modulate = Color(1.2, 1.2, 1.2)

func _on_mouse_exited():
	modulate = Color.WHITE

func select():
	is_selected = true
	show_navigation_path = true
	if selection_indicator:
		selection_indicator.visible = true
	if name_label:
		name_label.visible = true

func deselect():
	is_selected = false
	show_navigation_path = false
	if selection_indicator:
		selection_indicator.visible = false
	if name_label and scale.x <= 1.0:
		name_label.visible = false

func _draw():
	# Draw group connections
	if npc and npc.group and npc.group.leader and npc != npc.group.leader:
		var leader_pos = npc.group.leader.position - position
		draw_line(Vector2.ZERO, leader_pos, Color(0.3, 0.3, 0.3, 0.3), 1.0)
	
	# Draw navigation path
	if show_navigation_path and navigation_path.size() > 0:
		# Draw path line
		for i in range(navigation_path.size() - 1):
			var from = navigation_path[i] - global_position
			var to = navigation_path[i + 1] - global_position
			draw_line(from, to, Color.YELLOW, 2.0)
		
		# Draw path points
		for point in navigation_path:
			var local_point = point - global_position
			draw_circle(local_point, 2.0, Color.ORANGE)
		
		# Draw target
		if npc:
			var target_local = npc.target_position - global_position
			draw_circle(target_local, 4.0, Color.RED)
			draw_line(Vector2.ZERO, target_local * 0.3, Color.RED, 2.0)

# === SCENE STRUCTURE ===
# NPC2D (Node2D)
# ├── Sprite2D
# ├── HealthBar (ProgressBar)
# ├── NameLabel (Label)
# ├── SelectionIndicator (Node2D with custom draw)
# ├── GroupIndicator (Node2D with custom draw)
# └── NavigationAgent2D
