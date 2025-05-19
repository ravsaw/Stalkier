extends Node
class_name WorldManager

@export var world_size: Vector2 = Vector2(10000, 10000)
@export var location_size: Vector2 = Vector2(1000, 1000)

var locations: Dictionary = {}
var current_player_location: Vector2

func _ready():
	GameGlobals.world_manager = self
	# Poczekaj jedną klatkę, żeby wszystkie węzły się zainicjalizowały
	call_deferred("setup_initial_world")
	
	await get_tree().create_timer(0.5).timeout
	var camera_controller = get_tree().get_first_node_in_group("camera_controller")
	if camera_controller and camera_controller.has_method("center_on_locations"):
		camera_controller.center_on_locations()
		
func setup_initial_world():
	# Znajdź simulation layer bezpośrednio jeśli nie ma referencji w GameGlobals
	if not GameGlobals.simulation_layer:
		GameGlobals.simulation_layer = get_node("../SimulationLayer2D")
	
	# Create 9 locations in 3x3 grid for testing
	for x in range(3):
		for y in range(3):
			var location_pos = Vector2(x, y) * location_size
			create_location_at(location_pos)

func create_location_at(position: Vector2):
	var location_id = str(position.x) + "_" + str(position.y)
	
	# Load location scene
	var location_scene = preload("res://scenes/Location.tscn")
	var location = location_scene.instantiate()
	
	# Set position and add to simulation layer
	location.position = position
	location.name = location_id
	
	# Bezpośrednie odwołanie do węzła, jeśli GameGlobals nie działa
	var simulation_layer = GameGlobals.simulation_layer
	if not simulation_layer:
		simulation_layer = get_node("../SimulationLayer2D")
	
	simulation_layer.get_node("LocationsContainer").add_child(location)
	
	locations[location_id] = location
	
	# Create some test POIs
	create_test_pois(location)



func create_test_pois(location: Node2D):
	# Add 3-5 POIs per location for testing
	var poi_count = randi_range(3, 5)
	var poi_scene = preload("res://scenes/POI.tscn")
	
	for i in poi_count:
		var poi = poi_scene.instantiate()
		poi.position = Vector2(
			randf_range(-400, 400),
			randf_range(-400, 400)
		)
		poi.name = "POI_" + str(i)
		location.get_node("POIContainer").add_child(poi)
