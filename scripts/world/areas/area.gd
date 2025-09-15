# scripts/world/areas/area.gd
extends RefCounted
class_name Area

## Represents a world area that can exist in both 2D and 3D space
## Areas are dynamically loaded/unloaded based on player proximity and memory constraints

# === AREA IDENTIFICATION ===
var area_id: String = ""
var area_name: String = ""

# === AREA TYPE ===
enum AreaType { 
	MIXED,      # Supports both 2D and 3D modes
	MODE_2D_ONLY,    # Only accessible in 2D mode
	MODE_3D_ONLY     # Only accessible in 3D mode
}
var area_type: AreaType = AreaType.MIXED

# === SPATIAL BOUNDS ===
var bounds_2d: Rect2 = Rect2()
var bounds_3d: AABB = AABB()

# === AREA STATE ===
var is_loaded: bool = false
var is_active: bool = false
var last_access_time: float = 0.0

# === TERRAIN AND ENVIRONMENT ===
enum TerrainType { 
	PLAINS, FOREST, URBAN, INDUSTRIAL, 
	ANOMALY_ZONE, UNDERGROUND, SWAMP 
}
var terrain_type: TerrainType = TerrainType.PLAINS
var weather_factor: float = 1.0
var radiation_level: float = 0.0
var temperature: float = 20.0  # Celsius

# === RESOURCES ===
var scene_2d: PackedScene = null
var scene_3d: PackedScene = null
var navmesh_2d: NavigationPolygon = null
var navmesh_3d: NavigationMesh = null

# === POI REFERENCES ===
var pois: Array[POI] = []
var poi_ids: Array[String] = []

# === NPC SPAWN POINTS ===
var spawn_points_2d: Array[Vector2] = []
var spawn_points_3d: Array[Vector3] = []
var max_npc_count: int = 50

# === TRANSITION POINTS ===
var transition_points: Array[TransitionPoint] = []

# === AREA CONNECTIONS ===
var connected_areas: Dictionary = {}  # direction -> area_id
enum Direction { NORTH, SOUTH, EAST, WEST, UP, DOWN }

# === PERFORMANCE ===
var last_update_time: float = 0.0
var update_frequency: float = 1.0  # Update every second when not active

func _init():
	last_access_time = Time.get_time_dict_from_system()["unix"]

func setup(id: String, type: AreaType, bounds_2d: Rect2, bounds_3d: AABB = AABB()):
	area_id = id
	area_type = type
	self.bounds_2d = bounds_2d
	
	if bounds_3d == AABB():
		# Auto-generate 3D bounds from 2D bounds
		var min_pos = Vector3(bounds_2d.position.x, -10, bounds_2d.position.y)
		var size = Vector3(bounds_2d.size.x, 50, bounds_2d.size.y)
		self.bounds_3d = AABB(min_pos, size)
	else:
		self.bounds_3d = bounds_3d

func load_resources():
	if is_loaded:
		return
	
	print("Area: Loading resources for area ", area_id)
	
	# Load terrain data
	load_terrain_data()
	
	# Load navigation meshes
	load_navigation_data()
	
	# Load POI data
	load_poi_data()
	
	# Generate spawn points
	generate_spawn_points()
	
	# Setup transition points
	setup_transition_points()
	
	is_loaded = true
	last_access_time = Time.get_time_dict_from_system()["unix"]

func unload_resources():
	if not is_loaded:
		return
	
	print("Area: Unloading resources for area ", area_id)
	
	# Clear scene references
	scene_2d = null
	scene_3d = null
	navmesh_2d = null
	navmesh_3d = null
	
	# Clear POI references
	pois.clear()
	
	# Clear spawn points
	spawn_points_2d.clear()
	spawn_points_3d.clear()
	
	is_loaded = false

func load_terrain_data():
	# This would load actual terrain data from files
	# For now, we'll set some default values based on area_id
	
	if "forest" in area_id.to_lower():
		terrain_type = TerrainType.FOREST
		weather_factor = 0.8
	elif "urban" in area_id.to_lower() or "city" in area_id.to_lower():
		terrain_type = TerrainType.URBAN
		weather_factor = 1.2
		temperature = 25.0
	elif "industrial" in area_id.to_lower():
		terrain_type = TerrainType.INDUSTRIAL
		radiation_level = 0.1
		temperature = 30.0
	elif "anomaly" in area_id.to_lower():
		terrain_type = TerrainType.ANOMALY_ZONE
		radiation_level = 0.5
		weather_factor = 1.5
	else:
		terrain_type = TerrainType.PLAINS
		weather_factor = 1.0

