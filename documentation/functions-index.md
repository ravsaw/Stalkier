# Cień Podróżnika - Indeks Funkcjonalności

Ten dokument stanowi mapę wszystkich kluczowych systemów i mechanik gry "Cień Podróżnika", służący jako przewodnik po głównych elementach rozgrywki i technicznych rozwiązaniach.

## Hierarchia Priorytetów Systemów

### Priorytet 1 - Systemy Podstawowe (Must-Have)
1. **System "Dwóch Mózgów"** - Architektura AI (→ technical-design.md, Sekcja 1)
2. **System Lokacji** - Struktura świata
3. **Mechanika Pierwszej Osoby** - Podstawowa rozgrywka
4. **Anomalie i Artefakty** - Główne elementy unikalności

### Priorytet 2 - Systemy Kluczowe (Core Features)
1. **Historia i Biografia NPC** - Emergentne narracje
2. **Dynamika Frakcji** - Społeczna złożoność
3. **System Śledzenia Historii** (→ technical-design.md, Sekcja 3)
4. **Hierarchiczny LOD** - Optymalizacja (→ technical-design.md, Sekcja 2)

### Priorytet 3 - Systemy Wsparcia (Enhanced Experience)
1. **Ekonomia i Handel** - Dynamiczne systemy
2. **System Pogody** - Atmosfera i immersja
3. **Wydarzenia Emergentne** - Żywość świata
4. **Narzędzia Debugowania** - Wsparcie deweloperskie

## Mapa Zależności Systemów

```
[System "Dwóch Mózgów"]
├─→ [Historia NPC] ────┐
├─→ [Dynamika Frakcji] │
└─→ [System Lokacji] ──┼─→ [Wydarzenia Emergentne]
                       │
[Mechanika Pierwszej Osoby]
├─→ [Anomalie/Artefakty] ─→ [Ekonomia] ─→ [Dynamika Frakcji]
└─→ [System Progresji] ──→ [Historia NPC]

[System Pogody] ─→ [Anomalie] ─→ [System Strefy]
```

## Referencje Krzyżowe

- **Dla implementacji AI**: Zobacz technical-design.md, Sekcje 1-3
- **Dla fabuły i narracji**: Zobacz story-document.md, Sekcje 3-5
- **Dla definicji terminów**: Zobacz glossary.md
- **Dla połączenia systemów**: Patrz sekcja "Mapa Zależności" powyżej

## Przepływy Kluczowych Danych

### 1. Przepływ Informacji o NPC
```
[Mózg Strategiczny] ←→ [Status NPC] ←→ [Mózg Taktyczny]
         ↓                                    ↓
    [Historia NPC] ←────────────────→ [Interakcje 3D]
         ↓                                    ↓
    [Reputacja] ←─────────────────────→ [System Walki]
```

### 2. Przepływ Danych Frakcyjnych
```
[Cele Frakcji] → [Zadania NPC] → [Akcje Lokalne] → [Wydarzenia]
      ↓              ↓                ↓               ↓
   [Polityka] → [Alokacja Zasobów] → [Konflikty] → [Zmiany Status]
```

### 3. Przepływ Informacji o Anomaliach
```
[Generacja Anomalii] → [Mapa Strefy] → [Percepcja NPC] → [Decyzje AI]
         ↓                  ↓              ↓               ↓
   [Artefakty] ←──────[Detekcja]←────[Eksploracja]←──[Zachowania]
```

## Kluczowe Interfejsy Systemów

### 1. **Interfejs Mózg-Mózg**
- **Dane wejściowe**: Cele strategiczne, informacje o środowisku
- **Dane wyjściowe**: Decyzje taktyczne, aktualizacje statusu
- **Częstotliwość**: Buforowany transfer co 0.2s

### 2. **Interfejs AI-Svět**
- **Dane wejściowe**: Stan świata, pozycje obiektów, wydarzenia
- **Dane wyjściowe**: Intencje ruchu, akcje, interakcje
- **Częstotliwość**: Co klatkę dla LOD0-1, co 5 klatek dla LOD2+

### 3. **Interfejs Frakcja-Historia**
- **Dane wejściowe**: Wydarzenia grupowe, decyzje liderów
- **Dane wyjściowe**: Zmieniona reputacja, nowe cele, sojusze
- **Częstotliwość**: Związane z wydarzeniami

## Punkty Integracji

### Krytyczne powiązania wymagające szczególnej uwagi:

1. **AI ↔ System Lokacji**: Synchronizacja loadowania/unloadowania
2. **Historia NPC ↔ Wydarzenia**: Poprawność chronologiczna
3. **Dynamika Frakcji ↔ Ekonomia**: Sprzężenie zwrotne cen/dostępności
4. **System Strefy ↔ Wszystkie inne**: Wpływ anomalii na każdy aspekt

## Systemy Rozgrywki

### Mechanika Pierwszej Osoby
Podstawowy system kontroli gracza z perspektywy pierwszej osoby, obejmujący:
- Płynny ruch i interakcje z otoczeniem
- System broni i walki
- Zarządzanie ekwipunkiem i przedmiotami
- Mechaniki przetrwania i zdrowia

