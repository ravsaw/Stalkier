# Cień Podróżnika - Systemy FPS

Ten dokument zawiera szczegółowy opis wszystkich mechanik First Person Shooter w grze "Cień Podróżnika", ich unikalnych adaptacji do środowiska Strefy oraz integracji z innymi systemami gry.

> **Referencje**: Zobacz [technical-design.md](technical-design.md) dla implementacji technicznej i [gameplay-mechanics.md](gameplay-mechanics.md) dla interakcji z innymi systemami.

## 1. Mechanika Ruchu Gracza

### 1.1 Podstawy Przemieszczania

```typescript
interface MovementSystem {
  // Base movement speeds (m/s)
  walkSpeed: number;        // 3.5 m/s
  runSpeed: number;         // 6.0 m/s  
  sprintSpeed: number;      // 8.5 m/s
  crouchSpeed: number;      // 1.5 m/s
  proneSpeed: number;       // 0.8 m/s
  
  // Advanced movements
  leanAngle: number;        // ±45 degrees
  jumpHeight: number;       // 1.2 meters
  mantleHeight: number;     // 2.0 meters
  
  // Stamina system
  stamina: {
    max: 100,
    sprintCost: 15,         // per second
    jumpCost: 20,           // per jump
    mantleCost: 30,         // per mantle
    regenRate: 25           // per second (resting)
  };
}
```

### 1.2 Wpływ Naznaczenia na Ruch

```typescript
class MovementModifiers {
  calculateMovementSpeed(baseSpeed: number, marking: number): number {
    // Early marking improves agility, later stages reduce it
    if (marking < 30) {
      return baseSpeed * (1 + marking * 0.005); // +0.5% per 1% marking
    } else if (marking < 70) {
      return baseSpeed; // Stable period
    } else {
      return baseSpeed * (1 - (marking - 70) * 0.01); // -1% per 1% after 70%
    }
  }
  
  getMovementPenalties(marking: number): MovementPenalties {
    return {
      jumpHeight: marking > 80 ? 0.7 : 1.0,
      sprintDuration: marking > 60 ? 0.8 : 1.0,
      noiseGeneration: 1 + (marking * 0.02), // More noise as marking increases
      footstepDistortion: marking > 50 ? true : false
    };
  }
  
  // Unique abilities at high marking
  getMarkingAbilities(marking: number): MarkingAbilities {
    const abilities = [];
    
    if (marking > 40) {
      abilities.push('PHASE_STEP'); // Short invulnerability during step
    }
    if (marking > 60) {
      abilities.push('ANOMALY_WALK'); // Move through some anomalies
    }
    if (marking > 80) {
      abilities.push('REALITY_SLIP'); // Brief wall-walking
    }
    
    return abilities;
  }
}
```

### 1.3 Interakcja z Anomaliami

```typescript
interface AnomalyMovementEffects {
  // Gravity anomalies
  gravityFields: {
    lowGravity: {
      jumpMultiplier: 3.0,
      fallSpeedMultiplier: 0.3,
      floatyMovement: true
    },
    highGravity: {
      jumpMultiplier: 0.2,
      fallSpeedMultiplier: 3.0,
      stamina exhaustionRate: 2.0
    }
  };
  
  // Electric anomalies  
  electricFields: {
    movementStutter: true,
    randomDirectionImpulses: true,
    equipmentInterference: true
  };
  
  // Spatial anomalies
  spatialDistortions: {
    stretchedDistances: 'visual disconnect from real movement',
    forcedTeleportation: 'random position shifts',
    dimensionalLoops: 'returning to same position'
  };
}
```

## 2. System Broni

### 2.1 Kategorie Broni

