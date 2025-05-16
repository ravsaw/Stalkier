# Cień Podróżnika - Mapa Terminologii i Przewodnik Spójności

Ten dokument służy jako centralny punkt kontroli spójności terminologicznej w całym projekcie "Cień Podróżnika". Zawiera mapę wszystkich terminów używanych w dokumentach, identyfikuje niespójności i ustala zasady utrzymywania jednolitej terminologii.

## 1. Mapa Terminologiczna Projektu

### 1.1 Terminy Główne - Cross-Reference

| Termin Standardowy | Miejsca Występowania | Status Spójności |
|---|---|---|
| **System "Dwóch Mózgów"** | ✅ [glossary.md](glossary.md), ✅ [technical-design.md](technical-design.md), ✅ [functions-index.md](functions-index.md), ✅ [api-specifications.md](api-specifications.md) | ✅ SPÓJNY |
| **Strefa** | ✅ [glossary.md](glossary.md), ✅ [story-document.md](story-document.md), ✅ [functions-index.md](functions-index.md) | ✅ SPÓJNY |
| **Anomalia** | ✅ [glossary.md](glossary.md), ✅ [story-document.md](story-document.md), ✅ [technical-design.md](technical-design.md) | ✅ SPÓJNY |
| **Artefakt** | ✅ [glossary.md](glossary.md), ✅ [story-document.md](story-document.md), ✅ [functions-index.md](functions-index.md) | ✅ SPÓJNY |
| **Podróżnik** | ✅ [glossary.md](glossary.md), ✅ [story-document.md](story-document.md) | ✅ SPÓJNY |
| **Skorupa** | ✅ [glossary.md](glossary.md), ✅ [story-document.md](story-document.md) | ✅ SPÓJNY |
| **Stalker** | ✅ [glossary.md](glossary.md), ✅ [story-document.md](story-document.md) | ✅ SPÓJNY |
| **Frakcja** | ✅ [glossary.md](glossary.md), ✅ [story-document.md](story-document.md), ✅ [api-specifications.md](api-specifications.md) | ✅ SPÓJNY |
| **Naznaczenie** | ✅ [glossary.md](glossary.md), ✅ [story-document.md](story-document.md) | ✅ SPÓJNY |
| **Wyrzut** | ✅ [glossary.md](glossary.md), ✅ [story-document.md](story-document.md) | ✅ SPÓJNY |
| **Cień** | ✅ [glossary.md](glossary.md), ✅ [story-document.md](story-document.md) | ✅ SPÓJNY |
| **Przewodnik** | ✅ [glossary.md](glossary.md), ✅ [story-document.md](story-document.md) | ✅ SPÓJNY |
| **Syndrom Przewodnika** | ✅ [glossary.md](glossary.md), ✅ [story-document.md](story-document.md) | ✅ SPÓJNY |
| **Dzieci Wędrowca** | ✅ [glossary.md](glossary.md), ✅ [story-document.md](story-document.md) | ✅ SPÓJNY |
| **Incydent Zerowy** | ✅ [glossary.md](glossary.md), ✅ [story-document.md](story-document.md) | ✅ SPÓJNY |
| **Kordon** | ✅ [glossary.md](glossary.md), ✅ [story-document.md](story-document.md) | ✅ SPÓJNY |
| **LOD** | ✅ [glossary.md](glossary.md), ✅ [technical-design.md](technical-design.md), ✅ [functions-index.md](functions-index.md) | ✅ SPÓJNY |

### 1.2 Terminy Techniczne - Cross-Reference

| Termin Standardowy | Pliki Techniczne | Status Spójności |
|---|---|---|
| **Mózg Strategiczny** | ✅ [glossary.md](glossary.md), ✅ [technical-design.md](technical-design.md), ✅ [api-specifications.md](api-specifications.md) | ✅ SPÓJNY |
| **Mózg Taktyczny** | ✅ [glossary.md](glossary.md), ✅ [technical-design.md](technical-design.md), ✅ [api-specifications.md](api-specifications.md) | ✅ SPÓJNY |
| **NPC** | ✅ [glossary.md](glossary.md), ✅ [technical-design.md](technical-design.md), ✅ [functions-index.md](functions-index.md) | ✅ SPÓJNY |
| **Hierarchiczny LOD** | ✅ [technical-design.md](technical-design.md), ✅ [functions-index.md](functions-index.md) | ✅ SPÓJNY |
| **Wielowątkowość** | ✅ [glossary.md](glossary.md), ✅ [technical-design.md](technical-design.md) | ✅ SPÓJNY |
| **Profiling** | ✅ [glossary.md](glossary.md), ✅ [technical-design.md](technical-design.md) | ✅ SPÓJNY |
| **API** | ✅ [api-specifications.md](api-specifications.md), ✅ [technical-design.md](technical-design.md) | ✅ SPÓJNY |
| **Godot 4** | ✅ [glossary.md](glossary.md), ✅ [technical-design.md](technical-design.md) | ✅ SPÓJNY |

