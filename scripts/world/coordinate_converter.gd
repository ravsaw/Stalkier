# scripts/world/coordinate_converter.gd
class_name CoordinateConverter
extends RefCounted

# === COORDINATE SYSTEM CONSTANTS ===
const WORLD_SCALE: float = 1.0  # 1 unit 2D = 1 unit 3D
const DEFAULT_HEIGHT: float = 0.0  # Default Y coordinate for 2D->3D conversion
const AREA_SIZE: float = 1000.0  # Standard area size

# === COORDINATE CONVERSION ===
static func world_2d_to_local_3d(world_pos_2d: Vector2, area_center: Vector2) -> Vector3:
	"""Convert 2D world coordinates to 3D local coordinates within an area"""
	var local_2d = world_pos_2d - area_center
	return Vector3(local_2d.x * WORLD_SCALE, DEFAULT_HEIGHT, local_2d.y * WORLD_SCALE)

static func local_3d_to_world_2d(local_pos_3d: Vector3, area_center: Vector2) -> Vector2:
	"""Convert 3D local coordinates to 2D world coordinates"""
	var local_2d = Vector2(local_pos_3d.x / WORLD_SCALE, local_pos_3d.z / WORLD_SCALE)
	return area_center + local_2d

static func world_2d_to_world_3d(world_pos_2d: Vector2, height: float = DEFAULT_HEIGHT) -> Vector3:
	"""Convert 2D world coordinates directly to 3D world coordinates"""
	return Vector3(world_pos_2d.x * WORLD_SCALE, height, world_pos_2d.y * WORLD_SCALE)

static func world_3d_to_world_2d(world_pos_3d: Vector3) -> Vector2:
	"""Convert 3D world coordinates to 2D world coordinates"""
	return Vector2(world_pos_3d.x / WORLD_SCALE, world_pos_3d.z / WORLD_SCALE)

# === AREA COORDINATE CONVERSION ===
static func get_area_from_world_position(world_pos: Vector2, area_size: float = AREA_SIZE) -> Vector2:
	"""Get area coordinates from world position"""
	return Vector2(
		floor(world_pos.x / area_size),
		floor(world_pos.y / area_size)
	)

static func get_area_center_from_coordinates(area_coords: Vector2, area_size: float = AREA_SIZE) -> Vector2:
	"""Get world position of area center from area coordinates"""
	return Vector2(
		area_coords.x * area_size + area_size * 0.5,
		area_coords.y * area_size + area_size * 0.5
	)

static func get_local_position_in_area(world_pos: Vector2, area_center: Vector2) -> Vector2:
	"""Get local position within an area (relative to area center)"""
	return world_pos - area_center

static func get_world_position_from_local(local_pos: Vector2, area_center: Vector2) -> Vector2:
	"""Get world position from local area position"""
	return area_center + local_pos

# === DISTANCE CALCULATIONS ===
static func get_2d_distance(pos1: Vector2, pos2: Vector2) -> float:
	"""Get 2D distance between two positions"""
	return pos1.distance_to(pos2)

static func get_3d_distance(pos1: Vector3, pos2: Vector3) -> float:
	"""Get 3D distance between two positions"""
	return pos1.distance_to(pos2)

static func get_mixed_distance_2d_to_3d(pos_2d: Vector2, pos_3d: Vector3) -> float:
	"""Get distance between 2D and 3D positions (converts to same coordinate system)"""
	var pos_2d_as_3d = world_2d_to_world_3d(pos_2d)
	return pos_2d_as_3d.distance_to(pos_3d)

static func get_planar_distance_3d(pos1: Vector3, pos2: Vector3) -> float:
	"""Get 2D planar distance between 3D positions (ignoring Y)"""
	return Vector2(pos1.x, pos1.z).distance_to(Vector2(pos2.x, pos2.z))

# === DIRECTION AND ANGLE CONVERSION ===
static func direction_2d_to_3d(direction_2d: Vector2) -> Vector3:
	"""Convert 2D direction to 3D direction (Y=0)"""
	return Vector3(direction_2d.x, 0, direction_2d.y).normalized()

static func direction_3d_to_2d(direction_3d: Vector3) -> Vector2:
	"""Convert 3D direction to 2D direction (ignoring Y)"""
	return Vector2(direction_3d.x, direction_3d.z).normalized()

static func angle_2d_to_3d_rotation(angle_2d: float) -> Vector3:
	"""Convert 2D angle to 3D rotation (around Y axis)"""
	return Vector3(0, angle_2d, 0)

static func rotation_3d_to_2d_angle(rotation_3d: Vector3) -> float:
	"""Convert 3D rotation to 2D angle (Y axis rotation)"""
	return rotation_3d.y

# === BOUNDS AND AREA CHECKS ===
static func is_position_in_area_bounds(world_pos: Vector2, area_center: Vector2, area_size: float = AREA_SIZE) -> bool:
	"""Check if a world position is within area bounds"""
	var area_bounds = Rect2(
		area_center - Vector2(area_size * 0.5, area_size * 0.5),
		Vector2(area_size, area_size)
	)
	return area_bounds.has_point(world_pos)

static func clamp_position_to_area(world_pos: Vector2, area_center: Vector2, area_size: float = AREA_SIZE) -> Vector2:
	"""Clamp a position to stay within area bounds"""
	var half_size = area_size * 0.5
	var area_min = area_center - Vector2(half_size, half_size)
	var area_max = area_center + Vector2(half_size, half_size)
	
	return Vector2(
		clamp(world_pos.x, area_min.x, area_max.x),
		clamp(world_pos.y, area_min.y, area_max.y)
	)

