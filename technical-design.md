# Cień Podróżnika - Projekt Techniczny

Ten dokument zawiera szczegółowe informacje techniczne dotyczące implementacji kluczowych systemów gry "Cień Podróżnika", skupiając się szczególnie na architekturze AI, optymalizacji wydajności oraz zaawansowanych mechanizmach rozgrywki.

> **Referencje**: Ten dokument jest ściśle powiązany z [functions-index.md](functions-index.md) (architektura systemów), [glossary.md](glossary.md) (definicje terminów) i [api-specifications.md](api-specifications.md) (interfejsy API).

## 1. Architektura Systemu "Dwóch Mózgów"

> **MUST-HAVE**: Ten system jest fundamentalny dla całej gry (Priorytet 1 w [functions-index.md](functions-index.md))

### 1.1 Podstawy Koncepcyjne

System "dwóch mózgów" to dwuwarstwowa architektura AI zaprojektowana do efektywnego zarządzania zachowaniami NPC w świecie gry "Cień Podróżnika". Zapewnia realistyczne i złożone zachowania NPC (patrz: [glossary.md](glossary.md)#npc), jednocześnie optymalizując wykorzystanie zasobów systemu.

#### 1.1.1 Podział Warstw

1. **Mózg Strategiczny (Warstwa 2D)** (patrz: [glossary.md](glossary.md)#mózg-strategiczny)
   - Symulacja globalna, niska częstotliwość aktualizacji (co 5 sekund)
   - Długoterminowe planowanie i podejmowanie decyzji
   - Zarządzanie celami wysokiego poziomu i priorytetami
   - Globalne mapowanie świata i relacje między [frakcjami](glossary.md#frakcja)

2. **Mózg Taktyczny (Warstwa 3D)** (patrz: [glossary.md](glossary.md)#mózg-taktyczny)
   - Symulacja lokalna, wysoka częstotliwość aktualizacji (co klatkę)
   - Implementacja decyzji strategicznych w świecie 3D
   - Reakcje na bezpośrednie zagrożenia i możliwości
   - Nawigacja lokalna i interakcje z otoczeniem

#### 1.1.2 Szczegółowy Przepływ Informacji

```
[Strategic Brain: 2D Planning]
    ├── Goals: Long-term objectives, faction alignment, resource acquisition
    ├── Knowledge: World state, relationships, history
    ├── Decision Engine: Utility-based decision making
    └── Communication Buffer: Commands for tactical brain
                    ↓
[Synchronization Layer]
    ├── Command Queue: Priority-ordered tactical commands
    ├── State Sync: Current world state, NPC status updates
    ├── Conflict Resolution: Handling impossible commands
    └── Performance Throttling: Dynamic frequency adjustment
                    ↓
[Tactical Brain: 3D Execution]
    ├── Perception: Real-time environment scanning
    ├── Pathfinding: 3D navigation and obstacle avoidance
    ├── Action Execution: Movement, combat, interactions
    └── Feedback Loop: Reporting execution results
```

> **Связek с innymi systemами**: Zobacz [functions-index.md](functions-index.md)#przepływy-kluczowych-danych i [api-specifications.md](api-specifications.md)#interface-strategic-brain-tactical-brain

### 1.2 Modułowa Architektura Mózgów

Każdy z mózgów jest podzielony na współpracujące moduły, zapewniając elastyczność i łatwiejszą rozbudowę systemu.

#### 1.2.1 Szczegółowa Struktura Mózgu Strategicznego

```typescript
class StrategicBrain {
  // Core modules
  private memoryModule: MemoryModule;
  private planningModule: PlanningModule;
  private goalModule: GoalModule;
  private relationshipModule: RelationshipModule;
  private economicModule: EconomicAnalysisModule;
  
  // Decision making
  private utilitySystem: UtilitySystem;
  private riskAssessment: RiskAssessmentModule;
  private opportunityDetection: OpportunityDetectionModule;
  
  // Communication
  private commandQueue: CommandQueue;
  private stateBuffer: StateBuffer;
  
  // Main processing loop
  async processStrategicDecisions(worldState: WorldState): Promise<StrategicCommand[]> {
    // 1. Update internal state
    await this.updateInternalState(worldState);
    
    // 2. Analyze current situation
    const situation = await this.analyzeSituation(worldState);
    
    // 3. Evaluate goals
    const activeGoals = this.goalModule.evaluateGoals(situation);
    
    // 4. Generate options
    const options = await this.generateActionOptions(activeGoals, situation);
    
    // 5. Utility-based selection
    const selectedActions = this.utilitySystem.selectActions(options);
    
    // 6. Risk assessment
    const validatedActions = this.riskAssessment.validateActions(selectedActions);
    
    // 7. Create commands
    return this.createTacticalCommands(validatedActions);
  }
}
```

#### 1.2.2 Детальная Структура Mózgu Taktycznego

```typescript
class TacticalBrain {
  // Perception systems
  private visualPerception: VisualPerceptionModule;
  private auditoryPerception: AuditoryPerceptionModule;
  private zonePerception: ZonePerceptionModule; // Zone-specific senses
  
  // Navigation systems
  private pathfinding: PathfindingModule;
  private obstacleAvoidance: ObstacleAvoidanceModule;
  private navigationMesh: NavigationMeshModule;
  
  // Action execution
  private movementController: MovementController;
  private combatController: CombatController;
  private interactionController: InteractionController;
  
  // State management
  private tacticalState: TacticalState;
  private executionContext: ExecutionContext;
  
  // Main processing loop (runs every frame)
  update(deltaTime: number): void {
    // 1. Process perception
    const perceptionData = this.gatherPerceptionData();
    
    // 2. Update tactical state
    this.updateTacticalState(perceptionData);
    
    // 3. Process strategic commands
    this.processStrategicCommands();
    
    // 4. Execute immediate reactions
    this.processImmediateThreats(perceptionData);
    
    // 5. Update movement
    this.movementController.update(deltaTime);
    
    // 6. Handle interactions
    this.interactionController.update(deltaTime);
    
    // 7. Send feedback to strategic brain
    this.sendFeedbackToStrategic();
  }
}
```

#### 1.2.3 Zaawansowane Moduły AI

**1. Memory Module - Pamięć Strategiczna**
```typescript
class MemoryModule {
  // Tiered memory system
  private shortTermMemory: Map<string, MemoryEntry>; // Last 5 minutes
  private mediumTermMemory: Map<string, MemoryEntry>; // Last hour
  private longTermMemory: Map<string, MemoryEntry>; // Important events
  
  // Associative memory
  private associationsGraph: AssociativeGraph;
  
  // Memory consolidation
  async consolidateMemories(): Promise<void> {
    // Move important short-term memories to medium-term
    const candidatesForConsolidation = this.shortTermMemory.values()
      .filter(memory => memory.importance > CONSOLIDATION_THRESHOLD);
    
    for (const memory of candidatesForConsolidation) {
      const associations = await this.findAssociations(memory);
      const consolidatedMemory = this.createConsolidatedMemory(memory, associations);
      this.mediumTermMemory.set(consolidatedMemory.id, consolidatedMemory);
    }
    
    // Promote exceptional memories to long-term
    await this.promoteMagazineTierMemories();
  }
}
```

**2. Utility System - Система принятия решений**
```typescript
class UtilitySystem {
  // Utility curves for different considerations
  private utilityCurves: Map<ConsiderationType, UtilityCurve>;
  
  // Dynamic weights based on context
  private contextWeights: Map<ContextType, WeightMap>;
  
  evaluateAction(action: PotentialAction, context: DecisionContext): number {
    let totalUtility = 0;
    
    // Evaluate each consideration
    for (const [considerationType, curve] of this.utilityCurves.entries()) {
      const considerationValue = this.getConsiderationValue(
        considerationType, 
        action, 
        context
      );
      
      const utility = curve.evaluate(considerationValue);
      const weight = this.getWeight(considerationType, context);
      
      totalUtility += utility * weight;
    }
    
    // Apply context-specific modifiers
    const contextModifier = this.getContextModifier(action, context);
    
    return totalUtility * contextModifier;
  }
  
  // Dynamic utility curve adaptation
  adaptUtilityCurves(experiences: Experience[]): void {
    for (const experience of experiences) {
      const curve = this.utilityCurves.get(experience.considerationType);
      if (curve) {
        // Adjust curve based on experience outcome
        curve.adapt(experience.outcome, experience.expectedOutcome);
      }
    }
  }
}
```

**3. Zone Perception Module**
```typescript
class ZonePerceptionModule {
  // Zone-specific senses
  detectAnomalies(range: number): AnomalyDetection[] {
    const detections: AnomalyDetection[] = [];
    
    for (const anomaly of this.getNearbyAnomalies(range)) {
      const detection = {
        type: anomaly.type,
        position: anomaly.position,
        intensity: this.calculateDetectionIntensity(anomaly),
        confidence: this.calculateDetectionConfidence(anomaly),
        threat level: this.assessThreatLevel(anomaly),
        bypassability: this.assessBypassOptions(anomaly)
      };
      
      detections.push(detection);
    }
    
    return detections;
  }
  
  detectArtifacts(range: number): ArtifactDetection[] {
    // Implementation would depend on NPC's equipment and experience
    const baseRange = this.getBaseDetectionRange();
    const equipmentModifier = this.getEquipmentModifier();
    const experienceModifier = this.getExperienceModifier();
    
    const effectiveRange = Math.min(
      range, 
      baseRange * equipmentModifier * experienceModifier
    );
    
    return this.scanForArtifacts(effectiveRange);
  }
  
  assessZoneMarking(position: Vector3): ZoneMarkingAssessment {
    // Check for zone marking effects at position
    const nearbyMarking = this.findNearbyMarking(position);
    
    if (!nearbyMarking) return null;
    
    return {
      type: nearbyMarking.type,
      intensity: nearbyMarking.intensity,
      effects: this.calculateExpectedEffects(nearbyMarking),
      adaptation: this.assessAdaptationLevel(nearbyMarking),
      recommendations: this.generateRecommendations(nearbyMarking)
    };
  }
}
```

## 2. System Hierarchicznego LOD dla AI

### 2.1 Poziomy Szczegółowości - Rozszerzone

Hierarchiczny system LOD (Level of Detail) dla AI umożliwia skalowanie złożoności symulacji w zależności od odległości i znaczenia NPC. Pozwala to na symulowanie dużej liczby postaci przy zachowaniu wydajności.

#### 2.1.1 Detalizacja Poziomów LOD

**Poziom 0 - Full Detail (0-50m)**
```typescript
class FullDetailLOD implements AILODLevel {
  // Complete AI processing
  async update(npc: NPC, context: UpdateContext): Promise<void> {
    // Full strategic brain processing
    await this.updateStrategicBrain(npc, context);
    
    // Full tactical brain processing (every frame)
    this.updateTacticalBrain(npc, context);
    
    // Detailed perception
    const perceptionResult = this.fullPerceptionScan(npc);
    
    // Complex pathfinding
    if (npc.needsPathUpdate()) {
      await this.calculateDetailedPath(npc);
    }
    
    // Advanced combat AI
    this.updateAdvancedCombatBehavior(npc);
    
    // Detailed animations
    this.updateComplexAnimations(npc);
    
    // Particle effects and sounds
    this.updateAudioVisualEffects(npc);
  }
}
```

**Poziom 1 - Medium Detail (50-200m)**
```typescript
class MediumDetailLOD implements AILODLevel {
  async update(npc: NPC, context: UpdateContext): Promise<void> {
    // Strategic brain every 3rd frame
    if (context.frameCount % 3 === 0) {
      await this.updateStrategicBrain(npc, context);
    }
    
    // Simplified tactical brain
    this.updateSimplifiedTacticalBrain(npc, context);
    
    // Reduced perception range and frequency
    if (context.frameCount % 2 === 0) {
      const perception = this.simplifiedPerceptionScan(npc, 0.7);
      npc.updatePerceptionData(perception);
    }
    
    // Cached pathfinding with longer intervals
    if (npc.shouldUpdatePath(MEDIUM_PATH_UPDATE_INTERVAL)) {
      const path = await this.getCachedOrCalculatePath(npc);
      npc.updatePath(path);
    }
    
    // Basic combat behavior
    this.updateBasicCombatBehavior(npc);
    
    // Simplified animations
    this.updateSimpleAnimations(npc);
  }
}
```

**Poziom 2 - Low Detail (200-500m)**
```typescript
class LowDetailLOD implements AILODLevel {
  async update(npc: NPC, context: UpdateContext): Promise<void> {
    // Strategic brain every 10th frame
    if (context.frameCount % 10 === 0) {
      await this.updateStrategicBrainLimited(npc, context);
    }
    
    // Very basic tactical processing
    if (context.frameCount % 5 === 0) {
      this.updateMinimalTacticalBrain(npc, context);
    }
    
    // Minimal perception - only major threats
    if (context.frameCount % 5 === 0) {
      const threats = this.scanForMajorThreats(npc);
      npc.updateThreatData(threats);
    }
    
    // Pre-computed paths only
    if (npc.shouldUpdatePath(LOW_PATH_UPDATE_INTERVAL)) {
      const path = this.getPrecomputedPath(npc);
      npc.updatePath(path);
    }
    
    // No individual combat AI - group behavior only
    this.updateGroupBehavior(npc);
    
    // Static animations only
    this.maintainIdleAnimation(npc);
  }
}
```

**Poziom 3 - Strategic Only (500m+)**
```typescript
class StrategicOnlyLOD implements AILODLevel {
  async update(npc: NPC, context: UpdateContext): Promise<void> {
    // Strategic brain every 30th frame
    if (context.frameCount % 30 === 0) {
      await this.updateStrategicBrainOnly(npc, context);
    }
    
    // No tactical brain processing
    
    // No perception - world state updates only
    if (context.frameCount % 20 === 0) {
      this.updateWorldStateKnowledge(npc);
    }
    
    // 2D movement only on grid
    this.update2DMovement(npc);
    
    // No combat - faction-level conflicts only
    this.updateFactionConflictStatus(npc);
    
    // No rendering or animation
    npc.setRenderingEnabled(false);
  }
}
```

#### 2.1.2 Dynamiczny LOD Management

```typescript
class DynamicLODManager {
  private lodLevels: Map<LODLevel, AILODLevel>;
  private npcLodAssignments: Map<string, LODLevel>;
  private performanceMonitor: PerformanceMonitor;
  
  // Dynamic LOD adjustment based on performance
  adjustLODLevels(): void {
    const performance = this.performanceMonitor.getCurrentMetrics();
    
    if (performance.frameTime > TARGET_FRAME_TIME * 1.2) {
      // Performance too low - reduce LOD
      this.reduceLODForLessImportantNPCs();
    } else if (performance.frameTime < TARGET_FRAME_TIME * 0.8) {
      // Performance good - increase LOD where beneficial
      this.increaseLODForImportantNPCs();
    }
  }
  
  // Importance-based LOD assignment
  calculateNPCImportance(npc: NPC): number {
    let importance = 0;
    
    // Distance factor (most important)
    const distanceToPlayer = npc.position.distanceTo(player.position);
    importance += this.calculateDistanceScore(distanceToPlayer);
    
    // Player relationship
    importance += npc.getRelationshipWithPlayer() * 0.3;
    
    // Story relevance
    if (npc.isStoryRelevant()) importance += 0.5;
    
    // Current activity importance
    importance += this.getActivityImportance(npc.currentActivity) * 0.2;
    
    // Faction importance
    if (npc.faction && npc.faction.isPlayerRelevant()) importance += 0.3;
    
    return Math.min(1.0, importance);
  }
  
  // Smart transition between LOD levels
  transitionLOD(npc: NPC, fromLOD: LODLevel, toLOD: LODLevel): void {
    // Gradual transition to avoid pop-in
    const transition = new LODTransition(fromLOD, toLOD, TRANSITION_DURATION);
    
    // Preserve important state during transition
    const statesToPreserve = this.identifyImportantStates(npc);
    
    // Execute transition with interpolation
    this.executeLODTransition(npc, transition, statesToPreserve);
    
    // Log transition for performance analysis
    this.performanceMonitor.logLODTransition(npc.id, fromLOD, toLOD);
  }
}
```

## 3. System Śledzenia Historii NPC

### 3.1 Rozszerzona Struktura Danych Historii

```typescript
class NPCHistorySystem {
  private histories: Map<string, NPCHistory>;
  private eventCompressor: EventCompressor;
  private narrativeGenerator: NarrativeGenerator;
  
  // Create comprehensive history entry
  recordEvent(npcId: string, event: HistoryEvent): void {
    const history = this.getHistory(npcId);
    
    // Assign importance and categorize
    const categorizedEvent = this.categorizeEvent(event);
    const importance = this.calculateImportance(categorizedEvent);
    
    // Create comprehensive history entry
    const historyEntry: HistoryEntry = {
      id: generateId(),
      event: categorizedEvent,
      timestamp: Date.now(),
      importance: importance,
      context: this.captureContext(npcId, event),
      participants: this.identifyParticipants(event),
      consequences: [], // Will be filled as consequences unfold
      narrativeWeight: this.calculateNarrativeWeight(categorizedEvent),
      emotionalImpact: this.assessEmotionalImpact(npcId, categorizedEvent)
    };
    
    history.addEntry(historyEntry);
    
    // Update NPC's personality based on experience
    this.updatePersonalityFromExperience(npcId, historyEntry);
    
    // Check for story pattern recognition
    this.checkForNarrativePatterns(npcId, historyEntry);
  }
}
```

#### 3.1.1 Zaawansowane Kategorie Znaczenia

```typescript
// Extended importance categorization
enum EventSignificance {
  // Routine events (importance: 0-0.2)
  DAILY_ROUTINE = "DAILY_ROUTINE",
  MINOR_INTERACTION = "MINOR_INTERACTION",
  COMMODITY_TRANSACTION = "COMMODITY_TRANSACTION",
  
  // Notable events (importance: 0.2-0.5)
  SIGNIFICANT_FIND = "SIGNIFICANT_FIND",
  MINOR_COMBAT = "MINOR_COMBAT",
  FACTION_INTERACTION = "FACTION_INTERACTION",
  
  // Major events (importance: 0.5-0.8)
  RARE_ARTIFACT_DISCOVERY = "RARE_ARTIFACT_DISCOVERY",
  MAJOR_COMBAT_VICTORY = "MAJOR_COMBAT_VICTORY",
  FACTION_BETRAYAL = "FACTION_BETRAYAL",
  ZONE_MARKING_EXPOSURE = "ZONE_MARKING_EXPOSURE",
  
  // Life-changing events (importance: 0.8-1.0)
  FIRST_KILL = "FIRST_KILL",
  FACTION_LEADERSHIP = "FACTION_LEADERSHIP",
  UNIQUE_ARTIFACT = "UNIQUE_ARTIFACT",
  ZONE_TRANSFORMATION = "ZONE_TRANSFORMATION"
}

// Contextual significance modifiers
class SignificanceModifier {
  static apply(baseImportance: number, context: EventContext): number {
    let modifier = 1.0;
    
    // First time modifiers
    if (context.isFirstTime) modifier *= 1.5;
    
    // Risk level modifiers
    modifier *= 1 + (context.riskLevel * 0.3);
    
    // Personal relevance
    modifier *= 1 + (context.personalRelevance * 0.4);
    
    // Rarity modifier
    modifier *= 1 + (context.rarity * 0.6);
    
    // Consequence magnitude
    modifier *= 1 + (context.consequenceMagnitude * 0.5);
    
    return Math.min(1.0, baseImportance * modifier);
  }
}
```

### 3.2 Zaawansowany System Generowania Narracji

```typescript
class NarrativeGenerator {
  private templates: Map<EventPattern, NarrativeTemplate[]>;
  private characterVoices: Map<PersonalityType, NarrativeVoice>;
  
  generateLifeStory(npcId: string, timeframe?: TimeRange): LifeStory {
    const history = this.historySystem.getHistory(npcId);
    const personality = this.getPersonality(npcId);
    
    // Select narrative voice based on personality
    const voice = this.characterVoices.get(personality.type);
    
    // Extract major story arcs
    const storyArcs = this.extractStoryArcs(history, timeframe);
    
    // Generate cohesive narrative
    const narrative = this.composeNarrative(storyArcs, voice);
    
    // Add reflective elements
    const reflections = this.generateReflections(npcId, storyArcs);
    
    return new LifeStory(narrative, reflections, storyArcs);
  }
  
  private extractStoryArcs(history: NPCHistory, timeframe?: TimeRange): StoryArc[] {
    const events = history.getEvents(timeframe);
    const arcs: StoryArc[] = [];
    
    // Identify arc patterns
    const patterns = [
      new RiseAndFallPattern(),
      new QuestPattern(),
      new RelationshipPattern(),
      new TransformationPattern(),
      new ConflictPattern()
    ];
    
    for (const pattern of patterns) {
      const matchingArcs = pattern.findArcsIn(events);
      arcs.push(...matchingArcs);
    }
    
    // Resolve overlapping arcs
    return this.resolveArcOverlaps(arcs);
  }
  
  private composeNarrative(arcs: StoryArc[], voice: NarrativeVoice): string {
    let narrative = voice.createOpening();
    
    // Sort arcs chronologically
    arcs.sort((a, b) => a.startTime - b.startTime);
    
    for (const arc of arcs) {
      // Create smooth transitions between arcs
      const transition = voice.createTransition(arc);
      narrative += transition;
      
      // Compose arc narrative
      const arcNarrative = this.composeArcNarrative(arc, voice);
      narrative += arcNarrative;
    }
    
    // Create conclusion
    narrative += voice.createConclusion(arcs);
    
    return narrative;
  }
}

// Narrative patterns for story arc recognition
class QuestPattern implements StoryArcPattern {
  findArcsIn(events: HistoryEvent[]): StoryArc[] {
    const arcs: StoryArc[] = [];
    
    for (let i = 0; i < events.length; i++) {
      const startEvent = events[i];
      
      // Look for quest initiation events
      if (this.isQuestStart(startEvent)) {
        const arc = this.attemptToResolveQuest(events, i);
        if (arc) arcs.push(arc);
      }
    }
    
    return arcs;
  }
  
  private isQuestStart(event: HistoryEvent): boolean {
    return event.type === EventType.RARE_ARTIFACT_SPOTTED ||
           event.type === EventType.FACTION_MISSION_ACCEPTED ||
           event.type === EventType.MYSTERY_DISCOVERED;
  }
  
  private attemptToResolveQuest(events: HistoryEvent[], startIndex: number): StoryArc | null {
    const questStart = events[startIndex];
    const questGoal = this.extractQuestGoal(questStart);
    
    // Search for resolution within reasonable time
    for (let i = startIndex + 1; i < events.length; i++) {
      const event = events[i];
      
      if (this.isQuestResolution(event, questGoal)) {
        return new QuestArc(
          events.slice(startIndex, i + 1),
          questGoal,
          this.assessQuestOutcome(event)
        );
      }
      
      // Quest abandoned or failed?
      if (this.isQuestFailure(event, questGoal)) {
        return new QuestArc(
          events.slice(startIndex, i + 1),
          questGoal,
          QuestOutcome.FAILED
        );
      }
    }
    
    // Ongoing quest
    return new QuestArc(
      events.slice(startIndex),
      questGoal,
      QuestOutcome.ONGOING
    );
  }
}
```

## 4. Architektura Wielowątkowa

### 4.1 Szczegółowe Rozdzielenie Obliczeń

Implementacja wielowątkowa umożliwia efektywne wykorzystanie wielu rdzeni procesora i uniknięcie spadków wydajności podczas intensywnych obliczeń AI.

#### 4.1.1 Thread Pool Architecture

```typescript
// Main thread coordinating system
class GameThreadCoordinator {
  private threads: Map<ThreadType, GameThread>;
  private threadPool: ThreadPool;
  private taskScheduler: TaskScheduler;
  
  initialize(): void {
    // Initialize thread pool with hardware-appropriate size
    const threadCount = Math.max(2, navigator.hardwareConcurrency - 1);
    this.threadPool = new ThreadPool(threadCount);
    
    // Create specialized threads
    this.threads.set(ThreadType.STRATEGIC_AI, new StrategicAIThread());
    this.threads.set(ThreadType.PATHFINDING, new PathfindingThread());
    this.threads.set(ThreadType.WORLD_SIMULATION, new WorldSimulationThread());
    this.threads.set(ThreadType.SERIALIZATION, new SerializationThread());
    
    // Set up inter-thread communication
    this.setupThreadCommunication();
  }
  
  private setupThreadCommunication(): void {
    // Shared memory for read-only data
    this.setupSharedMemory();
    
    // Message passing for commands
    this.setupMessagePassing();
    
    // Synchronization primitives
    this.setupSynchronization();
  }
}
```

#### 4.1.2 Strategic AI Thread

```typescript
class StrategicAIThread extends GameThread {
  private strategicBrains: Map<string, StrategicBrain>;
  private tickRate: number = 5; // 5 Hz
  private batchProcessor: BatchProcessor;
  
  async runThread(): Promise<void> {
    while (this.isRunning) {
      const startTime = performance.now();
      
      // Process NPCs in batches
      const npcBatches = this.batchProcessor.createBatches(
        this.strategicBrains.keys(),
        BATCH_SIZE
      );
      
      // Process batches in parallel
      const tasks = npcBatches.map(batch => 
        this.processBatch(batch)
      );
      
      await Promise.all(tasks);
      
      // Send results to main thread
      this.sendResultsToMainThread();
      
      // Calculate sleep time to maintain target rate
      const elapsed = performance.now() - startTime;
      const sleepTime = Math.max(0, (1000 / this.tickRate) - elapsed);
      
      await this.sleep(sleepTime);
    }
  }
  
  private async processBatch(npcIds: string[]): Promise<BatchResult> {
    const results: NPCDecisionResult[] = [];
    
    for (const npcId of npcIds) {
      const brain = this.strategicBrains.get(npcId);
      if (!brain) continue;
      
      try {
        // Get latest world state for this NPC
        const worldState = await this.getWorldState(npcId);
        
        // Process strategic decisions
        const decisions = await brain.processStrategicDecisions(worldState);
        
        // Validate decisions
        const validatedDecisions = this.validateDecisions(decisions);
        
        results.push({
          npcId,
          decisions: validatedDecisions,
          status: 'success'
        });
      } catch (error) {
        results.push({
          npcId,
          error: error.message,
          status: 'error'
        });
      }
    }
    
    return new BatchResult(results);
  }
}
```

#### 4.1.3 Pathfinding Thread

```typescript
class PathfindingThread extends GameThread {
  private pathfinder: AStarPathfinder;
  private navigationMesh: NavigationMesh;
  private requestQueue: PriorityQueue<PathfindingRequest>;
  private cache: PathCache;
  
  async runThread(): Promise<void> {
    while (this.isRunning) {
      if (this.requestQueue.isEmpty()) {
        await this.waitForRequests();
        continue;
      }
      
      // Process highest priority request
      const request = this.requestQueue.dequeue();
      
      try {
        const path = await this.calculatePath(request);
        this.sendPathResult(request.id, path);
      } catch (error) {
        this.sendPathError(request.id, error);
      }
    }
  }
  
  private async calculatePath(request: PathfindingRequest): Promise<Path> {
    // Check cache first
    const cachedPath = this.cache.get(request.cacheKey);
    if (cachedPath && cachedPath.isValid()) {
      return cachedPath;
    }
    
    // Hierarchical pathfinding for long distances
    if (request.distance > HIERARCHICAL_THRESHOLD) {
      return this.hierarchicalPathfinding(request);
    }
    
    // Standard A* for short distances
    const path = await this.pathfinder.findPath(
      request.start,
      request.end,
      request.constraints
    );
    
    // Post-process path
    const smoothedPath = this.smoothPath(path);
    const optimizedPath = this.optimizePath(smoothedPath);
    
    // Cache result
    this.cache.set(request.cacheKey, optimizedPath);
    
    return optimizedPath;
  }
  
  private async hierarchicalPathfinding(request: PathfindingRequest): Promise<Path> {
    // Find path through high-level graph
    const abstractPath = await this.findAbstractPath(request);
    
    // Refine each segment
    const detailedSegments: PathSegment[] = [];
    
    for (const segment of abstractPath.segments) {
      const detailedSegment = await this.refineSegment(segment, request.constraints);
      detailedSegments.push(detailedSegment);
    }
    
    // Combine segments into full path
    return this.combineSegments(detailedSegments);
  }
}
```

## 5. Zaawansowane Wzorce Projektowe i Implementacje

### 5.1 State Pattern dla Zachowań AI

```typescript
// State pattern for NPC behaviors
abstract class NPCState {
  abstract enter(npc: NPC, context: StateContext): void;
  abstract update(npc: NPC, deltaTime: number): NPCState | null;
  abstract exit(npc: NPC, context: StateContext): void;
  abstract canTransitionTo(newState: NPCState): boolean;
}

class IdleState extends NPCState {
  private currentActivity: IdleActivity;
  private boredomLevel: number = 0;
  
  enter(npc: NPC, context: StateContext): void {
    this.currentActivity = this.selectIdleActivity(npc);
    npc.startActivity(this.currentActivity);
  }
  
  update(npc: NPC, deltaTime: number): NPCState | null {
    this.boredomLevel += deltaTime * npc.personalityTraits.restlessness;
    
    // Check for interruptions
    const threat = npc.perception.getNearestThreat();
    if (threat) {
      return npc.stateMachine.getState(StateType.THREAT_RESPONSE);
    }
    
    // Check for opportunities
    const opportunity = npc.perception.getBestOpportunity();
    if (opportunity && opportunity.utility > OPPORTUNITY_THRESHOLD) {
      return npc.stateMachine.getState(StateType.OPPORTUNITY_PURSUIT);
    }
    
    // Boredom-driven state changes
    if (this.boredomLevel > BOREDOM_THRESHOLD) {
      return this.selectBoredomResolution(npc);
    }
    
    // Update current activity
    this.currentActivity.update(deltaTime);
    
    return null; // Stay in current state
  }
  
  private selectIdleActivity(npc: NPC): IdleActivity {
    const activities = [
      new MaintenanceActivity(npc),
      new SocialActivity(npc),
      new WatchingActivity(npc),
      new PersonalTaskActivity(npc)
    ];
    
    // Weight activities by personality and context
    const weights = activities.map(activity => 
      activity.calculateUtility(npc)
    );
    
    return this.weightedRandomSelection(activities, weights);
  }
}

class CombatState extends NPCState {
  private combatStyle: CombatStyle;
  private currentTarget: NPC | null;
  private retreatThreshold: number;
  
  enter(npc: NPC, context: StateContext): void {
    this.combatStyle = this.determineCombatStyle(npc);
    this.currentTarget = context.target as NPC;
    this.retreatThreshold = this.calculateRetreatThreshold(npc);
    
    npc.weaponSystem.selectBestWeapon(this.currentTarget);
    this.combatStyle.initiate(npc);
  }
  
  update(npc: NPC, deltaTime: number): NPCState | null {
    // Check for combat end conditions
    if (!this.currentTarget || this.currentTarget.isDead()) {
      return npc.stateMachine.getState(StateType.COMBAT_VICTORY);
    }
    
    // Assess situation
    const combatAssessment = this.assessCombatSituation(npc);
    
    // Retreat if necessary
    if (combatAssessment.shouldRetreat()) {
      return npc.stateMachine.getState(StateType.RETREAT);
    }
    
    // Update combat style based on changing conditions
    this.combatStyle.update(npc, combatAssessment);
    
    // Execute combat actions
    this.executeCombatActions(npc, deltaTime);
    
    return null;
  }
  
  private assessCombatSituation(npc: NPC): CombatAssessment {
    return {
      ownHealth: npc.health.percentage,
      enemyHealth: this.currentTarget.health.percentage,
      availableAmmo: npc.inventory.getAmmoCount(),
      surroundings: npc.perception.analyzeCombatEnvironment(),
      alliesNearby: npc.perception.getNearbyAllies().length,
      enemiesNearby: npc.perception.getNearbyEnemies().length,
      shouldRetreat: () => this.evaluateRetreatNecessity(npc)
    };
  }
}
```

### 5.2 Command Pattern for AI Actions

```typescript
// Action system with undo/redo support
interface AIAction {
  readonly id: string;
  readonly type: ActionType;
  readonly timestamp: number;
  
  execute(npc: NPC): Promise<ActionResult>;
  canExecute(npc: NPC): boolean;
  getEstimatedDuration(): number;
  getCost(): ResourceCost;
  
  // For learning and adaptation
  getContext(): ActionContext;
  recordOutcome(outcome: ActionOutcome): void;
}

class MovementAction implements AIAction {
  constructor(
    public readonly id: string,
    public readonly targetPosition: Vector3,
    public readonly movementType: MovementType = MovementType.WALK,
    public readonly urgency: number = 0.5
  ) {}
  
  async execute(npc: NPC): Promise<ActionResult> {
    const pathfindingRequest = new PathfindingRequest(
      npc.position,
      this.targetPosition,
      this.getPathConstraints(npc)
    );
    
    // Request path from pathfinding thread
    const path = await npc.pathfindingService.requestPath(pathfindingRequest);
    
    if (!path.isValid()) {
      return ActionResult.failure("NO_VALID_PATH", path.errors);
    }
    
    // Execute movement
    const movementResult = await npc.movementController.followPath(path, {
      type: this.movementType,
      urgency: this.urgency
    });
    
    // Record result for learning
    this.recordOutcome(movementResult);
    
    return ActionResult.fromMovementResult(movementResult);
  }
  
  canExecute(npc: NPC): boolean {
    // Check if NPC is capable of movement
    if (npc.state.isIncapacitated()) return false;
    
    // Check for movement inhibiting anomalies
    const nearbyAnomalies = npc.perception.getNearbyAnomalies(5);
    const inhibitingAnomalies = nearbyAnomalies.filter(a => a.inhibitsMovement());
    if (inhibitingAnomalies.length > 0) return false;
    
    // Check for sufficient resources
    const energyCost = this.calculateEnergyCost(npc);
    if (npc.stats.stamina < energyCost) return false;
    
    return true;
  }
  
  private getPathConstraints(npc: NPC): PathConstraints {
    return {
      allowedAreas: npc.getAllowedAreas(),
      avoidanceLevel: npc.getRiskTolerance(),
      maxDanger: npc.getMaxAcceptableDanger(),
      preferredSurfaces: npc.getPreferredSurfaces(),
      zoneSpecificConstraints: npc.getZoneConstraints()
    };
  }
}

class InteractionAction implements AIAction {
  constructor(
    public readonly id: string,
    public readonly target: InteractableObject,
    public readonly interactionType: InteractionType
  ) {}
  
  async execute(npc: NPC): Promise<ActionResult> {
    // Check if still in range
    if (npc.position.distanceTo(this.target.position) > INTERACTION_RANGE) {
      return ActionResult.failure("OUT_OF_RANGE");
    }
    
    // Check for contextual requirements
    const contextCheck = this.checkContextualRequirements(npc);
    if (!contextCheck.valid) {
      return ActionResult.failure("CONTEXT_FAILURE", contextCheck.reasons);
    }
    
    // Execute interaction
    const result = await this.executeInteraction(npc);
    
    // Update NPC knowledge and relationships
    this.processInteractionConsequences(npc, result);
    
    return result;
  }
  
  private async executeInteraction(npc: NPC): Promise<ActionResult> {
    switch (this.interactionType) {
      case InteractionType.EXAMINE:
        return this.examineObject(npc);
      
      case InteractionType.TAKE:
        return this.takeObject(npc);
      
      case InteractionType.USE:
        return this.useObject(npc);
      
      case InteractionType.TRADE:
        return this.initiateTrading(npc);
      
      case InteractionType.TALK:
        return this.startConversation(npc);
      
      default:
        return ActionResult.failure("UNKNOWN_INTERACTION_TYPE");
    }
  }
}
```

### 5.3 Observer Pattern for Event System

```typescript
// Event system for decoupled communication
class EventSystem {
  private observers: Map<EventType, Set<Observer>>;
  private eventQueue: EventQueue;
  private eventHistory: EventHistory;
  
  subscribe<T>(eventType: EventType, observer: Observer<T>): Subscription {
    if (!this.observers.has(eventType)) {
      this.observers.set(eventType, new Set());
    }
    
    this.observers.get(eventType)!.add(observer);
    
    return new Subscription(eventType, observer, () => {
      this.unsubscribe(eventType, observer);
    });
  }
  
  emit<T>(event: GameEvent<T>): void {
    // Add to queue for ordered processing
    this.eventQueue.enqueue(event);
    
    // Record in history
    this.eventHistory.record(event);
    
    // Process immediately for critical events
    if (event.priority === Priority.CRITICAL) {
      this.processEvent(event);
    }
  }
  
  private processEvent<T>(event: GameEvent<T>): void {
    const observers = this.observers.get(event.type);
    if (!observers) return;
    
    // Create execution context
    const context = new EventContext(event);
    
    // Notify observers
    for (const observer of observers) {
      try {
        observer.notify(event, context);
      } catch (error) {
        console.error(`Observer error for event ${event.type}:`, error);
      }
    }
  }
  
  // Batch process queued events
  processQueuedEvents(): void {
    while (!this.eventQueue.isEmpty()) {
      const event = this.eventQueue.dequeue();
      this.processEvent(event);
    }
  }
}

// Zone-specific events
class ZoneEventObserver implements Observer<ZoneEvent> {
  constructor(private npcManager: NPCManager) {}
  
  notify(event: GameEvent<ZoneEvent>, context: EventContext): void {
    switch (event.data.type) {
      case ZoneEventType.BLOWOUT:
        this.handleBlowout(event.data);
        break;
      
      case ZoneEventType.ANOMALY_APPEARED:
        this.handleAnomalyAppeared(event.data);
        break;
      
      case ZoneEventType.ARTIFACT_SPAWNED:
        this.handleArtifactSpawned(event.data);
        break;
    }
  }
  
  private handleBlowout(blowout: BlowoutEvent): void {
    // Find all NPCs in affected area
    const affectedNPCs = this.npcManager.getNPCsInRadius(
      blowout.center,
      blowout.radius
    );
    
    // Trigger appropriate responses
    for (const npc of affectedNPCs) {
      // Strategic brain creates response strategy
      npc.strategicBrain.handleEmergency({
        type: EmergencyType.BLOWOUT,
        severity: blowout.intensity,
        expectedDuration: blowout.estimatedDuration,
        escapeRoutes: blowout.calculateEscapeRoutes(npc.position)
      });
      
      // Tactical brain handles immediate response
      npc.tacticalBrain.reactToImminentThreat({
        threat: blowout,
        timeToImpact: blowout.getTimeToReach(npc.position)
      });
    }
  }
}
```

## 6. Wydajność i Monitoring

### 6.1 Zaawansowane Metryki Wydajności

```typescript
// Comprehensive performance monitoring
class PerformanceMonitor {
  private metrics: Map<MetricType, TimeSeries>;
  private profilers: Map<SystemID, SystemProfiler>;
  private performanceTargets: PerformanceTargets;
  private alertSystem: AlertSystem;
  
  // Record detailed metrics
  recordAIPerformance(npcId: string, metrics: AIPerformanceData): void {
    // Strategic brain metrics
    this.recordMetric('ai.strategic.decision_time', metrics.strategicDecisionTime);
    this.recordMetric('ai.strategic.goals_evaluated', metrics.goalsEvaluated);
    this.recordMetric('ai.strategic.memory_queries', metrics.memoryQueries);
    
    // Tactical brain metrics
    this.recordMetric('ai.tactical.perception_time', metrics.perceptionTime);
    this.recordMetric('ai.tactical.pathfinding_time', metrics.pathfindingTime);
    this.recordMetric('ai.tactical.action_execution_time', metrics.actionExecutionTime);
    
    // LOD metrics
    this.recordMetric('ai.lod.current_level', metrics.currentLOD);
    this.recordMetric('ai.lod.transition_count', metrics.lodTransitions);
    
    // Memory usage
    this.recordMetric('ai.memory.strategic_brain', metrics.strategicMemoryUsage);
    this.recordMetric('ai.memory.tactical_brain', metrics.tacticalMemoryUsage);
    this.recordMetric('ai.memory.history_size', metrics.historySize);
    
    // Check performance targets
    this.checkPerformanceTargets(metrics);
  }
  
  // Bottleneck identification
  identifyBottlenecks(): PerformanceBottleneck[] {
    const bottlenecks: PerformanceBottleneck[] = [];
    
    // Analyze frame timing
    const frameTimeData = this.metrics.get(MetricType.FRAME_TIME);
    if (frameTimeData && frameTimeData.average > this.performanceTargets.maxFrameTime) {
      const contributors = this.identifyFrameTimeContributors();
      bottlenecks.push(new PerformanceBottleneck(
        'frame_time',
        contributors,
        frameTimeData.average
      ));
    }
    
    // Analyze memory usage
    const memoryUsage = this.metrics.get(MetricType.MEMORY_USAGE);
    if (memoryUsage && memoryUsage.current > this.performanceTargets.maxMemoryUsage) {
      const memoryHogs = this.identifyMemoryHogs();
      bottlenecks.push(new PerformanceBottleneck(
        'memory_usage',
        memoryHogs,
        memoryUsage.current
      ));
    }
    
    // Analyze AI performance
    const aiBottlenecks = this.identifyAIBottlenecks();
    bottlenecks.push(...aiBottlenecks);
    
    return bottlenecks;
  }
  
  private identifyAIBottlenecks(): PerformanceBottleneck[] {
    const bottlenecks: PerformanceBottleneck[] = [];
    
    // Check decision time distribution
    const decisionTimes = this.getMetricDistribution('ai.strategic.decision_time');
    const slowDecisionMakers = decisionTimes.outliers.high;
    
    if (slowDecisionMakers.length > 0) {
      bottlenecks.push(new PerformanceBottleneck(
        'slow_strategic_decisions',
        slowDecisionMakers,
        decisionTimes.p95
      ));
    }
    
    // Check pathfinding performance
    const pathfindingTimes = this.getMetricDistribution('ai.tactical.pathfinding_time');
    if (pathfindingTimes.average > PATHFINDING_TARGET_TIME) {
      bottlenecks.push(new PerformanceBottleneck(
        'pathfinding_performance',
        this.analyzePathfindingBottlenecks(),
        pathfindingTimes.average
      ));
    }
    
    // Check LOD thrashing
    const lodTransitions = this.metrics.get(MetricType.LOD_TRANSITIONS);
    if (lodTransitions && lodTransitions.rate > LOD_TRANSITION_THRESHOLD) {
      bottlenecks.push(new PerformanceBottleneck(
        'lod_thrashing',
        this.analyzeLODThrashing(),
        lodTransitions.rate
      ));
    }
    
    return bottlenecks;
  }
  
  // Performance optimization suggestions
  generateOptimizationRecommendations(): OptimizationRecommendation[] {
    const recommendations: OptimizationRecommendation[] = [];
    const bottlenecks = this.identifyBottlenecks();
    
    for (const bottleneck of bottlenecks) {
      switch (bottleneck.type) {
        case 'slow_strategic_decisions':
          recommendations.push({
            type: 'optimization',
            priority: Priority.HIGH,
            description: 'Reduce strategic brain update frequency for distant NPCs',
            implementation: 'Implement distance-based strategic update intervals',
            expectedGain: '15-25% strategic brain performance improvement'
          });
          break;
        
        case 'pathfinding_performance':
          recommendations.push({
            type: 'optimization',
            priority: Priority.MEDIUM,
            description: 'Implement hierarchical pathfinding for long distances',
            implementation: 'Add abstract path layer for paths > 200 units',
            expectedGain: '30-40% pathfinding performance for long paths'
          });
          break;
        
        case 'lod_thrashing':
          recommendations.push({
            type: 'configuration',
            priority: Priority.MEDIUM,
            description: 'Adjust LOD transition hysteresis',
            implementation: 'Increase LOD transition thresholds by 10-15%',
            expectedGain: 'Reduce LOD transitions by 40-50%'
          });
          break;
      }
    }
    
    return recommendations;
  }
}
```

### 6.2 Adaptive Performance System

```typescript
// Adaptive system that adjusts performance based on hardware
class AdaptivePerformanceSystem {
  private performanceHistory: PerformanceHistory;
  private hardwareProfile: HardwareProfile;
  private adaptationStrategies: Map<PerformanceIssue, AdaptationStrategy[]>;
  
  initialize(): void {
    // Profile hardware capabilities
    this.hardwareProfile = this.profileHardware();
    
    // Set initial performance parameters
    this.setInitialPerformanceParameters();
    
    // Register adaptation strategies
    this.registerAdaptationStrategies();
  }
  
  private profileHardware(): HardwareProfile {
    return {
      cpu: {
        cores: navigator.hardwareConcurrency,
        speed: this.estimateCPUSpeed(),
        features: this.detectCPUFeatures()
      },
      memory: {
        total: this.getTotalMemory(),
        available: this.getAvailableMemory()
      },
      gpu: {
        vendor: this.getGPUVendor(),
        memory: this.getGPUMemory(),
        features: this.detectGPUFeatures()
      }
    };
  }
  
  adaptPerformance(): void {
    const currentPerformance = this.performanceMonitor.getCurrentMetrics();
    const issues = this.identifyPerformanceIssues(currentPerformance);
    
    for (const issue of issues) {
      const strategies = this.adaptationStrategies.get(issue.type);
      if (!strategies) continue;
      
      // Select best strategy based on current state
      const strategy = this.selectBestStrategy(strategies, issue);
      
      // Apply adaptation
      const result = strategy.apply(issue);
      
      // Record adaptation for future reference
      this.recordAdaptation(issue, strategy, result);
    }
  }
  
  private selectBestStrategy(
    strategies: AdaptationStrategy[], 
    issue: PerformanceIssue
  ): AdaptationStrategy {
    // Score strategies based on:
    // - Expected effectiveness for the specific issue
    // - Impact on user experience
    // - Reversibility
    // - Previous success rate
    
    let bestStrategy = strategies[0];
    let bestScore = 0;
    
    for (const strategy of strategies) {
      const score = this.scoreStrategy(strategy, issue);
      if (score > bestScore) {
        bestScore = score;
        bestStrategy = strategy;
      }
    }
    
    return bestStrategy;
  }
  
  private scoreStrategy(strategy: AdaptationStrategy, issue: PerformanceIssue): number {
    let score = 0;
    
    // Effectiveness score
    const expectedEffectiveness = strategy.getExpectedEffectiveness(issue);
    score += expectedEffectiveness * 0.4;
    
    // User experience impact (lower is better)
    const uxImpact = strategy.getUserExperienceImpact();
    score += (1 - uxImpact) * 0.3;
    
    // Success history
    const successRate = this.getStrategySuccessRate(strategy);
    score += successRate * 0.2;
    
    // Reversibility (important for dynamic adaptation)
    const reversibility = strategy.isReversible() ? 1 : 0.5;
    score += reversibility * 0.1;
    
    return score;
  }
}

// Adaptive LOD system
class AdaptiveLODSystem {
  private performanceTarget: number = 60; // Target FPS
  private currentFrameTime: number = 0;
  private frameTimeHistory: number[] = [];
  private lodConfiguration: LODConfiguration;
  
  updateLODConfiguration(): void {
    // Calculate moving average frame time
    this.currentFrameTime = this.calculateAverageFrameTime();
    
    // Determine if adjustment is needed
    if (this.shouldAdjustLOD()) {
      const adjustment = this.calculateOptimalAdjustment();
      this.applyLODAdjustment(adjustment);
    }
  }
  
  private shouldAdjustLOD(): boolean {
    const targetFrameTime = 1000 / this.performanceTarget;
    const deviation = Math.abs(this.currentFrameTime - targetFrameTime);
    
    // Only adjust if deviation is significant and consistent
    return deviation > targetFrameTime * 0.1 && 
           this.isDeviationConsistent();
  }
  
  private calculateOptimalAdjustment(): LODAdjustment {
    const targetFrameTime = 1000 / this.performanceTarget;
    const ratio = this.currentFrameTime / targetFrameTime;
    
    if (ratio > 1.1) {
      // Performance too low - reduce quality
      return {
        direction: AdjustmentDirection.REDUCE,
        magnitude: Math.min(1.0, (ratio - 1.0) * 2),
        priority: this.identifyLODPriorities()
      };
    } else if (ratio < 0.9) {
      // Performance good - increase quality
      return {
        direction: AdjustmentDirection.INCREASE,
        magnitude: Math.min(1.0, (1.0 - ratio) * 2),
        priority: this.identifyImprovementPriorities()
      };
    }
    
    return null;
  }
  
  private applyLODAdjustment(adjustment: LODAdjustment): void {
    // Adjust LOD distance thresholds
    if (adjustment.direction === AdjustmentDirection.REDUCE) {
      this.lodConfiguration.reduceLODDistances(adjustment.magnitude);
    } else {
      this.lodConfiguration.increaseLODDistances(adjustment.magnitude);
    }
    
    // Adjust update frequencies
    this.adjustUpdateFrequencies(adjustment);
    
    // Adjust batch sizes for AI processing
    this.adjustBatchSizes(adjustment);
    
    // Log adjustment for monitoring
    this.logLODAdjustment(adjustment);
  }
}
```

## 7. Integrace Godot 4

### 7.1 Godot 4 Specific Implementation Guidelines

```csharp
// Godot 4 AutoLoad for AI system management
public partial class AISystemManager : Node
{
    [Signal]
    public delegate void NPCDecisionMadeEventHandler(string npcId, AIDecision decision);
    
    [Signal]
    public delegate void FactionEventOccurredEventHandler(FactionEvent factionEvent);
    
    private Dictionary<string, NPCController> _npcControllers = new();
    private StrategicBrainManager _strategicManager;
    private ThreadManager _threadManager;
    
    public override void _Ready()
    {
        // Initialize thread manager
        _threadManager = new ThreadManager();
        
        // Setup strategic brain manager with proper threading
        _strategicManager = new StrategicBrainManager();
        _strategicManager.Initialize(_threadManager);
        
        // Connect to global events
        ConnectGlobalSignals();
        
        // Start update timer for strategic processing
        var timer = GetNode<Timer>("StrategicUpdateTimer");
        timer.WaitTime = 0.2; // 5 Hz update rate
        timer.Connect("timeout", Callable.From(UpdateStrategicBrains));
        timer.Start();
    }
    
    public void RegisterNPC(NPCController npc)
    {
        _npcControllers[npc.GetInstanceId().ToString()] = npc;
        _strategicManager.AddNPC(npc);
        
        // Setup NPC-specific signals
        npc.Connect("DecisionMade", Callable.From<AIDecision>(decision => 
            EmitSignal(nameof(NPCDecisionMade), npc.GetInstanceId().ToString(), decision)));
    }
    
    private void UpdateStrategicBrains()
    {
        // This runs on main thread but delegates work to worker threads
        _strategicManager.UpdateAllBrains();
    }
}

// NPC Controller leveraging Godot's node system
public partial class NPCController : CharacterBody3D
{
    [Export] public NPCConfiguration Configuration { get; set; }
    [Export] public float PerceptionRange { get; set; } = 50.0f;
    
    private StrategicBrain _strategicBrain;
    private TacticalBrain _tacticalBrain;
    private NPCPerception _perception;
    private NPCMovement _movement;
    
    // LOD system integration
    private VisibilityNotifier3D _visibilityNotifier;
    private float _currentLODDistance = 0.0f;
    private LODLevel _currentLOD = LODLevel.Full;
    
    public override void _Ready()
    {
        // Initialize AI components
        InitializeAIComponents();
        
        // Setup perception system
        SetupPerceptionSystem();
        
        // Setup LOD management
        SetupLODSystem();
        
        // Register with global AI manager
        ((AISystemManager)GetNode("/root/AISystemManager")).RegisterNPC(this);
    }
    
    public override void _Process(double delta)
    {
        // Update based on current LOD level
        switch (_currentLOD)
        {
            case LODLevel.Full:
                UpdateFullDetail(delta);
                break;
            case LODLevel.Medium:
                UpdateMediumDetail(delta);
                break;
            case LODLevel.Low:
                UpdateLowDetail(delta);
                break;
            case LODLevel.StrategicOnly:
                // No processing on main thread
                break;
        }
    }
    
    private void SetupLODSystem()
    {
        _visibilityNotifier = GetNode<VisibilityNotifier3D>("VisibilityNotifier");
        
        // Connect LOD change signals
        _visibilityNotifier.Connect("screen_entered", Callable.From(OnScreenEntered));
        _visibilityNotifier.Connect("screen_exited", Callable.From(OnScreenExited));
        
        // Setup distance-based LOD updates
        var lodUpdateTimer = new Timer();
        AddChild(lodUpdateTimer);
        lodUpdateTimer.WaitTime = 0.1; // 10 Hz LOD updates
        lodUpdateTimer.Connect("timeout", Callable.From(UpdateLOD));
        lodUpdateTimer.Start();
    }
    
    private void UpdateLOD()
    {
        var player = GetNode<Player>("/root/Player");
        _currentLODDistance = GlobalPosition.DistanceTo(player.GlobalPosition);
        
        var newLOD = DetermineLODLevel(_currentLODDistance);
        if (newLOD != _currentLOD)
        {
            TransitionToLOD(newLOD);
        }
    }
    
    private LODLevel DetermineLODLevel(float distance)
    {
        if (distance <= 50.0f) return LODLevel.Full;
        if (distance <= 200.0f) return LODLevel.Medium;
        if (distance <= 500.0f) return LODLevel.Low;
        return LODLevel.StrategicOnly;
    }
}

// Zone system using Godot's Area3D
public partial class AnomalyArea : Area3D
{
    [Export] public AnomalyType AnomalyType { get; set; }
    [Export] public float Intensity { get; set; } = 1.0f;
    [Export] public float MaxRadius { get; set; } = 10.0f;
    
    private AnomalyBehavior _behavior;
    private Timer _updateTimer;
    private float _currentRadius;
    
    public override void _Ready()
    {
        // Setup area monitoring
        Monitoring = true;
        Monitorable = true;
        
        // Connect area signals
        Connect("body_entered", Callable.From<Node3D>(OnBodyEntered));
        Connect("body_exited", Callable.From<Node3D>(OnBodyExited));
        
        // Initialize anomaly behavior
        _behavior = AnomalyBehaviorFactory.Create(AnomalyType);
        
        // Setup update timer
        _updateTimer = new Timer();
        AddChild(_updateTimer);
        _updateTimer.WaitTime = 0.1f;
        _updateTimer.Connect("timeout", Callable.From(UpdateAnomaly));
        _updateTimer.Start();
    }
    
    private void OnBodyEntered(Node3D body)
    {
        if (body is NPCController npc)
        {
            // Calculate effect on NPC
            var effect = _behavior.CalculateEffect(npc, Intensity);
            npc.ApplyAnomalyEffect(effect);
            
            // Notify NPC's AI about anomaly interaction
            npc.NotifyAnomalyInteraction(this, InteractionType.Enter);
        }
    }
    
    private void UpdateAnomaly()
    {
        // Update anomaly behavior
        _behavior.Update(GetPhysicsDirectSpaceState());
        
        // Update visual representation
        UpdateVisualEffects();
        
        // Check for artifact generation
        CheckArtifactGeneration();
    }
}

// Faction management using Godot's resource system
[GlobalClass]
public partial class FactionResource : Resource
{
    [Export] public string FactionId { get; set; }
    [Export] public string Name { get; set; }
    [Export] public FactionType Type { get; set; }
    [Export] public Godot.Collections.Dictionary<string, float> Relationships { get; set; } = new();
    [Export] public Godot.Collections.Array<string> MemberIds { get; set; } = new();
    [Export] public float Influence { get; set; } = 0.0f;
    
    // Goals stored as custom resources
    [Export] public Godot.Collections.Array<FactionGoalResource> Goals { get; set; } = new();
}
```

### 7.2 Godot 4 Performance Considerations

```csharp
// Performance optimization using Godot 4 features
public partial class PerformanceManager : Node
{
    // Use Godot's built-in profiler integration
    [Export] public bool EnableProfiling { get; set; } = true;
    
    // Leverage Godot's threading system
    private WorkerThreadPool _threadPool;
    private Mutex _dataLock = new();
    
    public override void _Ready()
    {
        // Initialize thread pool with Godot 4 API
        _threadPool = WorkerThreadPool.GetSingleton();
        
        // Setup performance monitoring
        if (EnableProfiling)
        {
            SetupPerformanceMonitoring();
        }
    }
    
    // Async pathfinding using Godot's task system
    public async Task<Path> CalculatePathAsync(Vector3 start, Vector3 end, PathfindingOptions options)
    {
        var task = Task.Run(() =>
        {
            // Pathfinding calculation in background thread
            return CalculatePath(start, end, options);
        });
        
        return await task;
    }
    
    // Batch processing using WorkerThreadPool
    public void ProcessAI批量(IEnumerable<NPCController> npcs)
    {
        var batches = CreateBatches(npcs, Environment.ProcessorCount);
        
        foreach (var batch in batches)
        {
            _threadPool.AddTask(Callable.From(() => ProcessBatch(batch)));
        }
    }
    
    // Memory management using Godot's ObjectDB
    public void OptimizeMemoryUsage()
    {
        // Force garbage collection
        GC.Collect();
        
        // Clean up orphaned objects
        GD.PrintRich("[color=yellow]Cleaning up orphaned objects...[/color]");
        
        // Use Godot's object profiling
        var objectCount = Engine.GetSingleton().GetSingletonList().Count;
        GD.Print($"Active objects: {objectCount}");
    }
}

// Godot 4 specific AI debugging tools
public partial class AIDebugger : CanvasLayer
{
    private RichTextLabel _debugOutput;
    private Tree _npcTree;
    private VBoxContainer _metricsContainer;
    
    public override void _Ready()
    {
        // Setup debug UI
        SetupDebugUI();
        
        // Connect to AI events
        ConnectToAIEvents();
    }
    
    public override void _Input(InputEvent @event)
    {
        if (@event.IsActionPressed("toggle_ai_debug"))
        {
            Visible = !Visible;
        }
        
        if (@event.IsActionPressed("ai_step_mode"))
        {
            ToggleStepMode();
        }
    }
    
    private void ToggleStepMode()
    {
        var aiManager = GetNode<AISystemManager>("/root/AISystemManager");
        aiManager.ToggleStepMode();
        
        if (aiManager.IsInStepMode())
        {
            _debugOutput.AppendText("[color=red]AI Step Mode ENABLED[/color]\n");
        }
        else
        {
            _debugOutput.AppendText("[color=green]AI Step Mode DISABLED[/color]\n");
        }
    }
    
    // Visualize AI states in 3D space
    private void UpdateAIVisualization()
    {
        var viewport = GetViewport();
        if (viewport == null) return;
        
        foreach (var npc in GetTree().GetNodesInGroup("NPCs").Cast<NPCController>())
        {
            // Draw decision trees
            DrawDecisionTree(npc);
            
            // Draw pathfinding info
            DrawPathfindingVisualization(npc);
            
            // Draw perception ranges
            DrawPerceptionVisualization(npc);
        }
    }
}
```

## Podsumowanie

Architektura techniczna "Cienia Podróżnika" została szczegółowo rozszerzona o:

1. **Zaawansowany System Dual-Brain AI**: 
   - Modularna architektura z wyspecjalizowanymi komponentami
   - Utility-based decision making
   - Zaawansowawna pamięć i percepcja

2. **Hierarchический LOD System**: 
   - Dynamiczne dostosowywanie do wydajności
   - Inteligentne przejścia między poziomami
   - Adaptive performance management

3. **Sophisticated History System**:
   - Narrative generation
   - Pattern recognition
   - Emergentne opowieści

4. **Advanced Threading Architecture**:
   - Specialized thread pools
   - Efficient batch processing
   - Non-blocking AI updates

5. **Design Patterns **:
   - State Machine for behaviors
   - Command pattern for actions  
   - Observer pattern for events

6. **Performance Monitoring & Optimization**:
   - Detailed metrics collection
   - Bottleneck identification
   - Adaptive performance system

7. **Godot 4 Integration**:
   - Node-based architecture
   - Signal system utilization
   - Threading integration
   - Debug tools

Wszystkie systemy są zaprojektowane do współpracy, tworząc emergentne zachowania i umożliwiając implementację w Godot 4 z pełnym wykorzystaniem jego możliwości.

> **Documentation Links**: Zobacz [api-specifications.md](api-specifications.md) для interfaces, [functions-index.md](functions-index.md) dla dependenci и [glossary.md](glossary.md) для terminologii.