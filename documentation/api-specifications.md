# Cień Podróżnika - Specyfikacje API i Interfejsów

Ten dokument definiuje wszystkie interfejsy API między systemami gry "Cień Podróżnika", struktury danych i protokoły komunikacji. Dokument jest technology-agnostic, ale uwzględnia specyfikę Godot 4 w kontekście implementacji.

> **Referencje**: Ten dokument uzupełnia [technical-design.md](technical-design.md) i [functions-index.md](functions-index.md)

## 1. Core API - System Dwóch Mózgów

### 1.1 Interface Strategic Brain ↔ Tactical Brain

```typescript
// Główny interfejs komunikacji między mózgami
interface BrainSynchronizer {
  // Wysokopoziomowe komendy strategiczne
  sendStrategicCommand(command: StrategicCommand): Promise<ExecutionResult>;
  
  // Feedback z poziomu taktycznego
  reportTacticalState(state: TacticalState): void;
  
  // Negocjacja konfliktów między poziomami
  negotiateConflict(conflict: CommandConflict): Resolution;
  
  // Synchronizacja stanów
  synchronizeState(frequency: SyncFrequency): void;
}

// Command Pattern dla komunikacji AI
interface StrategicCommand {
  readonly id: string;
  readonly priority: CommandPriority;
  readonly deadline?: number; // timestamp
  readonly context: StrategicContext;
  
  // Metody wykonania
  execute(tacticalBrain: TacticalBrain): Promise<ExecutionResult>;
  canExecute(tacticalBrain: TacticalBrain): boolean;
  estimateCost(): ResourceCost;
  
  // Serialization dla network/save
  serialize(): SerializedCommand;
  static deserialize(data: SerializedCommand): StrategicCommand;
}

// Typy komend strategicznych
enum CommandType {
  MOVE_TO_LOCATION = "MOVE_TO_LOCATION",
  SEEK_ARTIFACT = "SEEK_ARTIFACT",
  AVOID_THREAT = "AVOID_THREAT",
  SOCIAL_INTERACTION = "SOCIAL_INTERACTION",
  ECONOMIC_TRANSACTION = "ECONOMIC_TRANSACTION",
  FACTION_OPERATION = "FACTION_OPERATION"
}

// Command implementations
class MoveToLocationCommand implements StrategicCommand {
  constructor(
    public readonly target: Vector3,
    public readonly urgency: number,
    public readonly safetyRequirement: number
  ) {}
  
  async execute(tacticalBrain: TacticalBrain): Promise<ExecutionResult> {
    // Request pathfinding from tactical brain
    const path = await tacticalBrain.calculatePath(this.target, {
      safety: this.safetyRequirement,
      urgency: this.urgency
    });
    
    if (!path.isValid) {
      return ExecutionResult.failure("NO_VALID_PATH", path.errors);
    }
    
    // Execute movement
    return await tacticalBrain.executeMovement(path);
  }
}
```

### 1.2 State Management API

