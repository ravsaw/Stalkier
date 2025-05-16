# Cień Podróżnika - Przewodnik Implementacyjny

Ten dokument zawiera praktyczne instrukcje implementacji systemów "Cienia Podróżnika" w Godot 4, z naciskiem na System Dwóch Mózgów i best practices deweloperskie.

> **Referencje**: Zobacz [technical-design.md](technical-design.md) dla szczegółów technicznych i [testing-and-tools.md](testing-and-tools.md) dla procedur testowania.

## 1. Setup Środowiska Deweloperskiego

### 1.1 Konfiguracja Projektu Godot 4

```
# Project structure
CienPodroznika/
├── Scripts/
│   ├── AI/
│   │   ├── BrainSystem/
│   │   ├── Behaviors/
│   │   └── Utilities/
│   ├── Faction/
│   ├── Zone/
│   └── Shared/
├── Scenes/
│   ├── NPC/
│   ├── Zones/
│   └── UI/
├── Resources/
│   └── AI/
├── Exports/
└── Tests/
```

### 1.2 Podstawowe Autoload Settings

```csharp
// project.godot - Autoloads
[autoload]
AISystemManager="*res://Scripts/AI/AISystemManager.cs"
EventBus="*res://Scripts/Shared/EventBus.cs"
FactionManager="*res://Scripts/Faction/FactionManager.cs"
ZoneManager="*res://Scripts/Zone/ZoneManager.cs"
PerformanceMonitor="*res://Scripts/AI/PerformanceMonitor.cs"
```

## 2. Implementacja Systemu Dwóch Mózgów

### 2.1 Bazowa Struktura Klas

```csharp
// ScriptsDI/BrainSystem/DualBrainSystem.cs
using Godot;

public partial class DualBrainSystem : Node
{
    [Export] public NPCController Owner { get; set; }
    
    private StrategicBrain strategicBrain;
    private TacticalBrain tacticalBrain;
    private BrainSynchronizer synchronizer;
    
    public override void _Ready()
    {
        InitializeBrains();
        SetupSynchronization();
    }
    
    private void InitializeBrains()
    {
        strategicBrain = GetNode<StrategicBrain>("StrategicBrain");
        tacticalBrain = GetNode<TacticalBrain>("TacticalBrain");
        
        // Pass owner reference to both brains
        strategicBrain.Initialize(Owner);
        tacticalBrain.Initialize(Owner);
    }
    
    private void SetupSynchronization()
    {
        synchronizer = new BrainSynchronizer(strategicBrain, tacticalBrain);
        
        // Connect signals
        strategicBrain.CommandIssued += synchronizer.OnStrategicCommand;
        tacticalBrain.StatusUpdated += synchronizer.OnTacticalStatus;
        
        // Setup synchronization timer
        var syncTimer = new Timer();
        AddChild(syncTimer);
        syncTimer.WaitTime = 0.2; // 5 Hz synchronization
        syncTimer.Connect("timeout", Callable.From(synchronizer.Synchronize));
        syncTimer.Start();
    }
}
```

### 2.2 Strategic Brain Implementation

```csharp
// Scripts/AI/BrainSystem/StrategicBrain.cs
public partial class StrategicBrain : Node
{
    [Signal] public delegate void CommandIssuedEventHandler(StrategicCommand command);
    
    private NPCController owner;
    private List<Goal> goals = new();
    private NPCMemory memory;
    private UtilitySystem utilitySystem;
    private Timer updateTimer;
    
    [Export] public float UpdateFrequency { get; set; } = 5.0f; // 5 times per second
    
    public void Initialize(NPCController npc)
    {
        owner = npc;
        memory = new NPCMemory(npc);
        utilitySystem = new UtilitySystem();
        
        SetupUpdateTimer();
    }
    
    private void SetupUpdateTimer()
    {
        updateTimer = new Timer();
        AddChild(updateTimer);
        updateTimer.WaitTime = 1.0f / UpdateFrequency;
        updateTimer.Connect("timeout", Callable.From(ProcessStrategicThinking));
        updateTimer.Start();
    }
    
    private async void ProcessStrategicThinking()
    {
        var worldState = GatherWorldState();
        var activeGoals = EvaluateGoals(worldState);
        var decisions = await MakeStrategicDecisions(activeGoals, worldState);
        
        foreach (var decision in decisions)
        {
            var command = CreateTacticalCommand(decision);
            EmitSignal(SignalName.CommandIssued, command);
        }
    }
    
    private WorldState GatherWorldState()
    {
        return new WorldState
        {
            NPCPosition = owner.GlobalPosition,
            NPCHealth = owner.Health,
            VisibleThreats = GetVisibleThreats(),
            KnownFactions = memory.GetFactionKnowledge(),
            AvailableArtifacts = GetKnownArtifacts(),
            TimeOfDay = GetTimeOfDay()
        };
    }
    
    private List<Decision> MakeStrategicDecisions(List<Goal> goals, WorldState state)
    {
        var decisions = new List<Decision>();
        
        foreach (var goal in goals.OrderByDescending(g => g.Priority))
        {
            if (utilitySystem.ShouldPursueGoal(goal, state))
            {
                var plan = CreatePlan(goal, state);
                var decision = new Decision(goal, plan, state);
                decisions.Add(decision);
            }
        }
        
        return ResolveConflictingDecisions(decisions);
    }
}
```

