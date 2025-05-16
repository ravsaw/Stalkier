class_name ActionExecutor
extends Node

var npc_owner: CharacterBody3D
var current_action: TacticalAction
var action_start_time: float

enum Result {
	RUNNING,
	COMPLETED,
	FAILED
}

func _ready():
	pass

func start_action(action: TacticalAction):
	current_action = action
	action_start_time = Time.get_ticks_usec()

func update_current_action(delta: float) -> Result:
	if not current_action:
		return Result.COMPLETED
	
	# Check if action timed out
	if current_action.timeout > 0 and Time.get_ticks_usec() - action_start_time > current_action.timeout:
		return Result.FAILED
	
	# Execute action based on type
	match current_action.type:
		"move":
			return _execute_move_action(delta)
		"wait":
			return _execute_wait_action(delta)
		"look":
			return _execute_look_action(delta)
		_:
			print("Unknown action type: ", current_action.type)
			return Result.FAILED

func _execute_move_action(delta: float) -> Result:
	if current_action.target_position.distance_to(npc_owner.global_position) < 0.5:
		return Result.COMPLETED
	return Result.RUNNING

func _execute_wait_action(delta: float) -> Result:
	if Time.get_ticks_usec() - action_start_time > current_action.duration:
		return Result.COMPLETED
	return Result.RUNNING

func _execute_look_action(delta: float) -> Result:
	# Simple look action - rotate toward target
	var look_dir = (current_action.target_position - npc_owner.global_position).normalized()
	var target_transform = npc_owner.global_transform.looking_at(npc_owner.global_position + look_dir, Vector3.UP)
	npc_owner.global_transform = npc_owner.global_transform.interpolate_with(target_transform, 2.0 * delta)
	
	# Consider completed when close enough to desired rotation
	var angle_diff = rad_to_deg((-npc_owner.global_transform.basis.z).angle_to(look_dir))
	if angle_diff < 5.0:  # Within 5 degrees
		return Result.COMPLETED
	return Result.RUNNING

class TacticalAction:
	var type: String
	var target_position: Vector3
	var duration: float = 0.0
	var timeout: float = 0.0
	var parameters: Dictionary = {}
