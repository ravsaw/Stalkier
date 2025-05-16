extends Node
class_name POIData

@export var poi_id: String
@export var poi_type: String = "settlement"
@export var capacity: int = 50
@export var controlled_by: String = "neutral"

var current_npcs: Array = []
var sub_objects: Dictionary = {}

func _ready():
	if poi_id.is_empty():
		poi_id = get_parent().name
