# Cień Podróżnika - Mechaniki Rozgrywki

Ten dokument szczegółowo opisuje mechaniki rozgrywki "Cienia Podróżnika", ich interakcje oraz praktyczne aspekty implementacji każdego systemu. Zawiera konkretne przykłady, edge cases i wytyczne balansowania.

> **Referencje**: Zobacz [technical-design.md](technical-design.md) dla implementacji technicznej i [story-document.md](story-document.md) dla kontekstu fabularnego.

## 1. System Naznaczenia Strefą

### 1.1 Mechanika Podstawowa

Naznaczenie to stopniowy proces transformacji gracza pod wpływem Strefy, wyrażony liczbowo od 0% do 100%.

```typescript
interface NaznczenieState {
  // Podstawowe wartości
  poziom: number;              // 0-100%
  szybkoscProgresji: number;   // Per hour
  odpornosc: number;           // Natural resistance
  
  // Efekty pozytywne
  zmyslStrefy: number;         // Anomaly detection +%
  detekcjaArtefaktow: number;  // Artifact detection +%
  odpornoscNaAnomalii: number; // Anomaly damage -%
  
  // Efekty negatywne
  stabilnoscPsychiczna: number; // Mental stability -%
  zdrowieMax: number;          // Max health -%
  zmeczenиe: number;           // Fatigue rate +%
  
  // Etapy transformacji
  faza: NaznaczeniePhase;      // Current phase
  objawySzczególne: Symptom[]; // Unique symptoms
}
```

### 1.2 Progresja Naznaczenia

**Tempo Progresji (bazowe 1%/godzina)**:
- **Centrum Strefy**: +500% (6%/godz.)
- **Wysokie Anomalie**: +300% (4%/godz.)
- **Średnie Anomalie**: +100% (2%/godz.)
- **Niskie Anomalie**: +50% (1.5%/godz.)
- **Obrzeża Strefy**: +0% (1%/godz.)

**Modyfikatory**:
```typescript
class NaznaczenieCalculator {
  calculateProgressionRate(context: GameContext): number {
    let baseRate = 1.0; // 1% per hour
    
    // Location modifiers
    const locationMultiplier = this.getLocationMultiplier(context.location);
    baseRate *= locationMultiplier;
    
    // Recent anomaly exposure
    const exposureMultiplier = this.getExposureMultiplier(context.recentExposure);
    baseRate *= exposureMultiplier;
    
    // Protective gear
    const protectionReduction = this.getProtectionReduction(context.equipment);
    baseRate *= (1 - protectionReduction);
    
    // Artifact effects
    const artifactModifier = this.getArtifactModifier(context.artifacts);
    baseRate *= artifactModifier;
    
    // Natural resistance (varies by character)
    const resistanceModifier = 1 - (context.character.nauralResistance / 100);
    baseRate *= resistanceModifier;
    
    return Math.max(0.1, baseRate); // Minimum 0.1%/hour
  }
}
```

### 1.3 Fazy Naznaczenia

#### Faza 1: Adaptacyjna (0-20%)
- **Pierwsze symptomy**: Zwiększone zmęczenie, żywe sny
- **Mechaniki**: 
  - Zmysł Strefy +5% per 5% poziomu
  - Stamina regeneration -2% per 5% poziomu
  - Unique dream sequences przy poziomie 15%

#### Faza 2: Aklimatyzacja (20-40%)  
- **Objawy**: Zmiany percepcji, sporadyczne podwójne widzenie
- **Mechaniki**:
  - Detekcja anomalii +10% per 5% poziomu
  - Detekcja artefaktów +5% per 5% poziomu  
  - Chance na hallucynacje 1% per 10% poziomu
  
#### Faza 3: Transformacja (40-70%)
- **Objawy**: Widoczne zmiany fizyczne, zwiększona agresja
- **Mechaniki**:
  - Damage od anomalii -15% per 5% poziomu
  - Social acceptance -5% per 5% poziomu
  - Unique dialogue options z Kultem

#### Faza 4: Dysocjacja (70-90%)
- **Objawy**: Częste "nieobecności", intuicyjne wyczuwanie artefaktów
- **Mechaniki**:
  - Automatic artifact detection w promieniu 50m
  - Random teleportation events (0.1% chance/hour)
  - Dialogue changes - philosophical, abstract responses

#### Faza 5: Próg Transformacji (90-95%)
- **Krytyczny punkt**: Gracz musi podjąć decyzję
- **Opcje**:
  - Akceptacja → Syndrom Przewodnika
  - Opór → Možliwość zatrzymania progresji (trudne)
  - Brak działania → Automatyczne przejście do Skorupy

#### Faza 6: Alternatywne Zakończenia (95-100%)
- **Skorupa** (100%): Game Over - gracz traci kontrolę
- **Syndrom Przewodnika** (stabilny na 95%): Nowa forma rozgrywki

### 1.4 Praktyczne Przykłady

**Scenariusz 1: Pierwsza wizyta w Strefie**
```
Gracz: Poziom 0%, Lokacja: Obrzeża
Czas spędzony: 4 godziny
Progresja: 4% (bazowe tempo)
Efekty: Pierwsza noc - dziwne sny, +1% zmysł strefy
```