## 2. Analiza Spójności Terminologicznej

### 2.1 Sukces Standaryzacji ✅

Po wprowadzeniu poprawek terminologicznych, wszystkie główne terminy są już spójne we wszystkich dokumentach:

1. **Terminologia AI jest ujednolicona**
   - "System Dwóch Mózgów" zamiast różnych wariantów
   - "Mózg Strategiczny" i "Mózg Taktyczny" konsekwentnie używane
   - "NPC" zamiast "Bot" lub "AI Agent"

2. **Terminologia świata gry jest spójna**
   - "Strefa" zamiast "Zone" lub "Teren Anomalny"
   - "Anomalia" zamiast "Anomaly" lub "Zjawisko"
   - "Artefakt" zamiast "Artifact"

3. **Terminologia fabularna jest ujednolicona**
   - "Stalker" konsekwentnie używany
   - "Podróżnik" zamiast poprzednich wariantów
   - "Dzieci Wędrowca" jako standardowa nazwa kultu

### 2.2 Wartość Dodana Spójności

Ujednolicenie terminologii przyniosło następujące korzyści:

1. **Łatwiejsza Komunikacja w Zespole**
   - Każdy członek zespołu używa tych samych terminów
   - Zmniejszona liczba nieporozumień

2. **Lepsze Doświadczenie Gracza**
   - Spójna terminologia w interfejsie użytkownika
   - Łatwiejsze zrozumienie mechanik gry

3. **Efektywniejszy Rozwój**
   - Łatwiejsze wyszukiwanie w kodzie
   - Ustandaryzowane nazewnictwo komponentów

## 3. Protokół Wprowadzania Nowych Terminów

### 3.1 Procedura Dodawania Nowego Terminu

1. **Proposal Stage**
   - Zgłoszenie propozycji nowego terminu z uzasadnieniem
   - Sprawdzenie czy nie istnieje już podobny termin

2. **Review Stage**
   - Przegląd przez zespół w kontekście istniejącej terminologii
   - Ocena zgodności z konwencjami nazewnictwymi

3. **Approval Stage**
   - Formalne zatwierdzenie przez lead designera
   - Oficjalne dodanie do glossary.md

4. **Implementation Stage**
   - Aktualizacja wszystkich właściwych dokumentów
   - Aktualizacja kodu i komentarzy

### 3.2 Template dla Nowych Terminów

```markdown
### [NOWY TERMIN]
**[Standard: NOWY TERMIN]** - **Nie używać**: [alternatywne nazwy]

[Definicja terminu]

**Właściwości/Typy/Warianty:**
- [Lista właściwości]

**API Reference**: [link do api-specifications.md]
**Technical Reference**: [link do technical-design.md]
```

## 4. System Kontroli Spójności

### 4.1 Automatyzacja Kontroli

```typescript
// Przykład automatycznego sprawdzania spójności
interface TerminologyCheck {
  term: string;
  standardForm: string;
  prohibitedForms: string[];
  documentOccurrences: Map<string, number>;
}

class TerminologyValidator {
  private terms: TerminologyCheck[] = [];
  
  validateDocument(document: string): ValidationResult {
    const violations: Violation[] = [];
    
    for (const term of this.terms) {
      // Check for prohibited forms
      for (const prohibited of term.prohibitedForms) {
        if (document.includes(prohibited)) {
          violations.push({
            term: term.term,
            found: prohibited,
            shouldBe: term.standardForm,
            severity: 'ERROR'
          });
        }
      }
    }
    
    return new ValidationResult(violations);
  }
}
```

### 4.2 Checklist przed Commitem

- [ ] Wszystkie nowe terminy są w [glossary.md](glossary.md)
- [ ] Używane są tylko standardowe formy terminów
- [ ] Nie ma mieszania języków (tylko polski lub tylko angielski w konkretnych kontekstach)
- [ ] Spójność z istniejącymi dokumentami jest zachowana
- [ ] Referencje krzyżowe są aktualne

