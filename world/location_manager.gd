# Location manager - handles transition between areas
extends Node
class_name LocationManager

@export var starting_location: PackedScene
@export var transition_fade_time: float = 1.0
@export var buffer_distance: float = 100.0  # Distance before actual boundary to begin transition
@export var load_next_location_distance: float = 150.0  # Distance at which to preload next location

# Map of location connections 
# Format: {"location_name": {"north": "next_location_name", "east": "other_location"}}
@export var location_connections: Dictionary = {}

# Reference to location scenes - allows for dynamic loading
@export var location_scenes: Dictionary = {}

var current_location: String = ""
var current_location_node: Node3D = null
var next_location_node: Node3D = null
var is_transitioning: bool = false
var transition_direction: String = ""

# Reference to player
@onready var player = $"/root/Game/Player"
#@onready var fade_screen = $"/root/Game/UI/FadeScreen"

signal location_changed(from_location, to_location)

func _ready():
	# Load starting location
	if starting_location:
		var initial_location = starting_location.instantiate()
		add_child(initial_location)
		current_location_node = initial_location
		current_location = initial_location.name
	
	# Initialize fade screen (if available)
	#if fade_screen:
	#	fade_screen.color.a = 0  # Fully transparent

func _process(_delta):
	if is_transitioning:
		return
	
	# Check for location boundaries
	check_location_boundaries()

func check_location_boundaries():
	# Get player position
	var player_pos = player.global_transform.origin
	
	# Check against the current location's boundaries
	if current_location_node.has_method("get_boundaries"):
		var boundaries = current_location_node.get_boundaries()
		var direction = ""
		var next_location = ""
		
		# Check if player is near a boundary
		if player_pos.x > boundaries.size.x/2 - buffer_distance:
			direction = "east"
		elif player_pos.x < -boundaries.size.x/2 + buffer_distance:
			direction = "west"
		elif player_pos.z > boundaries.size.z/2 - buffer_distance:
			direction = "north"
		elif player_pos.z < -boundaries.size.z/2 + buffer_distance:
			direction = "south"
		
		# If we're approaching a boundary and there's a connection
		if direction != "" and location_connections.has(current_location):
			if location_connections[current_location].has(direction):
				next_location = location_connections[current_location][direction]
				
				# Only preload if we're close enough to boundary
				var distance_to_boundary = 0.0
				
				match direction:
					"east":
						distance_to_boundary = boundaries.size.x/2 - player_pos.x
					"west":
						distance_to_boundary = player_pos.x + boundaries.size.x/2
					"north":
						distance_to_boundary = boundaries.size.z/2 - player_pos.z
					"south":
						distance_to_boundary = player_pos.z + boundaries.size.z/2
				
				if distance_to_boundary <= load_next_location_distance:
					preload_location(next_location, direction)
				
				# Check if player has crossed the actual boundary
				if distance_to_boundary <= 0:
					transition_to_location(next_location, direction)

func preload_location(location_name: String, direction: String):
	# Only preload if we haven't already loaded this location
	if next_location_node != null and next_location_node.name == location_name:
		return
	
	# Clean up any previously preloaded location
	if next_location_node != null:
		next_location_node.queue_free()
		next_location_node = null
	
	# Check if scene is available in the dictionary
	if location_scenes.has(location_name):
		var location_scene = location_scenes[location_name]
		
		# Instantiate the next location
		var location = location_scene.instantiate()
		add_child(location)
		next_location_node = location
		
		# Position the new location correctly based on direction
		position_new_location(direction)
		
		# Hide the location until needed, but keep it loaded
		location.hide()

func position_new_location(direction: String):
	# Get current boundaries
	var current_boundaries = current_location_node.get_boundaries()
	var next_boundaries = next_location_node.get_boundaries()
	
	# Calculate appropriate offset
	var offset = Vector3.ZERO
	
	match direction:
		"north":
			offset.z = current_boundaries.size.z/2 + next_boundaries.size.z/2
		"south":
			offset.z = -(current_boundaries.size.z/2 + next_boundaries.size.z/2)
		"east":
			offset.x = current_boundaries.size.x/2 + next_boundaries.size.x/2
		"west":
			offset.x = -(current_boundaries.size.x/2 + next_boundaries.size.x/2)
	
	# Position the new location
	next_location_node.global_transform.origin = current_location_node.global_transform.origin + offset

func transition_to_location(location_name: String, direction: String):
	if is_transitioning:
		return
	
	is_transitioning = true
	transition_direction = direction
	
	# Start fade transition
	#if fade_screen:
	#	var tween = create_tween()
	#	tween.tween_property(fade_screen, "color:a", 1.0, transition_fade_time)
	#	await tween.finished
	
	# If we haven't preloaded yet, do it now
	if next_location_node == null or next_location_node.name != location_name:
		preload_location(location_name, direction)
	
	# Show the new location
	next_location_node.show()
	
	# Move player to the correct entry point in new location
	reposition_player_in_new_location()
	
	# Switch locations
	var old_location = current_location
	current_location = location_name
	
	var temp = current_location_node
	current_location_node = next_location_node
	next_location_node = null
	
	# Hide and queue free the old location
	temp.hide()
	temp.queue_free()
	
	# Fade back in
	#if fade_screen:
	#	var tween = create_tween()
	#	tween.tween_property(fade_screen, "color:a", 0.0, transition_fade_time)
	#	await tween.finished
	
	is_transitioning = false
	
	# Emit signal that location has changed
	emit_signal("location_changed", old_location, current_location)

func reposition_player_in_new_location():
	var entry_point_offset = 10.0  # Move player a bit inside the new location
	var new_boundaries = next_location_node.get_boundaries()
	
	# Calculate new player position
	var new_position = player.global_transform.origin
	
	match transition_direction:
		"north":
			new_position.z = next_location_node.global_transform.origin.z - new_boundaries.size.z/2 + entry_point_offset
		"south":
			new_position.z = next_location_node.global_transform.origin.z + new_boundaries.size.z/2 - entry_point_offset
		"east":
			new_position.x = next_location_node.global_transform.origin.x - new_boundaries.size.x/2 + entry_point_offset
		"west":
			new_position.x = next_location_node.global_transform.origin.x + new_boundaries.size.x/2 - entry_point_offset
	
	# Apply new position
	player.global_transform.origin = new_position
