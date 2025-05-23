# scripts/ui/ui_controller.gd
extends Control

# === UI PANELS ===
@onready var time_label: Label = $TopBar/TimeLabel
@onready var day_label: Label = $TopBar/DayLabel
@onready var speed_label: Label = $TopBar/SpeedLabel
@onready var population_label: Label = $TopBar/PopulationLabel

@onready var selected_panel: Panel = $SelectedPanel
@onready var selected_name: Label = $SelectedPanel/VBox/NameLabel
@onready var selected_info: RichTextLabel = $SelectedPanel/VBox/InfoText
@onready var selected_needs: VBoxContainer = $SelectedPanel/VBox/NeedsContainer

@onready var statistics_panel: Panel = $StatisticsPanel
@onready var stats_text: RichTextLabel = $StatisticsPanel/StatsText

# === STATE ===
var selected_npc: NPC = null
var selected_group: Group = null
var selected_poi: POI = null

func _ready():
	# Connect to game events
	GameManager.connect("time_updated", _on_time_updated)
	GameManager.connect("day_passed", _on_day_passed)
	EventBus.connect("population_changed", _on_population_changed)
	
	# Hide panels initially
	selected_panel.visible = false
	statistics_panel.visible = false
	
	# Set up input
	set_process_unhandled_input(true)

func _process(_delta: float):
	# Update UI elements
	update_speed_label()
	
	# Update selected entity info
	if selected_npc:
		update_npc_info()
	elif selected_group:
		update_group_info()
	elif selected_poi:
		update_poi_info()

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("toggle_stats"):
		statistics_panel.visible = !statistics_panel.visible
		if statistics_panel.visible:
			update_statistics()
	
	if event.is_action_pressed("pause"):
		GameManager.toggle_pause()
	
	if event.is_action_pressed("speed_up"):
		GameManager.set_game_speed(min(10.0, GameManager.game_speed + 1.0))
	
	if event.is_action_pressed("speed_down"):
		GameManager.set_game_speed(max(0.0, GameManager.game_speed - 1.0))
	
	if event.is_action_pressed("deselect"):
		deselect_all()

func _on_time_updated(time: float, day: int):
	if time_label:
		time_label.text = GameManager.get_time_string()
	if day_label:
		day_label.text = "Day %d" % day

func _on_day_passed(day: int):
	# Could show notification
	pass

func _on_population_changed(old_count: int, new_count: int):
	if population_label:
		population_label.text = "Population: %d/%d" % [new_count, NPCManager.max_population]

func update_speed_label():
	if speed_label:
		if GameManager.is_paused:
			speed_label.text = "PAUSED"
		else:
			speed_label.text = "Speed: %.1fx" % GameManager.game_speed

func select_npc(npc: NPC):
	deselect_all()
	selected_npc = npc
	selected_panel.visible = true
	update_npc_info()

func select_group(group: Group):
	deselect_all()
	selected_group = group
	selected_panel.visible = true
	update_group_info()

func select_poi(poi: POI):
	deselect_all()
	selected_poi = poi
	selected_panel.visible = true
	update_poi_info()

func deselect_all():
	selected_npc = null
	selected_group = null
	selected_poi = null
	selected_panel.visible = false

func update_npc_info():
	if not selected_npc:
		return
	
	selected_name.text = selected_npc.name
	
	var info_text = ""
	info_text += "Age: %d\n" % selected_npc.age
	info_text += "Health: %d/100\n" % selected_npc.health
	info_text += "Group: %s\n" % (selected_npc.group.name if selected_npc.group else "None")
	info_text += "\n[b]Stats:[/b]\n"
	info_text += "Combat: %d | Trade: %d\n" % [selected_npc.combat_skill, selected_npc.trade_skill]
	info_text += "Leadership: %d | Survival: %d\n" % [selected_npc.leadership_skill, selected_npc.survival_skill]
	info_text += "\n[b]Personality:[/b]\n"
	info_text += "Morality: %d | Courage: %d\n" % [selected_npc.morality, selected_npc.courage]
	info_text += "Aggression: %d | Greed: %d\n" % [selected_npc.aggression, selected_npc.greed]
	info_text += "\n[b]Equipment:[/b]\n"
	info_text += "Weapon: %s\n" % (selected_npc.inventory.equipped_weapon if selected_npc.inventory.equipped_weapon else "None")
	info_text += "Armor: %s\n" % (selected_npc.inventory.equipped_armor if selected_npc.inventory.equipped_armor else "None")
	info_text += "Money: $%d\n" % selected_npc.inventory.money
	
	selected_info.text = info_text
	
	# Update needs display
	update_needs_display(selected_npc)

