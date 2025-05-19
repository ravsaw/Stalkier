# Enhanced FPS Mechanics

## 1. Weapon System

### 1.1 Weapon Slot Limitations
- **Primary Slot**: 1 long weapon (rifle, shotgun, sniper)
- **Secondary Slots**: 2 short weapons (pistols, SMGs, small tools)
- **Backpack**: Additional items, resources, and ammunition

### 1.2 Weapon Variety

#### Weapon Classes
- **Assault Rifles**: Balanced damage/rate of fire, medium range
- **Shotguns**: High close-range damage, significant falloff
- **Sniper Rifles**: High damage, precise, slow reload
- **Pistols**: Quick draw, moderate damage, fast reload
- **Submachine Guns**: Rapid fire, increased spread, short range
- **Special Weapons**: Unique mechanics (electrical, chemical, etc.)

#### Weapon Characteristics
- Each weapon has unique recoil pattern
- Bullet penetration varies by material and ammunition type
- Weapon sway affected by movement, stance, and character state
- Sound propagation varies by weapon type and modifications

## 2. NPC Perception System

### 2.1 Vision System
- Field of view (typically 120 degrees)
- Vision distance affected by lighting conditions
- Obstructions block line of sight
- Movement more noticeable than stationary targets
- Peripheral vision detects movement but not details

### 2.2 Hearing System
- 360-degree detection range
- Different surfaces produce different sound levels
- Environmental sounds can mask player-generated noise
- Sound categories (footsteps, gunshots, voice, impacts)
- Sound propagation follows realistic attenuation

### 2.3 Memory & Tracking
- NPCs remember last known position of targets
- Search patterns based on target's last known direction
- "Evidence" tracking (footprints, blood trails, disturbances)
- Information sharing between NPCs (tactical communication)
- Memory decay over time if no new information

## 3. Combat AI

### 3.1 Search Behavior
- Investigate suspicious sounds or visual stimuli
- Generate search patterns when target is lost
- Search intensity based on threat assessment
- Coordination between multiple searching NPCs
- Escalating search phases (casual → concerned → alert)

### 3.2 Cover System
- Dynamic cover detection and evaluation
- Cover quality assessment (partial vs. full protection)
- Flanking awareness to avoid exposed positions
- Suppressive fire to pin targets behind cover
- Grenades/tools to flush enemies from cover

### 3.3 Squad Tactics
- Fire team formations (varying by squad type)
- Coordinated advances and retreats
- Covering fire during teammate movement
- Role specialization (suppressor, flanker, grenadier)
- Leader-directed tactical decisions

## 4. Enhanced Gameplay Elements

### 4.1 Stealth Mechanics
- Light/shadow-based visibility modifiers
- Noise reduction techniques (crouch, slow movement)
- Distraction mechanics (throw objects, create noise)
- Takedown and stealth elimination options
- Alert levels and NPC suspicion states

### 4.2 Hit Feedback System
- Visual feedback (blood effects, impact markers)
- Auditory confirmation (distinct hit sounds)
- Enemy reaction animations based on hit location
- Damage indicators for player feedback
- Kill confirmation (only when visually confirmed)

### 4.3 Environmental Interaction
- Destructible cover elements
- Interactive objects (doors, switches, valves)
- Environmental hazards (explosive barrels, electrical boxes)
- Weather effects impacting visibility and sound propagation
- Day/night cycle affecting stealth and detection

## 5. Technical Implementation

```gdscript
# Basic weapon system implementation
class WeaponSystem extends Node3D:
    var equipped_primary: Weapon = null      # Long weapon slot
    var equipped_secondary: Array = []       # Two short weapons max
    var max_secondary_weapons: int = 2
    
    func equip_primary(weapon: Weapon) -> bool:
        if weapon.weapon_class == WeaponClass.LONG:
            equipped_primary = weapon
            emit_signal("weapon_equipped", weapon, "primary")
            return true
        return false
    
    func equip_secondary(weapon: Weapon) -> bool:
        if weapon.weapon_class == WeaponClass.SHORT and equipped_secondary.size() < max_secondary_weapons:
            equipped_secondary.append(weapon)
            emit_signal("weapon_equipped", weapon, "secondary")
            return true
        return false
    
    func switch_to_primary():
        if equipped_primary != null:
            active_weapon = equipped_primary
            emit_signal("weapon_switched", active_weapon)
    
    func switch_to_secondary(index: int = 0):
        if index < equipped_secondary.size():
            active_weapon = equipped_secondary[index]
            emit_signal("weapon_switched", active_weapon)
```