```typescript
enum WeaponCategory {
  // Standard weapons
  PISTOL = 'PISTOL',
  RIFLE = 'RIFLE',
  SHOTGUN = 'SHOTGUN',
  SNIPER = 'SNIPER',
  SMG = 'SMG',
  
  // Zone-specific weapons
  ENERGY_WEAPON = 'ENERGY_WEAPON',
  ARTIFACT_WEAPON = 'ARTIFACT_WEAPON',
  IMPROVISED = 'IMPROVISED',
  ANOMALY_LAUNCHER = 'ANOMALY_LAUNCHER'
}

// Example weapon definitions
const weaponSpecs = {
  ak74: {
    category: WeaponCategory.RIFLE,
    damage: 35,
    range: 400,        // meters
    rpm: 650,          // rounds per minute
    accuracy: 0.92,    // base accuracy
    recoil: {
      vertical: 0.3,
      horizontal: 0.15,
      rotational: 0.05
    },
    durability: 100,   // condition points
    weight: 3.2,       // kg
    
    // Zone-specific properties
    anomalyResistance: 0.8, // 80% resistance to anomaly effects
    markingAffinity: false  // Does not improve with marking
  },
  
  artifactRifle: {
    category: WeaponCategory.ARTIFACT_WEAPON,
    damage: 28,        // Lower base damage
    range: 350,
    rpm: 550,
    accuracy: 0.88,
    recoil: {
      vertical: 0.2,   // Better recoil control
      horizontal: 0.1,
      rotational: 0.03
    },
    durability: 150,   // More durable
    weight: 2.8,
    
    // Unique properties
    anomalyResistance: 1.0, // Immune to anomaly effects
    markingAffinity: true,  // Improves with marking level
    specialAbilities: ['PHASE_THROUGH_WALLS', 'AUTO_AIM_ASSIST']
  }
};
```

### 2.2 Mechanika Strzelania

```typescript
class ShootingMechanics {
  calculateShotAccuracy(weapon: Weapon, shooterState: ShooterState): number {
    let accuracy = weapon.baseAccuracy;
    
    // Stance modifiers
    switch (shooterState.stance) {
      case 'PRONE': accuracy *= 1.3; break;
      case 'CROUCH': accuracy *= 1.15; break;
      case 'STANDING': accuracy *= 1.0; break;
      case 'MOVING': accuracy *= 0.7; break;
      case 'RUNNING': accuracy *= 0.4; break;
    }
    
    // Aiming modifiers
    if (shooterState.isAiming) {
      accuracy *= 1.5;
    }
    
    // Stamina effect
    const staminaMultiplier = 0.7 + (shooterState.stamina / 100) * 0.3;
    accuracy *= staminaMultiplier;
    
    // Marking effects
    if (weapon.markingAffinity && shooterState.marking > 30) {
      accuracy *= 1 + (shooterState.marking - 30) * 0.005;
    }
    
    // Anomaly effects
    accuracy *= this.getAnomalyEffects(shooterState.location);
    
    return Math.min(1.0, accuracy);
  }
  
  // Recoil patterns
  calculateRecoilPattern(weapon: Weapon, consecutiveShots: number): Vector2 {
    const pattern = weapon.recoilPattern;
    let recoil = new Vector2(0, 0);
    
    // Vertical recoil (always present)
    recoil.y = pattern.vertical * (1 + consecutiveShots * 0.1);
    
    // Horizontal recoil (increases with consecutive shots)
    const horizontalVariation = (Math.random() - 0.5) * 2;
    recoil.x = pattern.horizontal * horizontalVariation * Math.sqrt(consecutiveShots);
    
    // Rotational recoil (weapon-specific)
    const rotation = pattern.rotational * (Math.random() - 0.5) * consecutiveShots;
    
    return { recoil, rotation };
  }
}
```

### 2.3 Degradacja i Maintenance Broni

```typescript
interface WeaponCondition {
  durability: number;     // 0-100
  jamChance: number;      // Calculated based on durability
  accuracyPenalty: number; // Accuracy loss due to wear
  
  // Zone-specific degradation
  anomalyExposure: number;  // Accumulated anomaly damage
  radiationDamage: number;  // Radiation-induced wear
  temporalStress: number;   // Temporal anomaly effects
}

class WeaponMaintenance {
  calculateDegradation(weapon: Weapon, environment: Environment): number {
    let degradation = 0;
    
    // Normal use
    degradation += weapon.shotsFromLastClean * 0.1;
    
    // Environmental factors
    if (environment.radiation > 50) {
      degradation += 0.5; // per hour
    }
    
    if (environment.humidity > 0.8) {
      degradation += 0.3; // per hour
    }
    
    // Anomaly exposure
    degradation += environment.anomalyIntensity * 0.2;
    
    // Zone marking interaction
    if (environment.markingLevel > 70 && !weapon.markingCompatible) {
      degradation += 1.0; // Incompatible weapons degrade faster
    }
    
    return degradation;
  }
  
  // Repair system
  repairWeapon(weapon: Weapon, tools: RepairTool[], parts: Parts[]): RepairResult {
    const skillMultiplier = this.getSkillMultiplier();
    const qualityMultiplier = this.getPartsQuality(parts);
    
    const repairAmount = 30 * skillMultiplier * qualityMultiplier;
    const successChance = this.calculateSuccessChance(weapon, tools);
    
    if (Math.random() < successChance) {
      weapon.durability = Math.min(100, weapon.durability + repairAmount);
      return RepairResult.SUCCESS;
    } else {
      weapon.durability = Math.max(0, weapon.durability - 5);
      return RepairResult.FAILURE;
    }
  }
}
```

