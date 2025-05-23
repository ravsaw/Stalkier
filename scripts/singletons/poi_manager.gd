# scripts/singletons/poi_manager.gd
extends Node

# === LOKACJE ===
var all_pois: Array[POI] = []
var pois_by_id: Dictionary = {}  # poi_id -> POI
var pois_by_type: Dictionary = {}  # POIType -> Array[POI]

func _ready():
	print("POIManager initialized")
	create_world_pois()

func _process(delta: float):
	# Update all POIs
	for poi in all_pois:
		poi.update(delta)

func create_world_pois():
	# Create 20 POIs as per GDD
	
	# === GŁÓWNE BAZY (4) ===
	create_poi("Main Base", Vector2(50, 50), POI.POIType.MAIN_BASE)
	create_poi("Military Post", Vector2(50, 10), POI.POIType.MILITARY_POST)
	create_poi("Civilian Settlement", Vector2(90, 50), POI.POIType.CIVILIAN_SETTLEMENT)
	create_poi("Stalker Hideout", Vector2(50, 90), POI.POIType.STALKER_HIDEOUT)
	
	# === STREFY ANOMALII (4) ===
	create_poi("Hell Zone", Vector2(20, 20), POI.POIType.ANOMALY_ZONE)
	create_poi("Whirlwind", Vector2(80, 20), POI.POIType.ANOMALY_ZONE)
	create_poi("Swamp", Vector2(20, 80), POI.POIType.ANOMALY_ZONE)
	create_poi("Storm", Vector2(80, 80), POI.POIType.ANOMALY_ZONE)
	
	# === MAŁE OBOZOWISKA (4) ===
	create_poi("Roadside Camp", Vector2(35, 35), POI.POIType.SMALL_CAMP)
	create_poi("Watchtower", Vector2(65, 35), POI.POIType.ABANDONED_POST)
	create_poi("Forest Hut", Vector2(35, 65), POI.POIType.SMALL_CAMP)
	create_poi("Stalker Camp", Vector2(65, 65), POI.POIType.SMALL_CAMP)
	
	# === PUNKTY HANDLOWE (3) ===
	create_poi("Bridge Market", Vector2(50, 30), POI.POIType.TRADING_POST)
	create_poi("Gas Station", Vector2(30, 50), POI.POIType.TRADING_POST)
	create_poi("Open Market", Vector2(70, 50), POI.POIType.TRADING_POST)
	
	# === MIEJSCA ZAGROŻEŃ (3) ===
	create_poi("Mutant Lair", Vector2(15, 50), POI.POIType.RESOURCE_POINT)
	create_poi("Factory Ruins", Vector2(50, 70), POI.POIType.INDUSTRIAL_RUINS)
	create_poi("Machine Graveyard", Vector2(85, 50), POI.POIType.INDUSTRIAL_RUINS)
	
	# === MIEJSCA ZASOBÓW (2) ===
	create_poi("Old Mine", Vector2(25, 25), POI.POIType.RESOURCE_POINT)
	create_poi("Secret Lab", Vector2(75, 75), POI.POIType.RESOURCE_POINT)
	
	print("Created %d POIs" % all_pois.size())
	
	# Initialize resources for POIs
	initialize_poi_resources()

func create_poi(poi_name: String, position: Vector2, type: int) -> POI:
	var poi = POI.new()
	poi.name = poi_name
	poi.position = position * 4
	poi.poi_type = type
	poi.setup_slots_for_type()
	
	add_poi(poi)
	return poi

func add_poi(poi: POI):
	all_pois.append(poi)
	pois_by_id[poi.poi_id] = poi
	
	# Add to type dictionary
	if not poi.poi_type in pois_by_type:
		pois_by_type[poi.poi_type] = []
	pois_by_type[poi.poi_type].append(poi)

func get_poi_by_id(poi_id: String) -> POI:
	return pois_by_id.get(poi_id, null)

func get_all_pois() -> Array[POI]:
	return all_pois

func get_pois_by_type(type: int) -> Array[POI]:
	return pois_by_type.get(type, [])