func load_navigation_data():
	# Create basic navigation polygon for 2D
	navmesh_2d = NavigationPolygon.new()
	
	# Create boundary outline
	var outline = PackedVector2Array([
		bounds_2d.position,
		Vector2(bounds_2d.position.x + bounds_2d.size.x, bounds_2d.position.y),
		bounds_2d.position + bounds_2d.size,
		Vector2(bounds_2d.position.x, bounds_2d.position.y + bounds_2d.size.y)
	])
	
	navmesh_2d.add_outline(outline)
	
	# Add obstacles for POIs
	add_navigation_obstacles()
	
	# Build the polygons
	navmesh_2d.make_polygons_from_outlines()
	
	# For 3D navigation, we'd create a NavigationMesh
	# This is more complex and would typically be done with actual 3D geometry
	navmesh_3d = NavigationMesh.new()

func add_navigation_obstacles():
	# Add obstacles around POIs
	for poi_id in poi_ids:
		var poi = POIManager.get_poi(poi_id)
		if poi and bounds_2d.has_point(poi.position):
			add_poi_obstacle(poi)

func add_poi_obstacle(poi: POI):
	var obstacle_size = get_poi_obstacle_size(poi.poi_type)
	var half_size = obstacle_size * 0.5
	
	var obstacle_outline = PackedVector2Array([
		poi.position + Vector2(-half_size, -half_size),
		poi.position + Vector2(-half_size, half_size),
		poi.position + Vector2(half_size, half_size),
		poi.position + Vector2(half_size, -half_size)
	])
	
	navmesh_2d.add_outline(obstacle_outline)

func get_poi_obstacle_size(poi_type: int) -> float:
	match poi_type:
		POI.POIType.MAIN_BASE:
			return 20.0
		POI.POIType.MILITARY_POST:
			return 15.0
		POI.POIType.CIVILIAN_SETTLEMENT:
			return 18.0
		POI.POIType.ANOMALY_ZONE:
			return 25.0
		POI.POIType.TRADING_POST:
			return 12.0
		POI.POIType.SMALL_CAMP:
			return 8.0
		_:
			return 10.0

func load_poi_data():
	# Load POIs that belong to this area
	var all_pois = POIManager.get_all_pois()
	
	for poi in all_pois:
		if bounds_2d.has_point(poi.position):
			pois.append(poi)
			poi_ids.append(poi.poi_id)

func generate_spawn_points():
	# Generate spawn points for NPCs
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	# Generate 2D spawn points
	var num_spawn_points_2d = randi_range(5, 15)
	for i in range(num_spawn_points_2d):
		var attempts = 0
		var spawn_point: Vector2
		
		# Try to find valid spawn points away from POIs
		while attempts < 50:
			spawn_point = Vector2(
				rng.randf_range(bounds_2d.position.x + 20, bounds_2d.position.x + bounds_2d.size.x - 20),
				rng.randf_range(bounds_2d.position.y + 20, bounds_2d.position.y + bounds_2d.size.y - 20)
			)
			
			if is_spawn_point_valid(spawn_point):
				spawn_points_2d.append(spawn_point)
				break
			
			attempts += 1
	
	# Generate 3D spawn points based on 2D points
	for spawn_2d in spawn_points_2d:
		var spawn_3d = Vector3(spawn_2d.x, get_ground_height_at(spawn_2d), spawn_2d.y)
		spawn_points_3d.append(spawn_3d)

func is_spawn_point_valid(point: Vector2) -> bool:
	# Check if spawn point is far enough from POIs
	for poi in pois:
		if point.distance_to(poi.position) < 30.0:
			return false
	
	# Check if it's not too close to area edges
	var margin = 25.0
	var inner_bounds = Rect2(
		bounds_2d.position + Vector2(margin, margin),
		bounds_2d.size - Vector2(margin * 2, margin * 2)
	)
	
	return inner_bounds.has_point(point)

func get_ground_height_at(position_2d: Vector2) -> float:
	# This would query actual terrain height in a full implementation
	# For now, return a base height with some variation
	match terrain_type:
		TerrainType.PLAINS:
			return 0.0
		TerrainType.FOREST:
			return randf_range(-2.0, 3.0)
		TerrainType.URBAN:
			return randf_range(0.0, 1.0)
		TerrainType.UNDERGROUND:
			return -10.0
		_:
			return 0.0

func setup_transition_points():
	# Create transition points at area edges
	create_edge_transition_points()
	
	# Create special transition points for specific locations
	create_special_transition_points()

