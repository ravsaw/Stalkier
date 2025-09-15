# scripts/world/coordinate_conversion/coordinate_converter.gd
extends RefCounted
class_name CoordinateConverter

## Handles conversion between 2D top-down and 3D FPS coordinate systems
## Manages seamless transition of positions, directions, and bounds between modes

# === COORDINATE SYSTEM CONFIGURATION ===
var world_bounds_2d: Rect2 = Rect2()
var world_bounds_3d: AABB = AABB()

# === CONVERSION PARAMETERS ===
var scale_factor: float = 1.0  # 1:1 scale by default
var height_offset: float = 0.0  # Base ground level in 3D
var height_variation: float = 5.0  # Max terrain height variation

# === AXIS MAPPING ===
# 2D: X = horizontal, Y = vertical (top-down view)
# 3D: X = horizontal, Y = up/down, Z = depth (forward/back)
# Mapping: 2D.x -> 3D.x, 2D.y -> 3D.z, 3D.y calculated from terrain

var axis_flip_z: bool = false  # Set to true if Z axis needs flipping

# === TERRAIN HEIGHT CACHE ===
var height_cache: Dictionary = {}  # Vector2 -> float (for performance)
var cache_resolution: float = 10.0  # Cache every 10 units
var max_cache_size: int = 10000

# === NOISE FOR TERRAIN HEIGHT ===
var height_noise: FastNoiseLite

func _init():
	setup_height_noise()

func setup_conversion(bounds_2d: Rect2, bounds_3d: AABB, scale: float = 1.0):
	world_bounds_2d = bounds_2d
	world_bounds_3d = bounds_3d
	scale_factor = scale
	
	# Calculate height offset from 3D bounds
	height_offset = world_bounds_3d.position.y
	height_variation = world_bounds_3d.size.y * 0.1  # 10% of Y size for terrain variation
	
	print("CoordinateConverter: Setup complete")
	print("  - 2D bounds: ", world_bounds_2d)
	print("  - 3D bounds: ", world_bounds_3d)
	print("  - Scale factor: ", scale_factor)
	print("  - Height offset: ", height_offset)

func setup_height_noise():
	height_noise = FastNoiseLite.new()
	height_noise.seed = randi()
	height_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	height_noise.frequency = 0.01
	height_noise.fractal_octaves = 3
	height_noise.fractal_gain = 0.5
	height_noise.fractal_lacunarity = 2.0

# === POSITION CONVERSION ===

func convert_2d_to_3d(pos_2d: Vector2) -> Vector3:
	var x = pos_2d.x * scale_factor
	var z = pos_2d.y * scale_factor
	if axis_flip_z:
		z = -z
	
	var y = get_terrain_height_at(pos_2d)
	
	return Vector3(x, y, z)

func convert_3d_to_2d(pos_3d: Vector3) -> Vector2:
	var x = pos_3d.x / scale_factor
	var y = pos_3d.z / scale_factor
	if axis_flip_z:
		y = -y
	
	return Vector2(x, y)

func get_terrain_height_at(pos_2d: Vector2) -> float:
	# Check cache first
	var cache_key = Vector2(
		floor(pos_2d.x / cache_resolution) * cache_resolution,
		floor(pos_2d.y / cache_resolution) * cache_resolution
	)
	
	if cache_key in height_cache:
		return height_cache[cache_key]
	
	# Calculate height using noise
	var noise_value = height_noise.get_noise_2d(pos_2d.x, pos_2d.y)
	var height = height_offset + (noise_value * height_variation)
	
	# Add cache entry (manage cache size)
	if height_cache.size() < max_cache_size:
		height_cache[cache_key] = height
	
	return height

# === DIRECTION CONVERSION ===

func convert_direction_2d_to_3d(dir_2d: Vector2) -> Vector3:
	var x = dir_2d.x
	var z = dir_2d.y
	if axis_flip_z:
		z = -z
	
	return Vector3(x, 0, z).normalized()

func convert_direction_3d_to_2d(dir_3d: Vector3) -> Vector2:
	var x = dir_3d.x
	var y = dir_3d.z
	if axis_flip_z:
		y = -y
	
	return Vector2(x, y).normalized()

# === BOUNDS CONVERSION ===

