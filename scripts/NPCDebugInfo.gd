extends Node2D
class_name NPCDebugInfo

@onready var debug_label: Label = $DebugLabel
@onready var needs_bars: VBoxContainer = $NeedsBars
@onready var npc_data: NPCData = $"../NPCData"

func _ready():
	#npc_data = get_parent().npc_data
	setup_needs_bars()

func setup_needs_bars():
	# Create progress bars for each need
	for need_name in npc_data.needs:
		var bar = ProgressBar.new()
		bar.name = need_name
		bar.min_value = 0.0
		bar.max_value = 1.0
		bar.show_percentage = false
		needs_bars.add_child(bar)
		
		var label = Label.new()
		label.text = need_name.capitalize()
		needs_bars.add_child(label)

func update_debug_display():
	if not npc_data:
		return
	
	# Update debug label
	debug_label.text = "State: " + npc_data.current_state + "\nPOI: " + npc_data.current_poi
	
	# Update needs bars
	for need_name in npc_data.needs:
		var bar = needs_bars.get_node(need_name)
		if bar:
			bar.value = npc_data.needs[need_name]
