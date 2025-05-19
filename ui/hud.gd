# Simple HUD
extends Control
class_name HUD

# References to UI elements
@onready var health_bar = $HealthBar
@onready var ammo_display = $AmmoDisplay
@onready var weapon_name = $WeaponName
@onready var crosshair = $Crosshair
@onready var location_name_label = $LocationNameLabel
@onready var interact_prompt = $InteractPrompt

# Game references
@onready var player = $"/root/Game/Player"
@onready var weapon_manager = $"/root/Game/Player/WeaponManager"
@onready var location_manager = $"/root/Game/LocationManager"

func _ready():
	# Connect signals
	player.connect("health_changed", update_health_display)
	weapon_manager.connect("weapon_switched", update_weapon_display)
	weapon_manager.connect("weapon_reloaded", update_ammo_display)
	weapon_manager.connect("weapon_fired", update_ammo_after_firing)
	location_manager.connect("location_changed", update_location_name)
	
	# Initial updates
	update_health_display(player.health, player.max_health)
	update_location_name(location_manager.current_location, location_manager.current_location)
	
	# Hide interact prompt initially
	interact_prompt.hide()

func update_health_display(current_health: float, max_health: float):
	health_bar.max_value = max_health
	health_bar.value = current_health
	
	# Change color based on health
	if current_health < max_health * 0.25:
		health_bar.modulate = Color(1, 0, 0)  # Red
	elif current_health < max_health * 0.5:
		health_bar.modulate = Color(1, 0.5, 0)  # Orange
	else:
		health_bar.modulate = Color(0, 1, 0)  # Green

func update_weapon_display(weapon_name_str: String, ammo_data: Dictionary):
	weapon_name.text = weapon_name_str
	update_ammo_display(weapon_name_str, ammo_data)

func update_ammo_display(_weapon_name: String, ammo_data: Dictionary):
	var current = ammo_data.get("current", 0)
	var reserve = ammo_data.get("reserve", 0)
	ammo_display.text = "%d / %d" % [current, reserve]

func update_ammo_after_firing(_weapon_name: String):
	# Just update display based on current weapon data
	if weapon_manager.current_weapon:
		update_ammo_display(weapon_manager.current_weapon.weapon_name, {
			"current": weapon_manager.current_weapon.current_ammo,
			"reserve": weapon_manager.current_weapon.reserve_ammo
		})

func update_location_name(_from_location: String, to_location: String):
	# Show location name
	location_name_label.text = to_location
	
	# Animate showing the name
	location_name_label.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(location_name_label, "modulate:a", 1.0, 0.5)
	tween.tween_interval(2.0)
	tween.tween_property(location_name_label, "modulate:a", 0.0, 0.5)

func show_interact_prompt(action_text: String):
	interact_prompt.text = "Press E to %s" % action_text
	interact_prompt.show()

func hide_interact_prompt():
	interact_prompt.hide()