```typescript
// System zarządzania stanem NPC
interface NPCStateManager {
  // Główny stan NPC
  getCurrentState(npcId: string): NPCState;
  updateState(npcId: string, delta: StateUpdate): void;
  
  // Zarządzanie pamięcią
  getMemory(npcId: string): NPCMemory;
  addMemory(npcId: string, memory: MemoryEntry): void;
  
  // Cele i zadania
  getGoals(npcId: string): Goal[];
  addGoal(npcId: string, goal: Goal): void;
  completeGoal(npcId: string, goalId: string): void;
  
  // Relacje społeczne
  getRelationships(npcId: string): Map<string, Relationship>;
  updateRelationship(npcId: string, targetId: string, change: RelationshipChange): void;
}

// Kompletny stan NPC
interface NPCState {
  readonly id: string;
  readonly type: NPCType;
  
  // Physical state
  position: Vector3;
  rotation: Vector3;
  health: number;
  stamina: number;
  
  // Cognitive state
  awareness: number;
  stress: number;
  focus: AIFocus;
  
  // Inventory
  items: ItemStack[];
  weapons: Weapon[];
  
  // Zone marking influence
  marking?: ZoneMarking;
  
  // Faction allegiance
  faction?: FactionInfo;
  
  // Current objectives
  activeGoals: ActiveGoal[];
  
  // Serialization
  serialize(): SerializedNPCState;
}

// Memory system
interface MemoryEntry {
  readonly id: string;
  readonly type: MemoryType;
  readonly timestamp: number;
  readonly importance: number; // 0-1
  readonly decay: number; // how fast memory fades
  
  content: MemoryContent;
  emotions?: EmotionalResponse;
  participants?: string[]; // other NPC IDs involved
  location?: Vector3;
  
  // Memory queries
  matches(query: MemoryQuery): boolean;
  getRelevance(context: AIContext): number;
}

enum MemoryType {
  LOCATION_DISCOVERED = "LOCATION_DISCOVERED",
  ANOMALY_ENCOUNTERED = "ANOMALY_ENCOUNTERED",
  ARTIFACT_FOUND = "ARTIFACT_FOUND",
  COMBAT_ENGAGEMENT = "COMBAT_ENGAGEMENT",
  SOCIAL_INTERACTION = "SOCIAL_INTERACTION",
  FACTION_EVENT = "FACTION_EVENT",
  ZONE_MARKING_EFFECT = "ZONE_MARKING_EFFECT"
}
```

### 1.3 Perception System API

```typescript
// System percepcji dla AI
interface PerceptionSystem {
  // Główne metody percepcji
  perceiveEnvironment(npc: NPC, radius: number): PerceptionResult;
  detectAnomalies(npc: NPC): AnomalyDetection[];
  scanForArtifacts(npc: NPC): ArtifactDetection[];
  perceiveSocialSituation(npc: NPC): SocialContext;
  
  // Sprawdzanie linii wzroku
  canSee(observer: NPC, target: Vector3): LineOfSightResult;
  
  // System uwaги
  focusAttention(npc: NPC, target: AttentionTarget): void;
  distributeAttention(npc: NPC, targets: AttentionTarget[]): void;
}

// Rezultat percepcji
interface PerceptionResult {
  // Wykryte obiekty
  visibleNPCs: NPCDetection[];
  visibleItems: ItemDetection[];
  visibleThreats: ThreatDetection[];
  visibleOpportunities: OpportunityDetection[];
  
  // Zmiany środowiska
  environmentalChanges: EnvironmentChange[];
  
  // Dźwięki
  audibleEvents: AudioEvent[];
  
  // Zapachy (dla zaawansowanego AI)
  scents?: ScentSignature[];
  
  // Anomalie strefy
  anomalyEffects: AnomalyEffect[];
}

// Wykrywanie anomalii
interface AnomalyDetection {
  type: AnomalyType;
  position: Vector3;
  intensity: number;
  safetyRating: number;
  
  // Informacje o interakcji
  isKnown: boolean;
  lastEncountered?: number;
  
  // Predykcje zachowania
  predictedBehavior: AnomalyPrediction;
  
  // Metody analizy
  getProximityDanger(npcPosition: Vector3): DangerLevel;
  canBypass(): boolean;
  getBypassMethod(): BypassMethod | null;
}
```

## 2. Faction System API

### 2.1 Faction Management

