class_name MovementController
extends Node

var npc_owner: CharacterBody3D
var navigation_agent: NavigationAgent3D
var movement_target: Vector3
var has_target: bool = false

@export var movement_speed: float = 3.0
@export var rotation_speed: float = 5.0
@export var use_navigation: bool = true

func _ready():
	print("MovementController initializing for: ", npc_owner.name if npc_owner else "unknown")
	
	# Try to find NavigationAgent3D in owner
	if npc_owner:
		navigation_agent = npc_owner.get_node_or_null("NavigationAgent3D")
		
		if navigation_agent:
			print("✅ Found existing NavigationAgent3D")
			# Configure the agent
			navigation_agent.max_speed = movement_speed
			navigation_agent.radius = 0.5
			navigation_agent.debug_enabled = true
		else:
			print("⚠️ No NavigationAgent3D found - using direct movement")
			use_navigation = false
	else:
		print("❌ ERROR: No NPC owner assigned!")
		use_navigation = false
			

func move_to(target: Vector3):
	print("🎯 MoveTo called with target: ", target)
	movement_target = target
	has_target = true
	
	if navigation_agent and use_navigation:
		# Wait for navigation agent to be ready
		await get_tree().process_frame
		navigation_agent.target_position = target
		print("📍 NavigationAgent target set to: ", target)
	else:
		print("➡️ Using direct movement mode")
		
func update_movement(delta: float):
	if not has_target or not npc_owner:
		return
	
	var distance_to_target = npc_owner.global_position.distance_to(movement_target)
	
	# Check if we reached the target
	if distance_to_target < 1.0:
		print("✅ Reached target! Distance: %.2f" % distance_to_target)
		has_target = false
		npc_owner.velocity = Vector3.ZERO
		return
	
	var direction: Vector3
	
	if navigation_agent and use_navigation and not navigation_agent.is_navigation_finished():
		# Navigation-based movement
		var next_position = navigation_agent.get_next_path_position()
		direction = (next_position - npc_owner.global_position).normalized()
		print("🧭 Navigation - Next: ", next_position)
	else:
		# Direct movement
		direction = (movement_target - npc_owner.global_position).normalized()
		print("🚶 Direct - Target: ", movement_target)
	
	# Apply movement
	if direction.length() > 0.1:
		npc_owner.velocity = direction * movement_speed
		print("➡️ Velocity set to: ", npc_owner.velocity)
	else:
		npc_owner.velocity = Vector3.ZERO
	
	# Apply the movement
	npc_owner.move_and_slide()
	print("📍 New position: ", npc_owner.global_position)
	
	# Rotate to face movement direction
	if npc_owner.velocity.length() > 0.1:
		var target_transform = npc_owner.global_transform.looking_at(npc_owner.global_position + direction, Vector3.UP)
		npc_owner.global_transform = npc_owner.global_transform.interpolate_with(target_transform, rotation_speed * delta)
		
func get_target() -> Vector3:
	return movement_target if has_target else Vector3.ZERO

func is_moving() -> bool:
	return has_target

func stop():
	has_target = false
	if npc_owner:
		npc_owner.velocity = Vector3.ZERO
	print("🛑 Movement stopped")
