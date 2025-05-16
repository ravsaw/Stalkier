class_name PerceptionSystem
extends Node

var npc_owner: CharacterBody3D
var perception_data: PerceptionData

@export var view_range: float = 20.0
@export var view_angle: float = 90.0  # degrees
@export var update_frequency: float = 10.0  # Hz

var space_state: PhysicsDirectSpaceState3D
var vision_ray: PhysicsRayQueryParameters3D
var last_update: float = 0.0

func _ready():
	perception_data = PerceptionData.new()
	if npc_owner:
		space_state = npc_owner.get_world_3d().direct_space_state

func scan_environment() -> PerceptionData:
	var current_time = Time.get_ticks_usec()
	if current_time - last_update < 1.0 / update_frequency:
		return perception_data
	
	last_update = current_time
	perception_data.clear()
	
	_scan_for_npcs()
	_scan_for_obstacles()
	_detect_threats()
	
	return perception_data

func _scan_for_npcs():
	if not npc_owner or not space_state:
		return
	
	# Use area overlap for efficiency
	var area_query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = view_range
	area_query.shape = sphere
	area_query.transform.origin = npc_owner.global_position
	area_query.collision_mask = 1  # Assuming NPCs are on layer 1
	
	var results = space_state.intersect_shape(area_query)
	
	for result in results:
		var collider = result.collider
		if collider and collider != npc_owner and collider.has_method("is_npc"):
			if _is_in_view_angle(collider.global_position):
				perception_data.add_visible_npc(collider)

func _scan_for_obstacles():
	# Simple 8-direction raycast for obstacles
	var directions = [
		Vector3.FORWARD, Vector3.BACK,
		Vector3.LEFT, Vector3.RIGHT,
		Vector3.FORWARD + Vector3.LEFT, Vector3.FORWARD + Vector3.RIGHT,
		Vector3.BACK + Vector3.LEFT, Vector3.BACK + Vector3.RIGHT
	]
	
	for direction in directions:
		var world_dir = npc_owner.global_transform.basis * direction
		var from = npc_owner.global_position + Vector3.UP * 0.5  # Start from chest height
		var to = from + world_dir * view_range
		
		var query = PhysicsRayQueryParameters3D.create(from, to)
		query.exclude = [npc_owner]  # Don't hit self
		
		var result = space_state.intersect_ray(query)
		if result:
			perception_data.add_obstacle(result.position, Vector3.ONE)  # Simple 1x1x1 obstacle

func _detect_threats():
	# For now, just check if any visible NPC is an enemy
	for npc in perception_data.visible_npcs:
		if npc.has_method("get_faction") and npc.get_faction() != npc_owner.get_faction():
			if npc.global_position.distance_to(npc_owner.global_position) < 10.0:
				perception_data.immediate_threats.append(npc)

func _is_in_view_angle(target_pos: Vector3) -> bool:
	var to_target = (target_pos - npc_owner.global_position).normalized()
	var forward = -npc_owner.global_transform.basis.z
	var angle = rad_to_deg(forward.angle_to(to_target))
	return angle <= view_angle / 2.0
