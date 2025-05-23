# scripts/npc/npc_brain.gd
class_name NPCBrain
extends RefCounted

var owner_npc: NPC
var current_goal: Goal = null
var goal_queue: Array[Goal] = []
var decision_cooldown: float = 0.0
var decision_interval: float = 5.0  # Make decision every 5 seconds

# Goal types for MVP
enum GoalType {
	FIND_FOOD,
	FIND_SHELTER,
	JOIN_GROUP,
	SOCIALIZE,
	HUNT_ARTIFACTS,
	TRADE_ITEMS,
	EXPLORE_AREA,
	ENGAGE_COMBAT,
	REST
}

func update(delta: float):
	decision_cooldown -= delta
	
	if decision_cooldown <= 0:
		make_decision()
		decision_cooldown = decision_interval
	
	# Execute current goal
	if current_goal and current_goal.is_valid():
		current_goal.execute(owner_npc, delta)
		
		if current_goal.is_completed():
			complete_current_goal()

func make_decision():
	# Check if current goal is still valid
	if current_goal and current_goal.is_valid() and current_goal.priority > 50:
		return  # Keep executing high priority goal
	
	# Find most urgent need
	var urgent_need = owner_npc.get_most_urgent_need()
	
	if urgent_need != -1:
		# Create goal based on need
		var new_goal = create_goal_for_need(urgent_need)
		if new_goal:
			set_current_goal(new_goal)
	else:
		# No urgent needs, choose activity based on personality
		var activity_goal = choose_activity_goal()
		if activity_goal:
			set_current_goal(activity_goal)

func create_goal_for_need(need_type: int) -> Goal:
	var goal: Goal = null
	
	match need_type:
		NPC.NPCNeed.HUNGER:
			goal = FindFoodGoal.new()
		NPC.NPCNeed.SHELTER:
			goal = FindShelterGoal.new()
		NPC.NPCNeed.COMPANIONSHIP:
			goal = JoinGroupGoal.new()
		NPC.NPCNeed.WEALTH:
			goal = HuntArtifactsGoal.new()
		NPC.NPCNeed.EXPLORATION:
			goal = ExploreAreaGoal.new()
		NPC.NPCNeed.COMBAT:
			goal = EngageCombatGoal.new()
	
	if goal:
		goal.priority = 100 - owner_npc.needs[need_type]  # Lower satisfaction = higher priority
	
	return goal

func choose_activity_goal() -> Goal:
	# Choose based on personality
	var options: Array[Goal] = []
	
	if owner_npc.sociability > 60:
		options.append(SocializeGoal.new())
	
	if owner_npc.greed > 60:
		options.append(TradeGoal.new())
	
	if owner_npc.ambition > 60:
		options.append(HuntArtifactsGoal.new())
	
	if owner_npc.aggression > 60 and owner_npc.combat_skill > 40:
		options.append(EngageCombatGoal.new())
	
	# Default to exploration if no specific preference
	if options.is_empty():
		options.append(ExploreAreaGoal.new())
	
	return options[randi() % options.size()]

func set_current_goal(goal: Goal):
	if current_goal:
		current_goal.interrupt()
	
	current_goal = goal
	current_goal.start(owner_npc)

func complete_current_goal():
	if current_goal:
		current_goal = null
		
		# Pick next goal from queue or make new decision
		if not goal_queue.is_empty():
			set_current_goal(goal_queue.pop_front())
		else:
			decision_cooldown = 0  # Force immediate decision

# === SPECIFIC GOAL IMPLEMENTATIONS ===
class FindFoodGoal extends Goal:
	func _init():
		type = GoalType.FIND_FOOD
		priority = 80
	
	func start(npc: NPC):
		# Find nearest POI with food
		target_poi = POIManager.find_nearest_with_resource(npc.position, "food")
		if target_poi:
			npc.target_position = target_poi.position
	
	func execute(npc: NPC, delta: float):
		if not target_poi:
			completed = true
			return
		
		# Move towards POI
		if npc.position.distance_to(target_poi.position) < 1.0:
			# Arrived, try to get food
			if POIManager.request_resource(target_poi, npc, "food"):
				npc.satisfy_need(NPC.NPCNeed.HUNGER, 50)
				completed = true

class FindShelterGoal extends Goal:
	func _init():
		type = GoalType.FIND_SHELTER
		priority = 70
	
	func start(npc: NPC):
		# Find nearest POI with available shelter
		target_poi = POIManager.find_nearest_with_slot(npc.position, POI.SlotType.SLEEPING_AREA)
		if target_poi:
			npc.target_position = target_poi.position
	
	func execute(npc: NPC, delta: float):
		if not target_poi:
			completed = true
			return
		
		if npc.position.distance_to(target_poi.position) < 1.0:
			# Try to occupy shelter slot
			if POIManager.request_slot(target_poi, npc, POI.SlotType.SLEEPING_AREA):
				npc.satisfy_need(NPC.NPCNeed.SHELTER, 80)
				completed = true