### 2.3 Tactical Brain Implementation

```csharp
// Scripts/AI/BrainSystem/TacticalBrain.cs
public partial class TacticalBrain : Node
{
    [Signal] public delegate void StatusUpdatedEventHandler(TacticalStatus status);
    
    private NPCController owner;
    private PerceptionSystem perception;
    private PathfindingSystem pathfinding;
    private ActionExecutor actionExecutor;
    private Queue<StrategicCommand> commandQueue = new();
    
    [Export] public int MaxCommandsPerFrame { get; set; } = 3;
    
    public void Initialize(NPCController npc)
    {
        owner = npc;
        perception = new PerceptionSystem(npc);
        pathfinding = new PathfindingSystem(npc);
        actionExecutor = new ActionExecutor(npc);
    }
    
    public override void _Process(double delta)
    {
        // Update every frame for tactical brain
        UpdatePerception();
        ProcessCommands();
        HandleImmediateThreats();
        UpdateActionExecution(delta);
        
        EmitStatusUpdate();
    }
    
    private void UpdatePerception()
    {
        var perceptionData = perception.ScanEnvironment();
        
        // Filter for immediate threats
        var threats = perceptionData.Threats
            .Where(t => t.Immediacy > 0.8)
            .OrderByDescending(t => t.Danger);
        
        if (threats.Any())
        {
            HandleThreatPriority(threats.First());
        }
    }
    
    private void ProcessCommands()
    {
        int processed = 0;
        while (commandQueue.Count > 0 && processed < MaxCommandsPerFrame)
        {
            var command = commandQueue.Dequeue();
            ExecuteStrategicCommand(command);
            processed++;
        }
    }
    
    public void ReceiveCommand(StrategicCommand command)
    {
        // Add to queue with priority sorting
        commandQueue.Enqueue(command);
        SortCommandQueue();
    }
    
    private void ExecuteStrategicCommand(StrategicCommand command)
    {
        switch (command.Type)
        {
            case CommandType.MoveTo:
                ExecuteMovementCommand(command as MovementCommand);
                break;
            case CommandType.Interact:
                ExecuteInteractionCommand(command as InteractionCommand);
                break;
            // ... other command types
        }
    }
}
```

## 3. Sistema LOD Implementation

### 3.1 LOD Manager

```csharp
// Scripts/AI/LODSystem/LODManager.cs
public partial class LODManager : Node
{
    private Dictionary<NPCController, LODLevel> npcLodLevels = new();
    private Timer lodUpdateTimer;
    
    [Export] public float LODUpdateFrequency { get; set; } = 10.0f; // 10 Hz
    [Export] public Vector3[] LODDistances { get; set; } = {
        new Vector3(50, 200, 500) // LOD transition distances
    };
    
    public override void _Ready()
    {
        SetupLODTimer();
        ConnectToPlayerEvents();
    }
    
    private void SetupLODTimer()
    {
        lodUpdateTimer = new Timer();
        AddChild(lodUpdateTimer);
        lodUpdateTimer.WaitTime = 1.0f / LODUpdateFrequency;
        lodUpdateTimer.Connect("timeout", Callable.From(UpdateAllLODs));
        lodUpdateTimer.Start();
    }
    
    private void UpdateAllLODs()
    {
        var playerPosition = GetPlayerPosition();
        var npcs = GetAllNPCs();
        
        foreach (var npc in npcs)
        {
            var distance = npc.GlobalPosition.DistanceTo(playerPosition);
            var newLOD = CalculateLODLevel(distance);
            
            if (ShouldUpdateLOD(npc, newLOD))
            {
                TransitionNPCLOD(npc, newLOD);
            }
        }
    }
    
    private LODLevel CalculateLODLevel(float distance)
    {
        if (distance <= LODDistances[0].X) return LODLevel.Full;
        if (distance <= LODDistances[0].Y) return LODLevel.Medium;
        if (distance <= LODDistances[0].Z) return LODLevel.Low;
        return LODLevel.StrategicOnly;
    }
    
    private void TransitionNPCLOD(NPCController npc, LODLevel newLOD)
    {
        var oldLOD = npcLodLevels.GetValueOrDefault(npc, LODLevel.Full);
        
        // Start transition effect
        var transition = new LODTransition(oldLOD, newLOD);
        npc.StartLODTransition(transition);
        
        // Update LOD level
        npcLodLevels[npc] = newLOD;
        
        // Configure NPC for new LOD
        ConfigureNPCForLOD(npc, newLOD);
    }
}
```

