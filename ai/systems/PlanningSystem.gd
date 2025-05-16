class_name PlanningSystem
extends Node

var npc_owner: CharacterBody3D

class StrategicDecision:
	var required_action: String
	var target_location: Vector3
	var parameters: Dictionary
	var urgency: float
	var reasoning: String

func _ready():
	pass

func create_plan_for_goal(goal: StrategyGoal, world_knowledge: WorldKnowledge) -> StrategicDecision:
	var decision = StrategicDecision.new()
	
	match goal.type:
		StrategyGoal.Type.SURVIVAL:
			decision = _plan_survival(goal, world_knowledge)
		StrategyGoal.Type.EXPLORATION:
			decision = _plan_exploration(goal, world_knowledge)
		StrategyGoal.Type.HUNTING:
			decision = _plan_hunting(goal, world_knowledge)
		_:
			# Default action - random movement
			decision.required_action = "move_to"
			decision.target_location = _get_random_nearby_position()
			decision.urgency = 0.5
			decision.reasoning = "No specific plan for goal type"
	
	return decision

func _plan_survival(goal: StrategyGoal, world_knowledge: WorldKnowledge) -> StrategicDecision:
	var decision = StrategicDecision.new()
	
	# Check if we're in immediate danger
	var safe_areas = world_knowledge.get_safe_areas_near(npc_owner.global_position, 50.0)
	
	if safe_areas.size() > 0:
		decision.required_action = "move_to"
		decision.target_location = safe_areas[0]
		decision.urgency = 0.8
		decision.reasoning = "Moving to safe area"
	else:
		# Find nearest safe location
		decision.required_action = "move_to"
		decision.target_location = _find_safer_position()
		decision.urgency = 0.7
		decision.reasoning = "Seeking safer position"
	
	return decision

func _plan_exploration(goal: StrategyGoal, world_knowledge: WorldKnowledge) -> StrategicDecision:
	var decision = StrategicDecision.new()
	
	if goal.target_location != Vector3.ZERO:
		# Specific exploration target
		decision.required_action = "move_to"
		decision.target_location = goal.target_location
		decision.urgency = goal.priority
		decision.reasoning = "Moving to exploration target"
	else:
		# Random exploration
		decision.required_action = "move_to"
		decision.target_location = _get_unexplored_position(world_knowledge)
		decision.urgency = goal.priority
		decision.reasoning = "Random exploration"
	
	return decision

func _plan_hunting(goal: StrategyGoal, world_knowledge: WorldKnowledge) -> StrategicDecision:
	var decision = StrategicDecision.new()
	
	# Look for known NPCs to hunt
	var target_npc = world_knowledge.get_nearest_known_npc(npc_owner.global_position)
	
	if target_npc:
		decision.required_action = "hunt"
		decision.target_location = target_npc.position
		decision.urgency = goal.priority
		decision.reasoning = "Hunting target NPC"
	else:
		# No targets known, explore to find some
		decision.required_action = "move_to"
		decision.target_location = _get_random_nearby_position()
		decision.urgency = goal.priority * 0.8
		decision.reasoning = "Searching for hunting targets"
	
	return decision

func _get_random_nearby_position() -> Vector3:
	var angle = randf() * TAU
	var distance = randf_range(5.0, 15.0)
	var offset = Vector3(cos(angle) * distance, 0, sin(angle) * distance)
	return npc_owner.global_position + offset

func _find_safer_position() -> Vector3:
	# Simple implementation - move away from center of danger
	# In real implementation, this would analyze known threats
	return _get_random_nearby_position()

func _get_unexplored_position(world_knowledge: WorldKnowledge) -> Vector3:
	# Find area we haven't been to recently
	# For now, just return random position
	return _get_random_nearby_position()
