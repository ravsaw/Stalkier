extends Node2D
class_name ALIfe2DSimulation

var simulation_speed: float = 1.0
var is_paused: bool = false

func _ready():
	GameGlobals.simulation_layer = self
	print("2D Simulation Layer initialized")
	setup_simulation()

func setup_simulation():
	# Connect to event bus
	EventBus.simulation_speed_changed.connect(_on_speed_changed)
	
	# Sprawdź czy LocationsContainer istnieje
	if not has_node("LocationsContainer"):
		var container = Node2D.new()
		container.name = "LocationsContainer"
		add_child(container)

func _on_speed_changed(multiplier: float):
	simulation_speed = multiplier
	Engine.time_scale = multiplier

func pause_simulation():
	is_paused = true
	get_tree().paused = true

func resume_simulation():
	is_paused = false
	get_tree().paused = false