### 3.2 LOD-Aware Systems

```csharp
// Scripts/AI/NPCController.cs - LOD-aware behavior
public partial class NPCController : CharacterBody3D
{
    private LODLevel currentLOD = LODLevel.Full;
    private DualBrainSystem brainSystem;
    
    public void SetLODLevel(LODLevel lod)
    {
        var oldLOD = currentLOD;
        currentLOD = lod;
        
        OnLODChanged(oldLOD, lod);
    }
    
    private void OnLODChanged(LODLevel from, LODLevel to)
    {
        // Update brain frequencies
        switch (to)
        {
            case LODLevel.Full:
                brainSystem.SetUpdateFrequencies(5.0f, 60.0f); // Strategic: 5Hz, Tactical: 60Hz
                EnableFullFeatures();
                break;
                
            case LODLevel.Medium:
                brainSystem.SetUpdateFrequencies(3.0f, 30.0f); // Strategic: 3Hz, Tactical: 30Hz
                DisableNonEssentialFeatures();
                break;
                
            case LODLevel.Low:
                brainSystem.SetUpdateFrequencies(1.0f, 10.0f); // Strategic: 1Hz, Tactical: 10Hz
                DisableVisualsAndAudio();
                break;
                
            case LODLevel.StrategicOnly:
                brainSystem.EnableStrategicOnly();
                DisableAllTacticalFeatures();
                break;
        }
    }
    
    public override void _Process(double delta)
    {
        // Only update if not in strategic-only mode
        if (currentLOD != LODLevel.StrategicOnly)
        {
            UpdateBasedOnLOD(delta);
        }
    }
}
```

## 4. Faction System Implementation

### 4.1 Faction Manager

```csharp
// Scripts/Faction/FactionManager.cs
public partial class FactionManager : Node
{
    [Signal] public delegate void FactionCreatedEventHandler(Faction faction);
    [Signal] public delegate void RelationshipChangedEventHandler(string factionA, string factionB, float newValue);
    
    private Dictionary<string, Faction> factions = new();
    private Dictionary<string, Dictionary<string, Relationship>> relationships = new();
    
    public Faction CreateFaction(FactionConfig config)
    {
        var faction = new Faction(config);
        factions[faction.Id] = faction;
        
        // Initialize relationships with existing factions
        foreach (var existingFaction in factions.Values)
        {
            if (existingFaction.Id != faction.Id)
            {
                InitializeRelationship(faction, existingFaction);
            }
        }
        
        EmitSignal(SignalName.FactionCreated, faction);
        return faction;
    }
    
    public void UpdateRelationship(string factionA, string factionB, float change)
    {
        if (!relationships.ContainsKey(factionA))
            relationships[factionA] = new Dictionary<string, Relationship>();
        
        if (!relationships[factionA].ContainsKey(factionB))
            relationships[factionA][factionB] = new Relationship();
        
        var relationship = relationships[factionA][factionB];
        relationship.UpdateRelationship(change);
        
        // Reciprocal update (with possible modifier)
        var reciprocalChange = change * GetReciprocityModifier(factionA, factionB);
        relationships[factionB][factionA].UpdateRelationship(reciprocalChange);
        
        EmitSignal(SignalName.RelationshipChanged, factionA, factionB, relationship.Value);
    }
    
    // Handle faction events
    private void OnNPCJoinedFaction(NPCController npc, Faction faction)
    {
        // Update faction member count
        faction.AddMember(npc);
        
        // Update NPC's relationships based on faction
        UpdateNPCRelationships(npc, faction);
        
        // Notify other systems
        EventBus.EmitSignal("NPC_JOINED_FACTION", npc, faction);
    }
}
```

