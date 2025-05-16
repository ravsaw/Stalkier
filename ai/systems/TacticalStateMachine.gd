class_name TacticalStateMachine
extends Node

var npc_owner: CharacterBody3D
var current_state: String = "idle"
var previous_state: String = ""
var state_start_time: float

# State machine logic
var states: Dictionary = {
	"idle": {"can_transition_to": ["moving", "alert", "combat"]},
	"moving": {"can_transition_to": ["idle", "alert", "combat"]},
	"alert": {"can_transition_to": ["idle", "moving", "combat"]},
	"combat": {"can_transition_to": ["idle", "alert", "fleeing"]},
	"fleeing": {"can_transition_to": ["idle", "moving", "hiding"]},
	"hiding": {"can_transition_to": ["idle", "moving", "alert"]}
}

func _ready():
	change_state("idle")

func change_state(new_state: String):
	if new_state == current_state:
		return
	
	# Check if transition is allowed
	if not _can_transition_to(new_state):
		print("Invalid state transition from ", current_state, " to ", new_state)
		return
	
	# Exit current state
	_exit_state(current_state)
	
	# Update state
	previous_state = current_state
	current_state = new_state
	state_start_time = Time.get_ticks_usec()
	
	# Enter new state
	_enter_state(new_state)
	
	print(npc_owner.name, " changed state: ", previous_state, " -> ", current_state)

func _can_transition_to(new_state: String) -> bool:
	if not current_state in states:
		return true  # If current state isn't defined, allow transition
	
	var allowed_transitions = states[current_state].get("can_transition_to", [])
	return new_state in allowed_transitions

func _enter_state(state: String):
	match state:
		"idle":
			_enter_idle_state()
		"moving":
			_enter_moving_state()
		"alert":
			_enter_alert_state()
		"combat":
			_enter_combat_state()
		"fleeing":
			_enter_fleeing_state()
		"hiding":
			_enter_hiding_state()

func _exit_state(state: String):
	match state:
		"idle":
			_exit_idle_state()
		"moving":
			_exit_moving_state()
		"alert":
			_exit_alert_state()
		"combat":
			_exit_combat_state()
		"fleeing":
			_exit_fleeing_state()
		"hiding":
			_exit_hiding_state()

# State behaviors
func _enter_idle_state():
	pass

func _exit_idle_state():
	pass

func _enter_moving_state():
	pass

func _exit_moving_state():
	pass

func _enter_alert_state():
	pass

func _exit_alert_state():
	pass

func _enter_combat_state():
	pass

func _exit_combat_state():
	pass

func _enter_fleeing_state():
	pass

func _exit_fleeing_state():
	pass

func _enter_hiding_state():
	pass

func _exit_hiding_state():
	pass

func get_state_age() -> float:
	return Time.get_ticks_usec() - state_start_time

func is_in_state(state: String) -> bool:
	return current_state == state
