# scripts/world/transitions/transition_point.gd
extends RefCounted
class_name TransitionPoint

## Represents a point where players and NPCs can transition between 2D and 3D modes
## Handles trigger detection, visual feedback, and smooth transitions

# === IDENTIFICATION ===
var transition_id: String = ""
var name: String = ""

# === POSITION ===
var position_2d: Vector2 = Vector2()
var position_3d: Vector3 = Vector3()
var trigger_radius: float = 10.0

# === TRANSITION CONFIGURATION ===
var from_mode: WorldManager.WorldMode = WorldManager.WorldMode.MODE_2D
var to_mode: WorldManager.WorldMode = WorldManager.WorldMode.MODE_3D
var is_bidirectional: bool = false

# === TRIGGER CONDITIONS ===
var requires_player: bool = true  # Only player can use this transition
var requires_key_item: bool = false
var required_item_id: String = ""
var minimum_level: int = 0

# === VISUAL SETTINGS ===
var show_visual_indicator: bool = true
var indicator_color: Color = Color.CYAN
var indicator_pulse: bool = true
var show_range_indicator: bool = false

# === TRANSITION EFFECTS ===
enum TransitionType { 
	INSTANT,     # Immediate mode switch
	FADE,        # Fade to black and switch
	PORTAL,      # Portal-like effect
	ELEVATOR,    # Vertical movement effect
	STAIRS       # Step-by-step transition
}
var transition_type: TransitionType = TransitionType.FADE
var transition_duration: float = 1.0

# === AUDIO ===
var transition_sound: String = ""
var ambient_sound: String = ""
var sound_radius: float = 20.0

# === STATE ===
var is_active: bool = true
var is_transitioning: bool = false
var last_triggered_time: float = 0.0
var cooldown_time: float = 2.0

# === AREA REFERENCES ===
var source_area_id: String = ""
var target_area_id: String = ""

# === ENTITIES IN RANGE ===
var entities_in_range: Array = []
var trigger_timer: float = 0.0
var trigger_check_interval: float = 0.1

func _init():
	transition_id = "tp_" + str(randi())

func setup(pos_2d: Vector2, pos_3d: Vector3, from: WorldManager.WorldMode, to: WorldManager.WorldMode):
	position_2d = pos_2d
	position_3d = pos_3d
	from_mode = from
	to_mode = to
	
	# Auto-calculate 3D position if not provided
	if pos_3d == Vector3.ZERO and WorldManager.coordinate_converter:
		position_3d = WorldManager.coordinate_converter.convert_2d_to_3d(pos_2d)

func update(delta: float):
	if not is_active:
		return
	
	trigger_timer += delta
	
	if trigger_timer >= trigger_check_interval:
		trigger_timer = 0.0
		check_for_triggers()

func check_for_triggers():
	var current_mode = WorldManager.get_current_mode()
	
	# Only check if we're in the correct source mode
	if current_mode != from_mode and not is_bidirectional:
		return
	
	# Clear previous entities and check current ones
	entities_in_range.clear()
	
	# Check for player
	if requires_player:
		var player_pos = get_player_position(current_mode)
		if player_pos != Vector2.INF and is_position_in_range(player_pos, current_mode):
			entities_in_range.append("player")
	
	# Check for NPCs (if they can use transitions)
	check_npcs_in_range(current_mode)
	
	# Trigger transition if conditions are met
	if not entities_in_range.is_empty() and can_trigger():
		trigger_transition()

func get_player_position(mode: WorldManager.WorldMode) -> Vector2:
	# This would get the actual player position from the game
	# For now, return a placeholder
	# In a real implementation, this would query the player controller
	return Vector2.INF  # Placeholder for "no player found"

func check_npcs_in_range(current_mode: WorldManager.WorldMode):
	# Check if any NPCs are in range and can use this transition
	for npc in NPCManager.get_all_npcs():
		if not npc.is_alive():
			continue
		
		var npc_pos = npc.position if current_mode == WorldManager.WorldMode.MODE_2D else WorldManager.coordinate_converter.convert_3d_to_2d(npc.position_3d)
		
		if is_position_in_range(npc_pos, current_mode):
			# Check if NPC can use this transition
			if can_npc_use_transition(npc):
				entities_in_range.append(npc)