**Scenariusz 2: Eksploracja centrum**
```
Gracz: Poziom 25%, Lokacja: Centrum Strefy  
Wyposażenie: Kombineson rad. (-30% progresji)
Czas: 2 godziny w centrum
Progresja: 25% + (6% × 0.7 × 2) = 33.4%
Efekty: Przejście do Fazy 3, zmiany fizyczne widoczne dla NPC
```

## 2. System Anomalii

### 2.1 Mechanika Wykrywania

Anomalie mają różne poziomy wykrywalności i zasięgi oddziaływania:

```typescript
interface AnomalyDetection {
  // Wykrywalność pasywna (bez sprzętu)
  baseDetectionRange: number;    // Metry
  visualCues: VisualCue[];       // Wizualne wskazówki
  audioMarkers: AudioMarker[];   // Dźwiękowe oznaki
  
  // Modyfikatory detekcji
  equipmentBonus: number;        // +% od detektorów
  experienceBonus: number;       // +% od doświadczenia
  markingBonus: number;          // +% od naznaczenia
  weatherPenalty: number;        // -% od pogody
  
  // Zagrożenie
  dangerRadius: number;          // Safe distance (m)
  lethality: number;            // 0-1 scale
  warningSystem: WarningType;    // How danger is communicated
}
```

### 2.2 Typy Anomalii - Szczegółowo

#### Anomalie Termiczne

**Żar** - Termiczny wir ognia
```typescript
const zarAnomaly: ThermalAnomaly = {
  type: 'Żar',
  baseTemperature: 800,      // °C at center
  damageRadius: 3,           // meters
  detectionRange: 15,        // Visual shimmer
  audioRange: 25,            // Crackling sounds
  
  // Damage curve
  damageCurve: (distance) => {
    if (distance >= 3) return 0;
    return 50 * (1 - distance/3); // 50 HP/s at center
  },
  
  // Effects
  effects: [
    { type: 'EQUIPMENT_DAMAGE', rate: 10 }, // %/second
    { type: 'DEHYDRATION', rate: 5 },
    { type: 'VISIBILITY_REDUCTION', radius: 10 }
  ],
  
  // Bypass methods
  bypassMethods: [
    { method: 'THROWING_OBJECT', successRate: 0.8 },
    { method: 'TIMING_PATTERN', difficulty: 7 },
    { method: 'SPECIAL_EQUIPMENT', requirement: 'Heat Suit' }
  ]
}
```

**Mróz** - Kriogeniczna kieszeń
```typescript
const mrozAnomaly: ThermalAnomaly = {
  type: 'Mróz',
  baseTemperature: -200,     // °C at center  
  damageRadius: 2,
  detectionRange: 20,        // Frost formation
  audioRange: 15,            // Ice cracking
  
  damageCurve: (distance) => {
    if (distance >= 2) return 0;
    return 30 + 20 * (1 - distance/2); // 30-50 HP/s
  },
  
  effects: [
    { type: 'STAMINA_PENALTY', percentage: 50 },
    { type: 'MOVEMENT_SLOW', percentage: 30 },
    { type: 'EQUIPMENT_BRITTLE', threshold: -50 }
  ],
  
  bypassMethods: [
    { method: 'HEAT_SOURCE', requirement: 'Portable Heater' },
    { method: 'ALCOHOL_IMMUNITY', duration: 30 },
    { method: 'SPECIAL_CLOTHING', requirement: 'Arctic Suit' }
  ]
}
```

#### Anomalie Grawitacyjne

**Wyrwa** - Punkt zwiększonej grawitacji
```typescript
const wyrwaAnomaly: GravityAnomaly = {
  type: 'Wyrwa',
  gravityMultiplier: 10,     // 10G at center
  attractionRadius: 8,       // Pull radius
  lethalRadius: 1,           // Instant death zone
  detectionRange: 30,        // Objects pulled in air
  
  pullStrength: (distance) => {
    if (distance <= 1) return Infinity;
    if (distance >= 8) return 0;
    return 100 * Math.pow(8 - distance, 2);
  },
  
  effects: [
    { type: 'OBJECT_ATTRACTION', minWeight: 0.1 },
    { type: 'PLAYER_PULL', resistance: 'mass + equipment' },
    { type: 'STRUCTURAL_DAMAGE', affectedObjects: 'loose items' }
  ],
  
  bypassMethods: [
    { method: 'THROWING_HEAVY_OBJECT', success: 0.7 },
    { method: 'MAGNETIC_ANCHOR', requirement: 'Heavy Anchor' },
    { method: 'TEAM_SUPPORT', minPlayers: 2 }
  ]
}
```

#### Anomalie Psychiczne

**Symfonia** - Zaburzona zona akustyczna
```typescript
const symfoniaAnomaly: PsychicAnomaly = {
  type: 'Symfonia',
  effectRadius: 15,
  intensityLayers: [
    { radius: 5, effect: 'HALLUCINATIONS', strength: 0.8 },
    { radius: 10, effect: 'DISORIENTATION', strength: 0.5 },
    { radius: 15, effect: 'UNEASE', strength: 0.2 }
  ],
  
  psychicDamage: (distance, exposure) => {
    const intensity = Math.max(0, (15 - distance) / 15);
    return intensity * exposure * 0.5; // % per second
  },
  
  effects: [
    { type: 'COMPASS_DISRUPTION', radius: 20 },
    { type: 'REALITY_DISTORTION', chance: 0.1 },
    { type: 'MEMORY_GAPS', duration: 300 },
    { type: 'PHANTOM_SOUNDS', variety: 'voices|music|warnings' }
  ],
  
  counterMeasures: [
    { method: 'EARPLUGS', effectiveness: 0.3 },
    { method: 'HIGH_MARKING', threshold: 40, immunity: 0.7 },
    { method: 'PSYCHIC_SHIELD', artifact: 'Mind Ward' }
  ]
}
```

