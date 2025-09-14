# Hybrid 2D/3D World System for Stalkier

## Overview

This system implements a complete hybrid 2D/3D world management system for the Stalkier FPS game in Godot 4. It provides seamless transitions between 2D global world representation and 3D local gameplay areas with intelligent NPC management.

## Key Features

### ✅ World Management System
- **Area-Based Division**: World split into 1000x1000 unit discrete regions/areas
- **Dynamic Loading**: Only load player's current area + adjacent areas in 3D
- **2D Global View**: Always maintain complete 2D world representation
- **Performance**: Support 100+ NPC groups while maintaining 60 FPS

### ✅ Coordinate System
- **Global 2D Coordinates**: World-space positioning (e.g., Village at (2000, 3000))
- **Local 3D Coordinates**: Area-specific positioning with conversion utilities
- **Seamless Conversion**: Functions to convert between 2D/3D coordinate systems

### ✅ NPC Group Management
- **State-Based Behavior**: Groups switch between 2D (distant) and 3D (nearby) representations
- **Distance Thresholds**: 
  - 2D State when >500m from player
  - 3D State when ≤500m from player
  - Despawn at 600m from player
- **Group Dynamics**: Leader-member hierarchy with cohesive movement

### ✅ Area Loading Logic
- **Smart Loading**: Load current area + connected areas
- **Timer-Based Optimization**: After 60s, preload all connected areas
- **Memory Management**: Unload disconnected areas to optimize performance

### ✅ Transition System
- **Transition Points**: Special waypoints at area boundaries
- **Cross-Area Navigation**: Groups can navigate between areas via transition points
- **State Persistence**: Maintain group state during area transitions

## How to Use

### Controls
- **TAB**: Toggle between 2D and 3D view modes
- **WASD**: Move camera/player in current view
- **I/J/K/L**: Move player position to test state transitions
- **N**: Spawn debug NPC (existing functionality)
- **C**: Spawn debug combat (existing functionality)

### Running the System

1. **Start the Game**: The system initializes automatically with the new Main scene
2. **View Modes**: 
   - 2D Mode: Shows the traditional simulation view with all NPCs
   - 3D Mode: Shows 3D representation of nearby NPCs only
3. **State Transitions**: Move around to see NPCs transition between 2D/3D/despawned states
4. **Group Behavior**: Watch groups maintain formations and move together

### System Architecture

```
scenes/
├── Main.tscn (Root scene with World2D and World3D nodes)
├── areas/
│   ├── Area2D.tscn (2D area template)
│   └── Area3D.tscn (3D area template)
└── npcs/
    ├── NPCAgent2D.tscn (2D NPC representation)
    └── NPCAgent3D.tscn (3D NPC representation)

scripts/
├── singletons/
│   └── world_manager.gd (Main system controller)
├── world/
│   ├── area.gd (Area data and management)
│   ├── transition_point.gd (Area boundary logic)
│   └── coordinate_converter.gd (2D/3D conversion utilities)
├── groups/
│   └── group.gd (Enhanced with formations and state management)
└── npc/
    └── npc.gd (Enhanced with 2D/3D state support)
```

## Technical Implementation

### WorldManager Singleton
- Manages all areas and their loading states
- Handles distance-based NPC state transitions
- Coordinates between 2D and 3D representations
- Provides coordinate conversion utilities

### NPC State Management
- **2D State**: Simple 2D representation, updated every 5 seconds
- **3D State**: Full 3D representation, updated every frame
- **Despawned State**: NPC exists in memory but not visually rendered

### Group Formations
- **Line Formation**: Single line behind leader
- **Wedge Formation**: V-shaped formation
- **Column Formation**: Two columns behind leader
- **Circle Formation**: Circular arrangement around leader

### Area System
- **Standard Areas**: 1000x1000 unit regions
- **Transition Points**: Seamless movement between areas
- **Dynamic Loading**: Areas load/unload based on player proximity
- **Terrain Types**: Plains, Forest, Mountains, Swamp, Desert, Urban, Industrial, Underground

## Performance Optimizations

1. **Distance-Based Updates**: 
   - 2D NPCs update every 5 seconds
   - 3D NPCs update every frame
   - Despawned NPCs skip visual updates

2. **Area Loading**: 
   - Only active areas loaded in 3D
   - Connected areas preloaded after 60 seconds
   - Disconnected areas automatically unloaded

3. **Group Management**:
   - Formation updates only when needed
   - State transitions minimize visual recreation
   - Batch updates for group members

## Demo Scenarios

The system includes several demo scenarios:

1. **State Transition Demo**: NPCs at various distances showing different states
2. **Group Formation Demo**: Military patrol, trade caravan, and bandit gang
3. **Area Transition Demo**: Moving between different world areas
4. **Performance Demo**: 100+ NPCs with smooth state transitions

## Testing

Run the included test suite to verify system functionality:

```gdscript
HybridSystemTest.run_tests()
```

Tests cover:
- Coordinate conversion accuracy
- Area management functionality
- NPC state transitions
- Group formation behavior
- Transition point mechanics

## Integration with Existing Systems

The hybrid system integrates seamlessly with existing Stalkier systems:

- **NPCManager**: Extended to support state management
- **GroupManager**: Enhanced with formation behavior
- **POIManager**: Continues to work with area system
- **CombatManager**: Functions in both 2D and 3D modes
- **EventBus**: All events preserved and extended

## Future Enhancements

Potential improvements for the system:

1. **LOD System**: Multiple levels of detail for distant objects
2. **Streaming**: Continuous loading of world data
3. **Networking**: Multiplayer support for hybrid world
4. **AI Improvements**: Context-aware behavior in different states
5. **Visual Effects**: Transition animations between states

## Troubleshooting

### Common Issues

1. **NPCs Not Transitioning**: Check distance thresholds in WorldManager
2. **Formation Not Working**: Ensure group has a valid leader
3. **Areas Not Loading**: Verify area connections and transition points
4. **Performance Issues**: Check NPC count and active 3D areas

### Debug Information

The UI displays real-time information about:
- Current view mode (2D/3D)
- Number of loaded 3D areas
- NPCs in each state (2D/3D/despawned)
- Current player area
- System performance statistics

## Conclusion

This hybrid 2D/3D world system provides a solid foundation for large-scale FPS games requiring both strategic overview and tactical gameplay. The system is designed to be scalable, performant, and easy to extend for future game development needs.