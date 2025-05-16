class_name BrainSynchronizer
extends Node

var strategic_brain: StrategicBrain
var tactical_brain: TacticalBrain

var sync_interval: float = 0.1  # 10 Hz sync rate
var last_sync_time: float = 0.0

# Sync statistics for debugging
var sync_count: int = 0
var failed_syncs: int = 0

func _ready():
	print("BrainSynchronizer initialized")

func _process(delta):
	if Time.get_ticks_usec() - last_sync_time >= sync_interval:
		_perform_sync()
		last_sync_time = Time.get_ticks_usec()

func _perform_sync():
	if not strategic_brain or not tactical_brain:
		failed_syncs += 1
		return
	
	# Update strategic brain with tactical info
	if tactical_brain.perception_data:
		strategic_brain.world_knowledge.update_from_perception(tactical_brain.perception_data)
	
	# Check if tactical brain has completed any actions
	var completed_actions = tactical_brain.get_completed_actions()
	for action in completed_actions:
		strategic_brain.memory.record_action_result(action)
	
	sync_count += 1

func _on_strategic_command(command: StrategicCommand):
	# Forward strategic commands to tactical brain
	if tactical_brain:
		tactical_brain.receive_command(command)
	else:
		push_warning("Tactical brain not available for command: " + command.type)

func _on_tactical_status(status: TacticalStatus):
	# Update strategic brain with tactical status
	if strategic_brain:
		strategic_brain.world_knowledge.update_from_status(status)

# Debug info
func get_sync_stats() -> Dictionary:
	return {
		"sync_count": sync_count,
		"failed_syncs": failed_syncs,
		"success_rate": float(sync_count) / max(1, sync_count + failed_syncs) * 100
	}
