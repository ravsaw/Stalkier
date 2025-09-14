# scripts/world/area.gd
class_name Area
extends RefCounted

# === IDENTIFICATION ===
var area_id: String
var display_name: String
var area_type: int = AreaType.STANDARD

# === SPATIAL PROPERTIES ===
var world_position: Vector2  # Position in global 2D world coordinates
var bounds: Rect2           # Area boundaries in world coordinates
var elevation: float = 0.0  # Average elevation for 3D generation

# === AREA CHARACTERISTICS ===
var terrain_type: int = TerrainType.PLAINS
var climate: int = Climate.TEMPERATE
var danger_level: int = 1  # 1-10 scale
var resource_richness: float = 1.0

# === LOADING STATE ===
var is_loaded_2d: bool = false
var is_loaded_3d: bool = false
var last_accessed: float = 0.0
var npc_count: int = 0

# === NAVIGATION ===
var navigation_mesh_2d: NavigationPolygon = null
var navigation_mesh_3d: NavigationMesh = null
var transition_points: Array[TransitionPoint] = []

# === AREA CONTENT ===
var poi_ids: Array[String] = []  # POIs in this area
var spawn_points: Array[Vector2] = []  # Valid spawn locations
var patrol_routes: Array[Array] = []  # Predefined patrol paths

# === ENVIRONMENTAL FACTORS ===
var weather_modifier: float = 1.0
var visibility_modifier: float = 1.0
var sound_dampening: float = 1.0

enum AreaType {
	STANDARD,      # Regular gameplay area
	SAFE_ZONE,     # No combat allowed
	DANGER_ZONE,   # High-risk area
	TRANSITION,    # Area boundary/loading zone
	SETTLEMENT,    # Major population center
	WILDERNESS     # Remote area
}

enum TerrainType {
	PLAINS,
	FOREST,
	MOUNTAINS,
	SWAMP,
	DESERT,
	URBAN,
	INDUSTRIAL,
	UNDERGROUND
}

enum Climate {
	TEMPERATE,
	COLD,
	HOT,
	WET,
	DRY,
	TOXIC
}

func _init():
	last_accessed = Time.get_unix_time_from_system()

func setup_basic_area(id: String, pos: Vector2, name: String):
	"""Set up basic area properties"""
	area_id = id
	world_position = pos
	display_name = name
	bounds = Rect2(pos - Vector2(500, 500), Vector2(1000, 1000))

func add_poi(poi_id: String):
	"""Add a POI to this area"""
	if poi_id not in poi_ids:
		poi_ids.append(poi_id)

func remove_poi(poi_id: String):
	"""Remove a POI from this area"""
	poi_ids.erase(poi_id)

func add_spawn_point(position: Vector2):
	"""Add a valid spawn point"""
	spawn_points.append(position)

func get_random_spawn_point() -> Vector2:
	"""Get a random spawn point within the area"""
	if spawn_points.is_empty():
		# Generate default spawn points
		generate_default_spawn_points()
	
	if spawn_points.is_empty():
		return world_position  # Fallback to center
	
	return spawn_points[randi() % spawn_points.size()]

func generate_default_spawn_points():
	"""Generate default spawn points based on area properties"""
	var points_count = 5
	var spawn_radius = 300.0
	
	for i in range(points_count):
		var angle = (TAU / points_count) * i
		var distance = randf_range(spawn_radius * 0.5, spawn_radius)
		var spawn_pos = world_position + Vector2.RIGHT.rotated(angle) * distance
		
		# Check if spawn point is within bounds
		if bounds.has_point(spawn_pos):
			spawn_points.append(spawn_pos)

func add_patrol_route(waypoints: Array[Vector2]):
	"""Add a patrol route to this area"""
	patrol_routes.append(waypoints)

func get_patrol_route(index: int) -> Array:
	"""Get a specific patrol route"""
	if index >= 0 and index < patrol_routes.size():
		return patrol_routes[index]
	return []

func get_random_patrol_route() -> Array:
	"""Get a random patrol route"""
	if patrol_routes.is_empty():
		generate_default_patrol_routes()
	
	if patrol_routes.is_empty():
		return []
	
	return patrol_routes[randi() % patrol_routes.size()]

func generate_default_patrol_routes():
	"""Generate default patrol routes for this area"""
	# Simple circular patrol around area center
	var waypoints: Array[Vector2] = []
	var patrol_radius = 200.0
	var waypoint_count = 6
	
	for i in range(waypoint_count):
		var angle = (TAU / waypoint_count) * i
		var waypoint = world_position + Vector2.RIGHT.rotated(angle) * patrol_radius
		waypoints.append(waypoint)
	
	patrol_routes.append(waypoints)
	
	# Add a second route closer to the center
	waypoints = []
	patrol_radius = 100.0
	
	for i in range(waypoint_count):
		var angle = (TAU / waypoint_count) * i
		var waypoint = world_position + Vector2.RIGHT.rotated(angle) * patrol_radius
		waypoints.append(waypoint)
	
	patrol_routes.append(waypoints)

func is_position_in_area(position: Vector2) -> bool:
	"""Check if a position is within this area"""
	return bounds.has_point(position)

func get_distance_to_position(position: Vector2) -> float:
	"""Get distance from area center to position"""
	return world_position.distance_to(position)

func get_local_position(world_pos: Vector2) -> Vector2:
	"""Convert world position to local area coordinates"""
	return world_pos - world_position