### 2.3 Interakcje między Anomaliami

```typescript
class AnomalyInteractionSystem {
  // Sprawdza czy anomalie wzajemnie się wpływają
  checkInteractions(anomaly1: Anomaly, anomaly2: Anomaly): Interaction[] {
    const distance = anomaly1.position.distanceTo(anomaly2.position);
    const maxRange = Math.max(anomaly1.influenceRadius, anomaly2.influenceRadius);
    
    if (distance > maxRange) return [];
    
    const interactions = [];
    
    // Thermal + Electric = Plasma
    if (this.isType(anomaly1, 'Thermal') && this.isType(anomaly2, 'Electric')) {
      if (distance < 5) {
        interactions.push(new PlasmaInteraction(anomaly1, anomaly2));
      }
    }
    
    // Gravity + Spatial = Distortion Field
    if (this.isType(anomaly1, 'Gravity') && this.isType(anomaly2, 'Spatial')) {
      if (distance < 10) {
        interactions.push(new DistortionFieldInteraction(anomaly1, anomaly2));
      }
    }
    
    // Psychic + Multiple = Cascade Effect
    if (this.isType(anomaly1, 'Psychic') && this.getAnomaliesInRadius(anomaly1.position, 20).length >= 3) {
      interactions.push(new PsychicCascadeInteraction(anomaly1));
    }
    
    return interactions;
  }
}
```

## 3. System Artefaktów

### 3.1 Generacja i Rzadkość

Artefakty są generowane w oparciu o kompleksowy system prawdopodobieństwa:

```typescript
interface ArtifactSpawnRate {
  // Bazowe szanse (per hour)
  baseChance: number;              // 0.1%
  
  // Modyfikatory lokacji
  locationMultipliers: {
    center: 5.0,        // Centrum strefy
    highAnomaly: 3.0,   // Wysokie anomalie
    mediumAnomaly: 2.0, // Średnie anomalie  
    lowAnomaly: 1.5,    // Niskie anomalie
    edge: 0.5           // Obrzeża
  };
  
  // Modyfikatory anomalii
  anomalyTypeMultipliers: {
    thermal: 1.2,
    gravity: 1.5,
    electric: 1.3,
    spatial: 2.0,       // Najrzadsze ale najcenniejsze
    psychic: 0.8
  };
  
  // Rzadkość
  rarityDistribution: {
    common: 0.65,      // 65%
    uncommon: 0.25,    // 25%
    rare: 0.08,        // 8%
    epic: 0.019,       // 1.9%
    legendary: 0.001   // 0.1%
  };
}
```

### 3.2 Właściwości Artefaktów

#### Artefakty Energetyczne

**Bateria** (Common)
```typescript
const bateriaArtifact: EnergeticArtifact = {
  name: 'Bateria',
  rarity: 'Common',
  effectRadius: 2,
  
  primaryEffect: {
    type: 'STAMINA_REGENERATION',
    value: 150,        // % of normal rate
    duration: PASSIVE  // Always active when equipped
  },
  
  secondaryEffects: [
    { type: 'ELECTRIC_RESISTANCE', value: 20 }, // %
    { type: 'DETECTOR_BOOST', value: 10 }       // %
  ],
  
  // Drawbacks
  negativeEffects: [
    { type: 'RADIATION_EMISSION', value: 1 },   // rads/hour
    { type: 'WEIGHT_PENALTY', value: 2 }        // kg
  ],
  
  // Może być ulepszony
  upgradePaths: [
    { 
      artifact: 'Super Bateria',
      requirements: ['Bateria', 'Electric Coil', 'Stabilizer']
    }
  ]
}
```

**Ognik** (Rare)
```typescript
const ognikArtifact: EnergeticArtifact = {
  name: 'Ognik',
  rarity: 'Rare',
  effectRadius: 15,
  
  primaryEffect: {
    type: 'THERMAL_SHIELD',
    value: 80,         // % damage reduction
    triggers: ['ACTIVATE_ON_THERMAL_DAMAGE']
  },
  
  activeAbility: {
    name: 'Thermal Burst',
    cooldown: 300,     // 5 minutes
    effect: 'AREA_THERMAL_DAMAGE',
    radius: 10,
    damage: 100,
    duration: 5
  },
  
  // Interakcje z otoczeniem
  environmentalEffects: [
    { type: 'MELT_ICE', radius: 5 },
    { type: 'IGNITE_FLAMMABLES', chance: 0.3 },
    { type: 'WARM_AREA', temperature: 25 }
  ]
}
```

#### Artefakty Biologiczne

