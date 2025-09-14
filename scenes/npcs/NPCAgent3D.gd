# scenes/npcs/NPCAgent3D.gd
extends CharacterBody3D

# === NPC REFERENCE ===
var npc_data: NPC
var npc_id: String

# === SCENE REFERENCES ===
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var head: Node3D = $Head
@onready var eyes: Node3D = $Head/Eyes
@onready var selection_indicator: Node3D = $SelectionIndicator
@onready var ui: Node3D = $UI
@onready var health_bar_3d: MeshInstance3D = $UI/HealthBar3D
@onready var state_label_3d: Label3D = $UI/StateLabel3D

# === MOVEMENT ===
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var last_velocity: Vector3 = Vector3.ZERO

# === VISUAL STATE ===
var is_selected: bool = false
var face_direction: Vector3 = Vector3.FORWARD

# === SIGNALS ===
signal npc_clicked_3d(npc: NPC)

func _ready():
	# Setup navigation agent
	navigation_agent.velocity_computed.connect(_on_velocity_computed)
	
	# Setup 3D UI elements
	setup_3d_ui()

func setup(npc: NPC):
	"""Initialize the 3D agent with NPC data"""
	npc_data = npc
	npc_id = npc.npc_id
	name = "NPCAgent3D_" + npc_id
	
	# Set initial position
	if npc.representation_state == "3d":
		position = npc.position_3d
	else:
		position = CoordinateConverter.world_2d_to_local_3d(npc.position, Vector2.ZERO)
	
	# Configure navigation agent
	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = 4.0
	navigation_agent.avoidance_enabled = true
	navigation_agent.radius = 0.5
	navigation_agent.height = 2.0
	navigation_agent.max_speed = npc.movement_speed
	
	# Connect NPC's 3D navigation agent
	npc.set_navigation_agent_3d(navigation_agent)
	
	# Update visual representation
	update_visuals()
	
	print("Setup 3D NPC agent: %s" % npc.name)

func _physics_process(delta: float):
	if not npc_data or not npc_data.is_alive():
		return
	
	# Update position from NPC data
	if npc_data.representation_state == "3d":
		position = npc_data.position_3d
	
	# Handle 3D movement with navigation
	handle_3d_movement(delta)
	
	# Update visual elements
	update_visuals()
	
	# Update head direction
	update_head_direction()

func handle_3d_movement(delta: float):
	"""Handle 3D movement with physics"""
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Handle navigation
	if navigation_agent.is_navigation_finished():
		velocity.x = move_toward(velocity.x, 0, npc_data.movement_speed * delta)
		velocity.z = move_toward(velocity.z, 0, npc_data.movement_speed * delta)
	else:
		var next_position = navigation_agent.get_next_path_position()
		var direction = (next_position - global_position).normalized()
		
		# Only move horizontally, let gravity handle Y
		velocity.x = direction.x * npc_data.movement_speed
		velocity.z = direction.z * npc_data.movement_speed
		
		# Update face direction
		if direction.length() > 0.1:
			face_direction = direction
	
	# Move the character
	move_and_slide()
	
	# Update NPC position
	if npc_data:
		npc_data.position_3d = position
		npc_data.position = Vector2(position.x, position.z)

func _on_velocity_computed(safe_velocity: Vector3):
	"""Handle computed velocity from navigation"""
	velocity = safe_velocity

func setup_3d_ui():
	"""Setup 3D UI elements"""
	# Create health bar mesh
	var health_material = StandardMaterial3D.new()
	health_material.albedo_color = Color.GREEN
	health_material.flags_unshaded = true
	health_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	
	var health_mesh = BoxMesh.new()
	health_mesh.size = Vector3(1.0, 0.1, 0.05)
	
	health_bar_3d.mesh = health_mesh
	health_bar_3d.material_override = health_material
	
	# Setup state label
	state_label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	state_label_3d.text = "3D"

func update_visuals():
	"""Update visual representation based on NPC state"""
	if not npc_data:
		return
	
	# Update health bar
	update_health_bar()
	
	# Update mesh color based on NPC state
	var material = mesh_instance.get_surface_override_material(0)
	if not material:
		material = StandardMaterial3D.new()
		mesh_instance.set_surface_override_material(0, material)
	
	# Color based on group
	var color = Color.WHITE
	if npc_data.group:
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
	
	material.albedo_color = color

func update_health_bar():
	"""Update 3D health bar"""
	if not npc_data:
		return
	
	var health_percent = npc_data.health / 100.0
	
	# Scale health bar based on health
	var health_scale = Vector3(health_percent, 1.0, 1.0)
	health_bar_3d.scale = health_scale
	
	# Color health bar
	var health_material = health_bar_3d.get_surface_override_material(0)
	if health_material:
		if health_percent > 0.6:
			health_material.albedo_color = Color.GREEN
		elif health_percent > 0.3:
			health_material.albedo_color = Color.YELLOW
		else:
			health_material.albedo_color = Color.RED

func update_head_direction():
	"""Update head facing direction"""
	if face_direction.length() > 0.1:
		var target_rotation = atan2(face_direction.x, face_direction.z)
		head.rotation.y = lerp_angle(head.rotation.y, target_rotation, 0.1)

func select():
	"""Select this 3D NPC agent"""
	is_selected = true
	selection_indicator.visible = true
	
	# Create selection ring if not exists
	var selection_ring = selection_indicator.get_node("SelectionRing")
	if not selection_ring.mesh:
		var ring_mesh = CylinderMesh.new()
		ring_mesh.height = 0.1
		ring_mesh.top_radius = 1.0
		ring_mesh.bottom_radius = 1.0
		
		var ring_material = StandardMaterial3D.new()
		ring_material.albedo_color = Color.GREEN
		ring_material.flags_unshaded = true
		ring_material.flags_transparent = true
		
		selection_ring.mesh = ring_mesh
		selection_ring.material_override = ring_material

func deselect():
	"""Deselect this 3D NPC agent"""
	is_selected = false
	selection_indicator.visible = false

func set_target_position_3d(target: Vector3):
	"""Set 3D navigation target"""
	if navigation_agent:
		navigation_agent.target_position = target

func is_navigation_finished() -> bool:
	"""Check if 3D navigation is finished"""
	return navigation_agent.is_navigation_finished() if navigation_agent else true

func get_next_path_position() -> Vector3:
	"""Get next position in 3D navigation path"""
	return navigation_agent.get_next_path_position() if navigation_agent else position

func get_navigation_agent_3d() -> NavigationAgent3D:
	"""Get the 3D navigation agent"""
	return navigation_agent

func look_at_target(target_position: Vector3):
	"""Make NPC look at a target position"""
	var direction = (target_position - position).normalized()
	if direction.length() > 0.1:
		face_direction = direction

func play_animation(animation_name: String):
	"""Play NPC animation (placeholder)"""
	# This would control an AnimationPlayer when we have proper 3D models
	print("Playing animation: %s for %s" % [animation_name, npc_data.name])

func show_interaction_prompt(prompt_text: String):
	"""Show interaction prompt above NPC"""
	# Create temporary label for interaction
	var prompt_label = Label3D.new()
	prompt_label.text = prompt_text
	prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_label.position = Vector3(0, 3.0, 0)
	
	ui.add_child(prompt_label)
	
	# Remove after delay
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.timeout.connect(func(): prompt_label.queue_free(); timer.queue_free())
	add_child(timer)
	timer.start()

func cleanup():
	"""Clean up this 3D agent"""
	if npc_data:
		npc_data = null
	queue_free()