extends CharacterBody2D
class_name NPCController

@export var debug_mode: bool = false

@onready var npc_data: NPCData = $NPCData
@onready var state_machine: NPCStateMachine = $StateMachine
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

@onready var visuals: Node2D = $NPCVisuals
@onready var sprite: Sprite2D = $NPCVisuals/Sprite2D
@onready var name_label: Label = $NPCVisuals/NameLabel
@onready var debug_info: Node2D = $DebugInfo

func _ready():
	await get_tree().process_frame
	
	# Ensure npc_data is ready
	if not npc_data:
		push_error("NPCData not found! Make sure it's a child of " + name)
		return
		
	# Setup visuals
	name_label.text = npc_data.npc_name
	name_label.visible = debug_mode
	
	# Setup navigation
	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = 4.0
	
	# Initialize state machine after everything is ready
	if state_machine:
		state_machine.initialize()
		
	# Connect signals
	EventBus.npc_created.emit(npc_data)

func _physics_process(delta):
	if not is_inside_tree():
		return
	
	# Update debug info if enabled
	if debug_mode and debug_info:
		debug_info.update_debug_display()
	
	# Let state machine handle movement
	state_machine.process_state(delta)

func move_to_poi(poi_id: String):
	var poi_position = get_poi_position(poi_id)
	if poi_position != Vector2.ZERO:
		navigation_agent.target_position = poi_position
		npc_data.target_poi = poi_id
		state_machine.change_state("moving")

func get_poi_position(poi_id: String) -> Vector2:
	# Find POI in current location
	var current_location = get_current_location()
	if current_location:
		var poi_container = current_location.get_node("POIContainer")
		for poi in poi_container.get_children():
			if poi.name == poi_id:
				return poi.global_position
	return Vector2.ZERO

func get_current_location() -> Node2D:
	# Find which location this NPC is currently in
	var locations_container = GameGlobals.simulation_layer.get_node("LocationsContainer")
	for location in locations_container.get_children():
		var bounds = Rect2(
			location.global_position - GameGlobals.LOCATION_SIZE/2,
			GameGlobals.LOCATION_SIZE
		)
		if bounds.has_point(global_position):
			return location
	return null

func select_target_poi_based_on_needs() -> String:
	var urgent_need = npc_data.get_most_urgent_need()
	var current_location = get_current_location()
	
	if not current_location:
		return ""
	
	# Simple POI selection based on needs
	var suitable_pois = find_pois_for_need(current_location, urgent_need)
	if suitable_pois.size() > 0:
		return suitable_pois[randi() % suitable_pois.size()]
	
	return ""

func find_pois_for_need(location: Node2D, need: String) -> Array:
	var suitable_pois = []
	var poi_container = location.get_node("POIContainer")
	
	for poi in poi_container.get_children():
		# Simple matching - in real implementation, use POI properties
		match need:
			"hunger":
				# Look for settlements or food sources
				if poi.name.begins_with("POI"):  # Placeholder logic
					suitable_pois.append(poi.name)
			"safety":
				# Look for fortified locations
				if poi.name.begins_with("POI"):  # Placeholder logic
					suitable_pois.append(poi.name)
			"energy":
				# Look for rest areas
				if poi.name.begins_with("POI"):  # Placeholder logic
					suitable_pois.append(poi.name)
	
	return suitable_pois

func _on_area_2d_body_entered(body):
	if body.has_method("get_poi_id"):
		EventBus.poi_entered.emit(npc_data.npc_id, body.get_poi_id())

func _on_area_2d_body_exited(body):
	if body.has_method("get_poi_id"):
		EventBus.poi_exited.emit(npc_data.npc_id, body.get_poi_id())
