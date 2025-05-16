# Cień Podróżnika - Przewodnik Testowania i Narzędzi Deweloperskich

Ten dokument zawiera praktyczne informacje o testowaniu systemów AI, metrykach wydajności, narzędziach deweloperskich i procedurach zapewniania jakości w projekcie "Cień Podróżnika".

> **Referencje**: Zobacz [technical-design.md](technical-design.md) dla szczegółów technicznych i [api-specifications.md](api-specifications.md) dla interfejsów.

## 1. Testowanie Systemów AI

### 1.1 Architektura Testów AI

Testowanie Systemu Dwóch Mózgów (patrz: [glossary.md](glossary.md)#system-dwóch-mózgów) wymaga specjalistycznego podejścia ze względu na emergentne zachowania i złożoność interakcji.

```typescript
// Framework testowy dla AI
export class AITestFramework {
  private testEnvironment: TestEnvironment;
  private mockWorld: MockWorldState;
  private behaviorValidators: BehaviorValidator[];
  
  // Setup isolated test environment
  async setupTestEnvironment(): Promise<TestEnvironment> {
    return {
      isolatedWorld: await this.createMockWorld(),
      controlledNPCs: await this.spawnTestNPCs(),
      deterministicRandom: new SeededRandom(FIXED_SEED),
      acceleratedTime: new TimeAccelerator(10)
    };
  }
  
  // Test strategic brain decision making
  async testStrategicDecisions(scenario: TestScenario): Promise<TestResult> {
    const npc = await this.createTestNPC(scenario.npcConfig);
    const worldState = this.mockWorld.setState(scenario.worldState);
    
    // Execute strategic brain tick
    const decisions = await npc.strategicBrain.processStrategicDecisions(worldState);
    
    // Validate decision quality
    const validation = this.validateDecisions(decisions, scenario.expectedOutcomes);
    
    return new TestResult(validation, decisions, scenario);
  }
}
```

### 1.2 Typy Testów AI

#### Unit Tests - Testy Jednostkowe
```typescript
describe('StrategicBrain', () => {
  describe('Goal Management', () => {
    it('should prioritize survival over exploration when health is low', async () => {
      // Arrange
      const npc = await createTestNPC();
      npc.health = 0.1; // 10% health
      const dangerousExplorationGoal = new ExplorationGoal(highRiskLocation);
      const safetyGoal = new SurvivalGoal();
      
      // Act
      npc.strategicBrain.addGoal(dangerousExplorationGoal);
      npc.strategicBrain.addGoal(safetyGoal);
      const prioritizedGoals = await npc.strategicBrain.getPrioritizedGoals();
      
      // Assert
      expect(prioritizedGoals[0]).toBeInstanceOf(SurvivalGoal);
      expect(prioritizedGoals[0].priority).toBeGreaterThan(dangerousExplorationGoal.priority);
    });
    
    it('should adapt goals based on faction relationships', async () => {
      // Test faction-aware goal adaptation
      const npc = await createTestNPC();
      const hostileFaction = await createHostileFaction();
      const friendlyFaction = await createFriendlyFaction();
      
      // Create conflicting faction missions
      const hostileMission = new FactionMission(hostileFaction, MissionType.ATTACK);
      const friendlyMission = new FactionMission(friendlyFaction, MissionType.TRADE);
      
      npc.strategicBrain.addGoal(hostileMission);
      npc.strategicBrain.addGoal(friendlyMission);
      
      const adaptedGoals = await npc.strategicBrain.adaptGoalsToRelationships();
      
      expect(adaptedGoals).not.toContain(hostileMission);
      expect(adaptedGoals).toContain(friendlyMission);
    });
  });
});
```

#### Integration Tests - Testy Integracyjne
```typescript
describe('Dual-Brain Integration', () => {
  it('should synchronize strategic commands with tactical execution', async () => {
    // Create integrated AI system
    const aiSystem = await createDualBrainSystem();
    const npc = await aiSystem.createNPC(standardConfig);
    
    // Issue strategic command
    const strategicCommand = new MovementCommand(targetPosition, urgency.HIGH);
    await npc.strategicBrain.issueCommand(strategicCommand);
    
    // Wait for tactical brain to receive and process
    await waitFor(() => npc.tacticalBrain.hasCommand(strategicCommand.id));
    
    // Check execution status
    const executionStatus = await npc.tacticalBrain.executeCommand(strategicCommand);
    expect(executionStatus.result).toBe(ExecutionResult.SUCCESS);
    
    // Verify position change
    const finalPosition = npc.getPosition();
    expect(finalPosition).toBeCloseTo(targetPosition, POSITION_TOLERANCE);
  });
  
  it('should handle conflicting strategic and tactical priorities', async () => {
    const npc = await createTestNPC();
    
    // Strategic brain wants to go to location A
    const strategicGoal = new MoveToLocationGoal(locationA);
    npc.strategicBrain.addGoal(strategicGoal);
    
    // Tactical brain detects immediate threat requiring escape to location B
    const immediateThreat = new ThreatDetection(enemyNPC, HIGH_DANGER);
    npc.tacticalBrain.detectThreat(immediateThreat);
    
    // Allow conflict resolution
    await npc.resolveConflicts();
    
    // Tactical priority should override strategic
    const finalDecision = await npc.getCurrentDecision();
    expect(finalDecision.type).toBe(DecisionType.AVOID_THREAT);
    expect(finalDecision.targetLocation).toBeCloseTo(locationB);
  });
});
```

#### Behavior Tests - Testy Zachowań
```typescript
describe('NPC Behavior Patterns', () => {
  it('should exhibit realistic patrol patterns', async () => {
    const guard = await createGuardNPC();
    guard.assignPatrolRoute(patrolRoute);
    
    // Run simulation for several patrol cycles
    const positionHistory = [];
    for (let i = 0; i < PATROL_CYCLES; i++) {
      await runSimulation(PATROL_DURATION);
      positionHistory.push(guard.getPosition());
    }
    
    // Validate patrol pattern
    const patternAnalysis = analyzePatrolPattern(positionHistory);
    expect(patternAnalysis.deviation).toBeLessThan(ACCEPTABLE_DEVIATION);
    expect(patternAnalysis.completedCycles).toBe(PATROL_CYCLES);
  });
  
  it('should adapt behavior to zone marking exposure', async () => {
    const stalker = await createStalkerNPC();
    const anomaly = await createTestAnomaly(AnomalyType.PSYCHIC);
    
    // Place stalker near anomaly
    stalker.setPosition(nearAnomalyPosition);
    
    // Run exposure simulation
    await simulateZoneExposure(stalker, anomaly, EXPOSURE_DURATION);
    
    // Check for adaptation markers
    const adaptationLevel = stalker.getZoneAdaptation();
    expect(adaptationLevel).toBeGreaterThan(BASELINE_ADAPTATION);
    
    // Verify changed behavior
    const behaviorChanges = stalker.getBehaviorModifications();
    expect(behaviorChanges).toContain(BehaviorChange.INCREASED_ANOMALY_TOLERANCE);
  });
});
```

### 1.3 Testy Scenariuszowe

```typescript
// Complex scenario testing
class ScenarioTester {
  async testBlowoutResponse(): Promise<TestResult> {
    // Setup: Multiple NPCs in zone, approaching blowout
    const zone = await this.createTestZone();
    const npcs = await this.spawnMultipleNPCs(zone, 5);
    
    // Trigger blowout
    const blowout = new BlowoutEvent(zone.center, HIGH_INTENSITY);
    zone.triggerBlowout(blowout);
    
    // Observe responses
    const responses = await this.observeNPCResponses(npcs, blowout);
    
    // Analyze behavior
    const analysis = this.analyzeBlowoutResponse(responses);
    
    return {
      scenario: 'Blowout Response',
      npcsSurvived: analysis.survivorCount,
      averageReactionTime: analysis.averageReactionTime,
      behaviorConsistency: analysis.behaviorConsistency,
      pathfindingEfficiency: analysis.pathfindingQuality
    };
  }
  
  async testFactionalConflict(): Promise<TestResult> {
    // Setup opposing factions
    const factionA = await this.createFaction(FactionType.STALKERS);
    const factionB = await this.createFaction(FactionType.BANDITS);
    
    // Create territorial overlap
    const disputedTerritory = new Territory(contestedArea);
    factionA.claimTerritory(disputedTerritory);
    factionB.claimTerritory(disputedTerritory);
    
    // Run conflict simulation
    await this.simulateConflict(factionA, factionB, CONFLICT_DURATION);
    
    // Analyze outcomes
    return this.analyzeConflictOutcome(factionA, factionB);
  }
}
```

## 2. Metryki Wydajności i Benchmarki

### 2.1 Kluczowe Metryki AI

```typescript
interface AIPerformanceMetrics {
  // Strategic Brain Metrics
  strategicBrain: {
    avgDecisionTime: number;    // < 5ms target
    peakDecisionTime: number;   // < 20ms target
    decisionQuality: number;    // 0-1 scale
    goalCompletionRate: number; // 0-1 scale
    memoryUtilization: number;  // MB
  };
  
  // Tactical Brain Metrics
  tacticalBrain: {
    avgFrameTime: number;       // < 0.1ms target for LOD0
    pathfindingTime: number;    // < 2ms target
    perceptionAccuracy: number; // 0-1 scale
    reactionTime: number;       // < 100ms target
  };
  
  // LOD System Metrics
  lodSystem: {
    transitionFrequency: number;    // per second
    transitionsSmoothness: number;  // 0-1 scale
    resourceSavings: number;        // % CPU saved
    qualityDegradation: number;     // 0-1 scale
  };
  
  // Memory Metrics
  memory: {
    totalAIMemory: number;      // MB
    avgNPCMemory: number;       // KB
    memoryLeakRate: number;     // MB/hour
    gcFrequency: number;        // per minute
  };
  
  // Threading Metrics
  threading: {
    threadUtilization: Map<ThreadType, number>; // 0-1 scale
    threadBalance: number;      // variance between threads
    syncOverhead: number;       // % of time spent synchronizing
  };
}
```

### 2.2 Benchmarki Wydajnościowe

```typescript
// Performance benchmark suite
class AIPerformanceBenchmarks {
  async runFullBenchmark(): Promise<BenchmarkResults> {
    const results = new BenchmarkResults();
    
    // Strategic Brain Benchmarks
    results.strategic = await this.benchmarkStrategicBrain();
    
    // Tactical Brain Benchmarks
    results.tactical = await this.benchmarkTacticalBrain();
    
    // LOD System Benchmarks
    results.lod = await this.benchmarkLODSystem();
    
    // Integrated System Benchmarks
    results.integration = await this.benchmarkIntegratedSystem();
    
    return results;
  }
  
  private async benchmarkStrategicBrain(): Promise<StrategicBenchmark> {
    return {
      singleNPCDecisionTime: await this.measureSingleDecision(),
      massNPCDecisionTime: await this.measureMassDecisions(100),
      memoryScalingTest: await this.testMemoryScaling(),
      goalComplexityImpact: await this.testGoalComplexity()
    };
  }
  
  // Example benchmark: Strategic decision scaling
  private async measureMassDecisions(npcCount: number): Promise<ScalingResult> {
    const results = [];
    
    for (let count = 1; count <= npcCount; count *= 2) {
      const npcs = await this.createTestNPCs(count);
      const startTime = performance.now();
      
      // Process all strategic brains
      await Promise.all(npcs.map(npc => 
        npc.strategicBrain.processStrategicDecisions(mockWorldState)
      ));
      
      const endTime = performance.now();
      results.push({
        npcCount: count,
        totalTime: endTime - startTime,
        avgTimePerNPC: (endTime - startTime) / count
      });
    }
    
    return new ScalingResult(results);
  }
}
```

### 2.3 System Profilowania

```typescript
// Detailed profiling system
class AIProfiler {
  private recordings: Map<string, ProfileRecording> = new Map();
  
  startProfiling(npcId: string, sessions: ProfilingSession[]): void {
    const recording = new ProfileRecording(npcId);
    
    for (const session of sessions) {
      switch (session.type) {
        case 'decision-tree':
          recording.addHook('decision', this.profileDecisions);
          break;
        case 'memory-access':
          recording.addHook('memory', this.profileMemoryAccess);
          break;
        case 'pathfinding':
          recording.addHook('pathfinding', this.profilePathfinding);
          break;
      }
    }
    
    this.recordings.set(npcId, recording);
  }
  
  private profileDecisions = (decision: AIDecision): void => {
    const profile = {
      timestamp: performance.now(),
      decisionType: decision.type,
      duration: decision.processingTime,
      complexity: decision.complexity,
      alternatives: decision.alternatives.length,
      utilityScores: decision.utilityScores
    };
    
    this.recordings.get(decision.npcId)?.addDataPoint('decision', profile);
  };
  
  // Generate comprehensive profile report
  generateReport(npcId: string): ProfileReport {
    const recording = this.recordings.get(npcId);
    if (!recording) throw new Error(`No recording for NPC ${npcId}`);
    
    return {
      summary: this.generateSummary(recording),
      decisionAnalysis: this.analyzeDecisions(recording),
      performanceBottlenecks: this.identifyBottlenecks(recording),
      recommendations: this.generateOptimizationRecommendations(recording)
    };
  }
}
```

## 3. Narzędzia Deweloperskie

### 3.1 AI Debugger

```typescript
// Advanced AI debugging interface
class AIDebugger {
  private debugVisualization: DebugRenderer;
  private stateInspector: StateInspector;
  private commandHistory: CommandHistory;
  
  // Real-time visualization of AI states
  visualizeAIState(npcId: string): DebugVisualization {
    const npc = this.getNPC(npcId);
    
    return {
      strategicVisualization: this.visualizeStrategicBrain(npc),
      tacticalVisualization: this.visualizeTacticalBrain(npc),
      memoryVisualization: this.visualizeMemoryState(npc),
      goalHierarchy: this.visualizeGoalHierarchy(npc),
      decisionTree: this.visualizeDecisionProcess(npc)
    };
  }
  
  // Strategic brain visualization
  private visualizeStrategicBrain(npc: NPC): StrategicVisualization {
    return {
      currentGoals: npc.strategicBrain.getActiveGoals(),
      goalPriorities: npc.strategicBrain.getGoalPriorities(),
      worldKnowledge: npc.strategicBrain.getWorldKnowledge(),
      relationships: npc.strategicBrain.getRelationships(),
      planningHorizon: npc.strategicBrain.getPlanningData(),
      debugAnnotations: this.generateStrategicAnnotations(npc)
    };
  }
  
  // Interactive debugging commands
  injectCommand(npcId: string, command: DebugCommand): CommandResult {
    const npc = this.getNPC(npcId);
    
    switch (command.type) {
      case 'FORCE_GOAL':
        return this.forceGoal(npc, command.data);
      case 'SIMULATE_THREAT':
        return this.simulateThreat(npc, command.data);
      case 'MODIFY_RELATIONSHIP':
        return this.modifyRelationship(npc, command.data);
      case 'TELEPORT':
        return this.teleportNPC(npc, command.data);
      case 'SET_HEALTH':
        return this.setHealth(npc, command.data);
    }
  }
  
  // Step-by-step execution
  enableStepMode(npcId: string): StepModeController {
    const npc = this.getNPC(npcId);
    const controller = new StepModeController(npc);
    
    controller.pauseAI();
    controller.provideStepping({
      stepStrategic: () => npc.strategicBrain.executeStep(),
      stepTactical: () => npc.tacticalBrain.executeStep(),
      stepFull: () => npc.executeStep(),
      skipToNextDecision: () => controller.skipToNextDecision()
    });
    
    return controller;
  }
}
```

### 3.2 Performance Monitor

```typescript
// Real-time performance monitoring
class PerformanceMonitor {
  private metrics: MetricsCollector;
  private alerts: AlertSystem;
  private visualization: PerformanceVisualization;
  
  startMonitoring(): void {
    // Start collecting metrics
    this.metrics.startCollection({
      interval: 100, // 100ms
      metrics: [
        'ai.frame_time',
        'ai.decision_time',
        'ai.memory_usage',
        'ai.thread_utilization'
      ]
    });
    
    // Setup real-time alerts
    this.alerts.configure([
      {
        metric: 'ai.frame_time',
        threshold: 16.67, // >60fps
        action: AlertAction.LOG_WARNING
      },
      {
        metric: 'ai.memory_usage',
        threshold: 1024, // 1GB
        action: AlertAction.TRIGGER_GC
      }
    ]);
  }
  
  // Performance dashboard
  getDashboard(): PerformanceDashboard {
    return {
      currentMetrics: this.metrics.getCurrent(),
      historicalTrends: this.metrics.getTrends(),
      aiDistribution: this.metrics.getAIDistribution(),
      bottleneckAnalysis: this.identifyBottlenecks(),
      optimizationSuggestions: this.generateSuggestions()
    };
  }
  
  // Automated optimization
  autoOptimize(): OptimizationResult {
    const currentPerformance = this.assessPerformance();
    
    if (currentPerformance.frameTime > TARGET_FRAME_TIME) {
      return this.optimizeFrameTime();
    }
    
    if (currentPerformance.memoryUsage > MEMORY_THRESHOLD) {
      return this.optimizeMemoryUsage();
    }
    
    return OptimizationResult.noActionNeeded();
  }
}
```

### 3.3 AI Scenario Editor

```typescript
// Tool for creating and editing AI test scenarios
class AIScenarioEditor {
  private scenarios: Map<string, TestScenario> = new Map();
  private templates: ScenarioTemplate[] = [];
  
  createScenario(config: ScenarioConfig): TestScenario {
    const scenario = new TestScenario({
      name: config.name,
      description: config.description,
      initialState: this.setupInitialState(config.worldState),
      npcs: this.createNPCs(config.npcConfigs),
      objectives: this.defineObjectives(config.objectives),
      timeLimit: config.timeLimit || INFINITE_TIME,
      validations: this.setupValidations(config.expectations)
    });
    
    this.scenarios.set(scenario.id, scenario);
    return scenario;
  }
  
  // Visual scenario builder
  openVisualEditor(scenarioId?: string): ScenarioEditorUI {
    const ui = new ScenarioEditorUI();
    
    ui.addComponents([
      new WorldStateEditor(),
      new NPCPlacer(),
      new ObjectiveDefiner(),
      new ValidationRuleBuilder(),
      new ScenarioRunner()
    ]);
    
    if (scenarioId) {
      ui.loadScenario(this.scenarios.get(scenarioId));
    }
    
    return ui;
  }
  
  // Scenario templates
  createFromTemplate(templateName: string, params: TemplateParams): TestScenario {
    const template = this.templates.find(t => t.name === templateName);
    if (!template) throw new Error(`Template ${templateName} not found`);
    
    return template.instantiate(params);
  }
}
```

## 4. Procedury Zapewniania Jakości

### 4.1 Code Review Checklist dla AI

```markdown
# AI Code Review Checklist

## Performance ✅
- [ ] Strategic brain operations complete within 5ms budget
- [ ] Tactical brain operations complete within 0.1ms budget
- [ ] Memory allocations are minimized and cleaned up
- [ ] LOD transitions are smooth and don't cause hitches
- [ ] Thread synchronization is minimal and efficient

## Correctness ✅
- [ ] Decision logic is sound and tested
- [ ] Edge cases are handled (empty world, no valid paths, etc.)
- [ ] State synchronization between brains is correct
- [ ] Memory consistency is maintained
- [ ] Goal priorities are correctly calculated

## Maintainability ✅
- [ ] Code follows established AI patterns
- [ ] Complex behaviors are well-documented
- [ ] Debug information is comprehensive
- [ ] Test coverage is adequate (>80%)
- [ ] Performance characteristics are documented
```

### 4.2 AI Testing Pipeline

```typescript
// Automated testing pipeline for AI changes
class AITestingPipeline {
  async runFullPipeline(changes: CodeChanges): Promise<PipelineResult> {
    const results = new PipelineResult();
    
    // 1. Unit Tests
    results.unitTests = await this.runUnitTests(changes);
    if (!results.unitTests.passed) return results;
    
    // 2. Integration Tests
    results.integrationTests = await this.runIntegrationTests(changes);
    if (!results.integrationTests.passed) return results;
    
    // 3. Performance Benchmarks
    results.performance = await this.runPerformanceBenchmarks();
    if (!results.performance.metTarget) return results;
    
    // 4. Behavior Validation
    results.behavior = await this.runBehaviorTests();
    if (!results.behavior.passed) return results;
    
    // 5. Scenario Tests
    results.scenarios = await this.runScenarioTests();
    
    return results;
  }
  
  // Custom AI assertions
  private async validateAIBehavior(behavior: ObservedBehavior, expected: ExpectedBehavior): Promise<ValidationResult> {
    return {
      decisions: this.validateDecisions(behavior.decisions, expected.decisions),
      performance: this.validatePerformance(behavior.performance, expected.performance),
      emergent: this.validateEmergentBehaviors(behavior.emergent, expected.emergent)
    };
  }
}
```

### 4.3 Performance Regression Detection

```typescript
class PerformanceRegressionDetector {
  private baseline: PerformanceBaseline;
  private thresholds: RegressionThresholds;
  
  checkForRegressions(current: PerformanceMetrics): RegressionReport {
    const regressions = [];
    
    // Check key metrics
    if (current.avgFrameTime > this.baseline.avgFrameTime * this.thresholds.frameTime) {
      regressions.push({
        metric: 'Frame Time',
        baseline: this.baseline.avgFrameTime,
        current: current.avgFrameTime,
        regression: this.calculateRegression(current.avgFrameTime, this.baseline.avgFrameTime),
        severity: this.assessSeverity('frame_time', current.avgFrameTime)
      });
    }
    
    // Check memory usage
    if (current.memoryUsage > this.baseline.memoryUsage * this.thresholds.memory) {
      regressions.push({
        metric: 'Memory Usage',
        baseline: this.baseline.memoryUsage,
        current: current.memoryUsage,
        regression: this.calculateRegression(current.memoryUsage, this.baseline.memoryUsage),
        severity: this.assessSeverity('memory', current.memoryUsage)
      });
    }
    
    return new RegressionReport(regressions);
  }
  
  // Automated baseline management
  updateBaseline(metrics: PerformanceMetrics): void {
    // Only update if performance improved
    if (this.isImprovement(metrics, this.baseline)) {
      this.baseline = metrics;
      this.persistBaseline();
    }
  }
}
```

## 5. Przewodniki dla Deweloperów

### 5.1 Quick Start Guide dla AI Developerów

```markdown
# AI Developer Quick Start Guide

## 1. Środowiska Development
```bash
# Setup development environment
git clone https://github.com/cien-podroznika/ai-systems
cd ai-systems
npm install

# Run tests
npm run test:ai
npm run test:performance

# Start debug server
npm run dev:debug
```

## 2. Podstawowe Patterns
```typescript
// Always extend from base AI classes
class MyCustomBrain extends StrategicBrain {
  async processDecisions(worldState: WorldState): Promise<Decision[]> {
    // Your custom logic here
    return super.processDecisions(worldState);
  }
}

// Use factories for creating AI components
const brain = AIFactory.createStrategicBrain({
  type: 'CustomBrain',
  parameters: config
});
```

## 3. Debugging Best Practices
- Always add debug visualization for new behaviors
- Use performance markers for critical sections
- Log decisions with sufficient context
- Test with various NPC configurations

## 4. Performance Guidelines
- Budget: Strategic brain < 5ms, Tactical brain < 0.1ms per frame
- Memory: Keep NPC memory under 2KB average
- LOD: Implement graceful degradation for all systems
```

### 5.2 Troubleshooting Guide

```typescript
// Common AI issues and solutions
class AITroubleshootingGuide {
  static commonIssues = {
    'npc-not-moving': {
      symptoms: 'NPC stands still despite having goals',
      possibleCauses: [
        'Pathfinding blocked',
        'No valid path to target',
        'Conflicting goals',
        'Strategic-tactical sync error'
      ],
      debugSteps: [
        'Check pathfinding visualization',
        'Inspect goal priorities',
        'Verify command synchronization',
        'Check for blocking anomalies'
      ],
      solutions: [
        'Clear pathfinding cache',
        'Adjust goal priorities',
        'Force tactical brain sync',
        'Update obstacle detection'
      ]
    },
    
    'performance-drops': {
      symptoms: 'Frame rate drops when many NPCs active',
      possibleCauses: [
        'Too many NPCs in LOD 0',
        'Inefficient pathfinding',
        'Memory leaks',
        'Synchronization overhead'
      ],
      debugSteps: [
        'Check LOD distribution',
        'Profile pathfinding calls',
        'Monitor memory usage',
        'Analyze thread utilization'
      ],
      solutions: [
        'Adjust LOD distances',
        'Implement path caching',
        'Fix memory leaks',
        'Optimize synchronization'
      ]
    }
  };
}
```

## 6. Praktyczne Przykłady

### 6.1 Implementacja Nowego Zachowania AI

```typescript
// Example: Implementing a new patrol behavior
class PatrolBehavior extends AIBehavior {
  private waypoints: Vector3[];
  private currentWaypoint: number = 0;
  private patrolSpeed: number;
  
  constructor(waypoints: Vector3[], speed: number = 1.0) {
    super('PatrolBehavior');
    this.waypoints = waypoints;
    this.patrolSpeed = speed;
  }
  
  // Strategic layer - decide whether to patrol
  async evaluateStrategic(npc: NPC, worldState: WorldState): Promise<number> {
    // Don't patrol if injured or in combat
    if (npc.health < 0.5 || npc.isInCombat()) {
      return 0.0;
    }
    
    // Higher priority if assigned to this patrol route
    return npc.hasRole('Guard') ? 0.8 : 0.3;
  }
  
  // Tactical layer - execute patrol movement
  async executeTactical(npc: NPC, deltaTime: number): Promise<void> {
    const targetWaypoint = this.waypoints[this.currentWaypoint];
    const distanceToWaypoint = npc.position.distanceTo(targetWaypoint);
    
    if (distanceToWaypoint < WAYPOINT_THRESHOLD) {
      this.currentWaypoint = (this.currentWaypoint + 1) % this.waypoints.length;
    }
    
    // Move towards current waypoint
    await npc.moveTowards(targetWaypoint, this.patrolSpeed);
  }
  
  // Debug visualization
  renderDebug(renderer: DebugRenderer): void {
    // Draw patrol route
    renderer.drawPath(this.waypoints, Color.BLUE);
    
    // Highlight current target
    renderer.drawSphere(this.waypoints[this.currentWaypoint], 0.5, Color.GREEN);
  }
}
```

### 6.2 Implementacja Testów dla Nowego Zachowania

```typescript
describe('PatrolBehavior', () => {
  it('should complete patrol route', async () => {
    // Setup test environment
    const waypoints = [
      new Vector3(0, 0, 0),
      new Vector3(10, 0, 0),
      new Vector3(10, 0, 10),
      new Vector3(0, 0, 10)
    ];
    
    const npc = await createTestNPC();
    const behavior = new PatrolBehavior(waypoints);
    npc.addBehavior(behavior);
    
    // Run simulation
    const positions = [];
    for (let i = 0; i < SIMULATION_STEPS; i++) {
      await runSimulationStep(npc, STEP_DURATION);
      if (i % 10 === 0) {
        positions.push(npc.position.clone());
      }
    }
    
    // Verify patrol completion
    const visitedWaypoints = this.checkWaypointVisitation(positions, waypoints);
    expect(visitedWaypoints.length).toBe(waypoints.length);
    
    // Verify route order
    expect(this.isSequentialVisitation(visitedWaypoints)).toBe(true);
  });
  
  it('should interrupt patrol for combat', async () => {
    const npc = await createTestNPC();
    const enemy = await createEnemyNPC();
    const behavior = new PatrolBehavior(standardPatrolRoute);
    
    npc.addBehavior(behavior);
    
    // Start patrol
    await runSimulation(npc, PATROL_START_TIME);
    expect(npc.getCurrentBehavior()).toBe(behavior);
    
    // Introduce enemy
    enemy.setPosition(npc.position.add(new Vector3(5, 0, 0)));
    npc.perceive(enemy);
    
    // Check behavior switch
    await runSimulation(npc, COMBAT_DETECTION_TIME);
    expect(npc.getCurrentBehavior().type).toBe('CombatBehavior');
  });
});
```

## 7. Automatyzacja i CI/CD

### 7.1 Automated AI Testing

```yaml
# .github/workflows/ai-tests.yml
name: AI Systems Testing

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  ai-tests:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Run AI unit tests
      run: npm run test:ai:unit
    
    - name: Run AI integration tests
      run: npm run test:ai:integration
    
    - name: Run performance benchmarks
      run: npm run benchmark:ai
    
    - name: Generate performance report
      run: npm run report:performance
    
    - name: Upload test results
      uses: actions/upload-artifact@v3
      with:
        name: test-results
        path: |
          coverage/
          reports/
```

### 7.2 Performance Monitoring Integration

```typescript
// Integration with monitoring services
class PerformanceTracker {
  // Send metrics to monitoring service
  async trackMetrics(metrics: AIMetrics): Promise<void> {
    await Promise.all([
      this.sendToDatadog(metrics),
      this.sendToPrometheus(metrics),
      this.updateDashboard(metrics)
    ]);
  }
  
  // Automated alerting
  private async checkThresholds(metrics: AIMetrics): Promise<void> {
    const violations = this.identifyViolations(metrics);
    
    for (const violation of violations) {
      await this.sendAlert({
        severity: violation.severity,
        metric: violation.metric,
        current: violation.current,
        threshold: violation.threshold,
        recommendations: violation.recommendations
      });
    }
  }
}
```

## Podsumowanie

Ten przewodnik zapewnia kompleksowe podejście do testowania i rozwijania systemów AI w "Cieniu Podróżnika":

1. **Wielopoziomowe testowanie** - od jednostkowych po scenariuszowe
2. **Dokładne metryki** - konkretne benchmarki i cele wydajności
3. **Zaawansowane narzędzia** - debugowanie, profilowanie, monitoring
4. **Procedury jakości** - review, regression detection, CI/CD
5. **Praktyczne przykłady** - gotowe do implementacji rozwiązania

Wszystkie narzędzia i procedury są zaprojektowane tak, aby wspierać iteracyjny rozwój złożonych systemów AI przy zachowaniu wysokiej jakości i wydajności.

---

> **Next Steps**: Implementacja narzędzi deweloperskich powinna rozpocząć się od podstawowych функцjonalności debugowania, następnie rozszerzenie o automated testing i monitoring systemy.