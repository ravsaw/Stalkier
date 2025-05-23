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

func setup(npc_ref: NPC):
	npc = npc_ref
	update_visual()
	
	# Set initial position
	position = npc.position

func _process(_delta: float):
	if not npc:
		return
	
	# Update position smoothly
	position = position.lerp(npc.position, 0.1)
	
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
	if selection_indicator:
		selection_indicator.visible = true
	if name_label:
		name_label.visible = true

func deselect():
	is_selected = false
	if selection_indicator:
		selection_indicator.visible = false
	if name_label and scale.x <= 1.0:
		name_label.visible = false

func _draw():
	# Draw group connections
	if npc and npc.group and npc.group.leader and npc != npc.group.leader:
		var leader_pos = npc.group.leader.position - position
		draw_line(Vector2.ZERO, leader_pos, Color(0.3, 0.3, 0.3, 0.3), 1.0)
	
	# Draw target position when moving
	if npc and npc.position.distance_to(npc.target_position) > 1.0:
		var target_dir = (npc.target_position - npc.position).normalized()
		draw_line(Vector2.ZERO, target_dir * 20, Color.YELLOW, 1.0)

# === SCENE STRUCTURE ===
# NPC2D (Node2D)
# ├── Sprite2D
# ├── HealthBar (ProgressBar)
# ├── NameLabel (Label)
# ├── SelectionIndicator (Node2D with custom draw)
# └── GroupIndicator (Node2D with custom draw)