## 3. System Namierzania (Aiming)

### 3.1 Mechanika ADS (Aim Down Sights)

```typescript
interface AimingSystem {
  adsSpeed: number;           // Time to ADS (seconds)
  adsAccuracyBonus: number;   // Accuracy multiplier when ADS
  fovReduction: number;       // Field of view reduction
  movementSpeedPenalty: number; // Speed reduction while ADS
  
  // Sway system
  aimSway: {
    amplitude: number;        // Maximum sway distance
    frequency: number;        // Sway cycles per second
    damping: number;         // Natural stabilization
  };
  
  // Hold breath mechanic
  holdBreath: {
    duration: number;         // Maximum hold time
    stabilization: number;    // Sway reduction while holding
    recoveryTime: number;     // Time to recover oxygen
  };
}
```

### 3.2 Wpływ Naznaczenia na Aiming

```typescript
class MarkingAimingEffects {
  // Early marking improves steady aim
  // Later marking causes hallucinations and distortions
  getAimingModifiers(marking: number): AimingModifiers {
    const modifiers = new AimingModifiers();
    
    if (marking < 40) {
      // Enhanced perception and steadiness
      modifiers.aimSway *= (1 - marking * 0.01);    // Reduced sway
      modifiers.targetHighlight = marking * 0.02;    // Subtle enemy highlighting
    } else if (marking < 70) {
      // Peak performance window
      modifiers.aimSway *= 0.6;  // Best accuracy period
      modifiers.targetAcquisition *= 1.3; // Faster target switching
    } else if (marking < 90) {
      // Distortions begin
      modifiers.visualDistortions = true;
      modifiers.ghostTargets = (marking - 70) * 0.05; // Chance for false targets
      modifiers.depthPerception *= 0.9; // Harder to judge distance
    } else {
      // Severe distortions
      modifiers.realityPhasing = true; // Bullets may phase through walls
      modifiers.multidimensionalAiming = true; // See into other dimensions
      modifiers.controlDifficulty *= 2.0; // Much harder to control
    }
    
    return modifiers;
  }
}
```

### 3.3 Optical Attachments and Zone Effects

```typescript
interface OpticAttachment {
  magnification: number;
  claritу: number;
  durability: number;
  anomalyResistance: number;
  
  // Special properties
  nightVision?: boolean;
  heatVision?: boolean;
  anomalyDetection?: boolean;
  dimensionalSight?: boolean; // Sees through reality distortions
}

// Example optic definitions
const opticsSpecs = {
  standardScope: {
    magnification: 4.0,
    clarity: 0.95,
    durability: 80,
    anomalyResistance: 0.3,
    staticChance: 0.02       // 2% chance of static per minute
  },
  
  artifactScope: {
    magnification: 6.0,
    clarity: 0.98,
    durability: 120,
    anomalyResistance: 1.0,
    specialProperties: [
      'ANOMALY_PENETRATION',  // See through anomaly fields
      'ENEMY_HIGHLIGHTING',   // Highlights hostile entities
      'DISTANCE_MEASUREMENT'  // Shows exact distance to target
    ],
    markingRequirement: 30   // Requires 30% marking to use effectively
  }
};
```

## 4. Audio System

### 4.1 Pozycyjny Dźwięk

