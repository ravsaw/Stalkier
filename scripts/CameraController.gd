extends Node2D
class_name CameraController

@export var move_speed: float = 300.0
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.1
@export var max_zoom: float = 3.0
@export var smooth_factor: float = 5.0

@onready var camera_2d: Camera2D = $Camera2D
var target_zoom: Vector2
var target_position: Vector2

func _ready():
	add_to_group("camera_controller")
	camera_2d.make_current()
	target_zoom = camera_2d.zoom
	target_position = global_position

func _process(delta):
	handle_input(delta)
	smooth_camera_movement(delta)

func handle_input(delta):
	# Camera movement
	var move_vector = Vector2.ZERO
	
	if Input.is_action_pressed("ui_left"):
		move_vector.x -= 1
	if Input.is_action_pressed("ui_right"):
		move_vector.x += 1
	if Input.is_action_pressed("ui_up"):
		move_vector.y -= 1
	if Input.is_action_pressed("ui_down"):
		move_vector.y += 1
	
	# Normalize diagonal movement
	if move_vector.length() > 0:
		move_vector = move_vector.normalized()
		target_position += move_vector * move_speed * delta / target_zoom.x
	
	# Zoom handling
	if Input.is_action_just_pressed("zoom_in"):
		target_zoom *= (1.0 + zoom_speed)
	elif Input.is_action_just_pressed("zoom_out"):
		target_zoom *= (1.0 - zoom_speed)
	
	# Clamp zoom
	target_zoom.x = clamp(target_zoom.x, min_zoom, max_zoom)
	target_zoom.y = clamp(target_zoom.y, min_zoom, max_zoom)
	
	# Reset camera position
	if Input.is_action_just_pressed("reset_camera"):
		target_position = Vector2.ZERO
		target_zoom = Vector2.ONE

func smooth_camera_movement(delta):
	# Smooth position
	global_position = global_position.lerp(target_position, smooth_factor * delta)
	
	# Smooth zoom
	camera_2d.zoom = camera_2d.zoom.lerp(target_zoom, smooth_factor * delta)

# Optional: method to follow a specific NPC
func follow_npc(npc_position: Vector2):
	target_position = npc_position

# Optional: method to center view on all NPCs
func center_on_all_npcs(npc_positions: Array):
	if npc_positions.is_empty():
		return
	
	var center = Vector2.ZERO
	for pos in npc_positions:
		center += pos
	center /= npc_positions.size()
	
	target_position = center

func center_on_locations():
	var locations_container = GameGlobals.simulation_layer.get_node("LocationsContainer")
	var locations = locations_container.get_children()
	
	if locations.is_empty():
		return
	
	var min_pos = Vector2(INF, INF)
	var max_pos = Vector2(-INF, -INF)
	
	for location in locations:
		var pos = location.global_position
		min_pos.x = min(min_pos.x, pos.x - GameGlobals.LOCATION_SIZE.x/2)
		min_pos.y = min(min_pos.y, pos.y - GameGlobals.LOCATION_SIZE.y/2)
		max_pos.x = max(max_pos.x, pos.x + GameGlobals.LOCATION_SIZE.x/2)
		max_pos.y = max(max_pos.y, pos.y + GameGlobals.LOCATION_SIZE.y/2)
	
	# Center camera on all locations
	target_position = (min_pos + max_pos) / 2
	
	# Adjust zoom to fit all locations
	var size_needed = max_pos - min_pos
	var screen_size = get_viewport().get_visible_rect().size
	var zoom_x = screen_size.x / size_needed.x
	var zoom_y = screen_size.y / size_needed.y
	target_zoom = Vector2.ONE * min(zoom_x, zoom_y) * 0.8  # 0.8 for some padding

# Metoda do śledzenia określonej liczby NPCs
func focus_on_active_area():
	var npc_manager = get_tree().get_first_node_in_group("npc_manager")
	if not npc_manager:
		return
	
	var npc_positions = []
	for npc in npc_manager.active_npcs.values():
		npc_positions.append(npc.global_position)
	
	center_on_all_npcs(npc_positions)
