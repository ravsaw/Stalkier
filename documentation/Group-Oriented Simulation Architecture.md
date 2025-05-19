# Group-Oriented Simulation Architecture

## 1. Group as Primary Simulation Unit

### 1.1 Core Design Philosophy
- Groups are the primary unit of simulation instead of individual NPCs
- Individual NPC needs and desires are aggregated into group decisions
- Groups interact with other groups and POIs as cohesive units
- Individual NPC detailed simulation only occurs during key decision points
- Movement between POIs is simulated at the group level

### 1.2 Group Structure
- **Leader**: Most influential member, directs group decisions
- **Members**: Contribute to group decisions based on influence level
- **Specialists**: Members with specific roles (medic, scout, negotiator)
- **Formation**: Physical arrangement when moving or in combat
- **Cohesion**: Metric representing group stability

### 1.3 Group States
- **Traveling**: Moving between POIs as a unit
- **At POI**: Interacting with a specific POI
- **In Conflict**: Engaged with another group in combat
- **Trading**: Exchanging resources with another group or POI
- **Resting**: Recovering and planning next moves
- **Disbanded**: Group dissolution in progress

## 2. Group Decision-Making

### 2.1 Collective Decision Process
- Each member contributes preferences weighted by influence
- Leader has significant but not absolute decision weight
- Decisions affected by group personality (aggregate of members)
- External factors (threats, opportunities) can override normal process
- Faction objectives influence priorities for aligned groups

### 2.2 Member Influence Factors
- **Leadership Rating**: Natural leadership abilities
- **Expertise**: Specialized knowledge relevant to current situation
- **Contribution**: Resources/skills provided to group
- **Seniority**: Time spent with the group
- **Reputation**: Standing within the group
- **Faction Rank**: Position in larger faction hierarchy

### 2.3 Decision Types
- **Destination Selection**: Which POI to visit next
- **Interaction Response**: How to respond to other groups
- **Resource Allocation**: How to distribute collective resources
- **Conflict Decisions**: Fight, flee, or negotiate
- **Membership Changes**: Accept new members or expel existing ones

## 3. Individual Evaluation Within Groups

### 3.1 Satisfaction Assessment
- Regular evaluation of individual's needs fulfillment in group
- Comparison of individual goals vs. group objectives
- Evaluation of personal safety and resource access
- Assessment of social position within group
- Calculation of alternative opportunities (other groups/POIs)

### 3.2 Departure Conditions
- **Low Satisfaction**: Below individual threshold triggers desire to leave
- **Better Opportunities**: Potential for better situation elsewhere
- **POI Arrival**: Safe context to depart from current group
- **Leadership Conflict**: Disagreement with leader's decisions
- **Faction Pull**: Stronger allegiance to faction than group

### 3.3 Role Specialization
- Individuals naturally assume roles based on strengths
- Role fulfillment increases satisfaction and influence
- Complementary roles increase group functionality
- Missing critical roles can destabilize group
- Role conflicts can create internal tension

## 4. Group Cohesion System

### 4.1 Cohesion Factors
- **Goal Alignment**: Shared objectives among members
- **Leadership Quality**: Effectiveness of group leader
- **Social Compatibility**: Interpersonal relationships
- **Resource Sharing**: Fair distribution of collective resources
- **External Pressure**: Threats that unify the group
- **Shared Experiences**: History of overcoming challenges together

### 4.2 Cohesion Effects
- High cohesion improves combat effectiveness
- High cohesion reduces member departure rate
- High cohesion speeds decision making
- Low cohesion increases vulnerability to external threats
- Low cohesion reduces resource efficiency

### 4.3 Group Dissolution
- Occurs when cohesion falls below critical threshold
- Can be triggered by leadership death/departure
- Catastrophic failures can cause immediate dissolution
- Members may form smaller sub-groups when dissolving
- Resources divided based on influence during dissolution

## 5. Group Formation

### 5.1 Formation Triggers
- Similar destination interests
- Compatible needs
- Faction directives
- Safety in dangerous areas
- Resource complementarity
- Social bonds

### 5.2 Initial Leadership Selection
- Natural leadership attributes
- Resource contribution
- Experience/knowledge
- Faction rank (if applicable)
- Combat ability (in dangerous areas)
- Social connectivity

## 6. Technical Implementation

```gdscript
# Group as primary simulation unit
class NPCGroup extends Node:
    var group_id: String
    var leader_id: String
    var members: Array[String] = []  # NPC IDs
    var faction_id: String = ""
    var cohesion: float = 0.5
    var current_state: String = "idle"
    var destination_poi_id: String = ""
    var current_poi_id: String = ""
    var formation: String = "travel"
    var resources: Dictionary = {}
    var travel_progress: float = 0.0
    
    # Group personality (aggregate of members)
    var overall_courage: float = 0.5
    var overall_aggression: float = 0.5
    var risk_tolerance: float = 0.5
    var generosity: float = 0.5
    
    func _init(init_leader_id: String, init_members: Array[String]):
        leader_id = init_leader_id
        members = init_members.duplicate()
        group_id = generate_unique_id()
        
        # Calculate initial group personality from members
        update_group_personality()
    
    func update_group_personality():
        # Reset values
        overall_courage = 0.0
        overall_aggression = 0.0
        risk_tolerance = 0.0
        generosity = 0.0
        
        var total_influence = 0.0
        
        # Calculate weighted average of member personalities
        for member_id in members:
            var member = get_npc(member_id)
            var influence = calculate_member_influence(member_id)
            
            overall_courage += member.personality.courage * influence
            overall_aggression += member.personality.aggression * influence
            risk_tolerance += member.personality.risk_taking * influence
            generosity += member.personality.generosity * influence
            
            total_influence += influence
        
        # Normalize
        if total_influence > 0:
            overall_courage /= total_influence
            overall_aggression /= total_influence
            risk_tolerance /= total_influence
            generosity /= total_influence
```

