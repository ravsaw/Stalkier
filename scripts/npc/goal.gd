extends RefCounted

class_name Goal
var type: int
var priority: float = 50.0
var target_poi: POI = null
var completed: bool = false

func start(npc: NPC):
	pass

func execute(npc: NPC, delta: float):
	pass

func is_valid() -> bool:
	return not completed

func is_completed() -> bool:
	return completed

func interrupt():
	pass
