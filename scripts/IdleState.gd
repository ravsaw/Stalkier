extends Node
class_name IdleState

var state_machine: NPCStateMachine
var npc_controller: NPCController
var idle_time: float = 0.0
var decision_interval: float = 2.0  # Check for new goals every 2 seconds

func enter_state():
	# Check if npc_controller and npc_data are valid
	if not npc_controller or not npc_controller.npc_data:
		push_error("NPCController or NPCData is null in IdleState!")
		return
	
	print("NPC ", npc_controller.npc_data.npc_name, " entering idle state")
	idle_time = 0.0

func exit_state():
	pass

func process_state(delta: float):
	if not npc_controller or not npc_controller.npc_data:
		return
	
	idle_time += delta
	
	if idle_time >= decision_interval:
		idle_time = 0.0
		make_decision()

func make_decision():
	if not npc_controller or not npc_controller.npc_data:
		return
	
	# Check if needs require action
	var urgent_need = npc_controller.npc_data.get_most_urgent_need()
	var urgency = npc_controller.npc_data.get_need_urgency(urgent_need)
	
	# If need is urgent enough, find a POI to address it
	if urgency > 0.5:  # Need is below 50% satisfaction
		var target_poi = npc_controller.select_target_poi_based_on_needs()
		if target_poi != "":
			npc_controller.move_to_poi(target_poi)