```typescript
interface AudioSystem {
  // Base audio properties
  maxAudioDistance: number;    // 500 meters
  reverbSettings: ReverbSettings;
  occlusionSystem: AudioOcclusion;
  
  // Zone-specific audio
  anomalyDistortion: {
    frequency: number;         // How often distortion occurs
    intensity: number;         // Strength of distortion
    types: AudioDistortionType[];
  };
  
  // Marking-based audio changes
  markingAudio: {
    enhancedHearing: boolean;  // Better sound localization
    paranormalSounds: boolean; // Hearing sounds from other dimensions
    audioHallucinations: boolean; // False audio cues
  };
}

class ZoneAudioProcessor {
  processAudio(sound: AudioSource, listener: Player): ProcessedAudio {
    const distance = sound.position.distanceTo(listener.position);
    const direction = sound.position.subtract(listener.position).normalized();
    
    // Base audio processing
    let volume = this.calculateVolumeByDistance(distance);
    let frequency = sound.baseFrequency;
    
    // Anomaly effects
    const nearbyAnomalies = this.getNearbyAnomalies(sound.position, listener.position);
    for (const anomaly of nearbyAnomalies) {
      volume *= anomaly.audioVolumeModifier;
      frequency *= anomaly.audioFrequencyModifier;
      
      // Special anomaly effects
      if (anomaly.type === 'Spatial') {
        direction = this.distortDirection(direction, anomaly.intensity);
      }
      if (anomaly.type === 'Electric') {
        volume *= (1 + Math.sin(Time.time * 10) * 0.1); // Audio crackling
      }
    }
    
    // Marking effects
    if (listener.marking > 50) {
      // Enhanced hearing
      volume *= 1.2;
      // Paranormal sounds
      if (Math.random() < listener.marking * 0.001) {
        this.addParanormalLayer(sound);
      }
    }
    
    return new ProcessedAudio(volume, frequency, direction);
  }
}
```

### 4.2 Dźwięki Broni w Strefie

```typescript
interface WeaponSounds {
  // Standard sounds
  fireSound: AudioClip;
  reloadSound: AudioClip;
  jamSound: AudioClip;
  
  // Zone modifications
  echoIntensity: number;      // How much sound echoes in the Zone
  anomalyMutation: number;    // How much anomalies affect the sound
  suppressorEffects: {
    volumeReduction: number;
    frequencyChange: number;
    anomalyInteraction: boolean; // Some anomalies detect suppressed fire
  };
}

// Sound propagation in the Zone
class ZoneSoundPropagation {
  calculateSoundTravel(source: Vector3, strength: number): SoundMap {
    const soundMap = new SoundMap();
    
    // Basic propagation
    const propagationRadius = strength * SOUND_PROPAGATION_MULTIPLIER;
    
    // Anomaly interactions
    const anomalies = this.getAnomaliesInRadius(source, propagationRadius);
    for (const anomaly of anomalies) {
      switch (anomaly.type) {
        case 'ACOUSTIC':
          // Sound anomalies can amplify or absorb sound
          if (anomaly.behavioral === 'AMPLIFY') {
            soundMap.addAmplificationZone(anomaly.position, anomaly.radius);
          } else {
            soundMap.addDeadZone(anomaly.position, anomaly.radius);
          }
          break;
          
        case 'SPATIAL':
          // Spatial anomalies can redirect sound
          soundMap.addSoundRedirection(anomaly.position, anomaly.redirectionAngle);
          break;
      }
    }
    
    return soundMap;
  }
}
```

## 5. User Interface FPS

### 5.1 Core FPS UI Elements

```typescript
interface FPSInterface {
  // Essential elements
  crosshair: CrosshairSettings;
  healthDisplay: HealthUI;
  ammoCounter: AmmoUI;
  minimapСистема: MinimapSettings;
  
  // Zone-specific elements
  anomalyWarningSystem: AnomalyWarnings;
  radiationMeter: RadiationUI;
  markingIndicator: MarkingDisplay;
  
  // Equipment display
  weaponDisplay: WeaponUI;
  inventoryQuickAccess: InventoryUI;
  artifactSlots: ArtifactUI;
}

// Example UI specifications
const uiSpecs = {
  crosshair: {
    style: 'DYNAMIC',           // Changes based on weapon/situation
    bloom: true,                // Expands during automatic fire
    colorChanges: [
      { trigger: 'ENEMY_TARGET', color: 'RED' },
      { trigger: 'FRIENDLY_FIRE', color: 'BLUE' },
      { trigger: 'ANOMALY_AIM', color: 'YELLOW' }
    ],
    markingEffects: {
      '30%': 'ENEMY_OUTLINE',    // Subtle enemy highlighting
      '60%': 'THREAT_PREDICTION', // Shows where enemies will be
      '80%': 'REALITY_FRACTURES'  // Shows multiple realities
    }
  },
  
  healthDisplay: {
    style: 'SEGMENTED',         // Shows in chunks like STALKER
    regenThreshold: 0.25,       // Starts regenerating at 25%
    damageIndicators: true,     // Directional damage indicators
    markingCorruption: {
      '50%': 'SLIGHT_DISTORTION',
      '70%': 'PERIODIC_GLITCHES',
      '90%': 'MAJOR_DISTORTIONS'
    }
  }
};
```

### 5.2 Adaptive UI Based on Marking