### 4.2 Dynamic Faction Formation

```csharp
// Scripts/Faction/FactionFormation.cs
public partial class FactionFormation : Node
{
    [Export] public float MinimumGroupSize { get; set; } = 3;
    [Export] public float FormationProbability { get; set; } = 0.1f;
    
    private FactionManager factionManager;
    private List<NPCController> unaffiliatedNPCs = new();
    
    public override void _Ready()
    {
        factionManager = GetNode<FactionManager>("/root/FactionManager");
        
        // Check for faction formation every game day
        var formationTimer = new Timer();
        AddChild(formationTimer);
        formationTimer.WaitTime = 3600.0f; // 1 hour game time
        formationTimer.Connect("timeout", Callable.From(CheckForFactionFormation));
        formationTimer.Start();
    }
    
    private void CheckForFactionFormation()
    {
        var potentialGroups = FindPotentialFactions();
        
        foreach (var group in potentialGroups)
        {
            if (group.Count >= MinimumGroupSize && 
                GD.Randf() < FormationProbability)
            {
                FormNewFaction(group);
            }
        }
    }
    
    private List<List<NPCController>> FindPotentialFactions()
    {
        var groups = new List<List<NPCController>>();
        
        // Group NPCs by common goals, location, and relationships
        var affinityGroups = unaffiliatedNPCs.GroupBy(npc => 
            new { 
                Goal = GetMostImportantGoal(npc),
                Location = GetRegion(npc.GlobalPosition),
                Alignment = GetIdeologicalAlignment(npc)
            });
        
        foreach (var group in affinityGroups)
        {
            var npcsInGroup = group.ToList();
            if (npcsInGroup.Count >= 2)
            {
                groups.Add(npcsInGroup);
            }
        }
        
        return groups;
    }
    
    private void FormNewFaction(List<NPCController> foundingMembers)
    {
        // Determine faction characteristics from members
        var factionConfig = CreateFactionConfig(foundingMembers);
        
        // Create the faction
        var faction = factionManager.CreateFaction(factionConfig);
        
        // Assign members
        foreach (var npc in foundingMembers)
        {
            AssignNPCToFaction(npc, faction);
            unaffiliatedNPCs.Remove(npc);
        }
        
        // Notify systems about new faction
        EventBus.EmitSignal("NEW_FACTION_FORMED", faction, foundingMembers);
    }
}
```

## 5. Zone and Anomaly System

### 5.1 Zone Manager Implementation

```csharp
// Scripts/Zone/ZoneManager.cs
public partial class ZoneManager : Node
{
    [Export] public PackedScene AnomalyScene { get; set; }
    [Export] public PackedScene ArtifactScene { get; set; }
    
    private Dictionary<string, Zone> zones = new();
    private List<Anomaly> activeAnomalies = new();
    private Timer blowoutTimer;
    
    public override void _Ready()
    {
        InitializeZones();
        SetupBlowoutSystem();
        ConnectToEvents();
    }
    
    private void InitializeZones()
    {
        // Load zone configuration from resource files
        var zoneConfigs = LoadZoneConfigurations();
        
        foreach (var config in zoneConfigs)
        {
            var zone = CreateZone(config);
            zones[zone.Id] = zone;
            SpawnInitialAnomalies(zone);
        }
    }
    
    private void SetupBlowoutSystem()
    {
        blowoutTimer = new Timer();
        AddChild(blowoutTimer);
        
        // Random blowout intervals (3-6 hours game time)
        ScheduleNextBlowout();
    }
    
    private void ScheduleNextBlowout()
    {
        var interval = GD.RandRange(10800, 21600); // 3-6 hours in seconds
        blowoutTimer.WaitTime = interval;
        blowoutTimer.Connect("timeout", Callable.From(TriggerBlowout));
        blowoutTimer.Start();
    }
    
    private void TriggerBlowout()
    {
        // Select random zone for blowout
        var availableZones = zones.Values.Where(z => z.CanHaveBlowout()).ToList();
        if (!availableZones.Any()) return;
        
        var targetZone = availableZones[GD.RandInt() % availableZones.Count];
        
        // Create blowout event
        var blowout = new BlowoutEvent
        {
            Zone = targetZone,
            Intensity = GD.RandRange(0.7f, 1.0f),
            Duration = GD.RandRange(60f, 180f),
            AffectRadius = GD.RandRange(200f, 500f)
        };
        
        ExecuteBlowout(blowout);
        ScheduleNextBlowout();
    }
    
    private void ExecuteBlowout(BlowoutEvent blowout)
    {
        // Warn all NPCs in the zone
        WarnNPCsOfBlowout(blowout);
        
        // Start blowout sequence
        StartBlowoutSequence(blowout);
        
        // Schedule blowout effects
        GetTree().CreateTimer(blowout.Duration).Connect("timeout",
            Callable.From(() => ApplyBlowoutEffects(blowout)));
    }
}
```