func convert_rect2d_to_aabb(rect: Rect2, height_min: float = 0, height_max: float = 20) -> AABB:
	var min_pos = Vector3(
		rect.position.x * scale_factor,
		height_offset + height_min,
		rect.position.y * scale_factor
	)
	
	var size = Vector3(
		rect.size.x * scale_factor,
		height_max - height_min,
		rect.size.y * scale_factor
	)
	
	if axis_flip_z:
		min_pos.z = -min_pos.z - size.z
	
	return AABB(min_pos, size)

func convert_aabb_to_rect2d(aabb: AABB) -> Rect2:
	var pos_x = aabb.position.x / scale_factor
	var pos_y = aabb.position.z / scale_factor
	var size_x = aabb.size.x / scale_factor
	var size_y = aabb.size.z / scale_factor
	
	if axis_flip_z:
		pos_y = -pos_y - size_y
	
	return Rect2(pos_x, pos_y, size_x, size_y)

# === DISTANCE CONVERSION ===

func convert_distance_2d_to_3d(distance_2d: float) -> float:
	return distance_2d * scale_factor

func convert_distance_3d_to_2d(distance_3d: float) -> float:
	return distance_3d / scale_factor

# === ANGLE CONVERSION ===

func convert_angle_2d_to_3d_y_rotation(angle_2d: float) -> float:
	# Convert 2D angle (0 = right, PI/2 = down) to 3D Y rotation
	var adjusted_angle = angle_2d
	if axis_flip_z:
		adjusted_angle = -adjusted_angle
	
	return adjusted_angle - PI/2  # Adjust for different forward directions

func convert_3d_y_rotation_to_2d_angle(y_rotation: float) -> float:
	# Convert 3D Y rotation to 2D angle
	var adjusted_rotation = y_rotation + PI/2
	if axis_flip_z:
		adjusted_rotation = -adjusted_rotation
	
	return adjusted_rotation

# === VELOCITY CONVERSION ===

func convert_velocity_2d_to_3d(velocity_2d: Vector2, current_3d_pos: Vector3 = Vector3.ZERO) -> Vector3:
	var vel_x = velocity_2d.x * scale_factor
	var vel_z = velocity_2d.y * scale_factor
	if axis_flip_z:
		vel_z = -vel_z
	
	# Calculate Y velocity based on terrain slope
	var vel_y = 0.0
	if current_3d_pos != Vector3.ZERO and velocity_2d.length() > 0:
		vel_y = calculate_slope_velocity(current_3d_pos, Vector3(vel_x, 0, vel_z))
	
	return Vector3(vel_x, vel_y, vel_z)

func convert_velocity_3d_to_2d(velocity_3d: Vector3) -> Vector2:
	var vel_x = velocity_3d.x / scale_factor
	var vel_y = velocity_3d.z / scale_factor
	if axis_flip_z:
		vel_y = -vel_y
	
	return Vector2(vel_x, vel_y)

func calculate_slope_velocity(current_pos: Vector3, horizontal_velocity: Vector3) -> float:
	# Calculate the Y velocity needed to follow terrain slope
	var current_2d = convert_3d_to_2d(current_pos)
	var future_2d = current_2d + convert_velocity_3d_to_2d(horizontal_velocity) * 0.1  # Look ahead 0.1 seconds
	
	var current_height = get_terrain_height_at(current_2d)
	var future_height = get_terrain_height_at(future_2d)
	
	return (future_height - current_height) * 10.0  # Scale for reasonable slope following

# === PATH CONVERSION ===

func convert_path_2d_to_3d(path_2d: PackedVector2Array) -> PackedVector3Array:
	var path_3d = PackedVector3Array()
	
	for point_2d in path_2d:
		path_3d.append(convert_2d_to_3d(point_2d))
	
	return path_3d

func convert_path_3d_to_2d(path_3d: PackedVector3Array) -> PackedVector2Array:
	var path_2d = PackedVector2Array()
	
	for point_3d in path_3d:
		path_2d.append(convert_3d_to_2d(point_3d))
	
	return path_2d

# === SPECIALIZED CONVERSIONS ===

func convert_camera_position_2d_to_3d(camera_2d_pos: Vector2, camera_mode: String = "overhead") -> Vector3:
	match camera_mode:
		"overhead":
			# Position camera above the 2D position
			var pos_3d = convert_2d_to_3d(camera_2d_pos)
			pos_3d.y += 50.0  # Elevated view
			return pos_3d
		
		"fps":
			# Position camera at ground level for FPS view
			var pos_3d = convert_2d_to_3d(camera_2d_pos)
			pos_3d.y += 1.8  # Human eye level
			return pos_3d
		
		_:
			return convert_2d_to_3d(camera_2d_pos)

