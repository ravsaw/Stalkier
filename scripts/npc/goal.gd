# scripts/npc/goal.gd
extends RefCounted

class_name Goal
var type: int
var priority: float = 50.0
var target_poi: POI = null
var target_npc: NPC = null
var completed: bool = false
var abandoned: bool = false

func start(npc: NPC):
	pass

func execute(npc: NPC, delta: float):
	pass

func is_valid() -> bool:
	return not completed and not abandoned

func is_completed() -> bool:
	return completed

func interrupt():
	# Called when goal is interrupted by higher priority goal
	pass

func abandon():
	# Called when goal cannot be completed
	abandoned = true

func handle_navigation_stuck():
	# Called when NPC gets stuck while navigating
	# Default behavior - abandon the goal
	abandon()

func get_progress() -> float:
	# Return progress as 0.0 to 1.0
	if completed:
		return 1.0
	elif abandoned:
		return 0.0
	else:
		return 0.5  # Override in subclasses for better progress tracking

func get_description() -> String:
	# Return human-readable description of the goal
	return "Goal: " + str(type)

func can_be_shared_with_group() -> bool:
	# Whether this goal can be adopted by group members
	return false

func estimate_duration() -> float:
	# Estimated time to complete in seconds
	return 60.0  # Default 1 minute

func get_required_resources() -> Dictionary:
	# Resources needed to complete the goal
	return {}

func get_risk_level() -> float:
	# Risk assessment 0.0 (safe) to 1.0 (very dangerous)
	return 0.1
