extends Control
class_name DebugInfo

@onready var fps_label: Label = $Performance/FPSLabel
@onready var memory_label: Label = $Performance/MemoryLabel
@onready var npc_count_label: Label = $NPCCount
@onready var location_info_label: Label = $LocationInfo

func _ready():
	# Make debug panel initially visible
	visible = true

func _process(delta):
	update_debug_info()

func update_debug_info():
	fps_label.text = "FPS: " + str(Engine.get_frames_per_second())
	memory_label.text = "Memory: " + str(OS.get_static_memory_usage()) + " bytes"
	
	var npc_manager = get_tree().get_first_node_in_group("npc_manager")
	if npc_manager and npc_manager.has_method("get_npc_count"):
		npc_count_label.text = "NPCs: " + str(npc_manager.get_npc_count())
	else:
		npc_count_label.text = "NPCs: 0"
		
	location_info_label.text = "Locations: " + str(GameGlobals.world_manager.locations.size())