```typescript
// Zarządzanie frakcjami
interface FactionManager {
  // CRUD operacje
  createFaction(template: FactionTemplate): Faction;
  getFaction(factionId: string): Faction | null;
  getAllFactions(): Faction[];
  updateFaction(factionId: string, updates: FactionUpdate): void;
  dissolveFaction(factionId: string): DissolutionResult;
  
  // Relacje między frakcjami
  getRelationship(factionA: string, factionB: string): FactionRelationship;
  updateRelationship(factionA: string, factionB: string, change: RelationshipChange): void;
  
  // Członkostwo
  addMember(factionId: string, npcId: string, role: FactionRole): void;
  removeMember(factionId: string, npcId: string): void;
  getMemberRole(factionId: string, npcId: string): FactionRole | null;
  
  // Wydarzenia frakcyjne
  processEvent(event: FactionEvent): void;
  getEventHistory(factionId: string): FactionEvent[];
  
  // Dynamika polityczna
  calculatePowerBalance(): PowerBalanceMap;
  predictConflicts(): ConflictPrediction[];
}

// Definicja frakcji
interface Faction {
  readonly id: string;
  readonly name: string;
  readonly type: FactionType;
  
  // Ideology and goals
  ideologyDocument: IdeologyDocument;
  primaryGoals: Goal[];
  currentPriorities: Priority[];
  
  // Organization
  hierarchy: FactionHierarchy;
  members: Map<string, FactionMembership>;
  
  // Resources and assets
  resources: ResourcePool;
  territories: Territory[];
  assets: FactionAsset[];
  
  // Relationships
  relationships: Map<string, FactionRelationship>;
  reputation: ReputationMap;
  
  // Operations
  activeOperations: Operation[];
  operationCapacity: OperationCapacity;
  
  // AI behavior modifiers
  behaviorModifiers: FactionBehaviorModifiers;
  
  // Methods
  canExecuteOperation(op: Operation): boolean;
  calculateInfluence(location: Vector3): number;
  getDisposition(target: string): FactionDisposition;
}

// Dinamika frakcji
interface FactionDynamics {
  // Evolucja celów
  evolveGoals(faction: Faction, context: WorldContext): Goal[];
  
  // Reakcje na wydarzenia
  reactToEvent(faction: Faction, event: WorldEvent): FactionResponse;
  
  // Formowanie nowych sojuszy
  evaluateAllianceOpportunities(faction: Faction): AllianceOpportunity[];
  
  // Rozwój ideologii
  evolveIdeology(faction: Faction, experiences: Experience[]): IdeologyUpdate;
  
  // Rekrutacja
  evaluateRecruitment(faction: Faction, candidate: NPC): RecruitmentAssessment;
}
```

### 2.2 Resource Management API

```typescript
// System zasobów ekonomicznych
interface ResourceManager {
  // Główne operacje
  getResourcePool(ownerId: string): ResourcePool;
  transferResources(from: string, to: string, transfer: ResourceTransfer): TransferResult;
  
  // Trading system
  createTrade(offerId: string, trader: string): TradeOffer;
  executeTrade(tradeId: string): TradeResult;
  
  // Production and consumption
  calculateProduction(location: string): ProductionOutput;
  calculateConsumption(ownerId: string): ConsumptionRequirement;
  
  // Market dynamics
  getMarketPrices(location?: string): PriceMap;
  predictPriceChanges(): PricePrediction[];
  
  // Supply chains
  traceSupplyChain(resourceType: ResourceType): SupplyChainMap;
  optimizeSupplyChain(chainId: string): OptimizationResult;
}

// Pool zasobów
interface ResourcePool {
  readonly ownerId: string;
  resources: Map<ResourceType, ResourceQuantity>;
  
  // Operations
  has(type: ResourceType, amount: number): boolean;
  add(type: ResourceType, amount: number): void;
  remove(type: ResourceType, amount: number): boolean;
  transfer(target: ResourcePool, transfer: ResourceTransfer): boolean;
  
  // Economy
  calculateValue(): number;
  getScarcity(type: ResourceType): ScarcityLevel;
  
  // Maintenance
  calculateUpkeep(): ResourceQuantity[];
  processDecay(deltaTime: number): void;
}

// Typy zasobów
enum ResourceType {
  // Basic resources
  RUBLES = "RUBLES",
  AMMUNITION = "AMMUNITION",
  FOOD = "FOOD",
  MEDICINE = "MEDICINE",
  
  // Zone-specific resources
  ARTIFACTS = "ARTIFACTS",
  DETECTORS = "DETECTORS",
  PROTECTIVE_GEAR = "PROTECTIVE_GEAR",
  
  // Faction resources
  INFLUENCE = "INFLUENCE",
  INTELLIGENCE = "INTELLIGENCE",
  REPUTATION = "REPUTATION",
  
  // Abstract resources
  TIME = "TIME",
  MORALE = "MORALE",
  EXPERTISE = "EXPERTISE"
}
```