**Regenerator** (Uncommon)
```typescript
const regeneratorArtifact: BiologicalArtifact = {
  name: 'Regenerator',
  rarity: 'Uncommon',
  
  primaryEffect: {
    type: 'HEALTH_REGENERATION',
    value: 2,          // HP per second
    conditions: ['OUT_OF_COMBAT', 'NOT_IN_ANOMALY']
  },
  
  adaptiveEffects: {
    // Efficacy improves with use
    learningCurve: (timesUsed) => {
      return Math.min(1.5, 1 + timesUsed * 0.001);
    },
    
    // Adapts to player's common injuries
    specialization: {
      thermalDamage: { threshold: 10, bonus: 0.3 },
      radiationPoisoning: { threshold: 20, bonus: 0.5 },
      bleedingWounds: { threshold: 15, bonus: 0.4 }
    }
  },
  
  // Negative adaptation
  tolerance: {
    buildup: 0.1,      // Per hour of use
    maxPenalty: 0.5,   // 50% reduction at maximum
    decayRate: 0.02    // Per hour without use
  }
}
```

#### Artefakty Przestrzenne

**Portal Flask** (Legendary)
```typescript
const portalFlaskArtifact: SpatialArtifact = {
  name: 'Portal Flask',
  rarity: 'Legendary',
  charges: 3,
  
  primaryEffect: {
    type: 'TELEPORTATION',
    maxDistance: 100,
    restrictions: ['LINE_OF_SIGHT', 'NOT_THROUGH_ANOMALIES'],
    castTime: 3,       // seconds
    cooldown: 3600     // 1 hour
  },
  
  // Zaawansowane użycie
  masterUse: {
    requirement: 'marking >= 70%',
    effect: 'DIMENSIONAL_STEP',
    phaseTime: 2,      // seconds in between dimensions
    allows: ['THROUGH_WALLS', 'AVOID_DAMAGE']
  },
  
  // Ryzyko użycia
  complications: [
    { 
      chance: 0.05,
      effect: 'TEMPORAL_DISPLACEMENT',
      duration: 'random(300, 3600)'
    },
    {
      chance: 0.02,
      effect: 'DIMENSIONAL_ECHO',
      description: 'Player appears in multiple locations'
    }
  ]
}
```

### 3.3 Kombinacje i Synergii Artefaktów

```typescript
class ArtifactSynergySystem {
  calculateSynergy(artifacts: Artifact[]): Synergy[] {
    const synergies = [];
    
    // Electrical set bonus
    const electricArtifacts = artifacts.filter(a => a.category === 'Electric');
    if (electricArtifacts.length >= 2) {
      synergies.push({
        name: 'Electrical Mastery',
        effect: 'ELECTRIC_IMMUNITY',
        bonus: 'CHAIN_LIGHTNING_ABILITY'
      });
    }
    
    // Thermal balance
    const hotArtifacts = artifacts.filter(a => a.thermalType === 'Hot');
    const coldArtifacts = artifacts.filter(a => a.thermalType === 'Cold');
    if (hotArtifacts.length > 0 && coldArtifacts.length > 0) {
      synergies.push({
        name: 'Thermal Equilibrium',
        effect: 'TEMPERATURE_IMMUNITY',
        cost: 'REDUCED_INDIVIDUAL_EFFECTS'
      });
    }
    
    // Reality warping (3+ spatial artifacts)
    const spatialArtifacts = artifacts.filter(a => a.category === 'Spatial');
    if (spatialArtifacts.length >= 3) {
      synergies.push({
        name: 'Reality Manipulation',
        effect: 'LOCALIZED_PHYSICS_CONTROL',
        duration: 30,
        cooldown: 7200
      });
    }
    
    return synergies;
  }
}
```

## 4. System Interakcji NPC

### 4.1 Mechanika Relacji

System relacji w grze jest wielowymiarowy i dynamiczny:

```typescript
interface NPCRelationship {
  // Podstawowe wartości
  trust: number;        // -100 to +100
  respect: number;      // -100 to +100  
  fear: number;         // 0 to 100
  attraction: number;   // -100 to +100 (romantic/platonic)
  
  // Historie interakcji
  sharedExperiences: Experience[];
  conflictHistory: Conflict[];
  favorsDone: Favor[];
  
  // Modyfikatory
  factionBonus: number;    // From faction relationships
  reputationImpact: number; // From general reputation
  markingEffect: number;    // From player's marking level
  
  // Obliczanie ogólnej relacji
  calculateOverallRelation(): RelationshipLevel {
    const weighted = this.trust * 0.4 + 
                    this.respect * 0.3 + 
                    this.fear * -0.2 +
                    this.attraction * 0.1;
    
    // Apply modifiers
    const final = weighted + this.factionBonus + this.reputationImpact + this.markingEffect;
    
    return this.getRelationshipLevel(final);
  }
}
```

### 4.2 Dynamiczne Dialogi