func is_position_in_range(pos: Vector2, mode: WorldManager.WorldMode) -> bool:
	var reference_pos = position_2d if mode == WorldManager.WorldMode.MODE_2D else WorldManager.coordinate_converter.convert_3d_to_2d(position_3d)
	return pos.distance_to(reference_pos) <= trigger_radius

func can_npc_use_transition(npc: NPC) -> bool:
	# Check if NPC meets requirements for this transition
	
	# Level requirement
	if npc.level < minimum_level:
		return false
	
	# Item requirement
	if requires_key_item and not npc.inventory.has_item(required_item_id):
		return false
	
	# Check if NPC's AI allows mode transitions
	if not npc.ai_can_change_modes:
		return false
	
	return true

func can_trigger() -> bool:
	# Check cooldown
	var current_time = Time.get_time_dict_from_system()["unix"]
	if current_time - last_triggered_time < cooldown_time:
		return false
	
	# Check if already transitioning
	if is_transitioning or WorldManager.current_mode == WorldManager.WorldMode.TRANSITIONING:
		return false
	
	return true

func trigger_transition():
	if not can_trigger():
		return
	
	print("TransitionPoint: Triggering transition from ", WorldManager.WorldMode.keys()[from_mode], " to ", WorldManager.WorldMode.keys()[to_mode])
	
	is_transitioning = true
	last_triggered_time = Time.get_time_dict_from_system()["unix"]
	
	# Play sound effect
	if not transition_sound.is_empty():
		play_transition_sound()
	
	# Start transition effect
	start_transition_effect()
	
	# Notify WorldManager
	EventBus.emit_signal("mode_transition_requested", to_mode)
	
	# Handle entities in transition
	process_entities_transition()

func start_transition_effect():
	match transition_type:
		TransitionType.INSTANT:
			complete_transition_immediately()
		
		TransitionType.FADE:
			start_fade_transition()
		
		TransitionType.PORTAL:
			start_portal_transition()
		
		TransitionType.ELEVATOR:
			start_elevator_transition()
		
		TransitionType.STAIRS:
			start_stairs_transition()

func complete_transition_immediately():
	# Immediate transition completion
	await get_tree().process_frame
	complete_transition()

func start_fade_transition():
	# Fade out, switch mode, fade in
	# This would typically involve UI elements
	await get_tree().create_timer(transition_duration * 0.3).timeout
	
	# Switch happens in the middle of the fade
	await get_tree().create_timer(transition_duration * 0.4).timeout
	
	await get_tree().create_timer(transition_duration * 0.3).timeout
	complete_transition()

func start_portal_transition():
	# Portal-like visual effect
	# This would involve particle effects and visual distortions
	await get_tree().create_timer(transition_duration).timeout
	complete_transition()

func start_elevator_transition():
	# Elevator-like vertical movement
	# This would involve camera movement and mechanical sounds
	await get_tree().create_timer(transition_duration).timeout
	complete_transition()

func start_stairs_transition():
	# Gradual transition simulating climbing/descending stairs
	await get_tree().create_timer(transition_duration).timeout
	complete_transition()

func complete_transition():
	is_transitioning = false
	print("TransitionPoint: Transition completed")

func process_entities_transition():
	# Update positions for entities that transitioned
	for entity in entities_in_range:
		if entity is String and entity == "player":
			# Handle player transition
			handle_player_transition()
		elif entity is NPC:
			# Handle NPC transition
			handle_npc_transition(entity)

func handle_player_transition():
	# Update player position for new mode
	# This would interact with the player controller
	pass

func handle_npc_transition(npc: NPC):
	# Update NPC position and mode
	if to_mode == WorldManager.WorldMode.MODE_3D:
		npc.position_3d = WorldManager.coordinate_converter.convert_2d_to_3d(npc.position)
	else:
		npc.position = WorldManager.coordinate_converter.convert_3d_to_2d(npc.position_3d)
	
	# Update NPC's current mode
	npc.current_mode = to_mode

func play_transition_sound():
	# Play transition sound effect
	# This would use an AudioStreamPlayer
	pass

