# Stalkier - S.T.A.L.K.E.R.-inspired FPS Game

## Hybrid 2D/3D World System

Stalkier features an innovative hybrid 2D/3D world system that allows seamless switching between top-down 2D strategic view and immersive 3D first-person gameplay.

### Features

#### World Management
- **Dynamic Area Loading**: Areas are loaded and unloaded dynamically based on player proximity
- **Seamless Mode Switching**: Press `T` to switch between 2D and 3D modes
- **Coordinate Conversion**: Automatic conversion between 2D and 3D coordinate systems
- **Performance Optimization**: LOD (Level of Detail) system for NPCs and world elements

#### NPC System
- **Hybrid NPCs**: All NPCs work in both 2D and 3D modes with appropriate AI scaling
- **Group Behavior**: NPCs form groups with formation systems and coordination
- **Smart AI**: Context-aware AI that adapts behavior based on current mode
- **Memory System**: NPCs remember events and share information within groups

#### Areas and Transitions
- **Mixed Areas**: Areas can support both 2D and 3D gameplay
- **Transition Points**: Special zones that allow mode switching with visual effects
- **Terrain System**: Procedural terrain height generation for 3D mode
- **Navigation**: Separate navigation meshes for 2D and 3D modes

### Controls

#### General
- **T** - Toggle between 2D and 3D modes
- **F12** - Toggle debug information display
- **Escape** - Deselect NPCs/objects
- **Space** - Pause/unpause simulation

#### 2D Mode (Top-down Strategic View)
- **WASD** - Move camera
- **Mouse Wheel** - Zoom in/out
- **Middle Mouse Click** - Quick focus camera
- **Left Click** - Select NPCs/objects
- **N** - Spawn test NPC (debug)
- **C** - Spawn test combat (debug)

#### 3D Mode (First-person View)
- **WASD** - Move camera
- **Right Mouse + Move** - Look around
- **Mouse Wheel** - Zoom (if applicable)

### Technical Architecture

#### Core Classes

1. **WorldManager** - Main controller for hybrid world system
2. **Area** - Unified area representation for both 2D and 3D
3. **CoordinateConverter** - Handles seamless coordinate conversion
4. **TransitionPoint** - Manages mode transition zones
5. **HybridNPCAgent** - Dual-mode NPC representation
6. **NPCGroup** - Enhanced group management system

#### Directory Structure

```
scripts/world/
├── world_manager.gd                 # Main world controller
├── world_main.gd                    # World scene controller
├── areas/
│   └── area.gd                      # Area management
├── coordinate_conversion/
│   └── coordinate_converter.gd      # 2D/3D conversion
├── npcs/
│   ├── hybrid_npc_agent.gd         # Hybrid NPC representation
│   └── npc_group.gd                 # Group management
└── transitions/
    └── transition_point.gd          # Mode transition points

scenes/world/
├── world_main.tscn                  # Main world scene
└── areas/                           # Area scene templates
```

### Performance Features

- **LOD System**: Reduces AI complexity and visual detail based on distance
- **Dynamic Loading**: Only active areas are kept in memory
- **Batch Updates**: NPCs are updated in batches to maintain 60 FPS
- **Culling**: Distant or inactive elements are culled from updates

### Gameplay Systems

#### NPCs
- **Needs System**: NPCs have needs (hunger, shelter, companionship, etc.)
- **Relationship System**: NPCs build relationships with each other
- **Group Dynamics**: NPCs form and leave groups dynamically
- **Combat System**: Turn-based combat with equipment and skills

#### Economics
- **Trading**: NPCs can trade items with each other and players
- **Equipment**: Comprehensive weapon and armor system
- **Resources**: Various resources and crafting materials

#### World
- **POI System**: Points of Interest with different types and functions
- **Weather**: Dynamic weather affecting gameplay
- **Day/Night Cycle**: Time progression with realistic lighting

### Development Status

✅ **Phase 1 Complete**: Core hybrid 2D/3D system implemented
- World management and area loading
- Coordinate conversion system
- Basic NPC hybrid agents
- Mode switching functionality
- Transition point system

🔄 **Phase 2 In Progress**: Integration and testing
- System integration testing
- Performance optimization
- Visual polish and effects
- User interface improvements

📋 **Phase 3 Planned**: Advanced features
- Save/load system for world state
- Multiplayer foundation
- Advanced AI behaviors
- Procedural content generation

### Building and Running

The project is built with Godot 4.x. Simply open the project in Godot and run the main scene.

### Contributing

This is a learning project exploring hybrid 2D/3D game design. The system is designed to be modular and extensible.

---

*This system represents a complete overhaul of the previous 2D-only implementation, providing a foundation for rich strategic and tactical gameplay.*