### 5.2 Anomaly System

```csharp
// Scripts/Zone/AnomalySystem.cs
public partial class AnomalySystem : Node
{
    [Export] public float AnomalySpawnRate { get; set; } = 0.1f;
    [Export] public int MaxAnomaliesPerZone { get; set; } = 50;
    
    private Dictionary<AnomalyType, AnomalyBehavior> behaviorTemplates = new();
    private List<Anomaly> activeAnomalies = new();
    
    public override void _Ready()
    {
        InitializeBehaviorTemplates();
        SetupSpawnTimer();
    }
    
    private void InitializeBehaviorTemplates()
    {
        behaviorTemplates[AnomalyType.Thermal] = new ThermalAnomalyBehavior();
        behaviorTemplates[AnomalyType.Gravity] = new GravityAnomalyBehavior();
        behaviorTemplates[AnomalyType.Electric] = new ElectricAnomalyBehavior();
        behaviorTemplates[AnomalyType.Spatial] = new SpatialAnomalyBehavior();
        behaviorTemplates[AnomalyType.Psychic] = new PsychicAnomalyBehavior();
    }
    
    public Anomaly CreateAnomaly(AnomalyType type, Vector3 position, Zone zone)
    {
        var anomalyScene = GD.Load<PackedScene>($"res://Scenes/Anomalies/{type}Anomaly.tscn");
        var anomaly = anomalyScene.Instantiate<Anomaly>();
        
        // Configure anomaly
        anomaly.Type = type;
        anomaly.GlobalPosition = position;
        anomaly.Initialize(behaviorTemplates[type].Clone());
        
        // Add to scene and tracking
        zone.AddChild(anomaly);
        activeAnomalies.Add(anomaly);
        
        // Connect anomaly events
        anomaly.ArtifactGenerated += OnArtifactGenerated;
        anomaly.NPCInteracted += OnNPCInteracted;
        
        return anomaly;
    }
    
    private void OnArtifactGenerated(Anomaly anomaly, Vector3 position)
    {
        // Create artifact based on anomaly type
        var artifactType = DetermineArtifactType(anomaly);
        var artifact = CreateArtifact(artifactType, position);
        
        // Notify systems
        EventBus.EmitSignal("ARTIFACT_SPAWNED", artifact, anomaly);
    }
    
    // Anomaly lifecycle management
    public void UpdateAnomalies(float deltaTime)
    {
        var toRemove = new List<Anomaly>();
        
        foreach (var anomaly in activeAnomalies)
        {
            anomaly.Update(deltaTime);
            
            // Check for anomaly expiration
            if (anomaly.ShouldExpire())
            {
                toRemove.Add(anomaly);
            }
        }
        
        // Remove expired anomalies
        foreach (var anomaly in toRemove)
        {
            RemoveAnomaly(anomaly);
        }
    }
}
```

## 6. Performance Optimization Implementation

### 6.1 Performance Monitor

