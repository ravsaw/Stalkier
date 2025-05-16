extends Node

# World configuration
var WORLD_SIZE := Vector2(10000, 10000)
var LOCATION_SIZE := Vector2(1000, 1000)
var MAX_NPCS := 300
var BASE_UPDATE_RATE := 0.5  # seconds

# References
var world_manager: Node
var simulation_layer: Node2D
var rendering_layer: Node3D

func _ready():
	print("GameGlobals initialized")