## 3. Zone System API

### 3.3 Anomaly Management

```typescript
// System zarządzania anomaliami
interface AnomalyManager {
  // CRUD operations
  createAnomaly(type: AnomalyType, position: Vector3, parameters: AnomalyParameters): Anomaly;
  getAnomaly(id: string): Anomaly | null;
  getAnomaliesInRadius(center: Vector3, radius: number): Anomaly[];
  
  // Life cycle
  updateAnomaly(id: string, deltaTime: number): void;
  destroyAnomaly(id: string): void;
  
  // Interactions
  checkInteraction(npc: NPC, anomaly: Anomaly): InteractionResult;
  processInteraction(interaction: AnomalyInteraction): InteractionEffect[];
  
  // Artifact generation
  checkArtifactGeneration(anomaly: Anomaly): ArtifactGenerationResult;
  generateArtifact(anomaly: Anomaly, type: ArtifactType): Artifact;
  
  // Area effects
  calculateAreaEffect(position: Vector3): AreaEffect;
  getAffectedNPCs(anomaly: Anomaly): NPC[];
}

// Definicja anomalii
interface Anomaly {
  readonly id: string;
  readonly type: AnomalyType;
  
  // Physical properties  
  position: Vector3;
  radius: number;
  intensity: number;
  
  // Behavior
  behavior: AnomalyBehavior;
  activationTriggers: Trigger[];
  
  // Life cycle
  age: number;
  maxAge?: number;
  decayRate: number;
  
  // Interactions
  interactionHistory: Interaction[];
  artifactGenerationRate: number;
  
  // Effects
  effects: AnomalyEffect[];
  
  // Methods
  updateBehavior(deltaTime: number): void;
  checkTriggers(context: ZoneContext): TriggerResult[];
  calculateEffectRadius(): number;
  canGenerateArtifact(): boolean;
}

// Zachowanie anomalii
interface AnomalyBehavior {
  // Movement patterns
  movementType: MovementType;
  movementSpeed: number;
  pathPredictability: number;
  
  // Activity patterns
  activePeriods: TimePeriod[];
  dormantPeriods: TimePeriod[];
  
  // Response to stimuli
  responses: Map<StimulusType, Response>;
  
  // Evolution
  evolutionParameters: EvolutionParameters;
  mutationRate: number;
  
  // Methods
  update(deltaTime: number, context: ZoneContext): BehaviorUpdate;
  respondToStimulus(stimulus: Stimulus): Response;
  predictNextAction(timeHorizon: number): ActionPrediction;
}
```

### 3.2 Zone Events System

