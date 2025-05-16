class_name DualBrainSystem
extends Node

@export var npc_owner: CharacterBody3D
var strategic_brain: StrategicBrain
var tactical_brain: TacticalBrain
var brain_synchronizer: BrainSynchronizer
var debug_viewer: Node

func _ready():
	_initialize_brains()
	_setup_synchronization()
	_setup_debug_viewer()
	
	print("DualBrainSystem initialized for: ", npc_owner.name if npc_owner else "unknown")

func _initialize_brains():
	# Create strategic brain
	strategic_brain = StrategicBrain.new()
	strategic_brain.npc_owner = npc_owner
	strategic_brain.name = "StrategicBrain"
	add_child(strategic_brain)
	
	# Create tactical brain
	tactical_brain = TacticalBrain.new()
	tactical_brain.npc_owner = npc_owner
	tactical_brain.name = "TacticalBrain"
	add_child(tactical_brain)
	
	# Link them together
	strategic_brain.tactical_brain = tactical_brain
	tactical_brain.strategic_brain = strategic_brain

func _setup_synchronization():
	brain_synchronizer = BrainSynchronizer.new()
	brain_synchronizer.strategic_brain = strategic_brain
	brain_synchronizer.tactical_brain = tactical_brain
	add_child(brain_synchronizer)
	
	# Connect signals for communication
	strategic_brain.command_issued.connect(brain_synchronizer._on_strategic_command)
	tactical_brain.status_update.connect(brain_synchronizer._on_tactical_status)

func _setup_debug_viewer():
	# Only in debug builds
	if OS.is_debug_build():
		var debug_script = load("res://debug/BrainDebugViewer.gd")
		if debug_script:
			debug_viewer = debug_script.new()
			debug_viewer.brain_system = self
			add_child(debug_viewer)

# Public methods for testing
func add_exploration_goal(target: Vector3):
	var goal = StrategyGoal.new()
	goal.type = StrategyGoal.Type.EXPLORATION
	goal.priority = 0.8
	goal.target_location = target
	goal.description = "Explore specific location"
	strategic_brain.add_goal(goal)

func get_status() -> Dictionary:
	return {
		"strategic_goals": strategic_brain.goals.size(),
		"tactical_state": tactical_brain.current_state,
		"current_position": npc_owner.global_position if npc_owner else Vector3.ZERO,
		"sync_stats": brain_synchronizer.get_sync_stats()
	}