```typescript
class AdaptiveUI {
  updateUIBasedOnMarking(marking: number): UIState {
    const ui = new UIState();
    
    // Base UI elements
    ui.crosshair = this.generateCrosshair(marking);
    ui.healthDisplay = this.generateHealthDisplay(marking);
    ui.ammoDisplay = this.generateAmmoDisplay(marking);
    
    // Marking-specific additions
    if (marking > 20) {
      ui.anomalyPreview = new AnomalyPreviewWidget(); // See anomalies ahead
    }
    
    if (marking > 40) {
      ui.pasteStates = new PastStatesOverlay(); // See echo of past events
    }
    
    if (marking > 60) {
      ui.multiverseOptions = new MultiverseSelector(); // Choose reality layer
    }
    
    if (marking > 80) {
      ui.realityManipulator = new RealityManipulator(); // Direct reality control
    }
    
    return ui;
  }
  
  // Dynamic UI corruption
  applyUICorruption(marking: number): CorruptionEffects {
    const effects = [];
    
    if (marking > 70) {
      effects.push(new StaticNoise(intensity: marking - 70));
      effects.push(new ColorDistortion(intensity: (marking - 70) * 0.02));
    }
    
    if (marking > 80) {
      effects.push(new GhostUI()); // UI elements from other dimensions
      effects.push(new TimeSkip()); // UI shows future/past states
    }
    
    if (marking > 90) {
      effects.push(new RealityFragmentation()); // UI splits into multiple realities
    }
    
    return effects;
  }
}
```

## 6. Interakcje Środowiskowe

### 6.1 System Interakcji

```typescript
interface InteractionSystem {
  // Standard interactions
  doorOpening: DoorInteraction;
  itemPickup: ItemInteraction;
  containerSearch: ContainerInteraction;
  
  // Zone-specific interactions
  anomalyManipulation: AnomalyInteraction;
  artifactActivation: ArtifactInteraction;
  cultistRelicAnimation: RelicInteraction;
  
  // Marking-based interactions
  phaseTouchInteractions: PhaseInteraction[];
  realityAlteringActions: RealityInteraction[];
  spiritualCommunications: SpiritInteraction[];
}

class EnvironmentalInteraction {
  // Standard FPS interactions enhanced for the Zone
  handleInteraction(object: InteractableObject, player: Player): InteractionResult {
    const interaction = this.determineInteractionType(object);
    const requirements = this.checkRequirements(object, player);
    
    if (!requirements.canInteract) {
      return InteractionResult.failed(requirements.reason);
    }
    
    // Zone-specific checks
    const anomalyInterfere = this.checkAnomalyInterference(object, player);
    if (anomalyInterfere.interferes) {
      return this.handleAnomalyInterference(anomalyInterfere);
    }
    
    // Marking level interactions
    if (player.marking > object.markingRequirement) {
      return this.handleEnhancedInteraction(object, player);
    }
    
    return this.executeStandardInteraction(object, player);
  }
  
  // Special marking interactions
  getMarkingInteractions(marking: number): SpecialInteraction[] {
    const interactions = [];
    
    if (marking > 30) {
      interactions.push(new ThroughWallsInteraction());
    }
    
    if (marking > 50) {
      interactions.push(new TimeDelayedInteraction()); // Interact with past/future objects
    }
    
    if (marking > 70) {
      interactions.push(new DimensionalInteraction()); // Interact across dimensions
    }
    
    return interactions;
  }
}
```

### 6.2 Inventory Management

```typescript
interface InventorySystem {
  // Standard inventory
  capacity: {
    weight: number;           // kg capacity
    volume: number;           // m³ capacity
    slots: number;            // Number of item slots
  };
  
  // Zone considerations
  radiationShielding: number;  // How well inventory protects items
  anomalyResistance: number;   // Resistance to anomaly effects
  
  // Weight distribution affects gameplay
  loadoutEffects: {
    movementSpeed: number;     // Speed modifier
    jumpHeight: number;        // Jump modifier
    staminaCost: number;       // Extra stamina cost
    noiseGeneration: number;   // How much noise movement makes
  };
}

class RadiationInventoryEffects {
  // Items can become radioactive in the Zone
  processRadiationEffects(inventory: Inventory): void {
    for (const item of inventory.items) {
      if (item.radiationLevel > 0) {
        // Items irradiate nearby items
        this.contaminateNearbyItems(item, inventory);
        
        // Player takes radiation damage
        player.takeRadiationDamage(item.radiationLevel * TIME_MULTIPLIER);
        
        // Equipment degrades from radiation
        item.durability -= item.radiationLevel * RADIATION_DECAY_RATE;
      }
      
      // Artifacts may provide protection
      const protection = this.calculateArtifactProtection(inventory);
      item.radiationLevel = Math.max(0, item.radiationLevel - protection);
    }
  }
}
```

