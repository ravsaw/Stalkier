# Simple enemy AI - can be expanded later
extends CharacterBody3D
class_name EnemyAI

enum States { IDLE, PATROL, CHASE, ATTACK, SEARCH, FLEE }

@export var enemy_name: String = "Enemy"
@export var max_health: float = 100.0
@export var speed: float = 3.0
@export var attack_damage: float = 10.0
@export var attack_range: float = 1.5
@export var sight_range: float = 20.0
@export var hearing_range: float = 15.0
@export var patrol_points: Array[NodePath] = []

# AI Settings
@export var state: States = States.IDLE
@export var aggression: float = 0.5  # 0-1, affects chase likelihood

# Navigation
@onready var nav_agent = $NavigationAgent3D
@onready var anim_player = $AnimationPlayer

var health: float = max_health
var current_patrol_index: int = 0
var player: Node3D = null
var last_known_player_pos: Vector3 = Vector3.ZERO
var search_time: float = 0.0
var attack_cooldown: float = 0.0
var home_position: Vector3

signal health_changed(new_health, max_health)
signal state_changed(new_state)

func _ready():
	health = max_health
	home_position = global_transform.origin
	player = get_tree().get_nodes_in_group("player")[0] if get_tree().get_nodes_in_group("player").size() > 0 else null
	
	# Initialize patrol points if any
	if patrol_points.size() > 0:
		state = States.PATROL
	
	emit_signal("state_changed", state)

func _physics_process(delta):
	update_state()
	process_state(delta)
	
	# Apply movement
	if velocity != Vector3.ZERO:
		look_at(global_transform.origin + velocity.normalized(), Vector3.UP)
		move_and_slide()

func update_state():
	# Check for player visibility
	var can_see_player = false
	if player and player.has_method("is_alive") and player.is_alive():
		var distance_to_player = global_transform.origin.distance_to(player.global_transform.origin)
		
		if distance_to_player <= sight_range:
			var space_state = get_world_3d().direct_space_state
			var query = PhysicsRayQueryParameters3D.new()
			query.from = global_transform.origin + Vector3(0, 1.5, 0)  # Eye level
			query.to = player.global_transform.origin + Vector3(0, 1.5, 0)
			query.exclude = [self]
			var result = space_state.intersect_ray(query)
			
			can_see_player = !result or (result.has("collider") and result.collider == player)
			
			if can_see_player:
				last_known_player_pos = player.global_transform.origin
				
				if distance_to_player <= attack_range:
					# Close enough to attack
					state = States.ATTACK
				else:
					# Chase player
					state = States.CHASE
			elif state == States.CHASE:
				# Lost sight of player, start searching
				state = States.SEARCH
				search_time = 0.0
		# Also detect player through sound
		elif distance_to_player <= hearing_range and player.has_method("is_making_noise") and player.is_making_noise():
			last_known_player_pos = player.global_transform.origin
			state = States.CHASE

func process_state(delta):
	match state:
		States.IDLE:
			# Just stand around
			velocity = Vector3.ZERO
			
			# Random chance to patrol
			if randf() < 0.01 and patrol_points.size() > 0:
				state = States.PATROL
				emit_signal("state_changed", state)
				
		States.PATROL:
			if patrol_points.size() > 0:
				var target_path = patrol_points[current_patrol_index]
				var target_node = get_node_or_null(target_path)
				
				if target_node:
					var target_pos = target_node.global_transform.origin
					
					# Navigate to target
					nav_agent.set_target_position(target_pos)
					var next_path_pos = nav_agent.get_next_path_position()
					
					# Move toward target
					var direction = (next_path_pos - global_transform.origin).normalized()
					velocity = direction * speed
					
					# Check if reached target
					if global_transform.origin.distance_to(target_pos) < 1.0:
						# Go to next patrol point
						current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
			else:
				state = States.IDLE
				emit_signal("state_changed", state)
				
		States.CHASE:
			# Navigate to player's last known position
			nav_agent.set_target_position(last_known_player_pos)
			var next_path_pos = nav_agent.get_next_path_position()
			
			# Move faster while chasing
			var direction = (next_path_pos - global_transform.origin).normalized()
			velocity = direction * speed * 1.5
			
		States.ATTACK:
			# Stop moving during attack
			velocity = Vector3.ZERO
			
			# Attack player if in range
			attack_cooldown -= delta
			if attack_cooldown <= 0 and player:
				var distance_to_player = global_transform.origin.distance_to(player.global_transform.origin)
				
				if distance_to_player <= attack_range:
					perform_attack()
					attack_cooldown = 1.0  # 1 second between attacks
				else:
					# Player moved out of range, chase again
					state = States.CHASE
					emit_signal("state_changed", state)
			
		States.SEARCH:
			search_time += delta
			
			if search_time < 5.0:  # Search for 5 seconds
				# Navigate to last known position
				nav_agent.set_target_position(last_known_player_pos)
				var next_path_pos = nav_agent.get_next_path_position()
				
				var direction = (next_path_pos - global_transform.origin).normalized()
				velocity = direction * speed
				
				# Check if reached search target
				if global_transform.origin.distance_to(last_known_player_pos) < 1.0:
					# Look around by generating new search points
					last_known_player_pos = global_transform.origin + Vector3(
						randf_range(-5, 5), 
						0, 
						randf_range(-5, 5)
					)
			else:
				# Give up search and go back to patrol/idle
				if patrol_points.size() > 0:
					state = States.PATROL
				else:
					state = States.IDLE
				emit_signal("state_changed", state)
		
		States.FLEE:
			# Run away from player
			if player:
				var flee_direction = (global_transform.origin - player.global_transform.origin).normalized()
				var flee_target = global_transform.origin + flee_direction * 20.0
				
				nav_agent.set_target_position(flee_target)
				var next_path_pos = nav_agent.get_next_path_position()
				
				var direction = (next_path_pos - global_transform.origin).normalized()
				velocity = direction * speed * 1.2  # Slightly faster than normal
				
				# If we're far enough away, go to idle/patrol
				if global_transform.origin.distance_to(player.global_transform.origin) > sight_range * 1.5:
					if patrol_points.size() > 0:
						state = States.PATROL
					else:
						state = States.IDLE
					emit_signal("state_changed", state)

func perform_attack():
	# Play attack animation
	if anim_player and anim_player.has_animation("attack"):
		anim_player.play("attack")
	
	# Deal damage to player
	if player and player.has_method("take_damage"):
		player.take_damage(attack_damage, global_transform.origin)

func take_damage(amount: float, _source_position: Vector3):
	health -= amount
	emit_signal("health_changed", health, max_health)
	
	if health <= 0:
		die()
	else:
		# Respond to being hit
		if player:
			last_known_player_pos = player.global_transform.origin
			
			# Aggressive enemies attack, timid ones flee
			if aggression > 0.5:
				state = States.CHASE
			else:
				state = States.FLEE
			
			emit_signal("state_changed", state)

func die():
	# Play death animation
	if anim_player and anim_player.has_animation("death"):
		anim_player.play("death")
	
	# Disable collision and physics
	$CollisionShape3D.disabled = true
	set_physics_process(false)
	
	# Drop items if needed
	
	# Remove after delay
	await get_tree().create_timer(3.0).timeout
	queue_free()
