# Cień Podróżnika - Projekt Techniczny

Ten dokument zawiera szczegółowe informacje techniczne dotyczące implementacji kluczowych systemów gry "Cień Podróżnika", skupiając się szczególnie na architekturze AI, optymalizacji wydajności oraz zaawansowanych mechanizmach rozgrywki.

> **Referencje**: Ten dokument jest ściśle powiązany z [functions-index.md](functions-index.md) (architektura systemów) i [glossary.md](glossary.md) (definicje terminów).

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

#### 1.1.2 Przepływ Informacji

```
[Mózg Strategiczny (2D)] <--> [System Buforowania/Synchronizacji] <--> [Mózg Taktyczny (3D)]
       |                                                                      |
       v                                                                      v
[Globalna Mapa Świata]                                                 [Lokalne Otoczenie]
[Długoterminowe Planowanie]                                           [Nawigacja 3D]
[Pamięć i Wiedza]                                                     [Percepcja Bezpośrednia]
```

> **Związek z innymi systemami**: Zobacz [functions-index.md](functions-index.md)#przepływy-kluczowych-danych

### 1.2 Modułowa Architektura Mózgów

Każdy z mózgów jest podzielony na współpracujące moduły, zapewniając elastyczność i łatwiejszą rozbudowę systemu.

#### 1.2.1 Moduły Mózgu Strategicznego

1. **Moduł Pamięci**
   - Przechowywanie wiedzy o świecie i doświadczeniach
   - System kategoryzacji i ważności informacji
   - Mechanizm zapominania nieistotnych danych
   - Udostępnianie wiedzy grupom i frakcjom

2. **Moduł Planowania Ścieżek 2D**
   - System nawigacji oparty na warstwieNavigacji2D
   - Globalne planowanie tras między lokacjami
   - System oceny bezpieczeństwa i efektywności ścieżek
   - Świadomość terytoriów frakcyjnych i zagrożeń

3. **Moduł Zarządzania Celami**
   - Hierarchiczna struktura celów długo- i średnioterminowych
   - System priorytetyzacji i warunków sukcesu/porażki
   - Mechanizm adaptacji celów do zmieniających się warunków
   - Balansowanie konfliktowych celów i potrzeb

4. **Moduł Relacji**
   - Śledzenie relacji z innymi NPC i frakcjami
   - System reputacji i historii interakcji
   - Mechanizm zaufania i podejrzliwości
   - Pamięć społeczna i wpływy kulturowe

#### 1.2.2 Moduły Mózgu Taktycznego

1. **Moduł Percepcji**
   - Symulacja zmysłów (wzrok, słuch, "zmysł strefy")
   - Wykrywanie i ocena zagrożeń i możliwości
   - Mechanizm uwagi i filtrowania bodźców
   - Adaptacja do warunków środowiskowych

2. **Moduł Nawigacji 3D**
   - System nawigacji w przestrzeni trójwymiarowej
   - Unikanie przeszkód i zagrożeń
   - Adaptacja ruchu do terenu i ukształtowania
   - Taktyczne wykorzystanie osłon i ukryć

3. **Moduł Interakcji**
   - System interakcji z obiektami w świecie
   - Wykorzystywanie przedmiotów i ekwipunku
   - Interakcje społeczne z innymi NPC
   - Specjalne interakcje z anomaliami i artefaktami

4. **Moduł Taktyki Bojowej**
   - Ocena sytuacji bojowej i zagrożeń
   - Wybór broni i taktyki odpowiedniej do sytuacji
   - Koordynacja grupowa w walce
   - Decyzje o wycofaniu się lub kontynuowaniu walki



## 2. System Hierarchicznego LOD dla AI

### 2.1 Poziomy Szczegółowości

Hierarchiczny system LOD (Level of Detail) dla AI umożliwia skalowanie złożoności symulacji w zależności od odległości i znaczenia NPC. Pozwala to na symulowanie dużej liczby postaci przy zachowaniu wydajności.

#### 2.1.1 Definicja Poziomów LOD

1. **Full Detail (Poziom 0)**
   - Odległość: 0-50 jednostek od gracza
   - Pełna percepcja, nawigacja i interakcje
   - Zaawansowane zachowania bojowe i społeczne
   - Kompleksowa animacja i fizyka
   - Aktualizacja co klatkę

