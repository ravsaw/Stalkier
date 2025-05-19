# Weapon manager - supports primary/secondary weapons
extends Node3D
class_name WeaponManager

@export var start_with_weapons: Array[PackedScene] = []
@export var max_primary_weapons: int = 1
@export var max_secondary_weapons: int = 2

var current_weapon: Weapon = null
var current_slot: String = ""
var weapons: Dictionary = {
	"primary": [],
	"secondary": []
}

signal weapon_fired(weapon_name)
signal weapon_switched(weapon_name, ammo_data)
signal weapon_reloaded(weapon_name, ammo_data)

func _ready():
	# Spawn starting weapons
	for weapon_scene in start_with_weapons:
		var weapon = weapon_scene.instantiate() as Weapon
		if weapon:
			pickup_weapon(weapon)
	
	# Equip first available weapon
	if weapons.primary.size() > 0:
		switch_to_weapon(weapons.primary[0], "primary")
	elif weapons.secondary.size() > 0:
		switch_to_weapon(weapons.secondary[0], "secondary")

func pickup_weapon(weapon: Weapon) -> bool:
	# Check weapon slot type and if there's room
	if weapon.weapon_class == Weapon.WeaponClass.LONG:
		if weapons.primary.size() >= max_primary_weapons:
			return false
		weapons.primary.append(weapon)
	else:
		if weapons.secondary.size() >= max_secondary_weapons:
			return false
		weapons.secondary.append(weapon)
	
	# Setup weapon but hide it initially
	add_child(weapon)
	weapon.hide()
	weapon.connect("ammo_changed", update_ammo_ui)
	
	return true

func switch_to_weapon(weapon: Weapon, slot: String) -> void:
	# Hide current weapon
	if current_weapon:
		current_weapon.on_unequip()
		current_weapon.hide()
	
	# Show and setup new weapon
	current_weapon = weapon
	current_slot = slot
	weapon.show()
	weapon.on_equip()
	
	# Notify UI
	emit_signal("weapon_switched", weapon.weapon_name, {
		"current": weapon.current_ammo,
		"reserve": weapon.reserve_ammo,
		"max": weapon.max_ammo
	})

func switch_to_next_weapon() -> void:
	if current_slot == "primary" and weapons.secondary.size() > 0:
		switch_to_weapon(weapons.secondary[0], "secondary")
	elif current_slot == "secondary" and weapons.primary.size() > 0:
		switch_to_weapon(weapons.primary[0], "primary")

func fire() -> void:
	if current_weapon:
		var did_fire = current_weapon.fire()
		if did_fire:
			emit_signal("weapon_fired", current_weapon.weapon_name)

func reload() -> void:
	if current_weapon:
		var did_reload = await current_weapon.reload()
		if did_reload:
			emit_signal("weapon_reloaded", current_weapon.weapon_name, {
				"current": current_weapon.current_ammo,
				"reserve": current_weapon.reserve_ammo,
				"max": current_weapon.max_ammo
			})

func update_ammo_ui() -> void:
	if current_weapon:
		emit_signal("weapon_switched", current_weapon.weapon_name, {
			"current": current_weapon.current_ammo,
			"reserve": current_weapon.reserve_ammo,
			"max": current_weapon.max_ammo
		})