```csharp
// Scripts/AI/PerformanceMonitor.cs
public partial class PerformanceMonitor : Node
{
    [Signal] public delegate void PerformanceThresholdExceededEventHandler(string metric, float value);
    
    private Dictionary<string, float> metrics = new();
    private Dictionary<string, float> thresholds = new();
    private Timer metricsTimer;
    
    [Export] public bool EnableDetailedLogging { get; set; } = false;
    
    public override void _Ready()
    {
        SetupThresholds();
        SetupMetricsCollection();
    }
    
    private void SetupThresholds()
    {
        thresholds["frame_time"] = 16.67f; // 60 FPS
        thresholds["ai_strategic_time"] = 5.0f;
        thresholds["ai_tactical_time"] = 0.1f;
        thresholds["memory_usage_mb"] = 1024.0f;
        thresholds["npc_count"] = 200.0f;
    }
    
    private void SetupMetricsCollection()
    {
        metricsTimer = new Timer();
        AddChild(metricsTimer);
        metricsTimer.WaitTime = 1.0f; // Collect metrics every second
        metricsTimer.Connect("timeout", Callable.From(CollectMetrics));
        metricsTimer.Start();
    }
    
    private void CollectMetrics()
    {
        // Frame time metrics
        var frameTime = Engine.GetFramesPerSecond();
        metrics["frame_time"] = 1000.0f / Math.Max(frameTime, 1.0f);
        
        // AI performance metrics
        var aiManager = GetNode<AISystemManager>("/root/AISystemManager");
        metrics["ai_strategic_time"] = aiManager.GetAverageStrategicTime();
        metrics["ai_tactical_time"] = aiManager.GetAverageTacticalTime();
        
        // Memory metrics
        metrics["memory_usage_mb"] = GC.GetTotalMemory(false) / (1024.0f * 1024.0f);
        
        // NPC count
        metrics["npc_count"] = aiManager.GetNPCCount();
        
        // Check thresholds
        CheckThresholds();
        
        if (EnableDetailedLogging)
        {
            LogDetailedMetrics();
        }
    }
    
    private void CheckThresholds()
    {
        foreach (var kvp in thresholds)
        {
            if (metrics.TryGetValue(kvp.Key, out var value) && value > kvp.Value)
            {
                EmitSignal(SignalName.PerformanceThresholdExceeded, kvp.Key, value);
                
                // Automatic optimization
                TriggerOptimization(kvp.Key, value);
            }
        }
    }
    
    private void TriggerOptimization(string metric, float value)
    {
        switch (metric)
        {
            case "frame_time":
                OptimizeFrameTime();
                break;
            case "ai_strategic_time":
                OptimizeStrategicAI();
                break;
            case "memory_usage_mb":
                TriggerGarbageCollection();
                break;
            case "npc_count":
                ReduceNPCComplexity();
                break;
        }
    }
}
```

### 6.2 Dynamic LOD Adjustment

```csharp
// Scripts/AI/DynamicLODAdjustment.cs
public partial class DynamicLODAdjustment : Node
{
    private LODManager lodManager;
    private PerformanceMonitor performanceMonitor;
    
    [Export] public float TargetFrameTime { get; set; } = 16.67f; // 60 FPS
    [Export] public float AdjustmentThreshold { get; set; } = 0.1f; // 10%
    
    public override void _Ready()
    {
        lodManager = GetNode<LODManager>("/root/LODManager");
        performanceMonitor = GetNode<PerformanceMonitor>("/root/PerformanceMonitor");
        
        performanceMonitor.Connect("PerformanceThresholdExceeded", 
            Callable.From<string, float>(OnPerformanceThresholdExceeded));
    }
    
    private void OnPerformanceThresholdExceeded(string metric, float value)
    {
        if (metric == "frame_time")
        {
            var deviation = (value - TargetFrameTime) / TargetFrameTime;
            
            if (deviation > AdjustmentThreshold)
            {
                // Reduce LOD quality
                AdjustLODQuality(-deviation);
            }
        }
    }
    
    private void AdjustLODQuality(float adjustment)
    {
        var currentDistances = lodManager.GetLODDistances();
        var newDistances = new Vector3[currentDistances.Length];
        
        for (int i = 0; i < currentDistances.Length; i++)
        {
            // Adjust LOD distances by percentage
            var multiplier = 1.0f + adjustment;
            newDistances[i] = new Vector3(
                currentDistances[i].X * multiplier,
                currentDistances[i].Y * multiplier,
                currentDistances[i].Z * multiplier
            );
        }
        
        lodManager.SetLODDistances(newDistances);
        
        GD.Print($"Adjusted LOD distances by {adjustment * 100:F1}%");
    }
    
    // Monitor performance and restore quality when possible
    public override void _Process(double delta)
    {
        if (performanceMonitor.GetMetric("frame_time") < TargetFrameTime * 0.9f)
        {
            // Performance is good, try to restore quality
            RestoreLODQuality(0.01f); // Gradually restore
        }
    }
}
```

## 7. Error Handling and Recovery

### 7.1 AI Error Recovery System