```gdscript
# NPC Perception system
class NPCPerception extends Node:
    # Vision properties
    var vision_range: float = 100.0
    var vision_angle: float = 120.0  # degrees
    var night_vision_modifier: float = 0.3
    
    # Hearing properties
    var hearing_range: float = 50.0
    var hearing_sensitivity: float = 1.0
    
    # Memory
    var memory_duration: float = 30.0  # seconds
    var last_known_positions: Dictionary = {}
    
    func process_perception(delta: float):
        var detected_entities = []
        
        # Process vision
        var visible_entities = process_vision(delta)
        detected_entities.append_array(visible_entities)
        
        # Process hearing
        var heard_entities = process_hearing(delta)
        detected_entities.append_array(heard_entities)
        
        # Update memory and validate old memories
        update_memory(detected_entities)
        clean_outdated_memories()
        
        return detected_entities
    
    func process_vision(delta: float):
        var visible_entities = []
        for entity in get_potential_visible_entities():
            if is_in_field_of_view(entity) and has_line_of_sight(entity):
                visible_entities.append(entity)
                last_known_positions[entity.id] = {
                    "position": entity.global_position,
                    "timestamp": Time.get_unix_time_from_system(),
                    "certainty": 1.0,
                    "source": "visual"
                }
        return visible_entities
    
    func process_hearing(delta: float):
        var heard_entities = []
        for sound in get_recent_sounds():
            var distance = global_position.distance_to(sound.position)
            if distance <= hearing_range * hearing_sensitivity * sound.intensity:
                heard_entities.append(sound.source)
                
                # Create last known position from sound
                var entity_id = sound.source_id
                if not entity_id in last_known_positions or last_known_positions[entity_id].certainty < 0.7:
                    last_known_positions[entity_id] = {
                        "position": sound.position,
                        "timestamp": Time.get_unix_time_from_system(),
                        "certainty": 0.7,  # Less certain than visual
                        "source": "audio"
                    }
        return heard_entities
```

```gdscript
# Search behavior for lost targets
class SearchBehavior extends State:
    var search_duration: float = 20.0  # seconds
    var search_time_elapsed: float = 0.0
    var search_points: Array = []
    var current_search_point_index: int = 0
    var alert_level: float = 0.0  # 0-1 scale
    
    func enter():
        # Generate search points around last known position
        var last_known = npc.perception.last_known_positions.get(npc.current_target_id)
        if last_known:
            search_points = generate_search_pattern(last_known.position, alert_level)
            current_search_point_index = 0
            npc.move_to(search_points[0])
    
    func update(delta: float):
        search_time_elapsed += delta
        
        # Check if target reacquired
        var visible_entities = npc.perception.process_vision(delta)
        for entity in visible_entities:
            if entity.id == npc.current_target_id:
                npc.transition_to_state("combat")
                return
        
        # Move between search points
        if npc.reached_destination():
            current_search_point_index += 1
            if current_search_point_index < search_points.size():
                npc.move_to(search_points[current_search_point_index])
            else:
                # Generate new search points or give up
                search_points = expand_search_pattern(search_points, alert_level)
                current_search_point_index = 0
                npc.move_to(search_points[0])
        
        # Give up search after duration
        if search_time_elapsed > search_duration:
            npc.transition_to_state("patrol")
    
    func generate_search_pattern(center: Vector3, alert_level: float) -> Array:
        var points = []
        var radius = 5.0 + (alert_level * 15.0)  # Higher alert = wider search
        var point_count = 3 + int(alert_level * 5)  # Higher alert = more thorough
        
        # Generate points in increasing spiral pattern
        for i in range(point_count):
            var angle = i * 2.5  # spiral outward
            var r = radius * (i / float(point_count))
            var offset = Vector3(cos(angle) * r, 0, sin(angle) * r)
            points.append(center + offset)
        
        return points
```