func create_edge_transition_points():
	# North edge
	var north_tp = TransitionPoint.new()
	north_tp.position_2d = Vector2(bounds_2d.get_center().x, bounds_2d.position.y)
	north_tp.position_3d = Vector3(north_tp.position_2d.x, get_ground_height_at(north_tp.position_2d), north_tp.position_2d.y)
	north_tp.from_mode = WorldManager.WorldMode.MODE_2D
	north_tp.to_mode = WorldManager.WorldMode.MODE_3D
	north_tp.trigger_radius = 20.0
	transition_points.append(north_tp)

func create_special_transition_points():
	# Create transition points near important POIs
	for poi in pois:
		if poi.poi_type == POI.POIType.MAIN_BASE or poi.poi_type == POI.POIType.MILITARY_POST:
			var tp = TransitionPoint.new()
			tp.position_2d = poi.position + Vector2(15, 0)  # Offset from POI
			tp.position_3d = Vector3(tp.position_2d.x, get_ground_height_at(tp.position_2d), tp.position_2d.y)
			tp.from_mode = WorldManager.WorldMode.MODE_2D
			tp.to_mode = WorldManager.WorldMode.MODE_3D
			tp.trigger_radius = 10.0
			transition_points.append(tp)

func update(delta: float):
	last_update_time += delta
	
	if last_update_time >= update_frequency:
		last_update_time = 0.0
		
		# Update area-specific systems
		update_environment(delta)
		update_poi_states(delta)

func update_environment(delta: float):
	# Update weather, radiation, temperature based on time and events
	# This is a simplified version
	
	match terrain_type:
		TerrainType.ANOMALY_ZONE:
			# Fluctuating radiation in anomaly zones
			radiation_level += sin(Time.get_time_dict_from_system()["unix"] * 0.1) * 0.1 * delta
			radiation_level = clamp(radiation_level, 0.0, 1.0)
		
		TerrainType.URBAN:
			# Urban heat island effect
			temperature = 20.0 + 5.0 * weather_factor

func update_poi_states(delta: float):
	# Update POI states if needed
	for poi in pois:
		poi.update_area_effects(self, delta)

func get_random_spawn_point_2d() -> Vector2:
	if spawn_points_2d.is_empty():
		generate_spawn_points()
	
	if spawn_points_2d.is_empty():
		return bounds_2d.get_center()
	
	return spawn_points_2d[randi() % spawn_points_2d.size()]

func get_random_spawn_point_3d() -> Vector3:
	if spawn_points_3d.is_empty():
		generate_spawn_points()
	
	if spawn_points_3d.is_empty():
		var center_2d = bounds_2d.get_center()
		return Vector3(center_2d.x, get_ground_height_at(center_2d), center_2d.y)
	
	return spawn_points_3d[randi() % spawn_points_3d.size()]

func add_connected_area(direction: Direction, area_id: String):
	connected_areas[direction] = area_id

func get_connected_area(direction: Direction) -> String:
	return connected_areas.get(direction, "")

func contains_point_2d(point: Vector2) -> bool:
	return bounds_2d.has_point(point)

func contains_point_3d(point: Vector3) -> bool:
	return bounds_3d.has_point(point)

func get_area_center_2d() -> Vector2:
	return bounds_2d.get_center()

func get_area_center_3d() -> Vector3:
	return bounds_3d.get_center()

func get_difficulty_factor() -> float:
	# Calculate area difficulty based on various factors
	var difficulty = 1.0
	
	# Terrain difficulty
	match terrain_type:
		TerrainType.ANOMALY_ZONE:
			difficulty += 2.0
		TerrainType.INDUSTRIAL:
			difficulty += 0.5
		TerrainType.URBAN:
			difficulty += 0.3
		TerrainType.UNDERGROUND:
			difficulty += 1.0
	
	# Radiation increases difficulty
	difficulty += radiation_level * 0.5
	
	# Weather factor
	difficulty *= weather_factor
	
	return difficulty

func get_area_info() -> Dictionary:
	return {
		"area_id": area_id,
		"area_name": area_name,
		"area_type": AreaType.keys()[area_type],
		"terrain_type": TerrainType.keys()[terrain_type],
		"bounds_2d": bounds_2d,
		"bounds_3d": bounds_3d,
		"is_loaded": is_loaded,
		"is_active": is_active,
		"poi_count": pois.size(),
		"spawn_points_2d": spawn_points_2d.size(),
		"spawn_points_3d": spawn_points_3d.size(),
		"difficulty_factor": get_difficulty_factor(),
		"radiation_level": radiation_level,
		"temperature": temperature
	}