func convert_npc_transform_2d_to_3d(pos_2d: Vector2, rotation_2d: float) -> Transform3D:
	var pos_3d = convert_2d_to_3d(pos_2d)
	var rotation_3d = convert_angle_2d_to_3d_y_rotation(rotation_2d)
	
	var transform = Transform3D()
	transform.origin = pos_3d
	transform = transform.rotated(Vector3.UP, rotation_3d)
	
	return transform

func convert_npc_transform_3d_to_2d(transform_3d: Transform3D) -> Array:
	var pos_2d = convert_3d_to_2d(transform_3d.origin)
	var rotation_2d = convert_3d_y_rotation_to_2d_angle(transform_3d.basis.get_euler().y)
	
	return [pos_2d, rotation_2d]

# === VALIDATION ===

func is_position_valid_2d(pos_2d: Vector2) -> bool:
	return world_bounds_2d.has_point(pos_2d)

func is_position_valid_3d(pos_3d: Vector3) -> bool:
	return world_bounds_3d.has_point(pos_3d)

func clamp_position_2d(pos_2d: Vector2) -> Vector2:
	return Vector2(
		clamp(pos_2d.x, world_bounds_2d.position.x, world_bounds_2d.position.x + world_bounds_2d.size.x),
		clamp(pos_2d.y, world_bounds_2d.position.y, world_bounds_2d.position.y + world_bounds_2d.size.y)
	)

func clamp_position_3d(pos_3d: Vector3) -> Vector3:
	return Vector3(
		clamp(pos_3d.x, world_bounds_3d.position.x, world_bounds_3d.position.x + world_bounds_3d.size.x),
		clamp(pos_3d.y, world_bounds_3d.position.y, world_bounds_3d.position.y + world_bounds_3d.size.y),
		clamp(pos_3d.z, world_bounds_3d.position.z, world_bounds_3d.position.z + world_bounds_3d.size.z)
	)

# === UTILITY FUNCTIONS ===

func get_world_info() -> Dictionary:
	return {
		"bounds_2d": world_bounds_2d,
		"bounds_3d": world_bounds_3d,
		"scale_factor": scale_factor,
		"height_offset": height_offset,
		"height_variation": height_variation,
		"axis_flip_z": axis_flip_z,
		"cache_size": height_cache.size()
	}

func clear_height_cache():
	height_cache.clear()

func precompute_height_cache_for_area(area_bounds_2d: Rect2):
	# Precompute height cache for an area to improve performance
	var start_x = area_bounds_2d.position.x
	var end_x = area_bounds_2d.position.x + area_bounds_2d.size.x
	var start_y = area_bounds_2d.position.y
	var end_y = area_bounds_2d.position.y + area_bounds_2d.size.y
	
	for x in range(start_x, end_x, cache_resolution):
		for y in range(start_y, end_y, cache_resolution):
			var pos = Vector2(x, y)
			get_terrain_height_at(pos)  # This will add to cache

func set_terrain_parameters(noise_seed: int, frequency: float, octaves: int):
	height_noise.seed = noise_seed
	height_noise.frequency = frequency
	height_noise.fractal_octaves = octaves
	clear_height_cache()  # Clear cache since terrain changed

# === DEBUGGING ===

func debug_conversion_test():
	print("=== CoordinateConverter Debug Test ===")
	
	# Test basic position conversion
	var test_2d = Vector2(100, 200)
	var converted_3d = convert_2d_to_3d(test_2d)
	var back_to_2d = convert_3d_to_2d(converted_3d)
	
	print("2D -> 3D -> 2D conversion test:")
	print("  Original 2D: ", test_2d)
	print("  Converted 3D: ", converted_3d)
	print("  Back to 2D: ", back_to_2d)
	print("  Error: ", test_2d.distance_to(back_to_2d))
	
	# Test bounds conversion
	var test_rect = Rect2(0, 0, 100, 100)
	var converted_aabb = convert_rect2d_to_aabb(test_rect)
	var back_to_rect = convert_aabb_to_rect2d(converted_aabb)
	
	print("\nBounds conversion test:")
	print("  Original Rect2D: ", test_rect)
	print("  Converted AABB: ", converted_aabb)
	print("  Back to Rect2D: ", back_to_rect)