2. **Medium Detail (Poziom 1)**
   - Odległość: 50-200 jednostek
   - Uproszczona percepcja (mniejszy zasięg i dokładność)
   - Podstawowa nawigacja z unikaniem przeszkód
   - Uproszczone animacje i zachowania
   - Aktualizacja co 2-3 klatki

3. **Low Detail (Poziom 2)**
   - Odległość: 200-500 jednostek
   - Minimalna percepcja (tylko krytyczne zagrożenia)
   - Bardzo uproszczona nawigacja
   - Podstawowe animacje
   - Aktualizacja co 5-10 klatek

4. **Strategic Only (Poziom 3)**
   - Odległość: ponad 500 jednostek
   - Brak symulacji taktycznej, tylko strategiczna
   - Ruch po siatce 2D zamiast pełnej nawigacji 3D
   - Minimalne renderowanie lub brak
   - Aktualizacja co 30-60 klatek


## 3. System Śledzenia Historii NPC

### 3.1 Struktura Danych Historii

Każdy NPC ma swoją "historię życia" składającą się z istotnych wydarzeń. Wydarzenia są kategoryzowane według znaczenia, aby uniknąć nadmiernego gromadzenia mało istotnych informacji.

#### 3.1.1 Kategorie Znaczenia Wydarzeń

1. **Trywialne (0)** - codzienne czynności, ignorowane w zapisie
2. **Drobne (1)** - mniejsze interakcje, podstawowe znaleziska
3. **Znaczące (2)** - walki, cenne znaleziska, ważne lokacje
4. **Kluczowe (3)** - pierwsze zabójstwo, rzadkie artefakty
5. **Krytyczne (4)** - transformacje, śmierć, unikalne osiągnięcia


### 3.2 System Generowania Narracji

System generowania narracji tworzy spójne opisy życia NPC na podstawie zgromadzonych wydarzeń.


## 4. Architektura Wielowątkowa

### 4.1 Rozdzielenie Obliczeń

Implementacja wielowątkowa umożliwia efektywne wykorzystanie wielu rdzeni procesora i uniknięcie spadków wydajności podczas intensywnych obliczeń AI.

#### 4.1.1 Podział na Wątki/Taski

1. **Główny Wątek/Task**
   - Renderowanie i fizyka
   - Obsługa wejścia gracza
   - Mózg taktyczny (3D) dla najbliższych NPC
   - Główna pętla gry i zarządzanie sceną

2. **Wątek/Task AI Strategicznego**
   - "Mózg strategiczny" (2D) dla wszystkich NPC
   - Długoterminowe planowanie i symulacja
   - Zarządzanie frakcjami i dynamiką społeczną
   - Periodyczna aktualizacja (niższa częstotliwość)

3. **Wątek/Task Nawigacyjny**
   - Obliczanie i buforowanie ścieżek
   - Dynamiczne aktualizacje map nawigacyjnych
   - Optymalizacja nawigacji dla grup NPC

4. **Wątek/Task Symulacji Świata**
   - Symulacja ekonomii i handlu
   - Zmiany środowiskowe i anomalie
   - System dynamicznej pogody
   - Ekologia i migracje fauny

## 5. Wzorce Projektowe i Przykłady Implementacji

### 5.1 Wzorzec Command Pattern dla AI

System AI wykorzystuje wzorzec Command do enkapsulacji decyzji i umożliwienia ich logowania oraz rewersji.

```typescript
interface AICommand {
  execute(): void;
  undo(): void;
  getContext(): AIDecisionContext;
}

class MoveCommand implements AICommand {
  constructor(
    private npc: NPC,
    private targetPosition: Vector3,
    private pathfinding: PathfindingService
  ) {}
  
  execute(): void {
    this.pathfinding.moveTo(this.npc, this.targetPosition);
  }
  
  undo(): void {
    this.pathfinding.cancelMovement(this.npc);
  }
}
```

### 5.2 Observer Pattern dla Synchronizacji Mózgów

```typescript
class StrategicBrain implements Subject {
  private observers: Observer[] = [];
  private state: StrategicState;
  
  // Notyfikacja Mózgu Taktycznego o zmianie strategii
  notifyObservers(decision: StrategicDecision): void {
    this.observers.forEach(observer => 
      observer.update(decision)
    );
  }
}

class TacticalBrain implements Observer {
  update(decision: StrategicDecision): void {
    // Adaptacja taktyk do nowej strategii
    this.adaptToStrategy(decision);
  }
}
```

