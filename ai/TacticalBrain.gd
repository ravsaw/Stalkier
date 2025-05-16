class_name TacticalBrain
extends Node

signal status_update(status: TacticalStatus)
signal action_completed(action)

@export var npc_owner: CharacterBody3D
var strategic_brain: StrategicBrain

# Core components
var perception_system: PerceptionSystem
var movement_controller: MovementController
var action_executor: ActionExecutor
var state_machine: TacticalStateMachine

# Data the strategic brain can access
var perception_data: PerceptionData
var current_state: String = "idle"

# Command queue from strategic brain
var command_queue: Array[StrategicCommand] = []
var current_command: StrategicCommand
var completed_actions: Array = []

func _ready():
	_initialize_components()
	print("TacticalBrain ready for: ", npc_owner.name if npc_owner else "unknown")

func _initialize_components():
	perception_system = PerceptionSystem.new()
	perception_system.npc_owner = npc_owner
	add_child(perception_system)
	
	movement_controller = MovementController.new()
	movement_controller.npc_owner = npc_owner
	add_child(movement_controller)
	
	action_executor = ActionExecutor.new()
	action_executor.npc_owner = npc_owner
	add_child(action_executor)
	
	state_machine = TacticalStateMachine.new()
	state_machine.npc_owner = npc_owner
	add_child(state_machine)

func _physics_process(delta):
	# Tactical thinking at full framerate
	_update_perception()
	_process_commands()
	_execute_current_actions(delta)
	_update_status()

func _update_perception():
	# Scan environment for immediate threats, obstacles, etc.
	perception_data = perception_system.scan_environment()
	
	# React to immediate threats regardless of strategic commands
	if perception_data.immediate_threats.size() > 0:
		_handle_immediate_threat(perception_data.immediate_threats[0])

func _handle_immediate_threat(threat):
	# Emergency override - interrupt current actions for survival
	if not current_command or current_command.priority < 0.9:
		var emergency_command = StrategicCommand.new()
		emergency_command.type = "avoid_threat"
		emergency_command.target = _calculate_safe_position(threat)
		emergency_command.priority = 1.0
		
		command_queue.push_front(emergency_command)

func _process_commands():
	# Get new commands from strategic brain
	if command_queue.size() > 0 and not current_command:
		current_command = command_queue.pop_front()
		_start_command_execution(current_command)

func _start_command_execution(command: StrategicCommand):
	print("Executing command: ", command.type)
	current_state = command.type
	
	# Proper command to state mapping
	var target_state = "idle"  # default
	
	match command.type:
		"move_to":
			target_state = "moving"
			movement_controller.move_to(command.target)
		"explore_area":
			target_state = "moving"
			_start_exploration(command.target)
		"avoid_threat":
			target_state = "fleeing"
			_execute_avoidance(command.target)
		"gather_resource":
			target_state = "moving"
			_start_gathering(command.target)
	
	state_machine.change_state(target_state)

func _execute_current_actions(delta):
	# Update movement controller
	movement_controller.update_movement(delta)
	
	# DEBUG: Print current state
	#if current_command:
	#	print("💰 NPC Status:")
	#	print("   Position: ", npc_owner.global_position)
	#	print("   Target: ", current_command.target)
	#	print("   Velocity: ", npc_owner.velocity)
	#	print("   Has Target: ", movement_controller.has_target)
		
	# Update current action execution
	if current_command:
		var action_result = _check_command_completion()
		
		if action_result == "completed":
			_command_completed()
		elif action_result == "failed":
			_command_failed()

func _check_command_completion() -> String:
	if not current_command:
		return "completed"
	
	match current_command.type:
		"move_to":
			if current_command.target.distance_to(npc_owner.global_position) < 1.0:
				return "completed"
			elif current_command.is_expired(5.0):  # 5 second timeout
				return "failed"
		"avoid_threat":
			# Check if we're far enough from all threats
			if perception_data.immediate_threats.size() == 0:
				return "completed"
		_:
			# Unknown command type, consider it completed after 1 second
			if current_command.is_expired(1.0):
				return "completed"
	
	return "running"

func _command_completed():
	var completed_command = current_command
	current_command = null
	completed_actions.append({"command": completed_command, "result": "success"})
	action_completed.emit(completed_command)
	state_machine.change_state("idle")

func _command_failed():
	var failed_command = current_command
	current_command = null
	completed_actions.append({"command": failed_command, "result": "failed"})
	# Report failure to strategic brain
	var status = TacticalStatus.new()
	status.current_state = "failed"
	status_update.emit(status)
	state_machine.change_state("idle")

func _update_status():
	# Send status to strategic brain
	var status = TacticalStatus.new()
	status.current_state = current_state
	status.position = npc_owner.global_position
	status.health = npc_owner.get("health") if npc_owner.has_method("get") else 100
	
	status_update.emit(status)

# Public methods for other systems
func receive_command(command: StrategicCommand):
	command_queue.append(command)

func get_current_perception() -> PerceptionData:
	return perception_data

func is_busy() -> bool:
	return current_command != null

func get_completed_actions() -> Array:
	var actions = completed_actions.duplicate()
	completed_actions.clear()  # Clear the list after returning
	return actions

# Helper methods
func _calculate_safe_position(threat) -> Vector3:
	# Simple implementation - move away from threat
	var threat_position = threat.global_position
	var escape_direction = (npc_owner.global_position - threat_position).normalized()
	return npc_owner.global_position + escape_direction * 10.0  # 10 units away

func _start_exploration(target: Vector3):
	movement_controller.move_to(target)

func _execute_avoidance(safe_pos: Vector3):
	movement_controller.move_to(safe_pos)

func _start_gathering(target: Vector3):
	movement_controller.move_to(target)
	# Add gathering logic later