```typescript
// System событий strefy
interface ZoneEventManager {
  // Event lifecycle
  createEvent(type: EventType, location: Vector3, parameters: EventParameters): ZoneEvent;
  processEvent(event: ZoneEvent): EventResult;
  resolveEvent(eventId: string): void;
  
  // Event chains
  createEventChain(trigger: EventTrigger): EventChain;
  processEventChain(chainId: string): void;
  
  // Emissions and blowouts
  scheduleEmission(location: Vector3, delay: number): EmissionEvent;
  processEmission(emission: EmissionEvent): EmissionResult;
  
  // Weather events
  updateWeather(deltaTime: number): WeatherUpdate;
  predictWeatherChanges(): WeatherPrediction[];
  
  // Listeners
  addEventListener(type: EventType, listener: EventListener): void;
  removeEventListener(listenerId: string): void;
}

// Zone events
interface ZoneEvent {
  readonly id: string;
  readonly type: EventType;
  readonly timestamp: number;
  
  // Location and scope
  location: Vector3;
  radius: number;
  affectedAreas: Zone[];
  
  // Properties
  intensity: number;
  duration: number;
  
  // Participants
  affectedNPCs: string[];
  affectedFactions: string[];
  
  // Effects
  effects: EventEffect[];
  consequences: EventConsequence[];
  
  // State
  state: EventState;
  progress: number;
  
  // Methods
  update(deltaTime: number): EventUpdate;
  checkResolutionConditions(): boolean;
  calculateEffects(): EventEffect[];
}

// Emissions (powerful zone events)
interface EmissionEvent extends ZoneEvent {
  // Emission-specific properties
  emissionType: EmissionType;
  originPoint: Vector3;
  expansionRate: number;
  
  // Anomaly changes
  anomalyCreation: AnomalyCreationRule[];
  anomalyDestruction: string[]; // Anomaly IDs to destroy
  anomalyModification: AnomalyModification[];
  
  // Effects on NPCs
  npcEffects: NPCEffect[];
  
  // Environmental changes
  landscapeChanges: LandscapeChange[];
  
  // Methods
  propagate(deltaTime: number): PropagationResult;
  createAnomalies(): Anomaly[];
  modifyTerrain(): TerrainModification[];
}
```

## 4. Integration Protocols

### 4.1 System Communication

```typescript
// Główny interfejs komunikacji między systemami
interface SystemBus {
  // Message passing
  send<T>(target: SystemID, message: Message<T>): Promise<Response<T>>;
  broadcast<T>(message: BroadcastMessage<T>): void;
  
  // Event subscription
  subscribe<T>(eventType: EventType, handler: EventHandler<T>): SubscriptionID;
  unsubscribe(subscriptionId: SubscriptionID): void;
  
  // System registration
  registerSystem(system: GameSystem): void;
  unregisterSystem(systemId: SystemID): void;
  
  // Health monitoring
  getSystemHealth(systemId: SystemID): SystemHealth;
  getAllSystemsHealth(): Map<SystemID, SystemHealth>;
}

// Protokół wiadomości
interface Message<T = any> {
  readonly id: string;
  readonly source: SystemID;
  readonly target: SystemID;
  readonly type: MessageType;
  readonly timestamp: number;
  
  payload: T;
  metadata?: MessageMetadata;
  
  // Message handling
  requiresResponse: boolean;
  timeoutMs?: number;
}

// Typy systemów
enum SystemID {
  AI_DUAL_BRAIN = "AI_DUAL_BRAIN",
  ZONE_MANAGER = "ZONE_MANAGER", 
  FACTION_MANAGER = "FACTION_MANAGER",
  RESOURCE_MANAGER = "RESOURCE_MANAGER",
  EVENT_MANAGER = "EVENT_MANAGER",
  NARRATIVE_MANAGER = "NARRATIVE_MANAGER",
  SAVE_MANAGER = "SAVE_MANAGER"
}

// System lifecycle
interface GameSystem {
  readonly id: SystemID;
  readonly dependencies: SystemID[];
  
  // Lifecycle
  initialize(bus: SystemBus): Promise<void>;
  update(deltaTime: number): void;
  shutdown(): Promise<void>;
  
  // Message handling
  handleMessage<T>(message: Message<T>): Promise<Response<T>>;
  
  // Health monitoring
  getHealth(): SystemHealth;
}
```

### 4.2 Data Serialization

