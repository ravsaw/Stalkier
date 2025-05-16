extends Node
class_name LocationData

@export var location_id: String
@export var location_type: String = "normal"
@export var security_level: float = 0.5
@export var resources: Dictionary = {}

var npcs_present: Array = []
var pois: Array = []

func _ready():
	# Get all POIs in this location
	var poi_container = get_parent().get_node("POIContainer")
	for child in poi_container.get_children():
		pois.append(child)
