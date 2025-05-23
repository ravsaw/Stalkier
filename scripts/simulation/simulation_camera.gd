# scripts/simulation/simulation_camera.gd
extends Camera2D

# === CAMERA SETTINGS ===
@export var move_speed: float = 500.0
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.1
@export var max_zoom: float = 2.0
@export var edge_scroll_margin: int = 50
@export var edge_scroll_speed: float = 300.0

# === WORLD BOUNDS ===
var world_size: Vector2 = Vector2(1000, 1000)  # In simulation units
var world_bounds: Rect2

# === INPUT STATE ===
var is_dragging: bool = false
var drag_start_position: Vector2

func _ready():
	# Set initial position to center of world
	position = world_size * 0.5
	
	# Calculate world bounds
	world_bounds = Rect2(-world_size, world_size * 2)
	
	# Set initial zoom
	zoom = Vector2(0.5, 0.5)

func _process(delta: float):
	handle_keyboard_movement(delta)
	#handle_edge_scrolling(delta)
	clamp_camera_position()

func _unhandled_input(event: InputEvent):
	# Mouse wheel zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_in()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_out()
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				is_dragging = true
				drag_start_position = event.position
			else:
				is_dragging = false
	
	# Mouse drag
	elif event is InputEventMouseMotion and is_dragging:
		var drag_delta = (event.position - drag_start_position) / zoom
		position -= drag_delta
		drag_start_position = event.position

func handle_keyboard_movement(delta: float):
	var movement = Vector2.ZERO
	
	if Input.is_action_pressed("camera_left"):
		movement.x -= 1
	if Input.is_action_pressed("camera_right"):
		movement.x += 1
	if Input.is_action_pressed("camera_up"):
		movement.y -= 1
	if Input.is_action_pressed("camera_down"):
		movement.y += 1
	
	if movement.length() > 0:
		position += movement.normalized() * move_speed * delta / zoom.x

func handle_edge_scrolling(delta: float):
	var viewport = get_viewport()
	if not viewport:
		return
	
	var mouse_pos = viewport.get_mouse_position()
	var viewport_size = viewport.get_visible_rect().size
	var movement = Vector2.ZERO
	
	# Check edges
	if mouse_pos.x < edge_scroll_margin:
		movement.x = -1
	elif mouse_pos.x > viewport_size.x - edge_scroll_margin:
		movement.x = 1
	
	if mouse_pos.y < edge_scroll_margin:
		movement.y = -1
	elif mouse_pos.y > viewport_size.y - edge_scroll_margin:
		movement.y = 1
	
	if movement.length() > 0:
		position += movement.normalized() * edge_scroll_speed * delta / zoom.x

func zoom_in():
	zoom *= (1 + zoom_speed)
	zoom = zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))

func zoom_out():
	zoom *= (1 - zoom_speed)
	zoom = zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))

func clamp_camera_position():
	# Get viewport size in world coordinates
	var viewport_size = get_viewport_rect().size / zoom
	
	# Calculate bounds considering viewport size
	var min_pos = Vector2.ZERO + viewport_size * 0.5
	var max_pos = world_size - viewport_size * 0.5
	
	# Clamp position
	#position.x = clamp(position.x, min_pos.x, max_pos.x)
	#position.y = clamp(position.y, min_pos.y, max_pos.y)

func center_on_position(pos: Vector2):
	position = pos
	clamp_camera_position()

func center_on_npc(npc: NPC):
	if npc:
		center_on_position(npc.position)

func center_on_poi(poi: POI):
	if poi:
		center_on_position(poi.position)

func center_on_group(group: Group):
	if group:
		center_on_position(group.get_average_position())

# Input action mappings to add to project settings:
# camera_left: A, Left Arrow
# camera_right: D, Right Arrow  
# camera_up: W, Up Arrow
# camera_down: S, Down Arrow
