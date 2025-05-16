class_name WorldKnowledge
extends Node

var known_locations: Dictionary = {}
var known_npcs: Dictionary = {}
var faction_relationships: Dictionary = {}
var resource_sites: Array = []
var danger_zones: Array = []

func update_from_perception(perception: PerceptionData):
	if not perception:
		return
	
	# Update known NPC positions
	for npc in perception.visible_npcs:
		known_npcs[npc.get_instance_id()] = {
			"position": npc.global_position,
			"last_seen": Time.get_ticks_usec(),
			"reference": npc
		}
	
	# Add new obstacles to known locations
	for obstacle in perception.obstacles:
		var key = str(obstacle.position.round())
		known_locations[key] = {
			"type": "obstacle",
			"position": obstacle.position,
			"discovered": Time.get_ticks_usec()
		}

func update_from_tactical(status: TacticalStatus):
	# Update our understanding of the world based on tactical feedback
	pass

func update_from_status(status: TacticalStatus):
	# Called by synchronizer to update world knowledge
	pass

func update_world_state():
	# Periodic updates of world knowledge
	_decay_old_information()
	_update_faction_status()

func _decay_old_information():
	# Remove old NPC sightings
	var current_time = Time.get_ticks_usec()
	for npc_id in known_npcs.keys():
		if current_time - known_npcs[npc_id].last_seen > 30.0:  # 30 seconds old
			known_npcs.erase(npc_id)

func _update_faction_status():
	# Update faction relationship knowledge
	pass

func get_nearest_known_npc(position: Vector3) -> Dictionary:
	var nearest = {}
	var min_distance = INF
	
	for npc_data in known_npcs.values():
		var distance = position.distance_to(npc_data.position)
		if distance < min_distance:
			min_distance = distance
			nearest = npc_data
	
	return nearest

func get_safe_areas_near(position: Vector3, radius: float) -> Array:
	# Return areas without known dangers
	var safe_areas = []
	# Simple implementation - check if area has no recent threats
	# This would be expanded based on actual danger mapping
	return safe_areas