```typescript
class DialogueSystem {
  generateDialogue(npc: NPC, context: InteractionContext): DialogueOptions {
    const relationship = this.getRelationship(npc, context.player);
    const options = [];
    
    // Podstawowe opcje zawsze dostępne
    options.push(...this.getBasicOptions(npc, context));
    
    // Opcje zależne od relacji
    if (relationship.trust > 50) {
      options.push(...this.getTrustedOptions(npc, context));
    }
    
    if (relationship.fear > 70) {
      options.push(...this.getIntimidationOptions(npc, context));
    }
    
    // Opcje zależne od naznaczenia
    if (context.player.marking > 60) {
      options.push(...this.getMarkedOptions(npc, context));
    }
    
    // Opcje kontekstowe
    if (context.location.hasAnomaly) {
      options.push(...this.getAnomalyOptions(npc, context));
    }
    
    if (context.recentEvents.includes('ARTIFACT_FOUND')) {
      options.push(...this.getArtifactOptions(npc, context));
    }
    
    // Filtruj opcje według osobowości NPC
    return this.filterByPersonality(options, npc);
  }
  
  private getMarkedOptions(npc: NPC, context: InteractionContext): DialogueOption[] {
    if (npc.faction === 'Dzieci Wędrowca') {
      return [
        {
          text: '[Naznaczony] Czuję obecność Podróżnika...',
          response: 'CULT_RECOGNITION',
          consequences: [
            { type: 'REPUTATION_CHANGE', faction: 'Dzieci Wędrowca', value: 10 },
            { type: 'UNLOCK_CULT_QUESTS' }
          ]
        }
      ];
    } else if (npc.personality.traits.includes('AFRAID_OF_MARKED')) {
      return [
        {
          text: '[Naznaczony] *Twoje oczy płoną dziwnym światłem*',
          response: 'FEARFUL_REACTION',
          consequences: [
            { type: 'RELATIONSHIP_CHANGE', stat: 'fear', value: 20 },
            { type: 'POSSIBLE_FLEE_REACTION' }
          ]
        }
      ];
    }
    
    return [];
  }
}
```

### 4.3 Memoria i Learning NPC

```typescript
class NPCMemorySystem {
  // NPC zapamiętują i uczą się z interakcji
  updateMemoryAfterInteraction(npc: NPC, interaction: Interaction): void {
    const memory = new InteractionMemory({
      playerId: interaction.player.id,
      type: interaction.type,
      outcome: interaction.outcome,
      location: interaction.location,
      items: interaction.itemsInvolved,
      timestamp: Date.now(),
      emotionalImpact: this.calculateEmotionalImpact(npc, interaction)
    });
    
    // Dodaj do pamięci
    npc.memories.addMemory(memory);
    
    // Aktualizuj pattern recognition
    npc.patterns.updatePattern(interaction.type, interaction.outcome);
    
    // Uczenie się z rezultatów
    this.updateLearning(npc, interaction);
  }
  
  private updateLearning(npc: NPC, interaction: Interaction): void {
    // Jeśli gracz spełnił obietnicę
    if (interaction.outcome === 'PROMISE_FULFILLED') {
      npc.expectations.updateReliability('PLAYER', 1.1);
      npc.trust += 5;
    }
    
    // Jeśli gracz kłamał
    if (interaction.outcome === 'DECEPTION_DISCOVERED') {
      npc.expectations.updateReliability('PLAYER', 0.5);
      npc.trust -= 15;
      npc.patterns.addDeceptionMarker(interaction.player.id);
    }
    
    // Jeśli gracz pomógł w trudnej sytuacji
    if (interaction.context.danger > 50 && interaction.outcome === 'HELPED') {
      npc.memories.markAsSignificant(memory.id);
      npc.loyalty += 10;
    }
  }
  
  // NPC używają pamięci do podejmowania decyzji
  assessPlayerReliability(npc: NPC, playerId: string): ReliabilityAssessment {
    const relevantMemories = npc.memories.getMemoriesAboutPlayer(playerId);
    
    let promisesFulfilled = 0;
    let promisesBroken = 0;
    let helpInDanger = 0;
    let deceptions = 0;
    
    for (const memory of relevantMemories) {
      switch (memory.outcome) {
        case 'PROMISE_FULFILLED':
          promisesFulfilled++;
          break;
        case 'PROMISE_BROKEN':
          promisesBroken++;
          break;
        case 'HELPED_IN_DANGER':
          helpInDanger++;
          break;
        case 'DECEPTION_DISCOVERED':
          deceptions++;
          break;
      }
    }
    
    return {
      trustworthiness: this.calculateTrustworthiness(promisesFulfilled, promisesBroken),
      reliability: this.calculateReliability(helpInDanger, relevantMemories.length),
      honesty: this.calculateHonesty(deceptions, relevantMemories.length),
      overallAssessment: this.getOverallAssessment(
        promisesFulfilled, promisesBroken, helpInDanger, deceptions
      )
    };
  }
}
```

## 5. System Handlu i Ekonomii

### 5.1 Dynamiczne Ceny

```typescript
class EconomicSystem {
  // Ceny zmieniają się w oparciu o podaż i popyt
  calculateDynamicPrice(item: Item, location: Location): number {
    const basePrice = item.basePrice;
    let finalPrice = basePrice;
    
    // Supply and demand
    const supply = this.getLocalSupply(item, location);
    const demand = this.getLocalDemand(item, location);
    const supplyDemandRatio = demand / Math.max(supply, 1);
    
    finalPrice *= (0.5 + 0.8 * supplyDemandRatio);
    
    // Location factors
    const locationModifier = this.getLocationModifier(item, location);
    finalPrice *= locationModifier;
    
    // Recent events
    const eventModifier = this.getEventModifier(item, location);
    finalPrice *= eventModifier;
    
    // Trader relationship
    const relationshipModifier = this.getRelationshipModifier(player, trader);
    finalPrice *= relationshipModifier;
    
    // Random market fluctuation (±5%)
    const fluctuation = 0.95 + Math.random() * 0.1;
    finalPrice *= fluctuation;
    
    return Math.round(finalPrice);
  }
  
  private getEventModifier(item: Item, location: Location): number {
    const recentEvents = this.getRecentEvents(location, 24); // Last 24 hours
    
    for (const event of recentEvents) {
      switch (event.type) {
        case 'BLOWOUT':
          if (item.category === 'PROTECTION') return 1.8;
          if (item.category === 'DETECTOR') return 1.5;
          break;
          
        case 'FACTION_CONFLICT':
          if (item.category === 'WEAPON') return 2.0;
          if (item.category === 'AMMO') return 1.7;
          if (item.category === 'MEDICAL') return 1.5;
          break;
          
        case 'ARTIFACT_DISCOVERY':
          if (item.category === 'CONTAINER') return 1.3;
          if (item.type === 'DETECTOR') return 1.6;
          break;
          
        case 'NPC_DEATH':
          // Deceased NPC's items flood the market
          if (event.npc.inventory.includes(item.type)) return 0.6;
          break;
      }
    }
    
    return 1.0;
  }
}
```

