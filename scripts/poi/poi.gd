# scripts/poi/poi.gd
class_name POI
extends RefCounted

# === IDENTYFIKACJA ===
var poi_id: String
var name: String
var position: Vector2
var poi_type: int = POIType.SMALL_CAMP

# === SLOTY ===
var slots: Dictionary = {}  # SlotType -> Array of slots
var total_capacity: int = 0

# === KONTROLA ===
var controlling_group: Group = null
var control_strength: float = 0.0

# === ZASOBY ===
var available_resources: Dictionary = {
	"food": 0,
	"water": 0,
	"medical": 0,
	"ammo": 0,
	"artifacts": 0
}

# === HANDEL ===
var trade_prices: Dictionary = {}  # item_id -> price
var is_trading_post: bool = false

enum POIType {
	MAIN_BASE,        # Główna baza
	MILITARY_POST,    # Posterunek wojskowy
	CIVILIAN_SETTLEMENT, # Osada cywilna
	STALKER_HIDEOUT,  # Kryjówka stalkerów
	ANOMALY_ZONE,     # Strefa anomalii
	SMALL_CAMP,       # Mały obóz
	ABANDONED_POST,   # Opuszczony posterunek
	TRADING_POST,     # Punkt handlowy
	INDUSTRIAL_RUINS, # Ruiny przemysłowe
	RESOURCE_POINT    # Punkt zasobów
}

enum SlotType {
	LEADER,           # 1 slot dla lidera
	TRADER,           # 1 slot dla handlarza
	GUARD,            # 2-6 slotów dla strażników
	BAR_PATRON,       # 3-15 miejsc w barze
	SLEEPING_AREA,    # 5-20 miejsc do spania
	WORKSHOP,         # 1-3 miejsca warsztatowe
	STORAGE,          # 2-5 miejsc magazynowych
	VISITOR          # 10-30 miejsc dla gości
}

class Slot extends RefCounted:
	var type: int
	var occupant: NPC = null
	var reserved_by: NPC = null
	var reservation_time: float = 0.0
	
	func is_available() -> bool:
		return occupant == null and reserved_by == null
	
	func reserve(npc: NPC) -> bool:
		if not is_available():
			return false
		reserved_by = npc
		reservation_time = Time.get_unix_time_from_system()
		return true
	
	func occupy(npc: NPC) -> bool:
		if occupant != null:
			return false
		if reserved_by != null and reserved_by != npc:
			return false
		occupant = npc
		reserved_by = null
		return true
	
	func free():
		occupant = null
		reserved_by = null

func _init():
	poi_id = generate_unique_id()

func generate_unique_id() -> String:
	return "poi_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

func setup_slots_for_type():
	slots.clear()
	
	match poi_type:
		POIType.MAIN_BASE:
			add_slots(SlotType.LEADER, 1)
			add_slots(SlotType.TRADER, 2)
			add_slots(SlotType.GUARD, 6)
			add_slots(SlotType.BAR_PATRON, 15)
			add_slots(SlotType.SLEEPING_AREA, 20)
			add_slots(SlotType.WORKSHOP, 3)
			add_slots(SlotType.STORAGE, 5)
			add_slots(SlotType.VISITOR, 30)
			
		POIType.MILITARY_POST:
			add_slots(SlotType.LEADER, 1)
			add_slots(SlotType.GUARD, 4)
			add_slots(SlotType.SLEEPING_AREA, 10)
			add_slots(SlotType.STORAGE, 3)
			add_slots(SlotType.VISITOR, 5)
			
		POIType.CIVILIAN_SETTLEMENT:
			add_slots(SlotType.LEADER, 1)
			add_slots(SlotType.TRADER, 1)
			add_slots(SlotType.GUARD, 2)
			add_slots(SlotType.BAR_PATRON, 8)
			add_slots(SlotType.SLEEPING_AREA, 15)
			add_slots(SlotType.VISITOR, 20)
			
		POIType.SMALL_CAMP:
			add_slots(SlotType.GUARD, 1)
			add_slots(SlotType.SLEEPING_AREA, 5)
			add_slots(SlotType.VISITOR, 5)
			
		POIType.TRADING_POST:
			add_slots(SlotType.TRADER, 2)
			add_slots(SlotType.GUARD, 2)
			add_slots(SlotType.STORAGE, 4)
			add_slots(SlotType.VISITOR, 15)
			is_trading_post = true
			
		POIType.ANOMALY_ZONE:
			# Anomaly zones have no permanent slots
			add_slots(SlotType.VISITOR, 10)
			
		_:
			# Default small location
			add_slots(SlotType.VISITOR, 5)
	
	calculate_total_capacity()

