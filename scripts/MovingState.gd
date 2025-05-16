extends Node
class_name MovingState

var state_machine: NPCStateMachine
var npc_controller: NPCController
var navigation_agent: NavigationAgent2D

func enter_state():
	# Check if npc_controller and npc_data are valid
	if not npc_controller or not npc_controller.npc_data:
		push_error("NPCController or NPCData is null in MovingState!")
		return
	
	print("NPC ", npc_controller.npc_data.npc_name, " entering moving state")
	navigation_agent = npc_controller.navigation_agent

func exit_state():
	pass

func process_state(delta: float):
	if not npc_controller or not npc_controller.npc_data or not navigation_agent:
		return
	
	if navigation_agent.is_navigation_finished():
		# Reached destination
		npc_controller.npc_data.current_poi = npc_controller.npc_data.target_poi
		npc_controller.npc_data.target_poi = ""
		state_machine.change_state("interacting")
		return
	
	# Move towards target
	var next_path_position = navigation_agent.get_next_path_position()
	var direction = (next_path_position - npc_controller.global_position).normalized()
	
	npc_controller.velocity = direction * npc_controller.npc_data.move_speed
	npc_controller.move_and_slide()
	
	# Update sprite direction
	if direction.x != 0 and npc_controller.sprite:
		npc_controller.sprite.scale.x = sign(direction.x)
