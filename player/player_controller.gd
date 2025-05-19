# Player controller with full FPS functionality
extends CharacterBody3D
class_name PlayerController

# Movement parameters
@export var walk_speed: float = 5.0
@export var run_speed: float = 9.0
@export var jump_strength: float = 5.0
@export var gravity: float = 20.0

# Camera parameters
@export var mouse_sensitivity: float = 0.2
@export var max_camera_pitch: float = 85.0

# References
@onready var camera = $Head/Camera
@onready var head = $Head
@onready var weapon_manager = $WeaponManager

var health = 100.0
var max_health = 100.0
var current_velocity = Vector3.ZERO
var is_running: bool = false

signal health_changed(update_health_display)

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _input(event):
	# Mouse look implementation
	if event is InputEventMouseMotion:
		# Horizontal rotation - full body
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		
		# Vertical rotation - head only
		var current_tilt = head.rotation_degrees.x
		current_tilt -= event.relative.y * mouse_sensitivity
		head.rotation_degrees.x = clamp(current_tilt, -max_camera_pitch, max_camera_pitch)

func _physics_process(delta):
	# Movement
	var input_dir = Vector3.ZERO
	input_dir.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	input_dir.z = Input.get_action_strength("backward") - Input.get_action_strength("forward")
	
	# Convert to local space
	input_dir = input_dir.rotated(Vector3.UP, rotation.y)
	
	# Apply speed
	is_running = Input.is_action_pressed("sprint")
	var target_speed = run_speed if is_running else walk_speed
	
	# Momentum and smoothing
	var target_velocity = input_dir.normalized() * target_speed
	current_velocity.x = lerp(current_velocity.x, target_velocity.x, delta * 8.0)
	current_velocity.z = lerp(current_velocity.z, target_velocity.z, delta * 8.0)
	
	# Gravity
	if is_on_floor():
		current_velocity.y = -0.5  # Stick to ground
		
		# Jump
		if Input.is_action_just_pressed("jump"):
			current_velocity.y = jump_strength
	else:
		current_velocity.y -= gravity * delta
	
	# Apply movement
	velocity = current_velocity
	move_and_slide()
	
	# Weapon actions
	if Input.is_action_just_pressed("fire"):
		weapon_manager.fire()
	
	if Input.is_action_just_pressed("reload"):
		weapon_manager.reload()
	
	if Input.is_action_just_pressed("switch_weapon"):
		weapon_manager.switch_to_next_weapon()