```typescript
// System serializacji dla save/load
interface SerializationManager {
  // Core methods
  serialize<T>(object: T): SerializedData;
  deserialize<T>(data: SerializedData, type: TypeConstructor<T>): T;
  
  // Batch operations
  serializeBatch(objects: object[]): SerializedBatch;
  deserializeBatch<T>(batch: SerializedBatch): T[];
  
  // Streaming for large data
  createStream<T>(objects: Iterable<T>): SerializationStream<T>;
  readStream<T>(stream: SerializationStream<T>): AsyncIterable<T>;
  
  // Version management
  registerVersion(version: string, schema: SerializationSchema): void;
  migrateData(data: SerializedData, fromVersion: string, toVersion: string): SerializedData;
}

// Serialized data formats
interface SerializedData {
  type: string;
  version: string;
  data: any;
  checksum: string;
  metadata: SerializationMetadata;
}

// Schema definition for migrations
interface SerializationSchema {
  version: string;
  fields: FieldDefinition[];
  migrations: Migration[];
  
  // Validation
  validate(data: any): ValidationResult;
  migrate(data: any, targetVersion: string): MigrationResult;
}

// Custom serializers
interface CustomSerializer<T> {
  canSerialize(object: any): object is T;
  serialize(object: T): any;
  deserialize(data: any): T;
  getVersion(): string;
}
```

## 5. Performance and Monitoring APIs

### 5.1 Performance Profiling

```typescript
// Performance monitoring system
interface PerformanceProfiler {
  // Profiling sessions
  startProfiling(sessionName: string, options: ProfilingOptions): ProfilingSession;
  stopProfiling(sessionId: string): ProfilingResult;
  
  // Metrics collection
  recordMetric(name: string, value: number, tags?: MetricTags): void;
  recordEvent(name: string, data: EventData): void;
  
  // Memory tracking
  captureMemorySnapshot(name: string): MemorySnapshot;
  trackMemoryLeaks(): MemoryLeakReport[];
  
  // Frame timing
  measureFrameTime(): FrameTimeMetrics;
  detectFrameDrops(): FrameDropEvents[];
  
  // System resources
  getSystemResourceUsage(): SystemResourceUsage;
  setResourceWarningThresholds(thresholds: ResourceThresholds): void;
  
  // Reports
  generateReport(timeRange: TimeRange): PerformanceReport;
  exportData(format: ExportFormat): ExportedData;
}

// Profiling результаты
interface ProfilingResult {
  sessionId: string;
  sessionName: string;
  duration: number;
  
  // Timing data
  totalTime: number;
  functionCalls: FunctionCallData[];
  
  // Resource usage
  memoryUsage: MemoryUsageProfile;
  cpuUsage: CPUUsageProfile;
  
  // AI-specific metrics
  aiDecisionTimes: DecisionTimeProfile[];
  npcUpdateTimes: Map<string, number>;
  
  // Bottlenecks
  bottlenecks: PerformanceBottleneck[];
  recommendations: PerformanceRecommendation[];
}

// Specific AI performance metrics
interface AIPerformanceMetrics {
  // Dual-brain system metrics
  strategicBrainTiming: TimingMetrics;
  tacticalBrainTiming: TimingMetrics;
  brainSynchronizationTime: number;
  
  // LOD system metrics
  lodTransitions: LODTransitionMetrics[];
  activeNPCsByLOD: Map<LODLevel, number>;
  
  // Decision quality metrics
  decisionSuccessRate: number;
  planExecutionTime: number;
  pathfindingEfficiency: number;
  
  // Memory usage
  npcMemoryFootprint: NPCMemoryFootprint[];
  historySizeLimits: number;
}
```

### 5.2 Debugging Tools API