## 7. Balansowanie FPS Mechanics

### 7.1 Weapon Balance Framework

```typescript
class WeaponBalancer {
  // Primary balance axes for weapons
  calculateWeaponBalance(weapon: Weapon): BalanceMetrics {
    const metrics = {
      dps: weapon.damage * (weapon.rpm / 60), // Damage per second
      range: weapon.effectiveRange,
      mobility: this.calculateMobility(weapon),
      reliability: this.calculateReliability(weapon),
      versatility: this.calculateVersatility(weapon)
    };
    
    // Zone-specific considerations
    metrics.anomalyResistance = weapon.anomalyResistance;
    metrics.markingAffinity = weapon.markingAffinity ? 1.0 : 0.0;
    
    return metrics;
  }
  
  // Balance targets for different weapon tiers
  getBalanceTargets(): WeaponTiers {
    return {
      starter: {
        dps: 20,
        range: 100,
        reliability: 0.9,
        cost: 'LOW'
      },
      intermediate: {
        dps: 40,
        range: 250,
        reliability: 0.95,
        cost: 'MEDIUM'
      },
      advanced: {
        dps: 60,
        range: 400,
        reliability: 0.98,
        cost: 'HIGH'
      },
      artifact: {
        dps: 45,        // Lower raw DPS
        range: 350,
        reliability: 1.0,
        specialAbilities: 'HIGH',
        cost: 'ARTIFACT_REQUIRED'
      }
    };
  }
}
```

### 7.2 Difficulty Progression

```typescript
class FPSDifficultyProgression {
  // How FPS difficulty scales throughout the game
  getDifficultyProgression(): DifficultyStages {
    return [
      {
        stage: 'TUTORIAL',
        enemy_accuracy: 0.3,
        enemy_reaction_time: 1.5,  // seconds
        player_damage_multiplier: 0.5,
        ammo_scarcity: 0.0
      },
      {
        stage: 'EARLY_GAME',
        enemy_accuracy: 0.5,
        enemy_reaction_time: 1.0,
        player_damage_multiplier: 0.7,
        ammo_scarcity: 0.2
      },
      {
        stage: 'MID_GAME',
        enemy_accuracy: 0.7,
        enemy_reaction_time: 0.7,
        player_damage_multiplier: 1.0,
        ammo_scarcity: 0.4
      },
      {
        stage: 'LATE_GAME',
        enemy_accuracy: 0.8,
        enemy_reaction_time: 0.5,
        player_damage_multiplier: 1.2,  // Enemies do more damage
        ammo_scarcity: 0.6
      },
      {
        stage: 'END_GAME',
        enemy_accuracy: 0.9,
        enemy_reaction_time: 0.3,
        player_damage_multiplier: 1.5,
        ammo_scarcity: 0.3,  // More ammo found to balance difficulty
        special_abilities: true  // Enemies gain Zone powers
      }
    ];
  }
  
  // Adaptive difficulty based on player performance
  adjustDifficulty(performance: PlayerPerformance): DifficultyAdjustment {
    const adjustment = new DifficultyAdjustment();
    
    if (performance.accuracy < 0.3) {
      // Player struggling with accuracy
      adjustment.enemyMovementSpeedPercentage = 0.85;
      adjustment.enemyAggressionLevel = 0.8;
    }
    
    if (performance.survivability < 0.5) {
      // Player dying too often
      adjustment.playerHealthModifier = 1.15;
      adjustment.medkitEffectiveness = 1.2;
    }
    
    if (performance.progressionRate > 1.5) {
      // Player progressing too fast
      adjustment.enemyReactionTime *= 0.9;
      adjustment.ammoScarcity += 0.1;
    }
    
    return adjustment;
  }
}
```

## 8. Performance Optimization

### 8.1 FPS Performance Targets

