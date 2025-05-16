extends Node
class_name NPCStateMachine

var states: Dictionary = {}
var current_state: Node
var npc_controller: NPCController
var is_initialized: bool = false

func _ready():
	npc_controller = get_parent()
	
	# Initialize states but don't start yet
	for child in get_children():
		if child.has_method("enter_state"):
			states[child.name.to_lower().replace("state", "")] = child
			child.state_machine = self
			child.npc_controller = npc_controller
	
	is_initialized = true

func initialize():
	# Start with idle state only after everything is ready
	if is_initialized:
		change_state("idle")
		
func change_state(new_state_name: String):
	if not is_initialized:
		push_error("StateMachine not initialized yet!")
		return
	
	if current_state:
		current_state.exit_state()
	
	var new_state = states.get(new_state_name)
	if new_state:
		current_state = new_state
		current_state.enter_state()
		if npc_controller.npc_data:
			npc_controller.npc_data.current_state = new_state_name
			npc_controller.npc_data.last_state_change = Time.get_unix_time_from_system()

func process_state(delta: float):
	if is_initialized and current_state:
		current_state.process_state(delta)