```typescript
// Debugging interface for development
interface DebugInterface {
  // AI debugging
  startAIDebugSession(npcId: string): AIDebugSession;
  stopAIDebugSession(sessionId: string): void;
  
  // Visualization
  enableVisualDebug(systems: SystemID[]): void;
  disableVisualDebug(systems: SystemID[]): void;
  
  // State inspection
  inspectNPCState(npcId: string): NPCStateInspection;
  inspectFactionState(factionId: string): FactionStateInspection;
  inspectZoneState(zoneId: string): ZoneStateInspection;
  
  // Simulation control
  pauseSystem(systemId: SystemID): void;
  resumeSystem(systemId: SystemID): void;
  stepSystem(systemId: SystemID, steps: number): void;
  
  // Time manipulation
  setTimeScale(scale: number): void;
  pauseTime(): void;
  resumeTime(): void;
  
  // Event injection
  injectEvent<T>(eventType: EventType, data: T): void;
  injectScenario(scenarioId: string): void;
}

// AI debug session
interface AIDebugSession {
  readonly sessionId: string;
  readonly npcId: string;
  
  // Decision tracking
  getDecisionTrace(): DecisionTrace[];
  getCurrentGoals(): Goal[];
  getCurrentState(): NPCState;
  
  // Brain state visualization
  getStrategicBrainState(): StrategicBrainState;
  getTacticalBrainState(): TacticalBrainState;
  
  // Memory inspection
  getMemoryContents(): MemoryEntry[];
  searchMemory(query: MemoryQuery): MemoryEntry[];
  
  // Relationship visualization
  getRelationshipMap(): RelationshipMap;
  getSocialContext(): SocialContext;
  
  // Predictions
  getNextActions(timeHorizon: number): ActionPrediction[];
  getGoalPredictions(): GoalPrediction[];
}
```

## 6. Godot 4 Considerations

### 6.1 Engine Integration Guidelines

```typescript
// Guidelines for Godot 4 implementation
interface GodotIntegrationNotes {
  // Recommendations for Godot 4
  nodeStructure: {
    // AI system should use separate nodes for strategic/tactical brains
    strategicBrainNode: "AutoLoad singleton for strategic decisions";
    tacticalBrainNodes: "Individual nodes attached to NPC scenes";
    
    // Zone system integration
    zoneManagerNode: "WorldManager autoload";
    anomalyNodes: "Area3D nodes with custom scripts";
    
    // Faction management
    factionManagerNode: "AutoLoad singleton";
    
    // Resource management
    resourceManagerNode: "AutoLoad singleton with persistent data";
  };
  
  // Godot-specific patterns
  signalPatterns: {
    // Use signals for system communication
    crossSystemMessaging: "Global signal bus";
    npcEvents: "Instance-specific signals";
    zoneEvents: "Area-based signals";
  };
  
  // MultiExporting and scenes
  sceneOrganization: {
    npcScenes: "PackedScene with modular components";
    anomalyScenes: "Procedurally instantiated Area3D";
    locationScenes: "Separate scenes with async loading";
  };
  
  // Threading considerations
  threading: {
    strategicAI: "Worker threads with call_deferred";
    pathfinding: "WorkerThreadPool for batch processing";
    serialization: "Background thread with Mutex protection";
  };
}
```

## Podsumowanie

Tej specyfikacji API służy jako most między abstrakcyjnymi systemami opisanymi w dokumentacji projektowej a konkretną implementacją w Godot 4. Kluczowe aspekty:

1. **Modularna struktura** umożliwiająca łatwe testowanie i rozbudowę
2. **Jasno zdefiniowane interfejsy** między systemami
3. **Async/await patterns** dla operacji wymagających czasu
4. **Sistem eventów** dla luźnego sprzężenia componentów
5. **Kompleksowe narzędzia** debugowania i profilowania
6. **Serialization** z support migracj wersji
7. **Performance monitoring** z konkretnymi metrykami

Wszystkie interfejsy są zaprojektowane tak, aby być implementowalne w Godot 4 z wykorzystaniem jego systemu węzłów, sygnałów i skryptów.

> **Next Steps**: Zobacz [technical-design.md](technical-design.md) dla implementacj wzorcydesigнs i [functions-index.md](functions-index.md) dla contextdependencies między systemami.