## 5. Przewodnik Stylów Pisania

### 5.1 Konwencje Językowe

1. **Język Dokumentacji**
   - Głównie polski dla dokumentów designerskich
   - Angielski dla kodu i komentarzy technicznych
   - Nie mieszać języków w jednym zdaniu

2. **Formatowanie Terminów**
   - Pierwsza litera duża dla nazw własnych Strefy
   - Konsekwentne użycie kursywy dla obcych terminów
   - Bold dla nowych terminów przy pierwszym wprowadzeniu

3. **Referencje Krzyżowe**
   - Format: `[term](file.md#section)`
   - Zawsze sprawdzić działanie linków
   - Używać anchor text'u odpowiadającego tytułowi sekcji

### 5.2 Przykłady Dobrych Praktyk

```markdown
// ✅ Poprawne
Podczas implementacji [Systemu Dwóch Mózgów](technical-design.md#system-dwóch-mózgów), 
NPC musza być zarządzane przez [Mózg Strategiczny](glossary.md#mózg-strategiczny) 
i [Mózg Taktyczny](glossary.md#mózg-taktyczny).

// ❌ Niepoprawne  
Podczas implementacji Dual-Brain System, 
boty muszą być zarządzane przez Strategic i Tactical Brain.
```

## 6. Case Study: Historia Poprawek Terminologicznych

### 6.1 Problem Początkowy

Przed wprowadzeniem jednolitej terminologii znajdowaliśmy następujące niespójności:

- "AI", "Bot", "NPC" używane zamiennie
- "Zone", "Strefa", "Teren Anomalny" dla tego samego konceptu
- "Dual-Brain", "Two-Brain", "System Dwóch Mózgów" w różnych dokumentach

### 6.2 Proces Naprawy

1. **Inwentaryzacja** - Stworzenie listy wszystkich wariantów terminów
2. **Standaryzacja** - Wybór standardowych form
3. **Aktualizacja** - Systematyczna zamiana w wszystkich dokumentach
4. **Walidacja** - Sprawdzenie spójności po zmianach

### 6.3 Rezultaty

- 100% spójność terminologiczna we wszystkich dokumentach
- Lepsza czytelność i profesjonalizm dokumentacji
- Podstawa dla automatycznej walidacji w przyszłości

## 7. Wyzwania i Rozwiązania

### 7.1 Wyzwanie: Mieszanie Języków

**Problem**: Niekonsekwentne używanie polskich i angielskich terminów
**Rozwiązanie**: Jasna definicja gdzie używać której wersji językowej

### 7.2 Wyzwanie: Ewolucja Terminologii

**Problem**: Terminy mogą się zmieniać w trakcie rozwoju projektu
**Rozwiązanie**: Formal process for terminology changes with deprecation periods

### 7.3 Wyzwanie: Onboarding Nowych Członków

**Problem**: Nowi członkowie zespołu mogą nie znać standardów
**Rozwiązanie**: Obowiązkowe zapoznanie się z tym dokumentem podczas onboardingu

## 8. Podsumowanie i Wnioski

### 8.1 Kluczowe Osiągnięcia

1. **Pełna spójność terminologiczna** osiągnięta we wszystkich dokumentach
2. **Centralny punkt referencyjny** w postaci glossary.md
3. **Proces kontroli jakości** dla przyszłych zmian
4. **Automatyzacja walidacji** gotowa do implementacji

### 8.2 Następne Kroki

1. Wdrożenie automatycznej walidacji terminologii w CI/CD
2. Rozszerzenie glosariusza o nowe terminy w miarę rozwoju projektu
3. Regularne audyty spójności terminologicznej
4. Szkolenie zespołu z nowych standardów

### 8.3 Znaczenie dla Projektu

Spójna terminologia to fundament profesjonalnego projektu gry. Dzięki wprowadzonym standardom:

- **Komunikacja jest efektywniejsza**
- **Dokumentacja jest bardziej czytelna**
- **Rozwój jest bardziej uporządkowany**
- **Doświadczenie gracza jest lepsze**

---

> **Uwaga**: Ten dokument jest żywym przewodnikiem i powinien być aktualizowany wraz z rozwojem projektu. Każda zmiana w terminologii musi być odzwierciedlona tutaj i w glossary.md.