### 5.3 Factory Pattern dla Różnych Typów AI

```typescript
abstract class AIBehaviorFactory {
  abstract createStrategicBrain(): StrategicBrain;
  abstract createTacticalBrain(): TacticalBrain;
}

class StalkerAIFactory extends AIBehaviorFactory {
  createStrategicBrain(): StrategicBrain {
    return new AggressiveStalkerStrategic();
  }
  
  createTacticalBrain(): TacticalBrain {
    return new CautiousStalkerTactical();
  }
}
```

### 5.4 Przykład Pełnego Przepływu Decyzji

```typescript
// 1. Mózg Strategiczny wykrywa możliwość
class StrategicBrain {
  processWorldState(worldState: WorldState): void {
    if (this.identifyArtifactOpportunity(worldState)) {
      const command = new GoToArtifactCommand(
        this.npc,
        worldState.artifactLocation
      );
      
      // 2. Wysłanie komendy do Mózgu Taktycznego
      this.sendToTactical(command);
      
      // 3. Aktualizacja historii i celów
      this.updatePersonalGoals('SEEK_ARTIFACT');
      this.historyService.addEvent(
        this.npc,
        'ARTIFACT_SPOTTED',
        worldState.artifactLocation
      );
    }
  }
}

// 4. Mózg Taktyczny implementuje decyzję
class TacticalBrain {
  receiveCommand(command: AICommand): void {
    // 5. Analiza bezpieczeństwa ścieżki
    const threats = this.analyzePathThreats(command.getPath());
    
    if (threats.length > this.npc.riskTolerance) {
      // 6. Negocjacja z Mózgiem Strategicznym
      this.requestAlternativeStrategy(command);
    } else {
      // 7. Wykonanie z monitoringiem
      this.executeWithMonitoring(command);
    }
  }
}
```

## 6. Metryki i Monitoring

### 6.1 Kluczowe Wskaźniki Wydajności (KPI)

#### Wydajność AI
- **Czas decyzji strategicznej**: < 5ms (średni), < 20ms (95 percentyl)
- **Czas reakcji taktycznej**: < 1ms (średni), < 5ms (95 percentyl)  
- **Zużycie CPU na NPC**: < 0.1ms/klatkę dla LOD 0-1
- **Zużycie pamięci na NPC**: < 2KB dla pełnego state

#### Jakość zachowań
- **Spójność celów**: > 95% decyzji spójnych z długoterminowymi celami
- **Realizm ścieżek**: < 5% przypadków "kluczenia" w nawigacji
- **Rozpoznawalność osobowości**: > 80% unikalnych wzorców na NPC

### 6.2 System Telemetrii

```typescript
class AITelemetry {
  trackDecision(npc: NPC, decision: AIDecision): void {
    const metrics = {
      npcId: npc.id,
      decisionType: decision.type,
      processingTime: decision.processingTime,
      context: decision.context,
      outcome: decision.outcome
    };
    
    // Wysłanie do systemu analityki
    this.analytics.track('ai_decision', metrics);
    
    // Lokalny cache dla hot-path analytics
    this.localCache.add(metrics);
  }
  
  generatePerformanceReport(): AIPerformanceReport {
    return new AIPerformanceReport(
      this.localCache.getMetrics(),
      this.calculateTrends(),
      this.identifyBottlenecks()
    );
  }
}
```

### 6.3 A/B Testing Framework dla AI

```typescript
class AIExperimentFramework {
  private experiments: Map<string, AIExperiment> = new Map();
  
  registerExperiment(name: string, variations: AIVariation[]): void {
    const experiment = new AIExperiment(name, variations);
    this.experiments.set(name, experiment);
  }
  
  getBehaviorForNPC(npc: NPC, experimentName: string): AIBehavior {
    const experiment = this.experiments.get(experimentName);
    const variation = experiment.getVariationForNPC(npc);
    
    return this.behaviorFactory.create(variation.parameters);
  }
  
  collectResults(): ExperimentResults {
    // Analiza wyników różnych wariantów AI
    return this.analyzer.analyze(this.experiments);
  }
}
```

## 7. Debugging i Development Tools

### 7.1 AI Debugger Interface