```typescript
const fpsPerformanceTargets = {
  // Godot 4 specific targets
  mainThread: {
    maxFrameTime: 16.67,     // 60 FPS target
    fpsSystemBudget: 6.0,    // 6ms for FPS systems
    visualEffects: 4.0,      // 4ms for weapon effects
    audio: 1.0,              // 1ms for audio processing
    ui: 1.0                  // 1ms for UI updates
  },
  
  // Memory targets
  memory: {
    weaponAnimations: 50,    // MB for all weapon animations
    audioSamples: 100,       // MB for all audio samples
    weaponModels: 200,       // MB for all weapon models
    hitDetection: 10         // MB for hit detection systems
  },
  
  // Network targets (for future multiplayer)
  network: {
    tickRate: 64,            // updates per second
    maxLatency: 100,         // milliseconds
    packetSize: 1400         // bytes maximum
  }
};
```

### 8.2 Optimization Strategies

```typescript
class FPSOptimization {
  // Level-of-detail for weapons
  implementWeaponLOD(): WeaponLODStrategy {
    return {
      // First person (player weapon)
      firstPerson: {
        polygonCount: 'FULL',
        textureResolution: '4K',
        animationFrameRate: 60,
        particleEffects: 'FULL'
      },
      
      // Nearby players/NPCs (0-50m)
      nearbyThirdPerson: {
        polygonCount: 'HIGH',
        textureResolution: '2K',
        animationFrameRate: 30,
        particleEffects: 'REDUCED'
      },
      
      // Distant NPCs (50-200m)
      distantThirdPerson: {
        polygonCount: 'MEDIUM',
        textureResolution: '1K',
        animationFrameRate: 15,
        particleEffects: 'MINIMAL'
      },
      
      // Very distant (200m+)
      veryDistant: {
        polygonCount: 'LOW',
        textureResolution: '512px',
        animationFrameRate: 10,
        particleEffects: 'NONE'
      }
    };
  }
  
  // Bullet simulation optimization
  optimizeBulletPhysics(): BulletOptimization {
    return {
      // Hitscan for most weapons up to certain distance
      hitscanDistance: 50,     // meters
      
      // Projectile simulation for:
      projectileWeapons: [
        'GRENADE_LAUNCHER',
        'ROCKET_LAUNCHER',
        'CROSSBOW',
        'ARTIFACT_WEAPONS'
      ],
      
      // Bullet drop approximation
      bulletDropLUT: true,     // Use lookup table for drop calculation
      
      // Hit detection optimization
      hitDetection: {
        usesOcclusion: true,
        maxSimultaneousRaycasts: 32,
        hitCacheDuration: 0.1   // seconds
      }
    };
  }
}
```

## 9. Godot 4 Implementation

### 9.1 FPS Controller Structure

```csharp
// Godot 4 FPS controller architecture
public partial class FPSController : CharacterBody3D
{
    // Camera setup
    [Export] public Camera3D FPSCamera { get; set; }
    [Export] public Node3D CameraHolder { get; set; }
    
    // Movement properties
    [Export] public float WalkSpeed { get; set; } = 5.0f;
    [Export] public float SprintSpeed { get; set; } = 8.0f;
    [Export] public float JumpVelocity { get; set; } = 4.5f;
    [Export] public float Sensitivity { get; set; } = 0.001f;
    
    // Zone-specific properties
    [Export] public float MarkingLevel { get; set; } = 0.0f;
    [Export] public RadiationMeter RadMeter { get; set; }
    
    // Components
    private WeaponSystem weaponSystem;
    private InventorySystem inventorySystem;
    private AnomalyDetection anomalyDetector;
    
    public override void _Ready()
    {
        InitializeComponents();
        SetupInputHandling();
        ConfigurePhysics();
    }
    
    public override void _UnhandledInput(InputEvent @event)
    {
        // Mouse look
        if (@event is InputEventMouseMotion mouseMotion)
        {
            RotatePlayer(mouseMotion.Relative);
        }
        
        // Weapon operations
        if (@event.IsActionPressed("fire"))
        {
            weaponSystem.StartFiring();
        }
        
        if (@event.IsActionReleased("fire"))
        {
            weaponSystem.StopFiring();
        }
        
        // Zone interactions
        if (@event.IsActionPressed("interact"))
        {
            InteractWithEnvironment();
        }
    }
    
    public override void _PhysicsProcess(double delta)
    {
        HandleMovement(delta);
        UpdateZoneEffects(delta);
        ProcessMarkingEffects(delta);
    }
    
    private void HandleMovement(double delta)
    {
        Vector2 inputDir = Input.GetVector("move_left", "move_right", "move_forward", "move_back");
        Vector3 direction = Transform.Basis * new Vector3(inputDir.X, 0f, inputDir.Y);
        
        // Apply zone effects
        direction = ApplyZoneMovementEffects(direction);
        
        // Handle gravity
        if (!IsOnFloor())
        {
            Velocity = Velocity with { Y = Velocity.Y - GetGravity() * (float)delta };
        }
        
        // Handle jump
        if (Input.IsActionJustPressed("jump") && IsOnFloor())
        {
            Velocity = Velocity with { Y = JumpVelocity };
        }
        
        // Apply movement
        if (direction != Vector3.Zero)
        {
            Velocity = Velocity with 
            { 
                X = direction.X * GetCurrentSpeed(), 
                Z = direction.Z * GetCurrentSpeed() 
            };
        }
        else
        {
            Velocity = Velocity with 
            { 
                X = Mathf.MoveToward(Velocity.X, 0f, GetFrictionForce() * (float)delta), 
                Z = Mathf.MoveToward(Velocity.Z, 0f, GetFrictionForce() * (float)delta) 
            };
        }
        
        MoveAndSlide();
    }
}
```