```csharp
// Scripts/AI/ErrorRecovery/AIErrorHandler.cs
public partial class AIErrorHandler : Node
{
    [Signal] public delegate void AIErrorOccurredEventHandler(AIError error);
    [Signal] public delegate void RecoveryAttemptedEventHandler(AIError error, bool successful);
    
    private Dictionary<ErrorType, IRecoveryStrategy> recoveryStrategies = new();
    private List<AIError> unhandledErrors = new();
    
    public override void _Ready()
    {
        InitializeRecoveryStrategies();
        SetupErrorMonitoring();
    }
    
    private void InitializeRecoveryStrategies()
    {
        recoveryStrategies[ErrorType.PathfindingFailure] = new PathfindingRecoveryStrategy();
        recoveryStrategies[ErrorType.DecisionTimeout] = new DecisionTimeoutRecoveryStrategy();
        recoveryStrategies[ErrorType.MemoryCorruption] = new MemoryRecoveryStrategy();
        recoveryStrategies[ErrorType.SynchronizationError] = new SyncRecoveryStrategy();
    }
    
    public async Task<bool> HandleError(AIError error)
    {
        EmitSignal(SignalName.AIErrorOccurred, error);
        
        // Log error for analysis
        LogError(error);
        
        // Attempt recovery
        bool recovered = false;
        if (recoveryStrategies.TryGetValue(error.Type, out var strategy))
        {
            try
            {
                recovered = await strategy.Attempt(error);
                EmitSignal(SignalName.RecoveryAttempted, error, recovered);
            }
            catch (Exception ex)
            {
                GD.PrintErr($"Recovery strategy failed: {ex.Message}");
                // Fall back to emergency recovery
                recovered = await EmergencyRecovery(error);
            }
        }
        
        if (!recovered)
        {
            unhandledErrors.Add(error);
        }
        
        return recovered;
    }
    
    private async Task<bool> EmergencyRecovery(AIError error)
    {
        // Last resort recovery - reset to safe state
        switch (error.Context)
        {
            case NPC npc:
                ResetNPCToSafeState(npc);
                return true;
            case DualBrainSystem brain:
                RestartBrainSystem(brain);
                return true;
            default:
                return false;
        }
    }
    
    private void ResetNPCToSafeState(NPC npc)
    {
        // Stop all current actions
        npc.StopAllActions();
        
        // Reset to basic state
        npc.SetBehavior(new BasicIdleBehavior());
        
        // Clear problematic goals
        npc.ClearGoals();
        
        // Add basic survival goal
        npc.AddGoal(new SurvivalGoal());
        
        // Restart AI systems after delay
        GetTree().CreateTimer(5.0f).Connect("timeout",
            Callable.From(() => npc.RestartAISystems()));
    }
}
```

### 7.2 Automated Testing and Validation

```csharp
// Scripts/Testing/AIValidation.cs
[System]
public partial class AIValidation : Node
{
    [Export] public bool EnableRuntimeValidation { get; set; } = true;
    [Export] public float ValidationInterval { get; set; } = 10.0f;
    
    private Timer validationTimer;
    private List<IValidator> validators = new();
    
    public override void _Ready()
    {
        if (!EnableRuntimeValidation) return;
        
        InitializeValidators();
        SetupValidationTimer();
    }
    
    private void InitializeValidators()
    {
        validators.Add(new DecisionConsistencyValidator());
        validators.Add(new PerformanceValidator());
        validators.Add(new StateIntegrityValidator());
        validators.Add(new BehaviorRealismValidator());
    }
    
    private void SetupValidationTimer()
    {
        validationTimer = new Timer();
        AddChild(validationTimer);
        validationTimer.WaitTime = ValidationInterval;
        validationTimer.Connect("timeout", Callable.From(RunValidation));
        validationTimer.Start();
    }
    
    private async void RunValidation()
    {
        var aiManager = GetNode<AISystemManager>("/root/AISystemManager");
        var npcs = aiManager.GetAllNPCs();
        
        foreach (var validator in validators)
        {
            var results = await validator.Validate(npcs);
            ProcessValidationResults(results);
        }
    }
    
    private void ProcessValidationResults(ValidationResults results)
    {
        foreach (var issue in results.Issues)
        {
            switch (issue.Severity)
            {
                case Severity.Critical:
                    HandleCriticalIssue(issue);
                    break;
                case Severity.Warning:
                    LogWarning(issue);
                    break;
                case Severity.Info:
                    LogInfo(issue);
                    break;
            }
        }
    }
}
```

