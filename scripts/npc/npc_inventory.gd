# scripts/npc/npc_inventory.gd
class_name NPCInventory
extends RefCounted

var owner_npc: NPC

# === EKWIPUNEK ===
var equipped_weapon: String = ""
var equipped_armor: String = ""
var items: Dictionary = {}  # item_id -> quantity
var money: int = 100

# === WAGA ===
var current_weight: float = 0.0
var max_weight: float = 50.0

func add_item(item_id: String, quantity: int = 1) -> bool:
	var item_weight = ItemDatabase.get_item_weight(item_id) * quantity
	
	if current_weight + item_weight > max_weight:
		return false  # Too heavy
	
	if item_id in items:
		items[item_id] += quantity
	else:
		items[item_id] = quantity
	
	current_weight += item_weight
	return true

func remove_item(item_id: String, quantity: int = 1) -> bool:
	if not item_id in items:
		return false
	
	if items[item_id] < quantity:
		return false
	
	items[item_id] -= quantity
	if items[item_id] <= 0:
		items.erase(item_id)
	
	var item_weight = ItemDatabase.get_item_weight(item_id) * quantity
	current_weight -= item_weight
	
	return true

func has_item(item_id: String, quantity: int = 1) -> bool:
	return item_id in items and items[item_id] >= quantity

func equip_weapon(item_id: String) -> bool:
	if not has_item(item_id):
		return false
	
	if not ItemDatabase.is_weapon(item_id):
		return false
	
	# Unequip current weapon
	if equipped_weapon != "":
		add_item(equipped_weapon, 1)
	
	equipped_weapon = item_id
	remove_item(item_id, 1)
	
	return true

func equip_armor(item_id: String) -> bool:
	if not has_item(item_id):
		return false
	
	if not ItemDatabase.is_armor(item_id):
		return false
	
	# Unequip current armor
	if equipped_armor != "":
		add_item(equipped_armor, 1)
	
	equipped_armor = item_id
	remove_item(item_id, 1)
	
	return true

func get_equipment_modifier() -> float:
	var modifier = 1.0
	
	# Weapon modifier
	if equipped_weapon != "":
		modifier *= ItemDatabase.get_weapon_effectiveness(equipped_weapon)
	else:
		modifier *= 0.5  # Unarmed penalty
	
	# Armor modifier
	if equipped_armor != "":
		modifier *= ItemDatabase.get_armor_protection(equipped_armor)
	
	return modifier

func calculate_total_value() -> int:
	var total = money
	
	# Add equipped items value
	if equipped_weapon != "":
		total += ItemDatabase.get_item_value(equipped_weapon)
	if equipped_armor != "":
		total += ItemDatabase.get_item_value(equipped_armor)
	
	# Add inventory items value
	for item_id in items:
		total += ItemDatabase.get_item_value(item_id) * items[item_id]
	
	return total

func add_money(amount: int):
	money += amount

func remove_money(amount: int) -> bool:
	if money >= amount:
		money -= amount
		return true
	return false

func is_overloaded() -> bool:
	return current_weight > max_weight

func get_weight_penalty() -> float:
	if not is_overloaded():
		return 0.0
	
	var excess = current_weight - max_weight
	return min(0.5, excess * 0.02)  # Max 50% speed penalty

# Simplified Item Database
class ItemDatabase:
	static var items = {
		# Weapons
		"pistol": {"weight": 1.0, "value": 300, "type": "weapon", "effectiveness": 1.2},
		"rifle": {"weight": 3.5, "value": 1500, "type": "weapon", "effectiveness": 1.8},
		"shotgun": {"weight": 4.0, "value": 800, "type": "weapon", "effectiveness": 1.6},
		
		# Armor
		"leather_jacket": {"weight": 2.0, "value": 200, "type": "armor", "protection": 1.2},
		"military_vest": {"weight": 6.0, "value": 800, "type": "armor", "protection": 1.5},
		"stalker_suit": {"weight": 4.0, "value": 1200, "type": "armor", "protection": 1.4},
		
		# Consumables
		"bread": {"weight": 0.5, "value": 50, "type": "food"},
		"canned_food": {"weight": 0.8, "value": 100, "type": "food"},
		"medkit": {"weight": 1.0, "value": 300, "type": "medical"},
		"bandage": {"weight": 0.2, "value": 100, "type": "medical"},
		
		# Artifacts
		"battery": {"weight": 0.3, "value": 2000, "type": "artifact"},
		"moonlight": {"weight": 0.2, "value": 5000, "type": "artifact"},
		
		# Ammo
		"pistol_ammo": {"weight": 0.01, "value": 5, "type": "ammo"},
		"rifle_ammo": {"weight": 0.015, "value": 8, "type": "ammo"}
	}
	
	static func get_item_weight(item_id: String) -> float:
		if item_id in items:
			return items[item_id].weight
		return 1.0
	
	static func get_item_value(item_id: String) -> int:
		if item_id in items:
			return items[item_id].value
		return 10
	
	static func is_weapon(item_id: String) -> bool:
		return item_id in items and items[item_id].type == "weapon"
	
	static func is_armor(item_id: String) -> bool:
		return item_id in items and items[item_id].type == "armor"
	
	static func get_weapon_effectiveness(item_id: String) -> float:
		if item_id in items and items[item_id].type == "weapon":
			return items[item_id].effectiveness
		return 1.0
	
	static func get_armor_protection(item_id: String) -> float:
		if item_id in items and items[item_id].type == "armor":
			return items[item_id].protection
		return 1.0
