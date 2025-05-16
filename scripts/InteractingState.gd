extends Node
class_name InteractingState

var state_machine: NPCStateMachine
var npc_controller: NPCController
var interaction_time: float = 0.0
var interaction_duration: float = 3.0  # Spend 3 seconds at POI

func enter_state():
	# Check if npc_controller and npc_data are valid
	if not npc_controller or not npc_controller.npc_data:
		push_error("NPCController or NPCData is null in InteractingState!")
		return
	
	print("NPC ", npc_controller.npc_data.npc_name, " entering interacting state")
	interaction_time = 0.0
	
	# Satisfy needs at current POI
	satisfy_needs_at_poi()

func exit_state():
	pass

func process_state(delta: float):
	if not npc_controller or not npc_controller.npc_data:
		return
	
	interaction_time += delta
	
	if interaction_time >= interaction_duration:
		state_machine.change_state("idle")

func satisfy_needs_at_poi():
	if not npc_controller or not npc_controller.npc_data:
		return
	
	# Simple need satisfaction - would be more complex in full implementation
	var npc_data = npc_controller.npc_data
	var urgent_need = npc_data.get_most_urgent_need()
	
	match urgent_need:
		"hunger":
			npc_data.needs.hunger = min(1.0, npc_data.needs.hunger + 0.5)
		"safety":
			npc_data.needs.safety = min(1.0, npc_data.needs.safety + 0.3)
		"energy":
			npc_data.needs.energy = min(1.0, npc_data.needs.energy + 0.7)
	
	print("NPC ", npc_data.npc_name, " satisfied ", urgent_need, " need")