func update_needs_display(npc: NPC):
	# Clear existing needs
	for child in selected_needs.get_children():
		child.queue_free()
	
	# Create need bars
	var need_names = {
		NPC.NPCNeed.HUNGER: "Hunger",
		NPC.NPCNeed.SHELTER: "Shelter",
		NPC.NPCNeed.COMPANIONSHIP: "Social",
		NPC.NPCNeed.WEALTH: "Wealth",
		NPC.NPCNeed.EXPLORATION: "Exploration",
		NPC.NPCNeed.COMBAT: "Combat"
	}
	
	for need_type in npc.needs:
		var hbox = HBoxContainer.new()
		
		var label = Label.new()
		label.text = need_names[need_type]
		label.custom_minimum_size.x = 100
		hbox.add_child(label)
		
		var progress = ProgressBar.new()
		progress.value = npc.needs[need_type]
		progress.custom_minimum_size.x = 150
		
		# Color based on satisfaction level
		if npc.needs[need_type] < 20:
			progress.modulate = Color.RED
		elif npc.needs[need_type] < 50:
			progress.modulate = Color.YELLOW
		else:
			progress.modulate = Color.GREEN
		
		hbox.add_child(progress)
		
		selected_needs.add_child(hbox)

func update_group_info():
	if not selected_group:
		return
	
	selected_name.text = selected_group.name
	
	var info_text = ""
	info_text += "Specialization: %s\n" % selected_group.get_specialization_name()
	info_text += "Members: %d/%d\n" % [selected_group.get_member_count(), selected_group.max_size]
	info_text += "Leader: %s\n" % (selected_group.leader.name if selected_group.leader else "None")
	info_text += "Morale: %.0f/100\n" % selected_group.morale
	info_text += "Discipline: %.0f/100\n" % selected_group.discipline
	info_text += "\n[b]Members:[/b]\n"
	
	for member in selected_group.members:
		info_text += "- %s (HP: %d)\n" % [member.name, member.health]
	
	selected_info.text = info_text
	
	# Clear needs display for groups
	for child in selected_needs.get_children():
		child.queue_free()

func update_poi_info():
	if not selected_poi:
		return
	
	selected_name.text = selected_poi.name
	
	var info_text = ""
	info_text += "Type: %s\n" % selected_poi.get_type_name()
	info_text += "Occupancy: %.0f%%\n" % (selected_poi.get_occupancy_rate() * 100)
	info_text += "Controller: %s\n" % (selected_poi.controlling_group.name if selected_poi.controlling_group else "None")
	info_text += "\n[b]Resources:[/b]\n"
	
	for resource in selected_poi.available_resources:
		if selected_poi.available_resources[resource] > 0:
			info_text += "%s: %.0f\n" % [resource.capitalize(), selected_poi.available_resources[resource]]
	
	info_text += "\n[b]Available Slots:[/b]\n"
	for slot_type in selected_poi.slots:
		var available = selected_poi.get_available_slots_count(slot_type)
		var total = selected_poi.slots[slot_type].size()
		if total > 0:
			info_text += "%s: %d/%d\n" % [POI.SlotType.keys()[slot_type], available, total]
	
	selected_info.text = info_text
	
	# Clear needs display for POIs
	for child in selected_needs.get_children():
		child.queue_free()

func update_statistics():
	var stats = GameManager.get_world_statistics()
	var text = "[b]World Statistics[/b]\n\n"
	
	text += "[b]Population:[/b]\n"
	text += "Total: %d\n" % stats.population.total_population
	text += "Living: %d\n" % stats.population.living_count
	text += "Armed: %.1f%%\n" % stats.population.armed_percentage
	text += "Avg Health: %.1f\n" % stats.population.average_health
	text += "Avg Wealth: $%.0f\n" % stats.population.average_wealth
	
	text += "\n[b]Groups:[/b]\n"
	text += "Total: %d\n" % stats.groups.total_groups
	text += "Avg Size: %.1f\n" % stats.groups.average_size
	
	text += "\n[b]Locations:[/b]\n"
	text += "Total POIs: %d\n" % stats.pois.total_pois
	text += "Avg Occupancy: %.1f%%\n" % stats.pois.average_occupancy
	text += "Controlled: %d\n" % stats.pois.controlled_pois
	
	text += "\n[b]Economy:[/b]\n"
	text += "Money Supply: $%d\n" % stats.economy.money_supply
	text += "Daily Trades: %d\n" % stats.economy.daily_trade_volume
	
	text += "\n[b]Conflict:[/b]\n"
	text += "Intensity: %.1f%%\n" % (stats.conflict_intensity * 100)
	
	stats_text.text = text

# Input action mappings to add:
# toggle_stats: Tab
# pause: Space
# speed_up: Plus, Equals
# speed_down: Minus
# deselect: Escape