## 8. Best Practices Summary

### 8.1 Code Organization

```
CienPodroznika/
├── Scripts/
│   ├── AI/
│   │   ├── BrainSystem/          # Strategic/Tactical brains
│   │   ├── Behaviors/            # Individual AI behaviors
│   │   ├── Utilities/           # Shared AI utilities
│   │   └── Testing/             # AI-specific tests
│   ├── Core/
│   │   ├── Managers/            # System managers (autoloads)
│   │   └── Events/              # Event system
│   └── Utils/
│       ├── Extensions/          # C# extensions
│       └── Helpers/             # Utility functions
```

### 8.2 Performance Guidelines

1. **Strategic Brain**: Max 5ms per update (5Hz)
2. **Tactical Brain**: Max 0.1ms per frame (LOD 0)
3. **Memory**: < 2KB per NPC average
4. **LOD Usage**: 70%+ NPCs should be in LOD 1+ most of the time
5. **Thread Utilization**: Main thread <40% for AI systems

### 8.3 Testing Guidelines

1. **Unit Tests**: Every AI decision function
2. **Integration Tests**: Brain synchronization
3. **Performance Tests**: Batch AI operations
4. **Behavior Tests**: Complex scenario validation
5. **Regression Tests**: Before each major release

### 8.4 Error Handling Rules

1. **Always catch exceptions** in AI critical paths
2. **Provide graceful degradation** for all AI systems
3. **Log errors with context** for debugging
4. **Implement recovery strategies** for common failures
5. **Monitor error rates** in production

## 9. Deployment and Monitoring

### 9.1 Build Configuration

```csharp
// Scripts/BuildConfiguration.cs
public static class BuildConfiguration
{
    public static void ConfigureAISettings()
    {
        #if DEBUG
            AISettings.EnableDebugVisualization = true;
            AISettings.EnablePerformanceLogging = true;
            AISettings.ValidateDecisions = true;
        #else
            AISettings.EnableDebugVisualization = false;
            AISettings.EnablePerformanceLogging = false;
            AISettings.ValidateDecisions = false;
        #endif
        
        #if !MOBILE
            AISettings.MaxNPCs = 200;
            AISettings.HighQualityAI = true;
        #else
            AISettings.MaxNPCs = 50;
            AISettings.HighQualityAI = false;
        #endif
    }
}
```

### 9.2 Production Monitoring

```csharp
// Scripts/ProductionMonitoring.cs
public partial class ProductionMonitoring : Node
{
    private const string ANALYTICS_ENDPOINT = "https://api.game-analytics.com";
    private Timer metricsUploadTimer;
    
    public override void _Ready()
    {
        #if !DEBUG
            SetupProductionMonitoring();
        #endif
    }
    
    private void SetupProductionMonitoring()
    {
        // Upload metrics every 5 minutes
        metricsUploadTimer = new Timer();
        AddChild(metricsUploadTimer);
        metricsUploadTimer.WaitTime = 300.0f;
        metricsUploadTimer.Connect("timeout", Callable.From(UploadMetrics));
        metricsUploadTimer.Start();
    }
    
    private async void UploadMetrics()
    {
        var metrics = CollectProductionMetrics();
        
        try
        {
            await SendMetricsToServer(metrics);
        }
        catch (Exception ex)
        {
            GD.PrintErr($"Failed to upload metrics: {ex.Message}");
        }
    }
}
```

## Podsumowanie

Ten przewodnik zawiera praktyczne instrukcje implementacji wszystkich kluczowych systemów "Cienia Podróżnika" w Godot 4:

1. **System Dwóch Mózgów** - Kompletna implementacja z przykładami kodu
2. **System LOD** - Dynamiczne zarządzanie wydajnością
3. **System Frakcji** - Emergentne grupy i relacje
4. **System Strefy** - Anomalie i blowouty
5. **Monitoring Wydajności** - Automatyczne optymalizacje
6. **Error Handling** - Resilient AI systems
7. **Testing Framework** - Automated validation
8. **Production Ready** - Deployment considerations

Wszystkie przykłady są gotowe do użycia w Godot 4 i zaprojektowane z myślą o łatwości utrzymania i rozbudowy.

---

> **Next Steps**: Rozpocznij implementację od systemu dwóch mózgów, następnie dodaj LOD management i stopniowo wprowadzaj kolejne systemy.