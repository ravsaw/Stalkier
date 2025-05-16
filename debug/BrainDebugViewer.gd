class_name BrainDebugViewer
extends Control

var brain_system: DualBrainSystem
var info_labels: Dictionary = {}
var update_timer: float = 0.0
var update_interval: float = 0.5  # Update twice per second

func _ready():
	# Setup UI
	_create_debug_interface()
	visible = true
	set_process(true)
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)

func _create_debug_interface():
	# Main container
	var main_vbox = VBoxContainer.new()
	add_child(main_vbox)
	
	# Title
	var title = Label.new()
	title.text = "AI Brain Debug Viewer"
	title.add_theme_font_size_override("font_size", 24)
	main_vbox.add_child(title)
	
	# Strategic Brain Section
	_create_brain_section(main_vbox, "Strategic Brain", "strategic")
	
	# Tactical Brain Section
	_create_brain_section(main_vbox, "Tactical Brain", "tactical")
	
	# Performance Section
	_create_brain_section(main_vbox, "Performance", "performance")
	
	# Controls
	_create_controls(main_vbox)

func _create_brain_section(parent: Node, title: String, section_key: String):
	var section_label = Label.new()
	section_label.text = title
	section_label.add_theme_font_size_override("font_size", 18)
	parent.add_child(section_label)
	
	var info_container = VBoxContainer.new()
	parent.add_child(info_container)
	
	# Add specific labels for each section
	match section_key:
		"strategic":
			_add_info_label(info_container, "strategic_goals", "Goals: N/A")
			_add_info_label(info_container, "strategic_top_goal", "Top Goal: N/A")
			_add_info_label(info_container, "strategic_memory_count", "Memories: N/A")
		"tactical":
			_add_info_label(info_container, "tactical_state", "State: N/A")
			_add_info_label(info_container, "tactical_command", "Current Command: N/A")
			_add_info_label(info_container, "tactical_perception", "Visible NPCs: N/A")
		"performance":
			_add_info_label(info_container, "sync_rate", "Sync Rate: N/A")
			_add_info_label(info_container, "sync_success", "Sync Success: N/A")
	
	# Add spacing
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 10
	parent.add_child(spacer)

func _add_info_label(parent: Node, key: String, default_text: String):
	var label = Label.new()
	label.text = default_text
	parent.add_child(label)
	info_labels[key] = label

func _create_controls(parent: Node):
	var controls_label = Label.new()
	controls_label.text = "Controls"
	controls_label.add_theme_font_size_override("font_size", 18)
	parent.add_child(controls_label)
	
	var controls_container = HBoxContainer.new()
	parent.add_child(controls_container)
	
	# Add exploration goal button
	var explore_btn = Button.new()
	explore_btn.text = "Add Exploration Goal"
	explore_btn.pressed.connect(_on_explore_button_pressed)
	controls_container.add_child(explore_btn)
	
	# Add survival goal button
	var survival_btn = Button.new()
	survival_btn.text = "Add Survival Goal"
	survival_btn.pressed.connect(_on_survival_button_pressed)
	controls_container.add_child(survival_btn)
	
	# Close button
	var close_btn = Button.new()
	close_btn.text = "Close Debug"
	close_btn.pressed.connect(_on_close_button_pressed)
	controls_container.add_child(close_btn)

func _process(delta):
	update_timer += delta
	if update_timer >= update_interval:
		_update_debug_info()
		update_timer = 0.0

func _update_debug_info():
	if not brain_system:
		return
	
	# Update Strategic Brain info
	if brain_system.strategic_brain:
		var strategic = brain_system.strategic_brain
		_update_label("strategic_goals", "Goals: %d" % strategic.goals.size())
		
		if strategic.goals.size() > 0:
			var top_goal = strategic.goals[0]
			_update_label("strategic_top_goal", "Top Goal: %s (%.2f)" % [top_goal.description, top_goal.priority])
		else:
			_update_label("strategic_top_goal", "Top Goal: None")
		
		if strategic.memory:
			_update_label("strategic_memory_count", "Memories: %d" % strategic.memory.memories.size())
	
	# Update Tactical Brain info
	if brain_system.tactical_brain:
		var tactical = brain_system.tactical_brain
		_update_label("tactical_state", "State: %s" % tactical.current_state)
		
		if tactical.current_command:
			_update_label("tactical_command", "Current Command: %s" % tactical.current_command.type)
		else:
			_update_label("tactical_command", "Current Command: None")
		
		if tactical.perception_data:
			_update_label("tactical_perception", "Visible NPCs: %d" % tactical.perception_data.visible_npcs.size())
	
	# Update Performance info
	if brain_system.brain_synchronizer:
		var stats = brain_system.brain_synchronizer.get_sync_stats()
		_update_label("sync_rate", "Sync Count: %d" % stats.sync_count)
		_update_label("sync_success", "Success Rate: %.1f%%" % stats.success_rate)

func _update_label(key: String, text: String):
	if key in info_labels:
		info_labels[key].text = text

func _on_explore_button_pressed():
	if brain_system and brain_system.npc_owner:
		var target = brain_system.npc_owner.global_position + Vector3(randf_range(-10, 10), 0, randf_range(-10, 10))
		brain_system.add_exploration_goal(target)
		print("Added exploration goal to: ", target)

func _on_survival_button_pressed():
	if brain_system and brain_system.strategic_brain:
		var goal = StrategyGoal.new()
		goal.type = StrategyGoal.Type.SURVIVAL
		goal.priority = 1.0
		goal.description = "Focus on survival"
		brain_system.strategic_brain.add_goal(goal)
		print("Added survival goal")

func _on_close_button_pressed():
	visible = false