### 5.2 Trading Mechanics

```typescript
interface TradingSession {
  player: Player;
  trader: NPC;
  relationship: NPCRelationship;
  location: Location;
  
  // Available actions
  actions: {
    barter: boolean;        // Based on speech skill
    intimidate: boolean;    // Based on strength/reputation
    seduce: boolean;        // Based on charisma/relationship
    technical: boolean;     // Based on technical knowledge
  };
  
  // Modifiers
  modifiers: {
    markup: number;         // Trader's price modifier
    discount: number;       // Player's negotiation bonus
    secrecy: number;        // Illegal goods modifier
    urgency: number;        // Time pressure modifier
  };
}

class TradingNegotiation {
  startNegotiation(session: TradingSession, offer: TradeOffer): NegotiationResult {
    const initialResponse = this.traderInitialResponse(session, offer);
    
    // Trading minigame begins
    return this.negotiationMinigame({
      session,
      offer,
      initialResponse,
      maxRounds: this.getMaxRounds(session),
      playerOptions: this.getPlayerOptions(session),
      traderPersonality: session.trader.personality
    });
  }
  
  private traderInitialResponse(session: TradingSession, offer: TradeOffer): TraderResponse {
    const trader = session.trader;
    const value_player = this.evaluateOffer(offer.playerItems, session.location);
    const value_trader = this.evaluateOffer(offer.traderItems, session.location);
    
    const fairValueRatio = value_player / value_trader;
    
    if (fairValueRatio >= 0.9 && fairValueRatio <= 1.1) {
      return {
        type: 'ACCEPT',
        comment: trader.generateComment('FAIR_DEAL')
      };
    } else if (fairValueRatio < 0.6) {
      return {
        type: 'REJECT_INSULTING',
        comment: trader.generateComment('INSULTING_OFFER'),
        relationshipImpact: -5
      };
    } else if (fairValueRatio < 0.8) {
      return {
        type: 'COUNTER_OFFER',
        comment: trader.generateComment('TOO_LOW'),
        counterOffer: this.generateCounterOffer(offer, trader, 0.85)
      };
    } else { // fairValueRatio > 1.1
      return {
        type: 'ACCEPT_EAGERLY',
        comment: trader.generateComment('GREAT_DEAL'),
        relationshipImpact: 3
      };
    }
  }
}
```

### 5.3 Faction Economics

```typescript
class FactionEconomics {
  // Każda frakcja ma własne zasoby ekonomiczne
  calculateFactionWealth(faction: Faction): EconomicState {
    const resources = faction.resources;
    const income = this.calculateIncome(faction);
    const expenses = this.calculateExpenses(faction);
    const assets = this.calculateAssets(faction);
    
    return {
      liquidRubles: resources.rubles,
      artifacts: resources.artifacts,
      supplies: resources.supplies,
      equipment: resources.equipment,
      
      // Income streams
      weeklyIncome: {
        artifactSales: income.artifacts,
        protection: income.protection,  // "Taxes" from territory
        missions: income.missions,
        trade: income.trade
      },
      
      // Fixed costs
      weeklyExpenses: {
        salaries: expenses.salaries,
        equipment: expenses.equipment,
        maintenance: expenses.maintenance,
        operations: expenses.operations
      },
      
      netWeeklyChange: income.total - expenses.total,
      wealthRating: this.calculateWealthRating(assets)
    };
  }
  
  // Frakcje inwestują w swoje cele
  processEconomicDecisions(faction: Faction): void {
    const budget = faction.getBudget();
    const priorities = faction.getPriorities();
    
    for (const priority of priorities) {
      const allocation = budget * priority.weight;
      
      switch (priority.type) {
        case 'MILITARY':
          this.investInMilitary(faction, allocation);
          break;
        case 'RESEARCH':
          this.investInResearch(faction, allocation);
          break;
        case 'INFRASTRUCTURE':
          this.investInInfrastructure(faction, allocation);
          break;
        case 'EXPANSION':
          this.investInExpansion(faction, allocation);
          break;
      }
    }
  }
  
  // Frakcje reagują na wydarzenia ekonomiczne
  onEconomicEvent(event: EconomicEvent): void {
    const affectedFactions = this.getAffectedFactions(event);
    
    for (const faction of affectedFactions) {
      const impact = this.calculateImpact(event, faction);
      
      // Adjust strategy
      faction.adjustStrategy(impact);
      
      // Economic response
      faction.respondToEconomicPressure(impact);
      
      // Political consequences
      if (impact.severity > 0.5) {
        this.triggerPoliticalResponse(faction, event);
      }
    }
  }
}
```

