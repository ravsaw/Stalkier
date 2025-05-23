# scripts/singletons/event_bus.gd
extends Node

# === NPC EVENTS ===
signal npc_spawned(npc: NPC)
signal npc_died(npc: NPC, killer: NPC)
signal npc_joined_group(npc: NPC, group: Group)
signal npc_left_group(npc: NPC, group: Group)
signal npc_need_critical(npc: NPC, need_type: int)

# === GROUP EVENTS ===
signal group_formed(group: Group)
signal group_dissolved(group: Group)
signal group_goal_changed(group: Group, new_goal)

# === COMBAT EVENTS ===
signal combat_started(attacker: Group, defender: Group)
signal combat_ended(result: Dictionary)
signal revenge_declared(victim: Group, target: Group)

# === POI EVENTS ===
signal poi_control_changed(poi: POI, old_controller: Group, new_controller: Group)
signal poi_slot_occupied(poi: POI, slot_type: int, occupant: NPC)
signal poi_slot_freed(poi: POI, slot_type: int)

# === ECONOMY EVENTS ===
signal trade_completed(buyer: NPC, seller: NPC, item_id: String, price: int)
signal item_price_changed(item_id: String, old_price: int, new_price: int)

# === WORLD EVENTS ===
signal day_passed(day: int)
signal population_changed(old_count: int, new_count: int)