func add_slots(type: int, count: int):
	if not type in slots:
		slots[type] = []
	
	for i in range(count):
		var slot = Slot.new()
		slot.type = type
		slots[type].append(slot)

func calculate_total_capacity():
	total_capacity = 0
	for slot_type in slots:
		total_capacity += slots[slot_type].size()

func request_slot(npc: NPC, slot_type: int) -> Slot:
	if not slot_type in slots:
		return null
	
	# Find available slot
	for slot in slots[slot_type]:
		if slot.is_available():
			if slot.reserve(npc):
				return slot
	
	return null

func occupy_slot(npc: NPC, slot: Slot) -> bool:
	if slot.occupy(npc):
		EventBus.emit_signal("poi_slot_occupied", self, slot.type, npc)
		return true
	return false

func free_slot(slot: Slot):
	var previous_occupant = slot.occupant
	slot.free()
	if previous_occupant:
		EventBus.emit_signal("poi_slot_freed", self, slot.type)

func get_occupancy_rate() -> float:
	if total_capacity == 0:
		return 0.0
	
	var occupied = 0
	for slot_type in slots:
		for slot in slots[slot_type]:
			if slot.occupant != null:
				occupied += 1
	
	return float(occupied) / total_capacity

func get_available_slots_count(slot_type: int = -1) -> int:
	var count = 0
	
	if slot_type == -1:
		# Count all available slots
		for type in slots:
			for slot in slots[type]:
				if slot.is_available():
					count += 1
	else:
		# Count specific type
		if slot_type in slots:
			for slot in slots[slot_type]:
				if slot.is_available():
					count += 1
	
	return count

func has_resource(resource_type: String) -> bool:
	return resource_type in available_resources and available_resources[resource_type] > 0

func consume_resource(resource_type: String, amount: int) -> bool:
	if not has_resource(resource_type):
		return false
	
	if available_resources[resource_type] >= amount:
		available_resources[resource_type] -= amount
		return true
	
	return false

func add_resource(resource_type: String, amount: int):
	if resource_type in available_resources:
		available_resources[resource_type] += amount

func set_control(group: Group, strength: float):
	var old_controller = controlling_group
	controlling_group = group
	control_strength = clamp(strength, 0.0, 1.0)
	
	if old_controller != group:
		EventBus.emit_signal("poi_control_changed", self, old_controller, group)

func get_type_name() -> String:
	match poi_type:
		POIType.MAIN_BASE: return "Main Base"
		POIType.MILITARY_POST: return "Military Post"
		POIType.CIVILIAN_SETTLEMENT: return "Civilian Settlement"
		POIType.STALKER_HIDEOUT: return "Stalker Hideout"
		POIType.ANOMALY_ZONE: return "Anomaly Zone"
		POIType.SMALL_CAMP: return "Small Camp"
		POIType.ABANDONED_POST: return "Abandoned Post"
		POIType.TRADING_POST: return "Trading Post"
		POIType.INDUSTRIAL_RUINS: return "Industrial Ruins"
		POIType.RESOURCE_POINT: return "Resource Point"
		_: return "Unknown"

func update(delta: float):
	# Update reservations (expire after 5 minutes)
	var current_time = Time.get_unix_time_from_system()
	for slot_type in slots:
		for slot in slots[slot_type]:
			if slot.reserved_by and current_time - slot.reservation_time > 300:
				slot.reserved_by = null  # Expire reservation
	
	# Regenerate resources slowly
	if poi_type != POIType.ANOMALY_ZONE:
		for resource in available_resources:
			if available_resources[resource] < 100:
				available_resources[resource] += delta * 0.1  # Slow regeneration

func to_dict() -> Dictionary:
	return {
		"poi_id": poi_id,
		"name": name,
		"type": poi_type,
		"position": {"x": position.x, "y": position.y},
		"occupancy_rate": get_occupancy_rate(),
		"controller": controlling_group.name if controlling_group else "None",
		"resources": available_resources
	}