## 6. System Pogody i Środowiska

### 6.1 Dynamiczna Pogoda

```typescript
interface WeatherSystem {
  current: WeatherState;
  forecast: WeatherForecast[];
  
  // Base weather patterns
  patterns: {
    spring: WeatherPattern;
    summer: WeatherPattern;
    autumn: WeatherPattern;
    winter: WeatherPattern;
  };
  
  // Zone-specific modifications
  zoneEffects: {
    anomalyInfluence: AnomalyWeatherEffect[];
    artificialWeather: ArtificialWeatherSource[];
    microClimates: MicroClimate[];
  };
}

class WeatherSimulation {
  updateWeather(deltaTime: number): void {
    const timeOfYear = this.getTimeOfYear();
    const basePattern = this.getBasePattern(timeOfYear);
    
    // Apply natural progression
    this.naturalWeatherProgression(basePattern, deltaTime);
    
    // Apply zone effects
    this.applyZoneEffects();
    
    // Random events
    this.checkForWeatherEvents();
    
    // Update forecast
    this.updateForecast();
  }
  
  private checkForWeatherEvents(): void {
    // Chance for anomalous weather
    if (Math.random() < 0.001) { // 0.1% per hour
      this.triggerAnomalousWeather();
    }
    
    // Seasonal events
    if (this.isSeasonalEventTime()) {
      this.triggerSeasonalEvent();
    }
  }
  
  private triggerAnomalousWeather(): void {
    const types = [
      'ACID_RAIN',
      'MAGNETIC_STORM', 
      'TIME_DILATION_FOG',
      'GRAVITY_ANOMALY_WINDS',
      'PSYCHIC_AURORA'
    ];
    
    const type = types[Math.floor(Math.random() * types.length)];
    const event = new AnomalousWeatherEvent(type);
    
    this.activateWeatherEvent(event);
  }
}
```

### 6.2 Wpływ Pogody na Rozgrywkę

```typescript
interface WeatherEffect {
  // Movement effects
  movementSpeedModifier: number;
  staminaConsumptionModifier: number;
  
  // Detection effects
  visualRangeModifier: number;
  audioRangeModifier: number;
  anomalyDetectionModifier: number;
  
  // Equipment effects
  equipmentDegradationRate: number;
  electronicsFailureChance: number;
  
  // NPC behavior
  npcMovementPattern: NPCMovementPattern;
  npcIsolationTendency: number;
  
  // Special effects
  specialEffects: SpecialWeatherEffect[];
}

// Example: Blowout approaching
const blowoutApproachingWeather: WeatherEffect = {
  // Before actual blowout hits
  duration: 3600, // 1 hour warning
  
  movementSpeedModifier: 1.2,    // NPCs move faster, urgency
  staminaConsumptionModifier: 1.3, // Anxiety increases fatigue
  
  visualRangeModifier: 0.7,      // Ominous haze
  audioRangeModifier: 1.5,       // Sounds carry further
  anomalyDetectionModifier: 2.0,  // Anomalies more active
  
  // NPCs seek shelter
  npcMovementPattern: 'SEEK_SHELTER',
  npcIsolationTendency: 0.9,
  
  specialEffects: [
    { type: 'STATIC_DISCHARGE', frequency: 0.1 },
    { type: 'PHANTOM_SOUNDS', intensity: 0.5 },
    { type: 'EQUIPMENT_INTERFERENCE', chance: 0.05 }
  ]
};
```

## 7. System Balansowania

### 7.1 Miary Progressu Gracza

```typescript
class ProgressTracker {
  // Śledzimy różne aspekty progressu
  trackPlayerProgress(): PlayerProgress {
    return {
      // Mechaniczny progress
      level: this.getPlayerLevel(),
      healthMax: this.getMaxHealth(),
      staminaMax: this.getMaxStamina(),
      carrying_capacity: this.getCarryingCapacity(),
      
      // Umiejętności
      zones_explored: this.getExploredZones(),
      artifacts_found: this.getArtifactsFound(),
      anomalies_bypassed: this.getAnomaliesBypassed(),
      
      // Społeczny progress
      faction_standings: this.getFactionStandings(),
      npc_relationships: this.getNPCRelationships(),
      reputation: this.getReputation(),
      
      // Naznaczenie progress
      marking_level: this.getMarkingLevel(),
      unique_abilities: this.getUnlockedAbilities(),
      
      // Meta progress  
      playtime: this.getPlaytime(),
      story_completion: this.getStoryCompletion(),
      secret_completion: this.getSecretCompletion()
    };
  }
  
  // Identyfikacja bottlenecków
  identifyBottlenecks(): ProgressBottleneck[] {
    const progress = this.trackPlayerProgress();
    const bottlenecks = [];
    
    // Player stuck in one area?
    if (progress.zones_explored < EXPECTED_ZONES_BY_TIME[progress.playtime]) {
      bottlenecks.push({
        type: 'EXPLORATION',
        severity: 'MEDIUM',
        suggestion: 'Provide exploration incentives'
      });
    }
    
    // No meaningful NPC interactions?
    if (progress.npc_relationships.meaningful < 3 && progress.playtime > 1200) {
      bottlenecks.push({
        type: 'SOCIAL',
        severity: 'HIGH',
        suggestion: 'Improve NPC interaction visibility'
      });
    }
    
    // Avoiding anomalies instead of learning?
    if (progress.anomalies_bypassed < 10 && progress.playtime > 600) {
      bottlenecks.push({
        type: 'SKILL_DEVELOPMENT',
        severity: 'LOW',
        suggestion: 'Tutorial for anomaly navigation'
      });
    }
    
    return bottlenecks;
  }
}
```

