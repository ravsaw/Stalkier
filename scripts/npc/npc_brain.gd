# scripts/npc/npc_brain.gd
class_name NPCBrain
extends RefCounted

var owner_npc: NPC
var current_goal: Goal = null
var goal_queue: Array[Goal] = []
var decision_cooldown: float = 0.0
var decision_interval: float = 5.0  # Make decision every 5 seconds
var stuck_retries: int = 0
var max_stuck_retries: int = 3

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
	stuck_retries = 0  # Reset stuck counter for new goal

func complete_current_goal():
	if current_goal:
		current_goal = null
		
		# Pick next goal from queue or make new decision
		if not goal_queue.is_empty():
			set_current_goal(goal_queue.pop_front())
		else:
			decision_cooldown = 0  # Force immediate decision

func handle_navigation_stuck():
	stuck_retries += 1
	
	if stuck_retries >= max_stuck_retries:
		# Abandon current goal if stuck too many times
		if current_goal:
			current_goal.abandon()
			complete_current_goal()
		stuck_retries = 0

# === SPECIFIC GOAL IMPLEMENTATIONS ===
class FindFoodGoal extends Goal:
	var reached_poi: bool = false
	
	func _init():
		type = GoalType.FIND_FOOD
		priority = 80
	
	func start(npc: NPC):
		# Find nearest POI with food
		target_poi = POIManager.find_nearest_with_resource(npc.position, "food")
		if target_poi:
			# Check if POI is reachable
			if npc.can_reach_position(target_poi.position):
				npc.set_navigation_target(target_poi.position)
			else:
				# Find alternative POI
				var all_food_pois = POIManager.get_all_pois().filter(
					func(poi): return poi.has_resource("food")
				)
				for poi in all_food_pois:
					if npc.can_reach_position(poi.position):
						target_poi = poi
						npc.set_navigation_target(target_poi.position)
						break
	
	func execute(npc: NPC, delta: float):
		if not target_poi:
			completed = true
			return
		
		# Check if we've reached the POI
		if npc.position.distance_to(target_poi.position) < 4.0:
			if not reached_poi:
				reached_poi = true
				# Try to get food
				if POIManager.request_resource(target_poi, npc, "food"):
					npc.satisfy_need(NPC.NPCNeed.HUNGER, 50)
					completed = true
				else:
					# No food available, find another POI
					completed = true
		else:
			# Still navigating
			if not npc.is_navigating:
				# Repath if navigation stopped
				npc.set_navigation_target(target_poi.position)
	
	func handle_navigation_stuck():
		# Try to find alternative POI
		abandon()

class FindShelterGoal extends Goal:
	var reached_poi: bool = false
	
	func _init():
		type = GoalType.FIND_SHELTER
		priority = 70
	
	func start(npc: NPC):
		# Find nearest POI with available shelter
		target_poi = POIManager.find_nearest_with_slot(npc.position, POI.SlotType.SLEEPING_AREA)
		if target_poi and npc.can_reach_position(target_poi.position):
			npc.set_navigation_target(target_poi.position)
		else:
			# Find any safe POI
			target_poi = POIManager.find_nearest_safe_base(npc.position)
			if target_poi:
				npc.set_navigation_target(target_poi.position)
	
	func execute(npc: NPC, delta: float):
		if not target_poi:
			completed = true
			return
		
		if npc.position.distance_to(target_poi.position) < 4.0:
			if not reached_poi:
				reached_poi = true
				# Try to occupy shelter slot
				if POIManager.request_slot(target_poi, npc, POI.SlotType.SLEEPING_AREA):
					npc.satisfy_need(NPC.NPCNeed.SHELTER, 80)
					completed = true
				else:
					# No slots available
					completed = true
		else:
			if not npc.is_navigating:
				npc.set_navigation_target(target_poi.position)

class JoinGroupGoal extends Goal:
	var target_group: Group = null
	var approached_group: bool = false
	
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
			var group_pos = target_group.get_average_position()
			if npc.can_reach_position(group_pos):
				npc.set_navigation_target(group_pos)
			else:
				target_group = null
	
	func execute(npc: NPC, delta: float):
		if not target_group or npc.group:
			completed = true
			return
		
		# Update target position as group moves
		var group_pos = target_group.get_average_position()
		
		if npc.position.distance_to(group_pos) < 8.0:
			if not approached_group:
				approached_group = true
				# Try to join
				if GroupManager.request_join_group(npc, target_group):
					npc.satisfy_need(NPC.NPCNeed.COMPANIONSHIP, 60)
					completed = true
				else:
					completed = true
		else:
			# Keep following the group
			if not npc.is_navigating or npc.target_position.distance_to(group_pos) > 10.0:
				npc.set_navigation_target(group_pos)

