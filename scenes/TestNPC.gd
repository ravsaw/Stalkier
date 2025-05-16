class_name TestNPC
extends CharacterBody3D

@export var health: float = 100.0
@export var max_health: float = 100.0
@export var movement_speed: float = 3.0

var brain_system: DualBrainSystem
var faction: String = "neutral"

func _ready():
	# Setup basic NPC structure
	_setup_brain_system()
	_setup_basic_components()
	print("TestNPC ready: ", name)

func _setup_brain_system():
	brain_system = DualBrainSystem.new()
	brain_system.npc_owner = self
	add_child(brain_system)

func _setup_basic_components():
	# Add basic collision
	var collision = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.5
	shape.height = 2.0
	collision.shape = shape
	add_child(collision)
	
	# Add mesh for visibility
	var mesh = MeshInstance3D.new()
	mesh.mesh = CapsuleMesh.new()
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.BLUE
	mesh.set_surface_override_material(0, material)
	add_child(mesh)
	
	# ADD NAVIGATION AGENT BEFORE BRAIN SYSTEM:
	var nav_agent = NavigationAgent3D.new()
	nav_agent.name = "NavigationAgent3D"
	# Configure navigation agent
	nav_agent.radius = 0.5  # Match collision shape
	nav_agent.height = 2.0  # Match collision shape
	nav_agent.max_speed = movement_speed
	add_child(nav_agent)
	
	print("NavigationAgent3D added to: ", name)

func _physics_process(delta):
	# Let the brain system handle movement through tactical brain
	pass

func is_npc() -> bool:
	return true

func get_faction() -> String:
	return faction

func take_damage(amount: float):
	health = max(0, health - amount)
	if health <= 0:
		print(name, " has died!")

# Public methods for testing
func give_exploration_goal(target: Vector3):
	if brain_system:
		brain_system.add_exploration_goal(target)
		print(name, " received exploration goal to: ", target)

func give_survival_goal():
	if brain_system and brain_system.strategic_brain:
		var goal = StrategyGoal.new()
		goal.type = StrategyGoal.Type.SURVIVAL
		goal.priority = 1.0
		goal.description = "Focus on survival"
		brain_system.strategic_brain.add_goal(goal)

func get_brain_status() -> Dictionary:
	if brain_system:
		return brain_system.get_status()
	return {}
	