### System Strefy
Centralny element gry, obejmujący:
- Anomalie o różnych typach i właściwościach
- System artefaktów i ich wykrywania
- Wpływ Strefy na postacie ("Naznaczenie")
- Dynamiczne wydarzenia i wyrzuty anomalii

### System Lokacji
Struktura świata gry podzielona na:
- Oddzielne obszary połączone przejściami
- System ładowania i przełączania lokacji
- Mapowanie między reprezentacją 2D i 3D
- Zarządzanie populacją NPC w różnych obszarach

## Systemy Sztucznej Inteligencji

### System "Dwóch Mózgów"
Innowacyjna architektura AI składająca się z:
- **Mózg Strategiczny (2D)**: Długoterminowe planowanie i decyzje globalne
- **Mózg Taktyczny (3D)**: Bezpośrednie interakcje i zachowania lokalne
- System synchronizacji między obiema warstwami
- Hierarchiczny LOD (Level of Detail) dla optymalizacji

### Historia i Biografia NPC
System dokumentowania życia postaci:
- Automatyczne rejestrowanie znaczących wydarzeń
- Generowanie narracyjnych opisów biografii
- Wpływ doświadczeń na rozwój osobowości
- System rankingu i osiągnięć NPC

### Dynamika Frakcji
Złożony system społeczny obejmujący:
- Zarządzanie istniejącymi frakcjami
- Możliwość powstawania nowych grup
- Dyplomacja i konflikty międzyfrakcyjne
- Ewolucja ideologii i celów frakcji

## Systemy Społeczne i Ekonomiczne

### Ekonomia i Handel
Dynamiczny system ekonomiczny z:
- Zmiennymi cenami opartymi na podaży i popycie
- Różne waluty i systemy wymiany
- Sieci handlowe między lokacjami
- Wpływ wydarzeń na rynki

### Relacje i Reputacja
System zarządzający stosunkami między postaciami:
- Indywidualne relacje NPC z graczem i innymi
- Pamięć grupowa i przekazywanie informacji
- Wpływ działań na reputację
- Konsekwencje społeczne wyborów gracza

## Systemy Środowiskowe

### Anomalie i Artefakty
Główne elementy unikalności Strefy:
- Różnorodne typy anomalii z unikalnym oddziaływaniem
- System detekcji i bezpiecznego omijania
- Artefakty jako cenne źródła mocy i bogactwa
- Interakcje między różnymi typami anomalii

### System Pogody i Środowiska
Dynamiczne warunki wpływające na rozgrywkę:
- Standardowe zjawiska pogodowe
- Unikalne dla Strefy "wyrzuty" i burze anomalii
- Wpływ warunków na zachowanie AI i mechaniki
- Atmosferyczne efekty wizualne i dźwiękowe

## Systemy Narracyjne

### Fabuła i Odkrywanie Prawdy
Wielowarstwowa narracja obejmująca:
- Główną ścieżkę fabularną
- Alternatywne interpretacje wydarzeń
- System poszlak i stopniowego odkrywania
- Influence storylines wynikające z działań gracza

### Wydarzenia Emergentne
System generujący nieprzewidywalne sytuacje:
- Losowe spotkania i wydarzenia
- Łańcuchy przyczynowo-skutkowe
- Reakcje świata na działania gracza
- Długoterminowe konsekwencje wyborów

## Systemy Postaci

### Rozwój Gracza
Mechaniki progresji obejmujące:
- System naznaczenia Strefą
- Adaptacje pozytywne i negatywne
- Wybór ścieżki rozwoju
- Konsekwencje transformacji

### NPC i Ich Zachowania
Zaawansowany system postaci niezależnych:
- Indywidualne cele i motywacje
- Dynamiczne zmiany osobowości
- Autonomiczne decyzje i działania
- Tworzenie grup i sojuszy

## Optymalizacja i Wydajność

### Zarządzanie Zasobami
Efektywne wykorzystanie mocy obliczeniowej:
- Hierarchiczny LOD dla AI
- System wielowątkowy
- Inteligentne ładowanie zasobów
- Optymalizacja pamięci

### Narzędzia Debugowania
Kompleksowe narzędzia deweloperskie:
- Wizualizacja stanów AI
- Monitoring wydajności
- Logi zachowań NPC
- Narzędzia balansowania

## Podsumowanie

System funkcjonalności "Cienia Podróżnika" tworzy złożoną, ale spójną całość, gdzie każdy element wpływa na inne, generując emergentne zachowania i unikalne doświadczenia dla gracza. Kluczem do sukcesu jest równoważne rozwijanie wszystkich aspektów, zapewniając, że innowacyjne rozwiązania techniczne służą tworzeniu angażującej i immersyjnej rozgrywki.

### Priorytetowe zadania implementacyjne:
1. Stabilizacja interfejsów między Mózgami AI
2. Implementacja systemu buforowania dla przepływu danych
3. Stworzenie narzędzi do debugowania powiązań międzysystemowych
4. Testowanie wydajności przy różnych obciążeniach NPC