class_name PerceptionData
extends Resource

var visible_npcs: Array = []
var visible_items: Array = []
var nearby_anomalies: Array = []
var immediate_threats: Array = []
var safe_areas: Array = []
var obstacles: Array = []
var last_update_time: float

func _init():
	last_update_time = Time.get_ticks_usec()

func get_age() -> float:
	return Time.get_ticks_usec() - last_update_time

func add_visible_npc(npc: Node):
	if npc not in visible_npcs:
		visible_npcs.append(npc)

func add_obstacle(position: Vector3, size: Vector3):
	obstacles.append({"position": position, "size": size})

func clear():
	visible_npcs.clear()
	visible_items.clear()
	nearby_anomalies.clear()
	immediate_threats.clear()
	safe_areas.clear()
	obstacles.clear()