func get_world_position(local_pos: Vector2) -> Vector2:
	"""Convert local area coordinates to world position"""
	return world_position + local_pos

func update_npc_count(new_count: int):
	"""Update the number of NPCs in this area"""
	npc_count = new_count
	last_accessed = Time.get_unix_time_from_system()

func get_spawn_probability() -> float:
	"""Get spawn probability modifier based on area properties"""
	var base_probability = 1.0
	
	# Area type modifiers
	match area_type:
		AreaType.SAFE_ZONE:
			base_probability *= 1.5  # More likely to spawn in safe areas
		AreaType.DANGER_ZONE:
			base_probability *= 0.5  # Less likely to spawn in danger zones
		AreaType.SETTLEMENT:
			base_probability *= 2.0  # High spawn rate in settlements
		AreaType.WILDERNESS:
			base_probability *= 0.3  # Low spawn rate in wilderness
	
	# Population density modifier
	if npc_count > 20:
		base_probability *= 0.5  # Reduce spawning in crowded areas
	elif npc_count < 5:
		base_probability *= 1.5  # Increase spawning in empty areas
	
	return base_probability

func get_movement_speed_modifier() -> float:
	"""Get movement speed modifier for this area"""
	var modifier = 1.0
	
	match terrain_type:
		TerrainType.SWAMP:
			modifier *= 0.7
		TerrainType.MOUNTAINS:
			modifier *= 0.8
		TerrainType.DESERT:
			modifier *= 0.9
		TerrainType.URBAN:
			modifier *= 1.1
		TerrainType.PLAINS:
			modifier *= 1.2
	
	return modifier

func get_visibility_range() -> float:
	"""Get visibility range in this area"""
	var base_range = 100.0
	
	match terrain_type:
		TerrainType.FOREST:
			base_range *= 0.6
		TerrainType.SWAMP:
			base_range *= 0.7
		TerrainType.MOUNTAINS:
			base_range *= 1.5
		TerrainType.PLAINS:
			base_range *= 2.0
		TerrainType.DESERT:
			base_range *= 1.8
		TerrainType.URBAN:
			base_range *= 0.8
	
	return base_range * visibility_modifier

func get_combat_modifier() -> float:
	"""Get combat effectiveness modifier for this area"""
	var modifier = 1.0
	
	# Terrain effects on combat
	match terrain_type:
		TerrainType.URBAN:
			modifier *= 1.1  # Urban combat advantages
		TerrainType.FOREST:
			modifier *= 0.9  # Reduced effectiveness in forests
		TerrainType.SWAMP:
			modifier *= 0.8  # Difficult combat in swamps
	
	# Climate effects
	match climate:
		Climate.TOXIC:
			modifier *= 0.7  # Toxic environment reduces effectiveness
		Climate.COLD:
			modifier *= 0.9  # Cold reduces performance
		Climate.HOT:
			modifier *= 0.9  # Heat reduces performance
	
	return modifier

func should_preload() -> bool:
	"""Determine if this area should be preloaded"""
	# Preload if recently accessed or has many NPCs
	var time_since_access = Time.get_unix_time_from_system() - last_accessed
	
	if time_since_access < 300:  # 5 minutes
		return true
	
	if npc_count > 10:
		return true
	
	# Preload important areas
	if area_type == AreaType.SETTLEMENT or area_type == AreaType.SAFE_ZONE:
		return true
	
	return false

func get_recommended_group_size() -> int:
	"""Get recommended group size for this area"""
	var base_size = 4
	
	match danger_level:
		1, 2:
			return base_size - 1  # Smaller groups in safe areas
		3, 4, 5:
			return base_size      # Standard groups
		6, 7, 8:
			return base_size + 2  # Larger groups in dangerous areas
		9, 10:
			return base_size + 4  # Very large groups in extreme danger
	
	return base_size

func to_dict() -> Dictionary:
	"""Convert area to dictionary for serialization"""
	return {
		"area_id": area_id,
		"display_name": display_name,
		"area_type": area_type,
		"world_position": {"x": world_position.x, "y": world_position.y},
		"bounds": {"x": bounds.position.x, "y": bounds.position.y, "w": bounds.size.x, "h": bounds.size.y},
		"terrain_type": terrain_type,
		"climate": climate,
		"danger_level": danger_level,
		"resource_richness": resource_richness,
		"npc_count": npc_count,
		"poi_count": poi_ids.size(),
		"spawn_points_count": spawn_points.size(),
		"patrol_routes_count": patrol_routes.size()
	}

func from_dict(data: Dictionary):
	"""Load area from dictionary"""
	area_id = data.get("area_id", "")
	display_name = data.get("display_name", "")
	area_type = data.get("area_type", AreaType.STANDARD)
	
	var pos_data = data.get("world_position", {"x": 0, "y": 0})
	world_position = Vector2(pos_data.x, pos_data.y)
	
	var bounds_data = data.get("bounds", {"x": 0, "y": 0, "w": 1000, "h": 1000})
	bounds = Rect2(bounds_data.x, bounds_data.y, bounds_data.w, bounds_data.h)
	
	terrain_type = data.get("terrain_type", TerrainType.PLAINS)
	climate = data.get("climate", Climate.TEMPERATE)
	danger_level = data.get("danger_level", 1)
	resource_richness = data.get("resource_richness", 1.0)
	npc_count = data.get("npc_count", 0)