```gdscript
# Group decision making system
class GroupDecisionSystem:
    func make_group_decision(group: NPCGroup, decision_type: String, options: Array) -> Dictionary:
        var option_scores = {}
        
        # Initialize scores
        for option in options:
            option_scores[option.id] = 0.0
        
        # Get input from all members
        for member_id in group.members:
            var member = get_npc(member_id)
            var member_influence = calculate_member_influence(member_id, group)
            
            # Get member's preferences
            var preferences = get_member_preferences(member, decision_type, options)
            
            # Add weighted preferences to scores
            for option_id in preferences:
                option_scores[option_id] += preferences[option_id] * member_influence
        
        # Leader bonus
        var leader = get_npc(group.leader_id)
        var leader_preferences = get_member_preferences(leader, decision_type, options)
        var leader_bonus = 0.5  # Additional 50% weight for leader
        
        for option_id in leader_preferences:
            option_scores[option_id] += leader_preferences[option_id] * leader_bonus
        
        # Find highest scoring option
        var best_option_id = null
        var best_score = -1.0
        
        for option_id in option_scores:
            if option_scores[option_id] > best_score:
                best_score = option_scores[option_id]
                best_option_id = option_id
        
        # Return decision result
        return {
            "selected_option": best_option_id,
            "confidence": calculate_decision_confidence(option_scores, best_option_id),
            "alternatives": get_viable_alternatives(option_scores, best_score)
        }
    
    func calculate_member_influence(member_id: String, group: NPCGroup) -> float:
        var member = get_npc(member_id)
        var base_influence = 1.0
        
        # Leader gets bonus influence
        if member_id == group.leader_id:
            base_influence += 1.0
        
        # Expertise in relevant fields
        if has_relevant_expertise(member, group.current_state):
            base_influence += 0.5
        
        # Seniority in group
        base_influence += get_member_seniority(member_id, group) * 0.1  # 0.1 per time unit
        
        # Resource contribution
        base_influence += get_resource_contribution_factor(member_id, group) * 0.3
        
        return base_influence
```

```gdscript
# Group system manager
class GroupSystem extends Node:
    var active_groups: Dictionary = {}
    var update_interval: float = 5.0  # Update group decisions every 5 seconds
    var time_since_update: float = 0.0
    
    func _process(delta: float):
        time_since_update += delta
        if time_since_update >= update_interval:
            update_all_groups()
            time_since_update = 0.0
    
    func update_all_groups():
        for group_id in active_groups:
            var group = active_groups[group_id]
            
            # Process group state
            match group.current_state:
                "traveling":
                    process_group_travel(group)
                "at_poi":
                    process_group_at_poi(group)
                "in_conflict":
                    process_group_conflict(group)
                "trading":
                    process_group_trading(group)
                "resting":
                    process_group_resting(group)
                "disbanded":
                    finalize_group_dissolution(group)
            
            # Update internal group dynamics (periodically)
            update_group_dynamics(group)
    
    func update_group_dynamics(group: NPCGroup):
        # Check for leadership challenges
        check_leadership_challenges(group)
        
        # Update cohesion
        update_group_cohesion(group)
        
        # Check for member departures
        process_member_evaluations(group)
```

```gdscript
# Group cohesion system
func update_group_cohesion(group: NPCGroup):
    # Base cohesion factors
    var factors = {
        "shared_goals": calculate_goal_alignment(group),
        "leadership_quality": evaluate_leadership_effectiveness(group.leader_id),
        "social_compatibility": calculate_social_compatibility(group),
        "recent_success": get_recent_success_bonus(group),
        "external_threat": get_external_pressure_bonus(group),
        "time_together": get_group_longevity_bonus(group)
    }
    
    # Calculate new cohesion value
    var new_cohesion = 0.0
    var factor_count = factors.size()
    
    for factor in factors:
        new_cohesion += factors[factor] / factor_count
    
    # Apply smoothing to avoid dramatic swings
    group.cohesion = lerp(group.cohesion, new_cohesion, 0.2)
    
    # Check for group dissolution
    if group.cohesion < 0.2 and not group.current_state == "in_conflict":
        begin_group_dissolution(group)
```

```gdscript
# Group movement system
func process_group_travel(group: NPCGroup):
    if group.destination_poi_id.is_empty():
        # No destination, go to idle
        group.current_state = "idle"
        return
    
    # Calculate travel progress
    var travel_speed = calculate_group_travel_speed(group)
    var distance_factor = calculate_remaining_distance(group)
    
    # Increase progress based on speed and distance
    group.travel_progress += travel_speed / distance_factor
    
    # Check for arrival
    if group.travel_progress >= 1.0:
        handle_group_arrival(group)
    
    # Check for encounters during travel
    check_travel_encounters(group)
```