static func get_area_boundary_position(world_pos: Vector2, area_center: Vector2, target_area_center: Vector2, area_size: float = AREA_SIZE) -> Vector2:
	"""Get position on area boundary towards target area"""
	var direction = (target_area_center - area_center).normalized()
	var half_size = area_size * 0.5
	
	# Find intersection with area boundary
	var boundary_x = area_center.x + (half_size * sign(direction.x))
	var boundary_y = area_center.y + (half_size * sign(direction.y))
	
	# Choose the boundary that's closer to the direction
	if abs(direction.x) > abs(direction.y):
		return Vector2(boundary_x, world_pos.y)
	else:
		return Vector2(world_pos.x, boundary_y)

# === PATH CONVERSION ===
static func convert_path_2d_to_3d(path_2d: PackedVector2Array, area_center: Vector2, height: float = DEFAULT_HEIGHT) -> PackedVector3Array:
	"""Convert a 2D path to 3D path"""
	var path_3d = PackedVector3Array()
	
	for point in path_2d:
		var local_3d = world_2d_to_local_3d(point, area_center)
		local_3d.y = height
		path_3d.append(local_3d)
	
	return path_3d

static func convert_path_3d_to_2d(path_3d: PackedVector3Array, area_center: Vector2) -> PackedVector2Array:
	"""Convert a 3D path to 2D path"""
	var path_2d = PackedVector2Array()
	
	for point in path_3d:
		var world_2d = local_3d_to_world_2d(point, area_center)
		path_2d.append(world_2d)
	
	return path_2d

# === INTERPOLATION AND SMOOTHING ===
static func interpolate_2d_to_3d(pos_2d_start: Vector2, pos_2d_end: Vector2, pos_3d_start: Vector3, t: float) -> Vector3:
	"""Interpolate between 2D and 3D positions during transition"""
	var pos_2d_end_as_3d = world_2d_to_world_3d(pos_2d_end)
	var pos_2d_start_as_3d = world_2d_to_world_3d(pos_2d_start)
	
	var interpolated_2d = pos_2d_start_as_3d.lerp(pos_2d_end_as_3d, t)
	return pos_3d_start.lerp(interpolated_2d, t)

static func smooth_coordinate_transition(current_pos: Vector3, target_pos: Vector3, delta: float, transition_speed: float = 5.0) -> Vector3:
	"""Smoothly transition between coordinate systems"""
	return current_pos.lerp(target_pos, transition_speed * delta)

# === UTILITY FUNCTIONS ===
static func snap_to_grid(position: Vector2, grid_size: float = 1.0) -> Vector2:
	"""Snap position to grid"""
	return Vector2(
		round(position.x / grid_size) * grid_size,
		round(position.y / grid_size) * grid_size
	)

static func get_relative_position_in_formation(leader_pos: Vector2, member_index: int, formation_type: String = "line") -> Vector2:
	"""Get relative position for formation member"""
	match formation_type:
		"line":
			return Vector2(-20 * (member_index + 1), 0)
		"wedge":
			var side = 1 if member_index % 2 == 0 else -1
			var row = (member_index + 1) / 2
			return Vector2(-15 * row, side * 10 * row)
		"circle":
			var angle = (TAU / 8) * member_index
			return Vector2.RIGHT.rotated(angle) * 15
		_:
			return Vector2(-10 * member_index, randf_range(-5, 5))

static func world_to_minimap_position(world_pos: Vector2, minimap_size: Vector2, world_bounds: Rect2) -> Vector2:
	"""Convert world position to minimap position"""
	var normalized_pos = Vector2(
		(world_pos.x - world_bounds.position.x) / world_bounds.size.x,
		(world_pos.y - world_bounds.position.y) / world_bounds.size.y
	)
	
	return Vector2(
		normalized_pos.x * minimap_size.x,
		normalized_pos.y * minimap_size.y
	)

static func minimap_to_world_position(minimap_pos: Vector2, minimap_size: Vector2, world_bounds: Rect2) -> Vector2:
	"""Convert minimap position to world position"""
	var normalized_pos = Vector2(
		minimap_pos.x / minimap_size.x,
		minimap_pos.y / minimap_size.y
	)
	
	return Vector2(
		world_bounds.position.x + normalized_pos.x * world_bounds.size.x,
		world_bounds.position.y + normalized_pos.y * world_bounds.size.y
	)

# === VALIDATION ===
static func is_valid_world_position(pos: Vector2, world_bounds: Rect2) -> bool:
	"""Check if position is within valid world bounds"""
	return world_bounds.has_point(pos)

static func is_valid_local_position(pos: Vector2, area_size: float = AREA_SIZE) -> bool:
	"""Check if local position is within area bounds"""
	var half_size = area_size * 0.5
	return abs(pos.x) <= half_size and abs(pos.y) <= half_size

static func get_coordinate_system_info() -> Dictionary:
	"""Get information about the coordinate system"""
	return {
		"world_scale": WORLD_SCALE,
		"default_height": DEFAULT_HEIGHT,
		"area_size": AREA_SIZE,
		"coordinate_system": "2D world coordinates with 3D local areas",
		"units": "Godot units (1 unit = 1 meter conceptually)"
	}