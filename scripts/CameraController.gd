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