### 9.2 Weapon System Integration

```csharp
// Weapon system for Godot 4
public partial class WeaponSystem : Node3D
{
    [Export] public PackedScene[] WeaponScenes { get; set; }
    [Export] public AudioStreamPlayer3D WeaponAudio { get; set; }
    
    private BaseWeapon currentWeapon;
    private List<BaseWeapon> inventory = new();
    
    // Zone integration
    private MarkingSystem markingSystem;
    private AnomalyDetector anomalyDetector;
    
    public override void _Ready()
    {
        markingSystem = GetNode<MarkingSystem>("/root/MarkingSystem");
        anomalyDetector = GetNode<AnomalyDetector>("../AnomalyDetector");
        
        LoadPlayerLoadout();
        SwitchToWeapon(0);
    }
    
    public void StartFiring()
    {
        if (currentWeapon != null && currentWeapon.CanFire())
        {
            // Check for zone effects on firing
            var zoneEffects = anomalyDetector.GetWeaponEffects();
            currentWeapon.StartFiring(zoneEffects);
            
            // Play spatial audio
            PlayWeaponSound(currentWeapon.FireSound);
        }
    }
    
    private void PlayWeaponSound(AudioStream sound)
    {
        WeaponAudio.Stream = sound;
        
        // Apply zone audio modifications
        var audioMods = GetZoneAudioModifications();
        WeaponAudio.PitchScale = audioMods.PitchModifier;
        WeaponAudio.VolumeDb = audioMods.VolumeModifier;
        
        WeaponAudio.Play();
    }
    
    // Zone-specific weapon behavior
    private void ApplyZoneEffects()
    {
        var marking = markingSystem.GetMarkingLevel();
        var anomalies = anomalyDetector.GetNearbyAnomalies();
        
        foreach (var weapon in inventory)
        {
            weapon.ApplyMarkingEffects(marking);
            weapon.ApplyAnomalyEffects(anomalies);
        }
    }
}
```

## Podsumowanie

System FPS w "Cieniu Podróżnika" łączy klasyczne mechaniki First Person Shooter z unikalnym setting'iem Strefy:

### 🎯 **Kluczowe Elementy:**

1. **Standard FPS Core** - Wszystkie podstawowe mechaniki FPS
2. **Zone Integration** - Anomalie wpływające na każdy aspekt rozgrywki
3. **Marking System** - Progresywna zmiana wszystkich mechanik
4. **Dynamic Adaptation** - Systemy reagujące na siebie nawzajem
5. **Godot 4 Optimization** - Spec specificzny dla silnika

### 🔧 **Unikalne Aspekty:**

- **Anomaly-affected Ballistics** - Kule mogą się zachowywać nieprzewidywalnie
- **Reality-bending Aiming** - Advanced marking pozwala na niemożliwe wcześniej cele
- **Adaptive Weapon Systems** - Broń "uczy się" razem z graczem
- **Multidimensional Audio** - Dźwięk z różnych warstw rzeczywistości
- **Physics-Breaking Interactions** - Wysokie naznaczenie = nieuwe możliwości

System jest zaprojektowany tak, aby:
- Zapewniać solid foundation dla FPS gameplay
- Stopniowo wprowadzać unikalne mechaniki Zone
- Utrzymywać balance między standardowym FPS a sci-fi elements
- Skalować się z player skill i progression
- Być fully integrated z innymi systems (AI, Economy, itd.)

---

> **Implementation Priority**: Zacznij od core FPS mechanics, następnie dodawaj Zone influences graduallу. Testuj każdy element pod kątem feel'u i responsiveness'u.