### 7.2 Automated Difficulty Adjustment

```typescript
class DifficultyManager {
  // Automatyczne dostosowywanie trudności
  adjustDifficulty(): void {
    const performance = this.assessPlayerPerformance();
    const frustrationLevel = this.calculateFrustrationLevel();
    const engagement = this.measureEngagement();
    
    if (frustrationLevel > FRUSTRATION_THRESHOLD) {
      this.reduceDifficulty();
    } else if (performance.successRate > 0.85 && engagement.boredom > 0.5) {
      this.increaseDifficulty();
    }
  }
  
  private reduceDifficulty(): void {
    // Subtle adjustments, players shouldn't notice
    this.adjustParameters({
      anomaly_damage: 0.9,           // -10% damage
      anomaly_detection_range: 1.1,  // +10% detection range
      artifact_spawn_rate: 1.1,      // +10% spawn rate
      npc_aggression: 0.9,           // -10% aggression
      item_durability: 1.1           // +10% durability
    });
    
    // Don't adjust all at once
    this.selectRandomAdjustments(3);
  }
  
  private assessPlayerPerformance(): PerformanceMetrics {
    const recentDeaths = this.getRecentDeaths(3600); // Last hour
    const successfulAnomalyNavigation = this.getSuccessfulNavigation(3600);
    const artifactsFound = this.getRecentArtifacts(3600);
    const questCompletion = this.getQuestCompletionRate();
    
    return {
      survivalRate: 1 - (recentDeaths / 10),
      skillDemonstration: successfulAnomalyNavigation / 5,
      exploration: artifactsFound / 2,
      progression: questCompletion,
      overallPerformance: this.calculateOverall([
        survivalRate, skillDemonstration, exploration, progression
      ])
    };
  }
}
```

### 7.3 Economy Balancing

```typescript
class EconomyBalancer {
  // Kontrola inflacji/deflacji w grze
  monitorEconomicHealth(): EconomicHealthReport {
    const markets = this.getAllMarkets();
    let inflationRate = 0;
    let liquidityLevel = 0;
    let tradingActivity = 0;
    
    for (const market of markets) {
      inflationRate += this.calculateInflation(market);
      liquidityLevel += this.calculateLiquidity(market);
      tradingActivity += this.calculateActivity(market);
    }
    
    // Average across markets
    inflationRate /= markets.length;
    liquidityLevel /= markets.length;
    tradingActivity /= markets.length;
    
    return {
      inflation: inflationRate,
      liquidity: liquidityLevel,
      activity: tradingActivity,
      healthScore: this.calculateHealthScore(inflationRate, liquidityLevel, tradingActivity),
      recommendations: this.generateRecommendations(inflationRate, liquidityLevel, tradingActivity)
    };
  }
  
  // Automatyczne interwencje ekonomiczne
  performEconomicIntervention(healthReport: EconomicHealthReport): void {
    if (healthReport.inflation > 0.15) { // 15% inflation
      // Reduce money sources
      this.adjustParameter('QUEST_REWARDS', 0.85);
      this.adjustParameter('ARTIFACT_VALUES', 0.9);
      this.adjustParameter('TRADING_PROFIT_MARGINS', 0.8);
    }
    
    if (healthReport.liquidity < 0.3) { // Low liquidity
      // Increase money circulation
      this.adjustParameter('NPC_TRADING_FREQUENCY', 1.2);
      this.adjustParameter('FACTION_MISSIONS_REWARDS', 1.15);
      this.spawnRandomEventsWithRewards();
    }
    
    if (healthReport.activity < 0.25) { // Low trading activity
      // Incentivize trading
      this.introduceTemporaryEvents(['TRADER_DISCOUNT', 'RARE_GOODS_AVAILABLE']);
      this.increaseNPCDemandForRareItems();
    }
  }
}
```

## Podsumowanie Mechanik

Mechaniki rozgrywki w "Cieniu Podróżnika" tworzą spójny i złożony system, gdzie:

1. **System Naznaczenia** napędza główną progresję z wieloma ścieżkami rozwoju
2. **Anomalie** dostarczają unikalnych wyzwań z jasną mechaniką risk/reward
3. **Artefakty** oferują power progression z ciekawymi trade-offami
4. **NPC Interactions** są głębokie i mają długofalowe konsekwencje
5. **Ekonomia** jest dynamiczna i odpowiada na działania graczy
6. **Weatherware** wpływa na wszystkie systemy w significantny sposób
7. **Balancing** jest automatic i responds to player behavior

Wszystkie systemy są zaprojektowane tak, aby:
- Reagować na siebie nawzajem (emergent gameplay)
- Dawać graczom meaningful choices
- Zapewniać long-term progression
- Utrzymywać engagement bez frustracji
- Być skalowalne dla różnych stylów gry

---

> **Implementation Note**: Każda mechanika powinna być implementowana z gathering detailed player metrics, aby móc odpowiednio balansować system w trakcie playtesting i post-launch.