class JoinGroupGoal extends Goal:
	var target_group: Group = null
	
	func _init():
		type = GoalType.JOIN_GROUP
		priority = 60
	
	func start(npc: NPC):
		if npc.group:
			completed = true
			return
		
		# Find nearby groups accepting members
		target_group = GroupManager.find_joinable_group(npc)
		if target_group and target_group.leader:
			npc.target_position = target_group.get_average_position()
	
	func execute(npc: NPC, delta: float):
		if not target_group or npc.group:
			completed = true
			return
		
		# Move towards group
		var group_pos = target_group.get_average_position()
		npc.target_position = group_pos
		
		if npc.position.distance_to(group_pos) < 3.0:
			# Try to join
			if GroupManager.request_join_group(npc, target_group):
				npc.satisfy_need(NPC.NPCNeed.COMPANIONSHIP, 60)
				completed = true

class HuntArtifactsGoal extends Goal:
	func _init():
		type = GoalType.HUNT_ARTIFACTS
		priority = 50
	
	func start(npc: NPC):
		# Find anomaly zone
		target_poi = POIManager.find_nearest_anomaly_zone(npc.position)
		if target_poi:
			npc.target_position = target_poi.position
	
	func execute(npc: NPC, delta: float):
		if not target_poi:
			completed = true
			return
		
		if npc.position.distance_to(target_poi.position) < 2.0:
			# Simulate artifact hunting
			if randf() < 0.1:  # 10% chance per update
				# Found artifact!
				var artifact_value = randi_range(500, 2000)
				npc.inventory.add_money(artifact_value)
				npc.satisfy_need(NPC.NPCNeed.WEALTH, 30)
				npc.satisfy_need(NPC.NPCNeed.EXPLORATION, 20)
				completed = true

class ExploreAreaGoal extends Goal:
	var exploration_radius: float = 10.0
	var start_position: Vector2
	
	func _init():
		type = GoalType.EXPLORE_AREA
		priority = 30
	
	func start(npc: NPC):
		start_position = npc.position
		# Pick random direction
		var angle = randf() * TAU
		var distance = randf_range(5, exploration_radius)
		npc.target_position = start_position + Vector2.from_angle(angle) * distance
	
	func execute(npc: NPC, delta: float):
		if npc.position.distance_to(npc.target_position) < 1.0:
			npc.satisfy_need(NPC.NPCNeed.EXPLORATION, 10)
			# Pick new exploration target
			var angle = randf() * TAU
			var distance = randf_range(5, exploration_radius)
			npc.target_position = npc.position + Vector2.from_angle(angle) * distance
			
			# Complete after some exploration
			if npc.position.distance_to(start_position) > exploration_radius * 2:
				completed = true

class SocializeGoal extends Goal:
	func _init():
		type = GoalType.SOCIALIZE
		priority = 40
	
	func start(npc: NPC):
		# Find nearest bar
		target_poi = POIManager.find_nearest_bar(npc.position)
		if target_poi:
			npc.target_position = target_poi.position
	
	func execute(npc: NPC, delta: float):
		if not target_poi:
			completed = true
			return
		
		if npc.position.distance_to(target_poi.position) < 1.0:
			# At bar, socialize
			npc.satisfy_need(NPC.NPCNeed.COMPANIONSHIP, 20)
			# Simulate spending time
			if randf() < 0.05:  # Stay for a while
				completed = true

class TradeGoal extends Goal:
	func _init():
		type = GoalType.TRADE_ITEMS
		priority = 45
	
	func start(npc: NPC):
		# Find trading post
		target_poi = POIManager.find_nearest_trading_post(npc.position)
		if target_poi:
			npc.target_position = target_poi.position
	
	func execute(npc: NPC, delta: float):
		if not target_poi:
			completed = true
			return
		
		if npc.position.distance_to(target_poi.position) < 1.0:
			# Simulate trading
			var profit = randi_range(-100, 300)
			npc.inventory.add_money(profit)
			if profit > 0:
				npc.satisfy_need(NPC.NPCNeed.WEALTH, 15)
			completed = true

class EngageCombatGoal extends Goal:
	func _init():
		type = GoalType.ENGAGE_COMBAT
		priority = 35
	
	func start(npc: NPC):
		# This is simplified - in full implementation would find enemies
		completed = true  # For now, just satisfy the need
		npc.satisfy_need(NPC.NPCNeed.COMBAT, 40)