```typescript
interface AIDebugger {
  // Wizualizacja stanów mózgów
  visualizeStrategicState(npc: NPC): DebugVisualization;
  visualizeTacticalState(npc: NPC): DebugVisualization;
  
  // Śledzenie decyzji
  traceDecisionProcess(npc: NPC, decision: AIDecision): DecisionTrace;
  
  // Symulacja scenariuszy
  simulateScenario(scenario: TestScenario): SimulationResult;
  
  // Live editing
  modifyBehavior(npc: NPC, modifications: BehaviorModifications): void;
}
```

### 7.2 Narzędzie AI Profiler

```typescript
class AIProfiler {
  private profiles: Map<string, AIProfile> = new Map();
  
  startProfiling(npcId: string): void {
    const profile = new AIProfile(npcId);
    profile.startCollection();
    this.profiles.set(npcId, profile);
  }
  
  stopProfiling(npcId: string): AIProfileReport {
    const profile = this.profiles.get(npcId);
    profile?.stopCollection();
    
    return this.generateReport(profile);
  }
  
  generateReport(profile: AIProfile): AIProfileReport {
    return {
      executionTimes: profile.getExecutionTimes(),
      memoryUsage: profile.getMemoryUsage(),
      decisionFrequency: profile.getDecisionFrequency(),
      bottlenecks: profile.identifyBottlenecks(),
      recommendations: this.generateRecommendations(profile)
    };
  }
}
```

## 8. Integracja z Innymi Systemami

### 8.1 Integracja z Systemem Fabuły

```typescript
class StoryAIIntegration {
  private storyManager: StoryManager;
  private aiSystem: DualBrainSystem;
  
  // NPC reagują na wydarzenia fabularne
  onStoryEvent(event: StoryEvent): void {
    const affectedNPCs = this.findNPCsInterestedIn(event);
    
    affectedNPCs.forEach(npc => {
      const reaction = this.generateReaction(npc, event);
      this.aiSystem.injectGoal(npc, reaction.newGoal);
      this.aiSystem.updateKnowledge(npc, reaction.newKnowledge);
    });
  }
  
  // AI wpływa na fabułę
  onAIAction(npc: NPC, action: AIAction): void {
    if (this.isStoryRelevantAction(action)) {
      const storyEvent = this.convertToStoryEvent(action);
      this.storyManager.processEvent(storyEvent);
    }
  }
}
```

### 8.2 Integracja z Systemem Ekonomii

> **Cross-reference**: Zobacz [functions-index.md](functions-index.md)#dynamika-frakcji dla kontekstu ekonomicznego

```typescript
class EconomyAIIntegration {
  // AI reakcja na zmiany ekonomiczne
  onPriceChange(goods: GoodsType, newPrice: number): void {
    const traders = this.aiSystem.getNPCsByRole('TRADER');
    
    traders.forEach(trader => {
      if (trader.hasGoods(goods)) {
        const strategy = this.calculateTradingStrategy(trader, goods, newPrice);
        this.aiSystem.updateStrategy(trader, strategy);
      }
    });
  }
  
  // AI wpływa na ekonomię
  onTradeComplete(trade: Trade): void {
    this.economySystem.updateSupplyDemand(trade.goods, trade.quantity);
    this.economySystem.adjustPrices(trade.location);
  }
}
```

## Podsumowanie

Architektura techniczna "Cienia Podróżnika" została zaprojektowana z myślą o skalowalności, wydajności i elastyczności. Kluczowe elementy to:

1. **System Dual-Brain AI**: Innowacyjne rozwiązanie łączące strategiczne planowanie z taktyczną realizacją
2. **Hierarchiczny LOD**: Inteligentne zarządzanie zasobami dla tysięcy NPC  
3. **Wielowątkowość**: Efektywne wykorzystanie nowoczesnych procesorów wielordzeniowych
4. **Rozbudowane Systemy Symulacji**: Od ekonomii po interakcje środowiskowe
5. **Narzędzia Debugowania**: Kompleksowe wsparcie dla deweloperów
6. **Wzorce Projektowe**: Proven patterns dla maintainable codebase
7. **Monitoring i Telemetria**: Data-driven approach do optymalizacji AI

Wszystkie te systemy współpracują ze sobą, tworząc emergentne zachowania i bogate doświadczenia gameplay'owe, które są charakterystyczne dla "Cienia Podróżnika".

> **Następne kroki**: Zobacz [project-overview.md](project-overview.md) dla workflow implementacyjnego