class_name StrategicBrain
extends Node

signal command_issued(command: StrategicCommand)
signal goal_completed(goal: StrategyGoal)

@export var npc_owner: CharacterBody3D
var tactical_brain: TacticalBrain

# Core components
var goals: Array[StrategyGoal] = []
var world_knowledge: WorldKnowledge
var memory: NPCMemory
var planning_system: PlanningSystem

# Update rates
var strategic_update_rate: float = 0.2  # 5 Hz
var last_update_time: float = 0.0

func _ready():
	_initialize_components()
	_setup_initial_goals()
	print("StrategicBrain ready for: ", npc_owner.name if npc_owner else "unknown")

func _initialize_components():
	world_knowledge = WorldKnowledge.new()
	memory = NPCMemory.new()
	planning_system = PlanningSystem.new()
	planning_system.npc_owner = npc_owner
	
	add_child(world_knowledge)
	add_child(memory)
	add_child(planning_system)

func _setup_initial_goals():
	# Every NPC starts with basic survival goal
	var survival_goal = StrategyGoal.new()
	survival_goal.type = StrategyGoal.Type.SURVIVAL
	survival_goal.priority = 1.0
	survival_goal.description = "Stay alive and healthy"
	goals.append(survival_goal)

func _process(delta):
	# Strategic thinking at 5 Hz
	if Time.get_ticks_usec() - last_update_time >= strategic_update_rate:
		_strategic_think()
		last_update_time = Time.get_ticks_usec()

func _strategic_think():
	# The main strategic loop
	_update_world_knowledge()
	_evaluate_goals()
	_make_decisions()
	_issue_commands()

func _issue_commands():
	# Process any pending commands that should be sent to tactical brain
	# For now, this is handled in _execute_decision()
	pass
	
func _update_world_knowledge():
	# Get info from tactical brain about what NPC sees
	if tactical_brain and tactical_brain.perception_data:
		world_knowledge.update_from_perception(tactical_brain.perception_data)
	
	# Update knowledge about other NPCs, factions, etc.
	world_knowledge.update_world_state()

func _evaluate_goals():
	# Re-evaluate goal priorities based on current situation
	for goal in goals:
		var new_priority = _calculate_goal_priority(goal)
		goal.priority = new_priority
	
	# Sort by priority
	goals.sort_custom(func(a, b): return a.priority > b.priority)

func _calculate_goal_priority(goal: StrategyGoal) -> float:
	match goal.type:
		StrategyGoal.Type.SURVIVAL:
			# Higher priority when health is low
			var health_percent = npc_owner.get("health") / npc_owner.get("max_health") if npc_owner.has_method("get") else 1.0
			return 1.0 - health_percent + 0.1  # Always some baseline priority
		StrategyGoal.Type.EXPLORATION:
			# Lower priority if we've explored a lot recently
			var recent_exploration = memory.get_recent_exploration_score()
			return 0.3 - recent_exploration * 0.2
		_:
			return goal.priority

func _make_decisions():
	# For now, focus on the top priority goal
	if goals.size() > 0:
		var primary_goal = goals[0]
		var decision = planning_system.create_plan_for_goal(primary_goal, world_knowledge)
		
		if decision:
			_execute_decision(decision)

func _execute_decision(decision):
	# Convert strategic decision to tactical command
	var command = StrategicCommand.new()
	command.type = decision.required_action
	command.target = decision.target_location
	command.parameters = decision.parameters
	command.priority = decision.urgency
	
	command_issued.emit(command)

# Public methods for other systems
func add_goal(goal: StrategyGoal):
	goals.append(goal)
	print("Added goal: ", goal.description)

func remove_goal(goal_type: StrategyGoal.Type):
	goals = goals.filter(func(g): return g.type != goal_type)

func get_current_priorities() -> Array:
	return goals.slice(0, min(3, goals.size()))  # Top 3 priorities
