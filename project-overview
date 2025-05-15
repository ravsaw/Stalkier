# Cień Podróżnika - Przegląd Projektu

## Struktura Dokumentacji

Ten dokument pełni rolę nawigacyjnego przewodnika po całej dokumentacji projektu "Cień Podróżnika", zapewniając jasne powiązania między różnymi aspektami gry.

## Dokumenty Projektowe

### 1. [functions-index.md](functions-index.md) - Indeks Funkcjonalności
**Opis**: Mapa wszystkich systemów gry z hierarchią priorytetów  
**Kluczowe sekcje**:
- Hierarchia priorytetów (Must-Have → Core → Enhanced)
- Mapa zależności między systemami
- Przepływy danych i interfejsy
- **Używaj jako**: Punkt startowy dla zrozumienia architektury

### 2. [story-document.md](story-document.md) - Fabuła i Historia Świata
**Opis**: Kompletna narracja, postacie i wydarzenia  
**Kluczowe sekcje**:
- Kalendarium wydarzeń Strefy
- Główne wątki fabularne
- Kluczowe postacie i ich historie
- **Używaj jako**: Referencja dla content designu i narracji

### 3. [technical-design.md](technical-design.md) - Projekt Techniczny
**Opis**: Szczegółowa implementacja systemów technicznych  
**Kluczowe sekcje**:
- System "Dwóch Mózgów" (MUST-HAVE)
- Hierarchiczny LOD dla AI
- System śledzenia historii NPC
- **Używaj jako**: Guide dla programistów i architektów systemu

### 4. [glossary.md](glossary.md) - Glosariusz Projektowy
**Opis**: Definicje wszystkich terminów i konceptów  
**Kluczowe sekcje**:
- Alfabetyczny indeks terminów
- Szczegółowe definicje mechanik
- Referencje do innych dokumentów
- **Używaj jako**: Słownik dla zespołu (obowiązkowe podczas debat terminologicznych)

## Przepływy Prac (Workflows)

### Dla Programistów
1. **Rozpoczęcie pracy nad systemem**:
   - [functions-index.md](functions-index.md) → Znajdź system w hierarchii  
   - [technical-design.md](technical-design.md) → Implementacyjne szczegóły  
   - [glossary.md](glossary.md) → Terminologia  

2. **Implementacja AI**:
   - [technical-design.md](technical-design.md), Sekcja 1 → System Dwóch Mózgów  
   - [functions-index.md](functions-index.md) → Mapa zależności  
   - [story-document.md](story-document.md) → Kontekst zachowań NPC  

### Dla Designerów Gry
1. **Projektowanie mechanik**:
   - [functions-index.md](functions-index.md) → Sprawdź priorytety  
   - [story-document.md](story-document.md) → Kontekst fabularny  
   - [glossary.md](glossary.md) → Spójność terminologiczna  

2. **Balansowanie systemów**:
   - [technical-design.md](technical-design.md) → Ograniczenia techniczne  
   - [functions-index.md](functions-index.md) → Interakcje systemów  

### Dla Writerów/Narratorów
1. **Tworzenie contentu**:
   - [story-document.md](story-document.md) → Główne wątki  
   - [glossary.md](glossary.md) → Spójność nazewnictwa  
   - [functions-index.md](functions-index.md) → Wpływ mechanik na narrację  

## Kluczowe Zasady Integracji

### 1. **System "Dwóch Mózgów" jest podstawą**
- Wszystkie systemy AI muszą być kompatybilne z tą architekturą
- Patrz: [technical-design.md](technical-design.md), Sekcja 1

### 2. **Emergentne zachowania są celem**
- Systemy mają współpracować, tworząc nieoczekiwane rezultaty
- Patrz: [functions-index.md](functions-index.md), Mapa zależności

### 3. **Fabuła napędza systemy**
- Mechaniki mają służyć narratywie, nie odwrotnie
- Patrz: [story-document.md](story-document.md), Sekcje 3-4

## Quick Reference

### Najważniejsze Systemy
- **System Dwóch Mózgów**: [technical-design.md](technical-design.md)#section1
- **System Lokacji**: [functions-index.md](functions-index.md)#system-lokacji  
- **Anomalie**: [glossary.md](glossary.md)#anomalia
- **Frakcje**: [story-document.md](story-document.md)#frakcje

### Kluczowe Terminy
- **NPC**: [glossary.md](glossary.md)#npc
- **LOD**: [technical-design.md](technical-design.md)#lod
- **Naznaczenie**: [glossary.md](glossary.md)#naznaczenie  
- **Stalker**: [glossary.md](glossary.md)#stalker

## Aktualizacje Dokumentacji

**Zasada**: Każda zmiana w jednym dokumencie powinna być sprawdzona pod kątem wpływu na inne dokumenty.

**Checklist przed commitem**:
- [ ] Sprawdź referencje w project-overview.md
- [ ] Zaktualizuj glossary.md jeśli dodano nowe terminy
- [ ] Sprawdź spójność z functions-index.md
- [ ] Zweryfikuj zgodność z założeniami z story-document.md