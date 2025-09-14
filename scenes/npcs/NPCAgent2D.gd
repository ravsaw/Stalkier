# scenes/npcs/NPCAgent2D.gd
extends CharacterBody2D

# === NPC REFERENCE ===
var npc_data: NPC
var npc_id: String

# === SCENE REFERENCES ===
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var selection_indicator: Node2D = $SelectionIndicator
@onready var health_bar: ProgressBar = $HealthBar
@onready var state_label: Label = $StateLabel

# === VISUAL STATE ===
var is_selected: bool = false
var last_update_time: float = 0.0
var update_frequency: float = 5.0  # Update every 5 seconds in 2D mode

# === SIGNALS ===
signal npc_clicked(npc: NPC)

func _ready():
	# Setup collision shape
	var shape = CircleShape2D.new()
	shape.radius = 8.0
	collision_shape.shape = shape
	
	# Setup input detection
	set_pickable_from_physics(true)
	input_event.connect(_on_input_event)

func setup(npc: NPC):
	"""Initialize the 2D agent with NPC data"""
	npc_data = npc
	npc_id = npc.npc_id
	name = "NPCAgent2D_" + npc_id
	
	# Set initial position
	position = npc.position
	
	# Configure navigation agent
	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = 4.0
	navigation_agent.avoidance_enabled = true
	navigation_agent.radius = 2.0
	navigation_agent.max_speed = npc.movement_speed
	
	# Connect NPC's navigation agent
	npc.set_navigation_agent(navigation_agent)
	
	# Update visual representation
	update_visuals()
	
	print("Setup 2D NPC agent: %s" % npc.name)

func _physics_process(delta: float):
	if not npc_data or not npc_data.is_alive():
		return
	
	# Update position from NPC data
	position = npc_data.position
	
	# Update visuals periodically (not every frame for performance)
	last_update_time += delta
	if last_update_time >= update_frequency:
		last_update_time = 0.0
		update_visuals()

func update_visuals():
	"""Update visual representation based on NPC state"""
	if not npc_data:
		return
	
	# Update health bar
	health_bar.value = npc_data.health
	
	# Update state label
	state_label.text = "2D"
	
	# Color sprite based on NPC state
	var color = Color.WHITE
	
	if npc_data.group:
		# Color based on group specialization
		match npc_data.group.specialization:
			Group.GroupSpecialization.MILITARY:
				color = Color.GREEN
			Group.GroupSpecialization.TRADING:
				color = Color.BLUE
			Group.GroupSpecialization.BANDIT:
				color = Color.RED
			Group.GroupSpecialization.RESEARCH:
				color = Color.PURPLE
			_:
				color = Color.YELLOW
	
	# Apply health-based darkening
	var health_factor = npc_data.health / 100.0
	color = color * (0.5 + health_factor * 0.5)
	
	sprite.modulate = color
	
	# Update name tooltip (simplified)
	tooltip_text = "%s\nHealth: %d\nGroup: %s" % [
		npc_data.name,
		npc_data.health,
		npc_data.group.name if npc_data.group else "Solo"
	]

func select():
	"""Select this NPC agent"""
	is_selected = true
	selection_indicator.visible = true

func deselect():
	"""Deselect this NPC agent"""
	is_selected = false
	selection_indicator.visible = false

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int):
	"""Handle input events on this NPC"""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			emit_signal("npc_clicked", npc_data)

func get_navigation_agent() -> NavigationAgent2D:
	"""Get the navigation agent for this NPC"""
	return navigation_agent

func set_target_position(target: Vector2):
	"""Set navigation target"""
	if navigation_agent:
		navigation_agent.target_position = target

func is_navigation_finished() -> bool:
	"""Check if navigation is finished"""
	return navigation_agent.is_navigation_finished() if navigation_agent else true

func get_next_path_position() -> Vector2:
	"""Get next position in navigation path"""
	return navigation_agent.get_next_path_position() if navigation_agent else position

func show_path_debug():
	"""Show debug path visualization"""
	# This could draw the current navigation path
	queue_redraw()

func _draw():
	"""Custom drawing for debug information"""
	if not is_selected or not npc_data:
		return
	
	# Draw selection circle
	draw_circle(Vector2.ZERO, 12.0, Color.GREEN, false, 2.0)
	
	# Draw group connections
	if npc_data.group and npc_data.group.leader == npc_data:
		# Draw lines to group members
		for member in npc_data.group.members:
			if member != npc_data:
				var member_pos = member.position - position
				draw_line(Vector2.ZERO, member_pos, Color.YELLOW, 1.0)

func update_from_npc_data():
	"""Force update from NPC data"""
	if npc_data:
		position = npc_data.position
		update_visuals()

func cleanup():
	"""Clean up this agent"""
	if npc_data:
		npc_data = null
	queue_free()