func find_nearest_poi(position: Vector2, filter_func: Callable = Callable()) -> POI:
	var nearest: POI = null
	var min_distance: float = INF
	
	for poi in all_pois:
		if filter_func.is_valid() and not filter_func.call(poi):
			continue
		
		var distance = position.distance_to(poi.position)
		if distance < min_distance:
			min_distance = distance
			nearest = poi
	
	return nearest

func find_nearest_with_resource(position: Vector2, resource_type: String) -> POI:
	return find_nearest_poi(position, func(poi): return poi.has_resource(resource_type))

func find_nearest_with_slot(position: Vector2, slot_type: int) -> POI:
	return find_nearest_poi(position, func(poi): return poi.get_available_slots_count(slot_type) > 0)

func find_nearest_anomaly_zone(position: Vector2) -> POI:
	return find_nearest_poi(position, func(poi): return poi.poi_type == POI.POIType.ANOMALY_ZONE)

func find_nearest_bar(position: Vector2) -> POI:
	return find_nearest_poi(position, func(poi): return poi.slots.has(POI.SlotType.BAR_PATRON))

func find_nearest_trading_post(position: Vector2) -> POI:
	return find_nearest_poi(position, func(poi): return poi.poi_type == POI.POIType.TRADING_POST)

func find_nearest_safe_base(position: Vector2) -> POI:
	var safe_types = [POI.POIType.MAIN_BASE, POI.POIType.CIVILIAN_SETTLEMENT, POI.POIType.STALKER_HIDEOUT]
	return find_nearest_poi(position, func(poi): return poi.poi_type in safe_types)

# === RESOURCE MANAGEMENT ===
func request_resource(poi: POI, requester: NPC, resource_type: String) -> bool:
	if not poi.has_resource(resource_type):
		return false
	
	# Simple resource consumption
	return poi.consume_resource(resource_type, 1)

func request_slot(poi: POI, requester: NPC, slot_type: int) -> POI.Slot:
	var slot = poi.request_slot(requester, slot_type)
	if slot:
		# NPC needs to actually occupy the slot
		if poi.occupy_slot(requester, slot):
			return slot
	return null

# === INITIALIZATION ===
func initialize_poi_resources():
	for poi in all_pois:
		match poi.poi_type:
			POI.POIType.MAIN_BASE:
				poi.available_resources["food"] = 50
				poi.available_resources["water"] = 50
				poi.available_resources["medical"] = 20
				poi.available_resources["ammo"] = 30
				
			POI.POIType.CIVILIAN_SETTLEMENT:
				poi.available_resources["food"] = 30
				poi.available_resources["water"] = 40
				poi.available_resources["medical"] = 10
				
			POI.POIType.MILITARY_POST:
				poi.available_resources["ammo"] = 50
				poi.available_resources["medical"] = 15
				poi.available_resources["food"] = 20
				
			POI.POIType.TRADING_POST:
				poi.available_resources["food"] = 20
				poi.available_resources["ammo"] = 20
				poi.available_resources["medical"] = 10
				
			POI.POIType.ANOMALY_ZONE:
				poi.available_resources["artifacts"] = 5
				
			POI.POIType.RESOURCE_POINT:
				poi.available_resources["food"] = 10
				poi.available_resources["artifacts"] = 3

# === STATISTICS ===
func get_poi_statistics() -> Dictionary:
	var stats = {
		"total_pois": all_pois.size(),
		"average_occupancy": 0.0,
		"controlled_pois": 0,
		"by_type": {}
	}
	
	var total_occupancy = 0.0
	
	for poi in all_pois:
		total_occupancy += poi.get_occupancy_rate()
		
		if poi.controlling_group:
			stats["controlled_pois"] += 1
		
		# Count by type
		if not poi.poi_type in stats["by_type"]:
			stats["by_type"][poi.poi_type] = 0
		stats["by_type"][poi.poi_type] += 1
	
	if all_pois.size() > 0:
		stats["average_occupancy"] = total_occupancy / all_pois.size() * 100.0
	
	return stats