class HuntArtifactsGoal extends Goal:
	var exploration_timer: float = 0.0
	var exploration_duration: float = 30.0  # Explore for 30 seconds
	
	func _init():
		type = GoalType.HUNT_ARTIFACTS
		priority = 50
	
	func start(npc: NPC):
		# Find anomaly zone
		target_poi = POIManager.find_nearest_anomaly_zone(npc.position)
		if target_poi and npc.can_reach_position(target_poi.position):
			npc.set_navigation_target(target_poi.position)
	
	func execute(npc: NPC, delta: float):
		if not target_poi:
			completed = true
			return
		
		exploration_timer += delta
		
		if npc.position.distance_to(target_poi.position) < 12.0:
			# In anomaly zone - explore around
			if exploration_timer > exploration_duration:
				completed = true
			elif not npc.is_navigating:
				# Pick random point near anomaly
				var random_offset = Vector2(
					randf_range(-20, 20),
					randf_range(-20, 20)
				)
				var explore_pos = target_poi.position + random_offset
				npc.set_navigation_target(explore_pos)
				
				# Chance to find artifact
				if randf() < 0.02:  # 2% chance per exploration
					var artifact_value = randi_range(500, 2000)
					npc.inventory.add_money(artifact_value)
					npc.satisfy_need(NPC.NPCNeed.WEALTH, 30)
					npc.satisfy_need(NPC.NPCNeed.EXPLORATION, 20)
					completed = true
		else:
			if not npc.is_navigating:
				npc.set_navigation_target(target_poi.position)

class ExploreAreaGoal extends Goal:
	var exploration_radius: float = 40.0
	var waypoints_visited: int = 0
	var max_waypoints: int = 5
	var current_waypoint: Vector2
	
	func _init():
		type = GoalType.EXPLORE_AREA
		priority = 30
	
	func start(npc: NPC):
		generate_new_waypoint(npc)
	
	func generate_new_waypoint(npc: NPC):
		# Pick random direction and distance
		var angle = randf() * TAU
		var distance = randf_range(10, exploration_radius)
		var potential_waypoint = npc.position + Vector2.from_angle(angle) * distance
		
		# Ensure waypoint is navigable
		if npc.can_reach_position(potential_waypoint):
			current_waypoint = potential_waypoint
			npc.set_navigation_target(current_waypoint)
		else:
			# Try different angle
			for i in range(8):
				angle = (angle + PI/4) 
				potential_waypoint = npc.position + Vector2.from_angle(angle) * distance
				if npc.can_reach_position(potential_waypoint):
					current_waypoint = potential_waypoint
					npc.set_navigation_target(current_waypoint)
					break
	
	func execute(npc: NPC, delta: float):
		if npc.position.distance_to(current_waypoint) < 4.0:
			waypoints_visited += 1
			npc.satisfy_need(NPC.NPCNeed.EXPLORATION, 10)
			
			if waypoints_visited >= max_waypoints:
				completed = true
			else:
				generate_new_waypoint(npc)
		else:
			if not npc.is_navigating:
				npc.set_navigation_target(current_waypoint)

class SocializeGoal extends Goal:
	var socializing_timer: float = 0.0
	var socializing_duration: float = 20.0
	
	func _init():
		type = GoalType.SOCIALIZE
		priority = 40
	
	func start(npc: NPC):
		# Find nearest bar
		target_poi = POIManager.find_nearest_bar(npc.position)
		if target_poi and npc.can_reach_position(target_poi.position):
			npc.set_navigation_target(target_poi.position)
	
	func execute(npc: NPC, delta: float):
		if not target_poi:
			completed = true
			return
		
		if npc.position.distance_to(target_poi.position) < 4.0:
			# At bar, socialize
			socializing_timer += delta
			npc.satisfy_need(NPC.NPCNeed.COMPANIONSHIP, delta * 2)  # Gradual satisfaction
			
			if socializing_timer >= socializing_duration:
				completed = true
		else:
			if not npc.is_navigating:
				npc.set_navigation_target(target_poi.position)

class TradeGoal extends Goal:
	var reached_poi: bool = false
	
	func _init():
		type = GoalType.TRADE_ITEMS
		priority = 45
	
	func start(npc: NPC):
		# Find trading post
		target_poi = POIManager.find_nearest_trading_post(npc.position)
		if target_poi and npc.can_reach_position(target_poi.position):
			npc.set_navigation_target(target_poi.position)
	
	func execute(npc: NPC, delta: float):
		if not target_poi:
			completed = true
			return
		
		if npc.position.distance_to(target_poi.position) < 4.0:
			if not reached_poi:
				reached_poi = true
				# Simulate trading
				var profit = randi_range(-100, 300)
				npc.inventory.add_money(profit)
				if profit > 0:
					npc.satisfy_need(NPC.NPCNeed.WEALTH, 15)
				completed = true
		else:
			if not npc.is_navigating:
				npc.set_navigation_target(target_poi.position)

class EngageCombatGoal extends Goal:
	func _init():
		type = GoalType.ENGAGE_COMBAT
		priority = 35
	
	func start(npc: NPC):
		# This is simplified - in full implementation would find enemies
		completed = true  # For now, just satisfy the need
		npc.satisfy_need(NPC.NPCNeed.COMBAT, 40)
