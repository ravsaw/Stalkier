# scripts/singletons/economy_manager.gd
extends Node

# === PRICES ===
var base_prices: Dictionary = {}
var current_prices: Dictionary = {}
var price_history: Dictionary = {}  # item_id -> Array of price snapshots

# === CONFIGURATION ===
@export var price_fluctuation_rate: float = 0.1  # 10% max daily fluctuation
@export var scarcity_multiplier: float = 2.0     # Price multiplier when scarce
@export var abundance_divisor: float = 2.0       # Price divisor when abundant

# === TRADE TRACKING ===
var daily_trades: Array = []
var total_money_in_circulation: int = 0

func _ready():
	print("EconomyManager initialized")
	initialize_base_prices()
	calculate_initial_money_supply()

func initialize_base_prices():
	# Weapons
	base_prices["pistol"] = 300
	base_prices["rifle"] = 1500
	base_prices["shotgun"] = 800
	
	# Armor
	base_prices["leather_jacket"] = 200
	base_prices["military_vest"] = 800
	base_prices["stalker_suit"] = 1200
	
	# Consumables
	base_prices["bread"] = 50
	base_prices["canned_food"] = 100
	base_prices["medkit"] = 300
	base_prices["bandage"] = 100
	
	# Artifacts
	base_prices["battery"] = 2000
	base_prices["moonlight"] = 5000
	
	# Ammo
	base_prices["pistol_ammo"] = 5
	base_prices["rifle_ammo"] = 8
	
	# Initialize current prices as base prices
	for item_id in base_prices:
		current_prices[item_id] = base_prices[item_id]
		price_history[item_id] = []

func calculate_initial_money_supply():
	total_money_in_circulation = 0
	
	for npc in NPCManager.get_all_npcs():
		total_money_in_circulation += npc.inventory.money

func get_item_price(item_id: String, poi: POI = null) -> int:
	var base_price = current_prices.get(item_id, 100)
	
	# Apply POI-specific modifiers
	if poi and poi.is_trading_post:
		# Trading posts have slightly better prices
		base_price = int(base_price * 0.9)
	
	# Apply scarcity/abundance modifiers
	var supply_modifier = calculate_supply_modifier(item_id)
	base_price = int(base_price * supply_modifier)
	
	return max(1, base_price)

func calculate_supply_modifier(item_id: String) -> float:
	# Count how many of this item exist in the world
	var total_count = 0
	
	for npc in NPCManager.get_all_npcs():
		if npc.inventory.has_item(item_id):
			total_count += npc.inventory.items.get(item_id, 0)
	
	# Determine if scarce or abundant
	var expected_count = NPCManager.get_living_npc_count() * 0.5  # Expect half NPCs to have item
	
	if total_count < expected_count * 0.5:
		# Scarce - increase price
		return scarcity_multiplier
	elif total_count > expected_count * 2.0:
		# Abundant - decrease price
		return 1.0 / abundance_divisor
	else:
		# Normal supply
		return 1.0

func execute_trade(buyer: NPC, seller: NPC, item_id: String, quantity: int = 1) -> bool:
	if not seller.inventory.has_item(item_id, quantity):
		return false
	
	var price = get_item_price(item_id) * quantity
	
	if buyer.inventory.money < price:
		return false
	
	# Execute transaction
	buyer.inventory.remove_money(price)
	seller.inventory.add_money(price)
	
	seller.inventory.remove_item(item_id, quantity)
	buyer.inventory.add_item(item_id, quantity)
	
	# Record trade
	record_trade(buyer, seller, item_id, quantity, price)
	
	# Update price based on demand
	adjust_price_from_trade(item_id, quantity)
	
	EventBus.emit_signal("trade_completed", buyer, seller, item_id, price)
	
	return true

func record_trade(buyer: NPC, seller: NPC, item_id: String, quantity: int, total_price: int):
	var trade_record = {
		"timestamp": GameManager.game_time,
		"day": GameManager.game_day,
		"buyer_id": buyer.npc_id,
		"seller_id": seller.npc_id,
		"item_id": item_id,
		"quantity": quantity,
		"total_price": total_price,
		"unit_price": total_price / quantity
	}
	
	daily_trades.append(trade_record)
	
	# Clean old trades (keep last 7 days)
	daily_trades = daily_trades.filter(func(trade): 
		return GameManager.game_day - trade.day <= 7
	)

func adjust_price_from_trade(item_id: String, quantity: int):
	if not item_id in current_prices:
		return
	
	# Each trade slightly increases price (demand signal)
	var price_change = base_prices[item_id] * 0.01 * quantity  # 1% per item traded
	var old_price = current_prices[item_id]
	var new_price = old_price + price_change
	
	# Limit daily fluctuation
	var max_change = base_prices[item_id] * price_fluctuation_rate
	new_price = clamp(new_price, old_price - max_change, old_price + max_change)
	
	# Don't stray too far from base price
	new_price = clamp(new_price, base_prices[item_id] * 0.5, base_prices[item_id] * 3.0)
	
	current_prices[item_id] = int(new_price)
	
	if old_price != new_price:
		EventBus.emit_signal("item_price_changed", item_id, old_price, new_price)