func get_visual_indicator_position(mode: WorldManager.WorldMode) -> Vector2:
	if mode == WorldManager.WorldMode.MODE_2D:
		return position_2d
	else:
		return WorldManager.coordinate_converter.convert_3d_to_2d(position_3d)

func get_visual_indicator_size() -> float:
	return trigger_radius * 2.0

func is_visible_in_mode(mode: WorldManager.WorldMode) -> bool:
	# Check if this transition point should be visible in the current mode
	return mode == from_mode or (is_bidirectional and mode == to_mode)

func set_bidirectional(bidirectional: bool):
	is_bidirectional = bidirectional
	
	if bidirectional:
		# Create reverse transition data
		name += " (Bidirectional)"

func set_requirements(requires_player: bool = true, requires_item: bool = false, item_id: String = "", min_level: int = 0):
	self.requires_player = requires_player
	self.requires_key_item = requires_item
	self.required_item_id = item_id
	self.minimum_level = min_level

func set_visual_settings(show_indicator: bool = true, color: Color = Color.CYAN, pulse: bool = true, show_range: bool = false):
	show_visual_indicator = show_indicator
	indicator_color = color
	indicator_pulse = pulse
	show_range_indicator = show_range

func set_audio_settings(transition_sound_path: String = "", ambient_sound_path: String = "", audio_radius: float = 20.0):
	transition_sound = transition_sound_path
	ambient_sound = ambient_sound_path
	sound_radius = audio_radius

func activate():
	is_active = true
	print("TransitionPoint: Activated - ", transition_id)

func deactivate():
	is_active = false
	is_transitioning = false
	entities_in_range.clear()
	print("TransitionPoint: Deactivated - ", transition_id)

func get_info() -> Dictionary:
	return {
		"transition_id": transition_id,
		"name": name,
		"position_2d": position_2d,
		"position_3d": position_3d,
		"trigger_radius": trigger_radius,
		"from_mode": WorldManager.WorldMode.keys()[from_mode],
		"to_mode": WorldManager.WorldMode.keys()[to_mode],
		"is_bidirectional": is_bidirectional,
		"is_active": is_active,
		"is_transitioning": is_transitioning,
		"transition_type": TransitionType.keys()[transition_type],
		"requires_player": requires_player,
		"requires_key_item": requires_key_item,
		"minimum_level": minimum_level,
		"entities_in_range": entities_in_range.size()
	}

# === UTILITY FUNCTIONS ===

func get_distance_to_position(pos: Vector2, mode: WorldManager.WorldMode) -> float:
	var reference_pos = position_2d if mode == WorldManager.WorldMode.MODE_2D else WorldManager.coordinate_converter.convert_3d_to_2d(position_3d)
	return pos.distance_to(reference_pos)

func get_direction_to_position(pos: Vector2, mode: WorldManager.WorldMode) -> Vector2:
	var reference_pos = position_2d if mode == WorldManager.WorldMode.MODE_2D else WorldManager.coordinate_converter.convert_3d_to_2d(position_3d)
	return (reference_pos - pos).normalized()

# === DEBUG FUNCTIONS ===

func debug_draw_range(canvas: CanvasItem, mode: WorldManager.WorldMode):
	if not show_range_indicator:
		return
	
	var center = get_visual_indicator_position(mode)
	var color = indicator_color
	color.a = 0.3
	
	# Draw trigger radius
	canvas.draw_circle(center, trigger_radius, color)
	
	# Draw border
	canvas.draw_arc(center, trigger_radius, 0, TAU, 32, indicator_color, 2.0)

func debug_info() -> String:
	var info = "TransitionPoint Debug Info:\n"
	info += "  ID: " + transition_id + "\n"
	info += "  Position 2D: " + str(position_2d) + "\n"
	info += "  Position 3D: " + str(position_3d) + "\n"
	info += "  From Mode: " + WorldManager.WorldMode.keys()[from_mode] + "\n"
	info += "  To Mode: " + WorldManager.WorldMode.keys()[to_mode] + "\n"
	info += "  Active: " + str(is_active) + "\n"
	info += "  Entities in Range: " + str(entities_in_range.size()) + "\n"
	return info