func daily_price_update():
	# Natural price drift back toward base prices
	for item_id in current_prices:
		var current = current_prices[item_id]
		var base = base_prices[item_id]
		
		if current != base:
			# Drift 5% back toward base price
			var drift = (base - current) * 0.05
			current_prices[item_id] = int(current + drift)
		
		# Record price history
		price_history[item_id].append({
			"day": GameManager.game_day,
			"price": current_prices[item_id]
		})
		
		# Keep only last 30 days of history
		if price_history[item_id].size() > 30:
			price_history[item_id].pop_front()

func get_artifact_price_trend() -> float:
	# Calculate average artifact price vs base price
	var artifact_items = ["battery", "moonlight"]
	var total_ratio = 0.0
	var count = 0
	
	for item_id in artifact_items:
		if item_id in current_prices and item_id in base_prices:
			total_ratio += float(current_prices[item_id]) / base_prices[item_id]
			count += 1
	
	if count > 0:
		return (total_ratio / count) - 1.0  # Return as percentage change
	
	return 0.0

func get_economy_statistics() -> Dictionary:
	var stats = {
		"money_supply": total_money_in_circulation,
		"daily_trade_volume": daily_trades.size(),
		"average_prices": {},
		"price_trends": {}
	}
	
	# Calculate average prices by category
	var categories = {
		"weapons": ["pistol", "rifle", "shotgun"],
		"armor": ["leather_jacket", "military_vest", "stalker_suit"],
		"consumables": ["bread", "canned_food", "medkit", "bandage"],
		"artifacts": ["battery", "moonlight"]
	}
	
	for category in categories:
		var total = 0
		var count = 0
		for item_id in categories[category]:
			if item_id in current_prices:
				total += current_prices[item_id]
				count += 1
		
		if count > 0:
			stats["average_prices"][category] = total / count
	
	# Calculate price trends (current vs base)
	for item_id in current_prices:
		if item_id in base_prices:
			var trend = (float(current_prices[item_id]) / base_prices[item_id] - 1.0) * 100.0
			stats["price_trends"][item_id] = "%.1f%%" % trend
	
	return stats

# === NPC TRADING AI ===
func find_profitable_trades(npc: NPC) -> Array:
	var trades = []
	
	# Find nearby trading partners
	var nearby_npcs = NPCManager.find_npcs_in_radius(npc.position, 5.0)
	
	for other_npc in nearby_npcs:
		if other_npc == npc:
			continue
		
		# Check what npc can sell
		for item_id in npc.inventory.items:
			var sell_price = get_item_price(item_id)
			
			# Check if other NPC needs it and can afford it
			if other_npc.inventory.money >= sell_price:
				var profit_margin = calculate_profit_margin(npc, item_id, sell_price)
				if profit_margin > 0.1:  # 10% profit minimum
					trades.append({
						"partner": other_npc,
						"item_id": item_id,
						"action": "sell",
						"price": sell_price,
						"profit_margin": profit_margin
					})
		
		# Check what npc can buy
		for item_id in other_npc.inventory.items:
			var buy_price = get_item_price(item_id)
			
			if npc.inventory.money >= buy_price:
				var value_score = calculate_item_value_for_npc(npc, item_id)
				if value_score > 1.2:  # 20% more valuable than price
					trades.append({
						"partner": other_npc,
						"item_id": item_id,
						"action": "buy",
						"price": buy_price,
						"value_score": value_score
					})
	
	# Sort by profitability
	trades.sort_custom(func(a, b): 
		var score_a = a.get("profit_margin", 0) + a.get("value_score", 0)
		var score_b = b.get("profit_margin", 0) + b.get("value_score", 0)
		return score_a > score_b
	)
	
	return trades

func calculate_profit_margin(npc: NPC, item_id: String, sell_price: int) -> float:
	# Simple profit calculation - could be enhanced
	return 0.2  # 20% default margin

func calculate_item_value_for_npc(npc: NPC, item_id: String) -> float:
	# Determine how valuable an item is for this specific NPC
	var value = 1.0
	
	# Weapons more valuable for combat-oriented NPCs
	if NPCInventory.ItemDatabase.is_weapon(item_id):
		value *= (1.0 + npc.combat_skill / 100.0)
		if npc.inventory.equipped_weapon == "":
			value *= 1.5  # Unarmed NPCs value weapons more
	
	# Armor more valuable for those without
	if NPCInventory.ItemDatabase.is_armor(item_id):
		if npc.inventory.equipped_armor == "":
			value *= 2.0
	
	# Food more valuable when hungry
	if item_id in ["bread", "canned_food"]:
		value *= (2.0 - npc.needs[NPC.NPCNeed.HUNGER] / 100.0)
	
	# Medical supplies more valuable when injured
	if item_id in ["medkit", "bandage"]:
		value *= (2.0 - npc.health / 100.0)
	
	return value
